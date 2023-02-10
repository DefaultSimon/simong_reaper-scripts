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
local function add_to_lua_path(path)
    package.path = package.path .. ";" .. path
end

local function get_script_path()
    local info = debug.getinfo(1, "S");
    local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]

    script_path = string.gsub(script_path, "\\", "/")

    return script_path
end
-- SCRIPT BASICS END --


-- LIBRARIES BEGIN --
-- Configure lua package path
add_to_lua_path(get_script_path() .. "../Functions/?.lua")

-- Load RTK and the utility library
local lib = require("simong_common")
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
