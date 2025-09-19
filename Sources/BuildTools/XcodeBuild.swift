import CommonProcess
import CommonShell
import Foundation

@MainActor
public struct XcodeBuildCLIWrapper {
  public var shell: CommonShell
  public init(shell: CommonShell = .init(executable: .name("xcodebuild"))) {
    self.shell = shell
  }

  @MainActor
  public func listWorkspaceJSON(_ workspace: String) async throws -> String {
    let r = try await shell.launch(options: ["-list", "-json", "-workspace", workspace])
    return (try? r.utf8Output()) ?? ""
  }

  @MainActor
  public func listWorkspaceText(_ workspace: String) async throws -> String {
    let r = try await shell.launch(options: ["-list", "-workspace", workspace])
    return (try? r.utf8Output()) ?? ""
  }

  @MainActor
  public func build(
    workspace: String, scheme: String, destination: String, configuration: String = "Debug",
    extra: [String] = [],
  ) async throws -> String {
    var args = [
      "-workspace", workspace, "-scheme", scheme, "-destination", destination, "-configuration",
      configuration, "-quiet", "-skipPackagePluginValidation", "build",
    ]
    args.append(contentsOf: extra)
    let r = try await shell.launch(options: args)
    return (try? r.utf8Output()) ?? ""
  }

  @MainActor
  public func clean(workspace: String, scheme: String) async throws -> String {
    let r = try await shell.launch(options: ["-workspace", workspace, "-scheme", scheme, "clean"])
    return (try? r.utf8Output()) ?? ""
  }
}
