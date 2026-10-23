param([string]$Target)

$ErrorActionPreference = 'SilentlyContinue'
$glazewm = 'C:\Program Files\glzr.io\GlazeWM\cli\glazewm.exe'
$logPath = 'C:\Users\Alex\.glzr\glazewm\kill-workspace.log'
$fallback = '1-desktop'
$untouchable = 'explorer', 'glazewm', 'glazewm-watcher', 'yasb', 'autohotkey64', 'dwm', 'csrss', 'winlogon', 'svchost', 'sihost', 'ctfmon', 'runtimebroker', 'applicationframehost'
$bases = @("$env:ProgramFiles\WindowsApps", $env:ProgramFiles, ${env:ProgramFiles(x86)}, "$env:LOCALAPPDATA\Programs", $env:LOCALAPPDATA, $env:APPDATA)
$protected = 'explorer', 'glazewm', 'glazewm-watcher', 'yasb', 'autohotkey64', 'wscript', 'powershell', 'pwsh', 'conhost', 'dwm', 'svchost', 'runtimebroker', 'applicationframehost', 'csrss', 'winlogon', 'sihost', 'ctfmon'

$mutex = New-Object System.Threading.Mutex($false, 'GlazeWmKillWorkspace')
if (-not $mutex.WaitOne(0)) { exit }

