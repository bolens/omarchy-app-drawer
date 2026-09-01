const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const vm = require("node:vm")
const source = fs.readFileSync(path.join(__dirname, "..", "Model.js"), "utf8").replace(/^\.pragma library\s*$/m, "")
const context = {}
vm.createContext(context)
vm.runInContext(source, context)
const ids = entries => Array.from(entries, context.entryId)
const drawer = context.PLUGIN_ID
assert.equal(context.SETTINGS_VERSION, 3)
const expanded = [{id: "tray", pinned: true}, "network", {id: drawer}]

assert.equal(context.entryId(null), "")
assert.equal(context.entryId({plugin: "fallback"}), "fallback")
assert.deepEqual(Array.from(context.uniqueIds(["tray", "tray", drawer, "", null])), ["tray"])
assert.deepEqual(Array.from(context.uniqueIds({0:"tray",1:"network",length:2})), ["tray","network"])
for (const invalidList of [{length:Infinity},{length:4097},{length:-1},{length:1.5},function listValue() {}]) {
  assert.deepEqual(Array.from(context.uniqueIds(invalidList)), [])
  assert.deepEqual(Array.from(context.validEntries(invalidList)), [])
}
assert.deepEqual(ids(context.collapsedEntries(expanded, ["tray"], {id: drawer})), ["tray", drawer])
assert.deepEqual(ids(context.collapsedEntries(expanded, ["unknown"], drawer)), [drawer])
const restored = context.restoredEntries(
  [{id: "tray", pinned: true}, "network"],
  [{id: "tray"}, {id: "new-widget"}, {id: drawer}],
  {id: drawer})
assert.deepEqual(ids(restored), ["tray", "network", "new-widget", drawer])
assert.equal(restored.at(-1).id, drawer)
const malformed = context.state({bar: {layout: {right: [null, {}, "audio"]}, drawerAlwaysVisible: "bad"}})
assert.deepEqual(ids(malformed.right), ["audio"])
assert.deepEqual(Array.from(malformed.alwaysVisible), [])
assert.equal(malformed.expanded, true)

const deterministic = {bar: {layout: {right: [{id: "tray", value: 1}, "network", drawer]}, drawerExpanded: true}}
assert.equal(context.applyExpanded(deterministic, false), false)
const firstSnapshot = JSON.stringify(deterministic)
assert.equal(context.applyExpanded(deterministic, false), false)
assert.equal(JSON.stringify(deterministic), firstSnapshot, "repeated collapse must be idempotent")
assert.deepEqual(ids(deterministic.bar.drawerExpandedEntries), ["tray", "network"])
assert.equal(context.applyExpanded(deterministic, true), true)
const firstRestore = JSON.stringify(deterministic)
assert.equal(context.applyExpanded(deterministic, true), true)
assert.equal(JSON.stringify(deterministic), firstRestore, "repeated expand must be idempotent")

const rapid = {bar: {layout: {right: ["tray", "network", drawer]}, drawerExpanded: true}}
for (let index = 0; index < 100; index++) context.toggleExpanded(rapid)
assert.equal(rapid.bar.drawerExpanded, true)
assert.deepEqual(ids(rapid.bar.layout.right), ["tray", "network", drawer])

context.applyExpanded(rapid, false)
assert.deepEqual(JSON.parse(JSON.stringify(context.applyPinned(rapid, "tray", true))), {ok: true, changed: true, value: true})
assert.deepEqual(ids(rapid.bar.layout.right), ["tray", drawer])
assert.equal(context.applyPinned(rapid, "tray", true).changed, false, "repeated pin must not dirty configuration")
assert.equal(context.applyPinned(rapid, "missing", true).ok, false)
assert.equal(context.resetPinned(rapid), true)
assert.equal(context.resetPinned(rapid), false, "repeated reset must be idempotent")
assert.deepEqual(ids(rapid.bar.layout.right), [drawer])

