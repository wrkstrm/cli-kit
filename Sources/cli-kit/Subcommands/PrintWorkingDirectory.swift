import ArgumentParser

struct PWD: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "pwd",
    abstract: "Print working directory"
  )
  func run() throws { print(FileManager.default.currentDirectoryPath) }
}
