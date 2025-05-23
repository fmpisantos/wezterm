local wezterm = require 'wezterm'
local sessionizer = require "sessionizer"

local mux = wezterm.mux
local io = require 'io'
local os = require 'os'
local act = wezterm.action
local platform = wezterm.target_triple

local windows, macos = false, false

if platform:find("windows") then
    windows = true
elseif wezterm.target_triple:find("apple%-darwin") ~= nil then
    macos = true
end

local function get_nvim_path()
    if macos then
        return "/opt/homebrew/bin/nvim"
    end
    return "nvim"
end

local function generate_session_id()
    local time = os.time()
    local random = math.random(1000, 9999)
    return string.format("%d-%d", time, random)
end

local session_id = generate_session_id()

local function log(str, newLine)
    if newLine then
        str = str .. "\n"
    end
    local f = io.open("/tmp/wezterm-" .. session_id, 'a')
    f:write(str)
    f:flush()
    f:close()
end

wezterm.on('trigger-vim-with-scrollback', function(window, pane)
    local text = pane:get_lines_as_text(pane:get_dimensions().scrollback_rows)

    local name = os.tmpname() .. ".zsh"
    local f = io.open(name, 'w+')
    f:write(text)
    f:flush()
    f:close()

    window:perform_action(
        act.SpawnCommandInNewTab {
            args = { get_nvim_path(), '+', name }
        },
        pane
    )

    wezterm.sleep_ms(500)
    os.remove(name)
end)

local resize_mode = false

local function resize(window, pane, side)
    if resize_mode then
        window:perform_action(wezterm.action.AdjustPaneSize { side, 5 }, pane)
    end
end

wezterm.on('gui-startup', function(cmd)
    local _, _, window = mux.spawn_window(cmd or {})
    window:gui_window():maximize()
end)

local function getExecutableName(path)
    return path:match("([^\\]+)%.exe$")
end

local currentWorkspace = nil
local lastWorkspace = nil

local function workspace_exists(_name, window)
    local active_workspaces = wezterm.mux.get_workspace_names()

    local exists = false
    for _, name in ipairs(active_workspaces) do
        if name == _name then
            exists = true
            break
        end
    end

    return exists
end

wezterm.on('switch_to_last_workspace', function(window, pane)
    if lastWorkspace then
        if workspace_exists(lastWorkspace, window) then
            window:perform_action(
                act.SwitchToWorkspace {
                    name = lastWorkspace
                },
                pane
            )
        else
            lastWorkspace = nil
        end
    end
end)

wezterm.on('update-right-status', function(window, _pane)
    local workspace = window:active_workspace()
    if currentWorkspace == nil then
        currentWorkspace = workspace
    end

    if currentWorkspace ~= workspace then
        lastWorkspace = currentWorkspace
        currentWorkspace = workspace
    end

    local _ = window:active_tab()

    for _, tab in ipairs(window:mux_window():tabs()) do
        local pane = tab:active_pane()
        local proc = pane:get_foreground_process_name()

        local process_name
        if windows then
            process_name = getExecutableName(proc:gsub("^.*/", ""))
        else
            process_name = proc:gsub("^.*/", "")
        end

        tab:set_title(process_name)
    end
end)

local config = wezterm.config_builder()

-- Performance
config.max_fps = 120
config.front_end = "WebGpu"

-- Window decoration
config.window_decorations = "RESIZE"
config.window_padding = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 0,
}
config.visual_bell = {
    fade_in_duration_ms = 0,
    fade_out_duration_ms = 0,
}
config.use_fancy_tab_bar = true
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = true
config.show_tab_index_in_tab_bar = true
config.tab_max_width = 25

-- Settings
config.quit_when_all_windows_are_closed = true
config.enable_scroll_bar = false
config.window_close_confirmation = "NeverPrompt"
config.audible_bell = "Disabled"
config.switch_to_last_active_tab_when_closing_tab = true

-- Colors
config.color_scheme = 'Tokyo Night Moon'
config.font = wezterm.font("JetBrains Mono", { weight = "Regular" })
config.font_size = 15
config.window_background_opacity = 0.95
config.window_background_image = nil
config.macos_window_background_blur = 40

