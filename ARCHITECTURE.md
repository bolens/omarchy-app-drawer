# Architecture

`Model.js` owns pure normalization, bounded settings, animation policy, and
state transitions. `Service.qml` is the sole IPC, persistence, monitor
registration, and mutation authority. `BarWidget.qml` is the monitor-local
presentation mounted inside Omarchy's stock bar. `DrawerSettings.qml` and
`DrawerAppearanceSettings.qml` provide bounded editors through the service.

`Bar.qml`, `BarModel.js`, and the plain-text controls are retained from the
upstream full-bar implementation for migration compatibility and license
provenance; they are not active manifest entry points.
