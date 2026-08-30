#!/usr/bin/env bash
set -euo pipefail

plugin_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$plugin_dir"

node tests/model.test.js
node tests/property.test.js
node tests/manifest.test.js
node tests/scripts.test.js
node tests/documentation.test.js
node tests/crash_safety.test.js
node tests/runtime.test.js
node tests/release.test.js
node tests/site.test.js
omarchy_path=${OMARCHY_PATH:-/home/panda/.local/share/omarchy-overlay}
qmllint -I "$omarchy_path/shell" BarWidget.qml DrawerSettings.qml DrawerAppearanceSettings.qml Service.qml Bar.qml
if [[ ${OMARCHY_SKIP_VALIDATE:-0} != 1 ]]; then omarchy plugin validate "$plugin_dir"; fi

if [[ ${OMABAR_QML_TESTS:-auto} == always ]] ||
   { [[ ${OMABAR_QML_TESTS:-auto} == auto ]] &&
     [[ -S ${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/wayland-1 ]] &&
     [[ -w ${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell ]]; }; then
  shell_inventory_before=$(quickshell list --all 2>/dev/null | awk '/Process ID:|Config path:/{sub(/^[[:space:]]+/,""); print}' | sort)
  tests/run_qml_runtime.sh
  shell_inventory_after=$(quickshell list --all 2>/dev/null | awk '/Process ID:|Config path:/{sub(/^[[:space:]]+/,""); print}' | sort)
  if [[ $shell_inventory_after != "$shell_inventory_before" ]]; then
    printf 'Persistent Quickshell inventory changed across isolated QML tests.\nBefore:\n%s\nAfter:\n%s\n' \
      "$shell_inventory_before" "$shell_inventory_after" >&2
    exit 1
  fi
elif [[ ${OMABAR_QML_TESTS:-auto} != never ]]; then
  printf 'Skipping isolated QML runtime tests: no Wayland socket found.\n'
fi

if [[ ${OMABAR_LIVE_TESTS:-auto} == always ]] ||
   { [[ ${OMABAR_LIVE_TESTS:-auto} == auto ]] && command -v qs >/dev/null && qs list --all 2>/dev/null | grep -q 'Process ID:'; }; then
  scripts/verify-live
elif [[ ${OMABAR_LIVE_TESTS:-auto} != never ]]; then
  printf 'Skipping live App Drawer tests: no Quickshell session found.\n'
fi

if [[ ${OMABAR_STRESS_TESTS:-never} == always ]]; then tests/verify-stress; fi
