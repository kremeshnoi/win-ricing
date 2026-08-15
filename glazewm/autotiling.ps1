$ErrorActionPreference = 'SilentlyContinue'
$glazewm = 'C:\Program Files\glzr.io\GlazeWM\cli\glazewm.exe'

$mutex = New-Object System.Threading.Mutex($false, 'GlazeWmAutotiling')
if (-not $mutex.WaitOne(0)) { exit }

function Get-FocusedContainer {
    $raw = & $glazewm query focused 2>$null
    if (-not $raw) { return $null }
    try { return ($raw | ConvertFrom-Json).data.focused } catch { return $null }
}

function Test-ActiveDrag {
    $raw = & $glazewm query windows 2>$null
    if (-not $raw) { return $true }
    try { $windows = ($raw | ConvertFrom-Json).data.windows } catch { return $true }
    foreach ($window in $windows) {
        if ($null -ne $window.activeDrag) { return $true }
    }
    return $false
}

function Sync-TilingDirection {
    $focused = Get-FocusedContainer
    if (-not $focused) { return }
    if ($focused.type -ne 'window') { return }
    if ($focused.state.type -ne 'tiling') { return }
    if ($focused.width -le 0 -or $focused.height -le 0) { return }
    if ($null -ne $focused.activeDrag) { return }
    if (Test-ActiveDrag) { return }

    $direction = if ($focused.width -gt $focused.height) { 'horizontal' } else { 'vertical' }
    & $glazewm command set-tiling-direction $direction 2>$null | Out-Null
}

while ($true) {
    & $glazewm sub -e focus_changed window_managed window_unmanaged workspace_activated 2>$null |
        ForEach-Object { Sync-TilingDirection }
    Start-Sleep -Seconds 2
}
