param([switch]$Uninstall)
$ErrorActionPreference = 'Stop'

$ProgId     = 'HelixTerminal.File'
$AppName    = 'Helix (Optimum)'
$Dir        = "$env:LOCALAPPDATA\HelixTerminal"
$Vbs        = "$Dir\helix-open.vbs"
$Classes    = 'Software\Classes'
$App        = 'Software\HelixTerminal'
$Registered = 'Software\RegisteredApplications'
$Previous   = 'HelixTerminal.Previous'
$Hkcu       = [Microsoft.Win32.Registry]::CurrentUser
$FileExts   = 'Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts'

$Optimum = @("$env:ProgramFiles\Optimum\optimum.exe", "$env:LOCALAPPDATA\Programs\Optimum\optimum.exe") |
    Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $Uninstall -and -not $Optimum) { throw 'optimum.exe not found' }
$Icon = "`"$Optimum`",0"

$Extensions = @(
    '.', '.txt', '.text', '.md', '.markdown', '.rst', '.adoc', '.org', '.log', '.out', '.srt', '.vtt', '.nfo', '.diz',
    '.json', '.jsonc', '.json5', '.jsonl', '.ndjson', '.yaml', '.yml', '.toml', '.ini', '.cfg', '.conf', '.config',
    '.properties', '.env', '.lock', '.csv', '.tsv', '.xml', '.xsd', '.xsl', '.plist', '.manifest', '.lst',
    '.vdf', '.acf', '.vcfg', '.editorconfig', '.gitignore', '.gitattributes', '.gitmodules', '.gitconfig',
    '.dockerignore', '.npmrc', '.nvmrc', '.prettierrc', '.eslintrc', '.babelrc', '.wslconfig', '.ideavimrc', '.vimrc',
    '.rs', '.ts', '.tsx', '.cts', '.js', '.jsx', '.mjs', '.cjs', '.vue', '.svelte', '.astro', '.py', '.pyi',
    '.go', '.rb', '.php', '.twig', '.java', '.kt', '.kts', '.gradle', '.scala', '.groovy', '.clj', '.cljs', '.cljc',
    '.edn', '.cs', '.fs', '.swift', '.dart', '.zig', '.ex', '.exs', '.erl', '.hs', '.ml', '.elm', '.r', '.jl', '.pl',
    '.sh', '.bash', '.zsh', '.fish', '.nu', '.ps1', '.psm1', '.psd1', '.lua', '.vim', '.nix', '.css', '.scss', '.sass',
    '.less', '.sql', '.graphql', '.gql', '.proto', '.c', '.h', '.cc', '.cpp', '.cxx', '.hpp', '.hh', '.cmake', '.mk',
    '.glsl', '.hlsl', '.frag', '.vert', '.geom', '.comp', '.shader', '.wgsl', '.qml', '.tf', '.hcl', '.http',
    '.diff', '.patch', '.pem'
)

function Set-Value($path, $name, $value) {
    $key = $Hkcu.CreateSubKey($path)
    $key.SetValue($name, $value)
    $key.Close()
}

function Clear-UserChoice($ext) {
    foreach ($name in 'UserChoice', 'UserChoiceLatest') {
        $path = "$FileExts\$ext\$name"
        $key = $Hkcu.OpenSubKey($path)
        if ($null -eq $key) { continue }
        $choice = $key.GetValue('ProgId')
        if ($null -eq $choice) {
            $sub = $Hkcu.OpenSubKey("$path\ProgId")
            if ($null -ne $sub) { $choice = $sub.GetValue('ProgId'); $sub.Close() }
        }
        $key.Close()
        if ($choice -eq $ProgId) { continue }
        try { $Hkcu.DeleteSubKeyTree($path, $false) } catch {}
    }
}

function Install {
    New-Item -ItemType Directory -Force -Path $Dir | Out-Null
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'helix-open.vbs') -Destination $Vbs -Force

    Set-Value "$Classes\$ProgId" '' 'Text file (Helix)'
    Set-Value "$Classes\$ProgId\DefaultIcon" '' $Icon
    Set-Value "$Classes\$ProgId\Application" 'ApplicationName' $AppName
    Set-Value "$Classes\$ProgId\Application" 'ApplicationIcon' $Icon
    Set-Value "$Classes\$ProgId\shell\open" 'FriendlyAppName' $AppName
    Set-Value "$Classes\$ProgId\shell\open\command" '' "wscript.exe //nologo `"$Vbs`" `"$Optimum`" `"%1`""

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
        if ($ext -ne '.') { Clear-UserChoice $ext }
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
