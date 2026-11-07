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
ShellCheck, behavior, strict QML controls and complete canonical headless runtime
suite on pull requests and pushes to `main`. Its pinned toolchain and v4.0.1
imports also serve retained GitHub callers. Preparation runs
`bash scripts/woodpecker-plugin.sh --prepare` to fetch only immutable public
imports. The required `--offline` phase runs as container user 10042 with
networking disabled; test dependencies are already in the image. Neither phase
receives publishing secrets.

The required plugin check is `ci/woodpecker/pr/plugin`. Ordinary GitHub PR
and main runs skip the duplicate plugin jobs. Reusable callers retain hosted
plugin validation by default; signed release validation explicitly enables
`release_validation: true` before publication. Use Woodpecker for manual plugin
validation. Repository links, HTML/XML, workflow security,
compatibility canaries, macOS, development-image builds, Pages and signed release
publication retain their GitHub workflows. Native success does not replace those
checks or prove live desktop behavior. No release is created by validation CI.

Editor image changes select a real hosted Docker build and post-create smoke
under a non-root user with a read-only image and no host Docker socket. Review
native workflow image pins monthly and after security releases; Dependabot's
Dockerfile coverage does not discover `.woodpecker/` image references.

## Woodpecker site accessibility

The native `site` workflow builds the existing Pages payload, runs its structure
tests, then runs `node scripts/audit-site.mjs` in the pinned official
Puppeteer/Chrome image. It requires an accessibility score exactly 1. The helper
awaits its own loopback HTTP listener and Chrome DevTools readiness, uses ephemeral
ports, and closes only its owned browser, profile, and server. It receives no
secrets or extra host capabilities.

Require `ci/woodpecker/pr/site` alongside the native plugin and existing hosted
checks. Ordinary PR and main runs use the pinned native browser audit; GitHub
continues the site build, structure, HTML/XML, link, and workflow-security checks.
Reusable callers retain hosted browser validation through `release_validation`
with its default `true`; signed releases explicitly enable it. Manual GitHub
workflow dispatch also retains the hosted audit, and Woodpecker supports a manual
site run. Forks still require native approval and receive no publishing secrets.

Publishing and platform checks retain their current workflows. Review the manual
browser-image digest pin alongside the other native image pins; Dependabot does
not update Woodpecker YAML.

The retained `Bar.qml` is migration and licensing reference, rather than a manifest
entry point. It stays in the source lint inventory. Its three inline `PanelWindow`
declarations have line-scoped `uncreatable-type` exceptions because Quickshell's
[static interface is deliberately abstract](https://github.com/quickshell-mirror/quickshell/blob/4f508be500dea6e5732cc3d50382a0048b17e7b1/src/window/panelinterface.hpp),
while its [Wayland overlay registers the concrete runtime type](https://github.com/quickshell-mirror/quickshell/blob/4f508be500dea6e5732cc3d50382a0048b17e7b1/src/wayland/init.cpp).
This matches the documented [upstream tooling issue](https://github.com/quickshell-mirror/quickshell/issues/543).
Each exception ends immediately after the declaration line. Property, type, signal
and binding checks in the component bodies remain enabled. These exceptions do
not establish legacy full-bar runtime acceptance; the active plugin entry points
and their existing behavior harnesses retain their own gates.

## Strict QML import preparation

Inside the qualified CI toolchain, use the same preparation entry point as the
native and retained hosted gates:

```sh
bash scripts/with-qml-imports.sh "$OMARCHY_PATH/shell" bash tests/run_all.sh
```

Use the clean `shell` subtree from Omarchy commit
`13f18b2cb7286fb54f87daf571a031aa6af3d8f0`. The source profile checks every one of
its 175 files, including Git blob hashes and executable modes, before copying it
into an owned temporary directory. It backports the upstream
[`b83d3df` palette qualification](https://github.com/omacom/omarchy/commit/b83d3df0840504299d3099ebf391eb8110527edd)
and gives the eleven existing anonymous token objects named component types.
Every field body and readonly slot is preserved. The installed shell is unchanged.
Unknown source contents fail preparation; the experimental compatibility canary
reports that gap rather than silently adapting an unreviewed upstream revision.

The tooling helper verifies the exact Quickshell/Qt package versions and all 72
Quickshell import files. Its private metadata copy resolves source-backed core
Margins, PopupAnchor, ObjectModel and flag typedefs; installed package files remain unchanged.
`QML_TOOLING_IMPORT_ROOT` selects that copy first with `qmllint --bare` and explicit
system imports. Runtime engines use the real installed package metadata.

The policy rejects warnings. Real-linter controls must accept a supported nested
font field and reject an invalid property, nested field and type with the expected
diagnostic. A successful subprocess with the wrong diagnostic does not pass.
Preparation, source lint and these controls are separate from the explicit QML
runtime suite; a static pass does not prove live desktop behavior. Run runtime
harnesses only with owned HOME/XDG roots and an isolated display appropriate to
the harnesses. Window tests require a real layer-shell compositor, not the
offscreen backend. See the QML warning validation feature's
[acceptance plan](specs/005-qml-warning-validation/plan.md).

If Qt 6.12 `qmllint` fails with empty text output, repeat its exact command with
`--json -` to read the structured diagnostics. Keep the same inputs, policy and
import arguments. Loop-analysis diagnostics can remain in the structured result
when Qt's text output is empty; an empty log never overrides a failing exit code.
Acceptance requires the complete target inventory and zero structured diagnostics.

The pinned Qt 6.12 linter misresolves the legacy bar's `ModuleSlot` forward
reference inside sibling inline components. Its declaration now precedes those
components; the component body and its four construction sites are unchanged.
The module-list Loader exposes its known Row/Column child through an `Item` view
before reading implicit dimensions. Neither workaround excludes the legacy file
from lint or establishes legacy-bar runtime acceptance.

## Required native QML validation

Woodpecker prepares only the immutable public Omarchy source in its first step.
The required plugin step then runs as container user 10042 with networking
disabled. It validates the source and tooling profiles, portable checks, strict
QML lint and real invalid controls before running every harness registered in
`tests/run_qml_runtime.sh` through `scripts/qml-runtime-fixture.py`. Optional
desktop-test selection variables do not skip this owned runtime gate.

Woodpecker 3.x reads `network_mode: none` as a direct step field; placing it
under `backend_options.docker` is ignored by the agent. Docker backend options
retain the ordinary `10042:10042` user. The server must accept the legacy
step-level field in its workflow schema. Verify the actual plugin container has
`HostConfig.NetworkMode=none` and no attached workflow network before claiming
offline acceptance; YAML lint and source assertions alone do not prove this.
Preparation and cloning retain their network access and public immutable inputs.

The fixture uses private HOME/XDG roots, canonical default typography and the
packaged font resolver. Window tests use a software headless compositor; Privacy
tests also use an isolated PipeWire registry without hardware nodes. Protocol
roundtrips establish readiness. Existing harness deadlines and natural exits
remain required; Privacy shutdown also checks the owned configuration is absent.
No host display, audio socket, device, Docker socket or privilege is required.

Each result retains its raw output in CI logs. Only exact, source-bound warnings
from explicitly asserted negative tests may pass; additional Qt, binding, type
or deprecation warnings fail. The palette contract checks all 87 declared token
fields plus eleven inherited object names, stable identities, readonly owners,
permitted child writes and reactive restoration. A missing harness, marker or
cleanup result fails validation.