const keepAlive = {plugins:[{id:"wallpaper"},{id:"old",_omabarDrawerKeepAlive:true},{id:"new",_appDrawerKeepAlive:true}]}
assert.equal(context.removeDrawerKeepAlives(keepAlive), true)
assert.deepEqual(JSON.parse(JSON.stringify(keepAlive.plugins)), [{id:"wallpaper"}])
assert.equal(context.removeDrawerKeepAlives(keepAlive), false, "keepalive cleanup must be idempotent")

const appearance = context.appearanceSettings({expandedGlyph: "  X ", collapsedGlyph: "", iconSize: 99,
  horizontalMargin: -2, verticalPadding: "bad", expandedColorRole: "invalid",
  collapsedColorRole: "urgent", showTooltip: false, leftClickAction: "collapse", middleClickAction: "bad",
  animationEnabled: false, animationDuration: 9999, animationStyle:"bad", animationCurve:"bad", hoverCollapseDelay:9999})
assert.deepEqual(JSON.parse(JSON.stringify(appearance)), {
  expandedGlyph: "X", collapsedGlyph: "󰅁", iconSize: 30, horizontalMargin: 2, verticalPadding: 6,
  expandedColorRole: "accent", collapsedColorRole: "urgent", showTooltip: false,
  leftClickAction: "collapse", middleClickAction: "settings", animationEnabled: false, animationDuration: 1000,
  animationStyle:"taskbar", animationCurve:"smooth",
  hoverCollapseDelay:2000
})
const appearanceConfig = {bar: {layout: {right: [drawer]}}}
context.applyAppearance(appearanceConfig, {iconSize: 22, leftClickAction: "expand"})
assert.equal(appearanceConfig.bar.drawerAppearance.iconSize, 22)
assert.equal(appearanceConfig.bar.drawerAppearance.leftClickAction, "expand")
assert.equal(context.resetAppearance(appearanceConfig).iconSize, 14)
assert.equal(context.resetAppearance(appearanceConfig).animationDuration, 250)
assert.equal(context.resetAppearance(appearanceConfig).animationStyle, "taskbar")
assert.equal(context.resetAppearance(appearanceConfig).animationCurve, "smooth")

assert.equal(context.revealExtent("taskbar", .5, 20, 40, 100), 10)
assert.equal(context.revealExtent("softCascade", .5, 20, 40, 100), 10)
assert.equal(context.revealExtent("uniform", .5, 20, 0, 100), 20)
assert.equal(context.revealExtent("cascade", .5, 20, 40, 100), 10)
assert.equal(context.revealOpacity("taskbar", .1, 20, 0, 100), 1)
assert.equal(context.revealOpacity("softCascade", 0, 20, 0, 100), 0)
assert.equal(context.revealOpacity("softCascade", 1, 20, 0, 100), 1)
assert.equal(context.revealOpacity("uniform", 0, 20, 0, 100), 0)
assert.ok(Math.abs(context.revealOpacity("uniform", .5, 20, 0, 100) - .6) < 1e-9)
assert.equal(context.revealOpacity("uniform", 1, 20, 0, 100), 1)
assert.equal(context.revealOpacity("cascade", 0, 20, 0, 100), 0)
assert.equal(context.revealOpacity("cascade", .09, 20, 0, 100), .5)
assert.equal(context.revealOpacity("cascade", .18, 20, 0, 100), 1)
for (const style of ["taskbar", "cascade", "softCascade", "uniform"]) {
  let previous = -1
  for (let step = 0; step <= 100; step++) {
    const value = context.revealExtent(style, step / 100, 23, 47, 211)
    assert.ok(value >= 0 && value <= 23, `${style} extent escaped bounds`)
    assert.ok(value >= previous, `${style} extent was not monotonic`)
    previous = value
  }
  assert.equal(context.revealExtent(style, 0, 23, 47, 211), 0)
  assert.equal(context.revealExtent(style, 1, 23, 47, 211), 23)
}

