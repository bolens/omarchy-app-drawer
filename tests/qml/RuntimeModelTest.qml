pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import "Model.js" as Model

ShellRoot {
  Component.onCompleted: Qt.callLater(function() {
    var config = {bar:{layout:{right:[{id:"tray",x:1},"media",Model.PLUGIN_ID]},drawerExpanded:true}}
    Model.applyExpanded(config, false)
    var collapsed = JSON.stringify(config)
    Model.applyExpanded(config, false)
    if (JSON.stringify(config) !== collapsed) throw new Error("collapse is not idempotent")
    if (config.bar.layout.right.length !== 1 || Model.entryId(config.bar.layout.right[0]) !== Model.PLUGIN_ID)
      throw new Error("collapse projection failed")
    Model.applyPinned(config, "tray", true)
    if (config.bar.layout.right.length !== 2) throw new Error("pin projection failed")
    Model.applyExpanded(config, true)
    if (config.bar.layout.right.length !== 3 || config.bar.layout.right[0].x !== 1)
      throw new Error("restore lost entry identity or settings")
    var settings = Model.appearanceSettings({iconSize:100,leftClickAction:"bad",showTooltip:false})
    if (settings.iconSize !== 30 || settings.leftClickAction !== "toggle" || settings.showTooltip !== false)
      throw new Error("appearance sanitization failed")
    var styles = ["taskbar", "cascade", "softCascade", "uniform"]
    var fingerprints = []
    for (var styleIndex = 0; styleIndex < styles.length; styleIndex++) {
      var style = styles[styleIndex]
      fingerprints.push([
        Model.revealOpacity(style, 0.25, 20, 0, 100).toFixed(4),
        Model.revealOpacity(style, 0.5, 20, 40, 100).toFixed(4),
        Model.revealOpacity(style, 0.75, 20, 80, 100).toFixed(4)
      ].join(":"))
    }
    for (var left = 0; left < fingerprints.length; left++)
      for (var right = left + 1; right < fingerprints.length; right++)
        if (fingerprints[left] === fingerprints[right])
          throw new Error("motion presets share a QML runtime fingerprint")
    var legacy = {bar:{layout:{right:[Model.PLUGIN_ID]},drawerAppearance:{iconSize:99,hoverToExpand:true},drawerTransition:{phase:"expanding"}},plugins:[{id:"old",_omabarDrawerKeepAlive:true}]}
    var migration = Model.migrateConfig(legacy)
    if (!migration.changed || legacy.bar._appDrawerSettingsVersion !== Model.SETTINGS_VERSION
        || legacy.bar.drawerAppearance.iconSize !== 30 || legacy.bar.drawerAppearance.hoverToExpand !== undefined
        || legacy.bar.drawerTransition !== undefined || legacy.plugins.length !== 0
        || Model.migrateConfig(legacy).changed)
      throw new Error("settings migration was not canonical and idempotent")
    console.log("DRAWER_QML_MODEL_OK")
    Qt.quit()
  })
}
