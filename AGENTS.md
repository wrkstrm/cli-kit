# AGENTS — cli‑kit Notifications

## Shared notifier

- Product: `WrkstrmCLI_Notifications` (library)
- Purpose: single cross‑platform desktop notification implementation reused across CLIs.
- API:
  - `DesktopNotification { title, message, subtitle?, sound?, urgency? }`
  - `DeliveryResult { platform, command, status, fallbackUsed }`
  - `WrkstrmCLINotify.send(_:) async -> DeliveryResult`
  - `WrkstrmCLINotify.json(_:) -> String`

### Transports

- macOS: AppleScript (`/usr/bin/osascript -e 'display notification …'`)
- Linux: `notify-send` via `/usr/bin/env notify-send`

### CLI subcommand

- `cli-kit notify "message" [--title …] [--subtitle …] [--sound …] [--urgency …] [--json]`
- Non‑JSON mode: silent on success; prints a concise failure line on non‑zero status.

### JSON schema

```json
{
  "platform": "macOS|linux",
  "command": ["/usr/bin/osascript", "-e", "display notification …"],
  "status": 0,
  "fallbackUsed": false
}
```

### Integration guidance

- Prefer calling the library API from Swift-based CLIs for zero subprocess overhead.
- Use the CLI subcommand (with `--json`) when integrating from shell scripts or other tools.
- Keep all transport and escaping logic inside the library; do not duplicate in consumers.
