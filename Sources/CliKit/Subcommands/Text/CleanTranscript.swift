import ArgumentParser
import Foundation
import CliKitConsoleTools

struct CleanTranscript: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "transcript-clean",
    abstract: "Normalize Codex/CLI transcript and emit Markdown"
  )

  @Argument(help: "Transcript file path (raw or stripped)") var input: String
  @Option(name: .customLong("output"), help: "Output file path (default stdout)") var output: String?

  func run() throws {
    let text = try String(contentsOfFile: input, encoding: .utf8)
    let lines = CliKitConsoleTools.cleanTranscriptLines(text)
    let body = lines.joined(separator: "\n")
    let md = "# Codex Transcript\n\n```text\n" + body + "\n```\n"
    if let o = output { try md.write(toFile: o, atomically: true, encoding: .utf8) }
    else { FileHandle.standardOutput.write(Data(md.utf8)) }
  }
}
