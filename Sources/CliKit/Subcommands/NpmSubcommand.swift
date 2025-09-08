import ArgumentParser
import BuildTools
import Foundation
import SwiftShell

struct Npm: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "npm",
    abstract: "Invoke npm with repo defaults"
  )

  @Flag(help: "Enable npm funding prompts") var fund: Bool = false
  @Flag(help: "Enable npm audit") var audit: Bool = false
  @Argument(help: "Arguments to pass to npm") var args: [String] = []

  func run() async throws {
    let shell = CShell(
      cli: "/usr/bin/env", options: ["npm"], reprintCommand: false, bashWrapper: false)
    let npm = NpmCLIWrapper(shell: shell)
    let out = try npm.run(
      args + (fund ? ["--fund"] : ["--no-fund"]) + (audit ? ["--audit"] : ["--no-audit"]))
    if !out.isEmpty { print(out) }
  }
}
