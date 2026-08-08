#Requires AutoHotkey v2.0
#SingleInstance Force
#NoTrayIcon

~LWin::Send "{Blind}{vkE8}"
~RWin::Send "{Blind}{vkE8}"

#HotIf WinActive("ahk_exe WindowsTerminal.exe")
<#h::HerdrNav("tab prev")
<#l::HerdrNav("tab next")
<#k::HerdrNav("agent prev")
<#j::HerdrNav("agent next")
<#+k::HerdrNav("workspace prev")
<#+j::HerdrNav("workspace next")
#HotIf

HerdrNav(cmd) {
    SetTimer(() => Run('wsl.exe -e /home/kremeshnoi/.local/bin/herdr-nav ' cmd, , "Hide"), -1)
}
