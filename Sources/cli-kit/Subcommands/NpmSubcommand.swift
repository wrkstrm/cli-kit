import ArgumentParser

struct Npm: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "npm",
    abstract: "Forward minimal npm operations (stub)."
  )
  @Argument var args: [String] = []
  func run() throws { print("npm stub:", args.joined(separator: " ")) }
}
