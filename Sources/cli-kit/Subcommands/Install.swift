import ArgumentParser

struct Install: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "install",
    abstract: "Install tools (stub)."
  )
  func run() async throws { print("install: not yet implemented") }
}

struct Uninstall: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "uninstall",
    abstract: "Uninstall tools (stub)."
  )
  func run() async throws { print("uninstall: not yet implemented") }
}
