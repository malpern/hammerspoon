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

-- Try to get video state via JavaScript (requires --enable-applescript-javascript)
local function getVideoState()
    local ok, result, rawErr = hs.osascript.applescript([[
        tell application "Dia"
            tell active tab of window 1
                execute javascript "
                    var v = document.querySelector('video');
                    v ? JSON.stringify({time: Math.floor(v.currentTime), paused: v.paused}) : 'novideo'
                "
            end tell
        end tell
    ]])
    flog("getVideoState — ok: " .. tostring(ok) .. " result: " .. tostring(result))
    if ok and result then
        local resultStr = tostring(result)
        if resultStr == "novideo" then
            flog("No video element found on page")
            return nil, false
        end
        local time = tonumber(resultStr:match('"time":%s*(%d+)')) or tonumber(resultStr:match('\\"time\\":%s*(%d+)'))
        local paused = (resultStr:match('"paused":%s*(%a+)') or resultStr:match('\\"paused\\":%s*(%a+)')) == "true"
        flog("Parsed — time: " .. tostring(time) .. " paused: " .. tostring(paused))
        if time and time > 0 then
            return time, not paused
        end
    end
    return nil, false
end

-- Auto-play video by waiting for load then sending spacebar
local function autoPlayVideo()
    hs.timer.doAfter(1.5, function()
        flog("Sending spacebar to resume playback")
        hs.osascript.applescript([[
            tell application "System Events"
                tell process "Dia"
                    keystroke " "
                end tell
            end tell
        ]])
    end)
end

-- Append timestamp to YouTube URL
local function appendTimestamp(url, seconds)
    if not seconds or seconds <= 0 then return url end
    -- Remove existing t= parameter
    url = url:gsub("[?&]t=%d+s?", "")
    local separator = url:find("?") and "&" or "?"
    return url .. separator .. "t=" .. seconds .. "s"
end

local function isYouTubeVideo(url)
    return url:match("youtube%.com/watch") or url:match("youtu%.be/")
end

local function moveTabToOtherProfile()
    flog("=== Ctrl+S triggered ===")

    local app = hs.application.frontmostApplication()
    if not app or app:bundleID() ~= DIA_BUNDLE then
        flog("WARN: Not Dia, ignoring")
        return
    end

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

    -- For YouTube videos, try to preserve playback position and play state
    local wasPlaying = false
    if isYouTubeVideo(url) then
        flog("YouTube video detected, getting state")
        local seconds, playing = getVideoState()
        wasPlaying = playing
        if seconds then
            flog("Playback position: " .. seconds .. "s, playing: " .. tostring(playing))
            url = appendTimestamp(url, seconds)
            flog("URL with timestamp: " .. url)
        else
            flog("Could not get video state (JS flag may not be enabled)")
        end
    end

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

    flog("Opening URL in " .. targetLabel .. " window: " .. targetWin:title())
    hs.osascript.applescript(string.format(
        'tell application "Dia" to make new tab in window 2 with properties {URL:"%s"}',
        url:gsub('"', '\\"')
    ))

    targetWin:focus()

    if wasPlaying then
        flog("Video was playing, will auto-play after load")
        autoPlayVideo()
    end

    -- Mark as recently routed so the auto-router doesn't bounce it back
    local router = package.loaded["Scripts.dia-url-router"]
    if router and router.markRouted then
        router.markRouted(url)
        flog("Marked URL on cooldown for auto-router")

        local n = hs.notify.new(function(notification)
            if notification:activationType() == hs.notify.activationTypes.actionButtonClicked then
                router.clearCooldown(url)
                flog("Cooldown cancelled by user for: " .. url)
                hs.notify.new(nil, {
                    title = "↩️  Cooldown cancelled",
                    informativeText = "Auto-routing re-enabled for this URL",
                    withdrawAfter = 2,
                }):send()
            end
        end, {
            title = targetIcon .. "  Moved to " .. targetLabel,
            informativeText = url,
            actionButtonTitle = "Undo Cooldown",
            hasActionButton = true,
            withdrawAfter = 5,
        })
        n:send()
    else
        hs.notify.new(nil, {
            title = targetIcon .. "  Moved to " .. targetLabel,
            informativeText = url,
            withdrawAfter = 2,
        }):send()
    end

    flog("=== Done, moved to " .. targetLabel .. " ===")
end

-- Always enabled; the callback checks if Dia is frontmost before acting
M.hotkey = hs.hotkey.bind({"ctrl"}, "s", nil, moveTabToOtherProfile)

-- Warn if Dia launches without the JS flag
M.appWatcher = hs.application.watcher.new(function(name, event, app)
    if not app or app:bundleID() ~= DIA_BUNDLE then return end
    if event ~= hs.application.watcher.launched then return end

    hs.timer.doAfter(8, function()
        local ok, _ = hs.osascript.applescript([[
            tell application "Dia"
                tell active tab of window 1
                    execute javascript "true"
                end tell
            end tell
        ]])
        if ok then
            flog("Dia launched with JS flag, all good")
        else
            flog("WARN: Dia launched without JS flag")
            hs.notify.new(nil, {
                title = "⚠️  Dia missing JS flag",
                informativeText = "Use 'Launch Dia' from Raycast for YouTube features",
                withdrawAfter = 5,
            }):send()
        end
    end)
end)
M.appWatcher:start()

return M
