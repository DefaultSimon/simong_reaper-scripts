local core = require("core")

local rtk = require("rtk")

local class = core.libraries.middleclass.class


local module_app = {}


---@class Application
local Application = class("Application")

function Application:initialize()
    ---@type rtk.Window
    local main_window = rtk.Window({
        minh = 130,
        minw = 400,
        title = "Hardware Recording Manager",
        resizable = true,
        docked = true,
        dock = rtk.Window.DOCK_BOTTOM
    })

    ---@type rtk.HBox
    local panels_hbox = main_window:add(rtk.HBox({
        spacing = 0,
        fillw = true,
        stretch = rtk.Box.STRETCH_FULL
    }))

    self.window = main_window
    self.panels_container = panels_hbox

    -- TODO

    -- TODO see add_panel TODO for more info
    -- self:add_block(add_instrument_block)
end

function Application:add_panel()
    -- TODO This would add a panel to the (right end of the) UI.
    --      - define a block (modify UIPanel)
    --      - all others, such as InstrumentUI should be modified so we can slot them in
    --      - implement AddInstrumentPanel in the same fashion
end


return module_app

