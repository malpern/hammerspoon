--[[
    🔊 Sound System for Arrows
    
    Features:
    🎵 Directional sounds for vim keys
    🎶 Dissonant sounds for arrow keys
    🔇 Mute toggle with double-ESC
    ⏱️  Sound debouncing
    🎯 Rapid-fire prevention for VIM keys
]]

local M = {}
local debug = require("Scripts.arrows.utils.debug")

local SOUND_ENABLED = false -- set to true to enable sounds by default

-- Sound state
local State = {
    sounds = {},            -- 🎵 Normal sounds
    dissonantSounds = {},   -- 🎶 Dissonant sounds
    backSound = nil,        -- ⬆️ Back sound
    forwardSound = nil,     -- ⬇️ Forward sound
    silentMode = not SOUND_ENABLED, -- 🔇 Mute state
    activeSound = nil,      -- 🎧 Currently playing
    lastPlayTime = 0,       -- ⏱️ Debounce timer
    lastEscTime = nil,      -- ⌨️ Last ESC press
    escKeyDown = false,     -- ⬇️ ESC key state
    lastVimDirection = nil, -- 🎯 Last VIM key pressed
    lastVimTime = 0        -- ⏱️ Time of last VIM key press
}

-- Constants
local VOLUME = {
    NORMAL = 0.2,  -- 🔊 Normal volume
    MUTED = 0.0    -- 🔇 Muted volume
}

local DOUBLE_PRESS_TIME = 0.3   -- ⚡ 300ms for double-tap
local DEBOUNCE_TIME = 0.01      -- ⏱️ 10ms for transitions
local VIM_TIMEOUT = 0.2         -- 🎯 200ms timeout for VIM key sound prevention

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

    -- Load back/forward sounds (both normal and dissonant)
    local backPath = configPath .. "backward.wav"
    local forwardPath = configPath .. "forward.wav"
    local dissonantBackPath = configPath .. "dissonant/backward.wav"
    local dissonantForwardPath = configPath .. "dissonant/forward.wav"
    
    -- Normal back/forward sounds
    local backSound = hs.sound.getByFile(backPath)
    local forwardSound = hs.sound.getByFile(forwardPath)
    if backSound then
        State.backSound = backSound
        backSound:volume(VOLUME.NORMAL)
        debug.log("⬆️ Loaded sound for back")
    else
        success = false
        debug.error("🚫 Failed to load back sound: " .. backPath)
    end
    if forwardSound then
        State.forwardSound = forwardSound
        forwardSound:volume(VOLUME.NORMAL)
        debug.log("⬇️ Loaded sound for forward")
    else
        success = false
        debug.error("🚫 Failed to load forward sound: " .. forwardPath)
    end

    -- Dissonant back/forward sounds
    local dissonantBackSound = hs.sound.getByFile(dissonantBackPath)
    local dissonantForwardSound = hs.sound.getByFile(dissonantForwardPath)
    if dissonantBackSound then
        State.dissonantSounds["back"] = dissonantBackSound
        dissonantBackSound:volume(VOLUME.NORMAL)
        debug.log("🎶 Loaded dissonant sound for back")
    else
        success = false
        debug.error("🚫 Failed to load dissonant back sound: " .. dissonantBackPath)
    end
    if dissonantForwardSound then
        State.dissonantSounds["forward"] = dissonantForwardSound
        dissonantForwardSound:volume(VOLUME.NORMAL)
        debug.log("🎶 Loaded dissonant sound for forward")
    else
        success = false
        debug.error("🚫 Failed to load dissonant forward sound: " .. dissonantForwardPath)
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

    local currentTime = hs.timer.secondsSinceEpoch()

    -- For VIM keys, prevent rapid-fire sounds within timeout window
    if keyType == "vim" then
        if direction == State.lastVimDirection and 
           (currentTime - State.lastVimTime) < VIM_TIMEOUT then
            debug.log("🔄 Rapid VIM key repeat, skipping sound")
            return true
        end
        State.lastVimDirection = direction
        State.lastVimTime = currentTime
    end

    -- For arrow keys, reset the VIM tracking
    if keyType == "arrow" then
        State.lastVimDirection = nil
        State.lastVimTime = 0
    end

    -- Debounce
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
        sound = keyType == "arrow" and State.dissonantSounds["back"] or State.backSound
    elseif direction == "forward" then
        sound = keyType == "arrow" and State.dissonantSounds["forward"] or State.forwardSound
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
    State.forwardSound = nil
    State.silentMode = false
end

return M
