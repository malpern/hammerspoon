--[[
    Arrows System - Main Entry Point
    
    This module initializes and coordinates all components of the Arrows system.
    It provides:
    - Component initialization
    - System configuration
    - Testing and debugging utilities
]]

local model = require("arrows.model")
local view = require("arrows.view")
local controller = require("arrows.controller")
local sound = require("arrows.utils.sound")
local animation = require("arrows.utils.animation")
local test = require("arrows.test")

local M = {}

-- Configuration validation
local function validateConfig()
    local success = true
    local messages = {}
    
    -- Check for required Hammerspoon modules
    local requiredModules = {"hs.webview", "hs.fnutils", "hs.eventtap", "hs.timer", "hs.sound"}
    for _, module in ipairs(requiredModules) do
        if not package.loaded[module] then
            success = false
            table.insert(messages, string.format("Missing required module: %s", module))
        end
    end
    
    -- Check for sound files
    local configPath = hs.configdir .. "/sounds/"
    local function checkFile(path)
        local file = io.open(path, "r")
        if file then
            file:close()
            return true
        end
        return false
    end
    
    -- Check normal sounds
    for direction in pairs(model.Direction) do
        if direction ~= "BACK" then
            local soundPath = configPath .. string.lower(direction) .. ".wav"
            if not checkFile(soundPath) then
                success = false
                table.insert(messages, string.format("Missing sound file: %s", soundPath))
            end
        end
    end
    
    -- Check dissonant sounds
    for direction in pairs(model.Direction) do
        if direction ~= "BACK" then
            local soundPath = configPath .. "dissonant/" .. string.lower(direction) .. ".wav"
            if not checkFile(soundPath) then
                success = false
                table.insert(messages, string.format("Missing dissonant sound file: %s", soundPath))
            end
        end
    end
    
    -- Check back sound
    local backSoundPath = configPath .. "up_deeper.wav"
    if not checkFile(backSoundPath) then
        success = false
        table.insert(messages, string.format("Missing back sound file: %s", backSoundPath))
    end
    
    return success, messages
end

-- System initialization
---@return boolean success Whether initialization was successful
---@return string|nil error Error message if initialization failed
function M.init(options)
    options = options or {}
    
    -- Validate configuration
    local configValid, configMessages = validateConfig()
    if not configValid then
        local errorMsg = "Configuration validation failed:\n" .. table.concat(configMessages, "\n")
        if options.strict then
            return false, errorMsg
        else
            print("⚠️ " .. errorMsg)
        end
    end
    
    -- Load required extensions
    require("hs.webview")
    require("hs.fnutils")
    
    -- Initialize components
    local success = true
    local errors = {}
    
    -- Initialize sound system
    if not sound.init() then
        table.insert(errors, "Sound system initialization failed")
        success = false
    end
    
    -- Initialize controller
    controller.init()
    
    -- Run integration tests if requested
    if options.test then
        local testsPassed = test.runTests()
        if not testsPassed then
            table.insert(errors, "Integration tests failed")
            success = false
        end
    end
    
    -- Show initialization status
    if success then
        hs.alert.show("🎮 Arrows System Initialized Successfully", 1)
        print("✅ Arrows System initialized successfully")
    else
        local errorMsg = "Initialization failed:\n" .. table.concat(errors, "\n")
        hs.alert.show("⚠️ Arrows System Initialization Failed", 2)
        print("❌ " .. errorMsg)
        return false, errorMsg
    end
    
    return true
end

-- System cleanup
function M.cleanup()
    controller.cleanup()
    sound.cleanup()
end

-- Debug utilities
function M.debug()
    test.debugState()
end

-- Run tests
function M.test()
    return test.runTests()
end

return M 