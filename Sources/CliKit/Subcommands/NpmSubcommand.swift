import ArgumentParser
import BuildTools
import CommonProcess
import CommonShell
import Foundation

struct Npm: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "npm",
    abstract: "Invoke npm with repo defaults",
  )

  @Flag(help: "Enable npm funding prompts") var fund: Bool = false
  @Flag(help: "Enable npm audit") var audit: Bool = false
  @Argument(help: "Arguments to pass to npm") var args: [String] = []

  func run() async throws {
    let shell = CommonShell()
    let arguments =
      args + (fund ? ["--fund"] : ["--no-fund"]) + (audit ? ["--audit"] : ["--no-audit"])
    let out = try await shell.run(
      host: .env(options: []),
      executable: .name("npm"),
      arguments: arguments
    )
    if !out.isEmpty { print(out) }
  }
}
