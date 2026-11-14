# Architecture decision records

One file per decision: what was decided, why, and what it costs. An accepted record is not edited; a later one supersedes it and links back.

| # | Decision | Status |
|---|---|---|
| [0001](0001-glazewm-defaults-over-helper-daemons.md) | GlazeWM's defaults come before helper daemons | accepted |
| [0002](0002-focus-only-main-windows.md) | Only an app's main window pulls focus to its workspace | accepted |
| [0003](0003-workspaces-on-ctrl-shift.md) | Workspaces stay on `ctrl+shift+<key>` although apps lose those shortcuts | accepted |
| [0004](0004-mac-like-modifiers.md) | Modifiers behave like on the Mac | accepted |

## Template

```markdown
# NNNN. Title

- Status: proposed | accepted | superseded by NNNN
- Date: YYYY-MM-DD

## Context

## Decision

## Consequences
```
