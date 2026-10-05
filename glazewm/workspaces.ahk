#Requires AutoHotkey v2.0
#SingleInstance Force
#NoTrayIcon

configPath := A_ScriptDir "\config.yaml"
statePath := A_ScriptDir "\workspaces.txt"
cliPath := "C:\Program Files\glzr.io\GlazeWM\cli\glazewm.exe"
logPath := A_ScriptDir "\workspaces.log"

OnError(LogError)

background := "18181b"
surface := "3f3f42"
hoverColor := "2a2a2e"
textColor := "e5e7eb"
mutedColor := "6b6b70"
barHeight := 40
gap := 8

focused := ""
populated := Map()
try {
    lines := StrSplit(FileRead(statePath, "UTF-8"), "`n", "`r")
    focused := lines[1]
    for line in lines
        if (A_Index > 1 && line != "")
            populated[line] := true
}

workspaces := []
section := ""
pending := ""
loop read configPath {
    if RegExMatch(A_LoopReadLine, "^(\w+):", &m) {
        section := m[1]
        continue
    }
    if (section != "workspaces")
        continue
    if RegExMatch(A_LoopReadLine, "^\s*-\s*name:\s*'([^']+)'", &m)
        pending := m[1]
    else if (pending != "" && RegExMatch(A_LoopReadLine, "^\s*display_name:\s*'([^']+)'", &m)) {
        workspaces.Push({ name: pending, label: m[1] })
        pending := ""
    }
}
if (workspaces.Length = 0)
    ExitApp

menuGui := Gui("-Caption +AlwaysOnTop +ToolWindow")
menuGui.BackColor := background
menuGui.MarginX := 6
menuGui.MarginY := 6
menuGui.SetFont("s10 w600", "Segoe UI Variable Text")

bases := Map()
for ws in workspaces {
    isFocused := ws.name = focused
    base := isFocused ? surface : background
    color := (isFocused || populated.Has(ws.name)) ? textColor : mutedColor
    item := menuGui.AddText("w150 h30 0x200 c" color " Background" base (A_Index > 1 ? " y+2" : ""), "    " ws.label)
    item.OnEvent("Click", Pick.Bind(ws.name))
    bases[item.Hwnd] := base
}

hovered := 0
menuGui.OnEvent("Escape", (*) => ExitApp())
OnMessage(0x0200, Hover)
OnMessage(0x0006, Deactivate)

scale := A_ScreenDPI / 96
CoordMode("Mouse", "Screen")
MouseGetPos(&mouseX)
menuGui.Show("Hide AutoSize")
menuGui.GetPos(, , &width, &height)
x := Max(Round(gap * scale), Min(mouseX - width // 2, A_ScreenWidth - width - Round(gap * scale)))
y := Round((barHeight + gap) * scale)
DllCall("dwmapi\DwmSetWindowAttribute", "ptr", menuGui.Hwnd, "int", 33, "int*", 2, "int", 4)
DllCall("dwmapi\DwmSetWindowAttribute", "ptr", menuGui.Hwnd, "int", 34, "uint*", 0x423f3f, "int", 4)
menuGui.Show("x" x " y" y)

Hover(wParam, lParam, msg, hwnd) {
    global hovered
    if (hwnd = hovered)
        return
    if (hovered && bases.Has(hovered))
        Paint(hovered, bases[hovered])
    hovered := 0
    if (!bases.Has(hwnd) || bases[hwnd] = surface)
        return
    Paint(hwnd, hoverColor)
    hovered := hwnd
}

Paint(hwnd, color) {
    control := GuiCtrlFromHwnd(hwnd)
    if (!control)
        return
    control.Opt("+Background" color)
    control.Redraw()
}

Deactivate(wParam, lParam, msg, hwnd) {
    if (hwnd = menuGui.Hwnd && (wParam & 0xFFFF) = 0)
        ExitApp
}

Pick(name, *) {
    OnMessage(0x0200, Hover, 0)
    OnMessage(0x0006, Deactivate, 0)
    menuGui.Hide()
    if (name != focused)
        RunWait('"' cliPath '" command focus --workspace ' name, , "Hide")
    ExitApp
}

LogError(exception, mode) {
    FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") " " exception.Message " " exception.What " line " exception.Line "`n", logPath)
    ExitApp
}
