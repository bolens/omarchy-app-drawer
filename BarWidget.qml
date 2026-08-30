import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Ui
import "Model.js" as Model

Item {
  id: root
  property var bar: null
  property var settings: ({})
  property string moduleName: Model.PLUGIN_ID
  readonly property var drawerService: bar && bar.shell && typeof bar.shell.serviceFor === "function"
    ? bar.shell.serviceFor(moduleName) : null
  readonly property var appearance: drawerService ? drawerService.appearance : Model.appearanceSettings({})
  property bool settingsOpen: false
  property var registeredService: null
  property string registeredScreenName: ""
  property int registeredGeneration: 0
  property var transitionSlots: []
  property real revealProgress: localExpanded ? 1 : 0
  property int lastAnimationSlotCount: 0
  property real lastAnimationTotalExtent: 0
  property int bindingAttempts: 0
  property bool bindingDeferred: false
  readonly property var presentationScreen: root.QsWindow.window ? root.QsWindow.window.screen : null
  readonly property string presentationScreenName: presentationScreen ? presentationScreen.name : "unknown"
  readonly property bool localExpanded: drawerService ? drawerService.expandedFor(presentationScreenName) : true
  readonly property string localMode: drawerService ? drawerService.modeFor(presentationScreenName) : "toggle"
  readonly property string animationStyle: String(appearance.animationStyle || "taskbar")
  readonly property string animationCurve: String(appearance.animationCurve || "smooth")
  readonly property bool animationActive: appearance.animationEnabled !== false && animationStyle !== "instant"
  readonly property int animationEasing: {
    if (animationCurve === "smooth") return Easing.InOutCubic
    if (animationCurve === "quick") return Easing.OutCubic
    if (animationCurve === "gentle") return Easing.InOutSine
    if (animationCurve === "linear") return Easing.Linear
    return Easing.InOutCubic
  }
  readonly property string transitionTopologyKey: drawerService ? JSON.stringify({
    saved: drawerService.drawerState.saved.map(function(entry) { return Model.entryId(entry) }),
    pinned: drawerService.drawerState.alwaysVisible,
    vertical: !!(bar && bar.vertical)
  }) : ""
  readonly property Item hoverRegion: {
    var slot = ownSlot()
    return slot && slot.parent ? slot.parent : null
  }

  function showSettings(page) {
    settingsContent.page = page === "appearance" ? "appearance" : "widgets"
    settingsOpen = true
  }
  function openSettings() {
    if (drawerService && typeof drawerService.openSettingsFor === "function")
      drawerService.openSettingsFor(root)
    else showSettings("widgets")
  }
  function closeSettings() { settingsOpen = false }
  // KeyboardPanel dismisses through owner.close(). Without this contract it
  // assigns its own bound `open` property and future right-clicks cannot reopen it.
  function close() { closeSettings() }
  function settingsStatus() {
    var scroll = settingsContent.scrollStatus()
    return {
      open: settingsOpen && settingsPanel.visible,
      requestedOpen: settingsOpen,
      panelWidth: settingsPanel.contentWidth,
      panelHeight: settingsPanel.contentHeight,
      viewportWidth: settingsContent.width,
      viewportHeight: settingsContent.height,
      contentHeight: settingsContent.listContentHeight,
      bodyWidth: settingsContent.bodyWidth,
      bodyHeight: settingsContent.bodyHeight,
      bodyImplicitHeight: settingsContent.bodyImplicitHeight,
      renderedRows: settingsContent.renderedRows,
      visible: settingsContent.visible,
      opacity: settingsContent.opacity,
      entryCount: drawerService ? drawerService.drawerState.saved.length : 0,
      page: settingsContent.page,
      scrollY: scroll.y,
      scrollMaximum: scroll.maximum
    }
  }
  function scrollSettings(position) {
    if (!settingsOpen) return "error: settings are closed"
    settingsContent.applyScroll(position)
    return JSON.stringify(settingsContent.scrollStatus())
  }
  function animationStatus() {
    var running = revealBehavior.enabled && revealProgress > 0 && revealProgress < 1
    var phase = running ? (localExpanded ? "expanding" : "collapsing") : "idle"
    return {screen:presentationScreenName, phase:phase,
      slots:lastAnimationSlotCount, totalExtent:lastAnimationTotalExtent,
      progress:revealProgress, running:running,
      expanded:localExpanded, mode:localMode, style:animationStyle, curve:animationCurve}
  }
  function syncServiceRegistration() {
    var nextScreen = presentationScreenName === "unknown" ? "" : presentationScreenName
    if (registeredService === drawerService && registeredScreenName === nextScreen) return
    if (registeredService && typeof registeredService.unregisterWidget === "function")
      registeredService.unregisterWidget(registeredScreenName, root, registeredGeneration)
    registeredService = null
    registeredScreenName = ""
    registeredGeneration = 0
    if (drawerService && nextScreen && typeof drawerService.registerWidget === "function") {
      registeredService = drawerService
      registeredScreenName = nextScreen
      registeredGeneration = Number(drawerService.registerWidget(nextScreen, root) || 0)
    }
  }
  function themeColor(role) {
    if (role === "accent") return Color.bar.active
    if (role === "urgent") return bar ? bar.urgent : Color.urgent
    if (role === "muted") return Color.muted
    return bar ? bar.barForeground : Color.foreground
  }
  function runAction(action) {
    if (!drawerService || action === "none") return
    if (action === "settings") openSettings()
    else if (action === "expand") drawerService.setExpandedFor(presentationScreenName, true)
    else if (action === "collapse") drawerService.setExpandedFor(presentationScreenName, false)
    else drawerService.toggleFor(presentationScreenName)
  }
  function wholeBarHovered() {
    return bar && typeof bar.barHovered === "boolean" ? bar.barHovered : drawerHover.hovered
  }
  function scheduleHoverCollapse() {
    if (localMode === "hover" && localExpanded && !wholeBarHovered() && !settingsOpen)
      hoverCollapseTimer.restart()
    else hoverCollapseTimer.stop()
  }

  function ownSlot() {
    var candidate = root.parent
    while (candidate) {
      if (candidate.moduleName === root.moduleName && candidate.region === "right") return candidate
      candidate = candidate.parent
    }
    return null
  }
  function implicitWidthBinding(slot) { return function() { return slot.implicitWidth } }
  function implicitHeightBinding(slot) { return function() { return slot.implicitHeight } }
  function revealedExtent(extent, trailingExtent, totalExtent) {
    return Model.revealExtent(animationStyle, root.revealProgress, extent, trailingExtent, totalExtent)
  }
  function animatedWidthBinding(slot, extent, trailingExtent, totalExtent) {
    return function() {
      return root.revealProgress >= 1 ? slot.implicitWidth
        : root.revealedExtent(extent, trailingExtent, totalExtent)
    }
  }
  function animatedHeightBinding(slot, extent, trailingExtent, totalExtent) {
    return function() {
      return root.revealProgress >= 1 ? slot.implicitHeight
        : root.revealedExtent(extent, trailingExtent, totalExtent)
    }
  }
  function animatedClipBinding() { return function() { return root.revealProgress < 1 } }
  function animatedOpacityBinding(extent, trailingExtent, totalExtent) {
    return function() {
      return Model.revealOpacity(root.animationStyle, root.revealProgress, extent, trailingExtent, totalExtent)
    }
  }
  function restoreTransitionSlots() {
    for (var slotIndex = 0; slotIndex < transitionSlots.length; slotIndex++) {
      var slot = transitionSlots[slotIndex]
      if (!slot) continue
      slot.clip = false
      slot.opacity = 1
      if (bar && bar.vertical)
        slot.height = Qt.binding(root.implicitHeightBinding(slot))
      else
        slot.width = Qt.binding(root.implicitWidthBinding(slot))
    }
    transitionSlots = []
  }
  function localTransitionSlots() {
    var owner = ownSlot()
    if (!owner || !owner.parent || !drawerService) return []
    var saved = drawerService.drawerState.saved.map(function(entry) { return Model.entryId(entry) })
    var pinned = drawerService.drawerState.alwaysVisible
    return owner.parent.children.filter(function(slot) {
      return slot && slot !== owner && saved.indexOf(String(slot.moduleName || "")) !== -1
        && pinned.indexOf(String(slot.moduleName || "")) === -1
    })
  }
  function expectedTransitionSlotCount() {
    if (!drawerService) return 0
    var pinned = drawerService.drawerState.alwaysVisible
    return drawerService.drawerState.saved.filter(function(entry) {
      return pinned.indexOf(Model.entryId(entry)) === -1
    }).length
  }
  function applySlotBindings() {
    slotBindingTimer.stop()
    bindingDeferred = false
    restoreTransitionSlots()
    lastAnimationSlotCount = 0
    lastAnimationTotalExtent = 0
    if (!drawerService) return
    var slots = localTransitionSlots()
    lastAnimationSlotCount = slots.length
    if (slots.length === 0) return
    transitionSlots = slots
    var extents = []
    for (var index = 0; index < slots.length; index++) {
      var slot = slots[index]
      var extent = bar && bar.vertical ? slot.implicitHeight : slot.implicitWidth
      extents.push(extent)
      lastAnimationTotalExtent += extent
    }
    var totalExtent = lastAnimationTotalExtent
    var trailingExtent = 0
    for (var reverseIndex = slots.length - 1; reverseIndex >= 0; reverseIndex--) {
      slot = slots[reverseIndex]
      extent = extents[reverseIndex]
      slot.clip = Qt.binding(root.animatedClipBinding())
      slot.opacity = Qt.binding(root.animatedOpacityBinding(extent, trailingExtent, totalExtent))
      if (bar && bar.vertical)
        slot.height = Qt.binding(root.animatedHeightBinding(slot, extent, trailingExtent, totalExtent))
      else
        slot.width = Qt.binding(root.animatedWidthBinding(slot, extent, trailingExtent, totalExtent))
      trailingExtent += extent
    }
  }
  function transitionInProgress() {
    return animationActive && revealProgress > 0 && revealProgress < 1
  }
  function scheduleSlotBinding() {
    if (transitionInProgress()) {
      bindingDeferred = true
      slotBindingTimer.stop()
      return
    }
    bindingDeferred = false
    bindingAttempts = 0
    slotBindingTimer.restart()
  }

  onLocalExpandedChanged: {
    applySlotBindings()
    revealProgress = localExpanded ? 1 : 0
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.localExpanded ? root.appearance.expandedGlyph : root.appearance.collapsedGlyph
    fontSize: root.appearance.iconSize
    horizontalMargin: root.appearance.horizontalMargin
    verticalPadding: root.appearance.verticalPadding
    foreground: root.themeColor(root.appearance.collapsedColorRole)
    activeColor: root.themeColor(root.appearance.expandedColorRole)
    tooltipText: root.appearance.showTooltip && root.drawerService
      ? (root.localExpanded ? "Collapse right-side widgets" : "Expand right-side widgets")
      : (root.appearance.showTooltip ? "App Drawer service unavailable" : "")
    active: root.drawerService && root.localExpanded
    dimmed: !root.drawerService
    onPressed: function(mouseButton) {
      if (!root.drawerService) {
        console.warn("App Drawer: ignored click because service is unavailable")
        return
      }
      if (mouseButton === Qt.LeftButton) root.runAction(root.appearance.leftClickAction)
      else if (mouseButton === Qt.MiddleButton) root.runAction(root.appearance.middleClickAction)
      else if (mouseButton === Qt.RightButton) root.openSettings()
    }
  }

  Behavior on revealProgress {
    id: revealBehavior
    enabled: root.animationActive
    NumberAnimation {
      id: revealAnimator
      duration: root.appearance.animationDuration
      easing.type: root.animationEasing
      onRunningChanged: if (!running && root.bindingDeferred) root.scheduleSlotBinding()
    }
  }
  HoverHandler {
    id: drawerHover
    target: root.hoverRegion
    enabled: root.localMode === "hover" && !root.settingsOpen
    onHoveredChanged: {
      if (!root.drawerService) return
      if (hovered) {
        hoverCollapseTimer.stop()
        root.drawerService.setExpandedFor(root.presentationScreenName, true)
      } else root.scheduleHoverCollapse()
    }
  }
  Connections {
    target: root.bar
    ignoreUnknownSignals: true
    function onBarHoveredChanged() {
      if (root.wholeBarHovered()) hoverCollapseTimer.stop()
      else root.scheduleHoverCollapse()
    }
  }
  Timer {
    id: hoverCollapseTimer
    interval: root.appearance.hoverCollapseDelay
    repeat: false
    onTriggered: {
      if (root.drawerService && root.localMode === "hover"
          && !root.wholeBarHovered() && !root.settingsOpen)
        root.drawerService.setExpandedFor(root.presentationScreenName, false)
    }
  }
  Timer {
    id: slotBindingTimer
    interval: 50
    repeat: false
    onTriggered: {
      root.applySlotBindings()
      root.bindingAttempts++
      if (root.transitionSlots.length < root.expectedTransitionSlotCount()
          && root.bindingAttempts < 20) restart()
    }
  }

  KeyboardPanel {
    id: settingsPanel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.settingsOpen
    focusTarget: settingsContent.initialFocusTarget
    contentWidth: fittedContentWidth(Style.space(400))
    contentHeight: fittedContentHeight(settingsContent.implicitHeight, Style.space(580))
    onOpenChanged: if (!open) root.settingsOpen = false

    DrawerSettings {
      id: settingsContent
      anchors.fill: parent
      controller: root
    }
  }

  Component.onCompleted: {
    syncServiceRegistration()
    revealProgress = localExpanded ? 1 : 0
    scheduleSlotBinding()
  }
  Component.onDestruction: {
    hoverCollapseTimer.stop()
    slotBindingTimer.stop()
    restoreTransitionSlots()
    if (registeredService && typeof registeredService.unregisterWidget === "function")
      registeredService.unregisterWidget(registeredScreenName, root, registeredGeneration)
    registeredService = null
    registeredScreenName = ""
    registeredGeneration = 0
  }
  onDrawerServiceChanged: {
    syncServiceRegistration()
    if (drawerService) scheduleSlotBinding()
  }
  onTransitionTopologyKeyChanged: scheduleSlotBinding()
  onLocalModeChanged: {
    if (localMode === "hover") scheduleHoverCollapse()
    else hoverCollapseTimer.stop()
  }
  onSettingsOpenChanged: {
    if (settingsOpen) hoverCollapseTimer.stop()
    else scheduleHoverCollapse()
  }
  onPresentationScreenNameChanged: {
    restoreTransitionSlots()
    syncServiceRegistration()
    scheduleSlotBinding()
  }
}
