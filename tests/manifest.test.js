const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const root = path.join(__dirname, "..")
const manifest = JSON.parse(fs.readFileSync(path.join(root, "manifest.json"), "utf8"))
assert.equal(manifest.schemaVersion, 1)
assert.equal(manifest.id, "io.github.bolens.app-drawer")
assert.equal(manifest.name, "App Drawer")
assert.equal(manifest.version, "2.6.5")
assert.equal(manifest.author, "bolens")
assert.equal(manifest.license, "MIT")
assert.deepEqual(manifest.kinds, ["bar-widget", "service"])
for (const entry of Object.values(manifest.entryPoints)) assert.ok(fs.existsSync(path.join(root, entry)), `missing ${entry}`)
assert.equal(manifest.keepLoaded, true)
assert.equal(manifest.barWidget.allowMultiple, false)
assert.deepEqual(manifest.barWidget.defaults, {
  expandedGlyph:"󰅂", collapsedGlyph:"󰅁", iconSize:14, horizontalMargin:8, verticalPadding:6,
  expandedColorRole:"accent", collapsedColorRole:"foreground", showTooltip:true,
  leftClickAction:"toggle", middleClickAction:"settings", animationEnabled:true, animationDuration:250,
  animationStyle:"taskbar", animationCurve:"smooth",
  hoverCollapseDelay:350
})
console.log("App Drawer manifest contracts passed")
