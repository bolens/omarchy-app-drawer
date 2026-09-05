# omarchy-app-drawer Spec Kit project guide

A stock-bar App Drawer plugin with per-monitor presentation and serialized shared
settings.

Read this guide with `AGENTS.md` and `.specify/memory/constitution.md` before
specifying, planning, or implementing a substantial change. It is project-owned
guidance, not an upstream-managed template.

## Source and ownership map

- `Model.js`
- `Service.qml`
- `BarWidget.qml`
- `DrawerSettings.qml`
- `DrawerAppearanceSettings.qml`
- `TESTING.md`

## Specification and plan decisions

Keep pure normalization and animation policy in Model.js, mutation/IPC/persistence in
Service.qml, and monitor-local rendering in BarWidget.qml. Specify ownership across
attach, replacement, detach, settings save, and reload.

## Acceptance evidence

Cover reordered monitors, stale callbacks, rapid settings changes, unrelated-key
preservation, animation completion, reduced motion, and missing optional dependencies.
Record both model and QML runtime evidence when behavior crosses the engine boundary.

## Validation and operational limits

```sh
OMABAR_QML_TESTS=never OMABAR_LIVE_TESTS=never OMABAR_STRESS_TESTS=never npm test
```

Portable tests need the documented Omarchy imports and Qt tools. Graphical, live IPC,
stress, and screenshot checks require explicit scope and owned temporary roots. Never
restart or terminate unrelated shell processes as part of static validation.

## Working through Spec Kit

Use Spec Kit for new capabilities, architectural or security-sensitive changes,
migrations, and coordinated changes that need a written contract. Keep narrow fixes,
dependency updates, and prose maintenance in the normal PR workflow.

For a new feature, record observable acceptance criteria in `spec.md`, source ownership
and constitution checks in `plan.md`, and evidence-bearing work in `tasks.md` under the
feature directory created by Spec Kit. Resolve material unknowns before implementation.
Mark tasks complete only after their stated verification, and distinguish completed,
skipped, blocked, and manual checks. Retain completed feature documents as decision
history; do not backfill feature specifications for already finished code.

Keep `.specify/templates/`, `.specify/scripts/`, and generated Codex skills under their
integration manifests. Use this guide and the constitution for local customization.
Regenerate managed files through Spec Kit and verify that project-owned memory survives
updates. Follow `RELEASING.md` for push, merge, release or delivery, and recovery.
