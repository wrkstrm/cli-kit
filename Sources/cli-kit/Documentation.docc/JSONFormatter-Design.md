# JSON Formatter: Engineering Design

## Requirements

- Single policy for human‑friendly JSON (pretty, sorted, readable URLs)
- Safe in‑place writes (atomic), or mirror to a destination directory
- CI‑friendly check mode; non‑zero exit on drift
- Globbing support for large repos; stdin/stdout for pipelines
- Minimal dependencies; reuse WrkstrmMain.JSON namespace + WrkstrmFoundation

## Architecture

- Policy lives in `WrkstrmFoundation`, bridged via `WrkstrmMain.JSON`:
  - `JSON.Formatting` and `JSON.FileWriter`
- CLI glue in `swift-cli-kit`: `json format` subcommand
  - expands `--glob` patterns (Darwin glob(3), fallback fnmatch)
  - reads JSON → applies policy → writes atomically
  - in check mode, compares normalized output without writing

## Trade‑offs

- We keep the policy strictly human‑friendly; for compact machine output, use dedicated tool flags elsewhere, not this command.
- The fallback glob implementation aims to be practical, not perfect; we document behavior and prefer the Darwin path on macOS.

## Future Enhancements

- HTML diff mode per file (side‑by‑side) for review UIs
- Normalization beyond formatting (stable arrays, field canonicalization) behind an explicit `--fix` flag
- Configurable include/exclude sets for triad sweeps
