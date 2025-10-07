# JSON Formatter: Usage

## Command

```
swift-cli-kit json format [--file <path>]... [--glob <pattern>]... [--write-to <dir>] [--check] [--quiet]
```

- `--file <path>`: one or more JSON files
- `--glob <pattern>`: glob patterns like `**/*.json` (repeatable)
- `--write-to <dir>`: mirror formatted files to a destination directory
- `--check`: detect drift without writing; exit 1 on changes
- `--quiet`: suppress per-file logs
- `--stdin`: read JSON from stdin and write formatted JSON to stdout

## Examples

Format specific files in place:

```
swift-cli-kit json format --file a.json --file b.json
```

Format by glob and mirror to a review folder (originals untouched):

```
swift-cli-kit json format --glob "**/*.json" --write-to .wrkstrm/tmp/formatted
```

Check only (CI-friendly):

```
swift-cli-kit json format --glob ".clia/agents/**/*.json" --check --quiet
```

Stream format:

```
cat data.json | swift-cli-kit json format --stdin
```

## Notes

- Policy is fixed: prettyPrinted + sortedKeys + withoutEscapingSlashes
- Atomic writes reduce partial state in case of interruptions
- `--stdin` is mutually exclusive with `--check` and `--write-to`

