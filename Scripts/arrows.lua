local M = {}

-- TODO:
-- 1. bring back meeting mode auto detect with time out
-- 2. you only get the good sound if your using hte vim keys. Fail sounds if using arrow keys. stop using KM.
---3. polish the double esc key
-- 4. Make it draggable

-- Load required extensions
require("hs.webview")
require("hs.fnutils")

-- HTML content template for arrows
local htmlTemplate = [[
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Arrow Display</title>
    <style>
        body {
            margin: 0;
            padding: 0;
            background: transparent;
            font-family: "Proxima Nova", "SF Pro", sans-serif;
            color: #666666;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            overflow: hidden;
        }
        .arrow-container {
            background-color: transparent;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 5px;
        }
        .arrow-block {
            background-color: %s;
            border-radius: 12px;
            padding: 20px;
            text-align: center;
            font-size: 48px;
            box-shadow: 0 0 5px rgba(0, 0, 0, 0.5);
            line-height: 0.8;
            display: flex;
            justify-content: center;
            align-items: center;
            min-width: 48px;
            min-height: 48px;
            margin: 5px;
        }
    </style>
</head>
<body>
    <div class="arrow-container">
        <div class="arrow-block">ARROW</div>
    </div>
</body>
</html>
]]

-- Keep a reference to the active webview
local activeWebview = nil

-- Arrow characters for each direction
local arrowTemplate = [[
<div style='
    display: flex; 
    flex-direction: column; 
    align-items: center;
'>
    <div style='
        font-family: "Proxima Nova", "SF Pro", sans-serif;
        color: %s;
        text-shadow: none;
        font-size: 1em;
        font-weight: 600;
    '>%s</div>
    <div style='
        font-family: "Proxima Nova", "SF Pro", sans-serif;
        margin-top: 5px;
        font-size: .8em;
        font-weight: 600;
        color: %s;
    '>%s</div>
</div>
]]

local function getArrowHtml(direction, isArrowKey)
    -- For arrow keys: letter is white, symbol is darker red
    -- For vim keys: symbol is white, letter is #666666 (gray)
    local symbolColor = isArrowKey and "#4B0000" or "white"
    local letterColor = isArrowKey and "white" or "#666666"  
    
    -- Define both symbol and letter for each direction
    local symbol = direction == "up" and "↑" or
                  direction == "down" and "↓" or
                  direction == "left" and "←" or
                  direction == "right" and "→"
    
    local letter = direction == "up" and "K" or
                  direction == "down" and "J" or
                  direction == "left" and "H" or
                  direction == "right" and "L"
    
    -- Format template with order depending on key type
    if isArrowKey then
        -- Letter on top, arrow below for arrow keys
        return string.format(arrowTemplate, letterColor, letter, symbolColor, symbol)
    else
        -- Arrow on top, letter below for vim keys (unchanged)
        return string.format(arrowTemplate, symbolColor, symbol, letterColor, letter)
    end
end

-- Update arrows table to use the new function
local arrows = {
    up = getArrowHtml("up", false),
    down = getArrowHtml("down", false),
    left = getArrowHtml("left", false),
    right = getArrowHtml("right", false)
}

-- Keep track of active timers
local fadeTimer = nil
local deleteTimer = nil

-- At the top with other locals
local inKeySequence = false
local lastKeyPressed = nil
local activeSound = nil
local sounds = {}
local silentMode = false
local lastEscTime = 0
local escDoubleTapThreshold = 0.3  -- 300ms for double-tap detection
local lastSoundTime = 0
local soundDebounceTime = 0.1  -- 100ms debounce
local lastKeyTime = 0
local keyDebounceTime = 0.1  -- 100ms debounce
local lastArrowPress = nil
local lastArrowTime ppp= 0
local celebrationTimeout = 2  -- 1 second window to complete the combination
local celebrationKeycode = hs.keycodes.map["p"]  -- For Hyper + P

-- Get the Hammerspoon config directory
local configPath = hs.configdir .. "/sounds/"

-- Load sound files with error handling
for _, direction in ipairs({"up", "down", "left", "right"}) do
    local soundPath = configPath .. direction .. ".wav"
    print("Attempting to load sound from: " .. soundPath)
    local sound = hs.sound.getByFile(soundPath)
    if sound then
        sounds[direction] = sound
        print("Successfully loaded sound for " .. direction)
    else
        print("Error: Failed to load sound for " .. direction .. " from path: " .. soundPath)
    end
end

