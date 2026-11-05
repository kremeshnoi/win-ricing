param([switch]$Uninstall)
$ErrorActionPreference = 'Stop'

$ProgId     = 'HelixTerminal.File'
$AppName    = 'Helix (Optimum)'
$Dir        = "$env:LOCALAPPDATA\HelixTerminal"
$Vbs        = "$Dir\helix-open.vbs"
$Icon       = "$env:LOCALAPPDATA\Programs\Optimum\optimum.exe,0"
$Classes    = 'Software\Classes'
$App        = 'Software\HelixTerminal'
$Registered = 'Software\RegisteredApplications'
$Previous   = 'HelixTerminal.Previous'
$Hkcu       = [Microsoft.Win32.Registry]::CurrentUser

$Extensions = @(
    '.', '.txt', '.md', '.markdown', '.log', '.json', '.jsonc', '.yaml', '.yml', '.toml', '.ini', '.cfg', '.conf',
    '.csv', '.tsv', '.xml', '.env', '.lock', '.editorconfig', '.gitignore', '.rs', '.ts', '.tsx', '.js', '.jsx',
    '.mjs', '.cjs', '.vue', '.py', '.go', '.rb', '.php', '.twig', '.java', '.kt', '.kts', '.clj', '.edn', '.sh',
    '.bash', '.zsh', '.lua', '.nix', '.css', '.scss', '.sql', '.c', '.h', '.cpp', '.hpp'
)

function Set-Value($path, $name, $value) {
    $key = $Hkcu.CreateSubKey($path)
    $key.SetValue($name, $value)
    $key.Close()
}

function Install {
    New-Item -ItemType Directory -Force -Path $Dir | Out-Null
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'helix-open.vbs') -Destination $Vbs -Force

    Set-Value "$Classes\$ProgId" '' 'Text file (Helix)'
    Set-Value "$Classes\$ProgId\DefaultIcon" '' $Icon
    Set-Value "$Classes\$ProgId\Application" 'ApplicationName' $AppName
    Set-Value "$Classes\$ProgId\Application" 'ApplicationIcon' $Icon
    Set-Value "$Classes\$ProgId\shell\open" 'FriendlyAppName' $AppName
    Set-Value "$Classes\$ProgId\shell\open\command" '' "wscript.exe //nologo `"$Vbs`" `"%1`""

    Set-Value "$App\Capabilities" 'ApplicationName' $AppName
    Set-Value "$App\Capabilities" 'ApplicationDescription' 'Opens text files in Helix inside Optimum'

    foreach ($ext in $Extensions) {
        $key = $Hkcu.CreateSubKey("$Classes\$ext")
        $current = $key.GetValue('')
        if ($current -ne $ProgId) {
            if ($null -ne $current) { $key.SetValue($Previous, $current) }
            $key.SetValue('', $ProgId)
        }
        $key.Close()
        Set-Value "$Classes\$ext\OpenWithProgids" $ProgId ''
        if ($ext -ne '.') { Set-Value "$App\Capabilities\FileAssociations" $ext $ProgId }
    }

    Set-Value $Registered $AppName "$App\Capabilities"
}

function Remove {
    foreach ($ext in $Extensions) {
        $key = $Hkcu.OpenSubKey("$Classes\$ext", $true)
        if ($null -eq $key) { continue }
        if ($key.GetValue('') -eq $ProgId) {
            $old = $key.GetValue($Previous)
            if ($null -ne $old) { $key.SetValue('', $old) } else { $key.DeleteValue('', $false) }
        }
        $key.DeleteValue($Previous, $false)
        $key.Close()
        $open = $Hkcu.OpenSubKey("$Classes\$ext\OpenWithProgids", $true)
        if ($null -ne $open) {
            $open.DeleteValue($ProgId, $false)
            $open.Close()
        }
    }

    $Hkcu.DeleteSubKeyTree("$Classes\$ProgId", $false)
    $Hkcu.DeleteSubKeyTree($App, $false)
    $reg = $Hkcu.OpenSubKey($Registered, $true)
    if ($null -ne $reg) {
        $reg.DeleteValue($AppName, $false)
        $reg.Close()
    }
    Remove-Item -LiteralPath $Dir -Recurse -Force -ErrorAction SilentlyContinue
}

Add-Type -Namespace Win32 -Name Shell -MemberDefinition @'
[DllImport("shell32.dll")] public static extern void SHChangeNotify(int e, uint f, System.IntPtr a, System.IntPtr b);
[DllImport("shlwapi.dll", CharSet = CharSet.Unicode)] public static extern uint AssocQueryString(uint f, uint s, string a, string e, System.Text.StringBuilder o, ref uint n);
'@

if ($Uninstall) { Remove } else { Install }
[Win32.Shell]::SHChangeNotify(0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)

if (-not $Uninstall) {
    foreach ($ext in $Extensions) {
        if ($ext -eq '.') { continue }
        $buffer = New-Object System.Text.StringBuilder 1024
        $size = [uint32]1024
        [void][Win32.Shell]::AssocQueryString(0, 1, $ext, 'open', $buffer, [ref]$size)
        if ($buffer.ToString() -notlike '*helix-open.vbs*') { "needs manual choice: $ext -> $buffer" }
    }
}
