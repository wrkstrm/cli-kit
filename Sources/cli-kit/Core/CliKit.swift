import ArgumentParser
import Foundation

@main
struct CliKit: AsyncParsableCommand {
  static let configuration = { () -> CommandConfiguration in
    var commands: [ParsableCommand.Type] = [
      Install.self, Uninstall.self,
      Refactor.self,
      Compare.self, CompareReport.self,
      Identifiers.self,
      RandomCharacters.self,
      PWD.self,
    ]
    #if os(macOS)
    commands += [ExtractSDEF.self]
    #endif  // os(macOS)
    // Text utilities and helpers
    commands += [Text.self, Time.self, Notify.self, TaskTimerCommand.self, JSONTools.self, Format.self]
    return CommandConfiguration(
      commandName: "swift-cli-kit",
      abstract: "Wrkstrm CLI kit for common developer tooling.",
      subcommands: commands,
      defaultSubcommand: RandomCharacters.self,
      helpNames: .shortAndLong,
    )
  }()

  @OptionGroup var options: Self.Options

  func run() throws {
    if options.verbose {
      Log.main.info("Running Swift CLI Kit in verbose mode.")
    }
  }
}
