import ArgumentParser
import CommonProcess
import CommonShell
import Foundation
import WrkstrmFoundation
import WrkstrmLog
import WrkstrmMain

/// Unified formatter entrypoint that can handle JSON, Markdown, and Swift in one run.
struct Format: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "format",
    abstract: "Format files: json | md | swift (one or many kinds)",
    discussion:
      "Supports multiple --kind values in a single invocation; expands files via --file/--glob."
  )

  enum Kind: String, CaseIterable, ExpressibleByArgument {
    case json
    case md
    case swift
  }

  // MARK: Options
  @Option(
    name: .customLong("kind"), parsing: .upToNextOption,
    help: "Kinds to format: json, md, swift. Repeatable.")
  var kinds: [Kind] = []

  @Option(name: .customLong("file"), parsing: .upToNextOption, help: "Input files. Repeatable.")
  var files: [String] = []

  @Option(
    name: .customLong("glob"), parsing: .upToNextOption,
    help: "Glob patterns like '**/*.json'. Repeatable.")
  var globs: [String] = []

  @Flag(name: .customLong("check"), help: "Check only; exit non-zero if any file would change.")
  var check: Bool = false

  @Flag(name: .customLong("quiet"), help: "Suppress per-file logs; show summary/errors only.")
  var quiet: Bool = false

  @Option(
    name: .customLong("prettier-exec"),
    help: "Path or name of prettier executable (for --kind md). Defaults to 'prettier'.")
  var prettierExec: String = "prettier"

  @Option(
    name: .customLong("swift-format-config"),
    help: "swift-format configuration file path (for --kind swift). Defaults to repo standard.")
  var swiftFormatConfig: String = "code/mono/apple/spm/configs/linting/.swift-format"

  @Flag(
    name: .customLong("include-ai"),
    help: "Include ai/imports and ai/exports paths (excluded by default).")
  var includeAI: Bool = false

  // MARK: Entry
  func run() async throws {
    let requested = Set(kinds)
    if requested.isEmpty { throw ValidationError("Provide at least one --kind (json|md|swift)") }

    // Resolve input set once, then partition by kind
    let expanded = expandGlobs(globs.isEmpty ? defaultGlobs(for: requested) : globs)
    let uniqueInputsAll = Array(Set(files + expanded)).sorted()
    let uniqueInputs = includeAI ? uniqueInputsAll : uniqueInputsAll.filter { !isExcludedPath($0) }
    if uniqueInputs.isEmpty { throw ValidationError("No input files resolved from --file/--glob") }

    var anyChanges = false
    var errorCount = 0

    // JSON
    if requested.contains(.json) {
      let jsonFiles = uniqueInputs.filter { $0.hasSuffix(".json") }
      let (changed, errors) = formatJSON(paths: jsonFiles, check: check, quiet: quiet)
      anyChanges = anyChanges || changed
      errorCount += errors
    }

    // Markdown (Prettier)
    if requested.contains(.md) {
      let mdFiles = uniqueInputs.filter { $0.hasSuffix(".md") || $0.hasSuffix(".mdx") }
      let (changed, errors) = await formatMarkdown(paths: mdFiles, check: check, quiet: quiet)
      anyChanges = anyChanges || changed
      errorCount += errors
    }

    // Swift (swift-format)
    if requested.contains(.swift) {
      let swiftFiles = uniqueInputs.filter { $0.hasSuffix(".swift") }
      let (changed, errors) = await formatSwift(paths: swiftFiles, check: check, quiet: quiet)
      anyChanges = anyChanges || changed
      errorCount += errors
    }

    if check {
      if !quiet {
        Log.main.info("format:check done. changed=\(anyChanges ? 1 : 0) errors=\(errorCount)")
      }
      if anyChanges || errorCount > 0 { throw ExitCode(1) }
    } else {
      if !quiet { Log.main.info("format:apply done. errors=\(errorCount)") }
    }
  }

  // MARK: JSON (in-process)
  private func formatJSON(paths: [String], check: Bool, quiet: Bool) -> (Bool, Int) {
    var anyChanges = false
    var errorCount = 0
    let opts = JSON.Formatting.humanOptions
    for path in paths {
      do {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        let obj = try JSONSerialization.jsonObject(with: data)
        let formatted = try JSONSerialization.data(withJSONObject: obj, options: opts)
        if check {
          let old = String(data: data, encoding: .utf8) ?? String(decoding: data, as: UTF8.self)
          let new = String(decoding: formatted, as: UTF8.self)
          if old != new {
            anyChanges = true
            if !quiet { Log.main.info("json: would change \(path)") }
          }
        } else {
          try JSON.FileWriter.writeJSONObject(obj, to: url, options: opts, atomic: true)
          if !quiet { Log.main.info("json: formatted \(path)") }
        }
      } catch {
        errorCount += 1
        Log.main.error("json: error formatting \(path): \(String(describing: error))")
      }
    }
    return (anyChanges, errorCount)
  }

  // MARK: Markdown (Prettier)
  private func formatMarkdown(paths: [String], check: Bool, quiet: Bool) async -> (Bool, Int) {
    guard !paths.isEmpty else { return (false, 0) }
    var anyChanges = false
    var errorCount = 0
    let chunked = chunk(paths, size: 100)
    for group in chunked {
      do {
        var args: [String] = []
        args.append("--log-level")
        args.append(quiet ? "error" : "warn")
        if check {
          args.append("--check")
        } else {
          args.append("--write")
        }
        args.append(contentsOf: group)
        let sh = CommonShell(executable: .name(prettierExec))
        _ = try await sh.run(arguments: args)
      } catch let e as ProcessError {
        // Prettier uses non-zero exit for check differences; treat as change when check=true.
        if check, (e.status ?? 1) != 0 {
          anyChanges = true
          if !quiet {
            Log.main.info("md: would change some files in group (\(group.count))")
          }
          continue
        }
        errorCount += 1
        Log.main.error("md: error: \(String(describing: e))")
      } catch {
        errorCount += 1
        Log.main.error("md: error: \(String(describing: error))")
      }
    }
    return (anyChanges, errorCount)
  }

  // MARK: Swift (swift-format)
  private func formatSwift(paths: [String], check: Bool, quiet: Bool) async -> (Bool, Int) {
    guard !paths.isEmpty else { return (false, 0) }
    var anyChanges = false
    var errorCount = 0
    let chunked = chunk(paths, size: 100)
    for group in chunked {
      do {
        var args: [String] = [
          "format",
          "--configuration", swiftFormatConfig,
        ]
        if check {
          args.append(contentsOf: ["--mode", "lint"])  // non-zero if changes needed
        } else {
          args.append("-i")  // in-place
        }
        args.append(contentsOf: group)
        let sh = CommonShell(executable: .name("swift"))
        _ = try await sh.run(arguments: args)
      } catch let e as ProcessError {
        if check, (e.status ?? 1) != 0 {
          anyChanges = true
          if !quiet {
            Log.main.info("swift: would change some files in group (\(group.count))")
          }
          continue
        }
        errorCount += 1
        Log.main.error("swift: error: \(String(describing: e))")
      } catch {
        errorCount += 1
        Log.main.error("swift: error: \(String(describing: error))")
      }
    }
    return (anyChanges, errorCount)
  }

  // MARK: Helpers
  private func defaultGlobs(for kinds: Set<Kind>) -> [String] {
    var patterns: [String] = []
    if kinds.contains(.json) { patterns.append("**/*.json") }
    if kinds.contains(.md) { patterns.append(contentsOf: ["**/*.md", "**/*.mdx"]) }
    if kinds.contains(.swift) { patterns.append("**/*.swift") }
    return patterns
  }

  private func expandGlobs(_ patterns: [String]) -> [String] {
    var out: Set<String> = []
    #if canImport(Darwin)
      let recursive = patterns.filter { $0.contains("**") }
      let simple = patterns.filter { !$0.contains("**") }
      for pat in simple { out.formUnion(globDarwin(pat)) }
      out.formUnion(globRecursiveMulti(recursive))
    #else
      out.formUnion(globRecursiveMulti(patterns))
    #endif
    return Array(out).sorted()
  }

  #if canImport(Darwin)
    private func globDarwin(_ pattern: String) -> [String] {
      var gt = glob_t()
      let flags: Int32 = 0
      let rc = pattern.withCString { cpat in glob(cpat, flags, nil, &gt) }
      guard rc == 0 else { return [] }
      defer { globfree(&gt) }
      var out: [String] = []
      let c = Int(gt.gl_matchc)
      if let pathv = gt.gl_pathv {
        for i in 0..<c { if let s = pathv[i] { out.append(String(cString: s)) } }
      }
      return out
    }
  #endif

  private func globRecursiveMulti(_ patterns: [String]) -> [String] {
    guard !patterns.isEmpty else { return [] }
    let fm = FileManager.default
    let cwd = URL(fileURLWithPath: fm.currentDirectoryPath)
    var out: [String] = []
    if let en = fm.enumerator(at: cwd, includingPropertiesForKeys: nil) {
      for case let url as URL in en {
        let rel = url.path.replacingOccurrences(of: cwd.path + "/", with: "")
        for pat in patterns {
          if fnmatch(pat, rel) {
            out.append(url.path)
            break
          }
        }
      }
    }
    return out
  }

  private func fnmatch(_ pattern: String, _ path: String) -> Bool {
    #if canImport(Darwin)
      return path.withCString { p in
        pattern.withCString { pat in Foundation.fnmatch(pat, p, 0) == 0 }
      }
    #elseif canImport(Glibc)
      return path.withCString { p in pattern.withCString { pat in Glibc.fnmatch(pat, p, 0) == 0 } }
    #else
      return path.contains(pattern.replacingOccurrences(of: "*", with: ""))
    #endif
  }

  private func chunk<T>(_ array: [T], size: Int) -> [[T]] {
    guard size > 0, array.count > size else { return array.isEmpty ? [] : [array] }
    var result: [[T]] = []
    result.reserveCapacity((array.count + size - 1) / size)
    var i = 0
    while i < array.count {
      let j = min(i + size, array.count)
      result.append(Array(array[i..<j]))
      i = j
    }
    return result
  }

  // Exclusions: do not touch ai/imports or ai/exports
  private func isExcludedPath(_ path: String) -> Bool {
    let p = URL(fileURLWithPath: path).standardizedFileURL.path
    if p.contains("/ai/imports/") || p.hasSuffix("/ai/imports") { return true }
    if p.contains("/ai/exports/") || p.hasSuffix("/ai/exports") { return true }
    // Also handle repo-root relative forms
    if p.hasPrefix("ai/imports/") || p == "ai/imports" { return true }
    if p.hasPrefix("ai/exports/") || p == "ai/exports" { return true }
    return false
  }
}
