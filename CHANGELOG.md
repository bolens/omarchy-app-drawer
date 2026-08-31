# Changelog

All notable changes to App Drawer are documented here. The project follows
[Semantic Versioning](https://semver.org/).

## [Unreleased]

## [2.6.1] - 2026-08-31

### Changed

- Align CI, release, dependency, runtime, and archive policies with the
  maintained plugin suite.
- Route Quickshell inventory and leak checks through the configured executable.
- Validate the tracked release payload locally and run staged-tree checks from
  the repository pre-commit hook.

### Fixed

- Detect the App Drawer IPC target before enabling automatic live tests.

## [2.6.0] - 2026-08-30

### Added

- Add a hard-fork service and bar-widget architecture with per-monitor state,
  versioned IPC, compact settings, shared pins, and configurable appearance.
- Add deterministic model, QML runtime, IPC, migration, crash-safety, and live
  stress coverage.
- Add a distinct GitHub Pages guide with installation, architecture,
  appearance, and troubleshooting coverage.
- Add pinned CI, release automation, governance documents, and repository
  validation for the maintained hard fork.
- Add reversible PNG and WebM capture with exact state and process restoration.
- Add supported-release and weekly upstream Omarchy compatibility checks.
- Add release artifact attestations and a 1.00 accessibility gate.

### Changed

- Retain Omarchy's stock bar instead of replacing it with the legacy full-bar
  implementation.
- Make expansion behavior and animation styles configurable per monitor.

[Unreleased]: https://github.com/bolens/omarchy-app-drawer/compare/v2.6.1...HEAD
[2.6.1]: https://github.com/bolens/omarchy-app-drawer/compare/v2.6.0...v2.6.1
[2.6.0]: https://github.com/bolens/omarchy-app-drawer/releases/tag/v2.6.0
