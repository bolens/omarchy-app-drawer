# Contributing

Keep changes focused, deterministic, and compatible with Omarchy Shell.

Before opening a pull request, review [ARCHITECTURE.md](ARCHITECTURE.md), update
tests for behavior changes, and run the validation documented in
[TESTING.md](TESTING.md). Use an issue first for substantial interface,
persistence, security, or compatibility changes.

```sh
git clone https://github.com/bolens/omarchy-app-drawer.git
cd omarchy-app-drawer
OMABAR_LIVE_TESTS=never npm test
npm run hooks:install
```

The pre-commit hook validates the staged release payload and runs the
deterministic suite. Graphical, live IPC, and stress checks remain explicit.

Pull requests should explain the problem, chosen behavior, user-visible impact,
and exact validation performed. Update `CHANGELOG.md` and documentation for
user-facing changes. Include visual evidence for layout or animation changes.
Never include secrets, private paths, personal monitor names, or unrelated logs.

By contributing, you agree that your contribution is licensed under the MIT
license in [LICENSE](LICENSE) while existing upstream notices remain intact.
