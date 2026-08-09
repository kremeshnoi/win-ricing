$ErrorActionPreference = 'Continue'

Add-Type -ErrorAction SilentlyContinue -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class RicingElev {
  [DllImport("advapi32.dll", SetLastError=true)]
  static extern bool OpenProcessToken(IntPtr h, uint acc, out IntPtr tok);
  [DllImport("advapi32.dll", SetLastError=true)]
  static extern bool GetTokenInformation(IntPtr tok, int cls, out uint info, uint len, out uint ret);
  public static string Of(IntPtr h) {
    IntPtr tok; uint elevation; uint ret;
    if (!OpenProcessToken(h, 0x0008, out tok)) return "denied";
    if (!GetTokenInformation(tok, 20, out elevation, 4, out ret)) return "unknown";
    return elevation != 0 ? "elevated" : "normal";
  }
}
"@

function Get-Elevation {
    param([string]$Name, [string]$ExcludePathLike)
    $procs = Get-Process -Name $Name -ErrorAction SilentlyContinue
    if ($ExcludePathLike) {
        $procs = $procs | Where-Object { $_.Path -notlike $ExcludePathLike }
    }
    if (-not $procs) { return 'not running' }
    ($procs | ForEach-Object {
        try { [RicingElev]::Of($_.Handle) } catch { 'elevated' }
    } | Sort-Object -Unique) -join ','
}

$rows = @()

$ahk   = Get-Elevation 'AutoHotkey64'
$glaze = Get-Elevation 'glazewm' -ExcludePathLike '*\cli\glazewm.exe'
$yasb  = Get-Elevation 'yasb'

$rows += [PSCustomObject]@{ Check = 'AutoHotkey'; Value = $ahk;   Ok = ($ahk -eq 'elevated') }
$rows += [PSCustomObject]@{ Check = 'GlazeWM';    Value = $glaze; Ok = ($glaze -eq 'normal') }
$rows += [PSCustomObject]@{ Check = 'YASB';       Value = $yasb;  Ok = ($yasb -ne 'not running') }

$task = Get-ScheduledTask -TaskPath '\win-ricing\' -TaskName 'autohotkey' -ErrorAction SilentlyContinue
$info = if ($task) { Get-ScheduledTaskInfo -TaskPath '\win-ricing\' -TaskName 'autohotkey' } else { $null }
$val  = if ($task) { "$($task.State), $($task.Principal.RunLevel), rc=0x{0:X}" -f $info.LastTaskResult } else { 'missing' }
$rows += [PSCustomObject]@{ Check = 'task autohotkey'; Value = $val; Ok = ($task -and $task.Principal.RunLevel -eq 'Highest' -and $info.LastTaskResult -in 0, 0x41301) }

$run = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -ErrorAction SilentlyContinue).GlazeWM
$rows += [PSCustomObject]@{ Check = 'Run\GlazeWM'; Value = $(if ($run) { 'present' } else { 'absent' }); Ok = [bool]$run }

$lnk = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\no-start-menu.lnk"
$rows += [PSCustomObject]@{ Check = 'old Startup shortcut'; Value = $(if (Test-Path -LiteralPath $lnk) { 'present' } else { 'absent' }); Ok = (-not (Test-Path -LiteralPath $lnk)) }

$lock = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System' -ErrorAction SilentlyContinue).DisableLockWorkstation
$rows += [PSCustomObject]@{ Check = 'DisableLockWorkstation'; Value = "$lock"; Ok = ($lock -eq 1) }

$ahkFile = "$env:USERPROFILE\.glzr\glazewm\no-start-menu.ahk"
$rows += [PSCustomObject]@{ Check = 'no-start-menu.ahk'; Value = $(if (Test-Path -LiteralPath $ahkFile) { 'deployed' } else { 'missing' }); Ok = (Test-Path -LiteralPath $ahkFile) }

$navOut = & wsl.exe -e /home/kremeshnoi/.local/bin/herdr-nav 2>&1
$navOk  = "$navOut" -match 'usage: herdr-nav'
$rows += [PSCustomObject]@{ Check = 'herdr-nav via wsl'; Value = $(if ($navOk) { 'reachable' } else { "$navOut" }); Ok = $navOk }

$sock = & wsl.exe -e test -S /home/kremeshnoi/.config/herdr/herdr.sock
$sockOk = ($LASTEXITCODE -eq 0)
$rows += [PSCustomObject]@{ Check = 'herdr.sock'; Value = $(if ($sockOk) { 'present' } else { 'absent (herdr not running)' }); Ok = $sockOk }

$rows | Format-Table Check, Value, @{ L = ''; E = { if ($_.Ok) { 'ok' } else { 'FAIL' } } } -AutoSize

if ($rows | Where-Object { -not $_.Ok }) { exit 1 }
