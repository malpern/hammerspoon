--[[
    🎮 Arrows System Controller
    
    Features:
    🎯 Key event handling
    🪟 Window management
    🔄 State management
    🎉 Celebration triggers
]]

local view = require("Scripts.arrows.view")
local sound = require("Scripts.arrows.utils.sound")
local animation = require("Scripts.arrows.utils.animation")
local debug = require("Scripts.arrows.utils.debug")

-- State management
local State = {
    activeWebview = nil,     -- 🪟 Current window
    fadeTimer = nil,         -- ⏱️ Fade timer
    deleteTimer = nil,       -- ⏱️ Cleanup timer
    lastArrowPress = nil,    -- ⌨️ Last arrow key
    lastArrowTime = 0,       -- ⏱️ Last press time
    isHyperGenerated = false,-- 🔑 Hyper key state
    position = nil           -- 📍 Window position
}

-- Constants
local TIMING = {
    FADE_DELAY = 0.5,           -- ⏱️ Pre-fade delay
    MATCH_WINDOW = 1.0,         -- ⚡ Match timeout
    FEEDBACK_DURATION = 1.0,    -- 💬 Alert duration
    TRANSITION_DELAY = 0.01     -- 🎨 Animation delay
}

local M = {}

-- Calculate window position
local function calculateWindowPosition()
    local screen = hs.screen.mainScreen()
    local frame = screen:frame()
    
    -- Default position (top right)
    local position = {
        x = frame.x + frame.w - 90 - 20,  -- width + margin
        y = frame.y + 20,                 -- margin
        w = 90,                          -- width
        h = 120                          -- height
    }
    
    State.position = position
    return position
end

-- Create and show window
function M.createWindow(direction, keyType)
    -- Clean up existing window
    if State.fadeTimer then State.fadeTimer:stop() end
    if State.deleteTimer then State.deleteTimer:stop() end
    if State.activeWebview then
        State.activeWebview:delete()
        State.activeWebview = nil
    end

    -- Calculate position
    local pos = State.position or calculateWindowPosition()

    -- Create webview
    local success, webview = pcall(function()
        local w = hs.webview.new(pos)
        if not w then error("Failed to create webview") end
        return w
    end)

    if not success or not webview then
        debug.error("🚫 Failed to create webview:", webview)
        return false
    end

    -- Configure webview
    State.activeWebview = webview
    local success, err = pcall(function()
        State.activeWebview:windowStyle({ "borderless", "closable", "nonactivating" })
        State.activeWebview:level(hs.drawing.windowLevels.floating)
        State.activeWebview:alpha(1.0)
        State.activeWebview:allowTextEntry(false)
        State.activeWebview:transparent(true)
        State.activeWebview:bringToFront()

        -- Set HTML content
        local html = view.generateWindowHtml(direction, keyType)
        State.activeWebview:html(html)
        State.activeWebview:show()

        -- Set up fade out
        State.fadeTimer = hs.timer.doAfter(TIMING.FADE_DELAY, function()
            animation.fadeOut(State.activeWebview, function()
                if State.activeWebview then
                    State.activeWebview:delete()
                    State.activeWebview = nil
                end
            end)
        end)
    end)

    if not success then
        debug.error("🚫 Failed to configure webview:", err)
        if State.activeWebview then
            State.activeWebview:delete()
            State.activeWebview = nil
        end
        return false
    end

    return true
end

