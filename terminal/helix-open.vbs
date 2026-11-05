Set shell = CreateObject("WScript.Shell")
file = WScript.Arguments(0)
optimum = shell.ExpandEnvironmentStrings("%LOCALAPPDATA%\Programs\Optimum\optimum.exe")
glazewm = "C:\Program Files\glzr.io\GlazeWM\cli\glazewm.exe"
shell.Run """" & optimum & """", 1, False
shell.Run """" & glazewm & """ command focus --workspace 3-terminal", 0, False
shell.Run "wsl.exe -d NixOS -e /usr/local/bin/hx-open-tab """ & file & """", 0, False
