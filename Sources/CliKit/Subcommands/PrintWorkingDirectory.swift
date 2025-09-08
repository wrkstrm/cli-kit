import ArgumentParser
import Foundation
import SwiftShell
import TSCBasic
import WrkstrmLog

struct PWD: ParsableCommand, ConfiguredShell {
  static let configuration =
    CommandConfiguration(
      abstract: "🖨️ | Prints the working directory.",
      shouldDisplay: false,
      helpNames: .shortAndLong,
    )

  // MARK: - OptionGroups, Arguments, Options and Flags

  @OptionGroup var options: CliKit.Options

  func run() throws {
    let directory = try configuredShell().printWorkingDirectory()
    print(directory)
  }
}
