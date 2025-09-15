import Foundation
import CommonShell

public struct NpmCLIWrapper {
  public var shell: CommonShell
  public init(shell: CommonShell = .init(executablePath: "/usr/bin/env", options: ["npm"])) {
    self.shell = shell
  }
  @discardableResult
  @MainActor
  public func run(_ args: [String]) throws -> String {
    let r = try shell.launch(options: args)
    return (try? r.utf8Output()) ?? ""
  }
  @MainActor
  public func version() throws -> String { try run(["--version"]) }
}
