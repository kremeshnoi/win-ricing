# 0002. Only an app's main window pulls focus to its workspace

- Status: accepted
- Date: 2026-11-14

## Context

Each app rule did `move --workspace X` and `focus --workspace X` for any window of the process. Opening an app and landing on its workspace is wanted, but a Telegram notification, the Discord updater or a dialog pulled focus the same way.

## Decision

Each app has two rules on `manage`:

- `move --workspace X` for every window of the process;
- `focus --workspace X` only when the window class is the main window's: `MozillaWindowClass` for Zen, `^Qt\d+QWindowIcon$` for Telegram, `Chrome_WidgetWin_1` for the Electron apps, `CASCADIA_HOSTING_WINDOW_CLASS` or `Optimum.Window.*` for terminals. Discord also excludes titles matching `updater`.

EVE switches only on its game window, `trinityWindow`. System windows and Docker switch on any window except a standard dialog (`#32770`). The catch-all `14-misc` never switches: a game client opening in the background pulled focus there. Their process matchers are YAML anchors, so the `focus` rule reuses the `move` rule's list.

## Consequences

- A popup lands on its app's workspace without moving you.
- An app update can change its window class; then opening it no longer switches. Check with `glazewm query windows`.
- Spotify and the Electron apps share the class of their popups, so a popup of theirs can still switch.
- An app without its own rule lands on `14-misc` and you stay where you are.
