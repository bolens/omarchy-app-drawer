const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const root = path.join(__dirname, "..")
const read = name => fs.readFileSync(path.join(root, name), "utf8")
const manifest = JSON.parse(read("manifest.json"))
const service = read("Service.qml")
const widget = read("BarWidget.qml")
const model = read("Model.js")
const legacyBar = read("Bar.qml")

for (const [name, source] of [["BarWidget.qml",widget],["Service.qml",service]]) {
  assert.doesNotMatch(source,/\bProcess\s*\{|execDetached|\bquickshell\b|\bqs\s+/, `${name} must not launch another Quickshell or subprocess`)
}

assert.deepEqual(manifest.kinds, ["bar-widget", "service"])
assert.equal(manifest.entryPoints.bar, undefined,
  "declaring a bar entry makes Omarchy ignore widget-layout enablement")
assert.equal(manifest.entryPoints.barWidget, "BarWidget.qml")
assert.equal(manifest.entryPoints.service, "Service.qml")
assert.equal(manifest.barWidget.allowMultiple, false)
assert.equal(manifest.keepLoaded, true)
assert.match(service, /function canMutate\(\)/)
assert.match(service, /if \(!canMutate\(\)\) return fail/)
assert.match(service, /function persistConfig\(mutator\)[\s\S]*try[\s\S]*shell\.mutateShellConfig\(mutator\)[\s\S]*catch/,
  "all direct persistence paths must convert exceptions into deterministic IPC errors")
assert.match(service, /monitorIntents = previousIntents[\s\S]*return "error: " \+ lastError/,
  "failed monitor persistence must roll back its speculative intent")
assert.match(service, /IpcHandler\s*\{[\s\S]*target:\s*"app-drawer"/)
for (const method of ["status", "expand", "collapse", "setExpanded", "toggle", "openSettings", "openAppearance", "closeSettings", "settingsStatus", "openMonitorSettings", "openMonitorAppearance", "settingsStatusFor", "scrollSettingsFor", "pin", "unpin", "resetPins", "setAppearance", "resetAppearance", "setMonitorExpanded", "toggleMonitor", "setMonitorMode", "monitorStatus", "registeredMonitors"])
  assert.match(service, new RegExp(`function ${method}\\(`), `IPC must expose ${method}`)
assert.match(service, /healthy:\s*lastError === ""/)
assert.match(service, /requested !== "toggle" && requested !== "hover"/,
  "monitor mode IPC must reject unknown values instead of changing state")
assert.match(service, /!Model\.isObject\(patch\)/,
  "appearance IPC must reject arrays, null, and primitive JSON")
assert.match(service, /settingsVersion:\s*settingsVersion/)
assert.match(service, /ipcVersion:\s*ipcVersion/)
assert.match(service, /settingsCommitTimer; interval:\s*75/,
  "settings UI mutations must use one bounded coalescing window")
assert.match(service, /registrationGeneration/,
  "presentation diagnostics must expose service-issued registration generations")
assert.match(service, /base = Object\.prototype\.hasOwnProperty\.call\(monitorIntents, key\)[\s\S]*monitorIntents = intents[\s\S]*Model\.applyMonitorExpanded\(config, key, result\)/,
  "monitor toggle intent must be claimed synchronously before persistence")
assert.match(service, /function reconcileMonitorIntents\(\)[\s\S]*delete next\[key\]/,
  "persisted monitor intents must be pruned before they become stale toggle bases")
assert.match(service, /function setExpandedFor\(screenName, nextExpanded\)[\s\S]*if \(Model\.monitorExpanded[\s\S]*return requested \? "expanded" : "collapsed"[\s\S]*intents\[key\] = requested/,
  "idempotent monitor sets must return before claiming an intent that cannot be reconciled")
assert.match(service, /Model\.resetPinned\(config\)/,
  "reset must use one configuration mutation")
assert.match(service, /function resetAlwaysVisible\(\)[\s\S]*pendingPinChanges = null/,
  "reset pins must cancel older queued pin writes")
assert.match(service, /function resetAppearance\(\)[\s\S]*pendingAppearancePatch = null/,
  "reset appearance must cancel older queued appearance writes")
assert.match(service, /function prepareMountedLayout\(config\)[\s\S]*Model\.applyExpanded\(config, true\)/,
  "per-monitor projection must keep the shared stock-bar row mounted")
assert.doesNotMatch(service, /for \([^)]*pinned[\s\S]{0,200}setAlwaysVisible/,
  "reset must not fan out into racing per-widget writes")
assert.match(service, /localeCompare/,
  "monitor-backed widget instances must have deterministic ordering")
assert.match(service, /function openSettingsFor\(preferred, page\)[\s\S]*closeSettings[\s\S]*selected\.showSettings\(page\)/,
  "opening settings must close competing monitor instances before selecting one")
assert.match(service, /instance !== selected[\s\S]*instance\.closeSettings\(\)/,
  "repeated right-click must not close and reopen the already selected panel")
assert.match(service, /function settingsStatus\(\)[\s\S]*requestedOpen[\s\S]*fallback/,
  "global settings status must prefer the monitor that owns an open request")
assert.match(widget, /if \(!root\.drawerService\)/)
assert.doesNotMatch(widget, /IpcHandler/, "per-monitor widgets must not register duplicate IPC endpoints")
assert.match(widget, /function syncServiceRegistration\(\)/)
assert.match(widget, /registeredService\.unregisterWidget\(registeredScreenName, root, registeredGeneration\)/,
  "screen migration must explicitly retire the previous registration generation")
assert.match(widget, /Component\.onDestruction:[\s\S]*unregisterWidget/,
  "destroyed monitor widgets must not remain in the service registry")
assert.match(widget, /Component\.onDestruction:[\s\S]*restoreTransitionSlots\(\)/,
  "destroyed presentations must restore host slot bindings before teardown")
const drawerSettings = read("DrawerSettings.qml")
assert.match(drawerSettings, /Repeater[\s\S]*setAlwaysVisible/)
assert.match(drawerSettings, /implicitHeight:\s*Style\.space\(540\)/,
  "settings must declare deterministic card height")
assert.match(drawerSettings, /Flickable[\s\S]*Repeater[\s\S]*RowLayout/,
  "only the widget list should scroll; primary actions must stay reachable")
assert.match(drawerSettings, /implicitHeight:\s*Style\.space\(46\)/,
  "compact widget rows must retain an accessible pointer target")
assert.match(drawerSettings, /ScrollBar\.vertical:/,
  "the bounded list must expose a visible scroll affordance")
assert.match(widget, /focusTarget:\s*settingsContent\.initialFocusTarget/,
  "keyboard-opened settings must focus a real interactive control")
assert.match(widget, /function close\(\)\s*\{\s*closeSettings\(\)\s*\}/,
  "KeyboardPanel must dismiss through its owner without breaking the bound open property")
assert.doesNotMatch(widget, /if \(settingsOpen\) settingsOpen = false/,
  "idempotent right-click must not create a stale asynchronous close edge")
assert.match(widget, /open:\s*settingsOpen && settingsPanel\.visible/,
  "settings status must distinguish requested state from rendered visibility")
assert.doesNotMatch(widget, /bar\.accent/,
  "the supported stock bar has no accent property")
const qmlRuntimeRunner = read("tests/run_qml_runtime.sh")
assert.match(qmlRuntimeRunner, /leaked_runtime_processes\(\)/,
  "the isolated runtime runner must detect only its own leaked Quickshell harnesses")
assert.match(qmlRuntimeRunner, /Leaked Quickshell runtime harnesses:/,
  "the isolated runtime runner must fail with explicit leak evidence")
const appearanceSettings = read("DrawerAppearanceSettings.qml")
for (const key of ["expandedGlyph", "collapsedGlyph", "iconSize", "horizontalMargin", "verticalPadding", "expandedColorRole", "collapsedColorRole", "showTooltip", "leftClickAction", "middleClickAction", "animationEnabled", "animationDuration", "animationStyleDropdown", "animationCurveDropdown", "monitorModeDropdown", "hoverCollapseDelay"])
  assert.match(appearanceSettings, new RegExp(key), `appearance surface must expose ${key}`)
assert.match(appearanceSettings, /objectName:\s*"animationToggle"[\s\S]*implicitHeight:\s*Style\.space\(52\)/,
  "multi-line animation help must remain inside a bounded accessible control")
assert.match(appearanceSettings, /objectName:\s*"tooltipToggle"[\s\S]*implicitHeight:\s*Style\.space\(50\)/,
  "tooltip help must remain inside its visual bounds")
assert.match(widget, /function applySlotBindings\(\)/)
assert.match(widget, /slotBindingTimer[\s\S]*bindingAttempts < 20/,
  "slot attachment must retry within a deterministic bound when the stock row mounts asynchronously")
assert.match(widget, /transitionSlots\.length < root\.expectedTransitionSlotCount\(\)/,
  "partial asynchronous row construction must not stop slot attachment retries early")
assert.match(widget, /slot\.width = Qt\.binding\(root\.animatedWidthBinding\(slot, extent, trailingExtent, totalExtent\)\)/,
  "animated horizontal slot widths must restore their stock binding")
assert.match(widget, /property real revealProgress:/)
assert.match(widget, /var phase = running \? \(localExpanded \? "expanding" : "collapsing"\) : "idle"/,
  "animation IPC phase must derive from current progress and target, not cached setup state")
assert.match(widget, /Behavior on revealProgress[\s\S]*enabled:\s*root\.animationActive[\s\S]*easing\.type:\s*root\.animationEasing/,
  "all selectable styles must share one configurable progress animation")
assert.match(widget, /animationStyle !== "instant"/)
for (const style of ["taskbar", "cascade", "softCascade", "uniform"])
  assert.match(widget + model, new RegExp(`(?:animationStyle|mode|style) === "${style}"|"${style}"`), `missing ${style} animation behavior`)
for (const curve of ["smooth", "quick", "gentle", "linear"])
  assert.match(widget, new RegExp(`animationCurve === "${curve}"`), `missing ${curve} curve behavior`)
assert.doesNotMatch(widget, /animatedScaleBinding|slot\.scale = Qt\.binding/,
  "drawer transitions must never resample every widget through scale animation")
assert.match(model, /function revealOpacity[\s\S]*mode === "taskbar"\) return 1/,
  "the default taskbar style must avoid per-frame opacity work")
assert.match(widget, /slot\.clip = Qt\.binding\(root\.animatedClipBinding\(\)\)/,
  "shrinking slots must clip their live widget instead of painting overlapping full-size content")
assert.match(model, /total \* p - trailing/,
  "the reveal must preserve spacing by distributing one shared clipped extent from the toggle outward")
assert.doesNotMatch(model, /mode === "uniform"[\s\S]{0,80}own \* p/,
  "uniform style must not restore the all-slots-resize performance regression")
assert.match(model, /mode === "cascade"[\s\S]*fadeSpan = 0\.18[\s\S]*local \* local \* \(3 - 2 \* local\)/,
  "cascade must use a bounded spatial opacity wave instead of overlapping geometry animations")
assert.match(widget, /for \(var reverseIndex = slots\.length - 1; reverseIndex >= 0; reverseIndex--\)/,
  "taskbar-style reveal must expose the slot nearest the toggle first")
assert.match(widget, /transitionTopologyKey[\s\S]*onTransitionTopologyKeyChanged:\s*scheduleSlotBinding/,
  "monitor state changes must not tear down slot bindings during animation")
assert.doesNotMatch(widget, /function onDrawerStateChanged\(\)[\s\S]*scheduleSlotBinding/,
  "generic state changes must not trigger mid-animation slot rebinding")
assert.doesNotMatch(widget, /revealAnimation/,
  "the taskbar-style Behavior must not retain references to the removed imperative animator")
assert.match(widget, /HoverHandler[\s\S]*target:\s*root\.hoverRegion[\s\S]*root\.scheduleHoverCollapse\(\)/,
  "hover behavior must cover the full monitor-local drawer group")
assert.match(widget, /function wholeBarHovered\(\)[\s\S]*bar\.barHovered/,
  "hover mode must observe the complete monitor-local bar surface")
assert.match(widget, /Connections\s*\{[\s\S]*target:\s*root\.bar[\s\S]*function onBarHoveredChanged\(\)/,
  "leaving the complete bar must drive delayed hover collapse")
assert.match(widget, /if \(root\.drawerService && root\.localMode === "hover"[\s\S]{0,100}!root\.wholeBarHovered\(\) && !root\.settingsOpen\)/,
  "delayed hover collapse must recheck the complete bar and settings state")
assert.match(widget, /onTriggered:[\s\S]*root\.localMode === "hover"[\s\S]*!root\.wholeBarHovered/,
  "an armed hover timer must not collapse after switching to click mode")
assert.match(widget, /onLocalModeChanged:[\s\S]*hoverCollapseTimer\.stop\(\)/,
  "mode changes must cancel stale hover timers")
assert.match(widget, /onSettingsOpenChanged:[\s\S]*scheduleHoverCollapse\(\)/,
  "closing settings off-bar must resume the hover-collapse policy")
assert.match(widget, /function scheduleSlotBinding\(\)[\s\S]*transitionInProgress\(\)[\s\S]*bindingDeferred = true/,
  "topology rebinding must defer until an active animation settles")
assert.match(service, /function setExpandedFor\(screenName, nextExpanded\)/)
assert.match(service, /function toggleFor\(screenName\)/)
assert.match(service, /function setModeFor\(screenName, mode\)/)
assert.match(widget, /readonly property bool localExpanded:[\s\S]*expandedFor\(presentationScreenName\)/,
  "every monitor presentation must project its own persistent state")
assert.match(appearanceSettings, /Right-click always opens settings/)
assert.doesNotMatch(drawerSettings, /Style\.(?:spacing|radius)\./,
  "settings must use Style.space(), which is available on the supported Omarchy runtime")
assert.match(legacyBar, /Loader\s*\{\s*active:\s*drawerToggle\.managerOpen[\s\S]*sourceComponent:\s*PopupCard/)
assert.match(legacyBar, /WidgetDrawerToggle\s*\{\}/, "the legacy UI must remain intact")
console.log("App Drawer QML and IPC contracts passed")
