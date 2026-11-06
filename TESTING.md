# Testing

[Documentation](DOCUMENTATION.md)

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

## Portable development gate

Run `bash tests/run_all.sh --portable` for deterministic Node and container-adapter tests without a desktop installation. This explicit mode reports the omitted Qt, plugin archive, QML runtime, live IPC, and stress checks. The default `npm test` behavior and full CI requirements remain unchanged.

## Woodpecker plugin validation

[Woodpecker](https://woodpecker.bolens.dev/repos) runs the plugin archive,
ShellCheck, behavior and QML lint checks on pull requests and pushes to `main`.
It uses the same immutable Omarchy toolchain image and v4.0.1 imports as
GitHub CI. The entry point is `bash scripts/woodpecker-plugin.sh` inside that
image. It requires network access only to fetch the pinned public imports
and any lockfile-based test dependencies; it receives no publishing secrets.

The required plugin check is `ci/woodpecker/pr/plugin`. Ordinary GitHub PR
and main runs skip the duplicate plugin jobs. Reusable callers retain hosted
plugin validation by default; signed release validation explicitly enables
`release_validation: true` before publication. Use Woodpecker for manual plugin
validation. Repository links, HTML/XML, browser accessibility, workflow security,
compatibility canaries, macOS, development-image builds, Pages and signed release
publication retain their GitHub workflows. Native success does not replace those
checks or prove live desktop behavior. No release is created by validation CI.

Editor image changes select a real hosted Docker build and post-create smoke
under a non-root user with a read-only image and no host Docker socket. Review
native workflow image pins monthly and after security releases; Dependabot's
Dockerfile coverage does not discover `.woodpecker/` image references.

## Native site audit proposal

The native `site` workflow builds the existing Pages payload, runs its structure
tests, then runs `node scripts/audit-site.mjs` in the pinned official
Puppeteer/Chrome image. It requires an accessibility score exactly 1. The helper
awaits its own loopback HTTP listener and Chrome DevTools readiness, uses ephemeral
ports, and closes only its owned browser, profile, and server. It receives no
secrets or extra host capabilities.

The hosted browser check remains required during adoption. A source review or
local build does not establish runner success: verify the final-head native site
pipeline and genuine merged-main run before retiring hosted coverage or changing
its required checks. Publishing, signed releases, and platform checks keep their
current workflows. Review the manual browser-image digest pin alongside the
other native image pins; Dependabot does not update Woodpecker YAML.
