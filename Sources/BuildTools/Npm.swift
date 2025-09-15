import Foundation
import CommonShell

public struct NpmCLIWrapper {
  public var shell: CommonShell
  public init(shell: CommonShell = .init(cli: "/usr/bin/env", options: ["npm"])) {
    self.shell = shell
    self.shell.bashWrapper = false
  }
  @discardableResult
  public func run(_ args: [String]) throws -> String {
    let r = try shell.launch(options: args)
    return (try? r.utf8Output()) ?? ""
  }
  public func version() throws -> String { try run(["--version"]) }
}