-- Add new sounds for arrow keys
local dissonantSounds = {}
for _, direction in ipairs({"up", "down", "left", "right"}) do
    local soundPath = configPath .. "dissonant/" .. direction .. ".wav"
    print("Attempting to load dissonant sound from: " .. soundPath)
    local sound = hs.sound.getByFile(soundPath)
    if sound then
        dissonantSounds[direction] = sound
        print("Successfully loaded dissonant sound for " .. direction)
    else
        print("Error: Failed to load dissonant sound for " .. direction .. " from path: " .. soundPath)
    end
end

-- Create event tap for escape key
local escWatcher = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
    local keyCode = event:getKeyCode()
    
    -- Check for escape key (keyCode 53)
    if keyCode == 53 then
        local currentTime = hs.timer.secondsSinceEpoch()
        
        -- Check if this is a double-tap
        if (currentTime - lastEscTime) < escDoubleTapThreshold then
            -- Toggle silent mode
            silentMode = not silentMode
            hs.alert.show(silentMode and "Arrow sounds: Off" or "Arrow sounds: On")
            print("Silent mode:", silentMode)
            lastEscTime = 0  -- Reset to prevent triple-tap
        else
            lastEscTime = currentTime
        end
    end
    
    return false
end):start()

local function playSound(direction, isArrowKey)
    -- Debounce check
    local currentTime = hs.timer.secondsSinceEpoch()
    if (currentTime - lastSoundTime) < soundDebounceTime then
        print("Debouncing sound playback")
        return
    end
    lastSoundTime = currentTime

    -- Check silent mode first
    if silentMode then
        print("Silent mode active, skipping sound")
        return
    end

    -- Stop any currently playing sound and wait a tiny bit
    if activeSound and activeSound:isPlaying() then
        print("Stopping previous sound")
        activeSound:stop()
        hs.timer.usleep(10000)  -- Wait 10ms to ensure clean transition
    end
    
    -- Choose the appropriate sound based on whether it's an arrow key
    activeSound = isArrowKey and dissonantSounds[direction] or sounds[direction]
    
    if activeSound then
        activeSound:volume(0.2)
        -- Use pcall to catch any playback errors
        local success, err = pcall(function() 
            activeSound:play() 
        end)
        if success then
            print("Successfully playing " .. (isArrowKey and "dissonant " or "") .. "sound for " .. direction)
        else
            print("Error playing sound for " .. direction .. ": " .. tostring(err))
        end
    end
    
    lastKeyPressed = direction
    inKeySequence = true
end

local function showArrow(direction, isArrowKey)
    -- Play sound for this direction
    playSound(direction, isArrowKey)

    -- Cancel any existing timers
    if fadeTimer then fadeTimer:stop() end
    if deleteTimer then deleteTimer:stop() end
    
    -- Clean up existing webview
    if activeWebview then
        activeWebview:delete()
        activeWebview = nil
    end
    
    -- Create new webview
    local width = 90
    local height = 120
    local screen = hs.screen.mainScreen()
    local frame = screen:frame()
    local x = frame.x + frame.w - width - 20
    local y = frame.y + 20
    
    activeWebview = hs.webview.new({x = x, y = y, w = width, h = height})
    activeWebview:windowStyle({"borderless", "closable", "nonactivating"})
    activeWebview:level(hs.drawing.windowLevels.floating)
    activeWebview:alpha(1.0)
    activeWebview:allowTextEntry(false)
    activeWebview:transparent(true)
    
    -- Choose the background color based on isArrowKey
    local bgColor = isArrowKey and "rgba(180, 0, 0, 1)" or "rgba(30, 30, 30, 1)"
    local formattedHtml = string.format(htmlTemplate, bgColor)
    
    -- Replace ARROW placeholder with the correct arrow character
    local arrowHtml = getArrowHtml(direction, isArrowKey)
    local html = string.gsub(formattedHtml, "ARROW", arrowHtml)
    activeWebview:html(html)
    activeWebview:show()
    
    -- Set up fade out
    fadeTimer = hs.timer.doAfter(2, function()
        local currentWebview = activeWebview  -- Capture current webview
        if currentWebview and currentWebview:isVisible() then
            local steps = 10
            local fadeTime = 0.8
            local stepTime = fadeTime / steps
            
            for i = 1, steps do
                hs.timer.doAfter(i * stepTime, function()
                    if currentWebview and currentWebview:isVisible() then
                        currentWebview:alpha(1.0 - (i/steps))
                    end
                end)
            end
            
            -- Delete after fade
            deleteTimer = hs.timer.doAfter(fadeTime + 0.1, function()
                if currentWebview then
                    currentWebview:delete()
                    if activeWebview == currentWebview then
                        activeWebview = nil
                    end
                end
            end)
        end
    end)
