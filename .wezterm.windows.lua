local wezterm = require 'wezterm'

local mux = wezterm.mux
local io = require 'io'
local os = require 'os'
local act = wezterm.action
local platform = wezterm.target_triple

local windows = false

if platform:find("windows") then
    windows = true
end

wezterm.on('trigger-vim-with-scrollback', function(window, pane)
    local text = pane:get_lines_as_text(pane:get_dimensions().scrollback_rows)

    local name = os.tmpname()
    local f = io.open(name, 'w+')
    f:write(text)
    f:flush()
    f:close()

    window:perform_action(
        act.SpawnCommandInNewTab {
            args = { 'nvim', '+', name },
        },
        pane
    )

    wezterm.sleep_ms(1000)
    os.remove(name)
end)

local directories = {
    { "D:\\",                           0 },
    { "D:\\src",                        0 },
    { "D:\\SIHOT.PMS",                  0 },
    { "D:\\net-nuget-packages",         0 },
    { "~\\.config",                     0 },
    { "~\\Documents/WindowsPowerShell", 0 },
}

local function sessionizer(window, pane)
    local function expand_path(path)
        return path:gsub("^~", os.getenv("HOME"))
    end

    local function build_find_command(dirs)
        local parts = {}

        for _, entry in ipairs(dirs) do
            local path = expand_path(entry[1])
            local maxdepth = entry[2]
            local cmd = string.format(
                "Get-ChildItem -Path '%s' -Recurse -Directory -Depth %d | Select-Object -ExpandProperty FullName",
                path, maxdepth
            )

            table.insert(parts, cmd)
        end

        return "powershell -Command \"" .. table.concat(parts, " ; ") .. "\""
    end

    local function get_projects()
        local cmd = build_find_command(directories)
        -- wezterm.log_info(cmd);
        local f = io.popen(cmd)
        local result = f:read("*a")
        f:close()

        local choices = {}
        local choices_labels = {}
        for dir in result:gmatch("[^\n]+") do
            local label = dir
            for _, pair in ipairs(directories) do
                label = label:gsub(expand_path(pair[1]), "")
            end
            if label == "" then
                label = dir
            end

            if choices_labels[label] then
                label = dir
            end
            choices_labels[label] = true

            table.insert(choices, { label = label, id = dir })
        end
        return choices
    end

    local projects = get_projects()

    window:perform_action(
        act.InputSelector({
            action = wezterm.action_callback(function(win, _, id, label)
                if not id and not label then
                else
                    local workspace = id:match("([^/]+)$"):gsub("%.", "_")

                    win:perform_action(
                        act.SwitchToWorkspace({
                            name = workspace,
                            spawn = { cwd = id }
                        }),
                        pane
                    )
                end
            end),
            fuzzy = true,
            title = "Select project",
            choices = projects,
        }),
        pane
    )
end

local resize_mode = false

local function resize(window, pane, side)
    if resize_mode then
        window:perform_action(wezterm.action.AdjustPaneSize { side, 5 }, pane)
    end
end

local config = {
    window_close_confirmation = "NeverPrompt",
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
    font_size = 12,
    window_background_opacity = 0.95,
    window_background_image = nil,
    audible_bell = "Disabled",
    leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1000 },
    keys = {
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
            key = '<',
            action = wezterm.action_callback(function(window, pane)
                resize(window, pane, 'Left')
            end)
        },
        {
            key = '>',
            action = wezterm.action_callback(function(window, pane)
                resize(window, pane, 'Right')
            end)
        },
        {
            key = '|',
            action = wezterm.action_callback(function(window, pane)
                resize(window, pane, 'Up')
            end)
        },
        {
            key = '\\',
            action = wezterm.action_callback(function(window, pane)
                resize(window, pane, 'Down')
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
                    -- wezterm.log_info("In nvim")
                    window:perform_action(
                        act.SendKey { key = 'f', mods = 'CTRL' },
                        pane
                    )
                else
                    sessionizer.toggle(window, pane);
                end
            end),
        },
        {
            key = 'F13',
            action = wezterm.action_callback(function(window, pane)
                sessionizer.toggle(window, pane)
            end)
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

local function getExecutableName(path)
    return path:match("([^\\]+)%.exe$")
end

wezterm.on('update-right-status', function(window, _)
    local _ = window:active_tab()

    for _, tab in ipairs(window:mux_window():tabs()) do
        local pane = tab:active_pane()
        local proc = pane:get_foreground_process_name()

        local process_name = getExecutableName(proc:gsub("^.*/", ""))

        tab:set_title(process_name)
    end
end)

return config
