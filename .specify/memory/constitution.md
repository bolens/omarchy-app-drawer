# App Drawer Constitution

## Core Principles

### I. Stock-Bar Compatibility
The plugin MUST extend the stock Omarchy bar without replacing its services or creating another Quickshell process. Migration and removal remain idempotent and preserve unrelated layout state.

### II. Deterministic Per-Monitor State
Expanded state and interaction mode MUST remain correctly scoped per monitor. Attachment, IPC, persistence, and animation behavior MUST be deterministic under monitor churn and reloads.

### III. Accessible, Distinct Motion
Controls MUST remain keyboard and assistive-technology operable. Animation styles MUST be observably distinct, bounded, topology-stable, and honor instant or reduced-motion behavior.

### IV. Serialized Settings Contract
Settings reads, normalization, writes, and reloads MUST flow through the shared service without lost updates. QML metadata, defaults, UI, IPC, documentation, and tests MUST agree.

### V. Isolated Runtime Evidence
Tests MUST use isolated Quickshell, HOME, and XDG roots and terminate only owned processes. QML lint, runtime tests, site checks, and visual evidence cover affected surfaces.

## Governance

`ARCHITECTURE.md`, `TESTING.md`, and `CONTRIBUTING.md` define detailed contracts. Exceptions require rationale, regression tests, and a constitution version update.

**Version**: 1.0.0 | **Ratified**: 2026-09-02 | **Last Amended**: 2026-09-02
