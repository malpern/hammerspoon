--[[
    Main module file for the Arrows system
    
    This file serves as the main entry point and re-exports all components
]]

local M = {}

-- Initialize function
function M.init(options)
    -- Load the actual implementation
    local impl = require("Scripts.arrows.init")
    return impl.init(options)
end

-- Export other functions
M.cleanup = function()
    local impl = require("Scripts.arrows.init")
    return impl.cleanup()
end

M.debug = function()
    local impl = require("Scripts.arrows.init")
    return impl.debug()
end

M.test = function()
    local impl = require("Scripts.arrows.init")
    return impl.test()
end

return M