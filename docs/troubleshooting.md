# Troubleshooting

## Zen opens a link in a new window

| Where the link comes from | Cause | Fix in `about:config` |
|---|---|---|
| a page inside Zen | `browser.link.open_newwindow` is `2` | reset it to `3` |
| another app, Telegram for example | GlazeWM hides other workspaces with `hide_method: 'cloak'`; Zen skips cloaked windows when it picks one for an external link, finds none and opens a new one | `widget.prefer_windows_on_current_virtual_desktop` = `false` |

The first pref is synced through Firefox Sync, so another device can bring `2` back.

## A closed app opens again by itself

It was `autolaunch.ps1`, removed. If it happens again, check `doctor.ps1` and the `Run` key for `GlazeWM Autolaunch`.

## `ctrl+alt+v` does nothing

With one window on the workspace nothing moves: the direction only decides where the next window goes. Open a second window to see it.

## The default browser looks like Chrome in the registry

`UrlAssociations\https\UserChoice` may still say `ChromeHTML`. Windows 11 reads `UserChoiceLatest\ProgId`, check that one.

## `errors.log` fills with `Window has no workspace`

Several scripts sent commands to GlazeWM at the same time. Fewer daemons, fewer of these; see [ADR 0001](adr/0001-glazewm-defaults-over-helper-daemons.md).
