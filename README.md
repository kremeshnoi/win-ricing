# Windows ricing
Windows 11 rice: tiling WM, taskbar on top with no Start button, a launcher instead of the Start menu, key remaps, agent navigation inside WSL, and a Spotify theme.

Verified on Windows 11 25H2, build 26200.

## Showcase
<img width="1920" height="1080" alt="{E5FB1AC5-4EA5-42F4-9D07-5F2A9E45A96B}" src="https://github.com/user-attachments/assets/d08bb3b2-a0a1-4b73-a2cf-741238599411" />
<img width="3840" height="2160" alt="image" src="https://github.com/user-attachments/assets/14f9afb5-e8e1-48c8-968b-64c465a5595c" />


## Stack
| Component | Version | Role |
|---|---|---|
| [GlazeWM](https://github.com/glzr-io/glazewm) | 3.10.1 | tiling window manager, one workspace per app |
| [YASB](https://github.com/amnweb/yasb) | 2.0.6 | status bar at the top, the only bar on screen |
| [AutoHotkey](https://www.autohotkey.com) + `index.ahk` | 2.0.26 | every key remap on this machine: suppresses the Start menu on a lone Win press while keeping Win as a modifier, puts the keyboard layout switch on Alt+Space, puts the window switcher on Ctrl+Tab, drives herdr |
| [Windhawk](https://windhawk.net) + `taskbar-auto-hide-keyboard-only` | 1.7.3 | keeps the system taskbar permanently hidden |
| Windows Terminal | — | WSL host, the only window herdr bindings are scoped to |
| [herdr](https://herdr.dev) | 0.7.5 | terminal workspace manager for AI agents, runs inside WSL |
| [Raycast](https://www.raycast.com/windows) | — | launcher replacing the Start menu |
| [Spicetify](https://spicetify.app) | 2.44.0 | Spotify theme |
| — | — | Xbox Game Bar removed to free up Win+G |
| — | — | `DisableLockWorkstation` policy set to free up Win+L |
