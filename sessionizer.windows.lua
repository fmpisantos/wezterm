local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

local directories = {
    { "D:\\",                   1 },
    { "D:\\src",                1 },
    { "D:\\inst",               1 },
    { "D:\\net-nuget-packages", 1 },
    { "E:\\",                   2 },
    { "~/",                     2 },
}

M.toggle = function(window, pane)
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

        return "powershell -Command \"" .. table.concat(parts, ";\n") .. "\""
    end

    local function get_projects()
        local cmd = build_find_command(directories)
        -- wezterm.log_info(cmd);
        local f = io.popen(cmd)
        local result = f:read("*a")
        f:close()

        local choices = {}
        for dir in result:gmatch("[^\n]+") do
            table.insert(choices, { label = dir, id = dir })
        end
        return choices
    end

    local projects = get_projects()

    window:perform_action(
        act.InputSelector({
            action = wezterm.action_callback(function(win, _, id, label)
                if not id and not label then
                else
                    local workspace = label:match("([^/]+)$"):gsub("%.", "_")

                    win:perform_action(
                        act.SwitchToWorkspace({
                            name = workspace,
                            spawn = { cwd = label }
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

return M
