--[[
    Arrows Module Initialization
    Loads and starts the arrow key enhancement system
]]

local controller = require("Scripts.arrows.controller")

-- Initialize the module
controller.init()

-- Return the module for potential use elsewhere
return controller 