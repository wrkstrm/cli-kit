import ArgumentParser
import CommonCLI
import CommonShell
import Foundation

/// Squash a day's worth of commits on a branch into a single commit.
///
/// Safety defaults:
/// - Dry-run by default (prints the planned steps).
/// - Requires `--write` to execute and `--push` to update the remote.
/// - Uses `--force-with-lease` when pushing rewritten history.
struct SquashDaily: AsyncParsableCommand, ConfiguredShell {
  static let configuration = CommandConfiguration(
    commandName: "squash-daily",
    _superCommandName: "repo",
    abstract: "Squash a day's commits on a branch into one commit (dry-run by default)."
  )

  // MARK: - Options

  @OptionGroup var options: CliKit.Options

  @Option(name: .customLong("branch"), help: "Target branch to squash.")
  var branch: String = "main"

  @Option(name: .customLong("remote"), help: "Remote to use when fetching/pushing.")
  var remote: String = "origin"

  @Option(
    name: .customLong("since"),
    help: "Lower bound for commit time window (git accepts values like 'midnight', '2025-11-12 00:00')."
  )
  var since: String = "midnight"

  @Option(
    name: .customLong("before"),
    help: "Upper bound for commit time window (optional)."
  )
  var before: String?

  @Option(name: .customLong("author"), help: "Optional author filter for commits in the window.")
  var author: String?

  @Option(name: .customLong("message"), help: "Commit message for the squashed commit.")
  var message: String?

  @Flag(name: .customLong("allow-dirty"), help: "Allow running with a dirty working tree.")
  var allowDirty: Bool = false

  @Flag(name: .customLong("write"), help: "Execute changes (otherwise just print planned steps).")
  var write: Bool = false

  @Flag(name: .customLong("push"), help: "Push the rewritten branch to the remote with --force-with-lease.")
  var push: Bool = false

  // MARK: - Run

  func run() async throws {
    let shell = try configuredShell()
    let git = shell.git

    // Ensure git is available by reading current branch
    _ = try await git.currentBranch()

    // Fetch latest refs
    _ = try await git.fetch(remote: remote, refspec: nil, prune: false, tags: false)

    let remoteRef = "\(remote)/\(branch)"

    // Resolve first commit since the given time window (and optional before boundary)
    var revArgs = [
      "rev-list", "--first-parent", "--reverse",
      "--since=\(since)",
    ]
    if let before, !before.isEmpty {
      revArgs.append("--before=\(before)")
    }
    if let author, !author.isEmpty {
      revArgs.append("--author=\(author)")
    }
    revArgs.append(remoteRef)

    let revOutput = try await git.run(revArgs)
    let firstCommit = revOutput
      .split(separator: "\n", omittingEmptySubsequences: true)
      .first.map(String.init) ?? ""

    guard !firstCommit.isEmpty else {
      print("No commits found on \(remoteRef) since=\(since)\(before.map { ", before=\($0)" } ?? "").")
      return
    }

    // Determine parent of the first commit (base for soft reset)
    let parentsLine = try await git.run(["rev-list", "--parents", "-n", "1", firstCommit]).trimmingCharacters(in: .whitespacesAndNewlines)
    let parts = parentsLine.split(separator: " ").map(String.init)
    guard parts.count >= 2 else {
      throw CliKitError.message("First commit in range appears to be a root commit; refusing to squash from repository root.")
    }
    let base = parts[1]  // parent SHA

    // Verify cleanliness unless explicitly allowed
    if !allowDirty {
      let status = try await git.status(porcelain: true).trimmingCharacters(in: .whitespacesAndNewlines)
      if !status.isEmpty {
        throw CliKitError.message("Working tree not clean. Stash/commit or pass --allow-dirty.")
      }
    }

    // Prepare commit message
    let commitMessage: String = {
      if let message, !message.isEmpty { return message }
      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy-MM-dd"
      let today = formatter.string(from: Date())
      let window = before.map { "\(since) .. \($0)" } ?? since
      return "squash(\(today)): \(window) on \(branch)"
    }()

    // Build plan description
    var plan: [String] = []
    plan.append("git fetch \(remote)")
    plan.append("git checkout \(branch)")
    plan.append("git pull \(remote) \(branch) --ff-only")
    plan.append("git reset --soft \(base)")
    plan.append("git commit -m \"\(commitMessage)\"")
    if push { plan.append("git push --force-with-lease \(remote) \(branch)") }

    print("Plan (dry-run=\(!write)):")
    for (i, step) in plan.enumerated() {
      print(String(format: "  %2d. %@", i + 1, step))
    }

    guard write else { return }

    // Execute the plan
    _ = try await git.checkout(branch)
    _ = try await git.pull(remote: remote, branch: branch, rebase: false)
    _ = try await git.run(["reset", "--soft", base])
    _ = try await git.run(["commit", "-m", commitMessage])
    if push {
      _ = try await git.run(["push", "--force-with-lease", remote, branch])
    }
  }
}