-- Check for celebration trigger
function M.checkCelebration(direction, keyType)
    local currentTime = hs.timer.secondsSinceEpoch()
    
    if keyType == "arrow" then
        -- Store arrow press
        State.lastArrowPress = direction
        State.lastArrowTime = currentTime
        debug.log("⌨️ Arrow key pressed:", direction)
    else
        -- Check for vim motion match
        if State.lastArrowPress then
            local timeDiff = currentTime - State.lastArrowTime
            if timeDiff < TIMING.MATCH_WINDOW and State.lastArrowPress == direction then
                debug.log("🎯 Match found! Triggering celebration")
                animation.triggerCelebration()
                State.lastArrowPress = nil
                
                -- Get vim key for direction
                local vimKey = direction == "up" and "K" or
                             direction == "down" and "J" or
                             direction == "left" and "H" or
                             direction == "right" and "L" or
                             direction == "back" and "B"
                             
                local arrowSymbol = direction == "up" and "↑" or
                                  direction == "down" and "↓" or
                                  direction == "left" and "←" or
                                  direction == "right" and "→" or
                                  direction == "back" and "Back"
                
                hs.alert.show(string.format("🎉 Great job using Vim %s to move %s!", vimKey, arrowSymbol), TIMING.FEEDBACK_DURATION)
                return true
            else
                if State.lastArrowPress ~= direction then
                    hs.alert.show("❌ Wrong direction! Try to match the arrow key!", TIMING.FEEDBACK_DURATION)
                end
                State.lastArrowPress = nil
            end
        end
    end
    return false
end

-- Handle Hyper key combinations
local function handleHyperKey(event)
    local keyCode = event:getKeyCode()
    local flags = event:getFlags()
    
    -- Check for Hyper key (all modifiers)
    if not (flags.cmd and flags.alt and flags.shift and flags.ctrl) then
        return false
    end

    -- Map vim keys to directions
    local direction = nil
    local arrowKeyCode = nil
    local keyMap = {
        k = { dir = "up", code = 126 },
        j = { dir = "down", code = 125 },
        h = { dir = "left", code = 123 },
        l = { dir = "right", code = 124 },
        b = { dir = "back", code = 116 }  -- Page Up for back
    }

    for key, map in pairs(keyMap) do
        if keyCode == hs.keycodes.map[key] then
            direction = map.dir
            arrowKeyCode = map.code
            break
        end
    end

    if direction then
        -- Set flag before any actions
        State.isHyperGenerated = true
        
        -- Show feedback and play sound
        M.createWindow(direction, "vim")
        sound.playSound(direction, "vim")
        M.checkCelebration(direction, "vim")

        -- Simulate arrow key
        hs.eventtap.event.newKeyEvent({}, arrowKeyCode, true):post()
        
        -- Reset hyper state after a short delay
        hs.timer.doAfter(0.2, function()
            State.isHyperGenerated = false
        end)
        
        return true
    end
    
    return false
end

-- Handle arrow keys
local function handleArrowKey(event)
    -- Skip if this is from a Hyper-generated event
    if State.isHyperGenerated then 
        return false 
    end

    local keyCode = event:getKeyCode()
    local keyMap = {
        [126] = "up",
        [125] = "down",
        [123] = "left",
        [124] = "right",
        [116] = "back"    -- Page Up for back
    }
    
    local direction = keyMap[keyCode]
    if direction then
        M.createWindow(direction, "arrow")
        sound.playSound(direction, "arrow")
        M.checkCelebration(direction, "arrow")
    end
    
    return false
end

-- Initialize
function M.init()
    -- Reset state
    State = {
        activeWebview = nil,     -- 🪟 Current window
        fadeTimer = nil,         -- ⏱️ Fade timer
        deleteTimer = nil,       -- ⏱️ Cleanup timer
        lastArrowPress = nil,    -- ⌨️ Last arrow key
        lastArrowTime = 0,       -- ⏱️ Last press time
        isHyperGenerated = false,-- 🔑 Hyper key state
        position = nil           -- 📍 Window position
    }

    -- Initialize sound system
    sound.init()

    -- Create event watchers
    M.hyperWatcher = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, handleHyperKey)
    M.arrowWatcher = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, handleArrowKey)

    -- Start watchers
    M.hyperWatcher:start()
    M.arrowWatcher:start()

    hs.alert.show("🎮 Arrow Keys Enhancement Active!", 1)
end

-- Cleanup
function M.cleanup()
    if M.hyperWatcher then M.hyperWatcher:stop() end
    if M.arrowWatcher then M.arrowWatcher:stop() end
    if State.activeWebview then State.activeWebview:delete() end
    if State.fadeTimer then State.fadeTimer:stop() end
    if State.deleteTimer then State.deleteTimer:stop() end
    sound.cleanup()
    State = nil
    hs.alert.show("👋 Arrow Keys Enhancement Deactivated", 1)
end

return M
