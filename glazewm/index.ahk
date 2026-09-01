#Requires AutoHotkey v2.0
#SingleInstance Force
#NoTrayIcon

SetTimer SquareLeagueCorners, 400

~LWin::Send "{Blind}{vkE8}"
~RWin::Send "{Blind}{vkE8}"

$!Space:: {
    Send "{LAlt up}{RAlt up}"
    SwitchLayout()
}

SwitchLayout() {
    hwnd := DllCall("GetForegroundWindow", "ptr")
    next := hwnd ? NextLayout(hwnd) : 0
    if (!next) {
        Send "#{Space}"
        return
    }

    DllCall("PostMessageW", "ptr", FocusedControl(hwnd), "uint", 0x0050, "ptr", 0, "ptr", next)

    loop 10 {
        Sleep 25
        if (CurrentLayout(hwnd) = next)
            return
    }
    Send "#{Space}"
}

FocusedControl(hwnd) {
    size := A_PtrSize = 8 ? 72 : 48
    info := Buffer(size, 0)
    NumPut("uint", size, info, 0)
    tid := DllCall("GetWindowThreadProcessId", "ptr", hwnd, "ptr", 0, "uint")
    if (DllCall("GetGUIThreadInfo", "uint", tid, "ptr", info)) {
        focus := NumGet(info, A_PtrSize = 8 ? 16 : 12, "ptr")
        if (focus)
            return focus
    }
    return hwnd
}

CurrentLayout(hwnd) {
    tid := DllCall("GetWindowThreadProcessId", "ptr", hwnd, "ptr", 0, "uint")
    return DllCall("GetKeyboardLayout", "uint", tid, "ptr")
}

NextLayout(hwnd) {
    count := DllCall("GetKeyboardLayoutList", "int", 0, "ptr", 0, "int")
    if (count < 2)
        return 0

    list := Buffer(count * A_PtrSize, 0)
    DllCall("GetKeyboardLayoutList", "int", count, "ptr", list)

    current := CurrentLayout(hwnd)
    index := 0
    loop count {
        if (NumGet(list, (A_Index - 1) * A_PtrSize, "ptr") = current) {
            index := A_Index
            break
        }
    }
    return NumGet(list, Mod(index, count) * A_PtrSize, "ptr")
}

~*LAlt::MaskAlt(true)
~*RAlt::MaskAlt(true)
~*LAlt up::MaskAlt(false)
~*RAlt up::MaskAlt(false)

MaskAlt(down) {
    static masked := false
    if (!down) {
        masked := false
        return
    }
    if (masked)
        return
    masked := true
    Send "{Blind}{F13}"
}

#HotIf GetKeyState("Shift", "P")
LCtrl & Tab::ShiftAltTab
#HotIf

LCtrl & Tab::AltTab

#HotIf WinActive("ahk_exe WindowsTerminal.exe")
<#h::HerdrNav("tab prev")
<#l::HerdrNav("tab next")
<#k::HerdrNav("workspace prev")
<#j::HerdrNav("workspace next")
<#+k::HerdrNav("agent prev")
<#+j::HerdrNav("agent next")
#HotIf

HerdrNav(cmd) {
    SetTimer(() => Run('wsl.exe -e /home/kremeshnoi/.local/bin/herdr-nav ' cmd, , "Hide"), -1)
}

SquareLeagueCorners() {
    DetectHiddenWindows true
    for hwnd in WinGetList("ahk_exe League of Legends.exe")
        SetSquareCorners(hwnd)
}

SetSquareCorners(hwnd) {
    current := 0
    if (DllCall("dwmapi\DwmGetWindowAttribute", "ptr", hwnd, "int", 33, "int*", &current, "int", 4) != 0)
        return
    if (current = 1)
        return
    DllCall("dwmapi\DwmSetWindowAttribute", "ptr", hwnd, "int", 33, "int*", 1, "int", 4)
}
