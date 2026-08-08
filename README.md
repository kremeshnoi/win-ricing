# Windows ricing

Windows 11 rice: tiling WM, taskbar on top with no Start button, a launcher instead of the Start menu, key remaps, agent navigation inside WSL, and a Spotify theme.

Verified on Windows 11 25H2, build 26200.

## Stack

| Component | Version | Role |
|---|---|---|
| [GlazeWM](https://github.com/glzr-io/glazewm) | 3.10.1 | tiling window manager, one workspace per app |
| [AutoHotkey](https://www.autohotkey.com) + `no-start-menu.ahk` | 2.0.26 | suppresses the Start menu on a lone Win press, keeps Win as a modifier, drives herdr |
| [Windhawk](https://windhawk.net) + 4 mods | 1.7.3 | taskbar on top, no Start button, compact height, transparent theme |
| [PowerToys](https://github.com/microsoft/PowerToys) Keyboard Manager | 0.100.2 | shortcut remaps the system itself won't let you rebind |
| Windows Terminal | — | WSL host, the only window herdr bindings are scoped to |
| [herdr](https://herdr.dev) | 0.7.5 | terminal workspace manager for AI agents, runs inside WSL |
| [Raycast](https://www.raycast.com/windows) | — | launcher replacing the Start menu |
| [Spicetify](https://spicetify.app) | 2.44.0 | Spotify theme |
| — | — | Xbox Game Bar removed to free up Win+G |
| — | — | `DisableLockWorkstation` policy set to free up Win+L |

Single modifier — `lwin`. Chosen because Win combos never reach nvim through the terminal, `alt+*` in nvim is taken (Alt is remapped to Ctrl there), and `ctrl+<digit>` means browser tabs and messenger channels.

This repo is plugged into [dotfiles](https://github.com/kremeshnoi/dotfiles) as the `windows` submodule — macOS and NixOS configs live there, so keybinding letters stay in sync across systems.

```powershell
git clone git@github.com:kremeshnoi/win-ricing.git
```

## 1. GlazeWM

```powershell
winget install --id glzr-io.glazewm -e
```

Copy the config (no symlinks here):

```powershell
Copy-Item glazewm\config.yaml "$env:USERPROFILE\.glzr\glazewm\config.yaml" -Force
```

Autostart:

```powershell
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v GlazeWM /t REG_SZ /d "C:\Program Files\glzr.io\GlazeWM\glazewm.exe" /f
```

Apply the config without logging out:

```powershell
& "C:\Program Files\glzr.io\GlazeWM\cli\glazewm.exe" command wm-reload-config
```

### Workspaces

Letters match the AeroSpace config on macOS wherever possible — it lives in the [dotfiles](https://github.com/kremeshnoi/dotfiles) repo under `mac/aerospace/`. Digits sit at the edges of the number row, letters follow the app name.

| Binding | Workspace | Window process |
|---|---|---|
| `lwin+0` | desktop | — |
| `lwin+1` | 1password | `1Password` |
| `lwin+9` | misc | everything else |
| `lwin+t` | term | `WindowsTerminal` |
| `lwin+g` | chrome | `chrome` |
| `lwin+c` | claude | `claude` |
| `lwin+o` | obsidian | `Obsidian` |
| `lwin+d` | discord | `Discord` |
| `lwin+m` | telegram | `Telegram` |
| `lwin+s` | spotify | `Spotify` |
| `lwin+tab` | previous workspace | — |

`lwin+shift+<same key>` — move the focused window to that workspace and follow it.

App routing lives in `window_rules` and matches on process name. Anything that matches no rule ends up in `misc` via a `not_regex` catch-all — the rules are mutually exclusive, so order doesn't matter. Installing the apps from the table is optional: without them the workspace just stays empty.

### Window management

| Binding | Action |
|---|---|
| `lwin+a` | cycle through windows in the workspace |
| `lwin+←↑↓→` | focus by direction |
| `lwin+shift+←↑↓→` | move window |
| `lwin+q` | close window |
| `lwin+f` | fullscreen |
| `lwin+shift+f` | floating |
| `lwin+v` | split direction |
| `lwin+shift+v` | tiling |
| `lwin+r` | resize mode: `hjkl`/arrows inside, `esc` to leave |
| `lwin+enter` | new terminal |
| `lwin+shift+r` | reload config |
| `lwin+shift+w` | redraw |
| `lwin+shift+p` | pause the WM |
| `lwin+shift+e` | exit the WM |

Left to the system: `Win+Space` (keyboard layout), `Win+E`, `Win+P`, `Win+Shift+S`. Every other `Win+<key>` from the tables above is taken over. `Win+L` is a special case — winlogon handles it below every user-mode hook, so neither GlazeWM nor AutoHotkey can see it — and it stays unusable unless the lock shortcut is disabled outright, which section 6 does to free `lwin+l` for herdr.

## 2. Start menu on a lone Win press

The shell opens Start on Win release if no other key was pressed in between. GlazeWM has no switch for this. The script sends an unassigned `vkE8` while Win is held, so the shell stops treating the press as solitary. `{Blind}` keeps AutoHotkey from releasing Win itself — that release alone would pop Start open. `~` lets the key pass through, so Win keeps working as a modifier for GlazeWM and for `Win+E`/`Win+Space`.

```powershell
winget install --id AutoHotkey.AutoHotkey -e
Copy-Item glazewm\no-start-menu.ahk "$env:USERPROFILE\.glzr\glazewm\no-start-menu.ahk" -Force
```

Autostart via a shortcut in Startup:

```powershell
$w = New-Object -ComObject WScript.Shell
$lnk = $w.CreateShortcut("$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\no-start-menu.lnk")
$lnk.TargetPath = 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe'
$lnk.Arguments = "$env:USERPROFILE\.glzr\glazewm\no-start-menu.ahk"
$lnk.Save()
```

Not through `general.startup_commands` in GlazeWM: `shell-exec` in 3.10.1 breaks on paths with spaces, quoted or not.

The same script also carries the herdr hotkeys from section 6, so this one shortcut is all the autostart there is.

The script sets `#NoTrayIcon` — no tray icon, so Exit or Suspend Hotkeys can't be hit by accident. To stop it: `taskkill /im AutoHotkey64.exe`.

If Start only pops up while an elevated window has focus, the non-elevated hook can't see those windows. Move the autostart from Startup to Task Scheduler with "run with highest privileges" checked.

## 3. Windhawk

```powershell
winget install --id RamenSoftware.Windhawk -e
```

Mods are installed by name from the catalog inside Windhawk. Settings are edited in each mod's UI; the values below are the current ones, anything not listed is left at default.

| Mod | Version | What it does |
|---|---|---|
| Hide Start Button | 1.0 | removes the Start button from the taskbar; Start itself stays reachable from the keyboard |
| Taskbar on top for Windows 11 | 1.1.7 | moves the taskbar to the top of the screen |
| Taskbar height and icon size | 1.3.7 | height 44, icons 20, button width 42 |
| Windows 11 Taskbar Styler | 1.8 | `SimplyTransparent` theme |

Order only matters on first install: Styler paints over geometry that's already been changed, so after changing taskbar height or position, reload it (toggle the mod off/on).

### Hide Start Button

Removes the Start button from the taskbar. No settings.

### Taskbar on top for Windows 11

| Setting | Value |
|---|---|
| `taskbarLocation` | `top` |
| `taskbarLocationSecondary` | `sameAsPrimary` |
| `runningIndicatorsOnTop` | on |
| `startMenuAnimationAdjust` | on |

### Taskbar height and icon size

| Setting | Value |
|---|---|
| `TaskbarHeight` | 44 |
| `IconSize` | 20 |
| `TaskbarButtonWidth` | 42 |
| `IconSizeSmall` | 22 |
| `TaskbarButtonWidthSmall` | 32 |

### Windows 11 Taskbar Styler

| Setting | Value |
|---|---|
| `theme` | `SimplyTransparent` |
| `clickThroughTaskbar` | off |
| `xamlDiagnosticsHandling` | `alert` |

`styleConstants`, `controlStyles` and `themeResourceVariables` are empty — the theme is applied as-is.

## 4. PowerToys Keyboard Manager

```powershell
winget install --id Microsoft.PowerToys -e
Copy-Item powertoys\default.json "$env:LOCALAPPDATA\Microsoft\PowerToys\Keyboard Manager\default.json" -Force
```

Keyboard Manager reloads the file on change; if it doesn't pick it up, toggle the module off/on in PowerToys Settings.

| From | To | Why |
|---|---|---|
| `Ctrl+Tab` | `Alt+Tab` | window switcher on a combo that doesn't stretch the pinky; `Win+Tab` is taken by GlazeWM for the previous workspace |
| `Win+Shift+Enter` | `Win+Shift+S` | region screenshot, alongside the other `Win+Shift+*` bindings from GlazeWM |

Both remaps are global with `exactMatch` off — they fire even with extra modifiers held.

## 5. Windows Terminal

```powershell
Copy-Item terminal\settings.json "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" -Force
```

GlazeWM routes it to the `term` workspace by process name `WindowsTerminal`, and the herdr bindings in section 6 are active only while this window has focus.

## 6. herdr navigation

herdr is installed inside WSL, so it is a TUI behind the terminal rather than a Windows process. Win never reaches it: the OS claims Win combos first, and terminals don't forward the Super modifier to console applications. Its own `[keys]` section cannot express a `win+*` binding at all — that part has to live on the Windows side.

So the key is caught by AutoHotkey and turned into a socket call instead of emulated keystrokes:

```
lwin+<key> → AutoHotkey → wsl.exe → herdr-nav → ~/.config/herdr/herdr.sock
```

Install, inside WSL:

```bash
brew install herdr
cp herdr/config.toml ~/.config/herdr/config.toml
cp herdr/herdr-nav ~/.local/bin/herdr-nav
chmod +x ~/.local/bin/herdr-nav
```

`herdr-nav` exists because the CLI only focuses by id — `tab focus <tab_id>`, `agent focus <target>`, `workspace focus <workspace_id>` — and has no relative next/prev. The script reads the matching `list`, finds the focused entry and steps to its neighbour cyclically, staying within the current workspace. Order follows the API response, not the `number` field, which does not match the visual order.

Free up `Win+L`:

```powershell
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableLockWorkstation /t REG_DWORD /d 1 /f
```

Without it `lwin+l` locks the screen and never reaches AutoHotkey. The policy takes effect on next sign-in. It costs every manual lock, not just the shortcut: the Lock entry disappears from Ctrl+Alt+Del and from the Start menu as well. Locking on timeout, on sleep and via the password-protected screensaver keeps working.

| Binding | Action |
|---|---|
| `lwin+h` / `lwin+l` | previous / next tab |
| `lwin+k` / `lwin+j` | previous / next agent |
| `lwin+shift+k` / `lwin+shift+j` | previous / next workspace |

The hotkeys sit in `no-start-menu.ahk` next to the Start-menu suppression, so the Startup shortcut from section 2 already launches them — nothing separate to autostart. A round trip through `wsl.exe` costs about 95 ms.

In `config.toml` the six matching `[keys]` entries are set to `""`: the same jump must not exist on two paths. `prefix = "ctrl+z"` stays, because `focus_pane_*` hangs off it and pane navigation has no lwin equivalent — `lwin+←↑↓→` is taken by GlazeWM for focus by direction.

| Binding | Action |
|---|---|
| `ctrl+z` then `←↓↑→` | focus pane inside the tab |

Because the bindings are scoped to `WinActive("ahk_exe WindowsTerminal.exe")`, they do nothing in another terminal, with AutoHotkey not running, or in a `herdr --remote` session over SSH. There is no fallback on the herdr side by design.

## 7. Raycast

Launcher in place of the Start menu: the button is gone via Windhawk and a lone Win press is swallowed by AHK, so there's nothing left to open Start with — and no reason to.

Install from [raycast.com/windows](https://www.raycast.com/windows). Settings live in the Raycast account and locally in `%LOCALAPPDATA%\Raycast` as sqlite databases — not versioned here, restored by logging in.

## 8. Spicetify

```powershell
winget install --id Spicetify.Spicetify -e
spicetify backup apply
```

Marketplace as a custom app; the theme is installed from there:

```powershell
spicetify config custom_apps marketplace
spicetify apply
```

Theme — **Text** (by darkthemer), installed with the Install button in Marketplace inside Spotify. `current_theme` in `%APPDATA%\spicetify\config-xpui.ini` stays `marketplace`: Marketplace injects the CSS itself, so `Themes\` holds nothing but an empty `color.ini` and the selected theme lives in Spotify's localStorage. Consequence — after a Spotify reinstall the theme has to be picked again; the config won't restore it.

A Spotify update wipes the patch; fix with:

```powershell
spicetify backup apply
```

## 9. Xbox Game Bar

It holds `Win+G`, which is given to Chrome. On 25H2 the old `AppCaptureEnabled=0` recipe no longer kills the overlay: it isn't tied to recording anymore. The package uninstalls without admin rights and can be reinstalled from the Store.

```powershell
Get-AppxPackage -Name 'Microsoft.XboxGamingOverlay' | Remove-AppxPackage
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v AppCaptureEnabled /t REG_DWORD /d 0 /f
reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 0 /f
```

A protocol stub so games don't trigger the "You'll need a new app to open this ms-gamingoverlay link" popup:

```powershell
reg add "HKCU\Software\Classes\ms-gamingoverlay" /ve /t REG_SZ /d "URL:ms-gamingoverlay" /f
reg add "HKCU\Software\Classes\ms-gamingoverlay" /v "URL Protocol" /t REG_SZ /d "" /f
reg add "HKCU\Software\Classes\ms-gamingoverlay\shell\open\command" /ve /t REG_SZ /d "C:\Windows\System32\rundll32.exe" /f
```

## Debugging

The CLI works from WSL without elevation and needs no separate `start`:

```bash
"/mnt/c/Program Files/glzr.io/GlazeWM/cli/glazewm.exe" query windows
"/mnt/c/Program Files/glzr.io/GlazeWM/cli/glazewm.exe" command <cmd> --help
```

Calling it with no subcommand answers `Invalid argument` — that's the missing subcommand, not an interop problem. Config errors are written to `%USERPROFILE%\.glzr\glazewm\errors.log`.
