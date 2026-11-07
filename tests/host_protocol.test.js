const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const vm = require("node:vm")
const protocol = { Qt: { isQtObject: value => value && value.qmlObject === true } }
vm.createContext(protocol)
vm.runInContext(fs.readFileSync(path.join(__dirname, "..", "DrawerHostProtocol.js"), "utf8"), protocol)

const slot = { qmlObject: true, moduleName: "drawer", region: "right", parent: null }
const other = { qmlObject: true, moduleName: "other", region: "right", parent: slot }
const wrapper = { qmlObject: true, parent: other }
assert.equal(protocol.slotOwner(wrapper, "drawer", "right"), slot)
assert.equal(protocol.slotOwner(wrapper, "other", "right"), other)
assert.equal(protocol.slotOwner(wrapper, "drawer", "left"), null)
assert.equal(protocol.slotOwner(null, "drawer", "right"), null)
assert.equal(protocol.slotOwner({ moduleName: "drawer", region: "right" }, "drawer", "right"), null)
const cycle = { qmlObject: true }
cycle.parent = cycle
assert.equal(protocol.slotOwner(cycle, "drawer", "right"), null)
const inaccessible = { qmlObject: true, get moduleName() { throw new Error("unavailable property") } }
assert.equal(protocol.slotOwner(inaccessible, "drawer", "right"), null)
assert.equal(protocol.windowScreen(null), null)
assert.equal(protocol.windowScreen({ screen: {} }), null)
const screen = { qmlObject: true }
assert.equal(protocol.windowScreen({ screen }), screen)
console.log("drawer ancestor identity, null/cyclic host and actual screen protocol contracts passed")