-- Keys
config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1000 }
config.keys = {
    {
        key = 'Escape',
        action = wezterm.action_callback(function(win, pane)
            if resize_mode then
                resize_mode = false
            else
                win:perform_action(wezterm.action.SendKey { key = 'Escape' }, pane)
            end
        end),
    },
    {
        key = 's',
        mods = 'LEADER',
        action = wezterm.action.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' },
    },
    {
        key = 'E',
        mods = 'LEADER',
        action = act.EmitEvent 'trigger-vim-with-scrollback',
    },
    {
        key = '[',
        mods = 'LEADER',
        action = act.EmitEvent 'trigger-vim-with-scrollback',
    },
    {
        key = 'w',
        mods = 'LEADER',
        action = wezterm.action.CloseCurrentTab { confirm = false },
    },
    {
        key = '=',
        mods = 'LEADER',
        action = act.EmitEvent 'switch_to_last_workspace'
    },
    { key = 'n', mods = 'LEADER', action = act.SpawnTab 'DefaultDomain' },
    { key = 'L', mods = 'LEADER', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
    { key = 'H', mods = 'LEADER', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
    { key = 'J', mods = 'LEADER', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
    { key = 'K', mods = 'LEADER', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
    { key = '1', mods = 'LEADER', action = act.ActivateTab(0) },
    { key = '2', mods = 'LEADER', action = act.ActivateTab(1) },
    { key = '3', mods = 'LEADER', action = act.ActivateTab(2) },
    { key = '4', mods = 'LEADER', action = act.ActivateTab(3) },
    { key = '5', mods = 'LEADER', action = act.ActivateTab(4) },
    { key = '6', mods = 'LEADER', action = act.ActivateTab(5) },
    { key = '7', mods = 'LEADER', action = act.ActivateTab(6) },
    { key = '8', mods = 'LEADER', action = act.ActivateTab(7) },
    { key = '9', mods = 'LEADER', action = act.ActivateTab(8) },
    { key = 'h', mods = 'LEADER', action = act.ActivatePaneDirection 'Left' },
    { key = 'l', mods = 'LEADER', action = act.ActivatePaneDirection 'Right' },
    { key = 'k', mods = 'LEADER', action = act.ActivatePaneDirection 'Up' },
    { key = 'j', mods = 'LEADER', action = act.ActivatePaneDirection 'Down' },
    {
        key = "R",
        mods = "LEADER",
        action = wezterm.action_callback(function(_, _)
            sessionizer.clear_cache();
        end)
    },
    {
        key = "r",
        mods = "LEADER",
        action = wezterm.action_callback(function(_, _)
            sessionizer.clear_cache();
        end)
    },
    {
        key = '<',
        mods = 'LEADER',
        action = wezterm.action_callback(function(window, pane)
            resize_mode = true
            resize(window, pane, 'Left')
        end)
    },
    {
        key = '>',
        mods = 'LEADER',
        action = wezterm.action_callback(function(window, pane)
            resize_mode = true
            resize(window, pane, 'Right')
        end)
    },
    {
        key = '\\',
        mods = 'LEADER',
        action = wezterm.action_callback(function(window, pane)
            resize_mode = true
            resize(window, pane, 'Down')
        end)
    },
    {
        key = '|',
        mods = 'LEADER',
        action = wezterm.action_callback(function(window, pane)
            resize_mode = true
            resize(window, pane, 'Up')
        end)
    },
    { key = 'a', mods = 'LEADER|CTRL', action = act.SendKey { key = 'a', mods = 'CTRL' } },
    {
        key = 'f',
        mods = 'CTRL',
        action = wezterm.action_callback(function(window, pane)
            local process = pane:get_foreground_process_name():lower()
            if process:find("nvim") then
                window:perform_action(
                    act.SendKey { key = 'f', mods = 'CTRL' },
                    pane
                )
            else
                sessionizer.toggle(window, pane, windows);
            end
        end),
    },
    {
        key = 'F13',
        action = wezterm.action_callback(function(window, pane)
            sessionizer.toggle(window, pane, windows)
        end)
    },
}

if windows then
    config.default_prog = { 'powershell.exe', '-NoLogo' };
    config.prefer_egl = true;
    config.font_size = 10
    config.window_background_opacity = 1.0
    config.front_end = "OpenGL"
end

return config
