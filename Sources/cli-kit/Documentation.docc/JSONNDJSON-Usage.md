# JSON NDJSON Usage

The `json ndjson` subcommand converts JSON into newline‑delimited JSON (NDJSON): one compact JSON
object per line, each line ending with a single trailing newline (`\n`). Arrays are expanded to
multiple records.

## Quick start

```bash
# From stdin -> stdout (single object)
echo '{"a":1}' | swift run --package-path code/mono/apple/spm/clis/cli-kit cli-kit json ndjson --stdin

# From stdin where root is an array -> two lines
echo '[{"x":1},{"x":2}]' | swift run --package-path code/mono/apple/spm/clis/cli-kit cli-kit json ndjson --stdin

# Files and globs
swift run --package-path code/mono/apple/spm/clis/cli-kit cli-kit json ndjson \
  --file data.json \
  --glob "**/*.json"

# Append to a file instead of stdout
echo '{"a":1}' | swift run --package-path code/mono/apple/spm/clis/cli-kit cli-kit json ndjson \
  --stdin --append-to out.ndjson
```

## Flags

- `--file <path>` (repeatable): explicit input file(s)
- `--glob <pattern>` (repeatable): expand glob patterns (supports `**` on Darwin)
- `--stdin`: read a single JSON payload from stdin
- `--append-to <file>`: append output lines to a file (creates parents if needed)
- `--without-escaping-slashes`: pass through `/` unescaped (applies to `JSONObject` inputs)
- `--unsorted-keys`: do not sort keys (default sorts keys for deterministic output)
- `--quiet`: suppress per-file logs; print only errors

## Behavior

- Emits compact JSON; no pretty printing. Each record ends with exactly one trailing newline.
- Root `array` inputs produce multiple output lines (one per element).
- String newlines in the source (e.g., `"hello\nworld"`) remain escaped as `\\n`, keeping each
  record on a single line.
- By default, object keys are sorted for deterministic output. Enable `--unsorted-keys` to retain
  original order when the input parser preserves it.
- Use `--without-escaping-slashes` to improve readability of URLs in object-based inputs.

## Foundation dependency

This command delegates encoding to WrkstrmFoundation’s `JSON.NDJSON` helpers:

- `JSON.NDJSON.encodeJSONObjectLine(_:)` / `appendJSONObjectLine(_:,to:)`
- For `Encodable` types in Swift programs, prefer `JSON.NDJSON.encodeLine(_:)` from
  WrkstrmFoundation for the same single‑line guarantees.
