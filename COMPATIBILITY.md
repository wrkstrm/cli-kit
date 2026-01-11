# Cli-kit Compatibility Shims (Temporary)

Purpose: keep cli-kit building while we migrate legacy SwiftShell usage to the new async APIs.

Shims to remove:

- `Sources/CliKit/Compat/SwiftShellCompat.swift`
  - Provides `ShellResult` alias, `CShell` typealias, `.launch(options:)`, `input(command:)`, and
    `printWorkingDirectory()` helpers.
  - TODO: Replace call sites with `await shell.run([...])` and explicit Process usage where
    synchronous behavior is required, then delete this file.

Wrappers modernized (still thin):

- `Sources/BuildTools/Npm.swift` — uses `await shell.run(args)`.
- `Sources/BuildTools/XcodeBuild.swift` — uses `await shell.run([...])`.

Notes:

- New functionality such as `run-spm` should depend on dev tools libraries (e.g.,
  `RunSPMLauncher`) and not introduce new shims.
- Prefer composition: cli-kit subcommands aggregate focused dev tools rather than re‑implement.
