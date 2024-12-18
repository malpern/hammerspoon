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
    keyRepeatTimer = nil,    -- ⏱️ Key repeat timer
    hyperHeld = false,       -- Track if hyper is being held
    hyperDirection = nil,    -- Track current vim direction while hyper held
    currentArrowKey = nil    -- Track currently pressed arrow key
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
local function calculateWindowPosition(direction)
    local screen = hs.screen.mainScreen()
    local frame = screen:frame()
    
    -- Constants for sizing
    local keyWidth = 90  -- width of each key
    local keyGap = 10    -- gap between keys
    local rightMargin = 25  -- distance from right edge of screen
    local borderWidth = 2   -- border thickness
    local containerPadding = 4  -- extra padding around container
    
    -- Calculate width based on number of keys
    local numKeys = (direction == "back" or direction == "forward") and 2 or 4
    local width = (keyWidth * numKeys) + (keyGap * (numKeys - 1)) + (borderWidth * 2) + (containerPadding * 2)
    
    -- Position from right edge
    local x = frame.x + frame.w - width - rightMargin
    
    local position = {
        x = x,
        y = frame.y + 20,  -- 20px margin from top
        w = width,
        h = 120 + (borderWidth * 2) + (containerPadding * 2)  -- add space for border and padding
    }
    
    State.position = position
    return position
end

-- Create and show window
function M.createWindow(direction, keyType, skipFade)
    -- Clean up existing window
    if State.fadeTimer then State.fadeTimer:stop() end
    if State.deleteTimer then State.deleteTimer:stop() end
    if State.activeWebview then
        State.activeWebview:delete()
        State.activeWebview = nil
    end

    -- Calculate position with direction parameter
    local pos = State.position or calculateWindowPosition(direction)

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

        -- Set up fade out unless skipFade is true
        if not skipFade then
            State.fadeTimer = hs.timer.doAfter(TIMING.FADE_DELAY, function()
                fadeOutWindow()
            end)
        end
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

-- Fade out and cleanup window
local function fadeOutWindow()
    local currentWebview = State.activeWebview
    if currentWebview and currentWebview:isVisible() then
        local steps = 20        -- More steps for smoother fade
        local fadeTime = 2    -- Longer fade duration (2 seconds)
        local stepTime = fadeTime / steps
        
        for i = 1, steps do
            hs.timer.doAfter(i * stepTime, function()
                if currentWebview and currentWebview:isVisible() then
                    currentWebview:alpha(1.0 - (i/steps))
                end
            end)
        end
        
        -- Delete after fade
        State.deleteTimer = hs.timer.doAfter(fadeTime + 0.1, function()
            if currentWebview then
                currentWebview:delete()
                if State.activeWebview == currentWebview then
                    State.activeWebview = nil
                end
            end
        end)
    end
end

-- Handle hyper key press
local function handleHyperPress()
    if not State.hyperHeld then
        State.hyperHeld = true
        State.hyperDirection = nil
        M.createWindow(nil, "vim", true)  -- Show all keys without highlighting any 
    end
end

-- Handle hyper key release
local function handleHyperRelease()
    State.hyperHeld = false
    State.hyperDirection = nil
    if State.activeWebview then
        fadeOutWindow()
    end
end

-- Handle vim key with hyper
local function handleVimKey(direction)
    if State.hyperHeld then
        State.hyperDirection = direction
        -- Always use "vim" keyType for vim keys to get VIM_HIGHLIGHT colors
        M.createWindow(direction, "vim", true)  -- Show highlighted key with white background, no fade
    end
end

-- Create flag watcher for hyper key
local hyperFlagWatcher = hs.eventtap.new({hs.eventtap.event.types.flagsChanged}, function(event)
    local flags = event:getFlags()
    local isHyper = flags.cmd and flags.alt and flags.shift and flags.ctrl
    
    if isHyper and not State.hyperHeld then
        handleHyperPress()
    elseif not isHyper and State.hyperHeld then
        handleHyperRelease()
    end
    
    return false
end)

