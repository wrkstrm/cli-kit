# Tutorial: Normalize Triads Safely

Agent triads (agent.json, agency.json, agenda.json) are human‑reviewed artifacts. This walkthrough shows how to mirror formatted triads to a staging directory for side‑by‑side review, verify changes, and then apply them safely.

## 1) Build the CLI once

```
swift build --package-path code/mono/apple/spm/clis/cli-kit -c release
```

## 2) Mirror formatted triads (root repo triads)

Create a mirrored copy of formatted files under a staging directory; originals remain untouched:

```
code/mono/apple/spm/clis/cli-kit/.build/release/cli-kit \
  json format \
  --glob ".clia/agents/**/*.json" \
  --write-to .clia/tmp/triads-formatted
```

## 3) Mirror mono triads (submodules/projects)

```
code/mono/apple/spm/clis/cli-kit/.build/release/cli-kit \
  json format \
  --glob "code/mono/**/.clia/agents/**/*.json" \
  --write-to .clia/tmp/triads-formatted-mono
```

## 4) Review diffs side‑by‑side

Use your favorite diff tool to compare originals vs formatted mirrors. Example with `diff`:

```
# Root triads
(diff -ru .clia/agents .clia/tmp/triads-formatted || true) | less

# Mono triads
(diff -ru code/mono .clia/tmp/triads-formatted-mono || true) | less
```

Tips:

- Focus on key triad sets (recently edited agents) first.
- Expect changes to be whitespace/key‑order only if the content was already valid JSON.

## 5) Dry‑run check (optional)

To see if anything is out of policy without writing files:

```
code/mono/apple/spm/clis/cli-kit/.build/release/cli-kit \
  json format \
  --glob ".clia/agents/**/*.json" \
  --check --quiet
```

Repeat for mono triads as needed.

## 6) Apply in place (when ready)

Once differences are reviewed and approved, format in place:

```
# Root triads (in place)
code/mono/apple/spm/clis/cli-kit/.build/release/cli-kit \
  json format --glob ".clia/agents/**/*.json"

# Mono triads (in place)
code/mono/apple/spm/clis/cli-kit/.build/release/cli-kit \
  json format --glob "code/mono/**/.clia/agents/**/*.json"
```

## Notes

- Policy is strictly human‑friendly: `prettyPrinted` + `sortedKeys` + `withoutEscapingSlashes`.
- Writes are atomic; parent directories are created as needed.
- For larger sweeps, prefer smaller PRs per area (e.g., per agent family or per project).
- If a triad fails to parse as JSON, the formatter will surface an error. Fix content first, then re‑run.
