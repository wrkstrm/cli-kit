// swift-tools-version:5.10
import PackageDescription

let package = Package(
  name: "Toolbox",
  platforms: [.macOS(.v12)],
  products: [
    // Products define the executables and libraries produced by a package, and make them visible to
    // other packages.
    .executable(name: "tb", targets: ["Toolbox"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.3"),
    .package(url: "https://github.com/apple/swift-log.git", from: "1.5.3"),
  ],
  targets: [
    .executableTarget(
      name: "Toolbox",
      dependencies: [
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
