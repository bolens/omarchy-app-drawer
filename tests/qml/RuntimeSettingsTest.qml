pragma ComponentBehavior: Bound
import Quickshell
import QtQuick

ShellRoot {
  id: root
  QtObject {
    id: serviceMock
    property var appearance: ({expandedGlyph:"E",collapsedGlyph:"C",iconSize:14,horizontalMargin:8,verticalPadding:6,expandedColorRole:"accent",collapsedColorRole:"foreground",showTooltip:true,leftClickAction:"toggle",middleClickAction:"settings",animationEnabled:true,animationDuration:250,animationStyle:"taskbar",animationCurve:"smooth",hoverCollapseDelay:350})
    property var drawerState: ({saved:["tray","audio"],alwaysVisible:[],expanded:false})
    property var events: []
    property string lastError: ""
    property bool expanded: false
    function displayName(entry) { return String(entry).toUpperCase() }
    function queueAppearance(patch) { serviceMock.events = serviceMock.events.concat([patch]); serviceMock.appearance = Object.assign({}, serviceMock.appearance, patch) }
    function setAlwaysVisible(id, enabled) { serviceMock.events = serviceMock.events.concat([{id:id,enabled:enabled}]) }
    function resetAlwaysVisible() {}
    function resetAppearance() {}
    function toggle() { expanded = !expanded }
    function modeFor(_screen) { return "toggle" }
    function setModeFor(screen, mode) { serviceMock.events = serviceMock.events.concat([{screen:screen,mode:mode}]) }
  }
  QtObject { id: controllerMock; property var service: serviceMock; property string monitorName:"DP-1"; function closeSettings() {} }
  DrawerAppearanceSettings { id: appearance; width: 368; height: 480; controller: controllerMock }

  function descendant(item, name) {
    if (!item) return null
    if (item.objectName === name) return item
    var children = item.children || []
    for (var index = 0; index < children.length; index++) { var match = descendant(children[index], name); if (match) return match }
    return null
  }
  Component.onCompleted: Qt.callLater(function() {
    var collapsed = descendant(appearance, "collapsedGlyphEditor")
    var size = descendant(appearance, "iconSizeEditor")
    var expandedColor = descendant(appearance, "expandedColorDropdown")
    var left = descendant(appearance, "leftClickDropdown")
    var tooltip = descendant(appearance, "tooltipToggle")
    var hover = descendant(appearance, "monitorModeDropdown")
    var hoverDelay = descendant(appearance, "hoverCollapseDelayEditor")
    var animationStyle = descendant(appearance, "animationStyleDropdown")
    var animationCurve = descendant(appearance, "animationCurveDropdown")
    if (!collapsed || !size || !expandedColor || !left || !tooltip || !hover || !hoverDelay || !animationStyle || !animationCurve) throw new Error("appearance controls missing")
    collapsed.text = "Z"; collapsed.editingFinished()
    size.text = "21"; size.editingFinished()
    expandedColor.changed("urgent"); left.changed("collapse"); tooltip.clicked()
    hover.changed("hover"); hoverDelay.text = "725"; hoverDelay.editingFinished()
    animationStyle.changed("cascade"); animationCurve.changed("gentle")
    if (serviceMock.events.length !== 9 || serviceMock.events[0].collapsedGlyph !== "Z"
        || serviceMock.events[1].iconSize !== 21 || serviceMock.events[2].expandedColorRole !== "urgent"
        || serviceMock.events[3].leftClickAction !== "collapse" || serviceMock.events[4].showTooltip !== false
        || serviceMock.events[5].mode !== "hover" || serviceMock.events[5].screen !== "DP-1"
        || serviceMock.events[6].hoverCollapseDelay !== 725
        || serviceMock.events[7].animationStyle !== "cascade" || serviceMock.events[8].animationCurve !== "gentle")
      throw new Error("appearance controls emitted incorrect patches")
    console.log("DRAWER_QML_SETTINGS_OK")
    Qt.quit()
  })
}