const transitionConfig = {bar:{layout:{right:[drawer]}}}
assert.deepEqual(JSON.parse(JSON.stringify(context.beginTransition(transitionConfig, "expanding", 7, 220, 1000))),
  {phase:"expanding",generation:7,expiresAt:1220})
assert.equal(context.state(transitionConfig).transition.phase, "expanding")
assert.equal(context.clearTransition(transitionConfig, 6), false, "stale generation must not clear a newer transition")
assert.equal(context.clearTransition(transitionConfig, 7), true)
assert.equal(context.state(transitionConfig).transition.phase, "idle")

const monitorConfig = {bar:{layout:{right:["tray",drawer]},drawerExpanded:true}}
assert.equal(context.monitorExpanded(monitorConfig,"DP-1"), true)
assert.equal(context.applyMonitorExpanded(monitorConfig,"DP-1",false), false)
assert.equal(context.monitorExpanded(monitorConfig,"DP-1"), false)
assert.equal(context.monitorExpanded(monitorConfig,"DP-3"), true)
assert.equal(context.applyMonitorMode(monitorConfig,"DP-1","hover"), "hover")
assert.equal(context.state(monitorConfig).monitorModes["DP-1"], "hover")

const legacyConfig = {bar:{layout:{right:["tray",drawer]},drawerAppearance:{iconSize:999,hoverToExpand:true},
  drawerAlwaysVisible:["tray","tray",drawer],drawerMonitorStates:{" DP-1 ":1,"DP-3":true},
  drawerMonitorModes:{"DP-1":"bad","DP-3":"hover"},drawerTransition:{phase:"expanding"}},
  plugins:[{id:"wallpaper",_omabarDrawerKeepAlive:true},{id:"media",_appDrawerKeepAlive:true},{id:"real"}]}
const migration = context.migrateConfig(legacyConfig)
assert.deepEqual(JSON.parse(JSON.stringify(migration)), {changed:true,version:3})
assert.equal(legacyConfig.bar._appDrawerSettingsVersion, 3)
assert.equal(legacyConfig.bar.drawerAppearance.iconSize, 30)
assert.equal(legacyConfig.bar.drawerAppearance.hoverToExpand, undefined)
assert.deepEqual(Array.from(legacyConfig.bar.drawerAlwaysVisible), ["tray"])
assert.deepEqual(JSON.parse(JSON.stringify(legacyConfig.bar.drawerMonitorStates)), {"DP-1":false,"DP-3":true})
assert.deepEqual(JSON.parse(JSON.stringify(legacyConfig.bar.drawerMonitorModes)), {"DP-1":"toggle","DP-3":"hover"})
assert.equal(legacyConfig.bar.drawerTransition, undefined)
assert.deepEqual(JSON.parse(JSON.stringify(legacyConfig.plugins)), [{id:"real"}])
assert.deepEqual(JSON.parse(JSON.stringify(context.migrateConfig(legacyConfig))), {changed:false,version:3},
  "migration must become a no-op after canonicalization")
const oldGlyphDefaults = {bar:{layout:{right:[drawer]},_appDrawerSettingsVersion:1,
  drawerAppearance:{expandedGlyph:"󰅀",collapsedGlyph:"󰅂",animationDuration:600}}}
context.migrateConfig(oldGlyphDefaults)
assert.equal(oldGlyphDefaults.bar.drawerAppearance.collapsedGlyph,"󰅁")
assert.equal(oldGlyphDefaults.bar.drawerAppearance.expandedGlyph,"󰅂")
assert.equal(oldGlyphDefaults.bar.drawerAppearance.animationDuration,250)
const oldAnimationDefault = {bar:{layout:{right:[drawer]},_appDrawerSettingsVersion:2,
  drawerAppearance:{animationDuration:450}}}
context.migrateConfig(oldAnimationDefault)
assert.equal(oldAnimationDefault.bar.drawerAppearance.animationDuration,250)
console.log("App Drawer model edge cases passed")
