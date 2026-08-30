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
