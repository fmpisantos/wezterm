local wezterm = require("wezterm")
local constants = require "constants"
local act = wezterm.action

local M = {}

M.toggle = function(window, pane, windows)
    local function expand_path(path)
        return path:gsub("^~", os.getenv("HOME"))
    end

    local function build_find_command(dirs)
        local parts = {}

        for _, entry in ipairs(dirs) do
            local path = expand_path(entry[1])
            local maxdepth = entry[2]
            local cmd
            if windows then
                cmd = string.format(
                    "Get-ChildItem -Path '%s' -Recurse -Directory -Depth %d | Select-Object -ExpandProperty FullName",
                    path, maxdepth
                )
            else
                cmd = string.format('find "%s" -mindepth 0 -maxdepth %d -type d', path, maxdepth)
            end
            table.insert(parts, cmd)
        end

        if windows then
            return "powershell -Command \"" .. table.concat(parts, " ; ") .. "\""
        end
        return table.concat(parts, ";\n") .. " 2> /dev/null"
    end

    local function get_projects()
        local cmd = build_find_command(constants.directories)
        local f = io.popen(cmd)
        local result = f:read("*a")
        f:close()

        local choices = {}
        local choices_labels = {}
        for dir in result:gmatch("[^\n]+") do
            local label = dir
            for _, pair in ipairs(constants.directories) do
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

return M
