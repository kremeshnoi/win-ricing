# 0003. Workspaces stay on `ctrl+shift+<key>` although apps lose those shortcuts

- Status: accepted
- Date: 2026-11-14

## Context

GlazeWM bindings are global, so every `ctrl+shift+<key>` it holds never reaches an app. Zen loses `ctrl+shift+t` (reopen tab), `ctrl+shift+c` (inspector), `ctrl+shift+h`, `ctrl+shift+y`, `ctrl+shift+b`, `ctrl+shift+n`, `ctrl+shift+m`, `ctrl+shift+s`. The Mac has the same trade on `cmd+shift`. No other modifier is free: `ctrl+alt` holds the window bindings, `lwin` belongs to herdr.

## Decision

Workspaces stay on `ctrl+shift+<key>`, the same physical keys as `cmd+shift+<key>` on the Mac. App shortcuts on those keys are given up.

## Consequences

- One muscle memory for workspaces on both systems.
- The lost app shortcuts are reached through menus or the mouse.
- Moving a workspace to another letter is done on both systems at once.
