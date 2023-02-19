--- Extend the `package.path` variable to contain an additional path.
---
---@param path string
local function add_to_lua_path(path)
    package.path = package.path .. ";" .. path
end

--- Remove all occurences of `path` from the lua `package.path`.
---
---@param path string
local function remove_from_lua_path(path)
    ---@type string[]
    local filtered_path = {}

    for path_item in string.gmatch(package.path, "([^;]+)") do
        if path_item ~= path then
            table.insert(filtered_path, path_item)
        end
    end

    package.path = table.concat(filtered_path, ";")
end

--- Return the directory this script resides in. Slashes are always forward-slashes, even on Windows.
---
---@return string
local function get_script_path()
    local info = debug.getinfo(1, "S");
    local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]

    script_path = string.gsub(script_path, "\\", "/")

    return script_path
end



-- We only modify `package.path` temporarily so we can import our modules.
local temporary_lua_path_extension = get_script_path() .. "/?.lua"
local temporary_lua_path_extension_2 = get_script_path() .. "/?/init.lua"

add_to_lua_path(temporary_lua_path_extension)
add_to_lua_path(temporary_lua_path_extension_2)

local full_internals_library = {
    core = require("core"),
    global = require("global"),
    track = require("track"),
    project = require("project"),
    instrument = require("instrument"),
    ui = require("ui"),
    panels = require("panels"),
}

remove_from_lua_path(temporary_lua_path_extension_2)
remove_from_lua_path(temporary_lua_path_extension)

return full_internals_library
