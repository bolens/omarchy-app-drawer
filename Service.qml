pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Io
import "Model.js" as Model

Item {
  id: root
  property var shell: null
  property var manifest: null
  property var barWidgetRegistry: null
  property var pluginRegistry: null
  readonly property string moduleName: Model.PLUGIN_ID
  readonly property var drawerState: Model.state(shell && shell.shellConfig ? shell.shellConfig : ({}))
  readonly property bool expanded: drawerState.expanded
  readonly property var appearance: drawerState.appearance
  property string lastError: ""
  property int mutationSerial: 0
  property var pendingAppearancePatch: null
  property var pendingPinChanges: null
  property string mutationStatus: ""
  property string mutationDetail: ""
  property int migrationAttempts: 0
  property var monitorIntents: ({})
  property var widgetInstances: []
  property int registrationSerial: 0
  readonly property int settingsVersion: Model.SETTINGS_VERSION
  readonly property int ipcVersion: 1
  readonly property string transitionPhase: "idle"
  readonly property int transitionGeneration: 0
  readonly property bool visualExpanded: expanded

  function registerWidget(screenName, instance) {
    if (!instance) return 0
    var key = String(screenName || "unknown")
    registrationSerial++
    var generation = registrationSerial
    var next = widgetInstances.filter(function(record) {
      return record && record.instance && record.instance !== instance && record.screenName !== key
    }).concat([{screenName: key, instance: instance, generation: generation}])
    next.sort(function(left, right) { return left.screenName.localeCompare(right.screenName) })
    widgetInstances = next
    return generation
  }

  function unregisterWidget(screenName, instance, generation) {
    var legacyCall = instance === undefined || instance === null
    var target = legacyCall ? screenName : instance
    var key = legacyCall ? "" : String(screenName || "").trim()
    var expectedGeneration = Number(generation || 0)
    widgetInstances = widgetInstances.filter(function(record) {
      if (!record || !record.instance) return false
      if (record.instance !== target) return true
      if (key && record.screenName !== key) return true
      if (expectedGeneration > 0 && record.generation !== expectedGeneration) return true
      return false
    })
  }

  function openSettingsFor(preferred, page) {
    var selected = null
    for (var index = 0; index < widgetInstances.length; index++) {
      var instance = widgetInstances[index].instance
      if (!selected && instance && typeof instance.showSettings === "function") selected = instance
      if (instance === preferred && typeof instance.showSettings === "function") selected = instance
    }
    if (!selected) return fail("no live bar widget is available")
    for (index = 0; index < widgetInstances.length; index++) {
      instance = widgetInstances[index].instance
      if (instance !== selected && instance && typeof instance.closeSettings === "function")
        instance.closeSettings()
    }
    selected.showSettings(page)
    lastError = ""
    return "opened"
  }

  function openSettings() { return openSettingsFor(null, "widgets") }
  function openAppearance() { return openSettingsFor(null, "appearance") }

  function widgetForScreen(screenName) {
    var key = String(screenName || "").trim()
    for (var index = 0; index < widgetInstances.length; index++) {
      var record = widgetInstances[index]
      if (record && record.screenName === key && record.instance) return record.instance
    }
    return null
  }

  function openSettingsOn(screenName, page) {
    var key = String(screenName || "").trim()
    if (!key) return fail("monitor name is unavailable")
    var instance = widgetForScreen(key)
    if (!instance || typeof instance.showSettings !== "function")
      return fail("no live bar widget for monitor: " + key)
    return openSettingsFor(instance, page === "appearance" ? "appearance" : "widgets")
  }

  function settingsStatusFor(screenName) {
    var key = String(screenName || "").trim()
    if (!key) return fail("monitor name is unavailable")
    var instance = widgetForScreen(key)
    if (!instance || typeof instance.settingsStatus !== "function")
      return fail("no live bar widget for monitor: " + key)
    lastError = ""
    return JSON.stringify(instance.settingsStatus())
  }

  function scrollSettingsFor(screenName, position) {
    var key = String(screenName || "").trim()
    var requested = String(position || "").trim()
    if (!key) return fail("monitor name is unavailable")
    if (["top", "middle", "bottom"].indexOf(requested) === -1) return fail("invalid scroll position: " + requested)
    var instance = widgetForScreen(key)
    if (!instance || typeof instance.scrollSettings !== "function")
      return fail("no live bar widget for monitor: " + key)
    var result = instance.scrollSettings(requested)
    if (String(result).indexOf("error:") === 0) return fail(String(result).slice(7).trim())
    lastError = ""
    return result
  }

  function closeSettings() {
    var closed = false
    for (var index = 0; index < widgetInstances.length; index++) {
      var instance = widgetInstances[index].instance
      if (instance && typeof instance.closeSettings === "function") {
        instance.closeSettings()
        closed = true
      }
    }
    if (!closed) return fail("no live bar widget is available")
    lastError = ""
    return "closed"
  }

  function settingsStatus() {
    var fallback = null
    for (var index = 0; index < widgetInstances.length; index++) {
      var instance = widgetInstances[index].instance
      if (instance && typeof instance.settingsStatus === "function") {
        var status = instance.settingsStatus()
        if (!fallback) fallback = status
        if (status.open || status.requestedOpen) return JSON.stringify(status)
      }
    }
    if (fallback) return JSON.stringify(fallback)
    return JSON.stringify({open: false, panelWidth: 0, panelHeight: 0, contentHeight: 0, entryCount: 0})
  }

  function fail(message) {
    lastError = String(message || "Unknown drawer error")
    console.warn("App Drawer: " + lastError)
    return "error: " + lastError
  }

  function canMutate() {
    return shell && typeof shell.mutateShellConfig === "function"
  }

  function persistConfig(mutator) {
    try {
      shell.mutateShellConfig(mutator)
      return true
    } catch (error) {
      fail(String(error && error.message ? error.message : error))
      return false
    }
  }

  function currentState() {
    return Model.state(shell && shell.shellConfig ? shell.shellConfig : ({}))
  }

  function ensureMigrated() {
    if (!canMutate() || !shell.shellConfig) return false
    var candidate
    try { candidate = JSON.parse(JSON.stringify(shell.shellConfig)) }
    catch (error) { fail("shell configuration could not be inspected"); return false }
    var preview = Model.migrateConfig(candidate)
    if (!preview.changed) return false
    if (!persistConfig(function(config) { Model.migrateConfig(config) })) return false
    mutationSerial++
    lastError = ""
    return true
  }

  function scheduleMigration() {
    if (drawerState.settingsVersion === settingsVersion) { migrationAttempts = 0; migrationTimer.stop(); return }
    if (migrationAttempts < 20) migrationTimer.restart()
  }

  function expandedFor(screenName) {
    var key = String(screenName || "").trim()
    return key && Object.prototype.hasOwnProperty.call(drawerState.monitorStates, key)
      ? drawerState.monitorStates[key] : drawerState.expanded
  }

  function modeFor(screenName) {
    var key = String(screenName || "").trim()
    return key && Object.prototype.hasOwnProperty.call(drawerState.monitorModes, key)
      ? drawerState.monitorModes[key] : "toggle"
  }

  function reconcileMonitorIntents() {
    if (!Model.isObject(monitorIntents)) { monitorIntents = ({}); return }
    var states = drawerState.monitorStates
    var next = Object.assign({}, monitorIntents)
    var changed = false
    var keys = Object.keys(next)
    for (var index = 0; index < keys.length; index++) {
      var key = keys[index]
      if (Object.prototype.hasOwnProperty.call(states, key) && states[key] === next[key]) {
        delete next[key]
        changed = true
      }
    }
    if (changed) monitorIntents = next
  }

  function prepareMountedLayout(config) {
    Model.migrateConfig(config)
    Model.applyExpanded(config, true)
    Model.removeDrawerKeepAlives(config)
    Model.clearTransition(config)
  }

  function setExpandedFor(screenName, nextExpanded) {
    var key = String(screenName || "").trim()
    var requested = nextExpanded === true
    if (!canMutate()) return fail("shell configuration mutator is unavailable")
    if (!key) return fail("monitor name is unavailable")
    lastError = ""
    var snapshot = currentState()
    if (Model.monitorExpanded(shell.shellConfig, key) === requested && snapshot.right.length > 1)
      return requested ? "expanded" : "collapsed"
    var intents = Object.assign({}, monitorIntents)
    intents[key] = requested
    var previousIntents = monitorIntents
    monitorIntents = intents
    if (!persistConfig(function(config) {
      root.prepareMountedLayout(config)
      Model.applyMonitorExpanded(config, key, requested)
    })) {
      monitorIntents = previousIntents
      return "error: " + lastError
    }
    mutationSerial++
    return requested ? "expanded" : "collapsed"
  }

  function toggleFor(screenName) {
    var key = String(screenName || "").trim()
    if (!canMutate()) return fail("shell configuration mutator is unavailable")
    if (!key) return fail("monitor name is unavailable")
    var base = Object.prototype.hasOwnProperty.call(monitorIntents, key)
      ? monitorIntents[key] : Model.monitorExpanded(shell.shellConfig, key)
    var result = !base
    var intents = Object.assign({}, monitorIntents)
    intents[key] = result
    var previousIntents = monitorIntents
    monitorIntents = intents
    lastError = ""
    if (!persistConfig(function(config) {
      root.prepareMountedLayout(config)
      Model.applyMonitorExpanded(config, key, result)
    })) {
      monitorIntents = previousIntents
      return "error: " + lastError
    }
    mutationSerial++
    return result ? "expanded" : "collapsed"
  }

  function setModeFor(screenName, mode) {
    var key = String(screenName || "").trim()
    var requested = String(mode || "").trim()
    if (!canMutate()) return fail("shell configuration mutator is unavailable")
    if (!key) return fail("monitor name is unavailable")
    if (requested !== "toggle" && requested !== "hover") return fail("invalid monitor mode: " + requested)
    lastError = ""
    var currentModes = currentState().monitorModes
    var currentMode = Object.prototype.hasOwnProperty.call(currentModes, key) ? currentModes[key] : "toggle"
    if (currentMode === requested) return requested
    var result = "toggle"
    if (!persistConfig(function(config) { Model.migrateConfig(config); result = Model.applyMonitorMode(config, key, requested) }))
      return "error: " + lastError
    mutationSerial++
    return result
  }

  function monitorStatus(screenName) {
    var key = String(screenName || "").trim()
    if (!key) return JSON.stringify({screen:"",expanded:false,mode:"toggle",healthy:false})
    return JSON.stringify({screen:key, expanded:expandedFor(key), mode:modeFor(key), healthy:lastError === ""})
  }

  function primaryScreenName() {
    return widgetInstances.length > 0 ? widgetInstances[0].screenName : ""
  }

  function registeredMonitors() {
    var names = widgetInstances.map(function(record) { return String(record.screenName || "").trim() })
      .filter(function(name, index, values) { return name && name !== "unknown" && values.indexOf(name) === index })
    names.sort()
    return JSON.stringify(names)
  }

  function setExpanded(nextExpanded) {
    var requested = nextExpanded === true
    if (!canMutate()) return fail("shell configuration mutator is unavailable")
    var screens = widgetInstances.map(function(record) { return record.screenName }).filter(function(name, index, values) {
      return name && name !== "unknown" && values.indexOf(name) === index
    })
    if (screens.length === 0) return fail("no live monitor is available")
    var intents = Object.assign({}, monitorIntents)
    for (var intentIndex = 0; intentIndex < screens.length; intentIndex++) intents[screens[intentIndex]] = requested
    var previousIntents = monitorIntents
    monitorIntents = intents
    lastError = ""
    if (!persistConfig(function(config) {
      root.prepareMountedLayout(config)
      for (var index = 0; index < screens.length; index++) Model.applyMonitorExpanded(config, screens[index], requested)
    })) {
      monitorIntents = previousIntents
      return "error: " + lastError
    }
    mutationSerial++
    return requested ? "expanded" : "collapsed"
  }

  function toggle() {
    return toggleFor(primaryScreenName())
  }

  function knownEntry(id) {
    var key = String(id || "").trim()
    if (!key || key === moduleName) return false
    var entries = drawerState.saved.concat(drawerState.right)
    return entries.some(function(entry) { return Model.entryId(entry) === key })
  }

  function setAlwaysVisible(id, enabled) {
    var key = String(id || "").trim()
    if (!canMutate()) return fail("shell configuration mutator is unavailable")
    if (!knownEntry(key)) return fail("unknown or invalid widget id: " + key)
    if ((Model.isObject(pendingPinChanges) || Model.isObject(pendingAppearancePatch))
        && !flushQueuedSettings()) return "error: " + lastError
    var requested = enabled === true
    var currentlyPinned = currentState().alwaysVisible.indexOf(key) !== -1
    if (currentlyPinned === requested) {
      lastError = ""
      return requested ? "pinned" : "unpinned"
    }
    var outcome = null
    lastError = ""
    if (!persistConfig(function(config) {
      Model.migrateConfig(config)
      outcome = Model.applyPinned(config, key, enabled)
    })) return "error: " + lastError
    if (!outcome || !outcome.ok) return fail("unknown or invalid widget id: " + key)
    if (outcome.changed) mutationSerial++
    return enabled === true ? "pinned" : "unpinned"
  }

  function queueAlwaysVisible(id, enabled) {
    var key = String(id || "").trim()
    if (!knownEntry(key)) return fail("unknown or invalid widget id: " + key)
    var next = Model.isObject(pendingPinChanges) ? Object.assign({}, pendingPinChanges) : ({})
    next[key] = enabled === true
    pendingPinChanges = next
    mutationStatus = "saving"
    mutationDetail = ""
    mutationFeedbackTimer.stop()
    settingsCommitTimer.restart()
    return "queued"
  }

  function resetAlwaysVisible() {
    if (!canMutate()) return fail("shell configuration mutator is unavailable")
    pendingPinChanges = null
    syncSettingsCommitTimer()
    if (currentState().alwaysVisible.length === 0) { lastError = ""; return "reset" }
    var changed = false
    lastError = ""
    if (!persistConfig(function(config) { Model.migrateConfig(config); changed = Model.resetPinned(config) }))
      return "error: " + lastError
    if (changed) mutationSerial++
    return "reset"
  }

  function updateAppearance(patch) {
    if (!canMutate()) return fail("shell configuration mutator is unavailable")
    if (!Model.isObject(patch)) return fail("appearance patch must be an object")
    if ((Model.isObject(pendingAppearancePatch) || Model.isObject(pendingPinChanges))
        && !flushQueuedSettings()) return "error: " + lastError
    var currentAppearance = currentState().appearance
    var merged = Object.assign({}, currentAppearance)
    for (var key in patch) merged[key] = patch[key]
    var normalized = Model.appearanceSettings(merged)
    if (JSON.stringify(normalized) === JSON.stringify(currentAppearance)) {
      lastError = ""
      return "unchanged"
    }
    lastError = ""
    if (!persistConfig(function(config) { Model.migrateConfig(config); Model.applyAppearance(config, patch) }))
      return "error: " + lastError
    mutationSerial++
    return "updated"
  }

  function queueAppearance(patch) {
    if (!Model.isObject(patch)) return fail("appearance patch must be an object")
    var next = Model.isObject(pendingAppearancePatch) ? Object.assign({}, pendingAppearancePatch) : ({})
    for (var key in patch) next[key] = patch[key]
    var currentAppearance = currentState().appearance
    var merged = Object.assign({}, currentAppearance)
    for (var pendingKey in next) merged[pendingKey] = next[pendingKey]
    if (JSON.stringify(Model.appearanceSettings(merged)) === JSON.stringify(currentAppearance)
        && !Model.isObject(pendingPinChanges)) {
      pendingAppearancePatch = null
      settingsCommitTimer.stop()
      lastError = ""
      return "unchanged"
    }
    pendingAppearancePatch = next
    mutationStatus = "saving"
    mutationDetail = ""
    mutationFeedbackTimer.stop()
    settingsCommitTimer.restart()
    return "queued"
  }

  function syncSettingsCommitTimer() {
    if (Model.isObject(pendingAppearancePatch) || Model.isObject(pendingPinChanges))
      settingsCommitTimer.restart()
    else settingsCommitTimer.stop()
  }

  function flushQueuedSettings() {
    if (!Model.isObject(pendingAppearancePatch) && !Model.isObject(pendingPinChanges)) return false
    var appearancePatch = pendingAppearancePatch
    var pinChanges = pendingPinChanges
    pendingAppearancePatch = null
    pendingPinChanges = null
    try {
      shell.mutateShellConfig(function(config) {
        Model.migrateConfig(config)
        if (Model.isObject(appearancePatch)) Model.applyAppearance(config, appearancePatch)
        if (Model.isObject(pinChanges)) {
          var ids = Object.keys(pinChanges).sort()
          for (var index = 0; index < ids.length; index++) Model.applyPinned(config, ids[index], pinChanges[ids[index]])
        }
      })
      mutationSerial++
      lastError = ""
      mutationStatus = "saved"
      mutationDetail = ""
    } catch (error) {
      var detail = String(error && error.message ? error.message : error)
      pendingAppearancePatch = appearancePatch
      pendingPinChanges = pinChanges
      fail(detail)
      mutationStatus = "failed"
      mutationDetail = detail
    }
    mutationFeedbackTimer.restart()
    return mutationStatus === "saved"
  }

  function resetAppearance() {
    if (!canMutate()) return fail("shell configuration mutator is unavailable")
    pendingAppearancePatch = null
    syncSettingsCommitTimer()
    if (JSON.stringify(currentState().appearance) === JSON.stringify(Model.appearanceSettings({}))) {
      lastError = ""
      return "unchanged"
    }
    lastError = ""
    if (!persistConfig(function(config) { Model.migrateConfig(config); Model.resetAppearance(config) }))
      return "error: " + lastError
    mutationSerial++
    return "reset"
  }

  function displayName(entry) {
    var id = Model.entryId(entry)
    var metadata = barWidgetRegistry && typeof barWidgetRegistry.metadataFor === "function"
      ? barWidgetRegistry.metadataFor(id) : null
    return metadata && metadata.displayName ? String(metadata.displayName) : id
  }

  function statusObject() {
    var presentations = []
    for (var index = 0; index < widgetInstances.length; index++) {
      var instance = widgetInstances[index].instance
      if (instance && typeof instance.animationStatus === "function") {
        var presentation = instance.animationStatus()
        presentation.registrationGeneration = widgetInstances[index].generation
        presentations.push(presentation)
      }
    }
    return {
      expanded: expanded,
      visibleEntries: drawerState.right.length,
      savedEntries: drawerState.saved.length,
      savedIds: drawerState.saved.map(function(entry) { return Model.entryId(entry) }),
      alwaysVisible: drawerState.alwaysVisible,
      appearance: appearance,
      visualExpanded: visualExpanded,
      transitionPhase: transitionPhase,
      transitionGeneration: transitionGeneration,
      monitorStates: drawerState.monitorStates,
      monitorModes: drawerState.monitorModes,
      monitorIntents: monitorIntents,
      presentations: presentations,
      mutationSerial: mutationSerial,
      registrationSerial: registrationSerial,
      mutationStatus: mutationStatus,
      mutationDetail: mutationDetail,
      settingsVersion: settingsVersion,
      ipcVersion: ipcVersion,
      healthy: lastError === "",
      lastError: lastError
    }
  }

  IpcHandler {
    target: "app-drawer"
    function status(): string { return JSON.stringify(root.statusObject()) }
    function expand(): string { return root.setExpanded(true) }
    function collapse(): string { return root.setExpanded(false) }
    function openSettings(): string { return root.openSettings() }
    function openAppearance(): string { return root.openAppearance() }
    function closeSettings(): string { return root.closeSettings() }
    function settingsStatus(): string { return root.settingsStatus() }
    function openMonitorSettings(screen: string): string { return root.openSettingsOn(screen, "widgets") }
    function openMonitorAppearance(screen: string): string { return root.openSettingsOn(screen, "appearance") }
    function settingsStatusFor(screen: string): string { return root.settingsStatusFor(screen) }
    function scrollSettingsFor(screen: string, position: string): string { return root.scrollSettingsFor(screen, position) }
    function pin(id: string): string { return root.setAlwaysVisible(id, true) }
    function unpin(id: string): string { return root.setAlwaysVisible(id, false) }
    function resetPins(): string { return root.resetAlwaysVisible() }
    function setAppearance(payload: string): string {
      try { return root.updateAppearance(JSON.parse(payload)) }
      catch (error) { return root.fail("invalid appearance JSON") }
    }
    function resetAppearance(): string { return root.resetAppearance() }
    function setExpanded(expanded: bool): string { return root.setExpanded(expanded) }
    function setMonitorExpanded(screen: string, expanded: bool): string { return root.setExpandedFor(screen, expanded) }
    function toggleMonitor(screen: string): string { return root.toggleFor(screen) }
    function setMonitorMode(screen: string, mode: string): string { return root.setModeFor(screen, mode) }
    function monitorStatus(screen: string): string { return root.monitorStatus(screen) }
    function registeredMonitors(): string { return root.registeredMonitors() }
    function toggle(): string { return root.toggle() }
  }

  Timer { id: settingsCommitTimer; interval: 75; repeat: false; onTriggered: root.flushQueuedSettings() }
  Timer {
    id: migrationTimer
    interval: 50
    repeat: false
    onTriggered: {
      root.migrationAttempts++
      root.ensureMigrated()
      if (root.drawerState.settingsVersion !== root.settingsVersion && root.migrationAttempts < 20) restart()
    }
  }
  Timer {
    id: mutationFeedbackTimer
    interval: 1800
    repeat: false
    onTriggered: { root.mutationStatus = ""; root.mutationDetail = "" }
  }

  onShellChanged: scheduleMigration()
  onDrawerStateChanged: { reconcileMonitorIntents(); scheduleMigration() }
  Component.onCompleted: { ensureMigrated(); scheduleMigration() }
}
