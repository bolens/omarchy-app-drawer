const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const vm = require("node:vm")

function method(file, name) {
  const source = fs.readFileSync(path.join(__dirname, "..", file), "utf8")
  const start = source.indexOf(`function ${name}(`)
  assert.ok(start >= 0, `${name} must remain an actual QML method`)
  for (let end = source.indexOf("}", start); end >= 0; end = source.indexOf("}", end + 1)) {
    try { return new vm.Script(`(${source.slice(start, end + 1)})`) }
    catch (error) { if (!(error instanceof SyntaxError)) throw error }
  }
  throw new Error(`No complete method ${name}`)
}

for (const preferredIndex of [0, 1]) {
  const events = []
  const instances = [0, 1].map(index => ({
    showSettings(page) { events.push(["show", index, page]) },
    closeSettings() { events.push(["close", index]) },
  }))
  const context = { widgetInstances: instances.map(instance => ({ instance })), lastError: "before", fail() { throw new Error("unexpected failure") } }
  const result = method("Service.qml", "openSettingsFor").runInNewContext(context)(instances[preferredIndex], "appearance")
  assert.equal(result, "opened")
  assert.deepEqual(events, [["close", 1 - preferredIndex], ["show", preferredIndex, "appearance"]])
  assert.equal(context.lastError, "")
}

for (const vertical of [false, true]) {
  const slots = [1, 2, 3].map(number => ({ number, implicitWidth: number * 10, implicitHeight: number * 40 }))
  const calls = []
  const root = {
    animatedClipBinding() { return () => true },
    animatedOpacityBinding(slotExtent, trailing, total) { return () => [slotExtent, trailing, total] },
    animatedWidthBinding(slot, extent, trailing, total) { calls.push([slot.number, extent, trailing, total]); return () => extent },
    animatedHeightBinding(slot, extent, trailing, total) { calls.push([slot.number, extent, trailing, total]); return () => extent },
  }
  let finished = 0
  const context = {
    root, bar: { vertical }, slotBindingGeneration: 7, drawerService: {},
    localTransitionSlots: () => slots, finishSlotBindingMeasurement() { finished++ },
    lastAnimationSlotCount: 0, lastAnimationTotalExtent: 0,
    Qt: { binding: factory => factory },
  }
  method("BarWidget.qml", "attachSlotBindings").runInNewContext(context)(7)
  const unit = vertical ? 40 : 10
  assert.deepEqual(calls, [[3, 3 * unit, 0, 6 * unit], [2, 2 * unit, 3 * unit, 6 * unit], [1, unit, 5 * unit, 6 * unit]])
  assert.equal(context.lastAnimationSlotCount, 3)
  assert.equal(context.lastAnimationTotalExtent, 6 * unit)
  assert.equal(finished, 1)
}

console.log("actual service and reveal-loop scope contracts passed")
