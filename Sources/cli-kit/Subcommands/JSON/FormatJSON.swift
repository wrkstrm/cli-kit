import ArgumentParser
import Foundation
import WrkstrmFoundation
import WrkstrmMain

struct FormatJSON: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "format",
    abstract: "Format JSON files using Wrkstrm JSON policy",
    discussion:
      "Formats one or more JSON files with prettyPrinted, sortedKeys, and withoutEscapingSlashes. Writes atomically. Use --write-to to mirror outputs into a separate directory."
  )

  @Option(
    name: .customLong("file"), parsing: .upToNextOption, help: "Input JSON file(s). Repeatable.")
  var files: [String] = []

  @Option(
    name: .customLong("glob"), parsing: .upToNextOption,
    help: "Glob patterns to expand (e.g., '**/*.json'). Repeatable.")
  var globs: [String] = []

  @Flag(
    name: .customLong("check"),
    help: "Check mode: exit non-zero if any file would change; do not write.")
  var check: Bool = false

  @Flag(name: .customLong("quiet"), help: "Suppress per-file logs; print only summary or errors.")
  var quiet: Bool = false

  @Option(
    name: .customLong("write-to"),
    help: "Write formatted output under this directory; mirrors relative paths.")
  var writeTo: String?

  @Flag(
    name: .customLong("stdin"),
    help: "Read JSON from stdin and write formatted JSON to stdout. Ignores files/globs.")
  var useStdin: Bool = false

  func run() async throws {
    let expanded: [String] = expandGlobs(globs)
    var inputs: [String] = Array(Set(files + expanded)).sorted()
    guard !inputs.isEmpty else {
      throw ValidationError("Provide at least one --file or --glob pattern")
    }
    var changedCount = 0
    var errorCount = 0
    // Streaming mode: stdin → stdout
    if useStdin {
      guard !check && writeTo == nil else {
        throw ValidationError("--stdin cannot be combined with --check or --write-to")
      }
      let data = FileHandle.standardInput.readDataToEndOfFile()
      let obj = try JSONSerialization.jsonObject(with: data)
      let formatted = try JSONSerialization.data(
        withJSONObject: obj, options: JSON.Formatting.humanOptions)
      FileHandle.standardOutput.write(formatted)
      FileHandle.standardOutput.write("\n".data(using: .utf8)!)
      return
    }

    let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).standardizedFileURL
    for path in inputs {
      do {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        // Allow object or array roots; validate JSON
        let obj = try JSONSerialization.jsonObject(with: data)
        // Render with our canonical options
        let formatted = try JSONSerialization.data(
          withJSONObject: obj, options: JSON.Formatting.humanOptions)
        if check {
          // Basic change detection: compare normalized strings
          let old = String(data: data, encoding: .utf8) ?? String(decoding: data, as: UTF8.self)
          let new = String(decoding: formatted, as: UTF8.self)
          if old != new {
            changedCount += 1
            if !quiet { fputs("would change: \(path)\n", stderr) }
          }
        } else {
          let destURL: URL = {
            guard let root = writeTo else {
              return url
            }
            let rootURL = URL(fileURLWithPath: root, isDirectory: true).standardizedFileURL
            let rel = relativePath(from: cwd, to: url)
            return rootURL.appendingPathComponent(rel)
          }()
          try JSON.FileWriter.writeJSONObject(
            obj, to: destURL, options: JSON.Formatting.humanOptions, atomic: true)
          if !quiet {
            if writeTo != nil {
              fputs("formatted: \(path) -> \(destURL.path)\n", stderr)
            } else {
              fputs("formatted: \(path)\n", stderr)
            }
          }
        }
      } catch {
        errorCount += 1
        fputs("error: \(path): \(error)\n", stderr)
      }
    }
    if check {
      if !quiet { fputs("\(changedCount) file(s) would change\n", stderr) }
      if changedCount > 0 { throw ExitCode(1) }
    } else if !quiet {
      fputs("done. errors=\(errorCount)\n", stderr)
    }
  }

  // MARK: - Globbing
  func expandGlobs(_ patterns: [String]) -> [String] {
    var out: Set<String> = []
    #if canImport(Darwin)
    let recursive = patterns.filter { $0.contains("**") }
    let simple = patterns.filter { !$0.contains("**") }
    // Expand simple patterns via glob(3)
    for pat in simple { out.formUnion(globDarwin(pat)) }
    // Expand recursive patterns with a single directory walk
    out.formUnion(globRecursiveMulti(recursive))
    #else
    out.formUnion(globRecursiveMulti(patterns))
    #endif
    return Array(out).sorted()
  }

  #if canImport(Darwin)
  private func globDarwin(_ pattern: String) -> [String] {
    var gt = glob_t()
    let flags: Int32 = 0  // default: supports *, ?, []
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
        // Match against any pattern
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
    return path.withCString { p in pattern.withCString { pat in Foundation.fnmatch(pat, p, 0) == 0 }
    }
    #elseif canImport(Glibc)
    return path.withCString { p in pattern.withCString { pat in Glibc.fnmatch(pat, p, 0) == 0 } }
    #else
    // Fallback: naive contains check
    return path.contains(pattern.replacingOccurrences(of: "*", with: ""))
    #endif
  }

  // MARK: - Path helpers
  private func relativePath(from base: URL, to file: URL) -> String {
    let b = base.standardizedFileURL.path
    let f = file.standardizedFileURL.path
    if f.hasPrefix(b + "/") { return String(f.dropFirst(b.count + 1)) }
    return file.lastPathComponent
  }
}
