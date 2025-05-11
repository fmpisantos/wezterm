# Copy-Item -Path "$env:USERPROFILE\.config\wezterm\sessionizer.windows.lua" -Destination "$env:USERPROFILE\sessionizer.lua"
# Copy-Item -Path "$env:USERPROFILE\.config\wezterm\.wezterm.windows.lua" -Destination "$env:USERPROFILE\.wezterm.lua"
New-Item -Path "$HOME\.wezterm.lua" -ItemType SymbolicLink -Target "$HOME\.config\wezterm\.wezterm.windows.lua"
New-Item -Path "$HOME\sessionizer.lua" -ItemType SymbolicLink -Target "$HOME\.config\wezterm\sessionizer.windows.lua"
