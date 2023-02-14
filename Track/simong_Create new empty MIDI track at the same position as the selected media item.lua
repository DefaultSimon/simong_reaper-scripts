-- @description Create new empty MIDI track at the same position as the selected media item
-- @about
--   This script creates a new empty MIDI track at the same position (and of the same length)
--   as the currently-selected media item. It also unselects the original media item and
--   selects the newly created one.
-- @author Simon Goričar
-- @link https://github.com/DefaultSimon/simong_reaper-scripts
-- @version 1.0.1
-- @changelog
--   - Remove external dependency on the shared library.

---@diagnostic disable: redefined-local

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



-- -- -- -- -- -- --
--  SCRIPT BEGIN  --
-- -- -- -- -- -- --
local current_project = lib.get_current_project()
if current_project == nil then
    return lib.printerrln("Could not get current Reaper project!", true)
end

lib.block_ui_refresh()
lib.begin_project_undo_block(current_project)


-- Find and parse selected media item.
local selected_media_item = reaper.GetSelectedMediaItem(current_project, 0)
-- If no item is selected when this scripts runs, we just exit.
if selected_media_item == nil then
    return
end

local media_track_of_item = reaper.GetMediaItem_Track(selected_media_item)
if media_track_of_item == nil then
    return lib.printerrln("Media item has no parent track?!", true)
end

local retval, media_track_of_item_name = reaper.GetTrackName(media_track_of_item)
if retval ~= true then
    return lib.printerrln("Could not get track name of selected media item.", true)
end

local media_item_position = reaper.GetMediaItemInfo_Value(selected_media_item, "D_POSITION")
local media_item_length = reaper.GetMediaItemInfo_Value(selected_media_item, "D_LENGTH")

-- We're now set to perform the main operation! --
-- Create new empty MIDI item at the same position.
local new_media_item = reaper.CreateNewMIDIItemInProj(media_track_of_item, media_item_position, media_item_position + media_item_length)
local new_media_item_take = reaper.GetActiveTake(new_media_item)

-- Rename its take to be "<track name>"
local retval, _ = reaper.GetSetMediaItemTakeInfo_String(new_media_item_take, "P_NAME", media_track_of_item_name, true)
if retval ~= true then
    return lib.printerrln("Could not set new item's take name.", true)
end

-- Deselect previous media item, select new empty MIDI item.
reaper.SetMediaItemSelected(selected_media_item, false)
reaper.SetMediaItemSelected(new_media_item, true)

-- Create an undo point.
lib.unblock_ui_refresh()
lib.end_project_undo_block(current_project, "Action: Create new empty MIDI track beside selected track")

-- Refresh the arrange view.
reaper.UpdateArrange()
