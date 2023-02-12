-- @description Move selected media items onto child track whose name contains "[STEMS]"
-- @author Simon Goričar
-- @about
--  This script moves the selected media items from the track they are on 
--  (effectively the track the first selected item is on) to the child track
--  whose name contains the phrase "[STEMS]".
--  
--  Part of a personal workflow thing I'm testing: I record a loop, use this action to
--  push the recorded material into a child track that sends to the parent (so I can still hear what I just recorded), 
--  then record a new "overdub" on the original track (but it's just a new item, not a real overdub).
--  
--  If no "[STEMS]"-matching track is found or if no media items are selected, this script does nothing.
--   
--  This makes it easier to separate multiple overdub "chunks" of your material into separate items
--  and name them accordingly.
--  
--  Manual dependencies: please install the following package: 
--  *"Library for common functionality in the simong_reaper-scripts repository"* (same repository).
-- @link https://github.com/DefaultSimon/simong_reaper-scripts
-- @version 1.0.0
-- @changelog
--   Initial version of the script.

-- CONFIGURATION BEGIN --
-- This is the name that must be matched on a child track for the script to do its job.
-- Note that this is actually a pattern, so %-escapes must be done before special characters (these: ^$()%.[]*+-?).
-- See https://www.lua.org/manual/5.3/manual.html#6.4.1 for more info.
local CHILD_FX_MACHING_NAME = "%[STEMS%]"
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

-- Collect selected media items.
local function get_all_selected_media_items()
    local selected_items = {}
    local current_selected_item_index = 0
    while true do
        local selected_item = reaper.GetSelectedMediaItem(current_project, current_selected_item_index)
        if selected_item == nil then
            break
        end

        table.insert(selected_items, selected_item)
        current_selected_item_index = current_selected_item_index + 1
    end

    return selected_items
end

local selected_items = get_all_selected_media_items()

-- If nothing is selected, do nothing.
if #selected_items < 1 then
    return
end

-- Otherwise, get a reference to the track the first media item is on.
local track_of_first_selected_item = reaper.GetMediaItemInfo_Value(selected_items[1], "P_TRACK")
if track_of_first_selected_item == nil then
    return lib.printerrln("Selected media item has no associated track?!", true)
end

-- Returns an array of tracks that are direct children of the parent track.
local function get_all_direct_children_of_track(reaper_project, parent_track)
    -- Quick documentation of GetMediaTrackInfo_Value return values:
    --    1: track has children (doesn't indicate how many; also says nothing about whether it has any parent itself)
    --    0: track is at root and has no children
    --   -1: track has a parent and is NOT the last leaf visually (next track down is NOT a root track) (says nothing about whether it has any children)
    --   -2: track has a parent, no children and is consequently the LAST LEAF (visually, next track down is a root track)
    local track_depth_info = reaper.GetMediaTrackInfo_Value(parent_track, "I_FOLDERDEPTH")
    if track_depth_info == 0 or track_depth_info == -2 then
        return {}
    end

    -- We'll be iterating over consecutive track indexes, so we first get the starting index - the parent track index.
    local current_track_index = reaper.GetMediaTrackInfo_Value(parent_track, "IP_TRACKNUMBER")
    if current_track_index == 0 then
        return lib.printerrln("Given track has no track number!?", true)
    end
    -- Generally, we'd increment this track index by 1 to start checking the next track, 
    -- HOWEVER: for whatever reason, Reaper's GetTrack function wants 0-based track indexes, 
    -- while GetMediaTrackInfo_Value returns 1-based indexes ?!?!

    local direct_children = {}

    -- Check consecutive indexes until we're at the next root track.
    while true do
        local current_track = reaper.GetTrack(reaper_project, current_track_index)
        -- Stop if we reach the end of tracks.
        if current_track == nil then
            break
        end

        local current_track_parent = reaper.GetParentTrack(current_track)
        if current_track_parent == parent_track then
            table.insert(direct_children, current_track)
        end

        
        local has_any_parent = reaper.GetMediaTrackInfo_Value(current_track, "P_PARTRACK") ~= 0

        -- FIXME: This misses and edge case when the `parent_track` is itself not a root track 
        -- (it'll check tracks it doesn't have to, up to the next root).
        if not has_any_parent then
           break
        end

        current_track_index = current_track_index + 1
    end

    return direct_children
end

local direct_children_tracks = get_all_direct_children_of_track(current_project, track_of_first_selected_item)
if #direct_children_tracks == 0 then
    return lib.printerrln("Selected media item track has no children.", true)
end


-- Finds the first matching child track whose name contains [STEMS] (or whatever `CHILD_FX_MACHING_NAME` is).
-- Returns the associated MediaTrack if it finds a match, nil if no track matches.
--
-- `tracks` should be an array of MediaTrack objects.
local function find_first_stem_matching_track_from_array(tracks)
    for _, track in ipairs(direct_children_tracks) do
        local retvalue, track_name = reaper.GetTrackName(track)
        if retvalue == false then
            return lib.printerrln("Could not get track name.", true)
        end

        local matches_stems_track_naming = string.find(track_name, CHILD_FX_MACHING_NAME) ~= nil
        if matches_stems_track_naming then
            return track
        end
    end

    return nil
end

local stem_collection_track = find_first_stem_matching_track_from_array(direct_children_tracks)
-- If no track matches the [STEMS] naming filter, we just stop executing.
if stem_collection_track == nil then
    return
end

-- Move the selected media items onto the stem collection track we just found.
for _, media_item in ipairs(selected_items) do
    local was_ok = reaper.MoveMediaItemToTrack(media_item, stem_collection_track)
    if not was_ok then
        return lib.printerrln("Could not move media item to stem collection track.", true)
    end
end

-- Create an undo point.
lib.unblock_ui_refresh()
lib.end_undo_block("Action: move selected items onto child track named [STEMS].")

-- Refresh the arrange view.
reaper.UpdateArrange()

-- DONE
