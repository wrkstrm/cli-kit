import ArgumentParser

struct JSONTools: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "json",
    abstract: "JSON utilities (formatting)",
    subcommands: [FormatJSON.self, NDJSONTool.self]
  )
}
