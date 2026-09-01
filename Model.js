.pragma library

var PLUGIN_ID = "io.github.bolens.app-drawer"
var SETTINGS_VERSION = 3
var APPEARANCE_DEFAULTS = {
  expandedGlyph: "󰅂", collapsedGlyph: "󰅁", iconSize: 14,
  horizontalMargin: 8, verticalPadding: 6,
  expandedColorRole: "accent", collapsedColorRole: "foreground",
  showTooltip: true, leftClickAction: "toggle", middleClickAction: "settings",
  animationEnabled: true, animationDuration: 250,
  animationStyle: "taskbar", animationCurve: "smooth", hoverCollapseDelay: 350
}

function isObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value)
}

function isBoundedList(value) {
  return boundedListLength(value) >= 0
}

function boundedListLength(value) {
  if (!value || typeof value !== "object") return -1
  var length = Number(value.length)
  return isFinite(length) && length >= 0 && Math.floor(length) === length && length <= 4096 ? length : -1
}

function listFrom(value) {
  var length = boundedListLength(value)
  if (length < 0) return []
  var result = []
  for (var index = 0; index < length; index++) result.push(value[index])
  return result
}

function entryId(entry) {
  if (typeof entry === "string") return entry.trim()
  if (!isObject(entry)) return ""
  return String(entry.id || entry.plugin || entry.module || "").trim()
}

function uniqueIds(values) {
  var result = []
  var source = listFrom(values)
  for (var index = 0; index < source.length; index++) {
    var id = String(source[index] || "").trim()
    if (id && id !== PLUGIN_ID && result.indexOf(id) === -1) result.push(id)
  }
  return result
}

function validEntries(values) {
  return listFrom(values).filter(function(entry) { return entryId(entry) !== "" })
}

function withoutDrawer(values) {
  return validEntries(values).filter(function(entry) { return entryId(entry) !== PLUGIN_ID })
}

function drawerEntry(values) {
  var entries = validEntries(values)
  for (var index = 0; index < entries.length; index++) {
    if (entryId(entries[index]) === PLUGIN_ID) return entries[index]
  }
  return PLUGIN_ID
}

function collapsedEntries(expandedEntries, alwaysVisible, toggleEntry) {
  var pinned = uniqueIds(alwaysVisible)
  var source = withoutDrawer(expandedEntries)
  var result = source.filter(function(entry) { return pinned.indexOf(entryId(entry)) !== -1 })
  result.push(toggleEntry || PLUGIN_ID)
  return result
}

function restoredEntries(savedEntries, currentEntries, toggleEntry) {
  var result = withoutDrawer(savedEntries).slice()
  var current = withoutDrawer(currentEntries)
  var ids = result.map(entryId)
  for (var index = 0; index < current.length; index++) {
    var id = entryId(current[index])
    if (ids.indexOf(id) === -1) {
      result.push(current[index])
      ids.push(id)
    }
  }
  result.push(toggleEntry || drawerEntry(currentEntries))
  return result
}

function state(config) {
  var bar = isObject(config) && isObject(config.bar) ? config.bar : ({})
  var layout = isObject(bar.layout) ? bar.layout : ({})
  return {
    expanded: bar.drawerExpanded !== false,
    right: validEntries(layout.right),
    saved: validEntries(bar.drawerExpandedEntries),
    alwaysVisible: uniqueIds(bar.drawerAlwaysVisible),
    appearance: appearanceSettings(bar.drawerAppearance),
    transition: transitionSettings(bar.drawerTransition),
    monitorStates: monitorBooleanMap(bar.drawerMonitorStates),
    monitorModes: monitorModeMap(bar.drawerMonitorModes),
    settingsVersion: boundedInteger(bar._appDrawerSettingsVersion, 0, 0, SETTINGS_VERSION)
  }
}

function monitorBooleanMap(value) {
  var result = {}
  if (!isObject(value)) return result
  var keys = Object.keys(value).sort()
  for (var index = 0; index < keys.length; index++) {
    var key = String(keys[index] || "").trim()
    if (key) result[key] = value[keys[index]] === true
  }
  return result
}

