$ErrorActionPreference = 'SilentlyContinue'
$logPath = 'C:\Users\Alex\.glzr\glazewm\eve.log'
$slotsPath = 'C:\Users\Alex\.glzr\glazewm\eve-slots.txt'
$workspacePath = 'C:\Users\Alex\.glzr\glazewm\workspace.txt'
$workspacesPath = 'C:\Users\Alex\.glzr\glazewm\workspaces.txt'
$endpoint = 'ws://localhost:6123'
$eveWorkspace = '7-eve'
$activeColor = '#e5e7eb'
$idleColor = '#6b6b70'
$timeout = 3000
$heartbeat = 5000

$mutex = New-Object System.Threading.Mutex($false, 'GlazeWmEveSlots')
if (-not $mutex.WaitOne(0)) { exit }

$nextSignal = New-Object System.Threading.EventWaitHandle($false, 'AutoReset', 'GlazeWmEveNext')
$prevSignal = New-Object System.Threading.EventWaitHandle($false, 'AutoReset', 'GlazeWmEvePrev')
$spaceSignal = New-Object System.Threading.EventWaitHandle($false, 'ManualReset', 'GlazeWmEveSpace')

$slots = @{}
$titles = @{}
$active = $null
$workspace = $null
$workspaceLabel = ''
$populated = @()
$initialized = $false
$events = $null
$commands = $null
$receive = $null
$frame = New-Object byte[] 65536
$written = @{}
$settle = $false

function Write-Log($message) {
    $file = Get-Item -Path $logPath -ErrorAction SilentlyContinue
    if ($file -and $file.Length -gt 200KB) { Clear-Content -Path $logPath }
    Add-Content -Path $logPath -Value ((Get-Date).ToString('yyyy-MM-dd HH:mm:ss') + ' ' + $message)
}

function Write-File($path, $content) {
    if ($written.ContainsKey($path) -and $written[$path] -eq $content) { return }
    $encoding = New-Object System.Text.UTF8Encoding($false)
    $temp = $path + '.tmp'
    [IO.File]::WriteAllText($temp, $content, $encoding)
    for ($attempt = 0; $attempt -lt 10; $attempt++) {
        try {
            if (Test-Path -LiteralPath $path) { [IO.File]::Replace($temp, $path, [NullString]::Value) }
            else { [IO.File]::Move($temp, $path) }
            $written[$path] = $content
            return
        }
        catch { Start-Sleep -Milliseconds 20 }
    }
}

function Connect-Wm {
    $client = New-Object System.Net.WebSockets.ClientWebSocket
    $cancel = New-Object System.Threading.CancellationTokenSource
    $cancel.CancelAfter($timeout)
    if (-not $client.ConnectAsync([Uri]$endpoint, $cancel.Token).Wait($timeout)) {
        $client.Dispose()
        return $null
    }
    if ($client.State -ne 'Open') {
        $client.Dispose()
        return $null
    }
    $client
}

function Send-Wm($client, $message) {
    $cancel = New-Object System.Threading.CancellationTokenSource
    $cancel.CancelAfter($timeout)
    $payload = [Text.Encoding]::UTF8.GetBytes($message)
    $outgoing = New-Object ArraySegment[byte] -ArgumentList @(, $payload)
    if (-not $client.SendAsync($outgoing, 'Text', $true, $cancel.Token).Wait($timeout)) { throw 'send timeout' }
}

function Invoke-Wm($client, $message) {
    Send-Wm $client $message

    $cancel = New-Object System.Threading.CancellationTokenSource
    $cancel.CancelAfter($timeout)
    $buffer = New-Object byte[] 131072
    $incoming = New-Object ArraySegment[byte] -ArgumentList @(, $buffer)
    $text = New-Object System.Text.StringBuilder
    do {
        $chunk = $client.ReceiveAsync($incoming, $cancel.Token)
        if (-not $chunk.Wait($timeout)) { throw 'receive timeout' }
        $result = $chunk.Result
        if ($result.MessageType -eq 'Close') { throw 'connection closed' }
        [void]$text.Append([Text.Encoding]::UTF8.GetString($buffer, 0, $result.Count))
    } while (-not $result.EndOfMessage)

    $text.ToString() | ConvertFrom-Json
}

function Start-Receive {
    $segment = New-Object ArraySegment[byte] -ArgumentList @(, $script:frame)
    $script:events.ReceiveAsync($segment, [Threading.CancellationToken]::None)
}

function Get-Windows($container) {
    foreach ($child in $container.children) {
        if ($child.type -eq 'window') { $child }
        else { Get-Windows $child }
    }
}

function Get-EveState {
    $response = Invoke-Wm $script:commands 'query workspaces'
    $workspaces = @($response.data.workspaces)
    $focused = $workspaces | Where-Object { $_.hasFocus } | Select-Object -First 1
    $windows = @(foreach ($workspace in $workspaces) {
        Get-Windows $workspace | Where-Object { $_.processName -eq 'exefile' -and $_.className -eq 'trinityWindow' }
    })
    $area = $workspaces | Where-Object { $_.name -eq $eveWorkspace } | Select-Object -First 1
    $label = if ($focused.displayName) { $focused.displayName } else { $focused.name }
    $names = @($workspaces | ForEach-Object { $_.name })
    [PSCustomObject]@{ Workspace = $focused.name; Label = $label; Names = $names; Area = $area; Windows = $windows }
}

function Float-Window($id, $area) {
    Invoke-Wm $script:commands ('command --id ' + $id + ' set-floating --shown-on-top=false --x-pos=' + $area.x + ' --y-pos=' + $area.y + ' --width=' + $area.width + ' --height=' + $area.height) | Out-Null
}

