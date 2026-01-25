import ArgumentParser
import CommonProcess
import CommonShell
import Foundation
import SwiftFormattingCore
import SwiftJSONFormatter
import SwiftMDFormatter
import CommonLog

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
    name: .customLong("swift-format-config"),
    help: "swift-format configuration file path (for --kind swift). Defaults to repo standard.")
  var swiftFormatConfig: String = "code/mono/apple/spm/universal/domain/tooling/configs/linting/.swift-format"

  @Flag(
    name: .customLong("include-ai"),
    help: "Include ai/imports and ai/exports paths (excluded by default).")
  var includeAI: Bool = false

  // MARK: Entry
  func run() async throws {
    let requested = Set(kinds)
    if requested.isEmpty { throw ValidationError("Provide at least one --kind (json|md|swift)") }

    let inputs = try FormattingInputs(files: files, globs: globs, includeAI: includeAI)
      .resolve(defaultGlobs: defaultGlobs(for: requested))

    var anyChanges = false
    var errorCount = 0

    if requested.contains(.json) {
      let jsonPaths = inputs.filter { $0.hasSuffix(".json") }
      let (changed, errors) = formatJSON(paths: jsonPaths, check: check, quiet: quiet)
      anyChanges = anyChanges || changed
      errorCount += errors
    }

    if requested.contains(.md) {
      let markdownFiles = inputs.filter { $0.hasSuffix(".md") || $0.hasSuffix(".mdx") }
      let (changed, errors) = formatMarkdown(paths: markdownFiles, check: check, quiet: quiet)
      anyChanges = anyChanges || changed
      errorCount += errors
    }

    if requested.contains(.swift) {
      let swiftPaths = inputs.filter { $0.hasSuffix(".swift") }
      let (changed, errors) = await formatSwift(paths: swiftPaths, check: check, quiet: quiet)
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
    let result = SwiftJSONFormatter.format(
      paths: paths,
      check: check,
      writeTo: nil,
      emit: { event in
        switch event {
        case .wouldChange(let path):
          if !quiet { Log.main.info("json: would change \(path)") }
        case .formatted(let path, _):
          if !quiet { Log.main.info("json: formatted \(path)") }
        case .error(let path, let error):
          Log.main.error("json: error formatting \(path): \(String(describing: error))")
        }
      }
    )
    return (result.changedCount > 0, result.errorCount)
  }

  // MARK: Markdown (in-process)
  private func formatMarkdown(paths: [String], check: Bool, quiet: Bool) -> (Bool, Int) {
    let result = SwiftMDFormatter().format(
      paths: paths,
      check: check,
      writeTo: nil,
      emit: { event in
        switch event {
        case .wouldChange(let path):
          if !quiet { Log.main.info("md: would change \(path)") }
        case .formatted(let path, _):
          if !quiet { Log.main.info("md: formatted \(path)") }
        case .error(let path, let error):
          Log.main.error("md: error formatting \(path): \(String(describing: error))")
        }
      }
    )
    return (result.changedCount > 0, result.errorCount)
  }

  // MARK: Swift (swift-format)
  private func formatSwift(paths: [String], check: Bool, quiet: Bool) async -> (Bool, Int) {
    guard !paths.isEmpty else { return (false, 0) }
    var anyChanges = false
    var errorCount = 0
    let chunked = chunk(paths, size: 100)
    for pathGroup in chunked {
      do {
        var arguments: [String] = [
          "format",
          "--configuration", swiftFormatConfig,
        ]
        if check {
          arguments.append(contentsOf: ["--mode", "lint"])
        } else {
          arguments.append("-i")
        }
        arguments.append(contentsOf: pathGroup)
        let sh = CommonShell(executable: .name("swift"))
        _ = try await sh.run(arguments: arguments)
      } catch let e as ProcessError {
        if check, (e.status ?? 1) != 0 {
          anyChanges = true
          if !quiet {
            Log.main.info("swift: would change some files in group (\(pathGroup.count))")
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

  private func chunk<T>(_ array: [T], size: Int) -> [[T]] {
    guard size > 0, array.count > size else { return array.isEmpty ? [] : [array] }
    var result: [[T]] = []
    result.reserveCapacity((array.count + size - 1) / size)
    var startIndex = 0
    while startIndex < array.count {
      let endIndex = min(startIndex + size, array.count)
      result.append(Array(array[startIndex..<endIndex]))
      startIndex = endIndex
    }
    return result
  }
}
