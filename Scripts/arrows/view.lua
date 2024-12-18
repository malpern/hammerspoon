--[[
    View module for the Arrows system - Simplified Version
    Handles HTML generation for arrow key display
]]

local M = {}
local debug = require("Scripts.arrows.utils.debug")

-- Constants
local COLORS = {
    VIM = {
        BG = "#1E1E1E",
        SYMBOL = "white",
        LABEL = "#666666"
    },
    ARROW = {
        BG = "#B40000",
        SYMBOL = "#4B0000",
        LABEL = "white"
    },
    VIM_HIGHLIGHT = {
        BG = "white",
        SYMBOL = "#666666",
        LABEL = "black"
    }
}

local SYMBOLS = {
    up = "↑",
    down = "↓",
    left = "←",
    right = "→",
    back = "▲",
    forward = "▼"
}

local LABELS = {
    up = "K",
    down = "J",
    left = "H",
    right = "L",
    back = "Back",
    forward = "Forward"
}

-- Generate a single key preview
local function generateKeyPreview(direction, keyType, isPressed)
    local colors
    local isArrowHighlight = keyType == "arrow" and isPressed
    local isVimHighlight = keyType == "vim" and isPressed
    
    if isArrowHighlight then
        colors = COLORS.ARROW
    elseif isVimHighlight then
        colors = COLORS.VIM_HIGHLIGHT
    else
        colors = COLORS.VIM
    end
    
    local symbol = SYMBOLS[direction]
    local label = LABELS[direction]
    
    -- For highlighted keys (both arrow and vim): label on top, symbol below
    -- For normal vim keys: symbol on top, label below
    local firstContent = (isArrowHighlight or isVimHighlight) and label or symbol
    local secondContent = (isArrowHighlight or isVimHighlight) and symbol or label
    local firstColor = (isArrowHighlight or isVimHighlight) and colors.LABEL or colors.SYMBOL
    local secondColor = (isArrowHighlight or isVimHighlight) and colors.SYMBOL or colors.LABEL

    -- Determine font sizes
    local isBackForward = direction == "back" or direction == "forward"
    local symbolSize = "0.836em"  -- 0.88em * 0.95 (5% smaller)
    local labelSize
    if direction == "forward" then
        labelSize = "0.462em"
    elseif direction == "back" then
        labelSize = "0.6em"
    else
        labelSize = "1em"  -- Default size for HJKL
    end

    -- Set sizes based on content type and position
    local firstFontSize, secondFontSize
    if isBackForward then
        if isArrowHighlight or isVimHighlight then
            -- Label on top, symbol below for highlighted Back/Forward
            firstFontSize = labelSize
            secondFontSize = symbolSize
        else
            -- Symbol on top, label below for normal Back/Forward
            firstFontSize = symbolSize
            secondFontSize = labelSize
        end
    else
        -- Normal HJKL sizing
        firstFontSize = (isArrowHighlight or isVimHighlight) and "1em" or "0.8em"
        secondFontSize = (isArrowHighlight or isVimHighlight) and "0.8em" or "0.8em"
    end

    return string.format([[
        <div style="
            background-color: %s;
            border-radius: 12px;
            width: 90px;
            height: 120px;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            box-shadow: 0 0 5px rgba(0, 0, 0, 0.5);
            font-size: 48px;
        ">
            <div style="
                font-family: 'SF Pro Display', 'SF Pro', -apple-system, BlinkMacSystemFont, sans-serif;
                color: %s;
                font-size: %s;
                font-weight: 700;
            ">%s</div>
            <div style="
                font-family: 'SF Pro Display', 'SF Pro', -apple-system, BlinkMacSystemFont, sans-serif;
                color: %s;
                font-size: %s;
                font-weight: 600;
                margin-top: 2px;
            ">%s</div>
        </div>
    ]], colors.BG, firstColor, firstFontSize, firstContent, secondColor, secondFontSize, secondContent)
end

function M.generateWindowHtml(direction, keyType)
    -- Determine which set of keys to show based on direction
    local directions
    if direction == "back" or direction == "forward" then
        directions = {"back", "forward"}  -- Show B and F keys
    else
        directions = {"left", "down", "up", "right"}  -- Show HJKL keys
    end
    
    local keysHtml = ""
    
    -- Generate all keys but with different display styles
    for _, dir in ipairs(directions) do
        local isPressed = direction and dir == direction
        local keyHtml = generateKeyPreview(dir, keyType, isPressed)
        
        keysHtml = keysHtml .. string.format([[
            <div style="display: %s">%s</div>
        ]], isPressed and "block" or "none", keyHtml)
    end
    
    return string.format([[
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body { 
                    background: transparent !important;
                    margin: 0;
                    padding: 0;
                    height: 132px;
                    display: flex;
                    align-items: center;
                }
                #container {
                    display: flex;
                    gap: 10px;
                    border: 2px solid red;
                    padding: 4px;
                }
            </style>
        </head>
        <body>
            <div id="container">%s</div>
            <script>
                setTimeout(function() {
                    document.querySelectorAll('div > div').forEach(function(key) {
                        if (key.style.display === 'none') {
                            key.style.display = 'block';
                        }
                    });
                }, 30);
            </script>
        </body>
        </html>
    ]], keysHtml)
end

return M
