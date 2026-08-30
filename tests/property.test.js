const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const vm = require("node:vm")
const source = fs.readFileSync(path.join(__dirname, "..", "Model.js"), "utf8").replace(/^\.pragma library\s*$/m, "")
const Model = {}; vm.createContext(Model); vm.runInContext(source, Model)
let seed = 0x5eed1234
const random = () => ((seed = (seed * 1664525 + 1013904223) >>> 0) / 0x100000000)
const ids = values => Array.from(values, Model.entryId)

for (let trial = 0; trial < 500; trial++) {
  const count = 1 + Math.floor(random() * 30)
  const entries = []
  for (let index = 0; index < count; index++) {
    const id = `widget-${index}`
    entries.push(random() < 0.5 ? id : {id, value:index, nested:{trial}})
  }
  entries.push(Model.PLUGIN_ID)
  const config = {bar:{layout:{right:entries},drawerExpanded:true,drawerAlwaysVisible:entries
    .filter(() => random() < 0.2).map(Model.entryId),left:[{id:"workspace-sentinel",trial}],center:["clock"]},plugins:[]}
  const untouched = JSON.stringify({left:config.bar.layout.left,center:config.bar.layout.center})
  const originalIds = ids(entries)
  Model.applyExpanded(config, false)
  const once = JSON.stringify(config)
  Model.applyExpanded(config, false)
  assert.equal(JSON.stringify(config), once)
  assert.equal(ids(config.bar.layout.right).at(-1), Model.PLUGIN_ID)
  assert.equal(new Set(ids(config.bar.layout.right)).size, config.bar.layout.right.length)
  Model.applyExpanded(config, true)
  assert.deepEqual(ids(config.bar.layout.right), originalIds)
  const restored = JSON.stringify(config)
  Model.applyExpanded(config, true)
  assert.equal(JSON.stringify(config), restored)
  assert.equal(JSON.stringify({left:config.bar.layout.left,center:config.bar.layout.center}), untouched,
    "drawer transitions changed a non-right layout section")
}

for (let trial = 0; trial < 500; trial++) {
  const raw = {
    expandedGlyph: random() < 0.5 ? "X" : "",
    collapsedGlyph: random() < 0.5 ? "Y" : "123456789",
    iconSize: (random() - 0.5) * 200,
    horizontalMargin: (random() - 0.5) * 100,
    verticalPadding: random() < 0.2 ? NaN : random() * 50,
    expandedColorRole: random() < 0.5 ? "urgent" : "invalid",
    leftClickAction: random() < 0.5 ? "expand" : "invalid",
    animationDuration: (random() - 0.5) * 2000
  }
  const value = Model.appearanceSettings(raw)
  assert.ok(value.iconSize >= 10 && value.iconSize <= 30)
  assert.ok(value.horizontalMargin >= 2 && value.horizontalMargin <= 18)
  assert.ok(value.verticalPadding >= 2 && value.verticalPadding <= 12)
  assert.ok(["foreground","accent","muted","urgent"].includes(value.expandedColorRole))
  assert.ok(["toggle","expand","collapse"].includes(value.leftClickAction))
  assert.ok(value.animationDuration >= 80 && value.animationDuration <= 1000)
  assert.ok(value.hoverCollapseDelay >= 100 && value.hoverCollapseDelay <= 2000)
  assert.ok(value.expandedGlyph.length > 0 && value.expandedGlyph.length <= 8)
  assert.ok(value.collapsedGlyph.length > 0 && value.collapsedGlyph.length <= 8)
}
console.log("App Drawer randomized invariants passed (1000 trials)")
