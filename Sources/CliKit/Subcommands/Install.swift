import ArgumentParser
import Foundation

private let toolName = CliKit.configuration.commandName!

struct Install: ParsableCommand, ConfiguredShell {
  static let configuration =
    CommandConfiguration(
      abstract: "⬇️ | Installs this binary ('\(toolName)') or prints a command showing how to.",
      helpNames: .shortAndLong,
    )

  // MARK: - OptionGroups, Arguments, Options and Flags

  @OptionGroup var options: CliKit.Options

  func run() throws {
    let shell = try configuredShell()
//    switch shell.cp(from: toolName, to: "/usr/local/bin/\(toolName)") {
//    case .failure:
//      Log.main.info(
//        """
//        To install run the following command with sudo privileges:
//        sudo cp \(shell.printWorkingDirectory())/\(toolName) /usr/local/bin/\(toolName)
//        """,
//      )
//
//    case .success:
//      Log.main.info("Install completed.")
//    }
  }
}

struct Uninstall: ParsableCommand {
  static let configuration =
    CommandConfiguration(
      abstract: "⬆️ | Uninstalls this binary ('\(toolName)') or prints a command showing how to.",
      helpNames: .shortAndLong,
    )

  func run() throws {
//    switch RShell().remove(from: "/usr/local/bin/\(toolName)") {
//    case .failure:
//      Log.main.error(
//        """
//        To uninstall run with sudo privileges:
//        sudo \(toolName) uninstall
//        """,
//      )
//
//    default:
//      Log.main.info("Uninstall completed.")
//    }
  }
}
