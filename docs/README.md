# Docs

How the Windows rice is built, where each file goes and why it is the way it is.

| Page | What it answers |
|---|---|
| [inventory.md](inventory.md) | every file, where it is deployed, what reads it |
| [keybindings.md](keybindings.md) | every global shortcut and the physical key behind it |
| [troubleshooting.md](troubleshooting.md) | failures already met and their fixes |
| [adr/](adr/README.md) | decisions that shaped the rice |

## Applying a change

Nothing is linked: the files under `glazewm/` are copies in `%USERPROFILE%\.glzr\glazewm\`.

1. Edit the file here.
2. Copy it to its place from [inventory.md](inventory.md).
3. Reload what reads it: GlazeWM with `ctrl+alt+shift+r`, AutoHotkey by running the `\win-ricing\autohotkey` scheduled task, YASB from its tray menu.

`glazewm/install-autostart.ps1` (as administrator) registers everything that starts at logon and ends with `glazewm/doctor.ps1`, which checks it.

## Principle

GlazeWM's own behaviour comes first. A helper script stays only for what GlazeWM cannot do at all, see [ADR 0001](adr/0001-glazewm-defaults-over-helper-daemons.md).
