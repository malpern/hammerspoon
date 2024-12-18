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

-- Learning log buffer and timer
local logBuffer = {}
local BUFFER_FLUSH_INTERVAL = 5  -- Flush every 5 seconds
local logTimer = nil

-- Initialize log timer
local function initLogTimer()
    if logTimer then logTimer:stop() end
    
    logTimer = hs.timer.doEvery(BUFFER_FLUSH_INTERVAL, function()
        if #logBuffer > 0 then
            local logPath = hs.configdir .. "/learning.log"
            local file = io.open(logPath, "a")
            if file then
                file:write(table.concat(logBuffer))
                file:close()
                logBuffer = {}
            else
                M.error("Failed to flush learning log")
            end
        end
    end)
end

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

-- Log learning event
function M.logLearning(direction, method)
    local timestamp = os.date("%Y-%m-%d, %H:%M:%S")
    local logLine = string.format("%s, %s, %s\n", timestamp, direction, method)
    table.insert(logBuffer, logLine)
end

-- Initialize timer when module loads
initLogTimer()

-- Cleanup function
function M.cleanup()
    if logTimer then
        -- Flush remaining entries
        if #logBuffer > 0 then
            local logPath = hs.configdir .. "/learning.log"
            local file = io.open(logPath, "a")
            if file then
                file:write(table.concat(logBuffer))
                file:close()
            end
        end
        logTimer:stop()
        logTimer = nil
    end
end

return M 