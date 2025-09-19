import ArgumentParser
import CliKitConsoleTools
import Foundation

@main
struct CliKitText: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "swift-cli-kit-text",
    abstract: "Text utilities (ANSI strip, transcript clean)",
    subcommands: [StripANSIText.self, CleanTranscriptText.self],
  )
}

struct StripANSIText: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "strip-ansi",
    abstract: "Remove ANSI/OSC escape sequences, overstrikes, and CR updates",
  )
  @Option(name: .customLong("input"), help: "Input file path (default stdin)") var input: String?
  @Option(name: .customLong("output"), help: "Output file path (default stdout)") var output:
    String?
  func run() async throws {
    let data: Data =
      if let path = input {
        try Data(contentsOf: URL(fileURLWithPath: path))
      } else {
        FileHandle.standardInput.readDataToEndOfFile()
      }
    let text = String(data: data, encoding: .utf8) ?? String(decoding: data, as: UTF8.self)
    let out = CliKitConsoleTools.stripANSI(text)
    if let o = output {
      try out.write(toFile: o, atomically: true, encoding: .utf8)
    } else {
      FileHandle.standardOutput.write(Data(out.utf8))
    }
  }
}

struct CleanTranscriptText: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "transcript-clean",
    abstract: "Normalize Codex/CLI transcript and emit Markdown",
  )
  @Argument(help: "Transcript file path (raw or stripped)") var input: String
  @Option(name: .customLong("output"), help: "Output file path (default stdout)") var output:
    String?
  func run() async throws {
    let text = try String(contentsOfFile: input, encoding: .utf8)
    let lines = CliKitConsoleTools.cleanTranscriptLines(text)
    let body = lines.joined(separator: "\n")
    let md = "# Codex Transcript\n\n```text\n" + body + "\n```\n"
    if let o = output {
      try md.write(toFile: o, atomically: true, encoding: .utf8)
    } else {
      FileHandle.standardOutput.write(Data(md.utf8))
    }
  }
}
