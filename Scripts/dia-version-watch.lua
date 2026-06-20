-- dia-version-watch.lua
-- Dia 1.36.0 crashes when launched with --enable-applescript-javascript (stack
-- overflow), so ProfileRouter runs Dia flagless and its YouTube position-preserve
-- feature is disabled (jsCapable=false). The fix will ship in a newer Dia build.
--
-- This watcher notifies — once per new version — when the installed Dia moves
-- past the known-bad build, so you know to re-test the flag. It does NOT launch
-- the flag or auto-test (that would crash an unfixed Dia); you stay in control.
-- Re-test steps: ~/local-code/ProfileRouter/docs/dia-applescript-js-crash-report.md

local M = {}

local KNOWN_BAD   = "1.36.0"
local DIA_BUNDLE  = "company.thebrowser.dia"
local SETTINGS_KEY = "diaFlagRetestNotifiedFor"   -- last version we already alerted on

-- "1.36.0" -> {1, 36, 0}
local function parseVersion(s)
    local parts = {}
    for n in tostring(s):gmatch("%d+") do parts[#parts + 1] = tonumber(n) end
    return parts
end

-- is a strictly newer than b?
local function isNewer(a, b)
    local va, vb = parseVersion(a), parseVersion(b)
    for i = 1, math.max(#va, #vb) do
        local x, y = va[i] or 0, vb[i] or 0
        if x ~= y then return x > y end
    end
    return false
end

-- Read Dia's version from its Info.plist without launching it.
local function diaVersion()
    local info = hs.application.infoForBundleID(DIA_BUNDLE)
    return info and info.CFBundleShortVersionString
end

local function check()
    local v = diaVersion()
    if not v or not isNewer(v, KNOWN_BAD) then return end
    if hs.settings.get(SETTINGS_KEY) == v then return end   -- already alerted for this version

    hs.notify.new(nil, {
        title = "Dia updated to " .. v,
        subTitle = "AppleScript-JS flag worth re-testing",
        informativeText = "Dia " .. KNOWN_BAD .. " crashed with --enable-applescript-javascript. "
            .. "Re-test the flag; if fixed, set jsCapable=true in ProfileRouter.",
        withdrawAfter = 0,   -- persist in Notification Center until dismissed
    }):send()
    hs.settings.set(SETTINGS_KEY, v)
end

function M.start()
    check()   -- catch the case where Dia already updated while HS was off
    M._watcher = hs.application.watcher.new(function(_, event, app)
        if event == hs.application.watcher.launched
            and app and app:bundleID() == DIA_BUNDLE then
            hs.timer.doAfter(3, check)
        end
    end)
    M._watcher:start()
    return M
end

return M
