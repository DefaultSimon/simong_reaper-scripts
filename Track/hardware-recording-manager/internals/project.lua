local core = require("core")

local class = core.libraries.middleclass.class


local module_project = {}

module_project.UNDO_STATE_ALL = -1
module_project.UNDO_STATE_TRACKCFG = 1
module_project.UNDO_STATE_FX = 2
module_project.UNDO_STATE_ITEMS = 4
module_project.UNDO_STATE_MISCCFG = 8
module_project.UNDO_STATE_FREEZE = 16

--[[
    ReaperProject class
    (an abstraction over the native ReaProject userdata type)
]]


--- ReaperProject is a light abstraction over the native ReaProject userdata type
--- provided by Reaper in its various API calls.
---
---@class ReaperProject
local ReaperProject = class("ReaperProject")


--- Initialize a new ReaperProject (wrapper over the native ReaProject userdata type).
--- Provided `project` userdata should be of type `ReaProject`.
---
---@param reaper_project userdata
function ReaperProject:initialize(reaper_project)
    self.project = reaper_project
end


--- Get the current Reaper project.
---
---@return ReaperProject | nil
function ReaperProject.static:get_current_project()
    local current_project = reaper.EnumProjects(-1)
    if current_project == nil then
        return nil
    end

    return self(current_project)
end

--- Begin an project-wide undo block. When the end of block is called,
--- this will generate an undo point. See UNDO_* flags for possible flag values.
---
---@return nil
function ReaperProject:begin_undo_block()
    reaper.Undo_BeginBlock2(self.project)
end

--- End an undo block. See UNDO_* flags for possible flag values 
--- (they dictate what states are captured).
---
---@return nil
function ReaperProject:end_undo_block(description, flags)
    reaper.Undo_EndBlock2(self.project, description, flags or module_project.UNDO_STATE_ALL)
end


-- TODO A lot of methods are missing, but that's intentional - I add methods when I need them.

module_project.ReaperProject = ReaperProject
--[[
    END OF ReaperProject class
]]

return module_project
