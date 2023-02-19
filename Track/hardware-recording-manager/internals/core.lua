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
        local final_error_message
        if message_on_error == nil then
            final_error_message = "Could not import module: " .. tostring(module_path)
        else
            final_error_message = tostring(message_on_error)
        end

        reaper.ShowMessageBox(final_error_message, "ReaScript Import Error", 0)

        -- Terminates the script.
        reaper.ReaScriptError("!Errored while trying to load a module. Please follow the instructions you just saw in the previous message.")
    end
end

--[[
    Other utility functions
]]

-- Huh. Are there really no better ways to do these simple conversions in lua?

--- Convert number to boolean value.
--- Any non-zero value is converted to `true`.
---
---@param num number
---@return boolean
local function number_to_boolean(num)
    if num == 0 then
        return false
    else
        return true
    end
end

--- Convert a boolean value to 0 or 1.
---
---@param bool boolean
---@return number
local function boolean_to_number(bool)
    if bool == true then
        return 1
    else
        return 0
    end
end

--- Return true if any arguments are nil.
---
---@param ... any
---@return boolean
local function any_are_nil(...)
    local args = table.pack(...)
    for index = 1, #args do
        local value = args[index]
        if value == nil then
            return true
        end
    end

    return false
end

--[[
    Assemble the core library.
]]
local core = {
    libraries = {
        inspect = require_with_feedback(
            "inspect", 
            "Installation is missing the \"inspect\" library (?!): \z
            try reinstalling the \"Hardware recording manager\" package via ReaPack."
        ),
        middleclass = require_with_feedback(
            "middleclass",
            "Installation is missing the \"middleclass\" library (?!): \z
            try reinstalling the \"Hardware recording manager\" package via ReaPack."
        ),
    },
    utilities = {
        number_to_boolean = number_to_boolean,
        boolean_to_number = boolean_to_number,
        any_are_nil = any_are_nil,
    }
}

return core
