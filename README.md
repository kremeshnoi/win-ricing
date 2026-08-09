# Windows ricing

Windows 11 rice: tiling WM, taskbar on top with no Start button, a launcher instead of the Start menu, key remaps, agent navigation inside WSL, and a Spotify theme.

Verified on Windows 11 25H2, build 26200.

## Stack

| Component | Version | Role |
|---|---|---|
| [GlazeWM](https://github.com/glzr-io/glazewm) | 3.10.1 | tiling window manager, one workspace per app |
| [YASB](https://github.com/amnweb/yasb) | 2.0.6 | status bar at the top, the only bar on screen |
| [AutoHotkey](https://www.autohotkey.com) + `no-start-menu.ahk` | 2.0.26 | suppresses the Start menu on a lone Win press, keeps Win as a modifier, drives herdr |
| [Windhawk](https://windhawk.net) + 5 mods, 1 active | 1.7.3 | keeps the system taskbar permanently hidden; the four cosmetic mods are off because there is nothing left to style |
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
| `lwin+alt+h/j/k/l` | focus by direction — focus only, nothing is relocated |
| `lwin+shift+←↑↓→` | move window — this is what swaps neighbours |
| `lwin+shift+l` | cycle focus, most-recent order, across workspaces rather than within one |
| `lwin+q` | close window |
| `lwin+a` | fullscreen |
| `lwin+shift+f` | floating |
| `lwin+v` | split direction |
| `lwin+shift+v` | tiling |
| `lwin+r` | resize mode: `hjkl`/arrows inside, `esc` to leave |
| `lwin+enter` | new terminal |
| `lwin+shift+r` | reload config |
| `lwin+shift+w` | redraw |
| `lwin+shift+p` | pause the WM |
| `lwin+shift+e` | exit the WM |

Left to the system: `Win+Space` (keyboard layout), `Win+E`, `Win+P`. Every other `Win+<key>` from the tables above is taken over.

`Win+Shift+S` is **not** left to the system, despite being the region-screenshot shortcut. It falls out of the "`lwin+shift+<same key>` moves the window there" rule — spotify sits on `lwin+s`, so the move took `lwin+shift+s`, and GlazeWM swallows it before the shell sees it. A PowerToys remap onto the same combination was tried and removed for that reason, see section 4. `PrtScn` is bound by nothing here and still opens the region snip. Unresolved: freeing it means moving the spotify move binding, e.g. to `lwin+shift+4`. `Win+L` is a special case — winlogon handles it below every user-mode hook, so neither GlazeWM nor AutoHotkey can see it — and it stays unusable unless the lock shortcut is disabled outright, which section 6 does to free `lwin+l` for herdr.

### Window effects

| Setting | Value |
|---|---|
| `border.enabled` | `false` for both focused and unfocused |
| `corner_style` | `rounded`, both |
| `hide_title_bar` | `false`, both |
| `transparency` | `false`, both |
| `gaps` | 8 px inner, 8 px on every outer edge, DPI-scaled |

`border.enabled: false` does not mean "leave the border alone" — it means there is no border at all. In `platform_impl/windows/native_window.rs` the effect maps to `DwmSetWindowAttribute(DWMWA_BORDER_COLOR)` with `DWMWA_COLOR_NONE` when no colour is configured, and to the colour itself otherwise. Windows draws its default 1 px border only while GlazeWM is not running.

Two things follow. A colour cannot be made invisible: `models/color.rs` demands a leading `#` and exactly 7 or 9 characters, so `transparent` and `none` are rejected, and `to_bgr()` builds the value from `b`, `g`, `r` alone — the alpha in a 9-character `#rrggbbaa` is parsed and then dropped, so `#00000000` paints black rather than nothing. And `wm-reload-config` does not always re-apply the attribute to windows that are already open; follow it with `wm-redraw`.

Corners stay `rounded` to match the bar, at the cost of the screen corners showing through in fullscreen — `maximized: true` would square them, since Windows never rounds a genuinely maximized window, but it was tried and rejected. `shown_on_top` does nothing in 3.10.1: the state reports `shownOnTop: false` whether it is set through the CLI flag, the bare flag, or `state_defaults`.

## 2. Start menu on a lone Win press

The shell opens Start on Win release if no other key was pressed in between. GlazeWM has no switch for this. The script sends an unassigned `vkE8` while Win is held, so the shell stops treating the press as solitary. `{Blind}` keeps AutoHotkey from releasing Win itself — that release alone would pop Start open. `~` lets the key pass through, so Win keeps working as a modifier for GlazeWM and for `Win+E`/`Win+Space`.

```powershell
winget install --id AutoHotkey.AutoHotkey -e
Copy-Item glazewm\no-start-menu.ahk "$env:USERPROFILE\.glzr\glazewm\no-start-menu.ahk" -Force
```

Autostart from an elevated PowerShell:

```powershell
scripts\install-autostart.ps1
```

It registers `\win-ricing\autohotkey` in Task Scheduler — at logon, run level Highest, no execution time limit, restart three times a minute apart — and drops the older shortcut in Startup if one is left over.

Not a Startup shortcut, and not `general.startup_commands` in GlazeWM: `shell-exec` in 3.10.1 breaks on paths with spaces, quoted or not, and a shortcut in Startup starts AutoHotkey unelevated. Terminal runs with `"elevate": true`, so an unelevated keyboard hook is cut off by UIPI and every binding from section 6 silently dies while that window has focus. Run level Highest is what makes them survive.

GlazeWM stays on the `HKCU\...\Run` key its installer creates, unelevated on purpose. Its manifest carries `uiAccess="true"`, which already lets it drive elevated windows without an elevated token — and a `uiAccess` binary launched at run level Highest fails outright with `0x800702E4` (`ERROR_ELEVATION_REQUIRED`). AutoHotkey ships a `AutoHotkey64_UIA.exe` built the same way; elevation is used here instead because it needs no trusted signature.

The same script also carries the herdr hotkeys from section 6, so this one task is all the autostart there is.

The script sets `#NoTrayIcon` — no tray icon, so Exit or Suspend Hotkeys can't be hit by accident. To stop it: `taskkill /im AutoHotkey64.exe`.

To check the whole chain — elevation of each process, the task, the `Run` key, the lock policy, `herdr-nav` over `wsl.exe` and the herdr socket:

```powershell
scripts\doctor.ps1
```

## 3. Windhawk

```powershell
winget install --id RamenSoftware.Windhawk -e
```

Mods are installed by name from the catalog inside Windhawk. Settings are edited in each mod's UI; the values below are the current ones, anything not listed is left at default.

| Mod | Version | State | What it does |
|---|---|---|---|
| Taskbar auto-hide fine tuning | 2.3 | active | `mode: never` — the taskbar never reveals itself, not on hover, not on notifications, not on the Win key |
| Hide Start Button | 1.0 | off | removes the Start button from the taskbar |
| Taskbar height and icon size | 1.3.7 | off | height 44, icons 20, button width 42 |
| Taskbar on top for Windows 11 | 1.1.7 | off | moves the taskbar to the top of the screen |
| Windows 11 Taskbar Styler | 1.8 | off | `SimplyTransparent` theme |

Only the first one is enabled. The other four style a taskbar that is never drawn, so they are kept installed but off — their settings are recorded below in case the approach is ever reverted to a visible taskbar. Order only matters if they come back on: Styler paints over geometry that's already been changed, so after changing taskbar height or position, reload it (toggle the mod off/on).

### Taskbar auto-hide fine tuning

YASB does not touch the system taskbar — it only registers itself as an appbar, and its `hide_taskbar_widget` option refers to its own widget, not to `Shell_TrayWnd`. Hiding the real taskbar is this mod's job.

It fine-tunes auto-hide rather than replacing it, so Windows' own auto-hide has to stay on — the checkbox in Settings, or bit 0 of `HKCU\...\Explorer\StuckRects3\Settings[8]`. With auto-hide on the taskbar reserves no work area, which is what GlazeWM measures against; `mode: never` then removes the reveal-on-hover that auto-hide leaves behind.

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

The remap is global with `exactMatch` off — it fires even with extra modifiers held.

There used to be a second one, `Win+Shift+Enter` → `Win+Shift+S` for the region screenshot. It was removed because it never worked: it synthesises `Win+Shift+S`, and GlazeWM claims that combination for the spotify move binding before the shell sees it, as described at the end of section 1. `PrtScn` does the same job and is bound by nothing here.

## 5. Windows Terminal

```powershell
Copy-Item terminal\settings.json "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" -Force
```

GlazeWM routes it to the `term` workspace by process name `WindowsTerminal`, and the herdr bindings in section 6 are active only while this window has focus.

`profiles.defaults` sets `"elevate": true`, so every window runs as administrator. That decides the autostart in section 2: an unelevated AutoHotkey cannot deliver a single hotkey into this window.

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

The hotkeys sit in `no-start-menu.ahk` next to the Start-menu suppression, so the scheduled task from section 2 already launches them — nothing separate to autostart. That task has to run elevated, otherwise UIPI blocks the hook from the elevated Terminal window and all six bindings fall through to the system. A round trip through `wsl.exe` costs about 95 ms; an elevated `wsl.exe` reaches the same distro instance and the same socket.

In `config.toml` the six matching `[keys]` entries are set to `""`: the same jump must not exist on two paths. `prefix = "ctrl+z"` stays, because `focus_pane_*` hangs off it and pane navigation has no lwin equivalent. GlazeWM used to hold `lwin+←↑↓→` for focus by direction; that moved to `lwin+alt+h/j/k/l`, so the arrows are free now if pane focus should ever be lifted onto `lwin`.

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

## 10. YASB

The only bar on screen — the system taskbar is hidden for good in section 3. Placed here rather than next to GlazeWM to keep the section numbers stable; in practice it is installed right after it.

```powershell
winget install --id AmN.yasb -e
Copy-Item yasb\config.yaml "$env:USERPROFILE\.config\yasb\config.yaml" -Force
Copy-Item yasb\styles.css "$env:USERPROFILE\.config\yasb\styles.css" -Force
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v YASB /t REG_SZ /d "C:\Program Files\Yasb\yasb.exe" /f
```

| Setting | Value |
|---|---|
| position | top, centered, 100% width |
| height | 36, padding 8 on top, left and right |
| `windows_app_bar` | `true` — registers as an appbar, so the work area shrinks and GlazeWM tiles below the bar |
| `always_on_top` | `false` |
| left widgets | cpu, gpu, memory, disk c/d/g |
| centre widgets | cava, media |
| right widgets | glazewm_workspaces, systray, open_meteo, language, clock |

`glazewm_workspaces` talks to GlazeWM over its IPC websocket, which is why the bar keeps working while GlazeWM runs unelevated and Terminal runs elevated — sockets are not subject to UIPI.

Styling is matched to the window frames from section 1: `--border-radius` 8, `--border-radius2` 6, `--border-radius3` 4 against `corner_style: rounded`, and `border: 1px solid var(--border)` on `.widget` with `--border: #333735`. That one variable is used by 48 declarations — tooltips, context menus, the clock and audio popups, systray and media flyouts all take their border from it.

`system_colors: true` makes YASB generate `yasb_colors.css` from the Windows accent colour on every start. `styles.css` imports it, but it is not tracked here — it is a generated file and would only ever conflict.

Both `watch_config` and `watch_stylesheet` are on, so edits apply on save. Edits written from inside WSL over `/mnt/c` often fail to raise the change notification the watcher listens for; reload explicitly instead:

```powershell
& "C:\Program Files\Yasb\yasbc.exe" reload
```

## Debugging

The CLI works from WSL without elevation and needs no separate `start`:

```bash
"/mnt/c/Program Files/glzr.io/GlazeWM/cli/glazewm.exe" query windows
"/mnt/c/Program Files/glzr.io/GlazeWM/cli/glazewm.exe" command <cmd> --help
```

Calling it with no subcommand answers `Invalid argument` — that's the missing subcommand, not an interop problem. Config errors are written to `%USERPROFILE%\.glzr\glazewm\errors.log`.

When every `lwin+*` binding stops working at once inside Terminal while the rest of the rice is fine, it is elevation, not herdr. `scripts\doctor.ps1` prints it directly; the manual check is:

```powershell
Get-Process AutoHotkey64, glazewm, WindowsTerminal | Select-Object ProcessName, Id
```

AutoHotkey must be elevated, GlazeWM must not be. Re-running `scripts\install-autostart.ps1` from an elevated shell restores both, plus the `DisableLockWorkstation` policy from section 6.
