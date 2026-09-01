#!/usr/bin/env bash
set -euo pipefail
plugin_dir=$(cd -- "$(dirname -- "$0")/.." && pwd)
requested=("$@")
runtime_dir=$(mktemp -d)
active_harness=""
# shellcheck disable=SC2317,SC2329 # Invoked by the signal and exit trap below.
cleanup_runtime() {
  if [[ -n $active_harness ]]; then
    "$quickshell_bin" kill --path "$active_harness" --any-display >/dev/null 2>&1 || true
  fi
  rm -rf -- "$runtime_dir"
}
trap cleanup_runtime EXIT INT TERM
quickshell_bin=${QUICKSHELL_BIN:-$(command -v quickshell || command -v qs)}
shell_root=${OMARCHY_SHELL_ROOT:-/home/panda/.local/share/omarchy-overlay/shell}
[[ -x "$quickshell_bin" && -d "$shell_root/Ui" && -d "$shell_root/Commons" ]] || {
  printf 'QML runtime dependencies are unavailable.\n' >&2; exit 2;
}
runtime_root=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell
[[ -w "$runtime_root" ]] || {
  printf 'Quickshell runtime directory is not writable: %s\n' "$runtime_root" >&2
  exit 2
}

leaked_runtime_processes() {
  "$quickshell_bin" list --all 2>/dev/null | awk -v root="$runtime_dir/" '
    /^Process ID:/ { pid=$3 }
    /^Config path:/ {
      sub(/^[[:space:]]+/, "")
      path=$0
      sub(/^Config path: /, "", path)
      if (index(path, root) == 1) print pid "\t" path
    }
  '
}

wait_for_runtime_teardown() {
  local leaks
  for _attempt in {1..100}; do
    leaks=$(leaked_runtime_processes || true)
    [[ -z $leaks ]] && return 0
    sleep 0.02
  done
  printf '%s\n' "$leaks"
  return 1
}
find "$plugin_dir" -maxdepth 1 -type f \( -name '*.qml' -o -name '*.js' \) -exec ln -s -- '{}' "$runtime_dir/" \;
find "$plugin_dir/tests/qml" -maxdepth 1 -type f -name 'Runtime*Test.qml' -exec ln -s -- '{}' "$runtime_dir/" \;
ln -s -- "$shell_root/Commons" "$runtime_dir/Commons"
ln -s -- "$shell_root/Ui" "$runtime_dir/Ui"

run_harness() {
  local file=$1 marker=$2 output status
  if (( ${#requested[@]} > 0 )); then
    local found=false item
    for item in "${requested[@]}"; do [[ $item == "$file" ]] && found=true; done
    [[ $found == true ]] || return 0
  fi
  active_harness="$runtime_dir/$file"
  set +e
  output=$(timeout 8 "$quickshell_bin" --no-color --path "$active_harness" 2>&1)
  status=$?
  set -e
  "$quickshell_bin" kill --path "$active_harness" --any-display >/dev/null 2>&1 || true
  active_harness=""
  leaks=$(wait_for_runtime_teardown || true)
  if [[ -n $leaks ]]; then
    printf 'Leaked Quickshell runtime harnesses after %s:\n%s\n' "$file" "$leaks" >&2
    return 1
  fi
  [[ $status -eq 0 ]] || { printf '%s\n' "$output" >&2; return "$status"; }
  grep -Eq "(^|[[:space:]])${marker}([[:space:]]|$)" <<<"$output" || {
    printf '%s did not emit %s\n%s\n' "$file" "$marker" "$output" >&2; return 1;
  }
  if grep -Eq 'WARN scene: .*(Error:|TypeError:|ReferenceError:|Binding loop|Unable to assign|Cannot assign)' <<<"$output"; then
    printf '%s emitted a QML runtime error\n%s\n' "$file" "$output" >&2; return 1
  fi
}

failures=0
run_harness RuntimeModelTest.qml DRAWER_QML_MODEL_OK || failures=1
run_harness RuntimeServiceTest.qml DRAWER_QML_SERVICE_OK || failures=1
run_harness RuntimeSettingsTest.qml DRAWER_QML_SETTINGS_OK || failures=1
run_harness RuntimeSettingsNavigationTest.qml DRAWER_QML_SETTINGS_NAVIGATION_OK || failures=1
run_harness RuntimeIpcTest.qml DRAWER_QML_IPC_OK || failures=1
run_harness RuntimeMonitorStateTest.qml DRAWER_QML_MONITOR_STATE_OK || failures=1
run_harness RuntimeMutationTest.qml DRAWER_QML_MUTATION_OK || failures=1
run_harness RuntimeAccessibilityTest.qml DRAWER_QML_ACCESSIBILITY_OK || failures=1
runtime_leaks=$(leaked_runtime_processes || true)
if [[ -n $runtime_leaks ]]; then
  printf 'Leaked Quickshell runtime harnesses:\n%s\n' "$runtime_leaks" >&2
  failures=1
fi
exit "$failures"
