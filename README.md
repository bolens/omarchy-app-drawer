# OmaBar Drawer

An Ice-style replacement bar for Omarchy Quattro. It keeps the normal Omarchy bar behavior while collapsing every widget in the right section behind a single far-right icon.

![OmaBar Drawer collapsed and expanded](preview.png)

Click the far-right ellipsis to reveal the widgets. Click the chevron to hide them again. Hidden widgets remain loaded, preserving their state and avoiding needless restarts.

Right-click the drawer icon to choose widgets that should remain visible. Every right-side widget starts inside the drawer; selections such as Power or Battery are persisted in Omarchy's `shell.json` configuration.

## Install

```bash
omarchy plugin add https://github.com/amitcpatel/omabar-drawer.git
omarchy bar use io.github.amitcpatel.omabar-drawer
```

## Remove

```bash
omarchy bar reset
omarchy plugin remove io.github.amitcpatel.omabar-drawer
```

Removing the plugin does not delete your other bar layout or widget settings. `omarchy bar reset` switches back to the stock Omarchy bar before removal.

## Requirements and dependencies

- Omarchy Quattro 4.0 or newer with full-bar plugin support.
- The standard Omarchy shell and its bundled QML modules.
- A Nerd Font supplied by Omarchy for the drawer glyphs.

There are no external packages, downloads, services, accounts, API keys, or network dependencies.

## Configuration and privacy

OmaBar Drawer reads the existing `bar.layout` section from `~/.config/omarchy/shell.json`. It changes configuration only after an explicit user action:

- `omarchy bar use io.github.amitcpatel.omabar-drawer` records the selected bar ID.
- Choosing a widget from the right-click menu records its ID in `bar.drawerAlwaysVisible`.

The plugin does not collect telemetry, access credentials, transmit data, request elevated privileges, install packages, or create background services. It retains the stock bar's support for user-authored command widgets; those commands run only when already configured by the user in `shell.json`.

## Development

The bar is derived from the MIT-licensed Omarchy Quattro bar and retains compatibility with the standard `shell.json` layout. The original copyright notice is preserved in [LICENSE](LICENSE). The left and center sections are unchanged; only the right section receives the collapsible drawer.
