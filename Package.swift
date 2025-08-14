import Foundation
// swift-tools-version:6.1
import PackageDescription

let package = Package(
  name: "cli-kit",
  platforms: [.macOS(.v14)],
  products: [
    // Products define the executables and libraries produced by a package, and make them visible to
    // other packages.
    .executable(name: "cli-kit", targets: ["CliKit"])
  ],
  dependencies: [
    .package(name: "CommonCommands", path: "../CommonCommands"),
    .package(name: "CommonShell", path: "../CommonShell"),
    .package(
      url: "https://github.com/apple/swift-argument-parser.git",
      from: "1.6.0"
    ),
    .package(url: "https://github.com/apple/swift-log.git", from: "1.6.0"),
  ],
  targets: [
    .executableTarget(
      name: "CliKit",
      dependencies: [
        .product(name: "CommonCommands", package: "CommonCommands"),
        .product(name: "CommonShell", package: "CommonShell"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "Logging", package: "swift-log"),
      ],
    ),
    .testTarget(
      name: "ToolboxTests",
      dependencies: [
        "CliKit",
      ]
    ),
  ],
)

// MARK: - Package Service

print("---- Package Inject Deps: Begin ----")
print("Use Local Deps? \(ProcessInfo.useLocalDeps)")
print(Package.Inject.shared.dependencies.map(\.kind))
print("---- Package Inject Deps: End ----")

extension Package {
  @MainActor
  public struct Inject {
    public static let version = "0.0.1"

    public var swiftSettings: [SwiftSetting] = []
    var dependencies: [PackageDescription.Package.Dependency] = []

    public static let shared: Inject =
      ProcessInfo.useLocalDeps ? .local : .remote

    static var local: Inject = .init(swiftSettings: [.localSwiftSettings])
    static var remote: Inject = .init()
  }
}

// MARK: - PackageDescription extensions

extension SwiftSetting {
  public static let localSwiftSettings: SwiftSetting = .unsafeFlags([
    "-Xfrontend",
    "-warn-long-expression-type-checking=10",
  ])
}

// MARK: - Foundation extensions

extension ProcessInfo {
  public static var useLocalDeps: Bool {
    ProcessInfo.processInfo.environment["SPM_USE_LOCAL_DEPS"] == "true"
  }
}

// PACKAGE_SERVICE_END_V0_0_1
