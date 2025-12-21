# The Solution

We centralized the JSON policy in WrkstrmFoundation and exposed it through the WrkstrmMain `JSON` namespace:

- `JSON.Formatting.humanEncoder` — `JSONEncoder` preset with `prettyPrinted`, `sortedKeys`, and `withoutEscapingSlashes`, using ISO‑8601 millis for dates.
- `JSON.Formatting.humanOptions` — `JSONSerialization.WritingOptions` with the same flags.
- `JSON.FileWriter.write` / `writeJSONObject` — atomic writes; creates parent directories as needed.

The `swift-cli-kit` JSON formatter wraps this policy so teams can normalize existing files quickly:

- Format explicit files, glob patterns (including `**`), or stream stdin → stdout.
- In‑place edits (atomic) or mirror to a separate folder for side‑by‑side review.
- Check mode for CI: detect diffs without writing; exit non‑zero if anything would change.
