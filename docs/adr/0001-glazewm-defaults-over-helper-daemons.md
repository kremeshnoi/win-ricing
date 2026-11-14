# 0001. GlazeWM's defaults come before helper daemons

- Status: accepted
- Date: 2026-11-14

## Context

Three PowerShell daemons talked to GlazeWM next to its own rules:

- `autolaunch.ps1` polled every 500 ms, started an app when its workspace was empty, restored minimized windows and restarted GlazeWM after a crash. A closed app came back at once, a window could not stay minimized.
- `autotiling.ps1` set the tiling direction from the focused window's shape on every focus change, so `ctrl+alt+v` lasted until the next focus change.
- `eve.ps1` keeps EVE clients in slots.

Their commands raced each other and the rules: `errors.log` filled with `Window has no workspace` and `No common ancestor between containers`.

## Decision

- What GlazeWM does by itself is not redone by a script.
- `autolaunch.ps1` and `autotiling.ps1` are removed, with their `Run` keys and `doctor.ps1` checks. `install-autostart.ps1` deletes the stale `Run` keys.
- A script stays only for what GlazeWM cannot do: `eve.ps1`, `kill-workspace.ps1`, `workspaces.ahk`, `index.ahk`.

## Consequences

- A closed window stays closed; an app on an empty workspace is started by hand.
- New windows follow the workspace's direction; `ctrl+alt+v` flips it until flipped back.
- Nothing restarts GlazeWM after a crash.
