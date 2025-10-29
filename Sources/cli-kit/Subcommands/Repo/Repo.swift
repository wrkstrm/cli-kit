import ArgumentParser

struct Repo: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "repo",
    _superCommandName: "swift-cli-kit",
    abstract: "Repository utilities (split subtrees, manage submodules).",
  subcommands: [StripSubmodule.self]
  )

  func run() throws {
    // Intentionally empty: acts as a namespace for subcommands.
  }
}
