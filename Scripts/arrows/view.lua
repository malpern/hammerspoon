--[[
    View module for the Arrows system
    
    This module handles all HTML generation and templating for the arrow display.
    It uses the model's style configurations to maintain consistent appearance.

    Return values:
    - All public functions MUST return string
    - generateWindowHtml() returns valid HTML string
    - generateArrowHtml() returns valid HTML string
    - nil returns indicate bugs and are NOT valid
]]

local model = require("Scripts.arrows.model")
local M = {}

-- CSS styles generation
local function generateStyles(keyType)
    local style = model.Style
    local bgColor = keyType == model.KeyType.ARROW and 
                   style.COLORS.BACKGROUND.ARROW or 
                   style.COLORS.BACKGROUND.DEFAULT
    
    return string.format([[
        /* Base styles */
        body {
            margin: 0;
            padding: 0;
            background: transparent;
            font-family: %s;
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
            background-color: %s;
            border-radius: %dpx;
            padding: %dpx;
            display: flex;
            justify-content: center;
            align-items: center;
            flex-direction: column;
            min-width: 48px;
            min-height: 48px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1), 
                       0 1px 3px rgba(0, 0, 0, 0.08);
            transition: all 0.2s ease;
        }
        
        /* Hover effects */
        .arrow-container:hover {
            box-shadow: 0 7px 14px rgba(0, 0, 0, 0.1), 
                       0 3px 6px rgba(0, 0, 0, 0.08);
            transform: translateY(-1px) scale(1.02);
        }
        
        /* Animation */
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(-10px); }
            to { opacity: 1; transform: translateY(0); }
        }
        
        .fade-in {
            animation: fadeIn 0.2s ease-out forwards;
        }
        
        /* High contrast mode */
        @media (prefers-contrast: high) {
            .arrow-container {
                box-shadow: 0 0 0 2px #000000;
            }
        }
        
        /* Dark mode support */
        @media (prefers-color-scheme: dark) {
            body {
                color: #ffffff;
            }
            .arrow-container {
                box-shadow: 0 4px 6px rgba(0, 0, 0, 0.2);
            }
        }
    ]], 
    style.FONT.FAMILY,
    bgColor,
    style.WINDOW.BORDER_RADIUS,
    style.WINDOW.PADDING)
end

-- Generate component HTML
local function generateComponentHtml(direction, keyType, isSymbol)
    local style = model.Style
    local content = isSymbol and model.SYMBOLS[direction] or model.LABELS[direction]
    
    -- Determine sizes and colors based on component type and key type
    local sizeKey = isSymbol and "SYMBOL" or "LABEL"
    local size = style.FONT.SIZES[sizeKey][direction] or style.FONT.SIZES[sizeKey].DEFAULT
    
    local colorKey = isSymbol and "SYMBOL" or "LABEL"
    local color = keyType == model.KeyType.ARROW and 
                 style.COLORS[colorKey].ARROW or
                 (style.COLORS[colorKey][direction] or style.COLORS[colorKey].DEFAULT)
    
    return string.format([[
        <div style='
            font-family: %s;
            font-weight: %s;
            font-size: %s;
            color: %s;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 2px;
            text-shadow: none;
        '>%s</div>
    ]], style.FONT.FAMILY, style.FONT.WEIGHT, size, color, content)
end

-- Generate complete window HTML
---@param direction string The direction to display (from model.Direction)
---@param keyType string The key type (from model.KeyType)
---@return string html The generated HTML for the window
function M.generateWindowHtml(direction, keyType)
    -- Generate CSS
    local css = generateStyles(keyType)
    
    -- Determine component order based on key type
    local firstComponent = keyType == model.KeyType.ARROW and 
                         generateComponentHtml(direction, keyType, false) or  -- Label for arrow keys
                         generateComponentHtml(direction, keyType, true)      -- Symbol for vim keys
    
    local secondComponent = keyType == model.KeyType.ARROW and 
                          generateComponentHtml(direction, keyType, true) or  -- Symbol for arrow keys
                          generateComponentHtml(direction, keyType, false)    -- Label for vim keys
    
    -- Generate complete HTML
    return string.format([[
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
            <div class="arrow-container fade-in">
                %s
                %s
            </div>
        </body>
        </html>
    ]], css, firstComponent, secondComponent)
end

-- Generate arrow HTML
---@param direction string The direction to display (from model.Direction)
---@param keyType string The key type (from model.KeyType)
---@return string html The generated HTML for the arrow display
function M.generateArrowHtml(direction, keyType)
    -- Generate CSS
    local css = generateStyles(keyType)
    
    -- Generate component HTML
    local componentHtml = generateComponentHtml(direction, keyType, true)
    
    -- Generate complete HTML
    return string.format([[
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
            <div class="arrow-container fade-in">
                %s
            </div>
        </body>
        </html>
    ]], css, componentHtml)
end

return M 