import Quickshell
import Quickshell.Io
import QtQuick

ShellRoot {
  id: root
  readonly property string configPath: Quickshell.shellPath("RuntimeIpcTest.qml")
  readonly property string executable: String(Quickshell.env("QUICKSHELL_BIN") || "quickshell")
  property int step: 0
  property var calls: [
    {method:"status",args:[]}, {method:"setMonitorExpanded",args:["DP-1","false"]},
    {method:"toggleMonitor",args:["DP-1"]}, {method:"setMonitorMode",args:["DP-1","hover"]},
    {method:"monitorStatus",args:["DP-1"]}, {method:"registeredMonitors",args:[]},
    {method:"openMonitorSettings",args:["DP-1"]}, {method:"settingsStatusFor",args:["DP-1"]},
    {method:"scrollSettingsFor",args:["DP-1","bottom"]},
    {method:"openMonitorAppearance",args:["missing"],error:true}, {method:"closeSettings",args:[]},
    {method:"setMonitorMode",args:["DP-1","invalid"],error:true},
    {method:"setMonitorMode",args:["DP-1","hover"]}, {method:"collapse",args:[]}, {method:"pin",args:["tray"]},
    {method:"setAppearance",args:['{"iconSize":23}']}, {method:"expand",args:[]},
    {method:"setAppearance",args:["bad-json"],error:true},
    {method:"setAppearance",args:["null"],error:true}, {method:"status",args:[]}
  ]
  QtObject {
    id: shellMock
    property var shellConfig: ({bar:{layout:{right:["tray","io.github.bolens.app-drawer"]},drawerExpanded:true,drawerAppearance:{animationEnabled:false}},plugins:[]})
    function mutateShellConfig(mutator) { var copy=JSON.parse(JSON.stringify(shellConfig)); mutator(copy); shellConfig=copy }
  }
  QtObject { id: registryMock; property var installedPlugins: ({}) }
  QtObject {
    id: widgetMock
    property bool open: false
    property string page: ""
    function showSettings(requested) { page=requested; open=true }
    function closeSettings() { open=false }
    function settingsStatus() { return {open:open,page:page} }
    function scrollSettings(position) { return JSON.stringify({page:page,y:position==="bottom"?100:0,maximum:100}) }
  }
  Service { id: service; shell: shellMock; pluginRegistry: registryMock }
  function next() {
    if (step >= calls.length) {
      if (!service.expandedFor("DP-1") || service.modeFor("DP-1") !== "hover"
          || service.appearance.iconSize !== 23 || service.lastError.indexOf("appearance") === -1)
        throw new Error("IPC state projection failed")
      console.log("DRAWER_QML_IPC_OK"); Qt.quit(); return
    }
    var call = calls[step]
    ipc.command = [root.executable,"ipc","--path",root.configPath,"call","app-drawer",call.method].concat(call.args)
    ipc.running = true
  }
  Process {
    id: ipc
    stdout: StdioCollector { id: output; waitForEnd: true }
    stderr: StdioCollector { id: errors; waitForEnd: true }
    onExited: function(code) {
      var response=String(output.text||"").trim(), call=root.calls[root.step]
      if (code !== 0 || (call.error === true && response.indexOf("error:") !== 0))
        throw new Error("IPC call failed: "+call.method+" "+response+" "+String(errors.text||""))
      root.step++; Qt.callLater(root.next)
    }
  }
  Component.onCompleted: Qt.callLater(function() { service.registerWidget("DP-1", widgetMock); next() })
}
