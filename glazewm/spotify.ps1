$ErrorActionPreference = 'Continue'

$SpotifyExe = "$env:APPDATA\Spotify\Spotify.exe"
$Marker     = "$env:APPDATA\Spotify\Apps\xpui\spicetify-config.json"
$Spicetify  = "$env:LOCALAPPDATA\spicetify\spicetify.exe"
$ConfigIni  = "$env:APPDATA\spicetify\config-xpui.ini"
$LogFile    = "$env:USERPROFILE\.glzr\glazewm\spotify.log"

$mutex = New-Object System.Threading.Mutex($false, 'GlazeWmSpotifyLaunch')
if (-not $mutex.WaitOne(0)) { exit }

function Write-Log($message) {
    $file = Get-Item -Path $LogFile -ErrorAction SilentlyContinue
    if ($file -and $file.Length -gt 200KB) { Clear-Content -Path $LogFile }
    Add-Content -Path $LogFile -Value ((Get-Date).ToString('yyyy-MM-dd HH:mm:ss') + ' ' + $message)
}

function Invoke-Spicetify([string[]]$arguments) {
    & $Spicetify @arguments *>&1 |
        ForEach-Object { $_ -replace '\x1b\[[0-9;]*m', '' } |
        Where-Object { $_ -match '(success|error|warn|info)\s' } |
        ForEach-Object { Write-Log ('  ' + $_.Trim()) }
    $LASTEXITCODE
}

function Get-BackupField($name) {
    $line = Select-String -LiteralPath $ConfigIni -Pattern "^\s*$name\s*=\s*(.+)$" -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($line) { $line.Matches[0].Groups[1].Value.Trim() } else { '' }
}

Invoke-Spicetify @('update') | Out-Null

$spotifyVersion   = (Get-Item -LiteralPath $SpotifyExe).VersionInfo.FileVersion
$spicetifyVersion = ((& $Spicetify -v) -replace '\x1b\[[0-9;]*m', '').Trim()
$backupVersion    = Get-BackupField 'version'
$backupWith       = Get-BackupField 'with'
$patched          = Test-Path -LiteralPath $Marker

$current = $patched -and $backupVersion.StartsWith($spotifyVersion + '.') -and $backupWith -eq $spicetifyVersion
if (-not $current) {
    Write-Log "reapply: spotify=$spotifyVersion spicetify=$spicetifyVersion backup=$backupVersion with=$backupWith patched=$patched"
    Get-Process -Name 'Spotify' -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 2
    $code = Invoke-Spicetify @('backup', 'apply')
    if ($code -ne 0) {
        Invoke-Spicetify @('restore') | Out-Null
        Invoke-Spicetify @('clear') | Out-Null
        $code = Invoke-Spicetify @('backup', 'apply')
    }
    Write-Log "spicetify exit $code"
}

if (-not (Get-Process -Name 'Spotify' -ErrorAction SilentlyContinue)) {
    Start-Process -FilePath $SpotifyExe
}
