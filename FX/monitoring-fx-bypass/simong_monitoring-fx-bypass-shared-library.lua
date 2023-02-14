--[[
    Minimal library for common functions in the Monitoring FX Bypass package.
]]

local lib = {}

-- -- -- -- -- -- -- -- --
-- INTERNAL UTILITIES   --
--   (not exported)  -- --
-- -- -- -- -- -- -- -- --

-- Declare the function here so we can use it in `prettyprint_any_value`.

--- Pretty-prints a table.
--- `indentation_level` parameter should be 0 when calling this from user-facing code (used for recursion).
---@type fun(value: any, indentation_level?: number): string
local prettyprint_table

--- Pretty-prints any possible lua value (via type() detection).
--- Do not pass the `indentation_level` parameter when calling this from user-facing code (used for recursion).
---
---@param value any
---@param indentation_level? number
---@return string
local function prettyprint_any_value(value, indentation_level)
    indentation_level = indentation_level or 0

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
        local metatable = getmetatable(value)

        if metatable == nil then
            return "<userdata>"
        else
            return "<userdata>: " .. prettyprint_table(getmetatable(value), indentation_level)
        end
    end
end

-- See declaration above for documentation.
prettyprint_table = function (value, indentation_level)
    indentation_level = indentation_level or 0

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



-- -- -- -- -- -- -- --
--  COMMON FUNCTIONS --
--     (exported)    --
-- -- -- -- -- -- -- --


--- Get the current project.
---
--- Returned userdata is of type: `ReaProject`.
---
---@return userdata | nil
function lib.get_current_project()
    return reaper.EnumProjects(-1)
end

--- Print the given `value` into Reaper's console (includes new line at the end).
---
---@param value any
---@return nil
function lib.print(value)
    reaper.ShowConsoleMsg(prettyprint_any_value(value))
end

--- Print the given `value` into Reaper's console (includes new line at the end).
---
---@param value any
---@return nil
function lib.println(value)
    reaper.ShowConsoleMsg(prettyprint_any_value(value) .. "\n")
end

--- Print the given error into Reaper's console after the script finishes.
---
--- If `should_exit` is true, this function does not return and instead **stops the script**.
--- Implementation detail: this is achieved by prepending "!" to ReaScriptError,
--- see ReaScript documentation: https://www.extremraym.com/cloud/reascript-doc/#ReaScriptError
---
---@param value any
---@param should_exit boolean
---@return nil
function lib.printerrln(value, should_exit)
    local exit_prefix
    if should_exit == true then
        exit_prefix = "!"
    else
        exit_prefix = ""
    end

    reaper.ReaScriptError(exit_prefix .. "SCRIPT ERROR: " .. prettyprint_any_value(value) .. "\n")
end


lib.UNDO_STATE_ALL = -1
lib.UNDO_STATE_TRACKCFG = 1
lib.UNDO_STATE_FX = 2
lib.UNDO_STATE_ITEMS = 4
lib.UNDO_STATE_MISCCFG = 8
lib.UNDO_STATE_FREEZE = 16

--- Begin an undo block - when the associated `end_project_undo_block` is called, 
--- this will (or at least should) generate an undo point. As for `flags`, see UNDO_* variables.
---
--- `project` userdata should be of type: `ReaProject`.
---
---@param project userdata
---@return nil
function lib.begin_project_undo_block(project)
    reaper.Undo_BeginBlock2(project)
end

--- End an undo block - this will generate an undo point if you used `begin_project_undo_block` previously.
---
--- `project` userdata should be of type: `ReaProject`.
---
---@param project userdata
---@param action_description string
---@param flags? number
---@return nil
function lib.end_project_undo_block(project, action_description, flags)
    reaper.Undo_EndBlock2(project, action_description, flags or lib.UNDO_STATE_ALL)
end

--- Start blocking the Reaper UI from refreshing.
---
---@return nil
function lib.block_ui_refresh()
    reaper.PreventUIRefresh(1)
end

--- Stop blocking the Reaper UI from refreshing.
---
---@return nil
function lib.unblock_ui_refresh()
    reaper.PreventUIRefresh(-1)
end

--- Returns an array of monitoring FX indexes and names.
---
--- Returned array values are tables with the following keys:
--- - `effective_index` is the real fx index on the master track (as far as Reaper is concerned)
--- - `name` is the monitoring fx name
---
--- NOTE: returned array is 1-based, even though Reaper's indexes are 0-based.
--- This means there is a positive offset of 1
--- (effective fx index of first array element is 0x1000000, not 0x1000001).
---
--- `project` userdata should be of type: `ReaProject`.
---
---@param project userdata
---@return {effective_index: number, name: string}[]
function lib.get_all_monitoring_fx_index_and_names(project)
    local master_track = reaper.GetMasterTrack(project)
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
            effective_index = effective_mfx_index,
            name = current_mfx_name,
        }

        -- We'll check the next index next iteration.
        current_mfx_index = current_mfx_index + 1
    end

    return monitoring_fx_list
end

return lib
