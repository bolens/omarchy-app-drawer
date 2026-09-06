# Agent guidance

[Documentation](DOCUMENTATION.md) maps architecture, deployment, state, and document ownership.

For behavior or architecture changes, read [.specify/memory/constitution.md](.specify/memory/constitution.md)
and the relevant parts of [ARCHITECTURE.md](ARCHITECTURE.md). Use [TESTING.md](TESTING.md) to select and run
checks, and [CONTRIBUTING.md](CONTRIBUTING.md) for commit and contribution requirements.

- Keep the plugin on the stock Omarchy bar and preserve unrelated layout and settings state during migration, save, reload, and removal.
- Route state and settings changes through the shared service; keep monitor-scoped state explicit and deterministic.
- Treat QML metadata, properties, defaults, settings UI, IPC, docs, and tests as one contract.
- Run focused Node or QML tests first, then `tests/run_all.sh`; use isolated runtime roots and never kill unrelated Quickshell processes.
- Regenerate screenshots or motion previews only for intentional visual changes and inspect the rendered site responsively.

## Planning and evidence

Use the [project guide](.specify/memory/project-guide.md) and
[constitution](.specify/memory/constitution.md) for substantial changes. The guide
owns Spec Kit scope, retained history, retrospective requirements, and acceptance
evidence. Prose maintenance uses the normal repository workflow.

## Context and handoffs

- Search before reading. Use bounded source excerpts for exploratory reads over
  350 lines, and inspect required guidance and actual source before editing.
- When delegation is permitted, assign a bounded question or output, paths, and
  check. Return source locations, changes, and verification gaps for final review.
- Keep durable corrections in the [project guide](.specify/memory/project-guide.md)
  or owning contract. Replace superseded advice and read it before reuse.
  Temporary progress belongs in task notes. Preserve existing authority rules.
