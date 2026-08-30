import Quickshell
import QtQuick

ShellRoot {
  id: root
  QtObject {
    id: shellMock
    property int mutationCount: 0
    property bool failNext: false
    property var shellConfig: ({bar:{layout:{right:["tray","audio","io.github.bolens.app-drawer"]},drawerExpandedEntries:["tray","audio"],drawerAppearance:{iconSize:14,horizontalMargin:8}},plugins:[]})
    function mutateShellConfig(mutator) {
      mutationCount++
      if (failNext) { failNext = false; throw new Error("fixture persistence failure") }
      var copy=JSON.parse(JSON.stringify(shellConfig)); mutator(copy); shellConfig=copy
    }
  }
  Service { id: service; shell:shellMock }
  Timer {
    interval: 250
    running: true
    onTriggered: {
      if (shellMock.mutationCount !== 2 || service.appearance.iconSize !== 22
          || service.appearance.horizontalMargin !== 11
          || service.drawerState.alwaysVisible.join(",") !== "audio")
        throw new Error("rapid settings were not coalesced into one transaction")
      if (service.mutationStatus !== "saved") throw new Error("successful batch did not publish feedback")
      var serial = service.mutationSerial
      if (service.updateAppearance({iconSize:22}) !== "unchanged" || service.mutationSerial !== serial
          || shellMock.mutationCount !== 2)
        throw new Error("no-op appearance update wrote configuration")
      shellMock.failNext = true
      service.queueAppearance({iconSize:25})
      failureCheck.start()
    }
  }
  Timer {
    id: failureCheck
    interval: 200
    onTriggered: {
      if (service.appearance.iconSize !== 22 || service.mutationStatus !== "failed"
          || service.lastError.indexOf("fixture persistence failure") === -1
          || !service.pendingAppearancePatch || service.pendingAppearancePatch.iconSize !== 25)
        throw new Error("failed batch did not retain prior state and feedback")
      shellMock.failNext = true
      if (service.toggleFor("DP-1").indexOf("error:") !== 0
          || Object.prototype.hasOwnProperty.call(service.monitorIntents,"DP-1"))
        throw new Error("failed monitor mutation retained speculative intent")
      console.log("DRAWER_QML_MUTATION_OK")
      Qt.quit()
    }
  }
  Component.onCompleted: Qt.callLater(function() {
    if (shellMock.mutationCount !== 1) throw new Error("startup migration count changed")
    service.queueAppearance({iconSize:22})
    service.queueAppearance({horizontalMargin:11})
    service.queueAlwaysVisible("audio",true)
  })
}
