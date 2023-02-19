local core = require("core")

local class = core.libraries.middleclass.class
local number_to_boolean = core.utilities.number_to_boolean
local boolean_to_number = core.utilities.boolean_to_number

local module_track = {}

--[[
    MediaTrack class
    (an abstraction over the native MediaTrack userdata type)
]]


--- Describes a media track in a project.
--- It's essentially just a wrapper around the native MediaTrack userdata type provided
--- by Reaper. The additional functionality comes from the fact that you can now operate
--- with media tracks slightly more in an object-oriented fashion.
---
---@class MediaTrack
local MediaTrack = class("MediaTrack")


--- Initialize a new MediaTrack from the given `MediaTrack userdata` reference.
---
---@param reaper_project ReaperProject
---@param reaper_track userdata
function MediaTrack:initialize(reaper_project, reaper_track)
    self.project = reaper_project
    self.track = reaper_track
end


--- Get the master track of the provided Reaper project.
---
---@param project ReaperProject
---@return MediaTrack
function MediaTrack.static:get_master_track(project)
    local master_track = reaper.GetMasterTrack(project.project)
    return self(project, master_track)
end

--- Get the track by its (0-based) index. Can not return the master track.
---
---@param project ReaperProject
---@param track_index number
---@return MediaTrack | nil
function MediaTrack.static:get_from_track_index(project, track_index)
    if track_index < -1 then
        error("Track number can't be negative (other than -1)!")
    end

    local track_reference = reaper.GetTrack(project.project, track_index)
    if track_reference == nil then
        return nil
    end

    return self(project, track_reference)
end

--- Get the currently selected track, if any.
--- If multiple tracks are selected, this returns the first one.
---
---@param project ReaperProject
---@return MediaTrack | nil
function MediaTrack.static:get_currently_selected(project)
    if project == nil then
        error("Missing parameter: project!")
    end

    local selected_track = reaper.GetSelectedTrack2(project, 0, true)
    if selected_track == nil then
        return nil
    end

    return self(project, selected_track)
end


--- Get the media track's folder state.
--- Return value meanings:
---   - 0 means the track is not a folder and has no children.
---   - 1 means the track is a folder - has children (could still be in a folder itself).
---   - negative numbers mean "how many folders this track closes", 
---     i.e. the difference in depth between itself and the next track.
---
--- Source: https://forums.cockos.com/showthread.php?t=238789
---
---@return number
function MediaTrack:get_folder_state()
    return reaper.GetMediaTrackInfo_Value(self.track, "I_FOLDERDEPTH")
end


--- Get the number of the track. Note that the returned index is 0-based (conversion is done)
---
--- `-1` means the master track, `>= 0` means the track index.
--- `nil` means track has no index.
---
---@return number | nil
function MediaTrack:get_track_index()
    local track_number = reaper.GetMediaTrackInfo_Value(self.track, "IP_TRACKNUMBER")
    if track_number == 0 then
        return nil
    elseif track_number == -1 then
        return -1
    else
        return track_number - 1
    end
end

--- Get the track name (defaults to "Track X" when the track does not have a name, where X is the 1-based track number).
---
---@return string
function MediaTrack:get_name()
    local retval, track_name = reaper.GetTrackName(self.track)
    if retval ~= true then
        error("Failed while retrieving track name.")
    else
        return track_name
    end
end

--- Get the track arming state.
---
---@return boolean
function MediaTrack:get_armed()
    ---@type number
    local record_arm_number = reaper.GetMediaTrackInfo_Value(self.track, "I_RECARM")

    if record_arm_number == 0 then
        return false
    else
        return true
    end
end

--- Arm or unarm a track.
---
---@param is_armed boolean
function MediaTrack:set_armed(is_armed)
    local is_armed_num = boolean_to_number(is_armed)

    ---@type boolean
    local set_ok = reaper.SetMediaTrackInfo_Value(self.track, "I_RECARM", is_armed_num)
    if not set_ok then
        error("Could not set track arm state.")
    end
end

--- Get number of track sends (hardware sends not included).
---
---@return number
function MediaTrack:get_track_send_count()
    return reaper.GetTrackNumSends(self.track, 0)
end