end

local function triggerCelebration()
    print("🎉 Starting celebration sequence!")
    
    -- Use osascript to trigger the keyboard shortcut
    local script = [[
        tell application "System Events"
            repeat 3 times
                key code 35 using {command down, option down, control down, shift down}
                delay 0.1
            end repeat
        end tell
    ]]
    
    local task = hs.task.new("/usr/bin/osascript", nil, function(exitCode, stdOut, stdErr)
        if exitCode == 0 then
            print("✨ Celebration sequence completed successfully")
        else
            print("❌ Error running celebration sequence:", stdErr)
        end
    end, {"-e", script})
    
    task:start()
end

local function checkCelebration(direction, isArrowKey)
    local currentTime = hs.timer.secondsSinceEpoch()
    
    if isArrowKey then
        -- Store the arrow press
        lastArrowPress = direction
        lastArrowTime = currentTime
        print(string.format("📝 Arrow key pressed: %s - Starting celebration window", direction))
    else
        -- Check if this vim motion matches a recent arrow press
        if lastArrowPress then
            local timeDiff = currentTime - lastArrowTime
            print(string.format("⌨️  Vim motion: %s (Previous arrow: %s, Time diff: %.2fs)", 
                direction, lastArrowPress, timeDiff))
            
            if timeDiff < celebrationTimeout and lastArrowPress == direction then
                print("🎯 Match found! Arrow + Vim combination detected")
                triggerCelebration()
                -- Reset after celebration
                lastArrowPress = nil
            else
                if timeDiff >= celebrationTimeout then
                    print("⌛ Too slow - celebration window expired")
                elseif lastArrowPress ~= direction then
                    print("❌ No match - wrong direction")
                end
            end
        else
            print("ℹ️  Vim motion without recent arrow press")
        end
    end
end

-- Add a flag to track if the key press was generated by our hyperWatcher
local isHyperGenerated = false

-- Set volume for sounds (20%)
local soundVolume = 0.2

local hyperWatcher = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
    local keyCode = event:getKeyCode()
    local flags = event:getFlags()
    
    -- Only process if ALL Hyper modifiers are pressed
    local isHyper = flags.cmd and flags.alt and flags.shift and flags.ctrl
    if not isHyper then 
        return false 
    end
    
    local arrowKeyCode = nil
    local direction = nil
    
    if keyCode == hs.keycodes.map["k"] then
        arrowKeyCode = 126  -- Up arrow
        direction = "up"
    elseif keyCode == hs.keycodes.map["j"] then
        arrowKeyCode = 125  -- Down arrow
        direction = "down"
    elseif keyCode == hs.keycodes.map["h"] then
        arrowKeyCode = 123  -- Left arrow
        direction = "left"
    elseif keyCode == hs.keycodes.map["l"] then
        arrowKeyCode = 124  -- Right arrow
        direction = "right"
    else
        return false
    end
    
    if arrowKeyCode then
        isHyperGenerated = true
        
        -- Show the visual feedback (grey box)
        showArrow(direction, false)
        
        -- Play the harmonious sound
        playSound(direction, false)
        
        -- Simulate the arrow key press
        local arrowEvent = hs.eventtap.event.newKeyEvent({}, arrowKeyCode, true)
        arrowEvent:post()
        
        -- Reset the flag after a short delay
        hs.timer.doAfter(0.1, function()
            isHyperGenerated = false
        end)
        
        return true  -- Prevent the original key from being passed to the system
    end
    
    return false
end)

-- Start the watchers
hyperWatcher:start()

-- Modify the arrowWatcher to respect isHyperGenerated
arrowWatcher = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
    if isHyperGenerated then
        return false
    end
    
    local keyCode = event:getKeyCode()
    local direction = nil
    
    if keyCode == 126 then       -- Up arrow
        direction = "up"
    elseif keyCode == 125 then   -- Down arrow
        direction = "down"
    elseif keyCode == 123 then   -- Left arrow
        direction = "left"
    elseif keyCode == 124 then   -- Right arrow
        direction = "right"
    end
    
    if direction then
        -- Show the visual feedback (red box)
        showArrow(direction, true)
        
        -- Play the dissonant sound
        playSound(direction, true)
        
        -- Start the celebration window
        lastArrowPress = direction
        lastArrowTime = os.time()
        print("📝 Arrow key pressed: " .. direction .. " - Starting celebration window")
    end
    
    return false
end)

-- Start the arrow watcher
arrowWatcher:start()