local wezterm = require 'wezterm'
local mux = wezterm.mux
local act = wezterm.action

local config = {
    default_prog = { 'powershell.exe', '-NoLogo' },
    prefer_egl = true,
    color_scheme = 'Tokyo Night Moon',
    window_decorations = "NONE",
    visual_bell = {
        fade_in_duration_ms = 0,
        fade_out_duration_ms = 0,
    },

    -- Show the name of the current process in the tab title
    use_fancy_tab_bar = true,
    tab_bar_at_bottom = false,
    hide_tab_bar_if_only_one_tab = false,
    show_tab_index_in_tab_bar = true,
    tab_max_width = 25,

    -- Set the leader key to Ctrl+a like tmux
    leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1000 },

    -- Configure keybindings
    keys = {
        -- Create a new tab with leader + n
        { key = 'n',          mods = 'LEADER',      action = act.SpawnTab 'DefaultDomain' },

        -- Split panes - right, left, below, above
        { key = 'L',          mods = 'LEADER',      action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
        { key = 'H',          mods = 'LEADER',      action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
        { key = 'J',          mods = 'LEADER',      action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
        { key = 'K',          mods = 'LEADER',      action = act.SplitVertical { domain = 'CurrentPaneDomain' } },

        -- Switch to tab 1-9
        { key = '1',          mods = 'LEADER',      action = act.ActivateTab(0) },
        { key = '2',          mods = 'LEADER',      action = act.ActivateTab(1) },
        { key = '3',          mods = 'LEADER',      action = act.ActivateTab(2) },
        { key = '4',          mods = 'LEADER',      action = act.ActivateTab(3) },
        { key = '5',          mods = 'LEADER',      action = act.ActivateTab(4) },
        { key = '6',          mods = 'LEADER',      action = act.ActivateTab(5) },
        { key = '7',          mods = 'LEADER',      action = act.ActivateTab(6) },
        { key = '8',          mods = 'LEADER',      action = act.ActivateTab(7) },
        { key = '9',          mods = 'LEADER',      action = act.ActivateTab(8) },

        -- Navigate between panes
        { key = 'LeftArrow',  mods = 'LEADER',      action = act.ActivatePaneDirection 'Left' },
        { key = 'RightArrow', mods = 'LEADER',      action = act.ActivatePaneDirection 'Right' },
        { key = 'UpArrow',    mods = 'LEADER',      action = act.ActivatePaneDirection 'Up' },
        { key = 'DownArrow',  mods = 'LEADER',      action = act.ActivatePaneDirection 'Down' },

        -- Navigate between panes with vim-style hjkl
        { key = 'h',          mods = 'LEADER',      action = act.ActivatePaneDirection 'Left' },
        { key = 'l',          mods = 'LEADER',      action = act.ActivatePaneDirection 'Right' },
        { key = 'k',          mods = 'LEADER',      action = act.ActivatePaneDirection 'Up' },
        { key = 'j',          mods = 'LEADER',      action = act.ActivatePaneDirection 'Down' },

        -- Send the leader key through to the application by pressing it twice
        { key = 'a',          mods = 'LEADER|CTRL', action = act.SendKey { key = 'a', mods = 'CTRL' } },

        -- Sessionizer - Ctrl+f to open project selector
        {
            key = 'f',
            mods = 'CTRL',
            action = wezterm.action_callback(function(window, pane)
                -- Check if the current foreground process is nvim
                local process = pane:get_foreground_process_name():lower()
                if process:find("n?vim") then
                    -- If in nvim, pass the keystroke through
                    window:perform_action(
                        act.SendKey { key = 'f', mods = 'CTRL' },
                        pane
                    )
                else
                    -- Otherwise run the sessionizer - using appropriate path for Windows
                    local home = os.getenv("USERPROFILE") or os.getenv("HOME")
                    local sessionizer_path

                    -- Check if we're on Windows or Unix-like
                    if package.config:sub(1, 1) == '\\' then
                        -- Windows
                        sessionizer_path = home .. "\\wezterm-sessionizer.ps1"
                        window:perform_action(
                            act.SpawnCommandInNewTab {
                                args = {
                                    'powershell.exe',
                                    '-NoProfile',
                                    '-ExecutionPolicy',
                                    'Bypass',
                                    '-File',
                                    sessionizer_path
                                },
                            },
                            pane
                        )
                    else
                        -- Unix-like
                        sessionizer_path = home .. "/.local/bin/wezterm-sessionizer"
                        window:perform_action(
                            act.SpawnCommandInNewTab {
                                args = { sessionizer_path },
                            },
                            pane
                        )
                    end

                    local cwd = os.getenv("WEZTERM_WORKSPACE_PATH")
                    local workspace = os.getenv("WEZTERM_WORKSPACE_NAME")

                    if cwd and workspace then
                        wezterm.on("spawn-my-workspace", function(_window, _pane)
                            local path = cwd
                            local workspace_name = workspace

                            _window:perform_action(
                                wezterm.action.SwitchToWorkspace {
                                    name = workspace_name,
                                },
                                _pane
                            )

                            mux.spawn_window {
                                workspace = workspace_name,
                                cwd = path,
                            }
                        end)
                    end
                end
            end),
        },
    },
}

wezterm.on('gui-startup', function(cmd)
    local _, _, window = mux.spawn_window(cmd or {})
    window:gui_window():maximize()
end)

wezterm.on('update-right-status', function(window, _)
    local _ = window:active_tab()

    for _, tab in ipairs(window:mux_window():tabs()) do
        local pane = tab:active_pane()
        local proc = pane:get_foreground_process_name()

        local process_name = proc:gsub("^.*/", "")

        tab:set_title(process_name)
    end
end)

return config