Add-Type -Namespace Native -Name User32 -MemberDefinition @'
[DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
[DllImport("user32.dll")] public static extern bool IsWindow(IntPtr hWnd);
'@

function Write-Log($message) {
    $file = Get-Item -Path $logPath
    if ($file -and $file.Length -gt 200KB) { Clear-Content -Path $logPath }
    Add-Content -Path $logPath -Value ((Get-Date).ToString('yyyy-MM-dd HH:mm:ss') + ' ' + $message)
}

function Get-Windows($container) {
    foreach ($child in $container.children) {
        if ($child.type -eq 'window') { $child }
        else { Get-Windows $child }
    }
}

function Get-Workspace($name) {
    $all = ((& $glazewm query workspaces) | ConvertFrom-Json).data.workspaces
    if ($name) { $all | Where-Object { $_.name -eq $name } | Select-Object -First 1 }
    else { $all | Where-Object { $_.hasFocus } | Select-Object -First 1 }
}

function Get-Processes {
    $table = @{}
    Get-CimInstance Win32_Process | ForEach-Object { $table[[int]$_.ProcessId] = $_ }
    $table
}

function Get-BaseName($name) { [IO.Path]::GetFileNameWithoutExtension($name).ToLower() }

function Test-Within($path, $root) {
    $root = $root.TrimEnd('\') + '\'
    ($path.TrimEnd('\') + '\').StartsWith($root, [StringComparison]::OrdinalIgnoreCase)
}

function Test-Protected($process) { $protected -contains (Get-BaseName $process.Name) }

function Get-WindowPid($window) {
    [uint32]$id = 0
    [void][Native.User32]::GetWindowThreadProcessId([IntPtr][long]$window.handle, [ref]$id)
    [int]$id
}

function Get-AppRoot($path) {
    if (-not $path -or (Test-Within $path $env:windir)) { return $null }
    $best = $null
    foreach ($base in $bases) {
        if ($base -and (Test-Within $path $base) -and (-not $best -or $base.Length -gt $best.Length)) { $best = $base }
    }
    if ($best) {
        $rest = $path.Substring($best.TrimEnd('\').Length).TrimStart('\')
        if ($rest.Contains('\')) { return (Join-Path $best $rest.Split('\')[0]) }
    }
    Split-Path $path
}

function Get-Descendants($ids, $processes) {
    $children = @{}
    foreach ($process in $processes.Values) {
        $parent = [int]$process.ParentProcessId
        if (-not $children.ContainsKey($parent)) { $children[$parent] = New-Object System.Collections.ArrayList }
        [void]$children[$parent].Add([int]$process.ProcessId)
    }
    $result = @{}
    $queue = New-Object System.Collections.Queue
    foreach ($id in $ids) { $queue.Enqueue([int]$id) }
    while ($queue.Count -gt 0) {
        $id = $queue.Dequeue()
        if ($result.ContainsKey($id)) { continue }
        $result[$id] = $true
        if ($children.ContainsKey($id)) { foreach ($child in $children[$id]) { $queue.Enqueue($child) } }
    }
    $result
}

function Get-ForeignPids($name, $processes) {
    $ids = foreach ($other in ((& $glazewm query workspaces) | ConvertFrom-Json).data.workspaces) {
        if ($other.name -eq $name) { continue }
        foreach ($window in @(Get-Windows $other)) { Get-WindowPid $window }
    }
    Get-Descendants @($ids) $processes
}

function Resolve-Targets($windows, $processes, $foreign) {
    $seeds = @{}
    $close = @()
    foreach ($window in $windows) {
        $process = $processes[(Get-WindowPid $window)]
        $owners = @()
        if ($process -and -not (Test-Protected $process)) { $owners = @($process) }
        elseif ($window.processName) {
            $wanted = $window.processName.ToLower()
            $owners = @($processes.Values | Where-Object { (Get-BaseName $_.Name) -eq $wanted -and -not (Test-Protected $_) })
        }
        if ($owners.Count -eq 0) {
            $close += $window
            continue
        }
        foreach ($owner in $owners) {
            $seeds[[int]$owner.ProcessId] = $true
            $root = Get-AppRoot $owner.ExecutablePath
            if (-not $root) { continue }
            foreach ($process in $processes.Values) {
                if ($process.ExecutablePath -and (Test-Within $process.ExecutablePath $root)) { $seeds[[int]$process.ProcessId] = $true }
            }
        }
    }
    $kill = @{}
    foreach ($id in (Get-Descendants @($seeds.Keys) $processes).Keys) {
        $process = $processes[$id]
        if (-not $process -or $id -eq $PID -or $process.SessionId -eq 0 -or $foreign.ContainsKey($id)) { continue }
        if ($untouchable -contains (Get-BaseName $process.Name)) { continue }
        $kill[$id] = $process
    }
    @{ Kill = $kill; Close = $close }
}

function Invoke-Targets($targets) {
    if ($targets.Kill.Count -gt 0) {
        $arguments = @('/F') + @($targets.Kill.Keys | ForEach-Object { '/PID'; $_ })
        & taskkill.exe $arguments 2>&1 | Out-Null
    }
    foreach ($window in $targets.Close) { & $glazewm command --id $window.id close | Out-Null }
}

function Switch-Away($name) {
    & $glazewm command focus --recent-workspace | Out-Null
    $current = Get-Workspace
    if (-not $current -or $current.name -eq $name -or @(Get-Windows $current).Count -eq 0) {
        & $glazewm command focus --workspace $fallback | Out-Null
    }
}

$workspace = Get-Workspace $Target
if (-not $workspace) { exit }
$name = $workspace.name
$windows = @(Get-Windows $workspace)
if ($windows.Count -eq 0) { exit }

$processes = Get-Processes
$foreign = Get-ForeignPids $name $processes
$targets = Resolve-Targets $windows $processes $foreign
Write-Log ('kill ' + $name + ': ' + (($targets.Kill.Values | ForEach-Object { $_.Name } | Sort-Object -Unique) -join ',') +
           ' pids=' + ($targets.Kill.Keys -join ',') + ' close=' + (($targets.Close | ForEach-Object { $_.processName }) -join ','))

if ($workspace.hasFocus -and $name -ne $fallback) { Switch-Away $name }
Invoke-Targets $targets

for ($attempt = 1; $attempt -le 30; $attempt++) {
    Start-Sleep -Milliseconds 150
    $current = Get-Workspace $name
    $left = @(if ($current) { Get-Windows $current })
    if ($left.Count -eq 0) {
        Write-Log ('done ' + $name + ' after ' + ($attempt * 150) + 'ms')
        exit
    }
    if ($attempt % 10 -eq 0) {
        $alive = @($left | Where-Object { [Native.User32]::IsWindow([IntPtr][long]$_.handle) })
        $dead = @($left | Where-Object { -not [Native.User32]::IsWindow([IntPtr][long]$_.handle) })
        foreach ($window in $dead) { & $glazewm command --id $window.id ignore | Out-Null }
        if ($alive.Count -gt 0) {
            $processes = Get-Processes
            Invoke-Targets (Resolve-Targets $alive $processes (Get-ForeignPids $name $processes))
        }
        Write-Log ('retry ' + $name + ': alive=' + (($alive | ForEach-Object { $_.processName }) -join ',') + ' ghost=' + $dead.Count)
    }
}

Write-Log ('left ' + $name + ': ' + (($left | ForEach-Object { $_.processName + '#' + $_.handle }) -join ','))
