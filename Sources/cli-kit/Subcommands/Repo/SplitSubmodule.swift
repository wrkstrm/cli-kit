import ArgumentParser
import CommonCLI
import CommonProcess
import CommonProcessExecutionKit
import CommonShell
import Foundation

/// Split a subtree into a new Git repository (history-preserving) and optionally add it back as a submodule.
struct SplitSubmodule: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "split-submodule",
    _superCommandName: "repo",
    abstract: "Split a path (subtree) with git filter-repo and add as submodule (dry-run by default)."
  )

  // Inputs
  @Option(name: .customLong("subtree-path"), help: "Path to the subtree root inside the monorepo.")
  var subtreePath: String

  @Option(name: .customLong("remote"), help: "Remote URL for the new repository.")
  var remoteURL: String

  @Option(name: .customLong("branch"), help: "Branch to track/add for the submodule (default: main)")
  var branch: String = "main"

  @Option(name: .customLong("tmp-dir"), help: "Temporary directory for the split repo.")
  var tmpDir: String = "/tmp/cli-kit-subtree-split"

  // Behavior flags
  @Flag(name: .customLong("add-submodule"), help: "After pushing, add the submodule at the same path.")
  var addSubmodule: Bool = false

  @Flag(name: .customLong("push"), help: "Push the split repository to the remote URL.")
  var push: Bool = false

  @Flag(name: .customLong("write"), help: "Execute changes (otherwise just print planned commands).")
  var write: Bool = false

  // MARK: - Implementation

  func run() async throws {
    // Detect the repository root using git so commands run at the correct place
    let start = FileManager.default.currentDirectoryPath
    let repoRoot = try await detectRepoRoot(start: start)
    let shell = CommonShell(workingDirectory: repoRoot)

    // Preflight checks
    try await ensureGitAvailable(shell)
    try ensurePaths(repoRoot: repoRoot)

    // Plan commands
    let plan = buildPlan(cwd: repoRoot)
    printPlan(plan)

    guard write else {
      print("\n[DRY-RUN] Use --write to execute. Nothing changed.")
      return
    }

    // Execute
    try await execute(plan: plan, shell: shell)
  }

  private func ensurePaths(repoRoot: String) throws {
    // Validate that the subtree exists under the detected repo root
    let absolute = URL(fileURLWithPath: repoRoot).appendingPathComponent(subtreePath).path
    var isDir: ObjCBool = false
    guard FileManager.default.fileExists(atPath: absolute, isDirectory: &isDir), isDir.boolValue else {
      throw CliKitError.message("subtree-path not found or not a directory: \(subtreePath) under repo root: \(repoRoot)")
    }
  }

  private func ensureGitAvailable(_ shell: CommonShell) async throws {
    // Ensure `git` exists
    _ = try await CommonShell(workingDirectory: shell.workingDirectory, executable: .name("git")).launch(options: ["--version"]) // throws if missing
    // Soft check for `git filter-repo`; if missing, we still allow dry-run.
    do {
      _ = try await CommonShell(workingDirectory: shell.workingDirectory, executable: .name("git")).launch(options: ["filter-repo", "--help"])
    } catch {
      if write {
        throw CliKitError.message("git filter-repo is required when --write is set. See https://github.com/newren/git-filter-repo")
      }
    }
  }

  /// Detects the repository root using `git rev-parse --show-toplevel` starting at `start`.
  private func detectRepoRoot(start: String) async throws -> String {
    var shell = CommonShell(workingDirectory: start)
    let out = try await shell.git.run(["rev-parse", "--show-toplevel"]) // stdout contains path with trailing newline
    let root = out.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !root.isEmpty else { throw CliKitError.message("Failed to detect repository root (empty output)") }
    return root
  }

  private func buildPlan(cwd: String) -> [CommandSpec] {
    let tmp = (tmpDir as NSString).expandingTildeInPath
    let path = (subtreePath as NSString).expandingTildeInPath
    let remote = remoteURL

    var specs: [CommandSpec] = []
    // Clean tmp dir
    specs.append(Rm.rm(path: tmp, options: [.recursive, .force], workingDirectory: cwd))
    // Clone a fresh copy to avoid rewriting the working tree
    specs.append(Git.clone(noLocal: true, noHardlinks: true, source: cwd, destination: tmp, workingDirectory: cwd))
    // Run filter-repo in the temp clone
    specs.append(Git.filterRepo(path: path, pathRename: "\(path):", force: true, workingDirectory: tmp))
    // Point to remote and push (optional)
    specs.append(Git.remoteRemove(name: "origin", workingDirectory: tmp))
    specs.append(Git.remoteAdd(name: "origin", url: remote, workingDirectory: tmp))
    if push {
      specs.append(Git.pushAll(setUpstream: true, remote: "origin", workingDirectory: tmp))
      specs.append(Git.pushTags(setUpstream: true, remote: "origin", workingDirectory: tmp))
    }
    if addSubmodule {
      // Remove subtree and add submodule at the same path in the monorepo
      specs.append(Git.rm(recursive: true, path: path, workingDirectory: cwd))
      specs.append(Git.submoduleAdd(branch: branch, url: remote, path: path, workingDirectory: cwd))
    }
    return specs
  }

  private func printPlan(_ specs: [CommandSpec]) {
    print("Plan (\(specs.count) steps):")
    for (i, s) in specs.enumerated() {
      let wd = s.workingDirectory ?? "."
      let cmd: String = {
        switch s.executable.ref {
        case .name(let n): return n
        case .path(let p): return p
        case .none: return s.args.first ?? ""
        }
      }()
      let argv = ([cmd] + s.args).joined(separator: " ")
      print(String(format: "  %2d. (cd %@) %@", i + 1, wd, argv))
    }
  }

  private func execute(plan: [CommandSpec], shell _: CommonShell) async throws {
    for s in plan {
      _ = try await RunnerControllerFactory.run(invocation: s)
    }
  }
}
