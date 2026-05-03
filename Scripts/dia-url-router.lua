--
-- URL Router for Dia Browser
--
-- Watches for new page loads in Dia and automatically moves tabs
-- to the correct profile (Personal vs Smirk) based on domain rules.
-- Also handles external URLs when Hammerspoon is set as default browser.
--
-- A 10-minute cooldown prevents re-routing a URL that was just moved
-- (e.g., if you Ctrl+S it back intentionally).
--

local M = {}

local DIA_BUNDLE = "company.thebrowser.dia"
local DEBUG = true -- set to false to disable logging

---------------------------------------------------------------------------
-- Logging
---------------------------------------------------------------------------

local LOGFILE = os.getenv("HOME") .. "/.hammerspoon/dia-url-router.log"
local function flog(msg)
    if not DEBUG then return end
    local f = io.open(LOGFILE, "a")
    if f then
        f:write(os.date("%H:%M:%S") .. " " .. msg .. "\n")
        f:close()
    end
end

---------------------------------------------------------------------------
-- Routing rules
--
-- Loaded from plain text files in ~/.hammerspoon/routes/
--   smirk.txt    — domains/paths that open in the Smirk (work) profile
--   personal.txt — domains/paths that open in the Personal profile
--
-- Format:
--   example.com              domain rule — matches example.com + subdomains
--   path:github.com/org      path rule — matches URLs starting with this
--   # comment                ignored
--
-- Domains not in either list are left where they are.
-- You can paste full URLs — they'll be treated as domain rules.
---------------------------------------------------------------------------

local ROUTES_DIR = os.getenv("HOME") .. "/.hammerspoon/routes/"

