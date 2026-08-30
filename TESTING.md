# Testing

Run `npm test` for pure, randomized, manifest, migration, crash-safety, QML
lint, plugin validation, isolated runtime, and auto-detected live checks.

- `OMABAR_QML_TESTS=never` skips isolated QML runtime tests.
- `OMABAR_LIVE_TESTS=never` skips live IPC checks.
- `OMABAR_LIVE_TESTS=always` requires live IPC checks.
- `OMABAR_STRESS_TESTS=always` enables the reversible concurrent stress suite.

CI sets `OMARCHY_PATH` to its checked-out Omarchy source and disables graphical
and live tests. Local runtime harnesses terminate only their exact temporary
configuration path and must preserve the persistent Quickshell inventory.

CI validates against Omarchy v4.0.1. The weekly compatibility workflow repeats
the portable checks against v4.0.1 and the current `quattro` branch. A canary
failure reports upstream drift without blocking supported-version work.

CI also runs ShellCheck, Actionlint, link checks, HTML and XML validation, and a
Lighthouse accessibility audit. The accessibility score must remain 1.00.

## Capture visual evidence

Run the reversible capture check on an existing Omarchy Shell session:

```sh
scripts/capture-screenshots --verify
```

To retain the PNG and WebM files for review, pass an empty directory below
`/tmp`:

```sh
audit_dir=$(mktemp -d /tmp/app-drawer-audit.XXXXXX)
scripts/capture-screenshots --audit-dir "$audit_dir" --report "$audit_dir/report.json"
```

The script records each animation style at 60 frames per second. It restores
the appearance, each monitor's expanded state and interaction mode, and the
previously open settings panel. The script fails if restoration or Quickshell
process identity changes.
