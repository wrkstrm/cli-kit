import ArgumentParser

struct Text: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "text",
    abstract: "Text utilities (ANSI stripping, transcript cleaning, intros)",
    subcommands: [StripANSI.self, CleanTranscript.self, Intro.self]
  )
}
