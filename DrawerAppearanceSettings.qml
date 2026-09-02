pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Ui

Flickable {
  id: root
  required property var controller
  readonly property var service: controller.service
  readonly property var appearance: service ? service.appearance : ({})
  contentWidth: width
  contentHeight: form.implicitHeight
  clip: true
  boundsBehavior: Flickable.StopAtBounds
  ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
  readonly property real maximumContentY: Math.max(0, contentHeight - height)

  function save(patch) { if (service) service.queueAppearance(patch) }
  function applyScroll(position) {
    var requested = String(position || "top")
    contentY = requested === "bottom" ? maximumContentY : (requested === "middle" ? maximumContentY / 2 : 0)
    return contentY
  }

  ColumnLayout {
    id: form
    width: root.width
    spacing: Style.space(6)

    Text {
      Layout.fillWidth: true
      text: "Glyphs and spacing"
      color: Color.popups.text
      font.family: Style.font.family
      font.pixelSize: Style.font.body
      font.bold: true
    }
    RowLayout {
      Layout.fillWidth: true
      spacing: Style.space(8)
      ColumnLayout {
        Layout.fillWidth: true
        Text { text: "Collapsed glyph"; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption }
        TextField {
          objectName: "collapsedGlyphEditor"
          Layout.fillWidth: true
          text: String(root.appearance.collapsedGlyph || "")
          foreground: Color.popups.text
          accent: Color.bar.active
          onEditingFinished: root.save({collapsedGlyph: text})
        }
      }
      ColumnLayout {
        Layout.fillWidth: true
        Text { text: "Expanded glyph"; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption }
        TextField {
          objectName: "expandedGlyphEditor"
          Layout.fillWidth: true
          text: String(root.appearance.expandedGlyph || "")
          foreground: Color.popups.text
          accent: Color.bar.active
          onEditingFinished: root.save({expandedGlyph: text})
        }
      }
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Style.space(8)
      Repeater {
        model: [
          {key: "iconSize", label: "Icon size", minimum: 10, maximum: 30},
          {key: "horizontalMargin", label: "Side margin", minimum: 2, maximum: 18},
          {key: "verticalPadding", label: "Vertical padding", minimum: 2, maximum: 12}
        ]
        ColumnLayout {
          id: sizeEditor
          required property var modelData
          Layout.fillWidth: true
          Layout.preferredWidth: 1
          Text { text: sizeEditor.modelData.label; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption }
          TextField {
            objectName: sizeEditor.modelData.key + "Editor"
            Layout.fillWidth: true
            text: String(root.appearance[sizeEditor.modelData.key])
            foreground: Color.popups.text
            accent: Color.bar.active
            validator: IntValidator { bottom: sizeEditor.modelData.minimum; top: sizeEditor.modelData.maximum }
            onEditingFinished: { var patch = {}; patch[sizeEditor.modelData.key] = Number(text); root.save(patch) }
          }
        }
      }
    }

    Text {
      Layout.fillWidth: true
      text: "State colors"
      color: Color.popups.text
      font.family: Style.font.family
      font.pixelSize: Style.font.body
      font.bold: true
    }
    RowLayout {
      Layout.fillWidth: true
      spacing: Style.space(8)
      Dropdown {
        objectName: "collapsedColorDropdown"
        Layout.fillWidth: true
        label: "Collapsed"
        value: String(root.appearance.collapsedColorRole || "foreground")
        options: [{value:"foreground",label:"Foreground"},{value:"accent",label:"Accent"},{value:"muted",label:"Muted"},{value:"urgent",label:"Urgent"}]
        foreground: Color.popups.text; accent: Color.bar.active
        onChanged: function(value) { root.save({collapsedColorRole:value}) }
      }
      Dropdown {
        objectName: "expandedColorDropdown"
        Layout.fillWidth: true
        label: "Expanded"
        value: String(root.appearance.expandedColorRole || "accent")
        options: [{value:"foreground",label:"Foreground"},{value:"accent",label:"Accent"},{value:"muted",label:"Muted"},{value:"urgent",label:"Urgent"}]
        foreground: Color.popups.text; accent: Color.bar.active
        onChanged: function(value) { root.save({expandedColorRole:value}) }
      }
    }

    Text {
      Layout.fillWidth: true
      text: "Behavior"
      color: Color.popups.text
      font.family: Style.font.family
      font.pixelSize: Style.font.body
      font.bold: true
    }
    RowLayout {
      Layout.fillWidth: true
      spacing: Style.space(8)
      Dropdown {
        objectName: "leftClickDropdown"
        Layout.fillWidth: true
        label: "Left click"
        value: String(root.appearance.leftClickAction || "toggle")
        options: [{value:"toggle",label:"Toggle"},{value:"expand",label:"Expand only"},{value:"collapse",label:"Collapse only"}]
        foreground: Color.popups.text; accent: Color.bar.active
        onChanged: function(value) { root.save({leftClickAction:value}) }
      }
      Dropdown {
        objectName: "middleClickDropdown"
        Layout.fillWidth: true
        label: "Middle click"
        value: String(root.appearance.middleClickAction || "settings")
        options: [{value:"settings",label:"Open settings"},{value:"toggle",label:"Toggle"},{value:"none",label:"Do nothing"}]
        foreground: Color.popups.text; accent: Color.bar.active
        onChanged: function(value) { root.save({middleClickAction:value}) }
      }
    }
    RowLayout {
      Layout.fillWidth: true
      spacing: Style.space(8)
      Dropdown {
        objectName: "monitorModeDropdown"
        Layout.fillWidth: true
        label: "This monitor"
        value: root.service ? root.service.modeFor(root.controller.monitorName) : "toggle"
        options: [{value:"toggle",label:"Click toggle"},{value:"hover",label:"Hover reveal"}]
        foreground: Color.popups.text; accent: Color.bar.active
        onChanged: function(value) { if (root.service) root.service.setModeFor(root.controller.monitorName, value) }
      }
      ColumnLayout {
        Layout.preferredWidth: Style.space(100)
        Text { text: "Hover close (ms)"; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption }
        TextField {
          objectName: "hoverCollapseDelayEditor"
          Layout.fillWidth: true
          text: String(root.appearance.hoverCollapseDelay || 350)
          foreground: Color.popups.text; accent: Color.bar.active
          validator: IntValidator { bottom: 100; top: 2000 }
          onEditingFinished: root.save({hoverCollapseDelay:Number(text)})
        }
      }
    }
    RowLayout {
      Layout.fillWidth: true
      spacing: Style.space(8)
      Toggle {
        objectName: "animationToggle"
        Layout.fillWidth: true
        implicitHeight: Style.space(52)
        label: "Smooth transitions"
        description: "Animate widget reveal and collapse."
        checked: root.appearance.animationEnabled !== false
        foreground: Color.popups.text; accent: Color.bar.active
        fontFamily: Style.font.family; titleSize: Style.font.bodySmall; descriptionSize: Style.font.caption
        onClicked: root.save({animationEnabled: !checked})
      }
      ColumnLayout {
        Layout.preferredWidth: Style.space(100)
        Text { text: "Duration (ms)"; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption }
        TextField {
          objectName: "animationDurationEditor"
          Layout.fillWidth: true
          text: String(root.appearance.animationDuration || 250)
          foreground: Color.popups.text; accent: Color.bar.active
          validator: IntValidator { bottom: 80; top: 1000 }
          onEditingFinished: root.save({animationDuration:Number(text)})
        }
      }
    }
    RowLayout {
      Layout.fillWidth: true
      spacing: Style.space(8)
      Dropdown {
        objectName: "animationStyleDropdown"
        Layout.fillWidth: true
        label: "Reveal style"
        value: String(root.appearance.animationStyle || "taskbar")
        options: [
          {value:"taskbar",label:"Taskbar wipe"},
          {value:"cascade",label:"Cascade"},
          {value:"softCascade",label:"Soft cascade"},
          {value:"uniform",label:"Uniform reveal"},
          {value:"instant",label:"Instant"}
        ]
        foreground: Color.popups.text; accent: Color.bar.active
        onChanged: function(value) { root.save({animationStyle:value}) }
      }
      Dropdown {
        objectName: "animationCurveDropdown"
        Layout.fillWidth: true
        label: "Motion curve"
        value: String(root.appearance.animationCurve || "smooth")
        enabled: String(root.appearance.animationStyle || "taskbar") !== "instant"
        options: [
          {value:"smooth",label:"Smooth"},
          {value:"quick",label:"Quick"},
          {value:"gentle",label:"Gentle"},
          {value:"linear",label:"Linear"}
        ]
        foreground: Color.popups.text; accent: Color.bar.active
        onChanged: function(value) { root.save({animationCurve:value}) }
      }
    }
    Toggle {
      objectName: "tooltipToggle"
      Layout.fillWidth: true
      implicitHeight: Style.space(50)
      label: "Show tooltip"
      description: "Describe the current drawer action on hover."
      checked: root.appearance.showTooltip !== false
      foreground: Color.popups.text
      accent: Color.bar.active
      fontFamily: Style.font.family
      titleSize: Style.font.bodySmall
      descriptionSize: Style.font.caption
      onClicked: root.save({showTooltip: !checked})
    }
    Text {
      Layout.fillWidth: true
      text: "Right-click always opens settings so customization remains reachable."
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
    }
  }
}
