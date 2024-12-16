--[[
    ✨ Welcome Window for Arrows System
    
    Features:
    🎨 Stylish welcome screen
    🎯 VIM key previews
    🖼️ VIM logo display
    ⏱️ Auto-fade after 2 seconds
]]

local debug = require("Scripts.arrows.utils.debug")
local animation = require("Scripts.arrows.utils.animation")

-- Constants
local COLORS = {
    BG = "#1E1E1E",
    SYMBOL = "white",
    LABEL = "#666666"
}

local M = {}

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
                font-family: 'SF Pro Display', 'SF Pro', -apple-system, BlinkMacSystemFont, sans-serif;
                color: %s;
                font-size: 1em;
                font-weight: 600;
            ">%s</div>
            <div style="
                font-family: 'SF Pro Display', 'SF Pro', -apple-system, BlinkMacSystemFont, sans-serif;
                color: %s;
                font-size: 0.6em;
                font-weight: 600;
                margin-top: 2px;
            ">%s</div>
        </div>
    ]], COLORS.BG, COLORS.SYMBOL, symbol, COLORS.LABEL, key)
end

-- Generate welcome window HTML
local function generateHtml()
    -- Try PNG first, then fall back to JPG
    local vimLogoPath = hs.configdir .. "/sounds/vim.png"
    debug.log("🔍 Attempting to load vim logo from:", vimLogoPath)
    
    -- Read the file directly as binary
    local file = io.open(vimLogoPath, "rb")
    if not file then
        debug.error("❌ Could not open file:", vimLogoPath)
        return ""
    end
    
    local data = file:read("*all")
    file:close()
    
    if not data then
        debug.error("❌ Could not read file data")
        return ""
    end
    
    -- Encode the binary data directly to base64
    local base64Image = "data:image/png;base64," .. hs.base64.encode(data)
    debug.log("✅ Successfully encoded image to base64")
    debug.log("📊 Base64 data length:", #base64Image)

    -- Define vim keys and their symbols
    local hjklKeys = {
        { key = "H", symbol = "←" },
        { key = "J", symbol = "↓" },
        { key = "K", symbol = "↑" },
        { key = "L", symbol = "→" }
    }
    
    local bfKeys = {
        { key = "B", symbol = "▲" },
        { key = "F", symbol = "▼" }
    }

    -- Generate vim key previews HTML
    local hjklHtml = ""
    for _, keyInfo in ipairs(hjklKeys) do
        hjklHtml = hjklHtml .. generateVimKeyPreview(keyInfo.key, keyInfo.symbol)
    end

    local bfHtml = ""
    for _, keyInfo in ipairs(bfKeys) do
        bfHtml = bfHtml .. generateVimKeyPreview(keyInfo.key, keyInfo.symbol)
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
                    font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', 'SF Pro', sans-serif;
                }
            </style>
        </head>
        <body>
            <div style="
                background-color: %s;
                border-radius: 8px;
                width: 800px;
                height: 400px;
                display: flex;
                box-shadow: 0 0 10px rgba(0, 0, 0, 0.5);
                border: 2px solid rgba(255, 255, 255, 0.1);
            ">
                <!-- Left Column - Vim Logo -->
                <div style="
                    flex: 0.6;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    padding: 30px;
                ">
                    <img src="%s" style="max-width: 100%%; max-height: 100%%; object-fit: contain;" 
                         onerror="console.error('Failed to load image:', this.src); this.style.display='none';">
                </div>

                <!-- Right Column - Content -->
                <div style="
                    flex: 2.4;
                    display: flex;
                    flex-direction: column;
                    align-items: center;
                    justify-content: center;
                    padding: 40px 50px 40px 30px;
                ">
                    <!-- Welcome Message -->
                    <div style="
                        color: white;
                        font-family: 'Proxima Nova', -apple-system, BlinkMacSystemFont, sans-serif;
                        font-size: 32px;
                        margin-bottom: 48px;
                        text-align: center;
                        font-weight: 600;
                        letter-spacing: -0.02em;
                        line-height: 1.2;
                        opacity: 0.95;
                        text-shadow: 0 1px 2px rgba(0, 0, 0, 0.1);
                        white-space: nowrap;
                    ">⌨️✨ Let's learn some VIM Motions</div>

                    <!-- Vim Keys Grid -->
                    <div style="
                        display: flex;
                        flex-direction: column;
                        align-items: center;
                        gap: 20px;
                        max-width: 400px;
                    ">
                        <!-- HJKL Row -->
                        <div style="
                            display: flex;
                            flex-wrap: wrap;
                            justify-content: center;
                            gap: 10px;
                        ">
                            %s
                        </div>
                        <!-- B F Row -->
                        <div style="
                            display: flex;
                            flex-wrap: wrap;
                            justify-content: center;
                            gap: 30px;
                        ">
                            %s
                        </div>
                    </div>
                </div>
            </div>
        </body>
        </html>
    ]], COLORS.BG, base64Image, hjklHtml, bfHtml)
end

-- Show welcome window
function M.show()
    -- Calculate center position
    local screen = hs.screen.mainScreen()
    local frame = screen:frame()
    local windowWidth = 800
    local windowHeight = 400
    
    local position = {
        x = frame.x + (frame.w - windowWidth) / 2,
        y = frame.y + (frame.h - windowHeight) / 2,
        w = windowWidth,
        h = windowHeight
    }

    -- Create webview
    local success, webview = pcall(function()
        local w = hs.webview.new(position)
        if not w then error("Failed to create welcome webview") end
        return w
    end)

    if not success or not webview then
        debug.error("🚫 Failed to create welcome webview:", webview)
        return false
    end

    -- Configure webview
    local success, err = pcall(function()
        webview:windowStyle({ "borderless", "closable", "nonactivating" })
        webview:level(hs.drawing.windowLevels.floating)
        webview:alpha(1.0)
        webview:allowTextEntry(false)
        webview:transparent(true)
        webview:bringToFront()

        -- Set HTML content
        local html = generateHtml()
        webview:html(html)
        webview:show()

        -- Fade out after 2 seconds
        hs.timer.doAfter(2.0, function()
            -- Single confetti celebration with 2 repeats
            animation.triggerCelebration()
            
            animation.fadeOut(webview, function()
                if webview then
                    webview:delete()
                end
            end)
        end)
    end)

    if not success then
        debug.error("🚫 Failed to configure welcome webview:", err)
        if webview then
            webview:delete()
        end
        return false
    end

    return true
end

return M 