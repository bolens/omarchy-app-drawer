import Quickshell
import QtQuick

ShellRoot {
  id: root
  QtObject {
    id: serviceMock
    property bool expanded: false
    property string lastError: ""
    property string mutationStatus: ""
    property var appearance: ({expandedGlyph:"E",collapsedGlyph:"C",iconSize:14,horizontalMargin:8,verticalPadding:6,expandedColorRole:"accent",collapsedColorRole:"foreground",showTooltip:true,leftClickAction:"toggle",middleClickAction:"settings"})
    property var drawerState: ({saved:["tray","audio"],alwaysVisible:[]})
    function displayName(entry) { return String(entry) }
    function setAlwaysVisible(_id,_enabled) {}
    function queueAlwaysVisible(_id,_enabled) {}
    function resetAlwaysVisible() {}
    function resetAppearance() {}
    function updateAppearance(_patch) {}
    function queueAppearance(_patch) {}
    function toggle() { expanded=!expanded }
    function expandedFor(_screen) { return expanded }
    function toggleFor(_screen) { expanded=!expanded }
    function modeFor(_screen) { return "toggle" }
    function setModeFor(_screen,_mode) {}
  }
  QtObject { id: controllerMock; property var drawerService: serviceMock; property string presentationScreenName:"DP-1"; property bool closed:false; function closeSettings(){closed=true} }
  DrawerSettings { id: settings; width:400; height:540; controller:controllerMock }
  function descendant(item,name) {
    if (!item) return null
    if (item.objectName===name) return item
    var children=item.children||[]
    for (var i=0;i<children.length;i++){var found=descendant(children[i],name);if(found)return found}
    return null
  }
  Component.onCompleted: Qt.callLater(function(){
    var widgets=descendant(settings,"widgetsTab"), appearance=descendant(settings,"appearanceTab")
    if(!widgets||!appearance||settings.page!=="widgets"||!widgets.active||appearance.active)
      throw new Error("default settings navigation state failed")
    appearance.clicked()
    if(settings.page!=="appearance"||!appearance.active||widgets.active)
      throw new Error("appearance navigation failed")
    settings.applyScroll("bottom")
    var scroll=settings.scrollStatus()
    if(scroll.maximum<=0||scroll.y!==scroll.maximum) throw new Error("appearance bottom scroll was not deterministic")
    widgets.clicked()
    if(settings.page!=="widgets"||settings.renderedRows!==2||settings.initialFocusTarget===null)
      throw new Error("widget navigation restoration failed")
    console.log("DRAWER_QML_SETTINGS_NAVIGATION_OK");Qt.quit()
  })
}
