# Keybindings

Ctrl and Alt are swapped in the Wooting firmware, so the key next to the space bar sends `ctrl` and the corner key sends `alt`. That matches the Mac, where `cmd` sits next to the space bar and `ctrl` in the corner, [ADR 0004](adr/0004-mac-like-modifiers.md).

| Physical key | Windows sees | Mac equivalent |
|---|---|---|
| next to space | `ctrl` | `cmd` |
| corner | `alt` | `ctrl` |
| Win | `lwin` | `option` |

## Who owns which modifier

| Modifier | Owner |
|---|---|
| `ctrl+shift+<key>` | GlazeWM, focus a workspace, [ADR 0003](adr/0003-workspaces-on-ctrl-shift.md) |
| `ctrl+alt+shift+<key>` | GlazeWM, move the window to a workspace |
| `ctrl+alt+<key>` | GlazeWM, windows and the WM itself |
| `lwin+<key>` in the terminal | herdr through `index.ahk` |
| `ctrl+tab`, `ctrl+shift+tab` | Windows window switcher through `index.ahk` |
| `alt+tab` | Windows window switcher; in Zen next tab, `alt+shift+tab` previous |
| `alt+space` | keyboard layout |
| `ctrl+left`, `ctrl+right` on `eve` and `browser` | previous / next EVE or Zen slot through `index.ahk`, [ADR 0005](adr/0005-zen-slots.md) |

The full list with every key is in `glazewm/keymap.html`.

## Not bound on purpose

| Shortcut | Why |
|---|---|
| `ctrl+enter` | apps use it to send; a global binding broke it everywhere |
