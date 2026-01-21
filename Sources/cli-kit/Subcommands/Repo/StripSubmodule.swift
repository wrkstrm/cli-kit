import ArgumentParser
import CommonCLI
import CommonProcess
import CommonProcessExecutionKit
import CommonShell
import Foundation
import Logging
import CommonLog

/// Strip everything but a subdirectory into a new Git repository (history-preserving)
/// and optionally add it back as a submodule.
struct StripSubmodule: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "strip-submodule",
    _superCommandName: "repo",
    abstract:
      "Clone and filter a subtree (phase 1), optionally remove the original directory (phase 2), and optionally add it back as a submodule (phase 3). Dry-run by default."
  )

  enum Phase: String, CaseIterable, ExpressibleByArgument {
    case cloneStrip = "clone-strip"
    case remove = "remove"
    case add = "add"
  }

  // Inputs
  @Option(name: .customLong("subtree-path"), help: "Path to the subtree root inside the monorepo.")
  var subtreePath: String

  @Option(
    name: .customLong("remote"),
    help: "Remote URL for the new repository (required for clone-strip or add phases).")
  var remoteURL: String?

  @Option(
    name: .customLong("branch"), help: "Branch to track/add for the submodule (default: main)")
  var branch: String = "main"

  @Option(name: .customLong("tmp-dir"), help: "Temporary directory for the split repo.")
  var tmpDir: String = "/tmp/cli-kit-subtree-split"

  // Behavior flags
  @Flag(
    name: .customLong("add-submodule"),
    help: "Deprecated: use --phases add. After pushing, add the submodule at the same path.")
  var addSubmodule: Bool = false

  @Flag(name: .customLong("push"), help: "Push the split repository to the remote URL.")
  var push: Bool = false

  @Flag(
    name: .customLong("no-history"),
    help: "Create a new repository without preserving history (copy files only, initial commit).")
  var noHistory: Bool = false

  @Flag(
    name: .customLong("write"), help: "Execute changes (otherwise just print planned commands).")
  var write: Bool = false

  @Option(
    name: .customLong("phases"), parsing: .upToNextOption,
    help:
      "Phases to run (repeatable). Allowed values: clone-strip, remove, add. Default: clone-strip; when --add-submodule is set, defaults to all three."
  )
  var phases: [Phase] = []

  private static let logger = Logger(label: "cli-kit.repo.strip-submodule")

  func validate() throws {
    let phasesToRun = effectivePhases()
    if phasesToRun.contains(where: { $0 == .cloneStrip || $0 == .add }) {
      if (remoteURL ?? "").isEmpty {
        throw ValidationError("--remote is required for phases: clone-strip and add")
      }
    }
    if phasesToRun.isEmpty {
      throw ValidationError("No phases selected; specify --phases or rely on defaults")
    }
    if !phasesToRun.contains(.cloneStrip), push {
      // Non-fatal behavior note; help the operator
      Self.logger.warning("--push has no effect without the clone-strip phase; ignoring flag")
    }
  }

  // MARK: - Implementation

  func run() async throws {
    // Resolve absolute subtree path and detect the owning repository root by starting from the subtree directory
    let resolution = try await resolveRepoAndPaths()
    let repoRoot = resolution.repoRoot
    let relSubtree = resolution.relSubtree
    let shell = CommonShell(workingDirectory: repoRoot)

    // Preflight checks
    try await ensureGitAvailable(shell)
    try ensurePaths(repoRoot: repoRoot, absoluteSubtree: resolution.absSubtree)
    try await warnIfNoTrackedFiles(repoRoot: repoRoot, relSubtree: relSubtree)

    // Plan commands using paths relative to the owning repo root
    let phasesToRun = effectivePhases()
    // Safety: when both remove and add are requested together, perform deletion-only now
    // and instruct the operator to run a separate invocation for the add phase. This avoids
    // edge cases where a submodule is added atop an uncommitted removal, causing path churn
    // or content duplication.
    let phasesForExecution: [Phase] = {
      if phasesToRun.contains(.remove) && phasesToRun.contains(.add) {
        Self.logger.notice(
          "Requested phases include both 'remove' and 'add'. Running deletion-only now; rerun with phase 'add' after review."
        )
        return phasesToRun.filter { $0 != .add }
      }
      return phasesToRun
    }()

    let plan = buildPlan(cwd: repoRoot, relSubtree: relSubtree, phases: phasesForExecution)
    printPlan(plan)

    guard write else {
      print("\n[DRY-RUN] Use --write to execute. Nothing changed.")
      return
    }

    // Execute
    try await execute(plan: plan, shell: shell)
  }

  private func ensurePaths(repoRoot: String, absoluteSubtree: String) throws {
    // Validate that the subtree exists on disk
    let absolute = absoluteSubtree
    var isDir: ObjCBool = false
    guard FileManager.default.fileExists(atPath: absolute, isDirectory: &isDir), isDir.boolValue
    else {
      throw CliKitError.message(
        "subtree-path not found or not a directory: \(subtreePath) under repo root: \(repoRoot)")
    }
  }

  private func ensureGitAvailable(_ shell: CommonShell) async throws {
    // Ensure `git` exists
    _ = try await CommonShell(workingDirectory: shell.workingDirectory, executable: .name("git"))
      .launch(options: ["--version"])  // throws if missing
    // Soft check for `git filter-repo`; if missing, we still allow dry-run.
    do {
      _ = try await CommonShell(workingDirectory: shell.workingDirectory, executable: .name("git"))
        .launch(options: ["filter-repo", "--help"])
    } catch {
      if write {
        throw CliKitError.message(
          "git filter-repo is required when --write is set. See https://github.com/newren/git-filter-repo"
        )
      }
    }
  }

  /// Detects the repository root using `git rev-parse --show-toplevel` starting at `start`.
  private func detectRepoRoot(start: String) async throws -> String {
    let shell = CommonShell(workingDirectory: start)
    let out = try await shell.git.run(["rev-parse", "--show-toplevel"])  // stdout contains path with trailing newline
    let root = out.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !root.isEmpty else {
      throw CliKitError.message("Failed to detect repository root (empty output)")
    }
    return root
  }

  private func buildPlan(cwd: String, relSubtree: String, phases: [Phase]) -> [CommandSpec] {
    var specs: [CommandSpec] = []
    for phase in phases {
      switch phase {
      case .cloneStrip:
        specs += buildCloneStripPlan(cwd: cwd, relSubtree: relSubtree)
      case .remove:
        specs += buildRemovePlan(cwd: cwd, relSubtree: relSubtree)
      case .add:
        specs += buildAddPlan(cwd: cwd, relSubtree: relSubtree)
      }
    }
    return specs
  }

  private func buildCloneStripPlan(cwd: String, relSubtree: String) -> [CommandSpec] {
    let tmp = (tmpDir as NSString).expandingTildeInPath
    let path = relSubtree
    let remote = remoteURL ?? ""
    var specs: [CommandSpec] = []
    specs.append(Rm.rm(path: tmp, options: [.recursive, .force], workingDirectory: cwd))

    if noHistory {
      // No-history mode: copy files into a fresh repo and make an initial commit.
      // 1) mkdir -p <tmp>
      specs.append(
        CommandSpec(executable: .name("mkdir"), args: ["-p", tmp], workingDirectory: cwd))
      // 2) rsync -a <cwd>/<relSubtree>/ <tmp>
      let source = path.hasSuffix("/") ? path : path + "/"
      specs.append(
        CommandSpec(executable: .name("rsync"), args: ["-a", source, tmp], workingDirectory: cwd))
      // 3) git init, add, commit, remote add
      specs.append(CommandSpec(executable: .name("git"), args: ["init"], workingDirectory: tmp))
      specs.append(
        CommandSpec(executable: .name("git"), args: ["add", "."], workingDirectory: tmp))
      specs.append(
        CommandSpec(
          executable: .name("git"), args: ["commit", "-m", "submodule initialization"],
          workingDirectory: tmp))
      specs.append(Git.remoteAdd(name: "origin", url: remote, workingDirectory: tmp))
      if push {
        specs.append(Git.pushAll(setUpstream: true, remote: "origin", workingDirectory: tmp))
        specs.append(Git.pushTags(setUpstream: true, remote: "origin", workingDirectory: tmp))
      }
      return specs
    }

    // History-preserving mode: clone + filter-repo
    specs.append(
      Git.clone(
        noLocal: true, noHardlinks: true, source: cwd, destination: tmp, workingDirectory: cwd))
    specs.append(Git.filterRepoSubdirectory(subdirectory: path, force: true, workingDirectory: tmp))
    specs.append(Git.remoteRemove(name: "origin", workingDirectory: tmp))
    specs.append(Git.remoteAdd(name: "origin", url: remote, workingDirectory: tmp))
    if push {
      specs.append(Git.pushAll(setUpstream: true, remote: "origin", workingDirectory: tmp))
      specs.append(Git.pushTags(setUpstream: true, remote: "origin", workingDirectory: tmp))
    }
    return specs
  }

  private func buildRemovePlan(cwd: String, relSubtree: String) -> [CommandSpec] {
    var specs: [CommandSpec] = []
    // 1) Stage deletion from Git history and remove from working tree
    specs.append(Git.rm(recursive: true, path: relSubtree, workingDirectory: cwd))
    // 2) Ensure the directory is gone from the filesystem (safety for ignored/untracked files)
    specs.append(Rm.rm(path: relSubtree, options: [.recursive, .force], workingDirectory: cwd))
    return specs
  }

  private func buildAddPlan(cwd: String, relSubtree: String) -> [CommandSpec] {
    let remote = remoteURL ?? ""
    return [Git.submoduleAdd(branch: branch, url: remote, path: relSubtree, workingDirectory: cwd)]
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
      _ = try await RunnerControllerFactory.run(command: s)
    }
  }

  // MARK: - Repo/path resolution helpers

  private func resolveRepoAndPaths() async throws -> (
    repoRoot: String, relSubtree: String, absSubtree: String
  ) {
    // Make absolute subtree path based on current directory if needed
    let cwd = FileManager.default.currentDirectoryPath
    let absSubtree: String = {
      if subtreePath.hasPrefix("/") { return subtreePath }
      return URL(fileURLWithPath: cwd).appendingPathComponent(subtreePath).standardizedFileURL.path
    }()
    // Detect owning repo root by starting at the subtree directory
    let subtreeDir = absSubtree
    let repoRoot = try await detectRepoRoot(start: subtreeDir)
    // Compute relative path to use with filter-repo and git commands
    let rel = URL(fileURLWithPath: absSubtree).path.replacingOccurrences(
      of: URL(fileURLWithPath: repoRoot).standardizedFileURL.path + "/", with: "")
    return (repoRoot: repoRoot, relSubtree: rel, absSubtree: absSubtree)
  }

  private func effectivePhases() -> [Phase] {
    if !phases.isEmpty { return phases }
    // Back-compat default: clone-strip only; when legacy --add-submodule is set, run all three
    return addSubmodule ? [.cloneStrip, .remove, .add] : [.cloneStrip]
  }

  private func warnIfNoTrackedFiles(repoRoot: String, relSubtree: String) async throws {
    let shell = CommonShell(workingDirectory: repoRoot)
    let out = try? await shell.git.run(["ls-files", "--", relSubtree])
    if (out ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      Self.logger.warning(
        "No tracked files under \(relSubtree) in repo \(repoRoot); filter-repo will produce an empty history unless commits exist"
      )
    }
  }
}
