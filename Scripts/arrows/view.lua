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
local function generateKeyPreview(direction, isHighlighted)
    local colors = isHighlighted and COLORS.ARROW or COLORS.VIM
    local symbol = SYMBOLS[direction]
    local label = LABELS[direction]
    
    -- For highlighted (arrow) keys: label on top, symbol below
    -- For normal (vim) keys: symbol on top, label below
    local firstContent = isHighlighted and label or symbol
    local secondContent = isHighlighted and symbol or label
    local firstColor = isHighlighted and colors.LABEL or colors.SYMBOL
    local secondColor = isHighlighted and colors.SYMBOL or colors.LABEL

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
            margin: 0 5px;
            box-shadow: 0 0 5px rgba(0, 0, 0, 0.5);
            font-size: 48px;
        ">
            <div style="
                font-family: 'SF Pro Display', 'SF Pro', -apple-system, BlinkMacSystemFont, sans-serif;
                color: %s;
                font-size: 1em;
                font-weight: 600;
            ">%s</div>
            <div style="
                font-family: 'SF Pro Display', 'SF Pro', -apple-system, BlinkMacSystemFont, sans-serif;
                color: %s;
                font-size: 0.8em;
                font-weight: 600;
                margin-top: 2px;
            ">%s</div>
        </div>
    ]], colors.BG, firstColor, firstContent, secondColor, secondContent)
end

function M.generateWindowHtml(direction, keyType)
    -- Only show HJKL keys
    local directions = {"left", "down", "up", "right"}
    local keysHtml = ""
    
    for _, dir in ipairs(directions) do
        local isHighlighted = keyType == "arrow" and dir == direction
        keysHtml = keysHtml .. generateKeyPreview(dir, isHighlighted)
    end
    
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
                display: flex;
                justify-content: center;
                align-items: center;
                gap: 10px;
                padding: 10px;
            ">
                %s
            </div>
        </body>
        </html>
    ]], keysHtml)
end

return M
