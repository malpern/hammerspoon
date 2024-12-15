--[[
    🔍 Debug Utility for Arrows System
    
    Provides three levels of logging:
    🚫 NONE  (0) - No output
    ⚠️  ERROR (1) - Only errors
    🔬 DEBUG (2) - All debug output
]]

local M = {}

-- Debug levels
M.LEVEL = {
    NONE = 0,   -- 🚫 No output
    ERROR = 1,  -- ⚠️ Only errors
    DEBUG = 2   -- 🔬 All debug output
}

-- Current debug level (default to DEBUG)
local currentLevel = M.LEVEL.DEBUG

-- Set debug level
function M.setLevel(level)
    if level >= M.LEVEL.NONE and level <= M.LEVEL.DEBUG then
        currentLevel = level
        if level > M.LEVEL.NONE then
            local levelEmojis = {
                [M.LEVEL.ERROR] = "⚠️",
                [M.LEVEL.DEBUG] = "🔬"
            }
            print("🔄 Debug level set to: " .. levelEmojis[level] .. " " .. level)
        end
    end
end

-- Debug logging
function M.log(...)
    if currentLevel >= M.LEVEL.DEBUG then
        local args = {...}
        local message = ""
        for i, v in ipairs(args) do
            if i > 1 then message = message .. " " end
            message = message .. tostring(v)
        end
        print("🔍 " .. message)
    end
end

-- Error logging
function M.error(...)
    if currentLevel >= M.LEVEL.ERROR then
        local args = {...}
        local message = ""
        for i, v in ipairs(args) do
            if i > 1 then message = message .. " " end
            message = message .. tostring(v)
        end
        print("❌ " .. message)
    end
end

return M 