import ArgumentParser

struct Time: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "time",
    abstract: "Time utilities (current timestamp, formatting)",
    subcommands: [Now.self]
  )
}

