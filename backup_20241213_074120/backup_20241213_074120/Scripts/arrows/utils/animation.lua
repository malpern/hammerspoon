--[[
    Animation utility module for the Arrows system
    
    This module handles all animation-related functionality including:
    - Window fade animations
    - Celebration animations
    - Timing coordination
]]

local model = require("arrows.model")

local M = {}

-- Fade out a webview
---@param webview userdata The webview to fade out
---@param onComplete function|nil Optional callback to run after fade completes
function M.fadeOut(webview, onComplete)
    local style = model.Style.ANIMATION
    local steps = style.FADE_STEPS
    local fadeTime = style.FADE_DURATION
    local stepTime = fadeTime / steps
    
    -- Only proceed if webview exists and is visible
    if webview and webview:isVisible() then
        for i = 1, steps do
            hs.timer.doAfter(i * stepTime, function()
                if webview and webview:isVisible() then
                    webview:alpha(1.0 - (i/steps))
                end
            end)
        end
        
        -- Call completion handler after fade
        if onComplete then
            hs.timer.doAfter(fadeTime + style.TRANSITION_DELAY, onComplete)
        end
    end
end

-- Create celebration animation
---@return boolean success Whether the celebration was triggered successfully
function M.triggerCelebration()
    print("🎉 Starting celebration sequence!")
    
    -- Use osascript to trigger the keyboard shortcut
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
    
    local task = hs.task.new("/usr/bin/osascript", nil, function(exitCode, stdOut, stdErr)
        if exitCode == 0 then
            print("✨ Celebration sequence completed successfully")
            return true
        else
            print("❌ Error running celebration sequence:", stdErr)
            return false
        end
    end, {"-e", script})
    
    return task:start()
end

return M 