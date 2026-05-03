-- Smart App Switcher with debugging
-- First press = Command + Tab + Tab, subsequent = Tab, double tap = select
local appSwitcher = {
    active = false,
    lastPressTime = 0,
    doubleTapThreshold = 300, -- milliseconds
    timeoutTimer = nil,
    pendingTimer = nil
}

-- Debug logging function
local function debug(message)
    print(string.format("[AppSwitcher] %s", message))
end

-- Cleanup function
local function cleanup()
    debug("🧹 Cleanup called")
    appSwitcher.active = false
    if appSwitcher.timeoutTimer then
        appSwitcher.timeoutTimer:stop()
        appSwitcher.timeoutTimer = nil
        debug("   ⏰ Timeout timer stopped")
    end
    if appSwitcher.pendingTimer then
        appSwitcher.pendingTimer:stop()
        appSwitcher.pendingTimer = nil
        debug("   ⏳ Pending timer stopped")
    end
    debug("   🔄 State reset to inactive")
end

-- Close app switcher and select current app
local function selectCurrentApp()
    debug("✅ Selecting current app and closing switcher")
    hs.eventtap.keyStroke({}, "return") -- Select current app
    cleanup()
end

-- Auto-close after timeout (fallback)
local function setupAutoClose()
    debug("⏰ Setting up 3-second auto-close timer")
    if appSwitcher.timeoutTimer then
        appSwitcher.timeoutTimer:stop()
    end
    appSwitcher.timeoutTimer = hs.timer.doAfter(3.0, function()
        debug("⏰ Auto-close timer triggered - selecting current app")
        selectCurrentApp()
    end)
end

-- Handle F13 key press
local function handleF13Press()
    local currentTime = hs.timer.secondsSinceEpoch() * 1000 -- milliseconds
    local timeSinceLastPress = currentTime - appSwitcher.lastPressTime
    
    debug(string.format("🔄 F13 pressed - Time since last: %.0fms", timeSinceLastPress))
    debug(string.format("   📊 Current state - active: %s", tostring(appSwitcher.active)))
    
    appSwitcher.lastPressTime = currentTime
    
    -- Check for double tap
    if timeSinceLastPress < appSwitcher.doubleTapThreshold and appSwitcher.active then
        debug("⚡ DOUBLE TAP detected - selecting current app")
        selectCurrentApp()
        return
    end
    
    -- Cancel any pending single-press action
    if appSwitcher.pendingTimer then
        debug("   ❌ Canceling pending timer")
        appSwitcher.pendingTimer:stop()
        appSwitcher.pendingTimer = nil
    end
    
    -- Set up pending action (delayed to allow for double-tap detection)
    debug("   ⏳ Setting up 350ms pending timer")
    appSwitcher.pendingTimer = hs.timer.doAfter(0.35, function()
        debug("⏳ Pending timer triggered - executing single press action")
        
        if not appSwitcher.active then
            -- First press: Open app switcher with Command+Tab+Tab
            debug("🚀 Opening app switcher (Command+Tab+Tab)")
            appSwitcher.active = true
            
            -- Hold Command and tap Tab twice
            hs.eventtap.keyStroke({"cmd"}, "tab")
            debug("   📱 First Tab sent")
            hs.timer.usleep(50000) -- 50ms delay between tabs
            hs.eventtap.keyStroke({"cmd"}, "tab") 
            debug("   📱 Second Tab sent")
            
            setupAutoClose()
        else
            -- Subsequent press: Cycle to next app
            debug("➡️  Cycling to next app (Tab)")
            hs.eventtap.keyStroke({}, "tab")
            setupAutoClose() -- Reset the auto-close timer
        end
        
        appSwitcher.pendingTimer = nil
        debug(string.format("   📊 New state - active: %s", tostring(appSwitcher.active)))
    end)
end

-- Set up the F13 key binding
hs.hotkey.bind({}, "f13", function()
    handleF13Press()
end)

-- Listen for other keys to close the app switcher
local function setupKeyListener()
    debug("🎧 Setting up global key listener")
    return hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
        local keyCode = event:getKeyCode()
        local keyName = hs.keycodes.map[keyCode]
        
        -- Ignore F13 (we handle it separately)
        if keyCode == 105 then -- F13 key code
            return false
        end
        
        if appSwitcher.active then
            debug(string.format("🎹 Other key pressed while switcher active: %s (%d)", keyName or "unknown", keyCode))
            
            -- ESC key should close without selecting
            if keyCode == 53 then -- ESC
                debug("🚫 ESC pressed - closing switcher without selection")
                cleanup()
                return true -- Consume the ESC
            end
            
            -- Any other key closes and selects current app
            debug("🔄 Other key pressed - selecting current app")
            selectCurrentApp()
        end
        
        return false -- Don't consume other events
    end):start()
end

-- Initialize
debug("🔧 Initializing Smart App Switcher")
debug("   ⚙️  Double-tap threshold: " .. appSwitcher.doubleTapThreshold .. "ms")
debug("   ⚙️  Auto-close timeout: 3 seconds")
debug("   ⚙️  First press: Command+Tab+Tab (2 tabs)")

local keyListener = setupKeyListener()

debug("✅ Smart App Switcher ready!")
debug("   📋 Usage:")
debug("      • Single press F13: Open switcher with 2 apps / Cycle apps")  
debug("      • Double tap F13: Select current app")
debug("      • ESC: Close without selecting")
debug("      • Any other key: Select current app")