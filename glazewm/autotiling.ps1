$ErrorActionPreference = 'SilentlyContinue'
$glazewm = 'C:\Program Files\glzr.io\GlazeWM\cli\glazewm.exe'

$mutex = New-Object System.Threading.Mutex($false, 'GlazeWmAutotiling')
if (-not $mutex.WaitOne(0)) { exit }

function Get-FocusedContainer {
    $raw = & $glazewm query focused 2>$null
    if (-not $raw) { return $null }
    try { return ($raw | ConvertFrom-Json).data.focused } catch { return $null }
}

function Sync-TilingDirection {
    $focused = Get-FocusedContainer
    if (-not $focused) { return }
    if ($focused.type -ne 'window') { return }
    if ($focused.state.type -ne 'tiling') { return }
    if ($focused.width -le 0 -or $focused.height -le 0) { return }

    $direction = if ($focused.width -gt $focused.height) { 'horizontal' } else { 'vertical' }
    & $glazewm command set-tiling-direction $direction 2>$null | Out-Null
}

while ($true) {
    & $glazewm sub -e focus_changed window_managed window_unmanaged focused_container_moved workspace_activated 2>$null |
        ForEach-Object { Sync-TilingDirection }
    Start-Sleep -Seconds 2
}
