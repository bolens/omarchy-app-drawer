// Explicit protocols for the injected window and stock-bar ancestor slot.
function member(receiver, key) {
  if (receiver === null || receiver === undefined) return undefined
  try { return receiver[key] } catch (error) { return undefined }
}

function windowScreen(window) {
  const screen = member(window, "screen")
  return screen && Qt.isQtObject(screen) ? screen : null
}

function slotOwner(candidate, moduleName, region) {
  const visited = []
  while (candidate && Qt.isQtObject(candidate) && visited.indexOf(candidate) === -1) {
    if (member(candidate, "moduleName") === moduleName && member(candidate, "region") === region) return candidate
    visited.push(candidate)
    candidate = member(candidate, "parent")
  }
  return null
}