local function loadRules(filename)
    local rules = { domains = {}, paths = {} }
    local f = io.open(ROUTES_DIR .. filename, "r")
    if not f then
        flog("WARN: Could not open " .. filename)
        return rules
    end
    for line in f:lines() do
        line = line:match("^%s*(.-)%s*$") -- trim
        if line ~= "" and line:sub(1, 1) ~= "#" then
            if line:sub(1, 5) == "path:" then
                local path = line:sub(6):lower()
                table.insert(rules.paths, path)
            else
                -- Strip protocol and path if someone pastes a full URL
                local domain = line:lower()
                    :gsub("^https?://", "")
                    :gsub("/.*$", "")
                table.insert(rules.domains, domain)
            end
        end
    end
    f:close()
    flog("Loaded " .. filename .. ": " .. #rules.domains .. " domains, " .. #rules.paths .. " paths")
    return rules
end

local smirkRules = loadRules("smirk.txt")
local personalRules = loadRules("personal.txt")

-- Reload when route files change
M.routeWatcher = hs.pathwatcher.new(ROUTES_DIR, function()
    smirkRules = loadRules("smirk.txt")
    personalRules = loadRules("personal.txt")
    flog("Routes reloaded")
    hs.notify.new(nil, {
        title = "🔄  Routes reloaded",
        informativeText = (smirkRules.domains and #smirkRules.domains or 0) + (#smirkRules.paths or 0) .. " work, "
            .. (#personalRules.domains or 0) + (#personalRules.paths or 0) .. " personal rules",
        withdrawAfter = 2,
    }):send()
end):start()

---------------------------------------------------------------------------
-- Cooldown — don't re-route a URL within 10 minutes
---------------------------------------------------------------------------

local COOLDOWN_SECONDS = 600
local recentlyRouted = {}

local function isOnCooldown(url)
    local t = recentlyRouted[url]
    if not t then return false end
    if os.time() - t > COOLDOWN_SECONDS then
        recentlyRouted[url] = nil
        return false
    end
    return true
end

local function markRouted(url)
    recentlyRouted[url] = os.time()
end
M.markRouted = markRouted
M.clearCooldown = function(url)
    recentlyRouted[url] = nil
end

M.cooldownTimer = hs.timer.doEvery(300, function()
    local now = os.time()
    for url, t in pairs(recentlyRouted) do
        if now - t > COOLDOWN_SECONDS then
            recentlyRouted[url] = nil
        end
    end
end)

---------------------------------------------------------------------------
-- Matching
---------------------------------------------------------------------------

local function extractHost(url)
    return url:match("^https?://([^/:]+)")
end

local function extractHostAndPath(url)
    return url:lower():gsub("^https?://", ""):gsub("[?#].*$", "")
end

local function domainMatches(host, pattern)
    host = host:lower()
    pattern = pattern:lower()
    if host == pattern then return true end
    if host:sub(-#pattern - 1) == "." .. pattern then return true end
    return false
end

local function matchesRules(url, rules)
    local host = extractHost(url)
    if not host then return false end

    -- Check path rules first (more specific)
    local hostAndPath = extractHostAndPath(url)
    for _, pathPattern in ipairs(rules.paths) do
        if hostAndPath:sub(1, #pathPattern) == pathPattern then
            return true
        end
    end

    -- Check domain rules
    for _, domain in ipairs(rules.domains) do
        if domainMatches(host, domain) then
            return true
        end
    end

    return false
end

-- Returns "Smirk", "Personal", or nil
local function profileForURL(url)
    -- Path rules are checked first, so path:github.com/smirkhealth
    -- takes priority over a domain-level github.com in the other list
    if matchesRules(url, smirkRules) then return "Smirk" end
    if matchesRules(url, personalRules) then return "Personal" end
    return nil
end

---------------------------------------------------------------------------
-- YouTube video state (requires --enable-applescript-javascript)
---------------------------------------------------------------------------

local function isYouTubeVideo(url)
    return url:match("youtube%.com/watch") or url:match("youtu%.be/")
end

local function getVideoState()
    local ok, result = hs.osascript.applescript([[
        tell application "Dia"
            tell active tab of window 1
                execute javascript "
                    var v = document.querySelector('video');
                    v ? JSON.stringify({time: Math.floor(v.currentTime), paused: v.paused}) : '{}'
                "
            end tell
        end tell
    ]])
    if ok and result then
        local time = tonumber(tostring(result):match('"time":(%d+)'))
        local paused = tostring(result):match('"paused":(%a+)') == "true"
        if time and time > 0 then
            return time, not paused
        end
    end
    return nil, false
end

local function appendTimestamp(url, seconds)
    if not seconds or seconds <= 0 then return url end
    url = url:gsub("[?&]t=%d+s?", "")
    local separator = url:find("?") and "&" or "?"
    return url .. separator .. "t=" .. seconds .. "s"
end

local function autoPlayVideo()
    hs.timer.doAfter(3, function()
        hs.osascript.applescript([[
            tell application "Dia"
                tell active tab of window 1
                    execute javascript "
                        var v = document.querySelector('video');
                        if (v && v.paused) v.play();
                    "
                end tell
            end tell
        ]])
    end)
end

---------------------------------------------------------------------------
-- Profile detection and tab operations
---------------------------------------------------------------------------

local function findProfileWindow(profileName)
    local app = hs.application.find(DIA_BUNDLE)
    if not app then return nil end
    for _, w in ipairs(app:allWindows()) do
        local isSmirk = w:title():find("Smirk:") ~= nil
        if profileName == "Smirk" and isSmirk then return w end
        if profileName == "Personal" and not isSmirk then return w end
    end
    return nil
end

local function moveCurrentTabToProfile(url, targetProfile)
    local app = hs.application.find(DIA_BUNDLE)
    if not app then return end

    local targetWin = findProfileWindow(targetProfile)
    if not targetWin then
        flog("WARN: Could not find " .. targetProfile .. " window")
        return
    end

    -- Preserve YouTube video state before closing
    local wasPlaying = false
    if isYouTubeVideo(url) then
        flog("YouTube video detected, getting state")
        local seconds, playing = getVideoState()
        wasPlaying = playing
        if seconds then
            flog("Playback position: " .. seconds .. "s, playing: " .. tostring(playing))
            url = appendTimestamp(url, seconds)
        else
            flog("Could not get video state (JS flag may not be enabled)")
        end
    end

    flog("Closing active tab")
    hs.osascript.applescript('tell application "Dia" to close active tab of window 1')

    local targetIndex = nil
    for i, w in ipairs(app:allWindows()) do
        if w:id() == targetWin:id() then
            targetIndex = i
            break
        end
    end

    flog("Opening in " .. targetProfile .. " (window " .. (targetIndex or 1) .. ")")
    hs.osascript.applescript(string.format(
        'tell application "Dia" to make new tab in window %d with properties {URL:"%s"}',
        targetIndex or 1,
        url:gsub('"', '\\"')
    ))

    targetWin:focus()
    app:activate()

    if wasPlaying then
        flog("Video was playing, will auto-play after load")
        autoPlayVideo()
    end

    local icon = targetProfile == "Smirk" and "💼" or "🏠"
    hs.notify.new(nil, {
        title = icon .. "  Routed to " .. targetProfile,
        informativeText = url,
        withdrawAfter = 2,
    }):send()
end

---------------------------------------------------------------------------
-- Tab watcher — monitors window title changes to detect new page loads
---------------------------------------------------------------------------

M.filter = hs.window.filter.new(false):setAppFilter("Dia")
M.filter:subscribe(hs.window.filter.windowTitleChanged, function(win)
    if not win then return end

    local app = win:application()
    if not app or app:bundleID() ~= DIA_BUNDLE then return end

    hs.timer.doAfter(0.5, function()
        local fw = hs.window.focusedWindow()
        if not fw or fw:id() ~= win:id() then return end

        local ok, url = hs.osascript.applescript('tell application "Dia" to return URL of active tab of window 1')
        if not ok or not url then return end
        url = tostring(url)

        flog("Title changed — URL: " .. url)

        local targetProfile = profileForURL(url)
        if not targetProfile then
            flog("No routing rule for this URL")
            return
        end

        local isSmirk = win:title():find("Smirk:") ~= nil
        local currentProfile = isSmirk and "Smirk" or "Personal"
        if currentProfile == targetProfile then
            flog("Already in correct profile (" .. currentProfile .. ")")
            return
        end

        if isOnCooldown(url) then
            flog("On cooldown, skipping")
            return
        end

        flog("=== Auto-routing to " .. targetProfile .. " ===")
        markRouted(url)
        moveCurrentTabToProfile(url, targetProfile)
    end)
end)

---------------------------------------------------------------------------
-- External URL handler (when Hammerspoon is set as default browser)
---------------------------------------------------------------------------

hs.urlevent.httpCallback = function(scheme, host, params, fullURL)
    flog("=== External URL: " .. fullURL .. " ===")

    local targetProfile = profileForURL(fullURL) or "Personal"
    flog("Routing to " .. targetProfile)

    local app = hs.application.find(DIA_BUNDLE)
    if not app then
        hs.application.launchBundleID(DIA_BUNDLE)
        hs.timer.usleep(1000000)
        app = hs.application.find(DIA_BUNDLE)
    end

    local targetWin = findProfileWindow(targetProfile)
    if targetWin then
        local targetIndex = nil
        for i, w in ipairs(app:allWindows()) do
            if w:id() == targetWin:id() then
                targetIndex = i
                break
            end
        end
        hs.osascript.applescript(string.format(
            'tell application "Dia" to make new tab in window %d with properties {URL:"%s"}',
            targetIndex or 1,
            fullURL:gsub('"', '\\"')
        ))
        targetWin:focus()
    else
        flog("WARN: " .. targetProfile .. " window not found, using window 1")
        hs.osascript.applescript(string.format(
            'tell application "Dia" to make new tab in window 1 with properties {URL:"%s"}',
            fullURL:gsub('"', '\\"')
        ))
    end

    app:activate()
end

return M
