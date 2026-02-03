// swift-tools-version:6.2
import Foundation
import PackageDescription

let supportedPlatforms: [SupportedPlatform] = [
  .iOS(.v15),
  .macOS(.v15),
  .macCatalyst(.v15),
]

let package = Package(
  name: "swift-cli-kit",
  platforms: supportedPlatforms,
  products: [
    .executable(name: "swift-cli-kit", targets: ["CLIKit"]),
    .executable(name: "cli-kit", targets: ["CLIKit"]),
    .library(name: "CLIKitNotifications", targets: ["CLIKitNotifications"]),
    .library(name: "TaskTimerCore", targets: ["TaskTimerCore"]),
  ],
  dependencies: Package.Inject.shared.dependencies + [
    .package(name: "swift-figlet-kit", path: "../../universal/domain/tooling/swift-figlet-kit"),
    .package(path: "../../../../../swift-universal/public/spm/universal/domain/tooling/swift-formatting-core"),
    .package(path: "../../../../../swift-universal/public/spm/universal/domain/tooling/swift-json-formatter"),
    .package(path: "../../../../../swift-universal/public/spm/universal/domain/tooling/swift-md-formatter"),
    .package(
      name: "WrkstrmIdentifierKit",
      path: "../../../../../wrkstrm/spm/cross/wrkstrm-identifier-kit"
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
        .product(name: "CommonShellArguments", package: "common-shell"),
        .product(name: "CommonShell", package: "common-shell"),
        .product(name: "CommonCLI", package: "common-cli"),
        .product(name: "WrkstrmMain", package: "wrkstrm-main"),
        .product(name: "WrkstrmFoundation", package: "wrkstrm-foundation"),
        .product(name: "SwiftFigletKit", package: "swift-figlet-kit"),
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
        .product(name: "CommonShell", package: "common-shell"),
        .product(name: "CommonCLI", package: "common-cli"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "Sources/build-tools",
    ),
    .target(
      name: "CLIKitNotifications",
      dependencies: [
        .product(name: "CommonShell", package: "common-shell")
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

    static var local: Inject = .init(
      swiftSettings: [.local],
      dependencies: [
        .package(
          path: "../../../../../swift-universal/public/spm/universal/domain/system/common-shell"
        ),
        .package(
          path: "../../../../../swift-universal/public/spm/universal/domain/system/common-cli"
        ),
        .package(name: "wrkstrm-main", path: "../../universal/domain/system/wrkstrm-main"),
        .package(name: "wrkstrm-foundation", path: "../../universal/domain/system/wrkstrm-foundation"),
      ]
    )

    static var remote: Inject = .init(
      dependencies: [
        .package(url: "https://github.com/swift-universal/common-shell.git", from: "0.0.1"),
        .package(url: "https://github.com/swift-universal/common-cli.git", from: "0.1.0"),
        .package(url: "https://github.com/wrkstrm/wrkstrm-main.git", from: "3.0.0"),
        .package(url: "https://github.com/wrkstrm/wrkstrm-foundation.git", from: "3.0.0"),
      ]
    )
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
    guard let raw = ProcessInfo.processInfo.environment["SPM_USE_LOCAL_DEPS"] else { return false }
    let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    return normalized == "1" || normalized == "true" || normalized == "yes"
  }
}

// PACKAGE_SERVICE_END_V0_0_1


// PACKAGE_SERVICE_START_V2_HASH:f21a2fab19fc20f3c87802dc7cff570f105851fa039aa0cd5e7c3c26440c1640
extension Package {
  @MainActor
  public struct Inject {
    public static let version = "2.0.0"

    public var swiftSettings: [SwiftSetting] = []
    var dependencies: [PackageDescription.Package.Dependency] = []

    public static let shared: Inject = ProcessInfo.useLocalDeps ? .local : .remote

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
    guard let raw = ProcessInfo.processInfo.environment["SPM_USE_LOCAL_DEPS"] else { return false }
    let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    return normalized == "1" || normalized == "true" || normalized == "yes"
  }
}
// PACKAGE_SERVICE_END_V2_HASH:{