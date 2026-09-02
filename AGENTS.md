# Agent guidance

Read `.specify/memory/constitution.md`, `ARCHITECTURE.md`, `TESTING.md`, and `CONTRIBUTING.md`.

- Keep the plugin on the stock Omarchy bar and preserve unrelated layout and settings state during migration, save, reload, and removal.
- Route state and settings changes through the shared service; keep monitor-scoped state explicit and deterministic.
- Treat QML metadata, properties, defaults, settings UI, IPC, docs, and tests as one contract.
- Run focused Node or QML tests first, then `tests/run_all.sh`; use isolated runtime roots and never kill unrelated Quickshell processes.
- Regenerate screenshots or motion previews only for intentional visual changes and inspect the rendered site responsively.
