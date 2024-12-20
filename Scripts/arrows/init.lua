--[[
    🎮 Arrows Module - Main Entry Point
    
    A delightful system for learning Vim motions through visual and audio feedback.
    
    Features:
    🎯 Visual arrow indicators
    🔊 Directional sound feedback
    ⌨️  Vim key training
    🎉 Celebration animations
    🔇 Sound toggle with double-ESC
]]

--[[
    TODO:
    - Add meeting detection mode
    - add stats on how well you've learned
]]

local controller = require("Scripts.arrows.controller")
local debug = require("Scripts.arrows.utils.debug")

-- 🛠️ Debug Configuration
-- NONE = 0  ➜ No output
-- ERROR = 1 ➜ Only errors (production)
-- DEBUG = 2 ➜ All debug output (development)
debug.setLevel(debug.LEVEL.DEBUG)  -- Show all debug output

-- 🚀 Initialize the module
controller.init()

-- 📦 Return the module for potential use elsewhere
return controller 