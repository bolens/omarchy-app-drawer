# Security

## Supported version

Security fixes are provided for the latest release on the `main` branch.

## Design

App Drawer is a QML-only widget and service inside Omarchy's stock bar. It performs no network requests, downloads, package installation, privilege escalation, credential access, telemetry, or service management. It persists normalized drawer appearance, shared pins, and per-monitor visibility/mode values in Omarchy's existing `~/.config/omarchy/shell.json` file.

All bar-owned text sinks force `Text.PlainText`, including widget tooltips, manifest-provided names, configured command output, and configured command tooltips. This prevents Qt's automatic rich-text handling from interpreting widget-controlled markup or loading remote resources.

The plugin's active entry points do not launch Quickshell, detached processes, or arbitrary commands. Its isolated QML test runner starts only a temporary path-scoped harness and kills that exact path during normal and signal cleanup. The stock bar may still run custom command widgets already authored by the user in `shell.json`; App Drawer neither creates nor modifies those commands.

## Reporting

Please use GitHub's private vulnerability reporting for sensitive security reports. Do not include credentials or private information in a public issue.

## Release security checklist

- Preserve every upstream copyright notice and the complete MIT license.
- Confirm release archives contain `LICENSE` and `NOTICE` and exclude tests,
  workflows, local caches, and maintainer scripts.
- Run the complete validation suite and inspect dependency-action updates.
- Verify the GitHub artifact attestation for the release archive.
- Never publish credentials, private paths, monitor serials, or captured logs.
