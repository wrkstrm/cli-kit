import ArgumentParser
import Foundation
import WrkstrmFoundation
import WrkstrmLog
import WrkstrmMain

/// NDJSON helpers: convert JSON to single-line records and append to files/stdout.
struct NDJSONTool: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "ndjson",
    abstract: "Produce newline-delimited JSON (single-line records)",
    discussion:
      "Reads JSON from files, globs, or stdin and emits NDJSON: one JSON object per line with a trailing newline. Arrays are expanded into multiple lines."
  )

  @Option(
    name: .customLong("file"), parsing: .upToNextOption, help: "Input JSON file(s). Repeatable.")
  var files: [String] = []

  @Option(
    name: .customLong("glob"), parsing: .upToNextOption,
    help: "Glob patterns to expand (e.g., '**/*.json'). Repeatable.")
  var globs: [String] = []

  @Flag(
    name: .customLong("stdin"), help: "Read JSON from stdin. If array, expands to multiple lines.")
  var useStdin: Bool = false

  @Option(
    name: .customLong("append-to"),
    help: "Append output lines to the given file path instead of stdout.")
  var appendTo: String?

  @Flag(
    name: .customLong("without-escaping-slashes"),
    help: "Do not escape '/' in output (applies to JSONObject inputs).")
  var withoutEscapingSlashes: Bool = false

  @Flag(
    name: .customLong("unsorted-keys"),
    help: "Do not sort object keys (default sorts for determinism).")
  var unsortedKeys: Bool = false

  @Flag(name: .customLong("quiet"), help: "Suppress per-file logs; print only errors.")
  var quiet: Bool = false

  func run() async throws {
    var options: JSONSerialization.WritingOptions = []
    if !unsortedKeys { options.insert(.sortedKeys) }
    if withoutEscapingSlashes { options.insert(.withoutEscapingSlashes) }

    let destURL = appendTo.map { URL(fileURLWithPath: $0) }
    if useStdin {
      try processStream(
        FileHandle.standardInput.readDataToEndOfFile(), options: options, destURL: destURL)
      return
    }

    let expanded = expandGlobs(globs)
    let inputs = Array(Set(files + expanded)).sorted()
    guard !inputs.isEmpty else {
      throw ValidationError("Provide --stdin or at least one --file/--glob")
    }
    for path in inputs { try processFile(path, options: options, destURL: destURL) }
  }

  // MARK: - Processing
  private func processFile(_ path: String, options: JSONSerialization.WritingOptions, destURL: URL?)
    throws
  {
    do {
      let data = try Data(contentsOf: URL(fileURLWithPath: path))
      try processStream(data, options: options, destURL: destURL)
      if !quiet, let dest = destURL {
        Log.main.info("ndjson: appended \(path) -> \(dest.path)")
      }
    } catch {
      Log.main.error("ndjson: \(path) failed — \(String(describing: error))")
    }
  }

  private func processStream(_ data: Data, options: JSONSerialization.WritingOptions, destURL: URL?)
    throws
  {
    let obj = try JSONSerialization.jsonObject(with: data)
    if let array = obj as? [Any] {
      try array.forEach { try emitObject($0, options: options, destURL: destURL) }
    } else {
      try emitObject(obj, options: options, destURL: destURL)
    }
  }

  private func emitObject(_ object: Any, options: JSONSerialization.WritingOptions, destURL: URL?)
    throws
  {
    if let dest = destURL {
      try JSON.NDJSON.appendJSONObjectLine(object, to: dest, options: options)
    } else {
      let line = try JSON.NDJSON.encodeJSONObjectLine(object, options: options)
      FileHandle.standardOutput.write(line)
    }
  }

  // MARK: - Globbing (copied from FormatJSON)
  func expandGlobs(_ patterns: [String]) -> [String] {
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
}
