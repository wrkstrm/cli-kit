import ArgumentParser
import Foundation
import CommonShell
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

  @OptionGroup var options: Toolbox.Options

  func run() throws {
//    let directory = try configuredShell().printWorkingDirectory()
    #if os(Linux)
      print(directory)
    #endif  // os(Linux)
  }
}

