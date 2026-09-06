# Tasks

- [x] Add explicit portable mode and locked development environment.
- [x] Pass native and Podman checks, including runner and adapter regressions.
- [x] Verify native Linux/macOS and Linux Docker checks on the recorded main revision.
- [x] Verify merged source delivery and the applicable main-revision workflows.

Historical pre-merge observation (superseded by the receipt below):
Native devenv and actual rootless Podman passed all Node suites, portable-mode rejection/isolation checks, and five adapter tests. Full Qt/plugin/live validation remains with the existing CI and host gate. Docker/macOS CI and Apple execution evidence remain pending.

## Delivery verification — 2026-09-06

The [development workflow](https://github.com/bolens/omarchy-app-drawer/actions/runs/34030205609) passed on
`29784d769c9e716e6794f1d01b1e2793135df191`. Both native platform jobs ran successfully;
the Linux job also executed and passed the Docker development-image check. All
applicable workflows observed for that main revision completed successfully.

Actual Apple container-engine execution remains unverified. Native macOS devenv
validation does not establish that engine's runtime behavior. Existing live-host
and optional dependency limits still apply. Checkout cleanup remains part of each
task's delivery procedure and is not inferred from CI success.
