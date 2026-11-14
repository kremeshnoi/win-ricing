# 0004. Modifiers behave like on the Mac

- Status: accepted
- Date: 2026-11-14

## Context

The same hands work on a Mac and on Windows. On the Mac `cmd` sits next to the space bar and does copy, paste and the app switcher.

## Decision

- Ctrl and Alt are swapped in the Wooting firmware: next to space is `ctrl`, the corner is `alt`.
- `index.ahk` maps left `ctrl+tab` to the Windows window switcher, like `cmd+tab`.
- In Zen `index.ahk` sends `alt+tab` and `alt+shift+tab` as `ctrl+tab` and `ctrl+shift+tab`, so tabs still switch.
- No global binding takes a shortcut apps rely on: `ctrl+enter` stays with the apps and has no GlazeWM binding.

## Consequences

- Apps never see left `ctrl+tab`; Zen gets it from `alt+tab` instead.
- Outside Zen both `ctrl+tab` and `alt+tab` switch windows.
- Without the firmware swap every binding lands on the wrong physical key.
- The terminal has no global shortcut on Windows.
