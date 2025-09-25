// swift-tools-version:6.1
import Foundation
import PackageDescription

let supportedPlatforms: [SupportedPlatform] = [
  .iOS(.v15),
  .macOS(.v15),
  .macCatalyst(.v15),
]

let package = Package(
  name: "cli-kit",
  platforms: supportedPlatforms,
  products: [
    .executable(name: "swift-cli-kit", targets: ["CLIKit"]),
    .library(name: "CLIKitNotifications", targets: ["CLIKitNotifications"]),
  ],
  dependencies: [
    .package(
      name: "CommonShell",
      path: "../../universal/common/domain/system/common-shell"
    ),
    .package(
      name: "CommonCLI",
      path: "../../universal/common/domain/system/common-cli"
    ),
    .package(name: "WrkstrmMain", path: "../../universal/WrkstrmMain"),
    .package(name: "SwiftFigletKit", path: "../../universal/SwiftFigletKit"),
    .package(name: "clia", path: "../../universal/domain/ai/clia"),
    .package(
      name: "IdentifierKit",
      path: "../../../../../spm/tools/identifier-kit"
    ),
    .package(
      url: "https://github.com/apple/swift-argument-parser.git",
      from: "1.6.0",
    ),
    .package(url: "https://github.com/apple/swift-log.git", from: "1.6.0"),
  ],
  targets: [
    .executableTarget(
      name: "CLIKit",
      dependencies: [
        "BuildTools",
        "CLIKitConsoleTools",
        "CLIKitNotifications",
        .product(name: "IdentifierKit", package: "IdentifierKit"),
        .product(
          name: "IdentifierKitArgumentParserSupport",
          package: "IdentifierKit"
        ),
        .product(name: "CommonShellArguments", package: "CommonShell"),
        .product(name: "CommonShell", package: "CommonShell"),
        .product(name: "CommonCLI", package: "CommonCLI"),
        .product(name: "WrkstrmMain", package: "WrkstrmMain"),
        .product(name: "SwiftFigletKit", package: "SwiftFigletKit"),
        .product(name: "CLIATaskTimer", package: "clia"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "Logging", package: "swift-log"),
      ],
      path: "sources/cli-kit",
    ),
    .target(
      name: "BuildTools",
      dependencies: [
        .product(name: "CommonShell", package: "CommonShell"),
        .product(name: "CommonCLI", package: "CommonCLI"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "sources/build-tools",
    ),
    .target(
      name: "CLIKitNotifications",
      dependencies: [
        .product(name: "CommonShell", package: "CommonShell")
      ],
      path: "sources/cli-kit-notifications",
    ),
    .target(
      name: "CLIKitConsoleTools",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser")
      ],
      path: "sources/cli-kit-console-tools",
    ),
    .testTarget(
      name: "CLIKitTests",
      dependencies: [
        "CLIKit"
      ],
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

    static var local: Inject = .init(swiftSettings: [.local])
    static var remote: Inject = .init()
  }
}

// MARK: - PackageDescription extensions

extension SwiftSetting {
  public static let local: SwiftSetting = .unsafeFlags([
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
