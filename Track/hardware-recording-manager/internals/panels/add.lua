local mod_core = require("core")
local mod_track = require("track")
local mod_instrument = require("instrument")
local mod_panel_base = require("panels.base")
local mod_panel_instrument = require("panels.instrument")

local rtk = require("rtk")

local class = mod_core.libraries.middleclass.class


local module_add = {}

--- A panel containing a plus button that triggers the "New Instrument" panel.
---
---@class PlusButtonPanel: Panel
local PlusButtonPanel = class("NewInstrumentPanel", mod_panel_base.Panel)

--- Initialize a new plus button panel.
--- DO NOT use this method for normal initialization from scratch, use `create` instead.
---
---@param reaper_project ReaperProject
---@param panel_root rtk.VBox
---@param panel_add_button rtk.Button
function PlusButtonPanel:initialize(
    reaper_project,
    panel_root,
    panel_add_button
)
    self.project = reaper_project

    self.panel_root = panel_root
    self.panel_add_button = panel_add_button
end

--- Create a new plus button panel.
--- This creates and adds all the UI elements required to the main panel container.
---
---@param reaper_project ReaperProject
---@return PlusButtonPanel
function PlusButtonPanel.static:create(
    reaper_project
)
    ---@type rtk.VBox
    local panel_root_box = rtk.VBox({
        stretch = rtk.Box.STRETCH_FULL,
        fillh = true,
    })

    ---@type rtk.Button
    local panel_add_button = panel_root_box:add(rtk.Button({
        -- TODO Add proper icon instead of label.
        label = "+"
    }))

    return self:new(reaper_project, panel_root_box, panel_add_button)
end

--- Return the root widget of this panel that can be added to the UI (the DOM, if you will).
--- This is used by the PanelManager to add panels to the UI.
---
---@return rtk.VBox
function PlusButtonPanel:_get_root_widget()
    return self.panel_root
end

--- Called by the PanelManager when it adds the panel to the UI.
---
---@param manager PanelManager
function PlusButtonPanel:_setup(manager)
    -- We must always call the superclass implementation of _setup.
    self.class.super:_setup(manager)


    ---@param button rtk.Button
    ---@param event rtk.Event
    self.panel_add_button.onclick = function(button, event)
        ---@type MediaTrack | nil
        local selected_track = mod_track.MediaTrack:get_currently_selected(self.project)
        if selected_track == nil then
            return
        end

        ---@type MediaTrackTree
        local track_tree = mod_track.MediaTrackTree:generate_from_track(selected_track)
        local direct_children = track_tree:get_direct_children_tracks()

        ---@type boolean, Instrument | string
        local was_ok, instrument = pcall(
            function ()
                return mod_instrument.Instrument:find_matching_tracks_and_create(
                    selected_track:get_name(),
                    self.project,
                    selected_track,
                    direct_children
                )
            end
        )
        if not was_ok then
            error("Errored while creating instruments.")
        end

        instrument:apply_all_states()

        ---@type InstrumentPanel
        local instrument_ui = mod_panel_instrument.InstrumentPanel:create(self.project, instrument)

        self.panel_manager:add_panel(
            instrument_ui,
            self.panel_manager:get_panel_count()
        )
    end
end

module_add.PlusButtonPanel = PlusButtonPanel

return module_add
