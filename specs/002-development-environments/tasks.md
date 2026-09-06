# Tasks

- [x] Add explicit portable mode and locked development environment.
- [x] Pass native and Podman checks, including runner and adapter regressions.
- [ ] Verify archive exclusions and current platform CI.
- [ ] Complete protected delivery and cleanup.

Native devenv and actual rootless Podman passed all Node suites, portable-mode rejection/isolation checks, and five adapter tests. Full Qt/plugin/live validation remains with the existing CI and host gate. Docker/macOS CI and Apple execution evidence remain pending.
