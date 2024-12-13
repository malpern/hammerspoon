--[[
    View module for the Arrows system
    
    This module handles all HTML generation and templating for the arrow display.
    It uses the model's style configurations to maintain consistent appearance.
]]

local model = require("arrows.model")
local M = {}

-- CSS styles generation
local function generateStyles()
    local style = model.Style
    return string.format([[
        /* Base styles */
        body {
            margin: 0;
            padding: 0;
            background: transparent;
            font-family: %s;
            color: #666666;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            overflow: hidden;
            user-select: none;
            -webkit-user-select: none;
            cursor: default;
        }
        
        /* Container styles */
        .arrow-container {
            background-color: transparent;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 5px;
            transition: transform 0.2s ease-in-out;
        }
        .arrow-container:hover {
            transform: scale(1.05);
        }
        
        /* Arrow block styles */
        .arrow-block {
            background-color: %s;
            border-radius: %dpx;
            padding: %dpx;
            text-align: center;
            font-size: 48px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1), 
                       0 1px 3px rgba(0, 0, 0, 0.08);
            line-height: 0.8;
            display: flex;
            justify-content: center;
            align-items: center;
            min-width: 48px;
            min-height: 48px;
            margin: 5px;
            transition: all 0.2s ease;
        }
        .arrow-block:hover {
            box-shadow: 0 7px 14px rgba(0, 0, 0, 0.1), 
                       0 3px 6px rgba(0, 0, 0, 0.08);
            transform: translateY(-1px);
        }
        
        /* Animation keyframes */
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(-10px); }
            to { opacity: 1; transform: translateY(0); }
        }
        
        /* Animation classes */
        .fade-in {
            animation: fadeIn 0.2s ease-out forwards;
        }
        
        /* High contrast mode */
        @media (prefers-contrast: high) {
            .arrow-block {
                box-shadow: 0 0 0 2px #000000;
            }
        }
        
        /* Dark mode support */
        @media (prefers-color-scheme: dark) {
            body {
                color: #ffffff;
            }
        }
    ]], 
    style.FONT.FAMILY,
    "%s", -- Background color placeholder
    style.WINDOW.BORDER_RADIUS,
    style.WINDOW.PADDING)
end

-- HTML templates
local htmlTemplate = [[
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="color-scheme" content="light dark">
    <title>Arrow Display</title>
    <style>%s</style>
</head>
<body>
    <div class="arrow-container">
        <div class="arrow-block fade-in">%s</div>
    </div>
</body>
</html>
]]

-- Component templates
local function generateSymbolHtml(symbol, color, size, font)
    return string.format([[
        <div style='
            font-family: %s;
            color: %s;
            text-shadow: none;
            font-size: %s;
            font-weight: %s;
            display: flex;
            align-items: center;
            justify-content: center;
        '>%s</div>
    ]], font.FAMILY, color, size, font.WEIGHT, symbol)
end

local function generateLetterHtml(letter, color, size, font)
    return string.format([[
        <div style='
            font-family: %s;
            color: %s;
            font-size: %s;
            font-weight: %s;
            margin-top: 5px;
            display: flex;
            align-items: center;
            justify-content: center;
        '>%s</div>
    ]], font.FAMILY, color, size, font.WEIGHT, letter)
end

-- Direction mappings
local SYMBOLS = {
    [model.Direction.UP] = "↑",
    [model.Direction.DOWN] = "↓",
    [model.Direction.LEFT] = "←",
    [model.Direction.RIGHT] = "→"
}

local LETTERS = {
    [model.Direction.UP] = "K",
    [model.Direction.DOWN] = "J",
    [model.Direction.LEFT] = "H",
    [model.Direction.RIGHT] = "L"
}

-- Generate arrow component HTML
---@param direction string The direction to display
---@param keyType string The type of key (vim/arrow)
---@return string The generated HTML content
function M.generateArrowHtml(direction, keyType)
    local style = model.Style
    local colors = style.COLORS
    local font = style.FONT
    
    -- For back command
    if direction == model.Direction.BACK then
        local symbolHtml = generateSymbolHtml(
            [[<span style="font-size: 0.85em">▲</span>]], 
            colors.BACK_SYMBOL, 
            font.SIZES.SYMBOL,
            font
        )
        
        local textHtml = generateLetterHtml(
            [[<span style="font-size: 0.65em">Back</span>]], 
            colors.BACK_TEXT,
            font.SIZES.BACK,
            font
        )
        
        return string.format([[
            <div style='display: flex; flex-direction: column; align-items: center;'>
                %s%s
            </div>
        ]], symbolHtml, textHtml)
    end
    
    local isArrowKey = keyType == model.KeyType.ARROW
    local symbolColor = isArrowKey and colors.ARROW_SYMBOL or colors.VIM_SYMBOL
    local letterColor = isArrowKey and colors.ARROW_LETTER or colors.VIM_LETTER
    local symbol = SYMBOLS[direction]
    local letter = LETTERS[direction]
    
    -- Generate component parts
    local symbolHtml = generateSymbolHtml(
        symbol,
        isArrowKey and letterColor or symbolColor,
        font.SIZES.SYMBOL,
        font
    )
    
    local letterHtml = generateLetterHtml(
        letter,
        isArrowKey and symbolColor or letterColor,
        font.SIZES.LETTER,
        font
    )
    
    -- Combine components
    return string.format([[
        <div style='display: flex; flex-direction: column; align-items: center;'>
            %s%s
        </div>
    ]], isArrowKey and letterHtml or symbolHtml, isArrowKey and symbolHtml or letterHtml)
end

-- Generate complete window HTML
---@param direction string The direction to display
---@param keyType string The type of key (vim/arrow)
---@return string The complete HTML for the window
function M.generateWindowHtml(direction, keyType)
    local style = model.Style
    local bgColor = keyType == model.KeyType.ARROW and style.COLORS.ARROW_BG or style.COLORS.VIM_BG
    
    -- Generate CSS with background color
    local css = string.format(generateStyles(), bgColor)
    
    -- Generate arrow content
    local arrowHtml = M.generateArrowHtml(direction, keyType)
    
    -- Combine everything
    return string.format(htmlTemplate, css, arrowHtml)
end

return M 