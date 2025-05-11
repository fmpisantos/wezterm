local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

local directories = {
    { "~/Projects/", 2 },
    { "~/.config/",  1 }
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
            local cmd = string.format('find "%s" -mindepth 0 -maxdepth %d -type d', path, maxdepth)
            table.insert(parts, cmd)
        end

        return table.concat(parts, ";\n") .. " 2> /dev/null"
    end

    local function get_projects()
        local cmd = build_find_command(directories)
        local f = io.popen(cmd)
        local result = f:read("*a")
        f:close()

        local choices = {}
        for dir in result:gmatch("[^\n]+") do
            local label = dir
            for _, pair in ipairs(directories) do
                label = label:gsub(expand_path(pair[1]), "")
            end
            if label == "" then
                label = dir
            end
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
