# OmaBar Drawer

An Ice-style replacement bar for Omarchy Quattro. It keeps the normal Omarchy bar behavior while collapsing every widget in the right section behind a single far-right icon.

Click the far-right ellipsis to reveal the widgets. Click the chevron to hide them again. Hidden widgets remain loaded, preserving their state and avoiding needless restarts.

Right-click the drawer icon to choose widgets that should remain visible. Every right-side widget starts inside the drawer; selections such as Power or Battery are persisted in Omarchy's `shell.json` configuration.

## Install

```bash
omarchy plugin add https://github.com/amitcpatel/omabar-drawer.git --yes
omarchy bar use io.github.amitcpatel.omabar-drawer
```

## Remove

```bash
omarchy bar reset
omarchy plugin remove io.github.amitcpatel.omabar-drawer --yes
```

## Development

The bar is derived from the MIT-licensed Omarchy Quattro bar and retains compatibility with the standard `shell.json` layout. The left and center sections are unchanged; only the right section receives the collapsible drawer.