function monitorModeMap(value) {
  var result = {}
  if (!isObject(value)) return result
  var keys = Object.keys(value).sort()
  for (var index = 0; index < keys.length; index++) {
    var key = String(keys[index] || "").trim()
    if (key) result[key] = enumValue(value[keys[index]], ["toggle", "hover"], "toggle")
  }
  return result
}

function monitorExpanded(config, screenName) {
  var snapshot = state(config)
  var key = String(screenName || "").trim()
  return key && Object.prototype.hasOwnProperty.call(snapshot.monitorStates, key)
    ? snapshot.monitorStates[key] : snapshot.expanded
}

function applyMonitorExpanded(config, screenName, requested) {
  var bar = ensureBar(config)
  var key = String(screenName || "").trim()
  if (!key) return false
  var states = monitorBooleanMap(bar.drawerMonitorStates)
  states[key] = requested === true
  bar.drawerMonitorStates = states
  return states[key]
}

function applyMonitorMode(config, screenName, mode) {
  var bar = ensureBar(config)
  var key = String(screenName || "").trim()
  if (!key) return "toggle"
  var modes = monitorModeMap(bar.drawerMonitorModes)
  modes[key] = enumValue(mode, ["toggle", "hover"], "toggle")
  bar.drawerMonitorModes = modes
  return modes[key]
}

function transitionSettings(value) {
  var source = isObject(value) ? value : ({})
  var phase = enumValue(source.phase, ["idle", "expanding", "collapsing"], "idle")
  return {
    phase: phase,
    generation: boundedInteger(source.generation, 0, 0, 2147483647),
    expiresAt: phase === "idle" || !isFinite(Number(source.expiresAt)) ? 0 : Math.max(0, Math.round(Number(source.expiresAt)))
  }
}

function beginTransition(config, phase, generation, duration, now) {
  var bar = ensureBar(config)
  var safePhase = enumValue(phase, ["expanding", "collapsing"], "collapsing")
  bar.drawerTransition = {
    phase: safePhase,
    generation: boundedInteger(generation, 0, 0, 2147483647),
    expiresAt: Math.max(0, Math.round(Number(now) || 0)) + boundedInteger(duration, 180, 80, 600)
  }
  return bar.drawerTransition
}

function clearTransition(config, generation) {
  var bar = ensureBar(config)
  var current = transitionSettings(bar.drawerTransition)
  if (generation !== undefined && current.generation !== generation) return false
  delete bar.drawerTransition
  return true
}

function boundedInteger(value, fallback, minimum, maximum) {
  var parsed = Number(value)
  if (!isFinite(parsed)) parsed = fallback
  return Math.max(minimum, Math.min(maximum, Math.round(parsed)))
}

function enumValue(value, allowed, fallback) {
  var candidate = String(value || "")
  return allowed.indexOf(candidate) !== -1 ? candidate : fallback
}

function glyphValue(value, fallback) {
  var candidate = String(value === undefined || value === null ? "" : value).trim()
  return candidate && candidate.length <= 8 ? candidate : fallback
}

function revealExtent(style, progress, extent, trailingExtent, totalExtent) {
  var mode = enumValue(style, ["taskbar", "cascade", "softCascade", "uniform"], "taskbar")
  var p = Math.max(0, Math.min(1, Number(progress) || 0))
  var own = Math.max(0, Number(extent) || 0)
  var trailing = Math.max(0, Number(trailingExtent) || 0)
  var total = Math.max(0, Number(totalExtent) || 0)
  // Every animated style uses the proven fixed-spacing wipe geometry. Visual
  // variants are compositor-friendly opacity treatments in revealOpacity().
  return Math.max(0, Math.min(own, total * p - trailing))
}

