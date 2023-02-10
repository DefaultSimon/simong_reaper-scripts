-- Copyright 2023 Simon Goričar
-- 
-- The following is a script that will **toggle bypass** on every monitoring fx that has
-- "[TOGGLEABLE]" in its name.


-- Set of local functions that need to exist before we can modify the path or require anything.
local function add_to_lua_path(path)
    package.path = package.path .. ";" .. path
end

local function get_script_path()
    local info = debug.getinfo(1, "S");
    local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]

    script_path = string.gsub(script_path, "\\", "/")

    return script_path
end

-- Configure lua package path
add_to_lua_path(get_script_path() .. "library/?.lua")

-- Load RTK and the utility library
local lib = require("simong_reaper_library")



-- -- -- -- -- -- --
--  SCRIPT BEGIN  --
-- -- -- -- -- -- --

local monitoring_effects = lib.get_all_monitoring_fx()

-- Now we iterate over all available monitoring fx and, if their name contains "[TOGGLEABLE]",
-- we toggle their bypass state.
local current_project = lib.get_current_project()
local master_track = reaper.GetMasterTrack(current_project)

for _, monitoring_fx in ipairs(monitoring_effects) do
    local is_configured_as_toggleable = string.find(monitoring_fx.fx_name, "%[TOGGLEABLE%]") ~= nil

    if is_configured_as_toggleable == true then
        local is_enabled = reaper.TrackFX_GetEnabled(master_track, monitoring_fx.real_index)
        reaper.TrackFX_SetEnabled(master_track, monitoring_fx.real_index, not is_enabled)
    end
end
