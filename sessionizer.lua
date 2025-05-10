local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

local directories = {
    { "~/Projects/", 3 },
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

        -- Process the result into a table of choices for InputSelector
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
                    wezterm.log_info("Cancelled")
                else
                    wezterm.log_info("Selected " .. label)
                    local workspace = label:match("([^/]+)$"):gsub("%.", "_")

                    -- -- Check if mux is available and get workspace
                    -- local mux = wezterm.mux
                    -- if mux then
                    --     local existing = window.get_workspace(workspace)
                    --
                    --     if not existing then
                    --         mux.spawn_window({
                    --             workspace = workspace,
                    --             cwd = label,
                    --         })
                    --     end

                    win:perform_action(
                        act.SwitchToWorkspace({
                            name = workspace,
                            spawn = { cwd = label }
                        }),
                        pane
                    )
                    -- else
                    --     wezterm.log_error("mux not available")
                    -- end
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
