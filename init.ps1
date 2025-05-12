# Copy-Item -Path "$env:USERPROFILE\.config\wezterm\sessionizer.windows.lua" -Destination "$env:USERPROFILE\sessionizer.lua"
# Copy-Item -Path "$env:USERPROFILE\.config\wezterm\.wezterm.windows.lua" -Destination "$env:USERPROFILE\.wezterm.lua"
$command = @'
New-Item -Path "$HOME\.wezterm.lua" -ItemType SymbolicLink -Target "$HOME\.config\wezterm\.wezterm.lua"
New-Item -Path "$HOME\sessionizer.lua" -ItemType SymbolicLink -Target "$HOME\.config\wezterm\sessionizer.lua"
New-Item -Path "$HOME\constants.lua" -ItemType SymbolicLink -Target "$HOME\.config\wezterm\constants.lua"
'@

Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile", "-NoExit", "-Command `"`$env:HOME='$HOME'; $command`""
