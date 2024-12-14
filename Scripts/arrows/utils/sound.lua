--[[
    Sound utility module for the Arrows system
    
    This module handles all sound-related functionality including:
    - Sound file loading and management
    - Sound playback with debouncing
    - Volume control and muting
    - Sound state management
    - Escape key handling for sound toggling

    Return values:
    - init() returns boolean - true if all sounds loaded successfully
    - cleanup() returns nil but must clean up all resources
    - playSound() returns boolean - true if sound played successfully
    - toggleMute() returns boolean - new mute state
    - nil returns indicate bugs and are NOT valid
]]

local model = require("Scripts.arrows.model")

local M = {}

-- Sound configuration types
---@class VolumeConfig
---@field NORMAL number Normal volume level (0.0 to 1.0)
---@field MUTED number Muted volume level (always 0.0)

---@class PathConfig
---@field NORMAL string Pattern for normal sound files
---@field DISSONANT string Pattern for dissonant sound files
---@field BACK string Path for back command sound

-- Sound Configuration
---@class SoundConfig
---@field VOLUME VolumeConfig Volume levels
---@field PATHS PathConfig Sound file paths
local SoundConfig = {
	VOLUME = {
		NORMAL = 0.2, -- Normal volume level
		MUTED = 0.0, -- Muted volume level
	},
	PATHS = {
		NORMAL = "%s.wav", -- Pattern for normal sounds
		DISSONANT = "dissonant/%s.wav", -- Pattern for dissonant sounds
		BACK = "up_deeper.wav", -- Back command sound
	},
}

-- Sound state
---@class SoundState
---@field sounds table<string, userdata> Normal sound objects
---@field dissonantSounds table<string, userdata> Dissonant sound objects
---@field backSound userdata Back command sound
---@field silentMode boolean Whether sound is muted
---@field activeSound userdata|nil Currently playing sound
---@field lastPlayTime number Timestamp of last sound play
---@field lastEscTime number|nil Timestamp of last escape press
---@field escKeyDown boolean Whether escape key is currently down
local State = {
	sounds = {},
	dissonantSounds = {},
	backSound = nil,
	silentMode = false,
	activeSound = nil,
	lastPlayTime = 0,
	lastEscTime = nil,
	escKeyDown = false,
}

-- Expose state for testing
M.sounds = State.sounds
M.dissonantSounds = State.dissonantSounds
M.backSound = State.backSound
M.silentMode = State.silentMode

---@param direction string The direction to get sound path for
---@param isDissonant boolean Whether to get dissonant sound
---@return string path The full path to the sound file
local function getSoundPath(direction, isDissonant)
	local basePath = hs.configdir .. "/sounds/"
	if direction == model.Direction.BACK then
		return basePath .. SoundConfig.PATHS.BACK
	end
	local pattern = isDissonant and SoundConfig.PATHS.DISSONANT or SoundConfig.PATHS.NORMAL
	return basePath .. string.format(pattern, string.lower(direction))
end

