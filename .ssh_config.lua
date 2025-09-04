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
        return "/Users/fmpi.santos/.local/share/bob/nvim-bin/nvim"
        -- return "/opt/homebrew/bin/nvim"
    end
    return "nvim"
end

local function generate_session_id()
    local time = os.time()
    local random = math.random(1000, 9999)
    return string.format("%d-%d", time, random)
end

local function get_temp_file()
    if windows then
        local temp_dir = os.getenv("TEMP") or os.getenv("TMP") or "C:\\Windows\\Temp"
        local sep = package.config:sub(1, 1)
        return temp_dir .. sep .. "wezterm_scrollback_" .. os.time() .. "_" .. math.random(1000, 9999) .. ".txt"
    else
        local temp_dir = os.getenv("TMPDIR") or "/tmp"
        return temp_dir .. "/wezterm_scrollback_" .. os.time() .. "_" .. math.random(1000, 9999) .. ".txt"
    end
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

    local name = get_temp_file()

    local f = io.open(name, 'w+')
    if not f then
        wezterm.log_error("Could not create temp file: " .. name)
        return
    end

    f:write(text)
    f:close()

    window:perform_action(
        act.SpawnCommandInNewTab {
            args = {
                get_nvim_path(),
                '+set bufhidden=wipe',
                '+autocmd BufWipeout <buffer> call delete(expand("%:p"))',
                '+normal! G',
                name
            },
            set_environment_variables = {
                FROM_WEZTERM = "1",
            },
        },
        pane
    )
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

local config = wezterm.config_builder()

-- Performance
config.max_fps = 120
config.front_end = "WebGpu"

-- Window decoration
-- config.window_decorations = "RESIZE"
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
}

if windows then
    config.default_prog = { 'pwsh', '-NoLogo' };
    config.prefer_egl = true;
    config.font_size = 10
    config.window_background_opacity = 1.0
    config.front_end = "OpenGL"
end

return config