function Get-OrderedIds {
    @($script:slots.GetEnumerator() | Sort-Object Value | ForEach-Object { $_.Key })
}

function Write-State {
    Write-File $workspacePath $script:workspaceLabel
    Write-File $workspacesPath ((@($script:workspace) + $script:populated) -join "`n")
    $ids = Get-OrderedIds
    if ($ids.Count -eq 0 -or $script:workspace -ne $eveWorkspace) {
        Write-File $slotsPath ''
        return
    }
    $parts = foreach ($id in $ids) {
        $color = if ($id -eq $script:active) { $activeColor } else { $idleColor }
        '<span style="color:' + $color + '">' + $script:slots[$id] + '</span>'
    }
    Write-File $slotsPath ($parts -join '&nbsp;&nbsp;&nbsp;')
}

function Sync {
    $previous = $script:active
    $state = Get-EveState
    if ($state.Workspace -eq $eveWorkspace) { [void]$spaceSignal.Set() } else { [void]$spaceSignal.Reset() }
    $script:workspace = $state.Workspace
    $script:workspaceLabel = $state.Label
    $script:populated = $state.Names
    $windows = $state.Windows
    $ids = @($windows | ForEach-Object { $_.id })

    foreach ($id in @($script:slots.Keys)) {
        if ($ids -notcontains $id) {
            Write-Log ('slot ' + $script:slots[$id] + ' closed: ' + $script:titles[$id])
            if ($id -eq $script:active) { $script:active = $null }
            $script:slots.Remove($id)
            $script:titles.Remove($id)
        }
    }

    $opened = $false
    foreach ($window in $windows) {
        $script:titles[$window.id] = $window.title
        if ($script:slots.ContainsKey($window.id)) { continue }
        $slot = 1
        while ($script:slots.Values -contains $slot) { $slot++ }
        $script:slots[$window.id] = $slot
        Write-Log ('slot ' + $slot + ' opened: ' + $window.title)
        if ($script:initialized) { $script:active = $window.id; $opened = $true }
    }
    $script:initialized = $true

    if ($state.Area) {
        foreach ($window in $windows) {
            if ($window.state.type -in 'tiling', 'minimized') { Float-Window $window.id $state.Area; continue }
            if ($window.state.type -eq 'floating' -and ($window.x -ne $state.Area.x -or $window.y -ne $state.Area.y)) {
                Write-Log ('align ' + $window.title + ' from ' + $window.x + ',' + $window.y)
                Invoke-Wm $script:commands ('command --id ' + $window.id + ' position --x-pos=' + $state.Area.x + ' --y-pos=' + $state.Area.y) | Out-Null
            }
        }
    }

    $focusedEve = $windows | Where-Object { $_.hasFocus } | Select-Object -First 1
    if ($focusedEve -and -not $opened) { $script:active = $focusedEve.id }
    if (-not $script:active -or -not $script:slots.ContainsKey($script:active)) {
        $script:active = Get-OrderedIds | Select-Object -First 1
    }

    if ($script:active -and $script:active -ne $previous) {
        Write-Log ('active slot ' + $script:slots[$script:active] + ' (focused ' + $focusedEve.title + ', workspace ' + $state.Workspace + ')')
    }
    Write-State
}

function Step($direction) {
    $state = Get-EveState
    if ($state.Workspace -ne $eveWorkspace) { return }
    Sync
    $ids = Get-OrderedIds
    if ($ids.Count -lt 2) { return }

    $index = [array]::IndexOf($ids, $script:active)
    if ($index -lt 0) { $index = 0 }
    $target = $ids[($index + $direction + $ids.Count) % $ids.Count]

    Invoke-Wm $script:commands ('command focus --container-id ' + $target) | Out-Null
    $script:active = $target
    Write-State
}

Write-File $slotsPath ''
Write-Log 'daemon started'

while ($true) {
    if (-not $events -or $events.State -ne 'Open' -or -not $commands -or $commands.State -ne 'Open') {
        if ($events) { $events.Dispose() }
        if ($commands) { $commands.Dispose() }
        $events = Connect-Wm
        $commands = Connect-Wm
        if (-not $events -or -not $commands) {
            Write-State
            Start-Sleep -Seconds 2
            continue
        }
        try {
            Send-Wm $events 'sub --events focus_changed window_managed window_unmanaged workspace_activated'
            $receive = Start-Receive
            Write-Log 'connected to glazewm'
            Sync
        }
        catch {
            Write-Log ('connect error: ' + $_.Exception.Message)
            $events.Dispose()
            $events = $null
            Start-Sleep -Seconds 2
            continue
        }
    }

    $handles = [Threading.WaitHandle[]]@(([IAsyncResult]$receive).AsyncWaitHandle, $nextSignal, $prevSignal)
    $wait = if ($settle) { 250 } else { $heartbeat }
    $settle = $false
    $index = [Threading.WaitHandle]::WaitAny($handles, $wait)

    try {
        switch ($index) {
            0 {
                $result = $receive.Result
                if ($result.MessageType -eq 'Close') { throw 'connection closed' }
                $receive = Start-Receive
                if ($result.EndOfMessage) { Sync; $settle = $true }
            }
            1 { Step 1 }
            2 { Step -1 }
            default { Sync }
        }
    }
    catch {
        Write-Log ('ipc error: ' + $_.Exception.Message)
        if ($events) { $events.Dispose() }
        $events = $null
        Start-Sleep -Seconds 2
    }
}
