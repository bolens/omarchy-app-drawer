pragma ComponentBehavior: Bound
import Quickshell
import QtQuick

ShellRoot {
  id: root
  readonly property string drawerId: "io.github.bolens.app-drawer"
  QtObject {
    id: shellMock
    property var shellConfig: ({bar:{layout:{right:["tray","audio",root.drawerId]},drawerExpanded:true,drawerAppearance:{animationEnabled:false}},plugins:[]})
    function mutateShellConfig(mutator) { var copy=JSON.parse(JSON.stringify(shellConfig)); mutator(copy); shellConfig=copy }
  }
  QtObject { id: registryMock; property var installedPlugins: ({}) }
  QtObject { id: dp1 }
  QtObject { id: dp3 }
  Service { id: service; shell:shellMock; pluginRegistry:registryMock }

  Component.onCompleted: Qt.callLater(function() {
    service.registerWidget("DP-3",dp3); service.registerWidget("DP-1",dp1)
    service.setExpandedFor("DP-1",false)
    if (service.expandedFor("DP-1") || !service.expandedFor("DP-3"))
      throw new Error("monitor state leaked across screens")
    if (shellMock.shellConfig.bar.layout.right.length !== 3)
      throw new Error("monitor collapse unmounted shared row")
    service.setModeFor("DP-3","hover")
    service.setModeFor("DP-1","invalid")
    if (service.modeFor("DP-3") !== "hover" || service.modeFor("DP-1") !== "toggle")
      throw new Error("monitor interaction modes were not isolated or sanitized")
    for (var index=0; index<101; index++) service.toggleFor("DP-1")
    if (!service.expandedFor("DP-1") || !service.expandedFor("DP-3"))
      throw new Error("rapid monitor toggles lost parity or changed peer state")
    service.setExpanded(false)
    if (service.expandedFor("DP-1") || service.expandedFor("DP-3"))
      throw new Error("global compatibility collapse did not target all monitors")
    var status=JSON.parse(service.monitorStatus("DP-3"))
    if (status.screen!=="DP-3" || status.expanded || status.mode!=="hover" || !status.healthy)
      throw new Error("monitor status contract failed")
    console.log("DRAWER_QML_MONITOR_STATE_OK");Qt.quit()
  })
}
