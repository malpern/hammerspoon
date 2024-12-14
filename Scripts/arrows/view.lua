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

-- View-specific constants that don't need to vary with model state
local VIEW_CONSTANTS = {
	-- Shadow configurations
	SHADOWS = {
		DEFAULT = "0 0 5px rgba(0, 0, 0, 0.5)",
		HOVER = "0 7px 14px rgba(0, 0, 0, 0.1), 0 3px 6px rgba(0, 0, 0, 0.08)",
		DARK = "0 4px 6px rgba(0, 0, 0, 0.2)",
		HIGH_CONTRAST = "0 0 0 2px #000000",
	},
	-- Component spacing
	MARGINS = {
		SYMBOL = "2px",
		LABEL = "5px 2px 2px 2px",
	},
	-- Animation timing
	FADE_IN_DURATION = "0.2s",
}

-- CSS styles generation
local function generateStyles(keyType)
	local style = model.Style
	local bgColor = keyType == model.KeyType.ARROW and style.COLORS.BACKGROUND.ARROW or style.COLORS.BACKGROUND.DEFAULT

	return string.format(
		[[
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
            padding: %dpx;
        }
        
        .arrow-block {
            background-color: %s;
            border-radius: %dpx;
            padding: %dpx;
            text-align: center;
            font-size: %s;
            box-shadow: %s;
            line-height: 0.8;
            display: flex;
            justify-content: center;
            align-items: center;
            min-width: %dpx;
            min-height: %dpx;
            margin: %dpx;
            transition: all 0.2s ease;
        }

        /* Hover effects */
        .arrow-block:hover {
            box-shadow: %s;
            transform: translateY(-1px) scale(1.02);
        }
        
        /* Animation */
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(-10px); }
            to { opacity: 1; transform: translateY(0); }
        }
        
        .fade-in {
            animation: fadeIn %s ease-out forwards;
        }
        
        /* High contrast mode */
        @media (prefers-contrast: high) {
            .arrow-block {
                box-shadow: %s;
            }
        }
        
        /* Dark mode support */
        @media (prefers-color-scheme: dark) {
            body {
                color: #ffffff;
            }
            .arrow-block {
                box-shadow: %s;
            }
        }
    ]],
		style.FONT.FAMILY,
		style.WINDOW.CONTAINER_PADDING,
		bgColor,
		style.WINDOW.BORDER_RADIUS,
		style.WINDOW.PADDING,
		style.FONT.SIZES.SYMBOL.DEFAULT,
		VIEW_CONSTANTS.SHADOWS.DEFAULT,
		style.WINDOW.WIDTH,
		style.WINDOW.HEIGHT,
		style.WINDOW.MARGIN,
		VIEW_CONSTANTS.SHADOWS.HOVER,
		VIEW_CONSTANTS.FADE_IN_DURATION,
		VIEW_CONSTANTS.SHADOWS.HIGH_CONTRAST,
		VIEW_CONSTANTS.SHADOWS.DARK
	)
end

-- Generate component HTML
local function generateComponentHtml(direction, keyType, isSymbol)
	local style = model.Style
	local symbolColor = keyType == model.KeyType.ARROW and style.COLORS.SYMBOL.ARROW or style.COLORS.SYMBOL.DEFAULT
	local letterColor = keyType == model.KeyType.ARROW and style.COLORS.LABEL.ARROW or style.COLORS.LABEL.DEFAULT

	local content = isSymbol and model.SYMBOLS[direction] or model.LABELS[direction]
	local color = isSymbol and symbolColor or letterColor

	return string.format(
		[[
		<div style='
			font-family: %s;
			color: %s;
			text-shadow: none;
			font-size: %s;
			font-weight: %s;
			margin: %s;
		'>%s</div>
	]],
		style.FONT.FAMILY,
		color,
		isSymbol and style.FONT.SIZES.SYMBOL.DEFAULT or style.FONT.SIZES.LABEL.DEFAULT,
		style.FONT.WEIGHT,
		isSymbol and VIEW_CONSTANTS.MARGINS.SYMBOL or VIEW_CONSTANTS.MARGINS.LABEL,
		content
	)
end

-- Generate complete window HTML
---@param direction string The direction to display (from model.Direction)
---@param keyType string The key type (from model.KeyType)
---@return string html The generated HTML for the window
function M.generateWindowHtml(direction, keyType)
	-- Generate CSS
	local css = generateStyles(keyType)

	-- For arrow keys: letter on top, symbol below
	-- For vim keys: symbol on top, letter below
	local firstComponent = keyType == model.KeyType.ARROW and generateComponentHtml(direction, keyType, false) -- Label for arrow keys
		or generateComponentHtml(direction, keyType, true) -- Symbol for vim keys

	local secondComponent = keyType == model.KeyType.ARROW and generateComponentHtml(direction, keyType, true) -- Symbol for arrow keys
		or generateComponentHtml(direction, keyType, false) -- Label for vim keys

	-- Generate complete HTML
	return string.format(
		[[
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
                <div class="arrow-block fade-in">
                    <div style="display: flex; flex-direction: column; align-items: center; gap: 5px;">
                        %s
                        %s
                    </div>
                </div>
            </div>
        </body>
        </html>
    ]],
		css,
		firstComponent,

		secondComponent
	)
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

	-- Generate complete HTML with simpler structure
	return string.format(
		[[
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
                <div class="arrow-block fade-in">
                    %s
                </div>
            </div>
        </body>
        </html>
    ]],
		css,
		componentHtml
	)
end

return M
