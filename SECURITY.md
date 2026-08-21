# Security

## Supported version

Security fixes are provided for the latest release on the `main` branch.

## Design

OmaBar Drawer is a QML-only replacement for Omarchy's stock bar. It performs no network requests, downloads, package installation, privilege escalation, credential access, telemetry, or service management. Its only plugin-specific persisted value is the user-selected `bar.drawerAlwaysVisible` list in Omarchy's existing `~/.config/omarchy/shell.json` file.

The inherited stock-bar implementation supports custom command widgets already authored by the user in `shell.json`. OmaBar Drawer neither creates those entries nor downloads commands for them.

## Reporting

Please use GitHub's private vulnerability reporting for sensitive security reports. Do not include credentials or private information in a public issue.
