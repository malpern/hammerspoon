--[[
    Sound utility module for the Arrows system
    
    This module handles all sound-related functionality including:
    - Loading and managing sound files
    - Playing sounds with proper timing and transitions
    - Managing sound state (mute/unmute)
    - Handling escape key for sound toggling
]]

local model = require("Scripts.arrows.model")

local M = {
    sounds = {},
    dissonantSounds = {},
    backSound = nil,
    activeSound = nil,
    silentMode = model.State.INITIAL.silentMode,
    lastSoundTime = 0,
    lastEscTime = nil,
    escKeyDown = false  -- Track if escape key is currently down
}

-- Initialize sound system
---@return boolean success Whether initialization was successful
function M.init()
    -- Reset timing variables
    M.lastSoundTime = 0
    M.lastEscTime = nil
    M.escKeyDown = false
    
    -- Get the Hammerspoon config directory
    local configPath = hs.configdir .. "/sounds/"
    local success = true
    
    -- Load normal sounds
    for direction in pairs(model.Direction) do
        if direction ~= "BACK" then
            local dirLower = string.lower(direction)
            local soundPath = configPath .. string.format(model.Sound.PATHS.NORMAL, dirLower)
            local sound = hs.sound.getByFile(soundPath)
            if sound then
                M.sounds[dirLower] = sound
                print("Successfully loaded sound for " .. direction)
            else
                print("Error: Failed to load sound for " .. direction .. " from path: " .. soundPath)
                success = false
            end
        end
    end
    
    -- Load dissonant sounds
    for direction in pairs(model.Direction) do
        if direction ~= "BACK" then
            local dirLower = string.lower(direction)
            local soundPath = configPath .. string.format(model.Sound.PATHS.DISSONANT, dirLower)
            local sound = hs.sound.getByFile(soundPath)
            if sound then
                M.dissonantSounds[dirLower] = sound
                print("Successfully loaded dissonant sound for " .. direction)
            else
                print("Error: Failed to load dissonant sound for " .. direction .. " from path: " .. soundPath)
                success = false
            end
        end
    end
    
    -- Load back sound
    local backSoundPath = configPath .. model.Sound.PATHS.BACK
    M.backSound = hs.sound.getByFile(backSoundPath)
    if M.backSound then
        print("Successfully loaded sound for back")
    else
        print("Error: Failed to load sound for back from path: " .. backSoundPath)
        success = false
    end
    
    -- Set up escape key watchers for silent mode toggle
    M.escWatcher = hs.eventtap.new({hs.eventtap.event.types.keyDown, hs.eventtap.event.types.keyUp}, function(event)
        local keyCode = event:getKeyCode()
        local eventType = event:getType()
        
        if keyCode == model.SpecialKeys.ESCAPE then
            local currentTime = hs.timer.secondsSinceEpoch()
            
            if eventType == hs.eventtap.event.types.keyDown then
                -- If escape is already down, this is a repeat event - ignore it
                if M.escKeyDown then
                    return false
                end
                
                M.escKeyDown = true
                
                -- If this is the first press in a sequence
                if not M.lastEscTime then
                    M.lastEscTime = currentTime
                    return false  -- Let the first press through
                end
                
                -- This is a second press, check if it's within the double-tap window
                local timeDiff = currentTime - M.lastEscTime
                if timeDiff < model.Timing.KEY.DOUBLE_TAP then
                    M.silentMode = not M.silentMode
                    hs.alert.show(M.silentMode and "Arrow sounds: Off" or "Arrow sounds: On")
                    print("Silent mode:", M.silentMode)
                    M.lastEscTime = nil
                    return true  -- Capture the second press
                end
                
                -- Too slow, treat as new first press
                M.lastEscTime = currentTime
                return false
                
            elseif eventType == hs.eventtap.event.types.keyUp then
                M.escKeyDown = false
                
                -- If no second press came quickly enough, reset the sequence
                if M.lastEscTime and (currentTime - M.lastEscTime) >= model.Timing.KEY.DOUBLE_TAP then
                    M.lastEscTime = nil
                end
                
                return false
            end
        end
        
        return false
    end):start()
    
    return success
end

-- Play sound for a direction
---@param direction string The direction to play sound for
---@param keyType string The type of key (vim/arrow)
function M.playSound(direction, keyType)
    -- Debounce check
    local currentTime = hs.timer.secondsSinceEpoch()
    if (currentTime - M.lastSoundTime) < model.Timing.KEY.DEBOUNCE then
        print("Debouncing sound playback")
        return
    end
    M.lastSoundTime = currentTime

    -- Check silent mode first
    if M.silentMode then
        print("Silent mode active, skipping sound")
        return
    end

    -- Stop any currently playing sound and wait for transition
    if M.activeSound and M.activeSound:isPlaying() then
        print("Stopping previous sound")
        M.activeSound:stop()
        hs.timer.usleep(model.Style.ANIMATION.TRANSITION_DELAY * 1000000)  -- Convert to microseconds
    end
    
    -- Choose the appropriate sound
    if direction == model.Direction.BACK then
        M.activeSound = M.backSound
    else
        local dirLower = string.lower(direction)
        M.activeSound = (keyType == model.KeyType.ARROW) 
            and M.dissonantSounds[dirLower] 
            or M.sounds[dirLower]
    end
    
    if M.activeSound then
        M.activeSound:volume(model.Sound.VOLUME.NORMAL)
        -- Use pcall to catch any playback errors
        local success, err = pcall(function() 
            M.activeSound:play() 
        end)
        if success then
            print("Successfully playing sound for " .. direction)
        else
            print("Error playing sound for " .. direction .. ": " .. tostring(err))
        end
    end
end

-- Toggle silent mode
---@return boolean isSilent The new silent mode state
function M.toggleSilent()
    M.silentMode = not M.silentMode
    return M.silentMode
end

-- Cleanup function
function M.cleanup()
    if M.escWatcher then
        M.escWatcher:stop()
    end
    
    -- Stop any playing sound
    if M.activeSound and M.activeSound:isPlaying() then
        M.activeSound:stop()
    end
end

return M 