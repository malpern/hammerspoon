--[[
    View module for the Arrows system - Simplified Version
    Handles HTML generation for arrow key display
]]

local M = {}

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
    }
}

local SYMBOLS = {
    up = "↑",
    down = "↓",
    left = "←",
    right = "→",
    back = "▲"
}

local LABELS = {
    up = "K",
    down = "J",
    left = "H",
    right = "L",
    back = "Back"
}

function M.generateWindowHtml(direction, keyType)
    local isArrowKey = keyType == "arrow"
    local colors = isArrowKey and COLORS.ARROW or COLORS.VIM
    
    -- For arrow keys: label on top, symbol below
    -- For vim keys: symbol on top, label below
    local firstContent = isArrowKey and LABELS[direction] or SYMBOLS[direction]
    local secondContent = isArrowKey and SYMBOLS[direction] or LABELS[direction]
    local firstColor = isArrowKey and colors.LABEL or colors.SYMBOL
    local secondColor = isArrowKey and colors.SYMBOL or colors.LABEL

    -- Special case for back button
    local secondMargin = direction == "back" and "0px" or "5px"

    return string.format([[
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                html, body { 
                    background: transparent !important;
                    height: 100vh;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    overflow: hidden;
                }
            </style>
        </head>
        <body>
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
                transition: all 0.2s ease;
                font-size: 48px;
            ">
                <div style="
                    font-family: %s;
                    color: %s;
                    font-size: 1em;
                    font-weight: 600;
                ">%s</div>
                <div style="
                    font-family: %s;
                    color: %s;
                    font-size: 0.8em;
                    font-weight: 600;
                    margin-top: %s;
                ">%s</div>
            </div>
        </body>
        </html>
    ]], colors.BG, 
        (isArrowKey or firstContent == SYMBOLS[direction]) and "'SF Pro', sans-serif" or "'Proxima Nova', 'SF Pro', sans-serif",
        firstColor, 
        firstContent,
        (isArrowKey or secondContent == SYMBOLS[direction]) and "'SF Pro', sans-serif" or "'Proxima Nova', 'SF Pro', sans-serif",
        secondColor,
        secondMargin,
        secondContent)
end

-- Simplified arrow-only display for special cases
function M.generateArrowHtml(direction, keyType)
    local isArrowKey = keyType == "arrow"
    local colors = isArrowKey and COLORS.ARROW or COLORS.VIM
    
    return string.format([[
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <style>
                * { margin: 0; padding: 0; }
                html, body { 
                    background: transparent !important;
                    height: 100vh;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                }
            </style>
        </head>
        <body>
            <div style="
                background-color: %s;
                border-radius: 12px;
                width: 90px;
                height: 120px;
                display: flex;
                align-items: center;
                justify-content: center;
                box-shadow: 0 0 5px rgba(0, 0, 0, 0.5);
                transition: all 0.2s ease;
                font-size: 48px;
            ">
                <div style="
                    font-family: 'SF Pro', sans-serif;
                    color: %s;
                    font-size: 1em;
                    font-weight: 600;
                ">%s</div>
            </div>
        </body>
        </html>
    ]], colors.BG, colors.SYMBOL, SYMBOLS[direction])
end

return M
