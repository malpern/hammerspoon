--[[
    Test configuration for Arrows system
]]

-- Load and initialize the Arrows system
local arrows = require("Scripts.arrows")

-- Initialize with testing enabled
local success, error = arrows.init({
    test = true,      -- Run integration tests
    strict = true     -- Strict mode for validation
})

if not success then
    print("❌ Initialization failed:")
    print(error)
    return
end

-- Run verification
require("Scripts.arrows.verify") 