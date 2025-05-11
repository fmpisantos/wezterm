local wezterm = require 'wezterm'
local sessionizer = require 'sessionizer'
local mux = wezterm.mux
local act = wezterm.action
local platform = wezterm.target_triple
local windows = false

if platform:find("windows") then
    windows = true
end

local config = {
    color_scheme = 'Tokyo Night Moon',
    window_decorations = "RESIZE",
    window_padding = {
        left = 0,
        right = 0,
        top = 0,
        bottom = 0,
    },
    visual_bell = {
        fade_in_duration_ms = 0,
        fade_out_duration_ms = 0,
    },
    use_fancy_tab_bar = true,
    tab_bar_at_bottom = true,
    hide_tab_bar_if_only_one_tab = false,
    show_tab_index_in_tab_bar = true,
    tab_max_width = 25,
    quit_when_all_windows_are_closed = true,
    font = wezterm.font("JetBrains Mono", { weight = "Regular" }),
    font_size = 14,
    window_background_opacity = 0.95,
    audible_bell = "Disabled",
    leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1000 },
    keys = {
        {
            key = 's',
            mods = 'LEADER',
            action = wezterm.action.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' },
        },
        { key = 'n', mods = 'LEADER',      action = act.SpawnTab 'DefaultDomain' },
        { key = 'L', mods = 'LEADER',      action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
        { key = 'H', mods = 'LEADER',      action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
        { key = 'J', mods = 'LEADER',      action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
        { key = 'K', mods = 'LEADER',      action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
        { key = '1', mods = 'LEADER',      action = act.ActivateTab(0) },
        { key = '2', mods = 'LEADER',      action = act.ActivateTab(1) },
        { key = '3', mods = 'LEADER',      action = act.ActivateTab(2) },
        { key = '4', mods = 'LEADER',      action = act.ActivateTab(3) },
        { key = '5', mods = 'LEADER',      action = act.ActivateTab(4) },
        { key = '6', mods = 'LEADER',      action = act.ActivateTab(5) },
        { key = '7', mods = 'LEADER',      action = act.ActivateTab(6) },
        { key = '8', mods = 'LEADER',      action = act.ActivateTab(7) },
        { key = '9', mods = 'LEADER',      action = act.ActivateTab(8) },
        { key = 'h', mods = 'LEADER',      action = act.ActivatePaneDirection 'Left' },
        { key = 'l', mods = 'LEADER',      action = act.ActivatePaneDirection 'Right' },
        { key = 'k', mods = 'LEADER',      action = act.ActivatePaneDirection 'Up' },
        { key = 'j', mods = 'LEADER',      action = act.ActivatePaneDirection 'Down' },
        { key = 'a', mods = 'LEADER|CTRL', action = act.SendKey { key = 'a', mods = 'CTRL' } },
        {
            key = 'f',
            mods = 'CTRL',
            action = wezterm.action_callback(function(window, pane)
                local process = pane:get_foreground_process_name():lower()
                if process:find("n?vim") then
                    window:perform_action(
                        act.SendKey { key = 'f', mods = 'CTRL' },
                        pane
                    )
                else
                    sessionizer.toggle(window, pane);
                end
            end),
        },
    },
}

if windows then
    config.default_prog = { 'powershell.exe', '-NoLogo' };
    config.prefer_egl = true;
end

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
