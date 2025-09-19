import ArgumentParser
import BuildTools
import Foundation

struct Xcodebuild: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "xcodebuild",
    abstract: "xcodebuild operations",
    subcommands: [List.self, Build.self, Clean.self],
  )

  struct Common: ParsableArguments {
    @Option(name: [.customLong("workspace"), .short], help: "Path to .xcworkspace") var workspace:
      String
    @Flag(help: "Emit JSON output where applicable") var json = false
  }

  struct List: AsyncParsableCommand {
    @OptionGroup var common: Common
    @MainActor
    func run() async throws {
      let xc = XcodeBuildCLIWrapper()
      if let jsonOut = try? await xc.listWorkspaceJSON(common.workspace),
        !jsonOut.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      {
        print(jsonOut)
      } else {
        let text = try await xc.listWorkspaceText(common.workspace)
        if common.json {
          let j = ["text": text]
          let data = try JSONSerialization.data(withJSONObject: j)
          print(String(data: data, encoding: .utf8)!)
        } else {
          print(text)
        }
      }
    }
  }

  struct Build: AsyncParsableCommand {
    @OptionGroup var common: Common
    @Option(name: [.customLong("scheme"), .short]) var scheme: String
    @Option(name: .customLong("platform")) var platform: String = "macOS"
    @MainActor
    func run() async throws {
      let xc = XcodeBuildCLIWrapper()
      let dests = destinations(for: platform)
      var built = false
      for d in dests {
        if await (try? xc.build(workspace: common.workspace, scheme: scheme, destination: d)) != nil
        {
          if common.json {
            let payload: [String: Any] = ["scheme": scheme, "destination": d, "status": "ok"]
            let data = try JSONSerialization.data(withJSONObject: payload)
            print(String(data: data, encoding: .utf8)!)
          } else {
            print("ok: \(scheme) (\(d))")
          }
          built = true
          break
        } else {
          fputs("retry next destination...\n", stderr)
        }
      }
      if !built { throw ExitCode.failure }
    }
  }

  struct Clean: AsyncParsableCommand {
    @OptionGroup var common: Common
    @Option(name: [.customLong("scheme"), .short]) var scheme: String
    @MainActor
    func run() async throws {
      let xc = XcodeBuildCLIWrapper()
      _ = try await xc.clean(workspace: common.workspace, scheme: scheme)
    }
  }
}

private func destinations(for platforms: String) -> [String] {
  let set = Set(platforms.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })
  var out: [String] = []
  if set.contains("macOS") || set.contains("all") || set.isEmpty {
    out += ["generic/platform=macOS", "platform=macOS,arch=arm64"]
  }
  if set.contains("macCatalyst") || set.contains("all") {
    out += ["platform=macOS,arch=arm64,variant=Mac Catalyst"]
  }
  if set.contains("iOS") || set.contains("all") {
    out += ["platform=iOS Simulator,name=iPhone 15", "generic/platform=iOS"]
  }
  return out
}
