--[[
    Hammerspoon Configuration
    - Arrows system for key visualization
    - Command-line reload support
]]

-- Load required Hammerspoon modules
require("hs.webview")
require("hs.eventtap")
require("hs.sound")
require("hs.fnutils")
require("hs.timer")
require("hs.ipc")     -- Required for command-line control
require("hs.console") -- Required for console logging

-- Clear the console on startup
hs.console.clearConsole()

-- Set up file logging
local logFile = os.getenv("HOME") .. "/.hammerspoon/hammerspoon.log"

-- Clear the log file on startup. This keeps the log file from getting too big.
local file = io.open(logFile, "w")
if file then
    file:close()
end

-- Set up print override for logging
local originalPrint = print
print = function(...)
    -- Call original print for console
    originalPrint(...)
    
    -- Get all arguments as strings
    local args = {...}
    local strArgs = {}
    for i, v in ipairs(args) do
        strArgs[i] = tostring(v)
    end
    local text = table.concat(strArgs, "\t")
    
    -- Add timestamp and write to file
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local logText = string.format("[%s] %s\n", timestamp, text)
    local file = io.open(logFile, "a")
    if file then
        file:write(logText)
        file:close()
    end
end

print("📝 Starting new log session")

-- Enable command-line IPC
if not hs.ipc.cliInstall() then
    hs.alert.show("Failed to install command-line tool!")
else
    hs.alert.show("✅ IPC Command Line Tool Installed", 1)
    print("✅ IPC Command Line Tool Installed")
end

-- Load and initialize the Arrows system
local arrows = require("Scripts.arrows.init")

-- Initialize Arrows with testing enabled
local success, error = arrows.init({
    test = true,      -- Run integration tests
    strict = true     -- Strict mode for validation
})

if not success then
    print("❌ Initialization failed:")
    print(error)
    return
end

-- Show a message when config is loaded
hs.alert.show("✅ Hammerspoon config loaded", 1)
print("✅ Hammerspoon config loaded")