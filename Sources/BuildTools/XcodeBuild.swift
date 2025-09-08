import SwiftShell
import Foundation

public struct XcodeBuildCLIWrapper {
  public var shell: SwiftShell
  public init(shell: SwiftShell = .init(cli: "xcodebuild")) {
    self.shell = shell
  }
  public func listWorkspaceJSON(_ workspace: String) async throws -> String {
    let r = try shell.launch(options: ["-list", "-json", "-workspace", workspace])
    return (try? r.utf8Output()) ?? ""
  }
  public func listWorkspaceText(_ workspace: String) async throws -> String {
    let r = try shell.launch(options: ["-list", "-workspace", workspace])
    return (try? r.utf8Output()) ?? ""
  }
  public func build(
    workspace: String, scheme: String, destination: String, configuration: String = "Debug",
    extra: [String] = []
  ) async throws -> String {
    var args = [
      "-workspace", workspace, "-scheme", scheme, "-destination", destination, "-configuration",
      configuration, "-quiet", "-skipPackagePluginValidation", "build",
    ]
    args.append(contentsOf: extra)
    let r = try shell.launch(options: args)
    return (try? r.utf8Output()) ?? ""
  }
  public func clean(workspace: String, scheme: String) async throws -> String {
    let r = try shell.launch(options: ["-workspace", workspace, "-scheme", scheme, "clean"])
    return (try? r.utf8Output()) ?? ""
  }
}
