local M = {}

local DELAY = 300000 -- microseconds between steps (300ms)
local DIA_BUNDLE = "company.thebrowser.dia"
local LOGFILE = os.getenv("HOME") .. "/.hammerspoon/dia-move-tab.log"
local function flog(msg)
    local f = io.open(LOGFILE, "a")
    if f then
        f:write(os.date("%H:%M:%S") .. " " .. msg .. "\n")
        f:close()
    end
end

local PROFILES = {
    personal = {mods = "{control down}", key = "1"},
    smirk    = {mods = "{control down}", key = "2"},
}

-- Dia ignores hs.eventtap synthetic events; must use System Events
local function sendKey(applescriptMods, key)
    local script
    if applescriptMods == "" then
        script = string.format([[
            tell application "System Events"
                tell process "Dia"
                    keystroke "%s"
                end tell
            end tell
        ]], key)
    else
        script = string.format([[
            tell application "System Events"
                tell process "Dia"
                    keystroke "%s" using %s
                end tell
            end tell
        ]], key, applescriptMods)
    end
    hs.osascript.applescript(script)
end

local function sendReturn()
    hs.osascript.applescript([[
        tell application "System Events"
            tell process "Dia"
                key code 36
            end tell
        end tell
    ]])
end

local function currentProfileIsPersonal()
    local win = hs.window.focusedWindow()
    if not win then
        flog("WARN: No focused window")
        return nil
    end
    local title = win:title() or ""
    flog("Window title: " .. title)
    local isPersonal = title:find("Personal") ~= nil
    flog("Detected profile: " .. (isPersonal and "Personal" or "Smirk"))
    return isPersonal
end

local function moveTabToOtherProfile()
    flog("=== Ctrl+S triggered ===")

    local app = hs.application.frontmostApplication()
    if not app then
        flog("WARN: No frontmost app")
        return
    end
    flog("Frontmost app: " .. app:name() .. " (" .. app:bundleID() .. ")")

    if app:bundleID() ~= DIA_BUNDLE then
        flog("WARN: Not Dia, ignoring")
        return
    end

    local isPersonal = currentProfileIsPersonal()
    local target = isPersonal and PROFILES.smirk or PROFILES.personal
    local targetName = isPersonal and "Smirk" or "Personal"
    flog("Target profile: " .. targetName)

    flog("Sending Cmd+Shift+C (copy URL)")
    sendKey("{command down, shift down}", "c")
    hs.timer.usleep(DELAY)

    local url = hs.pasteboard.getContents()
    flog("Clipboard: " .. (url or "<nil>"))

    if not url or not url:match("^https?://") then
        flog("WARN: No valid URL, aborting")
        hs.alert.show("❌ No valid URL in clipboard", 1.5)
        return
    end

    flog("Sending Cmd+W (close tab)")
    sendKey("{command down}", "w")
    hs.timer.usleep(DELAY)

    flog("Sending Ctrl+" .. target.key .. " (switch profile)")
    sendKey(target.mods, target.key)
    hs.timer.usleep(DELAY)

    flog("Sending Cmd+T (new tab)")
    sendKey("{command down}", "t")
    hs.timer.usleep(DELAY)

    flog("Sending Cmd+V (paste)")
    sendKey("{command down}", "v")
    hs.timer.usleep(DELAY)

    flog("Sending Return (navigate)")
    sendReturn()

    flog("=== Done, moved to " .. targetName .. " ===")
    hs.alert.show("→ Moved to " .. targetName, 1)
end

M.hotkey = hs.hotkey.new({"ctrl"}, "s", nil, moveTabToOtherProfile)

M.filter = hs.window.filter.new(false):setAppFilter("Dia")
M.filter:subscribe(hs.window.filter.windowFocused, function()
    flog("Dia window focused, enabling hotkey")
    M.hotkey:enable()
end)
M.filter:subscribe(hs.window.filter.windowUnfocused, function()
    flog("Dia window unfocused, disabling hotkey")
    M.hotkey:disable()
end)

local fw = hs.window.focusedWindow()
if fw and fw:application():bundleID() == DIA_BUNDLE then
    flog("Dia already focused on load, enabling hotkey")
    M.hotkey:enable()
end

return M