function revealOpacity(style, progress, extent, trailingExtent, totalExtent) {
  var mode = enumValue(style, ["taskbar", "cascade", "softCascade", "uniform"], "taskbar")
  var p = Math.max(0, Math.min(1, Number(progress) || 0))
  if (mode === "taskbar") return 1
  if (mode === "uniform") return p <= 0 ? 0 : 0.2 + 0.8 * p
  var own = Math.max(0, Number(extent) || 0)
  var trailing = Math.max(0, Number(trailingExtent) || 0)
  var total = Math.max(0, Number(totalExtent) || 0)
  if (mode === "cascade") {
    var spatialStart = total > 0 ? trailing / total : 0
    var fadeSpan = 0.18
    var local = Math.max(0, Math.min(1, (p - spatialStart) / fadeSpan))
    return local * local * (3 - 2 * local)
  }
  var visible = revealExtent(mode, p, own, trailing, total)
  if (visible <= 0) return 0
  if (visible >= own) return 1
  return 0.25 + 0.75 * visible / Math.max(1, own)
}

function appearanceSettings(value) {
  var source = isObject(value) ? value : ({})
  return {
    expandedGlyph: glyphValue(source.expandedGlyph, APPEARANCE_DEFAULTS.expandedGlyph),
    collapsedGlyph: glyphValue(source.collapsedGlyph, APPEARANCE_DEFAULTS.collapsedGlyph),
    iconSize: boundedInteger(source.iconSize, APPEARANCE_DEFAULTS.iconSize, 10, 30),
    horizontalMargin: boundedInteger(source.horizontalMargin, APPEARANCE_DEFAULTS.horizontalMargin, 2, 18),
    verticalPadding: boundedInteger(source.verticalPadding, APPEARANCE_DEFAULTS.verticalPadding, 2, 12),
    expandedColorRole: enumValue(source.expandedColorRole, ["foreground", "accent", "muted", "urgent"], APPEARANCE_DEFAULTS.expandedColorRole),
    collapsedColorRole: enumValue(source.collapsedColorRole, ["foreground", "accent", "muted", "urgent"], APPEARANCE_DEFAULTS.collapsedColorRole),
    showTooltip: source.showTooltip !== false,
    leftClickAction: enumValue(source.leftClickAction, ["toggle", "expand", "collapse"], APPEARANCE_DEFAULTS.leftClickAction),
    middleClickAction: enumValue(source.middleClickAction, ["settings", "toggle", "none"], APPEARANCE_DEFAULTS.middleClickAction),
    animationEnabled: source.animationEnabled !== false,
    animationDuration: boundedInteger(source.animationDuration, APPEARANCE_DEFAULTS.animationDuration, 80, 1000),
    animationStyle: enumValue(source.animationStyle, ["taskbar", "cascade", "softCascade", "uniform", "instant"], APPEARANCE_DEFAULTS.animationStyle),
    animationCurve: enumValue(source.animationCurve, ["smooth", "quick", "gentle", "linear"], APPEARANCE_DEFAULTS.animationCurve),
    hoverCollapseDelay: boundedInteger(source.hoverCollapseDelay, APPEARANCE_DEFAULTS.hoverCollapseDelay, 100, 2000)
  }
}

function applyAppearance(config, patch) {
  var bar = ensureBar(config)
  var merged = appearanceSettings(bar.drawerAppearance)
  if (isObject(patch)) for (var key in patch) merged[key] = patch[key]
  bar.drawerAppearance = appearanceSettings(merged)
  return bar.drawerAppearance
}

function resetAppearance(config) {
  var bar = ensureBar(config)
  bar.drawerAppearance = appearanceSettings({})
  return bar.drawerAppearance
}

