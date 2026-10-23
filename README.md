# Windows ricing
Windows 11 rice: tiling WM, taskbar on top with no Start button, a launcher instead of the Start menu, key remaps, and agent navigation inside WSL.

Verified on Windows 11 25H2, build 26200.

## Showcase
<img width="1920" height="1080" alt="{70289B8C-30DD-4F80-B4C3-0A63F159E72F}" src="https://github.com/user-attachments/assets/660f2302-d004-4a36-95a8-27c790afd217" />
<img width="1920" height="1080" alt="{709A015F-4A30-49CC-A2A1-4F5C72898CC4}" src="https://github.com/user-attachments/assets/3eaa1498-caac-4bf7-9b41-99fdee3fe388" />
<img width="1920" height="1080" alt="{F52221E2-6C81-47CA-B01E-0CF422F4CEEA}" src="https://github.com/user-attachments/assets/26c13d02-ad48-42b9-a53f-275f8e5d3edd" />
<img width="1920" height="1080" alt="{1348BCEE-67D7-4571-9090-7D948CEF8E8E}" src="https://github.com/user-attachments/assets/20cbfba4-55e8-4360-ac05-8b0be04dbcf5" />
<img width="1920" height="1080" alt="{D8751E22-5F0C-46EB-8EF7-99F8DE594522}" src="https://github.com/user-attachments/assets/74f88382-042a-45b5-96ed-96ee3c325346" />
<img width="1920" height="1080" alt="{41DA1090-0E85-45B0-B875-BB713DB2EC1E}" src="https://github.com/user-attachments/assets/1c3dbb30-f8e1-48ff-afea-4999a6fbd4e5" />

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
| — | — | Xbox Game Bar removed to free up Win+G |
| — | — | `DisableLockWorkstation` policy set to free up Win+L |
