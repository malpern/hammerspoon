--[[
    View module for the Arrows system - Simplified Version
    Handles HTML generation for arrow key display
]]

local M = {}

-- Constants
local COLORS = {
    VIM = {
        BG = "rgba(30, 30, 30, 0.95)",
        SYMBOL = "white",
        LABEL = "#666666",
        BORDER = "#444444"
    },
    ARROW = {
        BG = "rgba(180, 0, 0, 0.95)",
        SYMBOL = "#FFFFFF",
        LABEL = "#FFCCCC",
        BORDER = "#990000"
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
                border: 3px solid %s;
                border-radius: 25px;
                width: 90px;
                height: 120px;
                display: flex;
                flex-direction: column;
                align-items: center;
                justify-content: center;
                font-family: -apple-system, 'SF Pro', sans-serif;
                box-shadow: 0 4px 12px rgba(0,0,0,0.2);
                transition: all 0.2s ease;
                -webkit-backdrop-filter: blur(10px);
                backdrop-filter: blur(10px);
            ">
                <div style="
                    color: %s;
                    font-size: 24px;
                    font-weight: 600;
                    margin: 4px;
                    text-shadow: 0 1px 2px rgba(0,0,0,0.1);
                ">%s</div>
                <div style="
                    color: %s;
                    font-size: 48px;
                    font-weight: 600;
                    margin: 4px;
                    text-shadow: 0 1px 2px rgba(0,0,0,0.1);
                ">%s</div>
            </div>
        </body>
        </html>
    ]], colors.BG, colors.BORDER, firstColor, firstContent, secondColor, secondContent)
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
                border: 10px solid red;
                border-radius: 45px;
                width: 90px;
                height: 120px;
                display: flex;
                align-items: center;
                justify-content: center;
                font-family: 'SF Pro', sans-serif;
                box-shadow: 0 0 5px rgba(0,0,0,0.5);
                transition: all 0.2s ease;
            ">
                <div style="
                    color: %s;
                    font-size: 48px;
                    font-weight: 600;
                ">%s</div>
            </div>
        </body>
        </html>
    ]], colors.BG, colors.SYMBOL, SYMBOLS[direction])
end

return M
