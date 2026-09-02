# Changelog

All notable changes to App Drawer are documented here. The project follows
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Pages code examples use theme-aware shell syntax highlighting without changing copied commands.

## [2.6.7] - 2026-09-01

### Added

- Pages now include favicons, touch and install icons, a web manifest, and a 1200x630 social card. Regression tests protect the metadata and image dimensions.

## [2.6.6] - 2026-09-01

### Added

- Pages offer selectable dark and light themes.
- Browsers that prefer light mode start with GitHub Light; browsers without a preference keep the default dark theme.

## [2.6.5] - 2026-09-01

### Fixed

- Tag-triggered releases now receive the pull-request metadata required by path-filtered validation.

## [2.6.4] - 2026-09-01

### Changed

- Give taskbar, cascade, soft-cascade, and uniform reveals visibly distinct
  opacity timing while retaining the single clipped extent that avoids
  all-widget layout churn.
- Regenerate the Pages motion previews from the tuned runtime profiles.

### Fixed

- Preserve the original motion-preview duration while rendering smoother frames.
- Harden Pages, screenshot, and CI-image contracts found during review.

## [2.6.3] - 2026-09-01

### Fixed

- Preserve QML-backed pinned and always-visible widget lists across settings
  mutation, serialization, and reload while rejecting malformed or oversized
  array-like values with a single bounded length snapshot.
- Require Qt 6 QML tooling, publish plugin module metadata, and gate reliable
  semantic lint errors in local and CI validation.

## [2.6.2] - 2026-08-31

### Fixed

- Wait for restored monitor slot geometry to settle after a shell restart so
  the first drawer transition animates across the complete saved widget row.

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

[Unreleased]: https://github.com/bolens/omarchy-app-drawer/compare/v2.6.7...HEAD
[2.6.7]: https://github.com/bolens/omarchy-app-drawer/compare/v2.6.6...v2.6.7
[2.6.6]: https://github.com/bolens/omarchy-app-drawer/compare/v2.6.5...v2.6.6
[2.6.5]: https://github.com/bolens/omarchy-app-drawer/compare/v2.6.4...v2.6.5
[2.6.4]: https://github.com/bolens/omarchy-app-drawer/compare/v2.6.3...v2.6.4
[2.6.3]: https://github.com/bolens/omarchy-app-drawer/compare/v2.6.2...v2.6.3
[2.6.2]: https://github.com/bolens/omarchy-app-drawer/compare/v2.6.1...v2.6.2
[2.6.1]: https://github.com/bolens/omarchy-app-drawer/compare/v2.6.0...v2.6.1
[2.6.0]: https://github.com/bolens/omarchy-app-drawer/releases/tag/v2.6.0
