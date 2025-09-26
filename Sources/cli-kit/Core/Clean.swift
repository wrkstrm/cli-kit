import ArgumentParser
import CommonShell
import Foundation
import Logging

struct Clean: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "clean",
    abstract: "Aggressively cleans Xcode/SPM caches for a clean rebuild.",
  )

  @Flag(help: "Also remove global SwiftPM caches (~/.swiftpm, Library Caches).")
  var global = false

  @Flag(help: "Resolve SPM dependencies after cleaning.")
  var resolve = true

  @Option(help: "Path to project root (defaults to current directory).")
  var path: String?

  mutating func run() async throws {
    var logger = Logger(label: "laussat.clean")
    logger.logLevel = .info

    let fm = FileManager.default
    let home = FileManager.default.homeDirectoryForCurrentUser.path
    let proj = path ?? FileManager.default.currentDirectoryPath

    func rm(_ p: String) {
      let expanded = (p as NSString).expandingTildeInPath
      if fm.fileExists(atPath: expanded) {
        _ = try? fm.removeItem(atPath: expanded)
        logger.info("Removed \(expanded)")
      }
    }

    logger.info("Closing Xcode before cleaning is recommended.")

    // Xcode user caches
    rm("\(home)/Library/Developer/Xcode/DerivedData")
    rm("\(home)/Library/Developer/Xcode/ModuleCache.noindex")

    if global {
      rm("\(home)/.swiftpm")
      rm("\(home)/Library/Caches/org.swift.swiftpm")
    }

    // Per-project artifacts
    rm("\(proj)/.build")
    rm("\(proj)/.swiftpm")
    rm("\(proj)/Package.resolved")  // force a fresh resolve

    // Optional: git clean to purge extra generated files
    _ = await shell("git", ["clean", "-xfd"], cwd: proj)

    if resolve {
      _ = await shell("xcodebuild", ["-resolvePackageDependencies"], cwd: proj)
    }

    logger.info("Clean complete.")
  }
}

@discardableResult
func shell(_ cmd: String, _ args: [String], cwd: String? = nil) async -> Int32 {
  let shell = CommonShell(workingDirectory: cwd ?? FileManager.default.currentDirectoryPath)
  do {
    let out = try await shell.withExec(reference: .name(cmd)).launch(options: args)
    switch out.exitStatus {
    case .exited(let code): return Int32(code)
    case .signalled(let sig): return Int32(sig)
    }
  } catch {
    return -1
  }
}
