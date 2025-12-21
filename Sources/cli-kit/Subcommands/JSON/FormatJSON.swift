import ArgumentParser
import Foundation
import SwiftFormattingCore
import SwiftJSONFormatter
import WrkstrmLog

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

  @Flag(
    name: .customLong("include-ai"),
    help: "Include ai/imports and ai/exports paths (excluded by default)."
  )
  var includeAI: Bool = false

  func run() async throws {
    if useStdin {
      guard !check && writeTo == nil else {
        throw ValidationError("--stdin cannot be combined with --check or --write-to")
      }
      let data = FileHandle.standardInput.readDataToEndOfFile()
      let formatted = try SwiftJSONFormatter.formatStdin(data)
      FileHandle.standardOutput.write(formatted)
      FileHandle.standardOutput.write("\n".data(using: .utf8)!)
      return
    }

    let inputs = try FormattingInputs(files: files, globs: globs, includeAI: includeAI)
      .resolve(defaultGlobs: [])

    let result = SwiftJSONFormatter.format(
      paths: inputs,
      check: check,
      writeTo: writeTo,
      emit: { event in
        switch event {
        case .wouldChange(let path):
          if !quiet { Log.main.info("json: would change \(path)") }
        case .formatted(let path, let destination):
          guard !quiet else { return }
          if let destination {
            Log.main.info("json: formatted \(path) -> \(destination)")
          } else {
            Log.main.info("json: formatted \(path)")
          }
        case .error(let path, let error):
          Log.main.error("json: error formatting \(path): \(String(describing: error))")
        }
      }
    )

    if check {
      if !quiet { Log.main.info("\(result.changedCount) file(s) would change") }
      if result.changedCount > 0 { throw ExitCode(1) }
    } else if !quiet {
      Log.main.notice("json: done. errors=\(result.errorCount)")
    }
  }
}
