#!/bin/bash

# Create symlinks
ln -s ~/.config/wezterm/.wezterm.lua ~/.wezterm.lua
ln -s ~/.config/wezterm/sessionizer.lua ~/sessionizer.lua
ln -s ~/.config/wezterm/constants.lua ~/constants.lua

# Add SSH function to zshrc (instead of alias)
if ! grep -q "ssh()" ~/.zshrc; then
    cat >> ~/.zshrc << 'EOF'

# Custom SSH function using WezTerm with specific config
ssh() {
    wezterm --config-file ~/.config/wezterm/.ssh_config.lua start -- ssh "$@"
}
EOF
    echo "Added ssh function to .zshrc"
else
    echo "ssh function already exists in .zshrc"
fi
