-- @description Create new empty MIDI track at the same position as the selected media item
-- @about
--   This script creates a new empty MIDI track at the same position (and of the same length)
--   as the currently-selected media item.
--  
--   Manual dependencies: please install the following package: 
--   *"Library for common functionality in the simong_reaper-scripts repository"* (same repository).
-- @author Simon Goričar
-- @link https://github.com/DefaultSimon/simong_reaper-scripts
-- @version 1.0.0
-- @changelog
--   Initial version of the script.

-- CONFIGURATION BEGIN --
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
lib.block_ui_refresh()
lib.begin_undo_block()

local current_project = lib.get_current_project()

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
lib.end_undo_block("Action: Create new empty MIDI track beside selected track")

-- Refresh the arrange view.
reaper.UpdateArrange()
