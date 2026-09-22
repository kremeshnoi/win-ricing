$ErrorActionPreference = 'Stop'

$Spicetify  = "$env:LOCALAPPDATA\spicetify\spicetify.exe"
$SpotifyExe = "$env:APPDATA\Spotify\Spotify.exe"
$ConfigIni  = "$env:APPDATA\spicetify\config-xpui.ini"
$Marker     = "$env:APPDATA\Spotify\Apps\xpui\spicetify-config.json"
$LogFile    = "$env:LOCALAPPDATA\spicetify\guard.log"

function Write-Log {
    param([string]$Message)
    $line = "{0} {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Add-Content -LiteralPath $LogFile -Value $line
}

foreach ($p in $Spicetify, $SpotifyExe, $ConfigIni) {
    if (-not (Test-Path -LiteralPath $p)) { Write-Log "not found: $p"; exit 1 }
}

$installed = (Get-Item -LiteralPath $SpotifyExe).VersionInfo.FileVersion
$patched   = (Select-String -LiteralPath $ConfigIni -Pattern '^\s*version\s*=\s*(.+)$' |
    Select-Object -First 1).Matches[0].Groups[1].Value.Trim()
$isPatched = Test-Path -LiteralPath $Marker

if ($patched.StartsWith($installed) -and $isPatched) { exit 0 }

Write-Log "reapply: installed=$installed patched=$patched marker=$isPatched"

$wasRunning = [bool](Get-Process -Name 'Spotify' -ErrorAction SilentlyContinue)
if ($wasRunning) {
    Get-Process -Name 'Spotify' -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 2
}

function Invoke-Spicetify {
    param([Parameter(Mandatory)][string[]]$Arguments)
    & $Spicetify @Arguments *>&1 | ForEach-Object { Write-Log ($_ -replace '\x1b\[[0-9;]*m', '') }
    return $LASTEXITCODE
}

$code = Invoke-Spicetify -Arguments @('backup', 'apply')

if ($code -ne 0) {
    Write-Log "apply failed with exit code $code, updating spicetify"
    $updateCode = Invoke-Spicetify -Arguments @('update')
    if ($updateCode -ne 0) {
        Write-Log "update failed with exit code $updateCode"
        exit $updateCode
    }
    $code = Invoke-Spicetify -Arguments @('backup', 'apply')
}

if ($code -ne 0) {
    Write-Log "spicetify failed with exit code $code"
    exit $code
}

Write-Log "reapplied for $installed"

if ($wasRunning) {
    Start-Process -FilePath $SpotifyExe
}
