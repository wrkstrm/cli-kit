// swift-tools-version:6.1
import PackageDescription

let package = Package(
  name: "Toolbox",
  platforms: [.macOS(.v14)],
  products: [
    // Products define the executables and libraries produced by a package, and make them visible to
    // other packages.
    .executable(name: "tb", targets: ["Toolbox"])
  ],
  dependencies: [
    .package(name: "CommonCommands", path: "../CommonCommands"),
    .package(name: "CommonShell", path: "../CommonShell"),
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
    .package(url: "https://github.com/apple/swift-log.git", from: "1.5.3"),
  ],
  targets: [
    .executableTarget(
      name: "Toolbox",
      dependencies: [
        .product(name: "CommonCommands", package: "CommonCommands"),
        .product(name: "CommonShell", package: "CommonShell"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "Logging", package: "swift-log"),
      ]
    ),
    .testTarget(
      name: "ToolboxTests",
      dependencies: ["Toolbox"]
    ),
  ]
)
