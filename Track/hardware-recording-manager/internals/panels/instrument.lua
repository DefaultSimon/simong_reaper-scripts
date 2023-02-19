local mod_global = require("global")
local mod_core = require("core")
local mod_base = require("panels.base")

local rtk = require("rtk")

local class = mod_core.libraries.middleclass.class


local module_instrument = {}

--- Represents a single instrument that is registered in the UI.
---
---@class InstrumentPanel: Panel
---@field project ReaperProject Project this instrument panel belongs to.
---@field instrument Instrument The instrument this panel operates on.
---@field panel_root_container rtk.HBox The root panel widget.
--- -- TODO
---
---
local InstrumentPanel = class("InstrumentPanel", mod_base.Panel)

--- Initialize a new UI Instrument: Don't use this method directly in normal code, use `create` instead!
---
---@param reaper_project ReaperProject
---@param instrument Instrument
---@param ui_root_container rtk.HBox
---@param ui_name rtk.Text
---@param ui_midi_in_checkbox rtk.CheckBox
---@param ui_midi_out_checkbox rtk.CheckBox
---@param ui_midi_through_checkbox rtk.CheckBox
---@param ui_audio_in_checkbox rtk.CheckBox
function InstrumentPanel:initialize(
    reaper_project,
    instrument,
    ui_root_container,
    ui_name,
    ui_midi_in_checkbox,
    ui_midi_out_checkbox,
    ui_midi_through_checkbox,
    ui_audio_in_checkbox
)
    self.project = reaper_project
    self.instrument = instrument

    self.panel_root_container = ui_root_container
    self.panel_name_text = ui_name

    self.panel_midi_in_checkbox = ui_midi_in_checkbox
    self.panel_midi_out_checkbox = ui_midi_out_checkbox
    self.panel_midi_through_checkbox = ui_midi_through_checkbox
    self.panel_audio_in_checkbox = ui_audio_in_checkbox
end

--- Create a new Instrument, also creating all required UI elements and setting them up.
---
---@param reaper_project ReaperProject
---@param instrument Instrument
function InstrumentPanel.static:create(
    reaper_project,
    instrument
)
    ---@type rtk.VBox
    local instr_ui_box = rtk.VBox({
        spacing=5,
        stretch=rtk.Box.STRETCH_FULL,
        fillh=true
    })

    ---@type rtk.Text
    local instr_ui_name = instr_ui_box:add(rtk.Text({
        text = instrument.name,
        wrap = rtk.Text.WRAP_NONE,
        textalign = rtk.Widget.TOP,
    }))

    ---@type rtk.CheckBox
    local instr_ui_midi_in_checkbox = instr_ui_box:add(rtk.CheckBox({
        value = rtk.CheckBox.UNCHECKED,
        label = "MIDI IN"
    }))

    ---@type rtk.CheckBox
    local instr_ui_midi_out_checkbox = instr_ui_box:add(rtk.CheckBox({
        value = rtk.CheckBox.UNCHECKED,
        label = "MIDI OUT"
    }))

    ---@type rtk.CheckBox
    local instr_ui_midi_through_checkbox = instr_ui_box:add(rtk.CheckBox({
        value = rtk.CheckBox.UNCHECKED,
        label = "MIDI THROUGH"
    }))

    ---@type rtk.CheckBox
    local instr_ui_audio_in_checkbox = instr_ui_box:add(rtk.CheckBox({
        value = rtk.CheckBox.UNCHECKED,
        label = "AUDIO IN"
    }))

    return self:new(
        reaper_project,
        instrument,
        instr_ui_box,
        instr_ui_name,
        instr_ui_midi_in_checkbox,
        instr_ui_midi_out_checkbox,
        instr_ui_midi_through_checkbox,
        instr_ui_audio_in_checkbox
    )
end

--- Return the root widget of this panel that can be added to the UI (the DOM, if you will).
--- This is used by the PanelManager to add panels to the UI.
---
---@return rtk.HBox
function InstrumentPanel:_get_root_widget()
    return self.panel_root_container
end

--- Called by the PanelManager when it adds the panel to the UI.
---
---@param manager PanelManager
function InstrumentPanel:_setup(manager)
    -- We must always call the superclass implementation of _setup.
    self.class.super:_setup(manager)

    self.panel_midi_in_checkbox.onchange = function(checkbox)
        mod_global.block_ui_refresh()
        self.project:begin_undo_block()
        
        self.instrument:set_midi_in(checkbox.value == rtk.CheckBox.CHECKED)

        self.project:end_undo_block("Script: change MIDI IN state for instrument")
        mod_global.unblock_ui_refresh()
    end

    self.panel_midi_out_checkbox.onchange = function(checkbox)
        mod_global.block_ui_refresh()
        self.project:begin_undo_block()

        self.instrument:set_midi_out(checkbox.value == rtk.CheckBox.CHECKED)

        self.project:end_undo_block("Script: change MIDI OUT state for instrument")
        mod_global.unblock_ui_refresh()
    end

    self.panel_midi_through_checkbox.onchange = function(checkbox)
        mod_global.block_ui_refresh()
        self.project:begin_undo_block()

        self.instrument:set_midi_through(checkbox.value == rtk.CheckBox.CHECKED)

        self.project:end_undo_block("Script: change MIDI THROUGH state for instrument")
        mod_global.unblock_ui_refresh()
    end

    self.panel_audio_in_checkbox.onchange = function(checkbox)
        mod_global.block_ui_refresh()
        self.project:begin_undo_block()

        self.instrument:set_audio_in(checkbox.value == rtk.CheckBox.CHECKED)

        self.project:end_undo_block("Script: change AUDIO IN state for instrument")
        mod_global.unblock_ui_refresh()
    end
end

module_instrument.InstrumentPanel = InstrumentPanel

return module_instrument
