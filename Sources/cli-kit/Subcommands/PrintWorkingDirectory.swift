import ArgumentParser
import Foundation

struct PWD: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "pwd",
    abstract: "Print working directory"
  )
  func run() async throws { print(FileManager.default.currentDirectoryPath) }
}
