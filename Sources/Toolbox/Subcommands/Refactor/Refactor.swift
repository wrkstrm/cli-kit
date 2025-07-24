import ArgumentParser
import Foundation
import Logging

extension Log {
  fileprivate static let refactor = { () -> Logger in
    Logger(label: "toolbox.refactor")
  }()
}

extension Refactor {
  typealias Info = (partialResult: String, step: Step, resolvedSearchPaths: [String])
}

struct Refactor: ParsableCommand, ConfiguredShell {
  // MARK: - Static Variables

  nonisolated(unsafe) static let fileManager = FileManager.default

  static let decoder = JSONDecoder()

  // MARK: - CommandConfiguration

  static let configuration: CommandConfiguration =
    .init(
      abstract: "🍲| Runs a refactor recipe.",
      helpNames: .shortAndLong,
    )

  // MARK: - OptionGroups, Arguments, Options and Flags

  @OptionGroup var options: Toolbox.Options

  @Argument(help: "The recipe to run.")
  var recipePath: String

  @Option
  var searchPaths: [String] = [
    ""
  ]

  // MARK: - Output Creatation Literals

  var resolvedSearchPaths: [String] {
    let workingDirectory = options.workingDirectory
    return searchPaths.map { workingDirectory + $0 }
  }

  // MARK: -

  mutating func run() throws {
    guard let stepData = try? Data(contentsOf: URL(fileURLWithPath: recipePath, isDirectory: true))
    else {
      throw "Could not load data from url: \(recipePath)"
    }
    guard let steps = try? Self.decoder.decode([Step].self, from: stepData) else {
      throw "Could not decode step array."
    }
    let reductionResult = try? reduce(steps: steps)
    if options.verbose {
      Log.refactor.info("\(String(describing: reductionResult))")
    }
  }
}
