--[[
    🔊 Sound System for Arrows
    
    Features:
    🎵 Directional sounds for vim keys
    🎶 Dissonant sounds for arrow keys
    🔇 Mute toggle with double-ESC
    ⏱️  Sound debouncing
]]

local M = {}
local debug = require("Scripts.arrows.utils.debug")

-- Sound state
local State = {
    sounds = {},            -- 🎵 Normal sounds
    dissonantSounds = {},   -- 🎶 Dissonant sounds
    backSound = nil,        -- ⬆️ Back sound
    silentMode = false,     -- 🔇 Mute state
    activeSound = nil,      -- 🎧 Currently playing
    lastPlayTime = 0,       -- ⏱️ Debounce timer
    lastEscTime = nil,      -- ⌨️ Last ESC press
    escKeyDown = false      -- ⬇️ ESC key state
}

-- Constants
local VOLUME = {
    NORMAL = 0.2,  -- 🔊 Normal volume
    MUTED = 0.0    -- 🔇 Muted volume
}

local DOUBLE_PRESS_TIME = 0.3  -- ⚡ 300ms for double-tap
local DEBOUNCE_TIME = 0.01     -- ⏱️ 10ms for transitions

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
            debug.log("🎵 Loaded sound for " .. direction)
        else
            success = false
            debug.error("🚫 Failed to load sound: " .. path)
        end
    end

    -- Load dissonant sounds
    for _, direction in ipairs({ "up", "down", "left", "right" }) do
        local path = configPath .. "dissonant/" .. direction .. ".wav"
        local sound = hs.sound.getByFile(path)
        if sound then
            State.dissonantSounds[direction] = sound
            sound:volume(VOLUME.NORMAL)
            debug.log("🎶 Loaded dissonant sound for " .. direction)
        else
            success = false
            debug.error("🚫 Failed to load dissonant sound: " .. path)
        end
    end

    -- Load back sounds (both normal and dissonant)
    local backPath = configPath .. "backward.wav"
    local dissonantBackPath = configPath .. "dissonant/backward.wav"
    
    -- Normal back sound
    local backSound = hs.sound.getByFile(backPath)
    if backSound then
        State.backSound = backSound
        backSound:volume(VOLUME.NORMAL)
        debug.log("⬆️ Loaded sound for back")
    else
        success = false
        debug.error("🚫 Failed to load back sound: " .. backPath)
    end

    -- Dissonant back sound
    local dissonantBackSound = hs.sound.getByFile(dissonantBackPath)
    if dissonantBackSound then
        State.dissonantSounds["back"] = dissonantBackSound
        dissonantBackSound:volume(VOLUME.NORMAL)
        debug.log("🎶 Loaded dissonant sound for back")
    else
        success = false
        debug.error("🚫 Failed to load dissonant back sound: " .. dissonantBackPath)
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
        debug.log("🔇 Silent mode active, skipping sound")
        return true
    end

    -- Debounce
    local currentTime = hs.timer.secondsSinceEpoch()
    if currentTime - State.lastPlayTime < DEBOUNCE_TIME then
        debug.log("⏱️ Debouncing sound playback")
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
        sound = keyType == "arrow" and State.dissonantSounds[direction] or State.backSound
    else
        sound = keyType == "arrow" and State.dissonantSounds[direction] or State.sounds[direction]
    end

    -- Play sound
    if sound then
        State.activeSound = sound
        sound:volume(VOLUME.NORMAL)
        local success = pcall(function() sound:play() end)
        if success then
            debug.log("🎵 Playing " .. (keyType == "arrow" and "dissonant" or "normal") .. " sound for " .. direction)
        else
            debug.error("🚫 Error playing sound for " .. direction)
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
    debug.log("🎚️ Silent mode:", State.silentMode)
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
