local rtk = require("rtk")

--[[
    Typed RTK classes (so they show up in autocompletion)
]]
---@class rtk.Window
local Window = rtk.Window
---@class rtk.HBox
local HBox = rtk.HBox
---@class rtk.VBox
local VBox = rtk.VBox
---@class rtk.Button
local Button = rtk.Button
---@class rtk.Text
local Text = rtk.Text
---@class rtk.CheckBox
local CheckBox = rtk.CheckBox
---@class rtk.Widget
local Widget = rtk.Widget
---@class rtk.Box
local Box = rtk.Box
---@class rtk.Event
local Event = rtk.Event

--[[
    Require submodules
]]
local panels = {
    base = require("panels.base"),
    add = require("panels.add"),
    instrument = require("panels.instrument"),
    manager = require("panels.manager")
}

return panels
