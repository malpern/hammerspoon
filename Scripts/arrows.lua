local M = {}

-- Load required extensions
require("hs.webview")

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
            color: white;
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
            background-color: rgba(30, 30, 30, 1);
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
        font-weight: 600;
    '>%s</div>
    <div style='
        font-family: "Proxima Nova", "SF Pro", sans-serif;
        margin-top: %s;
        color: #666666;
        text-shadow: none;
        font-size: 0.7em;
        font-weight: 600;
    '>%s</div>
</div>
]]

local arrows = {
    up = string.format(arrowTemplate, "K", "15px", "↑"),
    down = string.format(arrowTemplate, "J", "15px", "↓"),
    left = string.format(arrowTemplate, "H", "10px", "←"),
    right = string.format(arrowTemplate, "L", "10px", "→")
}

-- Keep track of active timers
local fadeTimer = nil
local deleteTimer = nil

local function showArrow(direction)
    -- Cancel any existing timers
    if fadeTimer then
        fadeTimer:stop()
        fadeTimer = nil
    end
    if deleteTimer then
        deleteTimer:stop()
        deleteTimer = nil
    end

    -- Immediately remove any existing webview without waiting for fade
    if activeWebview then
        activeWebview:delete()
        activeWebview = nil
    end
    
    -- Create a window size that accommodates all content
    local width = 90  -- Increased from 80 to prevent truncation
    local height = 120  -- Increased from 110 to prevent truncation
    
    -- Get the main screen's frame
    local screen = hs.screen.mainScreen()
    local frame = screen:frame()
    
    -- Calculate top-right position with margins
    local x = frame.x + frame.w - width - 20
    local y = frame.y + 20
    
    -- Create the webview with some padding
    activeWebview = hs.webview.new({x = x, y = y, w = width, h = height})
    
    -- Configure the window properties
    activeWebview:windowStyle({"borderless", "closable", "nonactivating"})
    activeWebview:level(hs.drawing.windowLevels.floating)
    activeWebview:alpha(1.0)
    activeWebview:allowTextEntry(false)
    activeWebview:transparent(true)
    activeWebview:windowCallback(function(webview, message)
        -- Set corner radius when the window is created
        if message == "windowCreated" then
            local win = webview:hswindow()
            if win then
                win:setRoundedCorners(true)
                -- Try to force a more rounded appearance
                hs.execute([[defaults write org.hammerspoon.Hammerspoon NSWindowCornerRadius -float 10]])
            end
        end
    end)
    
    -- Replace ARROW placeholder with the correct arrow character
    local html = string.gsub(htmlTemplate, "ARROW", arrows[direction])
    activeWebview:html(html)
    
    -- Show the window
    activeWebview:show()
    
    -- Set timer to fade out after 3.5 seconds (giving 0.8 seconds for fade)
    fadeTimer = hs.timer.doAfter(2, function()
        -- Store reference to this specific webview instance
        local thisWebview = activeWebview
        -- Only proceed with fade if this specific webview is still active
        if thisWebview and thisWebview:isVisible() then
            local steps = 10
            local fadeTime = 0.8
            local stepTime = fadeTime / steps
            local alphaStep = 1.0 / steps
            
            for i = 1, steps do
                hs.timer.doAfter(i * stepTime, function()
                    -- Check if this specific webview is still active
                    if thisWebview and thisWebview:isVisible() then
                        thisWebview:alpha(1.0 - (i * alphaStep))
                    end
                end)
            end
            
            deleteTimer = hs.timer.doAfter(fadeTime, function()
                -- Check if this specific webview is still active
                if thisWebview and thisWebview:isVisible() then
                    thisWebview:delete()
                    if activeWebview == thisWebview then
                        activeWebview = nil
                    end
                end
            end)
        end
    end)
end

-- Create an event tap to watch for arrow keys
local keyWatcher = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
    local keyCode = event:getKeyCode()
    local keyMap = hs.keycodes.map
    
    print("Key pressed:", keyCode)  -- Debug output
    
    if keyCode == keyMap["up"] then
        print("Up arrow pressed")  -- Debug output
        showArrow("up")
    elseif keyCode == keyMap["down"] then
        print("Down arrow pressed")  -- Debug output
        showArrow("down")
    elseif keyCode == keyMap["left"] then
        print("Left arrow pressed")  -- Debug output
        showArrow("left")
    elseif keyCode == keyMap["right"] then
        print("Right arrow pressed")  -- Debug output
        showArrow("right")
    end
    
    return false  -- Return false to let the event pass through
end)

-- Start watching for key events
keyWatcher:start()