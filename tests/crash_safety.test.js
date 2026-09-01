const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const root = path.join(__dirname,"..")
const runner = fs.readFileSync(path.join(root,"tests/run_qml_runtime.sh"),"utf8")
const suite = fs.readFileSync(path.join(root,"tests/run_all.sh"),"utf8")
assert.match(runner,/runtime_root=.*quickshell[\s\S]*\[\[ -w "\$runtime_root" \]\]/,
  "direct QML runs must reject inaccessible runtime directories before Qt aborts")
assert.match(suite,/wayland-1[\s\S]*-w .*quickshell/,
  "automatic QML runs must require Wayland and writable Quickshell runtime state")
assert.match(runner,/timeout 8/,
  "hung QML harnesses must be terminated within a bounded interval")
assert.match(runner,/Binding loop\|Unable to assign\|Cannot assign/,
  "unstable QML runtime warnings must fail the suite")
assert.match(runner,/failures=0[\s\S]*exit "\$failures"/,
  "every QML harness failure must propagate to the suite exit status")
assert.match(runner,/active_harness[\s\S]*quickshell_bin" kill --path "\$active_harness" --any-display/,
  "temporary QML shells must be explicitly terminated during normal and trap cleanup")
assert.match(suite,/shell_inventory_before[\s\S]*shell_inventory_after[\s\S]*Persistent Quickshell inventory changed/,
  "isolated QML tests must preserve the persistent Quickshell inventory")
console.log("App Drawer crash-safety runner contracts passed")
