# Inventory

`%G%` is `%USERPROFILE%\.glzr\glazewm`.

## glazewm/

| File | Deployed to | Read by | Purpose |
|---|---|---|---|
| `config.yaml` | `%G%\config.yaml` | GlazeWM | workspaces, window rules, keybindings |
| `index.ahk` | `%G%\index.ahk` | AutoHotkey, `\win-ricing\autohotkey` task, elevated | lone Win press does not open Start, layout switch on `alt+space`, window switcher on `ctrl+tab`, tab switch on `alt+tab` in Zen, herdr navigation in the terminal, EVE and Zen slot keys |
| `workspaces.ahk`, `workspaces.vbs` | `%G%\` | YASB workspace widget on click | workspace menu under the cursor |
| `kill-workspace.ps1`, `kill-workspace.vbs` | `%G%\` | GlazeWM `ctrl+shift+q` | closes every window of the workspace and kills the processes behind them |
| `eve.ps1`, `eve.vbs` | `%G%\` | `Run\GlazeWM Eve` at logon | keeps EVE clients in slots on `12-eve`; writes `workspace.txt`, `workspaces.txt` and `eve-slots.txt` for YASB and the workspace menu |
| `zen.ps1`, `zen.vbs` | `%G%\` | `Run\GlazeWM Zen` at logon | keeps Zen windows in full-size slots on `4-browser`; writes `zen-slots.txt` for YASB |
| `install-autostart.ps1` | run from the repo | by hand, as administrator | registers the AutoHotkey task and the `Run` keys, removes stale ones |
| `doctor.ps1` | run from the repo | `install-autostart.ps1`, by hand | checks the autostart entries and daemons |
| `keymap.html` | Docker image | `Dockerfile` | printable keymap |

## Other directories

| File | Deployed to | Read by | Purpose |
|---|---|---|---|
| `yasb/config.yaml`, `yasb/styles.css` | `%USERPROFILE%\.config\yasb\` | YASB | the top bar |
| `terminal/settings.json` | Windows Terminal settings | Windows Terminal | WSL profile |
| `terminal/install-helix-open.ps1`, `terminal/helix-open.vbs` | `%LOCALAPPDATA%\HelixTerminal\` | Explorer file associations | opens text files in Helix inside Optimum |
| `Dockerfile`, `Caddyfile` | — | Docker | serves `keymap.html` |

## Logon

| Entry | Starts |
|---|---|
| task `\win-ricing\autohotkey` | `index.ahk`, elevated |
| `Run\GlazeWM` | GlazeWM |
| `Run\GlazeWM Eve` | `eve.vbs` |
| `Run\GlazeWM Zen` | `zen.vbs` |

## Removed

| File | Why |
|---|---|
| `autolaunch.ps1` | reopened closed apps and restored minimized windows, [ADR 0001](adr/0001-glazewm-defaults-over-helper-daemons.md) |
| `autotiling.ps1` | overrode `ctrl+alt+v` on every focus change, [ADR 0001](adr/0001-glazewm-defaults-over-helper-daemons.md) |
