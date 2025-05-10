param(
    [string]$Directory
)

# If no directory provided, use fzf to select one
if (-not $Directory) {
    $dirs = @()

    if (Test-Path "D:") {
        $dirs += Get-ChildItem -Path "D:\" -Recurse -Directory -Depth 2 -ErrorAction SilentlyContinue
    }

    # Add more paths if needed
    # $dirs += Get-ChildItem -Path "$env:USERPROFILE\Projects" -Recurse -Directory -Depth 2

    $dirPaths = $dirs | ForEach-Object { $_.FullName }
    $Directory = $dirPaths | fzf
}

if (-not $Directory) {
    exit 0
}

# Create a sanitized session name
$sessionName = (Split-Path -Leaf $Directory) -replace '\W', '_'

# Run wezterm with the session name and path as environment variables
[Environment]::SetEnvironmentVariable("WEZTERM_WORKSPACE_PATH", $Directory, "User")
[Environment]::SetEnvironmentVariable("WEZTERM_WORKSPACE_NAME", $sessionName, "User")
# $env:WEZTERM_WORKSPACE_PATH = $Directory
# $env:WEZTERM_WORKSPACE_NAME = $sessionName
# wezterm