-- Start the flag watcher
hyperFlagWatcher:start()

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

-- Handle arrow keys
local function handleArrowKey(event)
    -- Skip if this is from a Hyper-generated event
    if State.isHyperGenerated then 
        State.isRealArrowPress = false
        State.isRealVimPress = false
        return false 
    end

    -- Skip if this is a key repeat
    if event:getProperty(hs.eventtap.event.properties.keyboardEventAutorepeat) == 1 then
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
        State.currentArrowKey = direction  -- Track current arrow key
        M.createWindow(direction, "arrow", true)  -- Create window with skipFade=true
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

-- Handle arrow key releases
local function handleArrowKeyUp(event)
    -- Skip if this is from a Hyper-generated event
    if State.isHyperGenerated then return false end

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
    if direction and direction == State.currentArrowKey then
        State.currentArrowKey = nil  -- Clear current arrow key
        fadeOutWindow()  -- Fade out the window
    end
    
    return false
end

-- Handle vim key events
local vimKeyWatcher = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
    if not State.hyperHeld then return false end
    
    local keyCode = event:getKeyCode()
    local keyMap = {
        [hs.keycodes.map.k] = "up",
        [hs.keycodes.map.j] = "down",
        [hs.keycodes.map.h] = "left",
        [hs.keycodes.map.l] = "right",
        [hs.keycodes.map.b] = "back",
        [hs.keycodes.map.f] = "forward"
    }
    
    local direction = keyMap[keyCode]
    if direction then
        -- Log VIM key usage
        debug.logLearning(direction, "vim")
        
        -- Show feedback and play sound
        State.isHyperGenerated = true  -- Mark this as hyper-generated
        State.isRealVimPress = true    -- Mark this as a real vim press
        handleVimKey(direction)
        sound.playSound(direction, "vim")
        
        -- Simulate arrow key
        local arrowKeyCodes = {
            up = 126,
            down = 125,
            left = 123,
            right = 124,
            back = 116,
            forward = 121
        }
        hs.eventtap.event.newKeyEvent({}, arrowKeyCodes[direction], true):post()
        
        -- Reset state after delay
        hs.timer.doAfter(TIMING.STATE_RESET_DELAY, function()
            State.isHyperGenerated = false
            State.isRealVimPress = false
        end)
        
        return true
    end
    
    return false
end)

-- Start the vim key watcher
vimKeyWatcher:start()

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
        keyRepeatTimer = nil,    -- ⏱️ Key repeat timer
        hyperHeld = false,       -- Track if hyper is being held
        hyperDirection = nil,    -- Track current vim direction while hyper held
        currentArrowKey = nil    -- Track currently pressed arrow key
    }

    -- Initialize sound system
    sound.init()

    -- Create event watchers
    M.arrowWatcher = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, handleArrowKey)
    M.arrowUpWatcher = hs.eventtap.new({ hs.eventtap.event.types.keyUp }, handleArrowKeyUp)
    M.hyperFlagWatcher = hyperFlagWatcher
    M.vimKeyWatcher = vimKeyWatcher

    -- Start watchers
    M.arrowWatcher:start()
    M.arrowUpWatcher:start()
    M.hyperFlagWatcher:start()
    M.vimKeyWatcher:start()

    -- Show welcome window
    welcome.show()
end

-- Cleanup
function M.cleanup()
    if M.hyperFlagWatcher then M.hyperFlagWatcher:stop() end
    if M.vimKeyWatcher then M.vimKeyWatcher:stop() end
    if M.arrowWatcher then M.arrowWatcher:stop() end
    if M.arrowUpWatcher then M.arrowUpWatcher:stop() end
    if State.activeWebview then State.activeWebview:delete() end
    if State.fadeTimer then State.fadeTimer:stop() end
    if State.deleteTimer then State.deleteTimer:stop() end
    if State.keyRepeatTimer then State.keyRepeatTimer:stop() end
    sound.cleanup()
    State = nil
    hs.alert.show("👋 Arrow Keys Enhancement Deactivated", 1)
end

return M
