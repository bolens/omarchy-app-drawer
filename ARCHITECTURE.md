# Architecture

[Documentation](DOCUMENTATION.md)

`Model.js` owns pure normalization, bounded settings, animation policy, and
state transitions. `Service.qml` is the sole IPC, persistence, monitor
registration, and mutation authority. `BarWidget.qml` is the monitor-local
presentation mounted inside Omarchy's stock bar. `DrawerSettings.qml` and
`DrawerAppearanceSettings.qml` provide bounded editors through the service.

`Bar.qml`, `BarModel.js`, and the plain-text controls are retained from the
upstream full-bar implementation for migration compatibility and license
provenance; they are not active manifest entry points.

`Model.configForHost()` adapts either the legacy full-shell configuration or the current detached `barConfig` snapshot. On scoped hosts, the service writes only its own inline entry via `updateEntryInline`; `drawerState` contains an allowlisted projection of drawer preferences. Entry metadata and unknown future preference fields are retained. The migration normalizes string slots into settings entries without moving other widgets. Explicit host rejection is a failed save, including queued saves; pending edits and prior saved state are retained.
