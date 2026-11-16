# 0005. Zen windows live in slots like EVE clients

- Status: accepted
- Date: 2026-11-16

## Context

EVE clients on `12-eve` float at the full size of the workspace, one on top, the others in numbered slots shown in YASB and switched with `left` and `right`, which on `4-browser` would take the arrows from text fields and pages. Zen windows on `4-browser` tiled side by side and got narrow.

## Decision

`zen.ps1` is a copy of `eve.ps1` for Zen main windows (`zen`, `MozillaWindowClass`) on `4-browser`, with its own events, slots file and logon entry `Run\GlazeWM Zen`. `eve.ps1` is untouched and still the only writer of `workspace.txt` and `workspaces.txt`. `index.ahk` sends `ctrl+left` and `ctrl+right` to whichever daemon owns the focused workspace; EVE moved from bare arrows to the same keys, so both work alike.

## Consequences

- Every Zen window covers the whole workspace; tiling one is undone at the next sync. `zen.ps1` fixes the size as well as the position, because a new Zen window arrives tiled at half width.
- On `4-browser` and `12-eve` `ctrl+left` and `ctrl+right` never reach the app: no word jumps in Zen text fields.
- Zen dialogs and popups are not slots; they keep GlazeWM's defaults.
- A fix to the slot logic goes into both scripts.
