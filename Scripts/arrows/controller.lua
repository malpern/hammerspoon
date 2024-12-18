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
    keyRepeatTimer = nil     -- ⏱️ Key repeat timer
}

-- Constants
local TIMING = {
    FADE_DELAY = 0.5,           -- ⏱️ Pre-fade delay
    MATCH_WINDOW = 1.0,         -- ⚡ Match timeout
    FEEDBACK_DURATION = 1.0,    -- 💬 Alert duration
    TRANSITION_DELAY = 0.01,    -- 🎨 Animation delay
    KEY_REPEAT_DELAY = 0.1,     -- ⌨️ Key repeat delay
    STATE_RESET_DELAY = 0.2     -- 🔄 State reset delay
}

local M = {}

-- Calculate window position
local function calculateWindowPosition()
    local screen = hs.screen.mainScreen()
    local frame = screen:frame()
    
    -- New dimensions for 4 keys side by side (90px each) plus margins
    local width = (90 * 4) + (5 * 2) + (10 * 3)  -- 4 keys * 90px + outer margins + inner gaps
    local height = 120
    
    local position = {
        x = frame.x + frame.w - width - 20,  -- 20px margin from right edge
        y = frame.y + 20,                    -- 20px margin from top
        w = width,
        h = height
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
        -- Log VIM key usage
        debug.logLearning(direction, "vim")
        
        -- Set flags before any actions
        State.isHyperGenerated = true
        State.isRealVimPress = true
        
        -- Show feedback and play sound
        M.createWindow(direction, "vim")
        sound.playSound(direction, "vim")
        M.checkCelebration(direction, "vim")

        -- Simulate arrow key
        hs.eventtap.event.newKeyEvent({}, arrowKeyCode, true):post()
        
        -- Reset state after delay
        hs.timer.doAfter(TIMING.STATE_RESET_DELAY, function()
            State.isHyperGenerated = false
            State.isRealVimPress = false
        end)
        
        -- Set up key repeat timer
        if State.keyRepeatTimer then State.keyRepeatTimer:stop() end
        State.keyRepeatTimer = hs.timer.doAfter(TIMING.KEY_REPEAT_DELAY, function()
            State.lastSoundKey = nil
        end)
        
        return true
    end
    
    return false
end

-- Handle arrow keys
local function handleArrowKey(event)
    -- Skip if this is from a Hyper-generated event
    if State.isHyperGenerated then 
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
        -- Log arrow key usage
        debug.logLearning(direction, "arrow")
        
        State.isRealArrowPress = true  -- Mark this as a real arrow press
        State.isRealVimPress = false   -- Reset VIM press state
        M.createWindow(direction, "arrow")
        sound.playSound(direction, "arrow")
        M.checkCelebration(direction, "arrow")
        
        -- Set up key repeat timer
        if State.keyRepeatTimer then State.keyRepeatTimer:stop() end
        State.keyRepeatTimer = hs.timer.doAfter(TIMING.KEY_REPEAT_DELAY, function()
            State.lastSoundKey = nil
        end)
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
        keyRepeatTimer = nil     -- ⏱️ Key repeat timer
    }

    -- Initialize sound system
    sound.init()

    -- Create event watchers
    M.hyperWatcher = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, handleHyperKey)
    M.arrowWatcher = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, handleArrowKey)

    -- Start watchers
    M.hyperWatcher:start()
    M.arrowWatcher:start()

    -- Show welcome window
    welcome.show()
end

-- Cleanup
function M.cleanup()
    if M.hyperWatcher then M.hyperWatcher:stop() end
    if M.arrowWatcher then M.arrowWatcher:stop() end
    if State.activeWebview then State.activeWebview:delete() end
    if State.fadeTimer then State.fadeTimer:stop() end
    if State.deleteTimer then State.deleteTimer:stop() end
    if State.keyRepeatTimer then State.keyRepeatTimer:stop() end
    sound.cleanup()
    State = nil
    hs.alert.show("👋 Arrow Keys Enhancement Deactivated", 1)
end

return M
