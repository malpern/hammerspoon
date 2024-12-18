--[[
    ✨ Animation System for Arrows
    
    Features:
    🌟 Window fade effects
    🎉 Celebration animations
    ⚡ Fast performance
    🎨 Smooth transitions
]]

local M = {}
local debug = require("Scripts.arrows.utils.debug")

-- Animation state
local State = {
	celebrationTimer = nil,  -- ⏱️ Celebration timeout
	isCelebrating = false,   -- 🎉 Celebration state
	timers = {}             -- ⚡ Active fade timers
}

-- Constants
local ANIMATION = {
	FADE_DURATION = 0.5,     -- ⏱️ Fade duration (seconds)
	FADE_STEPS = 8,          -- 🎨 Fade smoothness
	CELEBRATION_DURATION = 1.5,  -- 🎉 Celebration length
	CELEBRATION_REPEATS = 2,     -- 🔄 Number of repeats
	CELEBRATION_DELAY = 0.15     -- ⏱️ Delay between repeats
}

-- Helper function to safely check webview
local function isValidWebview(wv)
	if not wv then return false end
	if type(wv) ~= "userdata" then return false end
	
	-- Safely check if methods exist and can be called
	local function safeCall(obj, method)
		local success = pcall(function() return obj[method] end)
		return success and type(obj[method]) == "function"
	end
	
	-- Check required methods
	if not safeCall(wv, "hswindow") then return false end
	
	-- Get window safely
	local success, window = pcall(function() return wv:hswindow() end)
	if not success or not window then return false end
	
	-- Check window visibility safely
	success, _ = pcall(function() return window:isVisible() end)
	return success
end

-- Fade out a window
function M.fadeOut(webview, callback)
	-- Early exit if webview is invalid
	if not isValidWebview(webview) then
		if callback then callback() end
		return
	end

	-- Clean up existing timers
	for _, timer in pairs(State.timers) do
		if timer then timer:stop() end
	end
	State.timers = {}

	-- Calculate fade steps
	local stepTime = ANIMATION.FADE_DURATION / ANIMATION.FADE_STEPS
	debug.log("🎨 Starting fade animation with", ANIMATION.FADE_STEPS, "steps")

	-- Create fade steps
	for i = 1, ANIMATION.FADE_STEPS do
		State.timers[i] = hs.timer.doAfter(i * stepTime, function()
			-- Check if webview is still valid before each step
			if isValidWebview(webview) then
				local success = pcall(function()
					webview:alpha(1.0 - (i / ANIMATION.FADE_STEPS))
				end)
				if not success then
					-- Cancel remaining timers if alpha setting fails
					for j = i + 1, ANIMATION.FADE_STEPS do
						if State.timers[j] then 
							State.timers[j]:stop() 
							State.timers[j] = nil
						end
					end
				end
			else
				-- Cancel remaining timers if window is invalid
				for j = i + 1, ANIMATION.FADE_STEPS do
					if State.timers[j] then 
						State.timers[j]:stop() 
						State.timers[j] = nil
					end
				end
			end
		end)
	end

	-- Call completion handler
	if callback then
		hs.timer.doAfter(ANIMATION.FADE_DURATION + 0.01, function()
			-- Final check before callback
			if isValidWebview(webview) then
				callback()
			end
		end)
	end
end

-- Trigger celebration animation
function M.triggerCelebration()
	if State.isCelebrating then return false end

	debug.log("🎉 Starting celebration sequence!")
	State.isCelebrating = true

	-- Create celebration script
	-- Note: Key code 35 is 'p'. Hyper+P triggers Raycast's confetti animation
	local script = string.format([[
		tell application "System Events"
			-- Trigger Raycast confetti animation with Hyper+P
			repeat %d times
				key code 35 using {command down, option down, control down, shift down}
				delay %f
			end repeat
		end tell
	]], ANIMATION.CELEBRATION_REPEATS, ANIMATION.CELEBRATION_DELAY)

	-- Run celebration
	local task = hs.task.new("/usr/bin/osascript", function(exitCode, stdOut, stdErr)
		if exitCode == 0 then
			debug.log("✨ Celebration sequence completed!")
		else
			debug.error("💥 Error running celebration sequence:", stdErr)
		end
		State.isCelebrating = false
		State.celebrationTimer = nil
		return exitCode == 0
	end, { "-e", script })

	-- Set timeout
	State.celebrationTimer = hs.timer.doAfter(ANIMATION.CELEBRATION_DURATION, function()
		State.isCelebrating = false
		State.celebrationTimer = nil
	end)

	return task:start()
end

return M
