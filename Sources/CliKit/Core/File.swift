import Foundation
import ArgumentParser
import Foundation
import Logging

struct Clean: ParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "clean",
    abstract: "Aggressively cleans Xcode/SPM caches for a clean rebuild."
  )

  @Flag(help: "Also remove global SwiftPM caches (~/.swiftpm, Library Caches).")
  var global = false

  @Flag(help: "Resolve SPM dependencies after cleaning.")
  var resolve = true

  @Option(help: "Path to project root (defaults to current directory).")
  var path: String?

  mutating func run() throws {
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
    rm("\(proj)/Package.resolved") // force a fresh resolve

    // Optional: git clean to purge extra generated files
    _ = shell("git", ["clean", "-xfd"], cwd: proj)

    if resolve {
      _ = shell("xcodebuild", ["-resolvePackageDependencies"], cwd: proj)
    }

    logger.info("Clean complete.")
  }
}

@discardableResult
func shell(_ cmd: String, _ args: [String], cwd: String? = nil) -> Int32 {
  let task = Process()
  task.launchPath = "/usr/bin/env"
  task.arguments = [cmd] + args
  if let cwd { task.currentDirectoryPath = cwd }
  task.launch()
  task.waitUntilExit()
  return task.terminationStatus
}
