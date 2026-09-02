pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Ui
import "Model.js" as Model

Item {
  id: root
  required property var controller
  readonly property var service: controller.drawerService
  readonly property string monitorName: String(controller.presentationScreenName || "unknown")
  readonly property bool monitorExpanded: service ? service.expandedFor(monitorName) : false
  readonly property real bodyWidth: layout.width
  readonly property real bodyHeight: layout.height
  readonly property real bodyImplicitHeight: implicitHeight
  readonly property int renderedRows: widgetRepeater.count
  readonly property real listContentHeight: widgetChoices.implicitHeight
  readonly property Item initialFocusTarget: collapseButton
  property string page: "widgets"
  implicitHeight: Style.space(540)

  function applyScroll(position) {
    if (page === "appearance") return appearanceSettings.applyScroll(position)
    var maximum = Math.max(0, widgetList.contentHeight - widgetList.height)
    var requested = String(position || "top")
    widgetList.contentY = requested === "bottom" ? maximum : (requested === "middle" ? maximum / 2 : 0)
    return widgetList.contentY
  }
  function scrollStatus() {
    if (page === "appearance") return {page:page,y:appearanceSettings.contentY,maximum:appearanceSettings.maximumContentY}
    return {page:page,y:widgetList.contentY,maximum:Math.max(0,widgetList.contentHeight-widgetList.height)}
  }

  ColumnLayout {
    id: layout
    anchors.fill: parent
    spacing: Style.space(10)

    Text {
      Layout.fillWidth: true
      text: "App Drawer"
      textFormat: Text.PlainText
      color: Color.popups.text
      font.family: Style.font.family
      font.pixelSize: Style.font.title
      font.bold: true
    }
    Text {
      Layout.fillWidth: true
      text: root.page === "appearance"
        ? "Per-monitor behavior; glyphs and styling are shared."
        : "Keep selected widgets visible while this monitor is collapsed. Pins are shared."
      textFormat: Text.PlainText
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }
    RowLayout {
      Layout.fillWidth: true
      spacing: Style.space(6)
      Button { objectName: "widgetsTab"; text: "Widgets"; active: root.page === "widgets"; focusable: true; onClicked: root.page = "widgets" }
      Button { objectName: "appearanceTab"; text: "Appearance"; active: root.page === "appearance"; focusable: true; onClicked: root.page = "appearance" }
      Item { Layout.fillWidth: true }
    }

    Rectangle {
      visible: root.page === "widgets"
      Layout.fillWidth: true
      Layout.fillHeight: true
      Layout.minimumHeight: Style.space(180)
      radius: Style.space(8)
      color: Qt.lighter(Color.popups.background, 1.08)
      clip: true

      Flickable {
        id: widgetList
        anchors.fill: parent
        anchors.margins: Style.space(8)
        clip: true
        contentWidth: width
        contentHeight: widgetChoices.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout {
          id: widgetChoices
          width: widgetList.width
          spacing: Style.space(4)
          Repeater {
            id: widgetRepeater
            model: root.service ? root.service.drawerState.saved : []
            Toggle {
              required property var modelData
              Layout.fillWidth: true
              implicitHeight: Style.space(46)
              label: root.service ? root.service.displayName(modelData) : Model.entryId(modelData)
              description: Model.entryId(modelData)
              checked: root.service && root.service.drawerState.alwaysVisible.indexOf(Model.entryId(modelData)) !== -1
              foreground: Color.popups.text
              accent: Color.bar.active
              fontFamily: Style.font.family
              titleSize: Style.font.bodySmall
              descriptionSize: Style.font.caption
              onClicked: if (root.service) root.service.queueAlwaysVisible(Model.entryId(modelData), !checked)
            }
          }
        }
      }
    }

    DrawerAppearanceSettings {
      id: appearanceSettings
      visible: root.page === "appearance"
      Layout.fillWidth: true
      Layout.fillHeight: true
      controller: root
    }

    Text {
      Layout.fillWidth: true
      visible: !!root.service && root.service.lastError !== ""
      text: root.service ? root.service.lastError : ""
      textFormat: Text.PlainText
      color: Color.urgent
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
    }
    Text {
      Layout.fillWidth: true
      visible: !!root.service && root.service.mutationStatus !== "" && root.service.lastError === ""
      text: root.service ? (root.service.mutationStatus === "saving" ? "Saving changes…" : "Changes applied") : ""
      textFormat: Text.PlainText
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Style.space(6)
      Button {
        id: collapseButton
        text: root.monitorExpanded ? "Collapse " + root.monitorName : "Expand " + root.monitorName
        tooltipText: root.monitorExpanded ? "Collapse this monitor's unpinned widgets" : "Reveal this monitor's saved widgets"
        onClicked: if (root.service) root.service.toggleFor(root.monitorName)
      }
      Item { Layout.fillWidth: true }
      Button {
        text: root.page === "appearance" ? "Reset look" : "Reset pins"
        tooltipText: root.page === "appearance" ? "Restore default glyph appearance and mouse behavior" : "Move every widget back inside the drawer"
        enabled: !!root.service && (root.page === "appearance" || root.service.drawerState.alwaysVisible.length > 0)
        onClicked: if (root.service) {
          if (root.page === "appearance") root.service.resetAppearance()
          else root.service.resetAlwaysVisible()
        }
      }
      Button { text: "Close"; tooltipText: "Close drawer settings"; onClicked: root.controller.closeSettings() }
    }
  }
}
