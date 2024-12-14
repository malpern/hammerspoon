--[[
    Animation utility module for the Arrows system
    
    This module handles all animation-related functionality including:
    - Window fade animations
    - Celebration animations
    - Timing coordination

    Return values:
    - fadeOut() returns nil but must execute callback on completion
    - triggerCelebration() returns boolean - true if celebration started
    - nil returns indicate bugs and are NOT valid
]]

local model = require("Scripts.arrows.model")

local M = {}

-- Animation state types
---@class FadeState
---@field currentStep number Current step in fade animation
---@field timer userdata|nil Timer for fade animation
---@field webview userdata|nil Webview being faded
---@field callback function|nil Function to call on completion

---@class CelebrationState
---@field celebrationTimer userdata|nil Timer for celebration sequence
---@field isCelebrating boolean Whether celebration is in progress
---@field script string|nil Current celebration script
---@field repeatCount number Number of remaining repeats
---@field repeatDelay number Delay between repeats

-- Animation state
---@class AnimationState
---@field celebrationTimer userdata|nil Timer for celebration sequence
---@field isCelebrating boolean Whether celebration is in progress
---@field repeatCount number Number of remaining celebration repeats
---@field timers table<number, userdata> Active fade timers
local State = {
    celebrationTimer = nil,
    isCelebrating = false,
    repeatCount = 0,
    timers = {}
}

---@param webview userdata The webview to fade out
---@param callback function Function to call when fade is complete
---@return nil
function M.fadeOut(webview, callback)
    -- Check if webview is valid and visible
    if not webview or type(webview) ~= "userdata" or not webview:hswindow() or not webview:hswindow():isVisible() then
        print("Error: Invalid webview provided for fade out")
        if callback then callback() end
        return
    end
    
    local style = model.Style.ANIMATION
    local steps = style.FADE_STEPS
    local fadeTime = style.FADE_DURATION
    local stepTime = fadeTime / steps
    
    -- Clean up any existing timers
    for _, timer in pairs(State.timers) do
        if timer then timer:stop() end
    end
    State.timers = {}
    
    -- Create fade steps
    for i = 1, steps do
        State.timers[i] = hs.timer.doAfter(i * stepTime, function()
            -- Check if webview still exists and is visible
            if webview and type(webview) == "userdata" and webview:hswindow() and webview:hswindow():isVisible() then
                webview:alpha(1.0 - (i/steps))
            else
                -- Cancel remaining timers if webview is no longer valid
                for j = i + 1, steps do
                    if State.timers[j] then
                        State.timers[j]:stop()
                    end
                end
            end
        end)
    end
    
    -- Call completion handler after fade
    if callback then
        hs.timer.doAfter(fadeTime + style.TRANSITION_DELAY, function()
            -- Check if webview still exists and is visible
            if webview and type(webview) == "userdata" and webview:hswindow() and webview:hswindow():isVisible() then
                callback()
            end
        end)
    end
end

---@return boolean success Whether celebration was triggered successfully
function M.triggerCelebration()
    -- Don't start new celebration if one is in progress
    if State.isCelebrating then
        return false
    end
    
    print("🎉 Starting celebration sequence!")
    State.isCelebrating = true
    State.repeatCount = model.Timing.CELEBRATION.REPEAT_COUNT
    
    -- Create celebration script with repeat configuration
    local script = string.format([[
        tell application "System Events"
            repeat %d times
                key code %d using {command down, option down, control down, shift down}
                delay %f
            end repeat
        end tell
    ]], 
    model.Timing.CELEBRATION.REPEAT_COUNT,
    model.SpecialKeys.CELEBRATION,
    model.Timing.CELEBRATION.REPEAT_DELAY)
    
    -- Run celebration script with callback
    local task = hs.task.new("/usr/bin/osascript", function(exitCode, stdOut, stdErr)
        if exitCode == 0 then
            print("✨ Celebration sequence completed successfully")
            State.isCelebrating = false
            State.celebrationTimer = nil
            return true
        else
            print("❌ Error running celebration sequence:", stdErr)
            State.isCelebrating = false
            State.celebrationTimer = nil
            return false
        end
    end, {"-e", script})
    
    -- Set timeout to ensure celebration ends
    State.celebrationTimer = hs.timer.doAfter(model.Timing.CELEBRATION.DURATION, function()
        State.isCelebrating = false
        State.celebrationTimer = nil
    end)
    
    return task:start()
end

return M 