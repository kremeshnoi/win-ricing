$ErrorActionPreference = 'SilentlyContinue'
$glazewm = 'C:\Program Files\glzr.io\GlazeWM\cli\glazewm.exe'
$logPath = 'C:\Users\Alex\.glzr\glazewm\kill-workspace.log'
$protected = 'explorer', 'glazewm', 'yasb', 'autohotkey64', 'wscript', 'powershell', 'conhost', 'dwm', 'svchost', 'runtimebroker', 'applicationframehost'

Add-Type -Namespace Native -Name User32 -MemberDefinition @'
[DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
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

function Test-Within($path, $root) {
    $root = $root.TrimEnd('\') + '\'
    ($path.TrimEnd('\') + '\').StartsWith($root, [StringComparison]::OrdinalIgnoreCase)
}

$workspace = ((& $glazewm query workspaces) | ConvertFrom-Json).data.workspaces | Where-Object { $_.hasFocus } | Select-Object -First 1
if (-not $workspace) { exit }
$windows = @(Get-Windows $workspace)
if ($windows.Count -eq 0) { exit }

$processes = @{}
Get-CimInstance Win32_Process | ForEach-Object { $processes[[int]$_.ProcessId] = $_ }

$roots = @{}
foreach ($window in $windows) {
    [uint32]$id = 0
    [void][Native.User32]::GetWindowThreadProcessId([IntPtr][long]$window.handle, [ref]$id)
    $process = $processes[[int]$id]
    if (-not $process -or -not $process.ExecutablePath) { continue }
    if (Test-Within $process.ExecutablePath $env:windir) { continue }
    if ($protected -contains [IO.Path]::GetFileNameWithoutExtension($process.Name).ToLower()) { continue }

    $dir = Split-Path $process.ExecutablePath
    $parent = $processes[[int]$process.ParentProcessId]
    while ($parent -and $parent.ExecutablePath -and
           -not (Test-Within $parent.ExecutablePath $env:windir) -and
           (Test-Within $dir (Split-Path $parent.ExecutablePath))) {
        $process = $parent
        $parent = $processes[[int]$process.ParentProcessId]
    }
    $roots[[int]$process.ProcessId] = $process
}

if ($roots.Count -eq 0) { exit }

& $glazewm command focus --recent-workspace | Out-Null

foreach ($process in $roots.Values) {
    $paths = @($processes.Values | Where-Object { $_.ExecutablePath -eq $process.ExecutablePath } | ForEach-Object { [int]$_.ProcessId })
    Write-Log ('kill ' + $workspace.name + ': ' + $process.ExecutablePath + ' (' + ($paths -join ',') + ')')
    foreach ($id in $paths) { & taskkill.exe /PID $id /T /F | Out-Null }
}
