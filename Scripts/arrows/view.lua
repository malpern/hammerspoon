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

function M.generateWindowHtml(direction, keyType)
    local isArrowKey = keyType == "arrow"
    local isVimKey = not isArrowKey
    local colors = isArrowKey and COLORS.ARROW or COLORS.VIM
    
    -- For arrow keys: label on top, symbol below
    -- For vim keys: symbol on top, label below
    local firstContent = isArrowKey and LABELS[direction] or SYMBOLS[direction]
    local secondContent = isArrowKey and SYMBOLS[direction] or LABELS[direction]
    local firstColor = isArrowKey and colors.LABEL or colors.SYMBOL
    local secondColor = isArrowKey and colors.SYMBOL or colors.LABEL

    -- Special case for back button
    local secondMargin = direction == "back" and "0px" or "2px"
    -- Use smaller font for "Back" text only when it appears (depends on key mode)
    local secondFontSize = (direction == "back" and isVimKey) and "0.6em" or 
                          (direction == "forward" and isVimKey) and "0.45em" or "0.8em"  -- Forward text 25% smaller than Back
    local firstFontSize = (direction == "back" and isArrowKey) and "0.6em" or 
                         (direction == "forward" and isArrowKey) and "0.45em" or "1em"  -- Forward text 25% smaller than Back

    debug.log("Generating window HTML for", direction, "with type", keyType)

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
                    font-size: %s;
                    font-weight: 600;
                ">%s</div>
                <div style="
                    font-family: %s;
                    color: %s;
                    font-size: %s;
                    font-weight: 600;
                    margin-top: %s;
                ">%s</div>
            </div>
        </body>
        </html>
    ]], colors.BG, 
        (isArrowKey or firstContent == SYMBOLS[direction]) and "'SF Pro', sans-serif" or "'Proxima Nova', 'SF Pro', sans-serif",
        firstColor, 
        firstFontSize,
        firstContent,
        (isArrowKey or secondContent == SYMBOLS[direction]) and "'SF Pro', sans-serif" or "'Proxima Nova', 'SF Pro', sans-serif",
        secondColor,
        secondFontSize,
        secondMargin,
        secondContent)
end

-- Simplified arrow-only display for special cases
function M.generateArrowHtml(direction, keyType)
    local isArrowKey = keyType == "arrow"
    local isVimKey = not isArrowKey
    local colors = isArrowKey and COLORS.ARROW or COLORS.VIM
    
    debug.log("Generating simplified arrow HTML for", direction, "with type", keyType)
    
    -- Special case for "back" and "forward" commands with smaller text
    if direction == "back" or direction == "forward" then
        local symbol = direction == "back" and "▲" or "▼"  -- Triangle pointing up for back, down for forward
        local text = direction == "back" and "Back" or "Forward"
        return string.format(backTemplate, 
            "white",      -- Top symbol color (white triangle)
            string.format([[<span style="font-size: 0.85em">%s</span>]], symbol),  -- 25% smaller triangle
            "#666666",   -- Bottom text color (gray)
            string.format([[<span style="font-size: 0.65em">%s</span>]], text)  -- Smaller text
        )
    end
    
    -- Define both symbol and letter for each direction
    local symbol = direction == "up" and "↑" or
                  direction == "down" and "↓" or
                  direction == "left" and "←" or
                  direction == "right" and "→"
    
    local letter = direction == "up" and "K" or
                  direction == "down" and "J" or
                  direction == "left" and "H" or
                  direction == "right" and "L"
    
    -- Format template with order depending on key type
    if isArrowKey then
        -- Letter on top, arrow below for arrow keys
        return string.format(arrowTemplate, colors.letter, letter, colors.symbol, symbol)
    else
        -- Arrow on top, letter below for vim keys
        return string.format(arrowTemplate, colors.symbol, symbol, colors.letter, letter)
    end
end

-- Generate a single vim key preview
local function generateVimKeyPreview(key, symbol)
    return string.format([[
        <div style="
            background-color: %s;
            border-radius: 8px;
            width: 60px;
            height: 80px;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            margin: 5px;
            box-shadow: 0 0 5px rgba(0, 0, 0, 0.5);
            font-size: 32px;
        ">
            <div style="
                font-family: 'SF Pro', sans-serif;
                color: %s;
                font-size: 1em;
                font-weight: 600;
            ">%s</div>
            <div style="
                font-family: 'Proxima Nova', 'SF Pro', sans-serif;
                color: %s;
                font-size: 0.6em;
                font-weight: 600;
                margin-top: 2px;
            ">%s</div>
        </div>
    ]], COLORS.VIM.BG, COLORS.VIM.SYMBOL, symbol, COLORS.VIM.LABEL, key)
end

-- Generate welcome window HTML
function M.generateWelcomeHtml()
    -- Define vim keys and their symbols
    local vimKeys = {
        { key = "H", symbol = "←" },
        { key = "J", symbol = "↓" },
        { key = "K", symbol = "↑" },
        { key = "L", symbol = "→" },
        { key = "B", symbol = "▲" },
        { key = "F", symbol = "▼" }
    }

    -- Generate vim key previews HTML
    local vimKeysHtml = ""
    for _, keyInfo in ipairs(vimKeys) do
        vimKeysHtml = vimKeysHtml .. generateVimKeyPreview(keyInfo.key, keyInfo.symbol)
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
                    font-family: 'SF Pro', sans-serif;
                }
            </style>
        </head>
        <body>
            <div style="
                background-color: %s;
                border-radius: 16px;
                width: 800px;
                height: 400px;
                display: flex;
                box-shadow: 0 0 10px rgba(0, 0, 0, 0.5);
            ">
                <!-- Left Column - Vim Logo -->
                <div style="
                    flex: 1;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    padding: 40px;
                ">
                    <img src="file://%s/sounds/vim.png" style="max-width: 100%%; max-height: 100%%; object-fit: contain;">
                </div>

                <!-- Right Column - Content -->
                <div style="
                    flex: 2;
                    display: flex;
                    flex-direction: column;
                    align-items: center;
                    justify-content: center;
                    padding: 40px;
                ">
                    <!-- Welcome Message -->
                    <div style="
                        color: white;
                        font-size: 24px;
                        margin-bottom: 40px;
                        text-align: center;
                    ">⌨️✨ Let's learn some VIM Motions!</div>

                    <!-- Vim Keys Grid -->
                    <div style="
                        display: flex;
                        flex-wrap: wrap;
                        justify-content: center;
                        gap: 10px;
                        max-width: 400px;
                    ">
                        %s
                    </div>
                </div>
            </div>
        </body>
        </html>
    ]], COLORS.VIM.BG, hs.configdir, vimKeysHtml)
end

return M
