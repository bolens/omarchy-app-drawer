const assert = require("node:assert/strict")
const fs = require("node:fs")
const os = require("node:os")
const path = require("node:path")
const {spawnSync} = require("node:child_process")
const root = path.join(__dirname, "..")
const temp = fs.mkdtempSync(path.join(os.tmpdir(), "drawer-scripts-"))
try {
  const config = path.join(temp, "shell.json")
  fs.writeFileSync(config, JSON.stringify({version:1,bar:{id:"legacy",layout:{right:["one",{id:"io.github.amitcpatel.omabar-drawer"}]}},plugins:[]})+"\n")
  let result = spawnSync(path.join(root,"scripts/migrate-to-stock-bar"), [config], {encoding:"utf8"})
  assert.equal(result.status, 0, result.stderr)
  const migrated = JSON.parse(fs.readFileSync(config,"utf8"))
  assert.equal(migrated.bar.id, "omarchy.bar")
  assert.deepEqual(migrated.bar.layout.right, ["one","io.github.bolens.app-drawer"])
  assert.equal(migrated.bar.drawerExpanded, true)
  assert.ok(fs.existsSync(config+".pre-app-drawer-v2"))

  const install = path.join(temp,"plugin"); fs.mkdirSync(install)
  result = spawnSync(path.join(root,"scripts/deploy-shell-runtime"), [install], {encoding:"utf8"})
  assert.equal(result.status, 0, result.stderr)
  for (const file of fs.readdirSync(root).filter(name => /\.(qml|js)$/.test(name)).concat(["manifest.json"]))
    assert.deepEqual(fs.readFileSync(path.join(install,file)), fs.readFileSync(path.join(root,file)), `deploy mismatch: ${file}`)

  const invalid = path.join(temp,"invalid.json"); fs.writeFileSync(invalid,"not json\n")
  result = spawnSync(path.join(root,"scripts/migrate-to-stock-bar"), [invalid], {encoding:"utf8"})
  assert.notEqual(result.status, 0)
  assert.equal(fs.readFileSync(invalid,"utf8"), "not json\n", "failed migration modified its input")

  const capture = fs.readFileSync(path.join(root,"scripts/capture-screenshots"),"utf8")
  assert.match(capture,/probe=.*app-drawer status/,
    "capture must inspect the candidate response instead of trusting qs exit status")
  assert.match(capture,/\.ipcVersion == 1/,
    "capture must reject unrelated Quickshell IPC processes")
  assert.match(capture,/-c libvpx-vp9/,
    "WebM evidence must use a WebM-compatible codec")
  assert.match(capture,/wf-recorder -y -D/,
    "animation evidence must request a continuous frame stream")
  assert.match(capture,/ffprobe/,
    "capture must inspect recorded animation streams")
  assert.match(capture,/frame_count -ge 10/,
    "capture must reject truncated animation recordings")
  assert.match(capture,/local status=\$\?/,
    "capture cleanup must preserve the failing command status")
  assert.match(capture,/hl\.dsp\.focus\(\{ workspace/,
    "capture must use an empty workspace instead of retaining private window content")
  assert.match(capture,/hl\.dsp\.focus\(\{ monitor/,
    "capture must restore the selected and previously focused monitor")
  assert.match(capture,/grim -o "\$monitor"/,
    "settings evidence must include the complete monitor-height panel")
  const live = fs.readFileSync(path.join(root,"scripts/verify-live"),"utf8")
  const runner = fs.readFileSync(path.join(root,"tests/run_all.sh"),"utf8")
  assert.match(live, /--detect/,
    "live verification must expose a side-effect-free availability probe")
  assert.match(runner, /scripts\/verify-live --detect/,
    "auto mode must detect App Drawer IPC rather than any Quickshell process")
} finally { fs.rmSync(temp,{recursive:true,force:true}) }
console.log("App Drawer migration and deployment scripts passed")
