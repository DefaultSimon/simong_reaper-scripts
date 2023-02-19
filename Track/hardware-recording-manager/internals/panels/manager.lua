local core = require("core")

local class = core.libraries.middleclass.class

--[[
    Private functions
]]

--- Seed the `math` random generator using the current time.
local function seed_random_generator()
    --- Seconds since unix epoch.
    ---@type number
    local seconds_since_epoch = os.time()

    --- Number has 7 decimal places (at least on Windows 10),
    --- but is not clock time (and can therefore repeat over multiple runs, though very unlikely).
    ---@type number
    local precise_time = reaper.time_precise()

    -- The result of summing these two times together is a much more random number that we can use to seed further random generation.
    math.randomseed(seconds_since_epoch + precise_time)
end

--- Generate a random hexadecimal ID as a string.
--- The ID is generated from 16 bytes of random data, meaning it is a string
--- of `0123456789ABCDEF` characters and of length 32.
---
---@return string
local function generate_random_id()
    -- 8 two-byte numbers (16 bytes in total).
    -- We'll parse this into a 32-length hex string.
    local chunks = {
        math.random(0, 65536),
        math.random(0, 65536),
        math.random(0, 65536),
        math.random(0, 65536),
        math.random(0, 65536),
        math.random(0, 65536),
        math.random(0, 65536),
        math.random(0, 65536),
    }

    local hex_string_parts = {}
    for _, value in ipairs(chunks) do
        local value_as_hex_character = ""
        while value > 0 do
            local hex_character_index = (value % 16) + 1
            value_as_hex_character = string.sub('0123456789ABCDEF', hex_character_index, hex_character_index) .. value_as_hex_character

            value = math.floor(value / 16)
        end

        if #value_as_hex_character < 4 then
            value_as_hex_character = string.rep("0", 4 - #value_as_hex_character) .. value_as_hex_character
        end

        table.insert(hex_string_parts, value_as_hex_character)
    end

    return table.concat(hex_string_parts, "")
end

--[[
    Exposed classes and functions
]]
local module_manager = {}

--- A handle to a panel that exists in the UI. Provided by PanelManager, don't create by hand!
---
---@class PanelHandle
---@field id string
local PanelHandle = class("PanelHandle")

--- Initialize a new PanelHandle.
---
---@param random_id string
function PanelHandle:initialize(random_id)
    self.id = random_id
end


---@class PanelManager
---@field panel_container rtk.HBox
---@field panels {handle: PanelHandle, panel: Panel, root_widget: rtk.Widget}[]
local PanelManager = class("PanelManager")

---
---
---@param hbox_panel_container rtk.HBox
function PanelManager:initialize(hbox_panel_container)
    -- Sanity check at initialization that ensures the provided panel contain doesn't
    -- have any existing panels on it.
    if #hbox_panel_container.children > 0 then
        error("Can't initialize PanelManager: container should be empty.")
    end

    self.panel_container = hbox_panel_container
    self.panels = {}
end

--- Add a panel to the UI. If `insertion_index` is not provided, the method will
--- insert the panel at the end.
---
---@param panel_instance Panel
---@param insertion_index? number
---@return PanelHandle
function PanelManager:add_panel(panel_instance, insertion_index)
    local panel_random_id = generate_random_id()
    ---@type PanelHandle
    local panel_handle = PanelHandle:new(panel_random_id)

    local panel_root_widget = panel_instance:_get_root_widget()
    panel_instance:_setup(self)

    -- If no index is provided the method will insert the panel at the end.
    if insertion_index == nil then
        insertion_index = #self.panels + 1
    end

    table.insert(
        self.panels,
        insertion_index,
        {
            handle = panel_handle,
            panel = panel_instance,
            root_widget = panel_root_widget,
        }
    )

    self.panel_container:insert(insertion_index, panel_root_widget)

    return panel_handle
end

--- Given a handle to the panel, remove it from the UI.
---
---@param panel_handle PanelHandle
---@return boolean
function PanelManager:remove_panel(panel_handle)
    -- Find panel index.
    ---@type number | nil
    local panel_index = nil
    for index, registered_panel in ipairs(self.panels) do
        if registered_panel.handle.id == panel_handle.id then
            panel_index = index
            
            registered_panel.panel:_destroy()

            break
        end
    end

    if panel_index == nil then
        return false
    end

    -- Remove found panel.
    local was_widget_ok = self.panel_container:remove_index(panel_index) ~= nil
    if not was_widget_ok then
        error("BUG: Couldn't remove widget.")
    end

    local was_array_ok = table.remove(self.panels, panel_index) ~= nil
    if not was_array_ok then
        error("BUG: Couldn't remove panel from array even though widget was removed.")
    end

    return true
end

--- Return the number of panels currently visible in the UI.
---
---@return number
function PanelManager:get_panel_count()
    return #self.panels
end

--- Get a panel instance from its handle (if it exists).
---
---@param panel_handle PanelHandle
---@return Panel | nil
function PanelManager:get_panel_from_handle(panel_handle)
    -- Find panel instance.
    for _, registered_panel in ipairs(self.panels) do
        if registered_panel.handle.id == panel_handle.id then
            return registered_panel.panel
        end
    end

    return nil
end



module_manager.PanelHandle = PanelHandle
module_manager.PanelManager = PanelManager

seed_random_generator()

return module_manager
