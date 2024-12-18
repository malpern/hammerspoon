--[[
    ✨ Welcome Window for Arrows System
    
    Features:
    🎨 Stylish welcome screen
    🎯 VIM key previews
    🖼️ VIM logo display
    📊 VIM Motion Quotient
    ⏱️ Auto-fade after 2 seconds
]]

local debug = require("Scripts.arrows.utils.debug")
local animation = require("Scripts.arrows.utils.animation")

-- Calculate VIM Motion Quotient from learning logs
local function calculateVimQuotient()
    local logPath = hs.configdir .. "/learning.log"
    debug.log("📊 Calculating VIM Motion Quotient from:", logPath)
    
    local vimCount = tonumber(hs.execute("cat '" .. logPath .. "' | grep vim | wc -l") or "0")
    local arrowCount = tonumber(hs.execute("cat '" .. logPath .. "' | grep arrow | wc -l") or "0")
    local total = vimCount + arrowCount
    
    debug.log(string.format("📈 Stats - VIM: %d, Arrow: %d, Total: %d", vimCount, arrowCount, total))
    
    if total == 0 then 
        debug.log("⚠️ No usage data found")
        return 0 
    end
    
    local quotient = math.floor((vimCount / total) * 100)
    debug.log("✨ VIM Motion Quotient:", quotient .. "%")
    return quotient
end

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
            justify-content: center;e
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

-- Generate a progress bar string using block characters
local function generateProgressBar(percentage, width)
    local filledWidth = math.floor(width * percentage / 100)
    local emptyWidth = width - filledWidth
    return string.rep("█", filledWidth) .. string.rep("░", emptyWidth)
end

-- Generate welcome window HTML
local function generateHtml()
    -- Calculate VIM Motion Quotient
    local vimQuotient = calculateVimQuotient()
    local progressBar = generateProgressBar(vimQuotient, 14)  -- Reduced from 20 to 14 characters
    
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
                    flex: 0.4;
                    display: flex;
                    flex-direction: column;
                    align-items: center;
                    justify-content: center;
                    padding: 30px;
                    gap: 20px;
                    width: 100%%;
                ">
                    <div style="
                        width: 100%%;
                        display: flex;
                        flex-direction: column;
                        align-items: center;
                        gap: 20px;
                    ">
                        <img src="%s" style="width: 150px; height: 150px; object-fit: contain;" 
                             onerror="console.error('Failed to load image:', this.src); this.style.display='none';">
                        <div style="
                            color: rgba(255, 255, 255, 1) !important;
                            font-size: 16px;
                            font-family: monospace;
                            font-weight: 400;
                            padding: 10px 15px;
                            background-color: rgba(255, 255, 255, 0.1);
                            border-radius: 8px;
                            text-align: center;
                            text-shadow: 0 1px 2px rgba(0, 0, 0, 0.2);
                            width: fit-content;
                            white-space: nowrap;
                        ">🏆 [%s] %d%%</div>
                    </div>
                </div>

                <!-- Right Column - Content -->
                <div style="
                    flex: 2.6;
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
                    ">⌨️✨ Learning VIM Motions</div>

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
    ]], COLORS.BG, base64Image, progressBar, vimQuotient, hjklHtml, bfHtml)
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