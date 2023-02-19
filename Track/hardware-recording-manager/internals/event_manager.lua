local core = require("core")

local class = core.libraries.middleclass.class


local module_eventmanager = {}

module_eventmanager.SubscriptionType = {
    --- Triggered when a new track is created.
    ---
    --- TODO
    ADD_NEW_TRACK = "add_new_track"
}

---@class EventManager
local EventManager = class("EventManager")

--- Initialize a new EventManager that will act as a central DAW change event dispatcher.
---
---@param reaper_project ReaperProject
function EventManager:initialize(reaper_project)
    self.project = reaper_project
end

-- function EventManager:start_monitoring()
--     reaper.defer(self:)
-- end


-- function EventManager:subscribe()

-- TODO Abandoned this for now, as other features have more priority.

module_eventmanager.EventManager = EventManager

return module_eventmanager
