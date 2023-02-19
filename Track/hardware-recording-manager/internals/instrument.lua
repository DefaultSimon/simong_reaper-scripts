local core = require("core")

local any_are_nil = core.utilities.any_are_nil
local class = core.libraries.middleclass.class

local module_instrument = {}

--- Represents a single instrument in association with its MIDI/AUDIO tracks
--- as registered inside the hardware recording manager script.
---
---@class Instrument
local Instrument = class("Instrument")

--- Initialize a new instrument.
---
---@param instrument_name string
---@param reaper_project ReaperProject
---@param root_track MediaTrack
---@param midi_in_track MediaTrack
---@param midi_main_track MediaTrack
---@param midi_out_track MediaTrack
---@param audio_in_track MediaTrack
---@param audio_main_track MediaTrack
function Instrument:initialize(
    instrument_name,
    reaper_project,
    root_track,
    midi_in_track,
    midi_out_track,
    midi_main_track,
    audio_in_track,
    audio_main_track
)
    if any_are_nil(instrument_name, reaper_project, root_track,
                   midi_in_track, midi_out_track, midi_main_track,
                   audio_in_track, audio_main_track) then
        error("Invalid argument(s): all must be non-nil.")
    end

    -- Instrument name (which may be different from the root track name).
    self.name = instrument_name

    -- Associated Reaper project this instrument is in.
    self.project = reaper_project


    -- When enabled:
    --  - MIDI data passes from the "MIDI IN" track to any non-MIDI-OUT track via any configured send,
    --  - the "main MIDI track" is armed.
    --
    -- Usually the "main MIDI track" will have a receive from this track (see `track_midi_main`).
    self.state_midi_in_enabled = false
    -- When enabled, all received MIDI data from all receives except the "MIDI-IN track" receive (`track_midi_in`) are enabled.
    -- Usually, the "main MIDI track" will have a send to this track (see `track_midi_main).
    self.state_midi_out_enabled = false
    -- When enabled, the "MIDI IN" to "MIDI OUT" send is enabled (meaning all received MIDI goes right back to the hardware).
    -- The user must make sure to prevent any weird echo behaviour if they enable this option.
    self.state_midi_through_enabled = false
    -- When enabled:
    --  - audio data passes from the "AUDIO IN" track to any configured send,
    --  - the "main AUDIO track" is armed.
    --
    -- Usually the "main AUDIO track" will have a receive from this track (see `track_audio_main`).
    self.state_audio_in_enabled = false


    -- TODO We could add a prefix the root track name according to the state:
    --      [IOTA] would denote all four states enabled
    --      [xxxx] would denote all four states disabled

    -- The root ("group") track that is associated with the whole hardware instrument.
    self.track_root = root_track

    -- The MIDI IN "pseudo track" that is set to receive MIDI data from the associated hardware instrument.
    -- It's meant to act as a nicer way to patch the instrument MIDI data to wherever else you need it by simply creating a MIDI send.
    -- By default, the "main MIDI track" is the only intended send (see `track_midi_main`).
    self.track_midi_in = midi_in_track
    -- The MIDI OUT "pseudo track" that routes MIDI data to the associated hardware instrument.
    -- It has a hardware MIDI send.
    -- It's meant to act as a nicer way to pass the DAW MIDI data to the hardware instrument by simply creating a MIDI receive.
    self.track_midi_out = midi_out_track
    -- The AUDIO IN "pseudo track" that is set to receive audio data from the associated hardware instrument.
    -- It's meant to act as a nicer way of patching the incoming hardware audio to the relevant tracks for monitoring or recording.
    -- Generally, this track will have an audio send to the "main audio track" (see `track_audio_main`).
    self.track_audio_in = audio_in_track

    -- The MIDI track that acts as the "main midi track" - this is where, by default (and by original design), the MIDI data should be recorded.
    -- This track has two functionalities: 
    -- - when `state_midi_in_enabled == true`, a MIDI receive from the `track_midi_in` track is enabled (receiving all MIDI data from the hardware)
    -- - when `state_midi_out_enabled == true`, a MIDI send to the `track_midi_out` track is enabled (sending all recorded MIDI items to the hardware)
    self.track_midi_main = midi_main_track
    -- The audio track that acts as the "main audio track" - this is where, by default (and by original design), the audio data should be monitored/recorded.
    -- When `state_audio_in_enabled == true`, an audio receive gets enabled and this track receives the audio signal from the hardware instrument.
    self.track_audio_main = audio_main_track
end

--- Given a list of tracks that should match the MIDI IN, MIDI OUT, MIDI, AUDIO IN and AUDIO tracks,
--- find the matching tracks and create the Instrument.
---
---@param instrument_name string
---@param reaper_project ReaperProject
---@param root_instrument_track MediaTrack
---@param track_list_to_match_from MediaTrack[]
function Instrument.static:find_matching_tracks_and_create(
    instrument_name,
    reaper_project,
    root_instrument_track,
    track_list_to_match_from
)
    -- Find MIDI IN, MIDI OUT, MIDI, AUDIO IN and AUDIO tracks.
    ---@type MediaTrack | nil
    local track_midi_in = nil
    ---@type MediaTrack | nil
    local track_midi_out = nil
    ---@type MediaTrack | nil
    local track_midi_main = nil
    ---@type MediaTrack | nil
    local track_audio_in = nil
    ---@type MediaTrack | nil
    local track_audio_main = nil

    for child_index = 1, #track_list_to_match_from do
        local child_track = track_list_to_match_from[child_index]
        local child_track_name = child_track:get_name()

        if string.find(child_track_name, "MIDI IN") ~= nil then
            track_midi_in = child_track
        elseif string.find(child_track_name, "MIDI OUT") ~= nil then
            track_midi_out = child_track
        elseif string.find(child_track_name, "MIDI") ~= nil then
            track_midi_main = child_track
        elseif string.find(child_track_name, "AUDIO IN") ~= nil then
            track_audio_in = child_track
        elseif string.find(child_track_name, "AUDIO") ~= nil then
            track_audio_main = child_track
        end
    end

    if track_midi_in == nil then
        error("Could not find MIDI IN track.")
    elseif track_midi_out == nil then
        error("Could not find MIDI OUT track.")
    elseif track_midi_main == nil then
        error("Could not find main MIDI track.")
    elseif track_audio_in == nil then
        error("Could not find AUDIO IN track.")
    elseif track_audio_main == nil then
        error("Could not find main AUDIO track.")
    end

    return self:new(
        instrument_name,
        reaper_project,
        root_instrument_track,
        track_midi_in,
        track_midi_out,
        track_midi_main,
        track_audio_in,
        track_audio_main
    )
end

--- Apply
function Instrument:apply_all_states()
    self.project:begin_undo_block()

    self:set_midi_in(self.state_midi_in_enabled)
    self:set_midi_out(self.state_midi_out_enabled)
    self:set_midi_through(self.state_midi_through_enabled)
    self:set_audio_in(self.state_audio_in_enabled)

    self.project:end_undo_block("Script: apply all instrument states")
end

--- Set the instrument MIDI IN state.
--- When enabled, this will:
---  - unmute any MIDI sends from the MIDI IN track (except the one going to the MIDI OUT track),
---  - arm the main MIDI track.
---
---@param state boolean
function Instrument:set_midi_in(state)
    self.state_midi_in_enabled = state

    -- Unmute/Mute all but the MIDI OUT send.
    local sends_count = self.track_midi_in:get_track_send_count()
    for send_index = 0, sends_count - 1 do
        -- Make sure to ignore the MIDI OUT track.
        local send_target = self.track_midi_in:get_track_send_destination(send_index)
        if not send_target:is_same_track_as(self.track_midi_out) then
            self.track_midi_in:set_track_send_mute(send_index, not state)
        end
    end

    -- Arm/Unarm main MIDI track.
    self.track_midi_main:set_armed(state)
end

--- Set the instrument MIDI OUT state.
--- When enabled, this will unmute any MIDI receives on the MIDI OUT track (except the one coming from the MIDI IN track).
---
---@param state boolean
function Instrument:set_midi_out(state)
    -- Unmute/Mute all but the MIDI IN receive.
    local receives_count = self.track_midi_out:get_track_receive_count()
    for receive_index = 0, receives_count - 1 do
        self.track_midi_out:set_track_receive_mute(receive_index, not state)
    end
end

--- Set the instrument MIDI THROUGH state.
--- When enabled, this will unmute the MIDI send going from the MIDI IN to the MIDI OUT track.
--- The user must make sure to prevent any unwanted echo behaviour themselves if they enable this option.
---
---@param state boolean
function Instrument:set_midi_through(state)
    -- Enable MIDI send from MIDI IN to MIDI OUT tracks.
    local sends_count = self.track_midi_in:get_track_send_count()
    for send_index = 0, sends_count - 1 do
        -- Make sure we only set the mute on the MIDI OUT send.
        local send_target = self.track_midi_in:get_track_send_destination(send_index)
        if send_target:is_same_track_as(self.track_midi_out) then
            self.track_midi_in:set_track_send_mute(send_index, not state)
        end
    end
end

--- Set the instrument AUDIO IN state.
--- When enabled, this will:
---  - unmute any audio sends going from the AUDIO IN track,
---  - arm the main AUDIO track.
---
---@param state boolean
function Instrument:set_audio_in(state)
    -- Unmute/Mute all sends on the AUDIO IN track.
    local sends_count = self.track_audio_in:get_track_send_count()
    for send_index = 0, sends_count - 1 do
        self.track_audio_in:set_track_send_mute(send_index, not state)
    end

    -- Arm/Unarm main audio track.
    self.track_audio_main:set_armed(state)
end

--- Get a short, four character description of the instrument state:
---  - `ITOA` denotes all four states enabled (MIDI IN, MIDI THROUGH, MIDI OUT, AUDIO IN),
---  - `xxxx` denotes all four states disabled.
function Instrument:get_short_state_string()
    local state_chars = {}

    if self.state_midi_in_enabled then
        table.insert(state_chars, "I")
    else
        table.insert(state_chars, "x")
    end

    if self.state_midi_through_enabled then
        table.insert(state_chars, "T")
    else
        table.insert(state_chars, "x")
    end

    if self.state_midi_out_enabled then
        table.insert(state_chars, "O")
    else
        table.insert(state_chars, "x")
    end

    if self.state_audio_in_enabled then
        table.insert(state_chars, "A")
    else
        table.insert(state_chars, "x")
    end

    return table.concat(state_chars, "")
end

function Instrument:__tostring()
    return "<Instrument" ..
        " name=\"" .. self.name .. "\"" ..
        " state=" .. self:get_short_state_string() ..
        " track_midi_in=" .. self.track_midi_in:__tostring() ..
        " track_midi_out=" .. self.track_midi_out:__tostring() ..
        " track_midi_main=" .. self.track_midi_main:__tostring() ..
        " track_audio_in=" .. self.track_audio_in:__tostring() ..
        " track_audio_main=" .. self.track_audio_main:__tostring() ..
        ">"
end

module_instrument.Instrument = Instrument

return module_instrument
