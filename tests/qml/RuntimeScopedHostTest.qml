pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import "Model.js" as Model

ShellRoot {
  id: root
  QtObject {
    id: scopedHost
    property bool rejectWrites: false
    property var unrelated: ({theme: "preserved"})
    property var barConfig: ({layout: {left: ["launcher"], right: ["audio", {id: Model.PLUGIN_ID, custom: "preserved"}]},
      drawerAlwaysVisible: ["audio"], drawerAppearance: {iconSize: 23},
      drawerMonitorModes: {fixture: "hover"}, _appDrawerSettingsVersion: Model.SETTINGS_VERSION})
    function updateEntryInline(id, entry) {
      if (rejectWrites) return false
      var next = JSON.parse(JSON.stringify(barConfig))
      next.layout.right = next.layout.right.map(function(item) {
        return item && item.id === id ? entry : item
      })
      barConfig = next
      return true
    }
  }
  Service { id: service; shell: scopedHost }
  Timer {
    interval: 200
    running: false
    id: failureCheck
    onTriggered: {
      if (service.appearance.iconSize !== 23 || service.mutationStatus !== "failed"
          || !service.pendingAppearancePatch || service.pendingAppearancePatch.iconSize !== 25)
        throw new Error("rejected queued write lost saved settings or pending work")
      console.log("DRAWER_QML_SCOPED_HOST_OK")
      Qt.quit()
    }
  }
  Component.onCompleted: Qt.callLater(function() {
    if (service.drawerState.right.length !== 2 || service.appearance.iconSize !== 23
        || service.drawerState.alwaysVisible.join(",") !== "audio"
        || service.modeFor("fixture") !== "hover")
      throw new Error("scoped host settings were replaced by defaults")
    if (service.setModeFor("fixture", "toggle") !== "toggle"
        || service.modeFor("fixture") !== "toggle"
        || scopedHost.barConfig.layout.right[1].custom !== "preserved"
        || scopedHost.barConfig.layout.left.join(",") !== "launcher"
        || scopedHost.unrelated.theme !== "preserved")
      throw new Error("scoped write lost unrelated configuration")
    scopedHost.rejectWrites = true
    if (service.toggleFor("fixture").indexOf("error:") !== 0)
      throw new Error("host rejection was reported as a successful mutation")
    service.queueAppearance({iconSize: 25})
    failureCheck.start()
  })
}