---@return boolean success Whether all sounds were loaded successfully
function M.init()
	-- Reset timing variables
	State.lastPlayTime = 0
	State.lastEscTime = nil
	State.escKeyDown = false

	local success = true

	-- Load normal sounds
	for direction in pairs(model.Direction) do
		if direction ~= "BACK" then
			local path = getSoundPath(direction, false)
			local sound = hs.sound.getByFile(path)
			if sound then
				State.sounds[string.lower(direction)] = sound
				sound:volume(SoundConfig.VOLUME.NORMAL)
				print(string.format("Successfully loaded sound for %s", direction))
			else
				success = false
				print(string.format("Failed to load sound: %s", path))
			end
		end
	end

	-- Load dissonant sounds
	for direction in pairs(model.Direction) do
		if direction ~= "BACK" then
			local path = getSoundPath(direction, true)
			local sound = hs.sound.getByFile(path)
			if sound then
				State.dissonantSounds[string.lower(direction)] = sound
				sound:volume(SoundConfig.VOLUME.NORMAL)
				print(string.format("Successfully loaded dissonant sound for %s", direction))
			else
				success = false
				print(string.format("Failed to load dissonant sound: %s", path))
			end
		end
	end

	-- Load back sound
	local backPath = getSoundPath(model.Direction.BACK, false)
	local backSound = hs.sound.getByFile(backPath)
	if backSound then
		State.backSound = backSound
		backSound:volume(SoundConfig.VOLUME.NORMAL)
		print("Successfully loaded sound for back")
	else
		success = false
		print(string.format("Failed to load back sound: %s", backPath))
	end

	-- Set up escape key watchers for silent mode toggle
	M.escWatcher = hs.eventtap
		.new({ hs.eventtap.event.types.keyDown, hs.eventtap.event.types.keyUp }, function(event)
			local keyCode = event:getKeyCode()
			local eventType = event:getType()

			if keyCode == model.SpecialKeys.ESCAPE then
				local currentTime = hs.timer.secondsSinceEpoch()

				if eventType == hs.eventtap.event.types.keyDown then
					-- If escape is already down, this is a repeat event - ignore it
					if State.escKeyDown then
						return false
					end

					State.escKeyDown = true

					-- If this is the first press in a sequence
					if not State.lastEscTime then
						State.lastEscTime = currentTime
						return false -- Let the first press through
					end

					-- This is a second press, check if it's within the double-tap window
					local timeDiff = currentTime - State.lastEscTime
					if timeDiff < model.Timing.KEY.DOUBLE_PRESS then
						M.toggleMute()
						State.lastEscTime = nil
						return true -- Capture the second press
					end

					-- Too slow, treat as new first press
					State.lastEscTime = currentTime
					return false
				elseif eventType == hs.eventtap.event.types.keyUp then
					State.escKeyDown = false

					-- If no second press came quickly enough, reset the sequence
					if State.lastEscTime and (currentTime - State.lastEscTime) >= model.Timing.KEY.DOUBLE_PRESS then
						State.lastEscTime = nil
					end

					return false
				end
			end

			return false
		end)
		:start()

	-- Update exposed state
	M.sounds = State.sounds
	M.dissonantSounds = State.dissonantSounds
	M.backSound = State.backSound

	return success
end

---@return nil
function M.cleanup()
	-- Stop escape key watcher
	if M.escWatcher then
		M.escWatcher:stop()
	end

	-- Stop any playing sounds
	if State.activeSound then
		State.activeSound:stop()
		State.activeSound = nil
	end

	-- Clear sound objects
	State.sounds = {}
	State.dissonantSounds = {}
	State.backSound = nil
	State.silentMode = false

	-- Update exposed state
	M.sounds = State.sounds
	M.dissonantSounds = State.dissonantSounds
	M.backSound = State.backSound
	M.silentMode = State.silentMode
end

---@param direction string The direction to play sound for
---@param keyType string The type of key pressed
---@return boolean success Whether the sound was played successfully
function M.playSound(direction, keyType)
	if State.silentMode then
		print("Silent mode active, skipping sound")
		return true
	end

	-- Debounce sound playback
	local currentTime = hs.timer.secondsSinceEpoch()
	if currentTime - State.lastPlayTime < model.Style.ANIMATION.TRANSITION_DELAY then
		print("Debouncing sound playback")
		return true
	end
	State.lastPlayTime = currentTime

	-- Stop currently playing sound and wait for transition
	if State.activeSound and State.activeSound:isPlaying() then
		print("Stopping previous sound")
		State.activeSound:stop()
		hs.timer.usleep(model.Style.ANIMATION.TRANSITION_DELAY * 1000000) -- Convert to microseconds
	end

	-- Select appropriate sound
	local sound = nil
	if direction == model.Direction.BACK then
		sound = State.backSound
	else
		local dirLower = string.lower(direction)
		sound = keyType == model.KeyType.ARROW and State.dissonantSounds[dirLower] or State.sounds[dirLower]
	end

	-- Play sound if available
	if sound then
		State.activeSound = sound
		sound:volume(SoundConfig.VOLUME.NORMAL)
		-- Use pcall to catch any playback errors
		local success, err = pcall(function()
			sound:play()
		end)
		if success then
			print(string.format("Successfully playing sound for %s", direction))
		else
			print(string.format("Error playing sound for %s: %s", direction, tostring(err)))
		end
		return success
	end

	return false
end

---@return boolean muted The new mute state
function M.toggleMute()
	State.silentMode = not State.silentMode
	M.silentMode = State.silentMode

	-- Show feedback
	local message = State.silentMode and "🔇 Sound Off" or "🔊 Sound On"
	hs.alert.show(message, 1)
	print("Silent mode:", State.silentMode)

	return State.silentMode
end

return M
