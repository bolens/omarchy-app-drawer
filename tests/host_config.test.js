const assert = require("node:assert/strict")
const fs = require("node:fs")
const vm = require("node:vm")
const path = require("node:path")
const Model = {}
vm.createContext(Model)
vm.runInContext(fs.readFileSync(path.join(__dirname,"../Model.js"),"utf8").replace(/^\.pragma library\s*$/m,""),Model)
const plain = value => JSON.parse(JSON.stringify(value))
const legacy = {shellConfig:{bar:{drawerAlwaysVisible:["audio"]},other:"preserved"}}
assert.equal(Model.configForHost(legacy), legacy.shellConfig)
const entry={id:Model.PLUGIN_ID, custom:{keep:true}, drawerState:{drawerAlwaysVisible:["network"], future:"preserved", layout:{right:[]}}}
const bar={layout:{right:["audio",entry]},drawerAlwaysVisible:["audio"],drawerAppearance:{iconSize:23}}
const before=JSON.stringify(bar)
const config=Model.configForHost({barConfig:bar})
assert.deepEqual(plain(config.bar.drawerAlwaysVisible), ["network"])
assert.deepEqual(plain(config.bar.layout), bar.layout)
assert.equal(JSON.stringify(bar),before)
config.bar.drawerAppearance={iconSize:25}
config.bar.layout.right=[]
const saved=plain(Model.scopedDrawerSettings(entry,config))
assert.deepEqual(saved.custom,{keep:true})
assert.equal(saved.drawerState.future,"preserved")
assert.equal(saved.drawerState.drawerAppearance.iconSize,25)
assert.deepEqual(saved.drawerState.layout,entry.drawerState.layout)
assert.equal(JSON.stringify(bar),before)
assert.equal(Model.drawerEntrySettings({layout:{right:[Model.PLUGIN_ID]}}),null)
console.log("Scoped host settings and preservation contracts passed")
