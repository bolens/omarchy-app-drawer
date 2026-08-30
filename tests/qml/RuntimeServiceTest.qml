import Quickshell
import QtQuick
import "Model.js" as Model

ShellRoot {
  id: root
  QtObject {
    id: shellMock
    property int mutationCount: 0
    property var shellConfig: ({bar:{layout:{right:["wallpaper","plain","io.github.bolens.app-drawer"]},drawerExpanded:true,drawerAppearance:{animationEnabled:false,hoverToExpand:true}},plugins:[{id:"stale",_omabarDrawerKeepAlive:true}]})
    function mutateShellConfig(mutator) {
      mutationCount++; var copy = JSON.parse(JSON.stringify(shellConfig)); mutator(copy); shellConfig = copy
    }
  }
  QtObject {
    id: registryMock
    property var installedPlugins: ({wallpaper:{kinds:["service","bar-widget"]},plain:{kinds:["bar-widget"]}})
  }
  QtObject {
    id: dp3
    property string openedPage: ""
    property bool open: false
    function showSettings(page) { openedPage = page; open = true }
    function closeSettings() { open = false }
    function settingsStatus() { return {open:open} }
  }
  QtObject {
    id: dp1
    property string openedPage: ""
    property bool open: false
    function showSettings(page) { openedPage = page; open = true }
    function closeSettings() { open = false }
    function settingsStatus() { return {open:open} }
  }
  Service { id: service; shell: shellMock; pluginRegistry: registryMock }

  Component.onCompleted: Qt.callLater(function() {
    if (shellMock.shellConfig.bar._appDrawerSettingsVersion !== 3 || shellMock.shellConfig.plugins.length !== 0
        || shellMock.shellConfig.bar.drawerAppearance.hoverToExpand !== undefined || shellMock.mutationCount !== 1)
      throw new Error("service startup migration failed or was not singular")
    service.ensureMigrated()
    if (shellMock.mutationCount !== 1) throw new Error("idempotent migration rewrote configuration")
    var dp3Generation = service.registerWidget("DP-3", dp3)
    var dp1Generation = service.registerWidget("DP-1", dp1)
    if (dp3Generation < 1 || dp1Generation <= dp3Generation) throw new Error("registration generations did not advance")
    service.setExpandedFor("DP-3", true)
    shellMock.mutateShellConfig(function(config) { Model.applyMonitorExpanded(config, "DP-3", false) })
    service.reconcileMonitorIntents()
    service.toggleFor("DP-3")
    if (!service.expandedFor("DP-3")) throw new Error("idempotent set left a stale monitor intent")
    if (service.openAppearance() !== "opened" || !dp1.open || dp3.open || dp1.openedPage !== "appearance")
      throw new Error("deterministic monitor selection failed")
    if (service.openSettingsOn("DP-3","appearance") !== "opened" || !dp3.open || dp1.open
        || dp3.openedPage !== "appearance")
      throw new Error("monitor-targeted settings routing failed")
    if (!JSON.parse(service.settingsStatus()).open)
      throw new Error("global settings status ignored the open monitor")
    if (!JSON.parse(service.settingsStatusFor("DP-3")).open
        || service.openSettingsOn("missing","widgets") !== "error: no live bar widget for monitor: missing")
      throw new Error("monitor-targeted settings status or rejection failed")
    service.openSettingsOn("DP-1","widgets")
    service.setExpandedFor("DP-1", false)
    if (shellMock.shellConfig.bar.layout.right.length !== 3 || service.expandedFor("DP-1") || !service.expandedFor("DP-3"))
      throw new Error("per-monitor collapse projection failed")
    service.setAlwaysVisible("plain", true)
    if (service.drawerState.alwaysVisible.length !== 1) throw new Error("service pin failed")
    service.queueAlwaysVisible("plain", false)
    service.resetAlwaysVisible()
    if (service.flushQueuedSettings() || service.drawerState.alwaysVisible.length !== 0)
      throw new Error("stale queued pin write survived reset")
    service.updateAppearance({iconSize:27,middleClickAction:"none"})
    if (service.appearance.iconSize !== 27 || service.appearance.middleClickAction !== "none")
      throw new Error("appearance mutation failed")
    service.queueAppearance({iconSize:19})
    service.resetAppearance()
    if (service.flushQueuedSettings() || service.appearance.iconSize !== 14)
      throw new Error("stale queued appearance write survived reset")
    service.setModeFor("DP-1", "hover")
    if (service.modeFor("DP-1") !== "hover" || service.modeFor("DP-3") !== "toggle")
      throw new Error("per-monitor interaction mode failed")
    var serialBeforeInvalidMode = service.mutationSerial
    if (service.setModeFor("DP-1", "invalid") !== "error: invalid monitor mode: invalid"
        || service.modeFor("DP-1") !== "hover" || service.mutationSerial !== serialBeforeInvalidMode)
      throw new Error("invalid monitor mode mutated state")
    service.setModeFor("DP-1", "toggle")
    if (service.lastError !== "" || !JSON.parse(service.monitorStatus("DP-1")).healthy)
      throw new Error("successful mutation did not clear stale IPC error")
    if (service.registeredMonitors() !== '["DP-1","DP-3"]')
      throw new Error("registered monitor discovery was not deterministic")
    var replacementGeneration = service.registerWidget("DP-1", dp1)
    service.unregisterWidget("DP-1", dp1, dp1Generation)
    if (replacementGeneration <= dp1Generation || service.registeredMonitors() !== '["DP-1","DP-3"]')
      throw new Error("stale teardown removed a newer presentation generation")
    var serialBeforeInvalidAppearance = service.mutationSerial
    if (service.updateAppearance([]) !== "error: appearance patch must be an object"
        || service.mutationSerial !== serialBeforeInvalidAppearance)
      throw new Error("invalid appearance patch mutated state")
    service.setExpandedFor("DP-1", true)
    service.reconcileMonitorIntents()
    if (Object.keys(service.monitorIntents).length !== 0)
      throw new Error("persisted monitor intents were not reconciled")
    if (service.lastError !== "") throw new Error("idempotent success did not clear stale IPC error")
    service.toggleFor("DP-1")
    if (service.expandedFor("DP-1") || shellMock.shellConfig.plugins.length !== 0)
      throw new Error("monitor toggle cleanup failed")
    service.unregisterWidget("DP-1", dp1, replacementGeneration)
    service.openSettings()
    if (!dp3.open || dp3.openedPage !== "widgets") throw new Error("widget teardown fallback failed")
    console.log("DRAWER_QML_SERVICE_OK")
    Qt.quit()
  })
}
