import ArgumentParser
import CommonShell
import Foundation
import TSCBasic

struct PWD: AsyncParsableCommand, ConfiguredShell {
  static let configuration =
    CommandConfiguration(
      abstract: "🖨️ | Prints the working directory.",
      shouldDisplay: false,
      helpNames: .shortAndLong,
    )

  // MARK: - OptionGroups, Arguments, Options and Flags

  @OptionGroup var options: CliKit.Options

  func run() async throws {
    print(FileManager.default.currentDirectoryPath)
  }
}
