local core = require("core")

local class = core.libraries.middleclass.class


local module_base = {}

---@class Panel
---@field panel_manager PanelManager | nil
local Panel = class("Panel")

--- Return the root widget of this panel that can be added to the UI (the DOM, if you will).
--- This is used by the PanelManager to add panels to the UI.
---
---@return rtk.Widget
function Panel:_get_root_widget()
    error("Invalid panel implementation: missing get_root_widget override.")
end

--- Called by the PanelManager when it adds the panel to the UI.
---
---@param manager PanelManager
function Panel:_setup(manager)
    self.panel_manager = manager
end

--- Called by the PanelManager when it removes the panel from the UI.
function Panel:_destroy()
    self.panel_manager = nil
end


module_base.Panel = Panel

return module_base
