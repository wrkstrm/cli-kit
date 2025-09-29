import ArgumentParser
import Foundation

/// Prints the current time in a selected format.
struct Now: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "now",
    abstract: "Print the current time in the requested format."
  )

  enum Format: String, ExpressibleByArgument, CaseIterable {
    case iso8601
  }

  @Option(name: .customLong("format"), help: "Output format (e.g., iso8601)")
  var format: Format = .iso8601

  func run() async throws {
    switch format {
    case .iso8601:
      let ts = ISO8601DateFormatter().string(from: Date())
      print(ts)
    }
  }
}
