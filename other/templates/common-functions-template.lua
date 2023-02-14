--[[
    COMMON FUNCTIONS FOR THIS SCRIPT
]]
local lib = {}

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

    reaper.ReaScriptError(exit_prefix .. "SCRIPT ERROR: " .. tostring(value) .. "\n")
end

--- Get the current project.
---
--- Returned userdata is of type: `ReaProject`.
---
---@return userdata | nil
function lib.get_current_project()
    return reaper.EnumProjects(-1)
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

--[[
    END OF COMMON FUNCTIONS FOR THIS SCRIPT
]]
