# Development environments

Provide a locked devenv shell and source-free development image for app drawer model, settings, metadata, migration, documentation, and adapter tests. Add an explicit portable mode that requires no Qt, Omarchy installation, Wayland session, or live IPC. Preserve the existing full test default and its QML/plugin validation requirements.

Acceptance: portable mode runs deterministic Node and adapter tests and reports omitted host checks; invalid options fail. Docker, Podman, and Apple adapters preserve arguments and caller ownership. Development-only files remain excluded from plugin archives.
