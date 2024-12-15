--[[
    Animation utility module for the Arrows system - Simplified Version
    Handles window fading and celebration effects
]]

local M = {}

-- Animation state
local State = {
	celebrationTimer = nil,
	isCelebrating = false,
	timers = {}
}

-- Constants
local ANIMATION = {
	FADE_DURATION = 0.5,    -- Duration of fade in seconds (reduced for snappier feedback)
	FADE_STEPS = 8,        -- Number of steps in fade (reduced for smoother performance)
	CELEBRATION_DURATION = 1.5,  -- How long celebration lasts (reduced to match feedback timing)
	CELEBRATION_REPEATS = 2,     -- Number of celebration repeats (reduced for less intrusion)
	CELEBRATION_DELAY = 0.15     -- Delay between celebration repeats (increased for smoother animation)
}

-- Fade out a window
function M.fadeOut(webview, callback)
	if not webview or not webview:hswindow() or not webview:hswindow():isVisible() then
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

	-- Create fade steps
	for i = 1, ANIMATION.FADE_STEPS do
		State.timers[i] = hs.timer.doAfter(i * stepTime, function()
			if webview and webview:hswindow() and webview:hswindow():isVisible() then
				webview:alpha(1.0 - (i / ANIMATION.FADE_STEPS))
			else
				-- Cancel remaining timers if window is gone
				for j = i + 1, ANIMATION.FADE_STEPS do
					if State.timers[j] then State.timers[j]:stop() end
				end
			end
		end)
	end

	-- Call completion handler
	if callback then
		hs.timer.doAfter(ANIMATION.FADE_DURATION + 0.01, function()
			if webview and webview:hswindow() and webview:hswindow():isVisible() then
				callback()
			end
		end)
	end
end

-- Trigger celebration animation
function M.triggerCelebration()
	if State.isCelebrating then return false end

	print("🎉 Starting celebration sequence!")
	State.isCelebrating = true

	-- Create celebration script
	local script = string.format([[
		tell application "System Events"
			repeat %d times
				key code 126 using {command down, option down, control down, shift down}
				delay %f
			end repeat
		end tell
	]], ANIMATION.CELEBRATION_REPEATS, ANIMATION.CELEBRATION_DELAY)

	-- Run celebration
	local task = hs.task.new("/usr/bin/osascript", function(exitCode, stdOut, stdErr)
		if exitCode == 0 then
			print("✨ Celebration sequence completed successfully")
		else
			print("❌ Error running celebration sequence:", stdErr)
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
