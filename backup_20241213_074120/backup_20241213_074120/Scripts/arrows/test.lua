--[[
    Test module for the Arrows system
    
    This module provides integration tests and debugging utilities to ensure
    all components work together correctly.
]]

local model = require("arrows.model")
local view = require("arrows.view")
local sound = require("arrows.utils.sound")
local animation = require("arrows.utils.animation")
local controller = require("arrows.controller")

local M = {}

-- Test utilities
local function printHeader(text)
    print("\n" .. string.rep("=", 50))
    print(text)
    print(string.rep("=", 50))
end

local function printResult(name, success, message)
    print(string.format("%s %s: %s", 
        success and "✅" or "❌",
        name,
        message or (success and "Success" or "Failed")
    ))
end

-- Component tests
local function testView()
    printHeader("Testing View Component")
    
    -- Test HTML generation
    local success = true
    local message = ""
    
    -- Test arrow HTML
    local arrowHtml = view.generateArrowHtml(model.Direction.UP, model.KeyType.VIM)
    if not arrowHtml:match("↑") then
        success = false
        message = message .. "Missing arrow symbol\n"
    end
    if not arrowHtml:match("K") then
        success = false
        message = message .. "Missing key letter\n"
    end
    
    -- Test window HTML
    local windowHtml = view.generateWindowHtml(model.Direction.UP, model.KeyType.VIM)
    if not windowHtml:match("<html") then
        success = false
        message = message .. "Invalid HTML structure\n"
    end
    if not windowHtml:match("style") then
        success = false
        message = message .. "Missing styles\n"
    end
    
    printResult("View Tests", success, message)
    return success
end

local function testSound()
    printHeader("Testing Sound Component")
    
    -- Test sound initialization
    local success = sound.init()
    printResult("Sound Initialization", success)
    
    -- Test sound loading
    local hasAllSounds = true
    local message = ""
    
    for direction in pairs(model.Direction) do
        if direction ~= "BACK" then
            local dirLower = string.lower(direction)
            if not sound.sounds[dirLower] then
                hasAllSounds = false
                message = message .. "Missing sound for " .. direction .. "\n"
            end
            if not sound.dissonantSounds[dirLower] then
                hasAllSounds = false
                message = message .. "Missing dissonant sound for " .. direction .. "\n"
            end
        end
    end
    
    if not sound.backSound then
        hasAllSounds = false
        message = message .. "Missing back sound\n"
    end
    
    printResult("Sound Loading", hasAllSounds, message)
    return success and hasAllSounds
end

local function testAnimation()
    printHeader("Testing Animation Component")
    
    -- Test celebration script generation
    local success = true
    local message = ""
    
    -- Create a test webview
    local testWebview = hs.webview.new({x = 0, y = 0, w = 100, h = 100})
    testWebview:show()
    
    -- Test fade animation
    animation.fadeOut(testWebview, function()
        testWebview:delete()
    end)
    
    -- Test celebration
    local celebrationSuccess = animation.triggerCelebration()
    if not celebrationSuccess then
        success = false
        message = message .. "Celebration animation failed\n"
    end
    
    printResult("Animation Tests", success, message)
    return success
end

local function testController()
    printHeader("Testing Controller Component")
    
    local success = true
    local message = ""
    
    -- Test initialization
    controller.init()
    
    -- Test window creation
    controller.createWindow(model.Direction.UP, model.KeyType.VIM)
    if not controller.State.activeWebview then
        success = false
        message = message .. "Window creation failed\n"
    end
    
    -- Test celebration check
    controller.checkCelebration(model.Direction.UP, model.KeyType.ARROW)
    controller.checkCelebration(model.Direction.UP, model.KeyType.VIM)
    
    -- Cleanup
    controller.cleanup()
    
    printResult("Controller Tests", success, message)
    return success
end

-- Integration tests
function M.runTests()
    printHeader("Starting Integration Tests")
    
    local results = {
        view = testView(),
        sound = testSound(),
        animation = testAnimation(),
        controller = testController()
    }
    
    printHeader("Test Results Summary")
    for component, success in pairs(results) do
        printResult(component, success)
    end
    
    local allPassed = results.view and results.sound and 
                      results.animation and results.controller
    
    print("\n" .. string.rep("-", 50))
    printResult("All Tests", allPassed, 
        allPassed and "All components working correctly" or 
        "Some components need attention"
    )
    
    return allPassed
end

-- Debug utilities
function M.debugState()
    printHeader("Current System State")
    
    -- Check component states
    print("\nController State:")
    for key, value in pairs(controller.State) do
        if type(value) ~= "userdata" then
            print(string.format("  %s: %s", key, tostring(value)))
        end
    end
    
    print("\nSound State:")
    print(string.format("  Silent Mode: %s", tostring(sound.silentMode)))
    print(string.format("  Active Sound: %s", sound.activeSound and "Yes" or "No"))
    
    print("\nWindow Info:")
    if controller.State.activeWebview then
        local frame = controller.State.activeWebview:frame()
        print(string.format("  Position: x=%d, y=%d", frame.x, frame.y))
        print(string.format("  Size: w=%d, h=%d", frame.w, frame.h))
    else
        print("  No active window")
    end
end

return M 