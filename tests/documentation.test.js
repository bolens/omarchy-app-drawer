const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const root = path.join(__dirname,"..")
const readme = fs.readFileSync(path.join(root,"README.md"),"utf8")
const markdownImages = [...readme.matchAll(/!\[([^\]]*)\]\(<?([^)>\s]+)>?(?:\s+"[^"]*")?\)/g)]
for (const state of ["collapsed","expanded"])
  assert.ok(markdownImages.some(([, alt, target]) =>
    target === `screenshots/${state}.png` && new RegExp(state,"i").test(alt)),
  `README must embed the current ${state} screenshot with descriptive alt text`)
assert.match(readme,/same capture width/i,
  "README must describe the equal-width state comparison")
for (const command of ["scripts/migrate-to-stock-bar","scripts/deploy-shell-runtime","npm test","OMABAR_LIVE_TESTS=never","OMABAR_LIVE_TESTS=always"])
  assert.ok(readme.includes(command), `README omits ${command}`)
for (const behavior of ["service entry points","Right-click","settings panel","IPC"])
  assert.ok(readme.toLowerCase().includes(behavior.toLowerCase()), `README omits ${behavior}`)
assert.doesNotMatch(readme,/omarchy bar use io\.github\.(?:amitcpatel\.omabar-drawer|bolens\.app-drawer)/,
  "README must not reactivate the expensive legacy full-bar path")
console.log("App Drawer documentation contracts passed")
