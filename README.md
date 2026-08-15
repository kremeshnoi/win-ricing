# Windows ricing

Windows 11 rice: tiling WM, taskbar on top with no Start button, a launcher instead of the Start menu, key remaps, agent navigation inside WSL, and a Spotify theme.

Verified on Windows 11 25H2, build 26200.

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

## Showcase
<img width="1920" height="1080" alt="{35A6C9F6-FE42-47DC-AB6B-261D606527B4}" src="https://github.com/user-attachments/assets/ad214d89-0f16-4ac4-bbaa-f06ff66b24b4" />
<img width="1920" height="1080" alt="{3A7BD2EE-48CC-448B-95DF-77109C2D4B49}" src="https://github.com/user-attachments/assets/fa3c18f4-a155-49e5-81aa-2e91044deab9" />

