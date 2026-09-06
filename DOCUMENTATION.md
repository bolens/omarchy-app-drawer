# Documentation

App Drawer runtime, per-monitor behavior, and settings ownership.

## Start here

| Need | Owning document |
| --- | --- |
| Use the project | [README.md](README.md) |
| Change the repository | [AGENTS.md](AGENTS.md) |
| Deliver or recover | [RELEASING.md](RELEASING.md) |
| Plan substantial changes | [.specify/memory/project-guide.md](.specify/memory/project-guide.md) |
| Non-negotiable constraints | [.specify/memory/constitution.md](.specify/memory/constitution.md) |

## Architecture

[ARCHITECTURE.md](ARCHITECTURE.md) owns the boundary between pure model policy, shared service
mutation, and per-monitor presentation. Replacement and detach events must not let stale callbacks
overwrite current state. The plugin extends the stock bar within the existing shell process.

## Deployment and recovery

[README](README.md) owns installation and user behavior. [RELEASING.md](RELEASING.md) owns plugin
release and recovery, and [TESTING.md](TESTING.md) distinguishes portable checks from real QML
evidence. Installation, reload, and removal must preserve unrelated bar layout and settings.

## Database and state

There is no separate database service. [Service.qml](Service.qml) owns settings persistence and IPC,
while monitor-local presentation state has a different lifetime. Keep normalization, save,
migration, and reload behavior consistent with the architecture contract.

## Documentation maintenance

Keep decisions, invariants, failure modes, and recovery requirements in the owning document. Link to
commands, defaults, schemas, and generated catalogs instead of copying them. Change the owner and
affected references together. Update this index when adding or moving a guide, and verify relative
links and heading anchors. Historical specs and audits describe their recorded revision, not current
runtime proof. A topic without an implementation stays explicitly unimplemented.

## Topic guides

- [README.md](README.md): installation, behavior, configuration, and IPC
- [ARCHITECTURE.md](ARCHITECTURE.md): runtime ownership and module boundaries
- [TESTING.md](TESTING.md): validation modes and environment controls
- [SECURITY.md](SECURITY.md): trust boundaries and vulnerability reporting
- [CONTRIBUTING.md](CONTRIBUTING.md): contribution requirements
- [RELEASING.md](RELEASING.md): versioning and release procedure
- [SUPPORT.md](SUPPORT.md): public and private report routing
- [NOTICE](NOTICE): upstream provenance and retained notices

- [Editor setup](.vscode/README.md)
