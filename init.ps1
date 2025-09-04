# Create symbolic links with elevated permissions
$command = @'
New-Item -Path "$HOME\.wezterm.lua" -ItemType SymbolicLink -Target "$HOME\.config\wezterm\.wezterm.lua" -Force
New-Item -Path "$HOME\sessionizer.lua" -ItemType SymbolicLink -Target "$HOME\.config\wezterm\sessionizer.lua" -Force
New-Item -Path "$HOME\constants.lua" -ItemType SymbolicLink -Target "$HOME\.config\wezterm\constants.lua" -Force
'@
Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile", "-NoExit", "-Command `"`$env:HOME='$HOME'; $command`""

# Wait a moment for the elevated process to complete
Start-Sleep -Seconds 3

# Add function to PowerShell profile
$profilePath = $PROFILE
$sshFunction = @'

# Custom SSH function using WezTerm with specific config
function ssh {
    param([Parameter(ValueFromRemainingArguments)][string[]]$Arguments)
    wezterm --config-file "$env:USERPROFILE\.config\wezterm\.ssh_config.lua" start -- ssh @Arguments
}
'@

# Create profile directory if it doesn't exist
$profileDir = Split-Path $profilePath -Parent
if (!(Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force
}

# Check if the function already exists in the profile
if (Test-Path $profilePath) {
    $profileContent = Get-Content $profilePath -Raw
    if ($profileContent -notmatch "function ssh") {
        Add-Content -Path $profilePath -Value $sshFunction
        Write-Host "Added ssh function to PowerShell profile: $profilePath" -ForegroundColor Green
    } else {
        Write-Host "ssh function already exists in PowerShell profile" -ForegroundColor Yellow
    }
} else {
    # Create new profile with the function
    Set-Content -Path $profilePath -Value $sshFunction
    Write-Host "Created PowerShell profile with ssh function: $profilePath" -ForegroundColor Green
}

Write-Host "Setup complete! Restart your PowerShell session or run '. `$PROFILE' to reload." -ForegroundColor Cyan
