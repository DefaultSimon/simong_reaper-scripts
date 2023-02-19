local lib_global = {}

--- Start blocking the Reaper UI from refreshing.
---
---@return nil
function lib_global.block_ui_refresh()
    reaper.PreventUIRefresh(1)
end

--- Stop blocking the Reaper UI from refreshing.
---
---@return nil
function lib_global.unblock_ui_refresh()
    reaper.PreventUIRefresh(-1)
end

return lib_global