function migrateConfig(config) {
  if (!isObject(config)) return {changed: false, version: SETTINGS_VERSION}
  var before = JSON.stringify(config)
  var bar = ensureBar(config)
  var sourceVersion = boundedInteger(bar._appDrawerSettingsVersion, 0, 0, SETTINGS_VERSION)
  if (sourceVersion < 2 && isObject(bar.drawerAppearance)) {
    if (bar.drawerAppearance.expandedGlyph === "󰅀" && bar.drawerAppearance.collapsedGlyph === "󰅂") {
      bar.drawerAppearance.expandedGlyph = APPEARANCE_DEFAULTS.expandedGlyph
      bar.drawerAppearance.collapsedGlyph = APPEARANCE_DEFAULTS.collapsedGlyph
    }
    if (bar.drawerAppearance.animationDuration === 600)
      bar.drawerAppearance.animationDuration = APPEARANCE_DEFAULTS.animationDuration
  }
  if (sourceVersion < 3 && isObject(bar.drawerAppearance)
      && bar.drawerAppearance.animationDuration === 450)
    bar.drawerAppearance.animationDuration = APPEARANCE_DEFAULTS.animationDuration
  bar.drawerExpandedEntries = validEntries(bar.drawerExpandedEntries)
  bar.drawerAlwaysVisible = uniqueIds(bar.drawerAlwaysVisible)
  bar.drawerAppearance = appearanceSettings(bar.drawerAppearance)
  bar.drawerMonitorStates = monitorBooleanMap(bar.drawerMonitorStates)
  bar.drawerMonitorModes = monitorModeMap(bar.drawerMonitorModes)
  delete bar.drawerTransition
  bar._appDrawerSettingsVersion = SETTINGS_VERSION
  removeDrawerKeepAlives(config)
  return {changed: JSON.stringify(config) !== before, version: SETTINGS_VERSION}
}

function ensureBar(config) {
  if (!isObject(config.bar)) config.bar = {}
  if (!isObject(config.bar.layout)) config.bar.layout = {}
  if (!Array.isArray(config.bar.layout.right)) config.bar.layout.right = []
  return config.bar
}

function applyExpanded(config, requested) {
  var bar = ensureBar(config)
  var current = validEntries(bar.layout.right)
  var toggle = drawerEntry(current)
  if (requested === true) {
    bar.layout.right = restoredEntries(bar.drawerExpandedEntries, current, toggle)
    bar.drawerExpanded = true
  } else {
    // Only a genuinely expanded layout may replace the durable snapshot.
    // Repeated collapse calls otherwise shrink it to the pinned subset.
    if (bar.drawerExpanded !== false) {
      var snapshot = withoutDrawer(current)
      if (snapshot.length > 0) bar.drawerExpandedEntries = snapshot
    }
    bar.drawerExpandedEntries = validEntries(bar.drawerExpandedEntries)
    bar.layout.right = collapsedEntries(bar.drawerExpandedEntries, bar.drawerAlwaysVisible, toggle)
    bar.drawerExpanded = false
  }
  return bar.drawerExpanded
}

function toggleExpanded(config) {
  var bar = ensureBar(config)
  return applyExpanded(config, bar.drawerExpanded === false)
}

function applyPinned(config, id, enabled) {
  var key = String(id || "").trim()
  var bar = ensureBar(config)
  var known = withoutDrawer(validEntries(bar.drawerExpandedEntries).concat(validEntries(bar.layout.right)))
    .some(function(entry) { return entryId(entry) === key })
  if (!key || key === PLUGIN_ID || !known) return {ok: false, changed: false, value: false}
  var pinned = uniqueIds(bar.drawerAlwaysVisible)
  var found = pinned.indexOf(key)
  var requested = enabled === true
  var changed = false
  if (requested && found === -1) { pinned.push(key); changed = true }
  else if (!requested && found !== -1) { pinned.splice(found, 1); changed = true }
  bar.drawerAlwaysVisible = pinned
  if (bar.drawerExpanded === false)
    bar.layout.right = collapsedEntries(bar.drawerExpandedEntries, pinned, drawerEntry(bar.layout.right))
  return {ok: true, changed: changed, value: requested}
}

function resetPinned(config) {
  var bar = ensureBar(config)
  var changed = uniqueIds(bar.drawerAlwaysVisible).length > 0
  bar.drawerAlwaysVisible = []
  if (bar.drawerExpanded === false)
    bar.layout.right = collapsedEntries(bar.drawerExpandedEntries, [], drawerEntry(bar.layout.right))
  return changed
}

function removeDrawerKeepAlives(config) {
  if (!isObject(config) || !Array.isArray(config.plugins)) return false
  var before = config.plugins.length
  config.plugins = config.plugins.filter(function(plugin) {
    return !isObject(plugin) || (plugin._omabarDrawerKeepAlive !== true && plugin._appDrawerKeepAlive !== true)
  })
  return config.plugins.length !== before
}
