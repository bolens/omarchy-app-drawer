# Requirement coverage

| Requirement | Source and acceptance evidence |
| --- | --- |
| FR-001 | Manifest entry points, `Model.js` migration/layout functions, model and migration tests; `ARCHITECTURE.md` identifies inactive compatibility files. |
| FR-002 | `Service.qml` registration and monitor dispatch, `BarWidget.qml`, model/property tests, and RuntimeMonitorStateTest.qml. |
| FR-003 | `queueAppearance`, `queueAlwaysVisible`, `flushQueuedSettings`; RuntimeMutationTest.qml and settings contract tests. |
| FR-004 | `registerWidget` and `unregisterWidget`; runtime monitor-state coverage and static ownership contracts. |
| FR-005 | `Model.js` appearance/animation policy, property tests, BarWidget.qml, and animation/runtime contracts. |
| FR-006 | `tests/run_all.sh`, `tests/run_qml_runtime.sh`, fleet hardening and crash-safety tests. |

## Verification receipt

On 2026-09-05: The portable gate passed, including JavaScript model/property/contracts, QML lint, and clean-archive plugin validation. The sandbox fixture subprocess needed an unprivileged unsandboxed rerun; that rerun passed. Live controls and graphical runtime harnesses were not run. A separate self-review traced the listed source owners, mutation/observation boundaries, failure paths, and test assertions. No corrective runtime gap was established within this retrospective contract; real-engine and live operational evidence remain explicitly separate. Hosted delivery evidence belongs to the PR.
