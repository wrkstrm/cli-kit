import ArgumentParser
import Foundation

@main
struct CliKit: AsyncParsableCommand {
  static let configuration = { () -> CommandConfiguration in
    var commands: [ParsableCommand.Type] = [
      Install.self, Uninstall.self,
      Refactor.self,
      Compare.self, CompareReport.self,
      RandomCharacters.self,
      PWD.self,
    ]
#if os(macOS)
    commands += [Notify.self]
#endif  // os(macOS)
    // Text utilities
    commands += [StripANSI.self, CleanTranscript.self]
    return CommandConfiguration(
      commandName: "tb",
      abstract: "A collection of command line tools for iOS developers. 🧰",
      subcommands: commands,
      defaultSubcommand: RandomCharacters.self,
      helpNames: .customLong("h"),
    )
  }()

  @OptionGroup var options: Self.Options

  func run() throws {
    if options.verbose {
      Log.main.info("Running Toolbox in verbose mode.")
    }
  }
}
