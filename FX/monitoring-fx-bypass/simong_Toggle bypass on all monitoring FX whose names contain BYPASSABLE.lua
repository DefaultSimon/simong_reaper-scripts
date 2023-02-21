-- @description Toggle bypass on all monitoring FX whose names contain "[BYPASSABLE]"
-- @author Simon Goričar
-- @about
--   This script will *toggle bypass* all monitoring FX whose names contain the phrase "[BYPASSABLE]".
-- @link https://github.com/DefaultSimon/simong_reaper-scripts
-- @noindex



--[[
    CONFIGURATION BEGIN
]]
-- This is the name that must be matched on monitoring FX for the script to do its job.
-- Note that this is actually a pattern, so %-escapes must be done before special characters (these: ^$()%.[]*+-?).
-- See https://www.lua.org/manual/5.3/manual.html#6.4.1 for more info.
local MONITORING_FX_MATCHING_NAME = "%[BYPASSABLE%]"
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
local lib = require_with_feedback(
    "simong_monitoring-fx-bypass-shared-library",
    "Missing shared library files: please reinstall the entire \"Monitoring FX Bypass scripts\" package."
)

--[[
    LIBRARY IMPORTS END
]]



-- -- -- -- -- -- --
--  SCRIPT BEGIN  --
-- -- -- -- -- -- --
local current_project = lib.get_current_project()
if current_project == nil then
    return lib.printerrln("Could not get current Reaper project!", true)
end

lib.block_ui_refresh()
lib.begin_project_undo_block(current_project)


local monitoring_effects = lib.get_all_monitoring_fx_index_and_names(current_project)

-- Now we iterate over all available monitoring fx and, if their name contains 
-- the configured string (`MONITORING_FX_MATCHING_NAME`), we toggle their bypass state.
local master_track = reaper.GetMasterTrack(current_project)

for _, monitoring_fx in ipairs(monitoring_effects) do
    local is_configured_as_toggleable = string.find(monitoring_fx.name, MONITORING_FX_MATCHING_NAME) ~= nil

    if is_configured_as_toggleable == true then
        local is_enabled = reaper.TrackFX_GetEnabled(master_track, monitoring_fx.effective_index)
        reaper.TrackFX_SetEnabled(master_track, monitoring_fx.effective_index, not is_enabled)
    end
end


-- Create an undo point.
lib.unblock_ui_refresh()
lib.end_project_undo_block(current_project, "Action: Toggle bypass on all monitoring FX whose names contain [BYPASSABLE]")
