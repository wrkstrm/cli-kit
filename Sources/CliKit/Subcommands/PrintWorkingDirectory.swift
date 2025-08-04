import ArgumentParser
import CommonShell
import Foundation
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
    //    let directory = try configuredShell().printWorkingDirectory()
    #if os(Linux)
      print(directory)
    #endif  // os(Linux)
  }
}
