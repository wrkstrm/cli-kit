import Foundation

public struct XcodeBuildCLIWrapper {
  public init() {}

  public func listWorkspaceJSON(_ path: String) async throws -> String? {
    // Placeholder: In test/CI environments without Xcode, return nil
    return nil
  }

  public func listWorkspaceText(_ path: String) async throws -> String {
    return "xcodebuild listing is not available in this environment (no-op)"
  }

  public func build(workspace: String, scheme: String, destination: String) async throws -> String {
    return "build invoked for scheme=\(scheme), destination=\(destination) (no-op)"
  }

  public func clean(workspace: String, scheme: String) async throws -> String {
    return "clean invoked for scheme=\(scheme) (no-op)"
  }
}
