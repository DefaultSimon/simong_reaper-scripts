--[[
    CONFIGURATION BEGIN
]]

--[[ 
    CONFIGURATION END
]]



--[[
    SCRIPT ESSENTIALS BEGIN
    
    Set of local functions that help configure lua path and require other code.
]]

--- Extend the `package.path` variable to contain one additional path.
---
---@param path string
local function add_to_lua_path(path)
    package.path = package.path .. ";" .. path
end

--- Return the directory this script resides in. Slashes are always forward-slashes, even on Windows.
---
---@return string
local function get_script_path()
    local info = debug.getinfo(1, "S");
    local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]

    script_path = string.gsub(script_path, "\\", "/")

    return script_path
end

--- A fancier `require` with optional specific error messages 
--- (e.g. "go there and install that missing library").
---
---@param module_path string
---@param message_on_error? string
---@return any
local function require_with_feedback(module_path, message_on_error)
    local was_imported, imported_module = pcall(require, module_path)

    if was_imported then
        return imported_module
    else
        local reason = tostring(imported_module)

        local final_error_message
        if message_on_error == nil then
            final_error_message = "Could not import module: " .. tostring(module_path) .. "\n\nFull error: " .. reason
        else
            final_error_message = tostring(message_on_error) .. "\n\nFull error: " .. reason
        end

        reaper.ShowMessageBox(final_error_message, "ReaScript Import Error", 0)

        -- Terminates the script.
        reaper.ReaScriptError("!Errored while trying to load a module. Please follow the instructions you just saw in the previous message.")
    end
end

--[[
    SCRIPT ESSENTIALS END
]]



--[[
    LIBRARY IMPORTS BEGIN
]]

add_to_lua_path(reaper.GetResourcePath() .. '/Scripts/rtk/1/?.lua')
add_to_lua_path(get_script_path() .. "/external_libraries/?.lua")
add_to_lua_path(get_script_path() .. "/?/init.lua")

local rtk = require_with_feedback(
    "rtk",
    "Missing library: \"REAPER Toolkit (rtk)\". Please go to https://reapertoolkit.dev/ and follow the \z
    installation instructions for REAPER Toolkit (add repository url listen on the website into \z
    your ReaPack repository list, then install the library)."
)
local lib = require_with_feedback(
    "internals",
    "Missing internal library files: please reinstall the entire \"Hardware recording manager\" package via ReaPack."
)

--[[
    LIBRARY IMPORTS END
]]


--[[ 
    Exposed internal library modules
]]

local mod_core = lib.core
local mod_project = lib.project
local mod_panels = lib.panels

local inspect = mod_core.libraries.inspect.inspect

local log = rtk.log
log.level = log.DEBUG


--[[
    Various utility functions
]]
local function log_debug(value, ...)
    local value_type = type(value)

    if value_type == "table" then
        local metatable = getmetatable(value)
        if type(metatable) == "table" and metatable.__tostring ~= nil then
            log.debug(value:__tostring(), ...)
        else
            log.debug(inspect(value))
        end
    elseif value_type == "string" then
        log.debug(value, ...)
    else
        log.debug(inspect(value), ...)
    end
end

--[[
    Functionality, abstracted into methods
]]




-- -- -- -- -- -- --
--  SCRIPT BEGIN  --
-- -- -- -- -- -- --

---@type ReaperProject | nil
local current_project = mod_project.ReaperProject:get_current_project()
if current_project == nil then
    return log.error("Could not find current Reaper project!", true)
end


-- Reaper Toolkit setup
---@type rtk.Window
local window = rtk.Window({
    -- If not using the "Compact docker when small and single tab" docker option, the actual height is around 15 px smaller.
    h = 130 + 15,
    w = 400,
    title = "Hardware Recording Manager",
    resizable = true,
    docked = true,
    dock = rtk.Window.DOCK_BOTTOM
})

---@type rtk.HBox
local window_hbox_panel_container = window:add(rtk.HBox({}))

---@type PanelManager
local panel_manager = mod_panels.manager.PanelManager:new(window_hbox_panel_container)

--[[
    Initialize default panels (at this moment just the plus button)
    TODO Integrate state saving and loading when done.
]]

local plus_button_panel = mod_panels.add.PlusButtonPanel:create(current_project)
local plus_button_panel_handle = panel_manager:add_panel(plus_button_panel)

local function main()
    window:open()
end

rtk.defer(function () rtk.call(main) end)
