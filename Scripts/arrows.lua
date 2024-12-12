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
            font-family: Arial, sans-serif;
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
        }
        .arrow-block {
            background-color: rgba(30, 30, 30, 1);
            border-radius: 20px;
            padding: 25px;
            text-align: center;
            font-size: 64px;
            box-shadow: 0 0 5px rgba(0, 0, 0, 0.5);
            text-shadow: 
                1px 1px 0 white,
                -1px -1px 0 white,
                1px -1px 0 white,
                -1px 1px 0 white;
            line-height: 0.8;
            display: flex;
            justify-content: center;
            align-items: center;
            min-width: 64px;
            min-height: 64px;
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
local arrows = {
    up = "↑",
    down = "↓",
    left = "←",
    right = "→"
}

local function showArrow(direction)
    -- Close any existing webview
    if activeWebview then
        activeWebview:delete()
        activeWebview = nil
    end
    
    -- Get the main screen's frame
    local screen = hs.screen.mainScreen()
    local frame = screen:frame()
    
    -- Create a smaller window size to match key size
    local width = 120
    local height = 120
    
    -- Calculate center position
    local x = frame.x + (frame.w - width) / 2
    local y = frame.y + (frame.h - height) / 2
    
    -- Create the webview
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
    
    -- Set timer to fade out after 1 seconds (giving 0.5 seconds for fade)
    hs.timer.doAfter(1, function()
        if activeWebview then
            -- Create a fade effect over 0.5 seconds
            local steps = 10
            local fadeTime = 0.1
            local stepTime = fadeTime / steps
            local alphaStep = 1.0 / steps
            
            for i = 1, steps do
                hs.timer.doAfter(i * stepTime, function()
                    if activeWebview then
                        activeWebview:alpha(1.0 - (i * alphaStep))
                    end
                end)
            end
            
            -- Delete after fade completes
            hs.timer.doAfter(fadeTime, function()
                if activeWebview then
                    activeWebview:delete()
                    activeWebview = nil
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