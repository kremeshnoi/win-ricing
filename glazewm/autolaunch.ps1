$ErrorActionPreference = 'SilentlyContinue'
$logPath = 'C:\Users\Alex\.glzr\glazewm\autolaunch.log'
$endpoint = 'ws://localhost:6123'

$mutex = New-Object System.Threading.Mutex($false, 'GlazeWmWorkspaceAutolaunch')
if (-not $mutex.WaitOne(0)) { exit }

$launchers = @{
    '2-chrome'   = @('C:\Program Files\Google\Chrome\Application\chrome.exe')
    '3-terminal' = @('wt.exe')
    '4-spotify'  = @('C:\Users\Alex\AppData\Roaming\Spotify\Spotify.exe')
    '5-discord'  = @('C:\Users\Alex\AppData\Local\Discord\Update.exe', '--processStart', 'Discord.exe')
    '6-telegram' = @('C:\Users\Alex\AppData\Roaming\Telegram Desktop\Telegram.exe')
    '7-claude'   = @('explorer.exe', 'shell:AppsFolder\Claude_pzs8sxrjxfjjc!Claude')
    '8-obsidian' = @('C:\Users\Alex\AppData\Local\Obsidian\Obsidian.exe')
}

$pollInterval = 500
$timeout = 3000
$startupGrace = [timespan]::FromSeconds(20)
$restartCooldown = [timespan]::FromSeconds(60)
$wmExecutable = 'C:\Program Files\glzr.io\GlazeWM\glazewm.exe'
$pendingLaunch = @{}
$socket = $null
$lastRestart = [datetime]::MinValue

function Write-Log($message) {
    $file = Get-Item -Path $logPath -ErrorAction SilentlyContinue
    if ($file -and $file.Length -gt 200KB) { Clear-Content -Path $logPath }
    Add-Content -Path $logPath -Value ((Get-Date).ToString('yyyy-MM-dd HH:mm:ss') + ' ' + $message)
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

function Invoke-Wm($client, $message) {
    $cancel = New-Object System.Threading.CancellationTokenSource
    $cancel.CancelAfter($timeout)

    $payload = [Text.Encoding]::UTF8.GetBytes($message)
    $outgoing = New-Object ArraySegment[byte] -ArgumentList @(, $payload)
    if (-not $client.SendAsync($outgoing, 'Text', $true, $cancel.Token).Wait($timeout)) { throw 'send timeout' }

    $buffer = New-Object byte[] 131072
    $incoming = New-Object ArraySegment[byte] -ArgumentList @(, $buffer)
    $text = New-Object System.Text.StringBuilder
    do {
        $receive = $client.ReceiveAsync($incoming, $cancel.Token)
        if (-not $receive.Wait($timeout)) { throw 'receive timeout' }
        $frame = $receive.Result
        if ($frame.MessageType -eq 'Close') { throw 'connection closed' }
        [void]$text.Append([Text.Encoding]::UTF8.GetString($buffer, 0, $frame.Count))
    } while (-not $frame.EndOfMessage)

    $text.ToString() | ConvertFrom-Json
}

function Test-WmRunning {
    $processes = Get-CimInstance Win32_Process -Filter "Name='glazewm.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -notlike '*\cli\*' }
    [bool]$processes
}

function Test-RecentCrash {
    $since = (Get-Date).AddMinutes(-2)
    $events = Get-WinEvent -FilterHashtable @{ LogName = 'Application'; Id = 1000; StartTime = $since } -ErrorAction SilentlyContinue |
        Where-Object { $_.Message -like '*glazewm*' }
    [bool]$events
}

function Restore-Wm {
    if (Test-WmRunning) { return $false }
    if (-not (Test-RecentCrash)) { return $false }

    $now = [datetime]::UtcNow
    if (($now - $script:lastRestart) -lt $restartCooldown) { return $false }
    $script:lastRestart = $now

    Write-Log 'glazewm crashed and is gone, restarting it'
    Start-Process -FilePath $wmExecutable
    Start-Sleep -Seconds 4
    $true
}

function Get-Windows($container) {
    foreach ($child in $container.children) {
        if ($child.type -eq 'window') { $child }
        else { Get-Windows $child }
    }
}

Write-Log 'daemon started'

while ($true) {
    Start-Sleep -Milliseconds $pollInterval

    if (-not $socket -or $socket.State -ne 'Open') {
        if ($socket) { $socket.Dispose() }
        $socket = Connect-Wm
        if (-not $socket) {
            Restore-Wm | Out-Null
            Start-Sleep -Seconds 2
            continue
        }
        Write-Log 'connected to glazewm'
    }

    try {
        $response = Invoke-Wm $socket 'query workspaces'
        $workspace = $response.data.workspaces | Where-Object { $_.hasFocus } | Select-Object -First 1
        if (-not $workspace) { continue }

        $name = $workspace.name
        $command = $launchers[$name]
        if (-not $command) { continue }

        $windows = @(Get-Windows $workspace)
        $visible = @($windows | Where-Object { $_.state.type -ne 'minimized' })

        if ($visible.Count -gt 0) {
            $pendingLaunch.Remove($name)
            continue
        }

        if ($windows.Count -gt 0) {
            Write-Log ('restoring minimized window on ' + $name)
            foreach ($window in $windows) {
                Invoke-Wm $socket ('command --id ' + $window.id + ' set-tiling') | Out-Null
            }
            Invoke-Wm $socket ('command focus --container-id ' + $windows[0].id) | Out-Null
            continue
        }

        $now = [datetime]::UtcNow
        if ($pendingLaunch.ContainsKey($name) -and (($now - $pendingLaunch[$name]) -lt $startupGrace)) { continue }
        $pendingLaunch[$name] = $now

        Write-Log ('launching ' + ($command -join ' ') + ' for ' + $name)
        if ($command.Count -gt 1) {
            Start-Process -FilePath $command[0] -ArgumentList $command[1..($command.Count - 1)]
        }
        else {
            Start-Process -FilePath $command[0]
        }
    }
    catch {
        Write-Log ('ipc error: ' + $_.Exception.Message)
        if ($socket) { $socket.Dispose() }
        $socket = $null
        Start-Sleep -Seconds 2
    }
}
