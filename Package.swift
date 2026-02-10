// swift-tools-version:6.2
import Foundation
import PackageDescription

let useLocalDeps: Bool = {
  guard let raw = ProcessInfo.processInfo.environment["SPM_USE_LOCAL_DEPS"] else { return false }
  let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
  return normalized == "1" || normalized == "true" || normalized == "yes"
}()

func localOrRemote(name: String, path: String, url: String, from version: Version) -> Package.Dependency {
  if useLocalDeps { return .package(name: name, path: path) }
  return .package(name: name, url: url, from: version)
}

func localOrRemote(path: String, url: String, from version: Version) -> Package.Dependency {
  if useLocalDeps { return .package(path: path) }
  return .package(url: url, from: version)
}

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
  dependencies: [
    localOrRemote(
      name: "common-shell",
      path: "../../../../../swift-universal/public/spm/universal/domain/system/common-shell",
      url: "https://github.com/swift-universal/common-shell.git",
      from: "0.0.1"
    ),
    localOrRemote(
      name: "common-cli",
      path: "../../../../../swift-universal/public/spm/universal/domain/system/common-cli",
      url: "https://github.com/swift-universal/swift-common-cli.git",
      from: "0.1.0"
    ),
    localOrRemote(
      name: "wrkstrm-main",
      path: "../../universal/domain/system/wrkstrm-main",
      url: "https://github.com/wrkstrm/wrkstrm-main.git",
      from: "3.0.0"
    ),
    localOrRemote(
      name: "wrkstrm-foundation",
      path: "../../universal/domain/system/wrkstrm-foundation",
      url: "https://github.com/wrkstrm/wrkstrm-foundation.git",
      from: "3.0.0"
    ),
    localOrRemote(
      name: "swift-figlet-kit",
      path: "../../universal/domain/tooling/swift-figlet-kit",
      url: "https://github.com/wrkstrm/swift-figlet-kit.git",
      from: "1.0.0"
    ),
    localOrRemote(
      path: "../../../../../swift-universal/public/spm/universal/domain/tooling/swift-formatting-core",
      url: "https://github.com/swift-universal/swift-formatting-core.git",
      from: "0.1.0"
    ),
    localOrRemote(
      name: "swift-json-formatter",
      path: "../../../../../swift-universal/public/spm/universal/domain/tooling/swift-json-formatter",
      url: "https://github.com/swift-universal/swift-json-formatter.git",
      from: "0.1.0"
    ),
    useLocalDeps
      ? .package(
        name: "swift-md-formatter",
        path: "../../../../../swift-universal/public/spm/universal/domain/tooling/swift-md-formatter"
      )
      : .package(
        url: "https://github.com/swift-universal/swift-md-formatter.git",
        branch: "main"
      ),
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
