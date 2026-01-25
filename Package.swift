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
    .executable(name: "cli-kit", targets: ["CLIKit"]),
    .library(name: "CLIKitNotifications", targets: ["CLIKitNotifications"]),
    .library(name: "TaskTimerCore", targets: ["TaskTimerCore"]),
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
    .package(name: "wrkstrm-main", path: "../../universal/domain/system/wrkstrm-main"),
    .package(name: "wrkstrm-foundation", path: "../../universal/domain/system/wrkstrm-foundation"),
    .package(name: "SwiftFigletKit", path: "../../universal/domain/tooling/swift-figlet-kit"),
    .package(path: "../../universal/tooling/swift-formatting-core"),
    .package(path: "../../universal/tooling/swift-json-formatter"),
    .package(path: "../../universal/tooling/swift-md-formatter"),
    .package(
      name: "WrkstrmIdentifierKit",
      path: "../../cross/wrkstrm-identifier-kit"
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
        "CLIKitNotifications",
        .product(name: "WrkstrmIdentifierKit", package: "WrkstrmIdentifierKit"),
        .product(
          name: "WrkstrmIdentifierKitArgumentParserSupport",
          package: "WrkstrmIdentifierKit"
        ),
        .product(name: "CommonShellArguments", package: "CommonShell"),
        .product(name: "CommonShell", package: "CommonShell"),
        .product(name: "CommonCLI", package: "CommonCLI"),
        .product(name: "WrkstrmMain", package: "wrkstrm-main"),
        .product(name: "WrkstrmFoundation", package: "wrkstrm-foundation"),
        .product(name: "SwiftFigletKit", package: "SwiftFigletKit"),
        .product(name: "SwiftFormattingCore", package: "swift-formatting-core"),
        .product(name: "SwiftJSONFormatter", package: "swift-json-formatter"),
        .product(name: "SwiftMDFormatter", package: "swift-md-formatter"),
        "TaskTimerCore",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "Logging", package: "swift-log"),
      ],
      path: "Sources/cli-kit",
    ),
    .target(
      name: "TaskTimerCore",
      dependencies: [
        .product(name: "WrkstrmFoundation", package: "wrkstrm-foundation")
      ],
      path: "Sources/task-timer-core"
    ),
    .target(
      name: "BuildTools",
      dependencies: [
        .product(name: "CommonShell", package: "CommonShell"),
        .product(name: "CommonCLI", package: "CommonCLI"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "Sources/build-tools",
    ),
    .target(
      name: "CLIKitNotifications",
      dependencies: [
        .product(name: "CommonShell", package: "CommonShell")
      ],
      path: "Sources/cli-kit-notifications",
    ),
    .testTarget(
      name: "CLIKitTests",
      dependencies: ["TaskTimerCore"],
      path: "Tests/cli-kit-tests"
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
