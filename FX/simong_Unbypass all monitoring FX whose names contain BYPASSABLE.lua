-- @description Unbypass all monitoring FX whose names contain "[BYPASSABLE]"
-- @author Simon Goričar
-- @about
--   This script will *unbypass* all monitoring FX whose names contain the phrase "[BYPASSABLE]".
-- @link https://github.com/DefaultSimon/simong_reaper-scripts
-- @noindex


-- CONFIGURATION BEGIN --
-- This is the name that must be matched on monitoring FX for the script to do its job.
-- Note that this is actually a pattern, so %-escapes must be done before special characters (these: ^$()%.[]*+-?).
-- See https://www.lua.org/manual/5.3/manual.html#6.4.1 for more info.
local MONITORING_FX_MATCHING_NAME = "%[BYPASSABLE%]"
-- CONFIGURATION END --


-- SCRIPT BASICS BEGIN --
-- Set of local functions that must exist for us to be able to configure lua path and import libraries.

-- Extend the `package.path` variable to contain one additional path.
local function add_to_lua_path(path)
    package.path = package.path .. ";" .. path
end

-- Return the directory this script resides in. Slashes are always forward-slashes, even on Windows.
local function get_script_path()
    local info = debug.getinfo(1, "S");
    local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]

    script_path = string.gsub(script_path, "\\", "/")

    return script_path
end

-- A fancier `require` with optional specific error messages (e.g. "go there and install that missing library").
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
-- SCRIPT BASICS END --


-- LIBRARIES BEGIN --
-- Extend the lua path to we can load any modules from the `Functions` directory.
add_to_lua_path(get_script_path() .. "../Functions/?.lua")
-- Load the shared library.
local lib = require_with_feedback(
    "simong_Shared Library",
    "Missing shared library package: please install the \"Shared library for common functionality in the \z
    simong_reaper-scripts repository\" package via ReaPack (same repository)."
)
-- LIBRARIES END --


-- -- -- -- -- -- --
--  SCRIPT BEGIN  --
-- -- -- -- -- -- --

local monitoring_effects = lib.get_all_monitoring_fx()

-- Now we iterate over all available monitoring fx and, if their name contains 
-- the configured string (`MONITORING_FX_MATCHING_NAME`), we enable bypass on them.
local current_project = lib.get_current_project()
local master_track = reaper.GetMasterTrack(current_project)

for _, monitoring_fx in ipairs(monitoring_effects) do
    local is_configured_as_toggleable = string.find(monitoring_fx.fx_name, MONITORING_FX_MATCHING_NAME) ~= nil

    if is_configured_as_toggleable == true then
        local is_enabled = reaper.TrackFX_GetEnabled(master_track, monitoring_fx.real_index)
        if not is_enabled then
            reaper.TrackFX_SetEnabled(master_track, monitoring_fx.real_index, true)
        end
    end
end
