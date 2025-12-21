# Unified Formatter: Usage

## Command

```
swift-cli-kit format --kind <json|md|swift>... [--file <path>]... [--glob <pattern>]... [--check] [--quiet]
```

- `--kind <json|md|swift>`: one or more kinds; repeat to combine in one run
- `--file <path>`: one or more input files
- `--glob <pattern>`: glob patterns like `**/*.json`, `**/*.md`, `**/*.swift`
- `--check`: detect drift without writing; exit 1 if changes are needed
- `--quiet`: reduce per-file logs
- `--swift-format-config <path>`: config for Swift; defaults to repo standard

## Examples

Format JSON + Markdown together:

```
swift-cli-kit format --kind json --kind md --glob "**/*.{json,md,mdx}"
```

Swift only (check mode):

```
swift-cli-kit format --kind swift --glob "code/**/*.swift" --check
```

JSON only (files):

```
swift-cli-kit format --kind json --file a.json --file b.json
```

## Notes

- JSON uses in-process canonical formatting (pretty, sorted keys, unescaped slashes).
- Markdown uses the in-process Swift formatter (line endings + trailing newline normalization).
- Swift delegates to `swift format` with the repo config by default.
- When `--check` is used, the command exits non-zero if any selected kind would change files.
- Exclusions: paths under `ai/imports/**` and `ai/exports/**` are ignored by default.
  Use `--include-ai` to override and format those directories.
