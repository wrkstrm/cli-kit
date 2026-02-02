# Repo Squash Daily — Usage

Squash a full day's worth of commits on a branch into a single commit.

This command is part of Swift CLI Kit and uses CommonShell/CommonCLI to invoke Git. It defaults to
dry‑run for safety and requires explicit flags to make changes.

## Command

```
swift-cli-kit repo squash-daily [options]
```

## Safety Defaults

- Dry-run by default: prints the planned steps and exits.
- Requires `--write` to execute local history rewrite.
- Requires `--push` to update the remote; uses `--force-with-lease` for safety.
- Verifies a clean working tree unless `--allow-dirty` is provided.

## Options

- `--branch <name>`: target branch (default: `main`).
- `--remote <name>`: remote to fetch/push (default: `origin`).
- `--since <time>`: lower time bound (default: `midnight`; accepts Git times like
  `2025-11-12 00:00`).
- `--before <time>`: optional upper time bound.
- `--author <pattern>`: optional author filter for commits.
- `--message <text>`: custom commit message (defaults to a dated summary).
- `--allow-dirty`: skip clean working tree check.
- `--write`: execute the squash locally.
- `--push`: push the rewritten branch via `--force-with-lease`.

## Examples

Preview today’s squash on `main` (no changes):

```bash
swift run --package-path code/mono/orgs/wrkstrm/public/spm/clis/swift-cli-kit \
  swift-cli-kit repo squash-daily
```

Execute local squash (no push):

```bash
swift run --package-path code/mono/orgs/wrkstrm/public/spm/clis/swift-cli-kit \
  swift-cli-kit repo squash-daily --write
```

Specific date window and push to remote:

```bash
swift run --package-path code/mono/orgs/wrkstrm/public/spm/clis/swift-cli-kit \
  swift-cli-kit repo squash-daily \
  --since '2025-11-12 00:00' --before '2025-11-13 00:00' \
  --write --push
```

Filter to your commits only:

```bash
swift run --package-path code/mono/orgs/wrkstrm/public/spm/clis/swift-cli-kit \
  swift-cli-kit repo squash-daily \
  --author "$(git config user.name)" --write
```

## How it Works

1. Fetches `origin/<branch>` and finds the first commit since `--since` (optionally `--before` and
   `--author`).
2. Computes the parent of that commit as the reset base.
3. Performs `git reset --soft <base>` and commits the staged diff as one commit.
4. Optionally pushes with `git push --force-with-lease <remote> <branch>` when `--push` is set.

## Undo (Safety Net)

If you executed the squash locally and want to undo before pushing, use the reflog to reset:

```bash
git reflog
git reset --hard HEAD@{1}
```

If you already pushed, coordinate with your team before rewriting again.

## Notes

- Rewriting shared branch history should be coordinated with branch protections and team norms.
- The implementation uses CommonShell/CommonCLI; Foundation.Process is not used.
- Self-hosted runners can use this via `swift run` invocations in CI, but consider human gating for
  history-rewriting operations.
