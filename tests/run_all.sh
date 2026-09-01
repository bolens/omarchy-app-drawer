#!/usr/bin/env bash
set -euo pipefail

plugin_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$plugin_dir"
quickshell_bin=${QUICKSHELL_BIN:-$(command -v quickshell || command -v qs || true)}

persistent_shell_inventory() {
  [[ -n $quickshell_bin ]] || return 0
  "$quickshell_bin" list --all 2>/dev/null | awk '
    /^Process ID:/ { pid=$3 }
    /^Config path:/ {
      sub(/^[[:space:]]+/, "")
      path=$0
      sub(/^Config path: /, "", path)
      if (index(path, "/tmp/") != 1) {
        print "Process ID: " pid
        print "Config path: " path
      }
    }
  ' | sort
}

node tests/model.test.js
node tests/property.test.js
node tests/manifest.test.js
node tests/scripts.test.js
node tests/documentation.test.js
node tests/crash_safety.test.js
node tests/runtime.test.js
node tests/release.test.js
node tests/site.test.js
node tests/fleet_hardening.test.js
omarchy_path=${OMARCHY_PATH:-/home/panda/.local/share/omarchy-overlay}
qmllint_bin=${QMLLINT:-/usr/lib/qt6/bin/qmllint}
[[ -x $qmllint_bin ]] || { printf 'Qt 6 qmllint not found: %s\n' "$qmllint_bin" >&2; exit 1; }
"$qmllint_bin" -I "$omarchy_path/shell" -i "$plugin_dir/qmldir" \
  -i "$omarchy_path/shell/Commons/qmldir" -i "$omarchy_path/shell/Ui/qmldir" \
  Button.qml WidgetButton.qml PlainTextToggle.qml BarWidget.qml DrawerSettings.qml DrawerAppearanceSettings.qml Service.qml Bar.qml
if [[ ${OMARCHY_SKIP_VALIDATE:-0} != 1 ]]; then
  validation_dir=$(mktemp -d)
  trap 'rm -rf -- "$validation_dir"' EXIT
  git archive HEAD | tar -x -C "$validation_dir"
  omarchy plugin validate "$validation_dir"
  rm -rf -- "$validation_dir"
  trap - EXIT
fi

if [[ ${OMABAR_QML_TESTS:-auto} == always ]] ||
   { [[ ${OMABAR_QML_TESTS:-auto} == auto ]] &&
     [[ -S ${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/wayland-1 ]] &&
     [[ -w ${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell ]]; }; then
  shell_inventory_before=$(persistent_shell_inventory)
  tests/run_qml_runtime.sh
  shell_inventory_after=$(persistent_shell_inventory)
  if [[ $shell_inventory_after != "$shell_inventory_before" ]]; then
    printf 'Persistent Quickshell inventory changed across isolated QML tests.\nBefore:\n%s\nAfter:\n%s\n' \
      "$shell_inventory_before" "$shell_inventory_after" >&2
    exit 1
  fi
elif [[ ${OMABAR_QML_TESTS:-auto} != never ]]; then
  printf 'Skipping isolated QML runtime tests: no Wayland socket found.\n'
fi

if [[ ${OMABAR_LIVE_TESTS:-auto} == always ]] ||
   { [[ ${OMABAR_LIVE_TESTS:-auto} == auto ]] && scripts/verify-live --detect >/dev/null 2>&1; }; then
  scripts/verify-live
elif [[ ${OMABAR_LIVE_TESTS:-auto} != never ]]; then
  printf 'Skipping live App Drawer tests: no Quickshell session found.\n'
fi

if [[ ${OMABAR_STRESS_TESTS:-never} == always ]]; then tests/verify-stress; fi
