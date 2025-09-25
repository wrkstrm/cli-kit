import ArgumentParser

struct Install: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "install",
    abstract: "Install tools (stub)."
  )
  func run() throws { print("install: not yet implemented") }
}

struct Uninstall: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "uninstall",
    abstract: "Uninstall tools (stub)."
  )
  func run() throws { print("uninstall: not yet implemented") }
}
