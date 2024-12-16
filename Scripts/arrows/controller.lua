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
local welcome = require("Scripts.arrows.welcome")

-- State management
local State = {
    activeWebview = nil,     -- 🪟 Current window
    fadeTimer = nil,         -- ⏱️ Fade timer
    deleteTimer = nil,       -- ⏱️ Cleanup timer
    lastArrowPress = nil,    -- ⌨️ Last arrow key
    lastArrowTime = 0,       -- ⏱️ Last press time
    isHyperGenerated = false,-- 🔑 Hyper key state
    position = nil,          -- 📍 Window position
    lastSoundKey = nil,      -- 🔊 Last key that played sound
    isRealArrowPress = false,-- ⌨️ Track if arrow press was real or simulated
    isRealVimPress = false,  -- ⌨️ Track if VIM press was real or simulated
    activeHyperKey = nil    -- 🔑 Currently held Hyper key
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
        -- Only store arrow press if it was from a real key press
        if State.isRealArrowPress then
            State.lastArrowPress = direction
            State.lastArrowTime = currentTime
            debug.log("⌨️ Arrow key pressed:", direction)
        end
    else
        -- Only check for celebration if:
        -- 1. The last key was a real arrow key
        -- 2. This is a real VIM key press
        -- 3. This is not a Hyper-generated event
        if State.lastArrowPress and keyType == "vim" and 
           State.isRealVimPress and not State.isHyperGenerated then
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
                             direction == "back" and "B" or
                             direction == "forward" and "F"
                             
                local arrowSymbol = direction == "up" and "↑" or
                                  direction == "down" and "↓" or
                                  direction == "left" and "←" or
                                  direction == "right" and "→" or
                                  direction == "back" and "Back" or
                                  direction == "forward" and "Forward"
                
                hs.alert.show(string.format("🎉 Great job using Vim %s to move %s!", vimKey, arrowSymbol), TIMING.FEEDBACK_DURATION)
                return true
            else
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
        b = { dir = "back", code = 116 },  -- Page Up for back
        f = { dir = "forward", code = 121 }  -- Page Down for forward
    }

    for key, map in pairs(keyMap) do
        if keyCode == hs.keycodes.map[key] then
            direction = map.dir
            arrowKeyCode = map.code
            break
        end
    end

    if direction then
        -- If this is the same key that's being held down, ignore it
        if keyCode == State.activeHyperKey then
            return true
        end
        
        -- Set flags before any actions
        State.isHyperGenerated = true
        State.isRealVimPress = true
        State.activeHyperKey = keyCode
        
        -- Show feedback and play sound only if key changed
        M.createWindow(direction, "vim")
        if State.lastSoundKey ~= direction then
            sound.playSound(direction, "vim")
            State.lastSoundKey = direction
        end
        M.checkCelebration(direction, "vim")

        -- Simulate arrow key
        hs.eventtap.event.newKeyEvent({}, arrowKeyCode, true):post()
        
        -- Reset hyper state after a short delay
        hs.timer.doAfter(0.2, function()
            State.isHyperGenerated = false
            State.isRealVimPress = false
        end)
        
        return true
    end
    
    return false
end

-- Handle arrow keys
local function handleArrowKey(event)
    -- Skip if this is from a Hyper-generated event or if a Hyper key is being held
    if State.isHyperGenerated or State.activeHyperKey then 
        State.isRealArrowPress = false
        State.isRealVimPress = false
        return false 
    end

    local keyCode = event:getKeyCode()
    local keyMap = {
        [126] = "up",
        [125] = "down",
        [123] = "left",
        [124] = "right",
        [116] = "back",    -- Page Up for back
        [121] = "forward"  -- Page Down for forward
    }
    
    local direction = keyMap[keyCode]
    if direction then
        State.isRealArrowPress = true  -- Mark this as a real arrow press
        State.isRealVimPress = false   -- Reset VIM press state
        M.createWindow(direction, "arrow")
        if State.lastSoundKey ~= direction then
            sound.playSound(direction, "arrow")
            State.lastSoundKey = direction
        end
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
        position = nil,          -- 📍 Window position
        lastSoundKey = nil,      -- 🔊 Last key that played sound
        isRealArrowPress = false,-- ⌨️ Track if arrow press was real or simulated
        isRealVimPress = false,  -- ⌨️ Track if VIM press was real or simulated
        activeHyperKey = nil    -- 🔑 Currently held Hyper key
    }

    -- Initialize sound system
    sound.init()

    -- Create event watchers
    M.hyperWatcher = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, handleHyperKey)
    M.arrowWatcher = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, handleArrowKey)

    -- Start watchers
    M.hyperWatcher:start()
    M.arrowWatcher:start()

    -- Create key up watcher to reset sound state and key tracking
    M.keyUpWatcher = hs.eventtap.new({ hs.eventtap.event.types.keyUp }, function(event)
        local keyCode = event:getKeyCode()
        if keyCode == State.activeHyperKey then
            State.activeHyperKey = nil
        end
        State.lastSoundKey = nil
        return false
    end)
    M.keyUpWatcher:start()

    -- Show welcome window
    welcome.show()
end

-- Cleanup
function M.cleanup()
    if M.hyperWatcher then M.hyperWatcher:stop() end
    if M.arrowWatcher then M.arrowWatcher:stop() end
    if M.keyUpWatcher then M.keyUpWatcher:stop() end
    if State.activeWebview then State.activeWebview:delete() end
    if State.fadeTimer then State.fadeTimer:stop() end
    if State.deleteTimer then State.deleteTimer:stop() end
    sound.cleanup()
    State = nil
    hs.alert.show("👋 Arrow Keys Enhancement Deactivated", 1)
end

return M
