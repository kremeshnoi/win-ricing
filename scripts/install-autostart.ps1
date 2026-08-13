#Requires -RunAsAdministrator
$ErrorActionPreference = 'Stop'

$User     = "$env:USERDOMAIN\$env:USERNAME"
$AhkExe   = 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe'
$AhkArg   = "$env:USERPROFILE\.glzr\glazewm\index.ahk"
$GlazeExe = 'C:\Program Files\glzr.io\GlazeWM\glazewm.exe'
$TileVbs  = "$env:USERPROFILE\.glzr\glazewm\autotiling.vbs"
$TaskPath = '\win-ricing\'
$RunKey   = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'

foreach ($p in $AhkExe, $AhkArg, $GlazeExe, $TileVbs) {
    if (-not (Test-Path -LiteralPath $p)) { throw "not found: $p" }
}

$trigger   = New-ScheduledTaskTrigger -AtLogOn -User $User
$principal = New-ScheduledTaskPrincipal -UserId $User -LogonType Interactive -RunLevel Highest
$settings  = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -ExecutionTimeLimit ([TimeSpan]::Zero) `
    -MultipleInstances IgnoreNew `
    -StartWhenAvailable `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 1)

function Register-RicingTask {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Execute,
        [string]$Argument
    )
    $action = if ($Argument) {
        New-ScheduledTaskAction -Execute $Execute -Argument $Argument
    } else {
        New-ScheduledTaskAction -Execute $Execute
    }
    Unregister-ScheduledTask -TaskPath $TaskPath -TaskName $Name -Confirm:$false -ErrorAction SilentlyContinue
    Register-ScheduledTask -TaskPath $TaskPath -TaskName $Name `
        -Action $action -Trigger $trigger -Principal $principal -Settings $settings | Out-Null
    Write-Host "task registered: $TaskPath$Name (RunLevel=Highest)"
}

Register-RicingTask -Name 'autohotkey' -Execute $AhkExe -Argument $AhkArg

foreach ($stale in 'glazewm', 'games-watcher') {
    Unregister-ScheduledTask -TaskPath $TaskPath -TaskName $stale -Confirm:$false -ErrorAction SilentlyContinue
}

$lnk = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\no-start-menu.lnk"
if (Test-Path -LiteralPath $lnk) {
    Remove-Item -LiteralPath $lnk -Force
    Write-Host "removed startup shortcut: $lnk"
}

Set-ItemProperty -Path $RunKey -Name 'GlazeWM' -Value $GlazeExe -Type String
Write-Host "Run\GlazeWM = $GlazeExe"

$tileCmd = "wscript.exe `"$TileVbs`""
Set-ItemProperty -Path $RunKey -Name 'GlazeWM Autotiling' -Value $tileCmd -Type String
Write-Host "Run\GlazeWM Autotiling = $tileCmd"

$policy = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System'
if (-not (Test-Path -LiteralPath $policy)) { New-Item -Path $policy -Force | Out-Null }
Set-ItemProperty -Path $policy -Name 'DisableLockWorkstation' -Value 1 -Type DWord
Write-Host "DisableLockWorkstation = 1"

Get-Process -Name 'AutoHotkey64' -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 1
Start-ScheduledTask -TaskPath $TaskPath -TaskName 'autohotkey'

$wm = Get-Process -Name 'glazewm' -ErrorAction SilentlyContinue | Where-Object { $_.Path -notlike '*\cli\glazewm.exe' }
if (-not $wm) {
    Start-Process -FilePath 'explorer.exe' -ArgumentList $GlazeExe
}
Start-Sleep -Seconds 4

Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
    Where-Object { $_.CommandLine -like '*autotiling.ps1*' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Start-Process -FilePath 'explorer.exe' -ArgumentList $TileVbs
Start-Sleep -Seconds 2

Write-Host ''
& "$PSScriptRoot\doctor.ps1"
