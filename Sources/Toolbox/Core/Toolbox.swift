import ArgumentParser
import Foundation

@main
struct Toolbox: ParsableCommand {
  static let configuration = { () -> CommandConfiguration in
    var commands: [ParsableCommand.Type] = [
      Install.self, Uninstall.self,
      Refactor.self,
      Compare.self, CompareReport.self,
      PWD.self,
    ]
    #if os(macOS)
    commands += [GM.self, Notify.self]
    #endif  // os(macOS)
    return CommandConfiguration(
      commandName: "tb",
      abstract: "A collection of command line tools for iOS developers. 🧰",
      subcommands: commands,
      defaultSubcommand: Refactor.self,
      helpNames: .customLong("h")
    )
  }()

  @OptionGroup var options: Toolbox.Options

  func run() throws {
    if options.verbose {
      Log.main.info("Running Toolbox in verbose mode.")
    }
  }
}
