import ArgumentParser

struct Npm: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "npm",
    abstract: "Forward minimal npm operations (stub)."
  )
  @Argument var args: [String] = []
  func run() async throws { print("npm stub:", args.joined(separator: " ")) }
}
