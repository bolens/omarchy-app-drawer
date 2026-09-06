# Plan: Stock-bar drawer, settings, and monitor ownership

The [specification](spec.md) preserves existing behavior. Use the project guide
and constitution for implementation constraints. Keep upstream-managed templates,
helpers, and integration manifests unchanged.

## Source ownership

- `Model.js`
- `Service.qml`
- `BarWidget.qml`
- `DrawerSettings.qml`
- `DrawerAppearanceSettings.qml`
- `manifest.json`
- `tests/model.test.js`
- `tests/property.test.js`
- `tests/qml`

## Constitution check

Preserve stock-shell compatibility, explicit mutation authority, deterministic ownership, private data boundaries, and isolated verification. This retrospective documentation change adds no runtime behavior, deployment, or release tag.

## Validation

```sh
OMABAR_QML_TESTS=never OMABAR_LIVE_TESTS=never OMABAR_STRESS_TESTS=never npm test
```

Run checks in an isolated checkout. Commands are instructions, not evidence of
a pass. Record results in `coverage.md`, keep incomplete work in `tasks.md`, and
follow `RELEASING.md` for reviewed delivery. No live operation is required solely
to create this retrospective baseline.
