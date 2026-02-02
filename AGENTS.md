# AGENTS — Cli‑kit Notifications

## Shared Notifier

- Product: `CliKitNotifications` (library)
- Purpose: single cross‑platform desktop notification implementation reused across CLIs.
- API:
  - `DesktopNotification { title, message, subtitle?, sound?, urgency? }`
  - `DeliveryResult { platform, command, status, fallbackUsed }`
  - `WrkstrmCLINotify.send(_:) async -> DeliveryResult`
  - `WrkstrmCLINotify.json(_:) -> String`

### Transports

- macOS: AppleScript (`/usr/bin/osascript -e 'display notification …'`)
- Linux: `notify-send` via `/usr/bin/env notify-send`

### CLI Subcommand

- `swift-cli-kit notify "message" [--title …] [--subtitle …] [--sound …] [--urgency …] [--json]`
- Non‑JSON mode: silent on success; prints a concise failure line on non‑zero status.

### JSON Schema

```json
{
  "platform": "macOS|linux",
  "command": ["/usr/bin/osascript", "-e", "display notification …"],
  "status": 0,
  "fallbackUsed": false
}
```

### Integration Guidance

- Prefer calling the library API from Swift-based CLIs for zero subprocess overhead.
- Use the CLI subcommand (with `--json`) when integrating from shell scripts or other tools.
- Keep all transport and escaping logic inside the library; do not duplicate in consumers.

## Assistant Operating Mode

- Git command approval: do not run any `git` commands without explicit user approval
  (including but not limited to `clone`, `status`, `add`, `commit`, `reset`, `rebase`, `push`,
  `submodule`, `config`). Prefer reading workspace files over invoking `git` when possible.

## CLIA Canonicals and First Launch

- Canonical loaders: JSON triads under `.clia/agents/**`.
- Canonical MD (human): persona and system‑instructions alongside triads.
- Mirrors: `.generated/agent.md` is non‑canonical; use to validate rendering.
- Default agent: `^codex` unless an explicit agent load is requested via
  `>agentSlug` (e.g., `>clia`, `>carrie`).

Checklist

- `!sync` → reset, thin‑scan, determine scope; load triads; apply sandbox/approvals; announce mode.

Diverge paths

- If in submodule: stage a DocC request with diffs/rationale in parent repo.
- Use CommonShell/CommonProcess; avoid `Foundation.Process`.

DocC link: `code/.clia/docc/agents-onboarding.docc` (preview from repo root).
