--[[
    CONFIGURATION BEGIN
]]

--[[ 
    CONFIGURATION END
]]



--[[
    SCRIPT ESSENTIALS BEGIN
    
    Set of local functions that help configure lua path and require other code.
]]

--- Extend the `package.path` variable to contain one additional path.
---
---@param path string
local function add_to_lua_path(path)
    package.path = package.path .. ";" .. path
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

--- A fancier `require` with optional specific error messages 
--- (e.g. "go there and install that missing library").
---
---@param module_path string
---@param message_on_error? string
---@return any
local function require_with_feedback(module_path, message_on_error)
    local was_imported, imported_module = pcall(require, module_path)

    if was_imported then
        return imported_module
    else
        local final_error_message
        if message_on_error == nil then
            final_error_message = "Could not import module: " .. tostring(module_path)
        else
            final_error_message = tostring(message_on_error)
        end

        reaper.ShowMessageBox(final_error_message, "ReaScript Import Error", 0)

        -- Terminates the script.
        reaper.ReaScriptError("!Errored while trying to load a module. Please follow the instructions you just saw in the previous message.")
    end
end

--[[
    SCRIPT ESSENTIALS END
]]



--[[
    LIBRARY IMPORTS BEGIN
]]

add_to_lua_path(get_script_path() .. "/?.lua")
-- TODO Add your `require_with_feedback` calls here.

--[[
    LIBRARY IMPORTS END
]]


