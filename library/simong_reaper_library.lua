-- Copyright 2023 Simon Goričar

----
-- GENERAL UTILITIES (that aren't exported)
----

-- Declare the function here so we can use it in `prettyprint_table`.
local prettyprint_any_value

-- Pretty-prints a table.
-- `indentation_level` parameter should be 0 when calling this from user-facing code (used for recursion).
local function prettyprint_table(value, indentation_level)
    local initial_indentation = string.rep(" ", 4 * indentation_level)
    local serialized_str = "{\n"

    indentation_level = indentation_level + 1
    local new_indentation = string.rep(" ", 4 * indentation_level)
    for table_key, table_value in pairs(value) do
        local prettyprinted_key = prettyprint_any_value(table_key)
        local prettyprinted_value = prettyprint_any_value(table_value, indentation_level)

        local prettyprinted_entry = new_indentation .. tostring(prettyprinted_key) .. " = " .. prettyprinted_value .. ",\n"
        serialized_str = serialized_str .. prettyprinted_entry
    end

    serialized_str = serialized_str .. initial_indentation .."}"
    return serialized_str
end

-- Pretty-prints any possible lua value (via type() detection).
-- `indentation_level` parameter should be 0 when calling this from user-facing code (used for recursion).
prettyprint_any_value = function (value, indentation_level)
    local value_type = type(value)

    if value_type == "nil" or value_type == "number" or value_type == "string" or value_type == "boolean" then
        return tostring(value)
    elseif value_type == "table" then
        return prettyprint_table(value, indentation_level)
    elseif value_type == "function" then
        return "<function>"
    elseif value_type == "thread" then
        return "<thread>"
    elseif value_type == "userdata" then
        return "<userdata>"
    end
end



----
-- REAPER GENERAL WRAPPERS AND IMPROVED FUNCTIONS
----

local reaper_library = {}

-- Print the given value into Reaper's console, then print a new line.
function reaper_library.println(value)
    reaper.ShowConsoleMsg(prettyprint_any_value(value, 0) .. "\n")
end

-- Begin an undo block - when the associated `end_undo_block` is called, this will generate an undo point.
function reaper_library.begin_undo_block()
    reaper.Undo_BeginBlock()
end

-- End an undo block - this will generate an undo point if you used `begin_undo_block` previously.
function reaper_library.end_undo_block(action_description)
    reaper.Undo_EndBlock(action_description, -1)
end

function reaper_library.block_ui_refresh()
    reaper.PreventUIRefresh(1)
end

function reaper_library.unblock_ui_refresh()
    reaper.PreventUIRefresh(-1)
end

function reaper_library.get_current_project()
    return reaper.EnumProjects(-1)
end

-- Returns an array of monitoring FX.
-- Array values are table with the following keys:
-- - `real_index` is the real fx index on the master track (as far as Reaper is concerned)
-- - `fx_name` is the monitoring fx name
--
-- NOTE: returned array is 1-based, even though Reaper's indexes are 0-based. This means there is an offset of 1.
function reaper_library.get_all_monitoring_fx()
    local current_project = reaper_library.get_current_project()
    local master_track = reaper.GetMasterTrack(current_project)
    local monitoring_fx_list = {}

    local current_mfx_index = 0
    while true do
        local effective_mfx_index = 0x1000000 + current_mfx_index
        local retval, current_mfx_name = reaper.TrackFX_GetFXName(master_track, effective_mfx_index, "")

        -- Stop scanning when we reach the end of monitoring plugins (retval == false).
        if retval == false then
            break
        end

        -- Add to monitoring fx table.
        monitoring_fx_list[current_mfx_index + 1] = {
            real_index = effective_mfx_index,
            fx_name = current_mfx_name,
        }

        -- We'll check the next index next iteration.
        current_mfx_index = current_mfx_index + 1
    end

    return monitoring_fx_list
end

return reaper_library
