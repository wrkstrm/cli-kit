import ArgumentParser
import CliKitConsoleTools
import Foundation

struct StripANSI: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "strip-ansi",
    abstract: "Remove ANSI/OSC escape sequences, overstrikes, and CR updates",
  )

  @Option(name: .customLong("input"), help: "Input file path (default stdin)") var input: String?
  @Option(name: .customLong("output"), help: "Output file path (default stdout)") var output:
    String?

  func run() throws {
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
