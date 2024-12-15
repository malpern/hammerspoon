--[[
    Sound utility module for the Arrows system - Simplified Version
    Handles sound playback and muting
]]

local M = {}

-- Sound state
local State = {
    sounds = {},
    dissonantSounds = {},
    backSound = nil,
    silentMode = false,
    activeSound = nil,
    lastPlayTime = 0,
    lastEscTime = nil,
    escKeyDown = false
}

-- Constants
local VOLUME = {
    NORMAL = 0.2,
    MUTED = 0.0
}

local DOUBLE_PRESS_TIME = 0.3  -- 300ms for double-tap detection
local DEBOUNCE_TIME = 0.01     -- 10ms for sound transitions

-- Initialize sounds
function M.init()
    local success = true
    local configPath = hs.configdir .. "/sounds/"

    -- Load normal sounds
    for _, direction in ipairs({ "up", "down", "left", "right" }) do
        local path = configPath .. direction .. ".wav"
        local sound = hs.sound.getByFile(path)
        if sound then
            State.sounds[direction] = sound
            sound:volume(VOLUME.NORMAL)
            print("Successfully loaded sound for " .. direction)
        else
            success = false
            print("Failed to load sound: " .. path)
        end
    end

    -- Load dissonant sounds
    for _, direction in ipairs({ "up", "down", "left", "right" }) do
        local path = configPath .. "dissonant/" .. direction .. ".wav"
        local sound = hs.sound.getByFile(path)
        if sound then
            State.dissonantSounds[direction] = sound
            sound:volume(VOLUME.NORMAL)
            print("Successfully loaded dissonant sound for " .. direction)
        else
            success = false
            print("Failed to load sound: " .. path)
        end
    end

    -- Load back sound
    local backPath = configPath .. "up_deeper.wav"
    local backSound = hs.sound.getByFile(backPath)
    if backSound then
        State.backSound = backSound
        backSound:volume(VOLUME.NORMAL)
        print("Successfully loaded sound for back")
    else
        success = false
        print("Failed to load back sound: " .. backPath)
    end

    -- Set up escape key watcher for mute toggle
    M.escWatcher = hs.eventtap.new({ hs.eventtap.event.types.keyDown, hs.eventtap.event.types.keyUp }, function(event)
        local keyCode = event:getKeyCode()
        local eventType = event:getType()

        if keyCode == 53 then -- Escape key
            local currentTime = hs.timer.secondsSinceEpoch()

            if eventType == hs.eventtap.event.types.keyDown then
                if State.escKeyDown then return false end
                State.escKeyDown = true

                if not State.lastEscTime then
                    State.lastEscTime = currentTime
                    return false
                end

                if (currentTime - State.lastEscTime) < DOUBLE_PRESS_TIME then
                    M.toggleMute()
                    State.lastEscTime = nil
                    return true
                end

                State.lastEscTime = currentTime
                return false
            else
                State.escKeyDown = false
                if State.lastEscTime and (currentTime - State.lastEscTime) >= DOUBLE_PRESS_TIME then
                    State.lastEscTime = nil
                end
                return false
            end
        end
        return false
    end):start()

    return success
end

-- Play sound for a direction
function M.playSound(direction, keyType)
    if State.silentMode then
        print("Silent mode active, skipping sound")
        return true
    end

    -- Debounce
    local currentTime = hs.timer.secondsSinceEpoch()
    if currentTime - State.lastPlayTime < DEBOUNCE_TIME then
        print("Debouncing sound playback")
        return true
    end
    State.lastPlayTime = currentTime

    -- Stop current sound
    if State.activeSound and State.activeSound:isPlaying() then
        State.activeSound:stop()
        hs.timer.usleep(10000) -- 10ms delay
    end

    -- Select sound
    local sound = nil
    if direction == "back" then
        sound = State.backSound
    else
        sound = keyType == "arrow" and State.dissonantSounds[direction] or State.sounds[direction]
    end

    -- Play sound
    if sound then
        State.activeSound = sound
        sound:volume(VOLUME.NORMAL)
        local success = pcall(function() sound:play() end)
        if success then
            print("Successfully playing sound for " .. direction)
        else
            print("Error playing sound for " .. direction)
        end
        return success
    end

    return false
end

-- Toggle mute state
function M.toggleMute()
    State.silentMode = not State.silentMode
    local message = State.silentMode and "🔇 Sound Off" or "🔊 Sound On"
    hs.alert.show(message, 1)
    print("Silent mode:", State.silentMode)
    return State.silentMode
end

-- Cleanup
function M.cleanup()
    if M.escWatcher then M.escWatcher:stop() end
    if State.activeSound then State.activeSound:stop() end
    State.sounds = {}
    State.dissonantSounds = {}
    State.backSound = nil
    State.silentMode = false
end

return M
