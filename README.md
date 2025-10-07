# Swift CLI Kit

Swift CLI Kit is a small toolbox of developer commands built on Wrkstrm’s CommonShell/CommonCLI. It also provides public utilities that follow our JSON formatting policy (human‑friendly, deterministic, atomic writes).

## Random strings and emoji

Generate random characters:

```bash
swift run --package-path code/mono/apple/spm/clis/cli-kit swift-cli-kit random --length 6 --kind ascii
```

Generate a random emoji from curated sets (status, momentum, work, conventions/all):

```bash
swift run --package-path code/mono/apple/spm/clis/cli-kit swift-cli-kit random \
  --kind emoji --category conventions --length 1
```

## What’s New

### JSON formatter (human‑friendly)

Format JSON files with a single, consistent policy (prettyPrinted + sortedKeys + withoutEscapingSlashes). Supports globs, check mode, and stdin/stdout.

```bash
# In‑place files
swift run --package-path code/mono/apple/spm/clis/cli-kit cli-kit json format \
  --file path/to/a.json --file path/to/b.json

# Mirror to review dir (originals untouched)
swift run --package-path code/mono/apple/spm/clis/cli-kit cli-kit json format \
  --glob "**/*.json" --write-to .wrkstrm/tmp/formatted

# Check only (CI)
swift run --package-path code/mono/apple/spm/clis/cli-kit cli-kit json format \
  --glob ".clia/agents/**/*.json" --check --quiet

# Stream format
cat data.json | swift run --package-path code/mono/apple/spm/clis/cli-kit cli-kit json format --stdin
```

Docs:
- JSON formatter usage: code/mono/apple/spm/clis/cli-kit/sources/cli-kit/Documentation.docc/JSONFormatter-Usage.md
- Design & Problem/Solution: see the other JSONFormatter docs in the same DocC bundle