--- Get name of track send (name of track it's sending to) of the associated send index (0-based).
---
---@param send_index number
---@return string | nil
function MediaTrack:get_track_send_name(send_index)
    local existing_hardware_send_count = self:get_hardware_audio_send_count()

    ---@type boolean, string
    local send_exists, send_name = reaper.GetTrackSendName(self.track, send_index, existing_hardware_send_count + send_index)
    if not send_exists then
        return nil
    else
        return send_name
    end
end


--- Get the destination track of the track send on the given index.
---
---@param send_index number
---@return MediaTrack
function MediaTrack:get_track_send_destination(send_index)
    ---@type userdata
    local destination_track = reaper.GetTrackSendInfo_Value(self.track, 0, send_index, "P_DESTTRACK")
    local reaper_project = reaper.GetMediaTrackInfo_Value(destination_track, "P_PROJECT")

    return MediaTrack:new(reaper_project, destination_track)
end

--- Get mute state of track send (indexes are 0-based).
---
---@param send_index number
---@return boolean
function MediaTrack:get_track_send_mute(send_index)
    ---@type number
    local is_muted_number = reaper.GetTrackSendInfo_Value(self.track, 0, send_index, "B_MUTE")
    return number_to_boolean(is_muted_number)
end

--- Set track send mute (send indexes are 0-based).
---
---@param send_index number
---@param mute_state boolean
function MediaTrack:set_track_send_mute(send_index, mute_state)
    local mute_state_num = boolean_to_number(mute_state)

    local set_ok = reaper.SetTrackSendInfo_Value(self.track, 0, send_index, "B_MUTE", mute_state_num)
    if not set_ok then
        error("Could not set track send mute.")
    end
end

--- Get number of track receives.
---
---@return number
function MediaTrack:get_track_receive_count()
    return reaper.GetTrackNumSends(self.track, -1)
end

--- Get the name of track receive (name of track that is sending) of the associated receive index (0-based).
---
---@param receive_index number
---@return string | nil
function MediaTrack:get_track_receive_name(receive_index)
    ---@type boolean, string
    local receive_exists, receive_name = reaper.GetTrackReceiveName(self.track, receive_index)
    if not receive_exists then
        return nil
    else
        return receive_name
    end
end

--- Get the source (sending) track of the track receive on the given index.
---
---@param receive_index number
---@return MediaTrack
function MediaTrack:get_track_receive_source(receive_index)
    ---@type userdata
    local source_track = reaper.GetTrackSendInfo_Value(self.track, -1, receive_index, "P_SRCTRACK")
    local reaper_project = reaper.GetMediaTrackInfo_Value(source_track, "P_PROJECT")

    return MediaTrack:new(reaper_project, source_track)
end

--- Get mute state of track receive (indexes are 0-based).
---
---@param receive_index number
---@return boolean
function MediaTrack:get_track_receive_mute(receive_index)
    local is_muted_number = reaper.GetTrackSendInfo_Value(self.track, -1, receive_index, "B_MUTE")
    return number_to_boolean(is_muted_number)
end

--- Set track receive mute (receive indexes are 0-based).
---
---@param receive_index number
---@param mute_state boolean
function MediaTrack:set_track_receive_mute(receive_index, mute_state)
    local mute_state_num = boolean_to_number(mute_state)

    local set_ok = reaper.SetTrackSendInfo_Value(self.track, -1, receive_index, "B_MUTE", mute_state_num)
    if not set_ok then
        error("Could not set track receive mute.")
    end
end

--- Get number of hardware sends.
---
---@return number
function MediaTrack:get_hardware_audio_send_count()
    return reaper.GetTrackNumSends(self.track, 1)
end

--- Check whether the track matches another instance of a MediaTrack.
---
---@param other_media_track MediaTrack
---@return boolean
function MediaTrack:is_same_track_as(other_media_track)
    return self.track == other_media_track.track
end

function MediaTrack:__tostring()
    return "<MediaTrack name=\"" .. self:get_name() .. "\" index=" .. tostring(self:get_track_index()) .. ">"
end

-- TODO A lot of methods are missing, but that's intentional - I add methods when I need them.

module_track.MediaTrack = MediaTrack
--[[
    END OF MediaTrack class
]]



--[[
    MediaTrackTree class
]]


--- Describes a tree of parent-child-related tracks. Note that this does not track the reordering 
--- of tracks in any way, it is simply a snapshot of the track tree at a point in time.
---
---@class MediaTrackTree
local MediaTrackTree = class("MediaTrackTree")

---@param root_track MediaTrack
---@param children_tracks MediaTrackTree[]
function MediaTrackTree:initialize(root_track, children_tracks)
    self.track =  root_track
    self.children = children_tracks
end


--- Build a track tree, given the root track.
---
--- `root_media_track` userdata should be of type `MediaTrack`.
---
---@param root_track MediaTrack
function MediaTrackTree.static:generate_from_track(root_track)
    local project = root_track.project

    local root_track_folder_state = root_track:get_folder_state()
    -- If the track is not a folder, we exit early and return a leaf - a node without any children.
    if root_track_folder_state <= 0 then
        return MediaTrackTree:new(root_track, {})
    end

    local current_track_number = root_track:get_track_index()
    if current_track_number == -1 then
        error("Can't generate track tree from master track.")
    end

    --- Return values: 
    ---  - subtree generated from the track
    ---  - next unparsed track index
    ---  - "overshot depth" (when negative - e.g. when a track ends several depths worth of folders; otherwise 0)
    ---
    ---@param track MediaTrack
    ---@return MediaTrackTree, number, number
    local function _construct_tree_recursively(track)
        local track_index = track:get_track_index()
        if track_index == nil then
            error("Can't get track index from track.")
        end

        local next_index = track_index + 1
        local track_folder_state = track:get_folder_state()

        if track_folder_state == 1 then
            -- Track creates a new folder, so we should start iterating and building a list of subtrees.

            ---@type MediaTrack
            local next_track = MediaTrack:get_from_track_index(project, next_index)

            local depth_overshoot = 0

            ---@type MediaTrackTree[]
            local children_list = {}

            while next_track ~= nil do
                local local_subtree, next_index_from_child, child_depth_overshoot = _construct_tree_recursively(next_track)
                
                table.insert(children_list, local_subtree)

                next_index = next_index_from_child
                next_track = MediaTrack:get_from_track_index(project, next_index)

                if child_depth_overshoot < 0 then
                    depth_overshoot = child_depth_overshoot + 1
                    break
                end
            end
            
            ---@type MediaTrackTree
            local full_subtree = MediaTrackTree:new(track, children_list)
            return full_subtree, next_index, depth_overshoot
            
        else
            -- Track has no children, so we just return it + an empty subtree.

            ---@type MediaTrackTree
            local empty_subtree = MediaTrackTree:new(track, {})
            return empty_subtree, track_index + 1, track_folder_state
        end
    end

    local track_tree, _, _ = _construct_tree_recursively(root_track)
    return track_tree
end

--- Return a list of direct children tracks.
---
---@return MediaTrack[]
function MediaTrackTree:get_direct_children_tracks()
    ---@type MediaTrack[]
    local direct_children = {}

    for _, child in ipairs(self.children) do
        table.insert(direct_children, child.track)
    end

    return direct_children
end

--- Return a list of all descentant tracks.
---
---@return MediaTrack[]
function MediaTrackTree:get_all_descendant_tracks()
    ---@type MediaTrack[]
    local all_descendants = {}

    ---@type MediaTrackTree[]
    local search_stack = {self}

    while #search_stack > 0 do
        -- Pop last item off the search stack.
        local last_item = search_stack[#search_stack]
        search_stack[#search_stack] = nil

        if #last_item.children > 0 then
            for _, child_tree in ipairs(last_item.children) do
                table.insert(all_descendants, child_tree.track)
                table.insert(search_stack, child_tree)
            end
        end
    end
    
    return all_descendants
end

--- Convert the media track tree into a human-friendly string representation.
---
---@return string
function MediaTrackTree:__tostring()
    ---@param tree MediaTrackTree
    ---@param indentation_level number
    local function format_tree_recursively(tree, indentation_level)
        local indentation = string.rep(" ", 2 * indentation_level)
        local header = "<MediaTrackTree track=\"" .. tree.track:get_name() .. "\">"

        ---@type string[]
        local formatted_subtrees = {}

        if #tree.children > 0 then
            for _, value in ipairs(tree.children) do
                local formatted_subtree = format_tree_recursively(value, indentation_level + 1)
                table.insert(formatted_subtrees, formatted_subtree)
            end
        end

        local subtrees = table.concat(formatted_subtrees, "\n")
        if #formatted_subtrees > 0 then
            subtrees = "\n" .. subtrees
        end

        return indentation .. header .. subtrees
    end

    return format_tree_recursively(self, 0)
end


module_track.MediaTrackTree = MediaTrackTree
--[[
    END OF MediaTrackTree class
]]

return module_track
