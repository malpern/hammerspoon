local M = {}

local DIA_BUNDLE = "company.thebrowser.dia"
local LOGFILE = os.getenv("HOME") .. "/.hammerspoon/dia-move-tab.log"
local function flog(msg)
    local f = io.open(LOGFILE, "a")
    if f then
        f:write(os.date("%H:%M:%S") .. " " .. msg .. "\n")
        f:close()
    end
end

local function moveTabToOtherProfile()
    flog("=== Ctrl+S triggered ===")

    local app = hs.application.frontmostApplication()
    if not app or app:bundleID() ~= DIA_BUNDLE then
        flog("WARN: Not Dia, ignoring")
        return
    end

    -- Detect profile from Hammerspoon window title (includes profile prefix)
    local win = hs.window.focusedWindow()
    if not win then
        flog("WARN: No focused window")
        return
    end
    local currentName = win:title()
    flog("Current window: " .. currentName)

    local isPersonal = currentName:find("Smirk:") == nil
    local targetLabel = isPersonal and "Smirk" or "Personal"
    local targetIcon = isPersonal and "💼" or "🏠"
    flog("Target profile: " .. targetLabel)

    -- Get URL of active tab
    local ok2, url = hs.osascript.applescript('tell application "Dia" to return URL of active tab of window 1')
    if not ok2 or not url or not tostring(url):match("^https?://") then
        flog("WARN: No valid URL: " .. tostring(url))
        hs.notify.new(nil, {
            title = "⚠️  Tab Move Failed",
            informativeText = "No valid URL in active tab",
            withdrawAfter = 3,
        }):send()
        return
    end
    url = tostring(url)
    flog("URL: " .. url)

    -- Close active tab
    flog("Closing active tab")
    hs.osascript.applescript('tell application "Dia" to close active tab of window 1')

    -- Find the target window and open URL in it
    local allWindows = app:allWindows()
    local targetWin = nil
    for _, w in ipairs(allWindows) do
        local isSmirk = w:title():find("Smirk:") ~= nil
        if (targetLabel == "Smirk" and isSmirk) or (targetLabel == "Personal" and not isSmirk) then
            targetWin = w
            break
        end
    end

    if not targetWin then
        flog("WARN: Could not find " .. targetLabel .. " window")
        return
    end

    -- Get the target window's index in AppleScript (1-based, ordered by frontmost)
    flog("Opening URL in " .. targetLabel .. " window: " .. targetWin:title())
    hs.osascript.applescript(string.format(
        'tell application "Dia" to make new tab in window 2 with properties {URL:"%s"}',
        url:gsub('"', '\\"')
    ))

    -- Bring target window to front
    targetWin:focus()

    flog("=== Done, moved to " .. targetLabel .. " ===")
    hs.notify.new(nil, {
        title = targetIcon .. "  Moved to " .. targetLabel,
        informativeText = url,
        withdrawAfter = 2,
    }):send()
end

-- Always enabled; the callback checks if Dia is frontmost before acting
M.hotkey = hs.hotkey.bind({"ctrl"}, "s", nil, moveTabToOtherProfile)

return M
