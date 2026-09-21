-- moonlight-quit.lua
-- Cmd+Q ends a Moonlight stream, instead of Moonlight's built-in
-- Ctrl+Option+Shift+Q, which is awkward to reach and collides with Aqua
-- Voice's Ctrl+Shift dictation hotkey.
--
-- Only active while Moonlight is frontmost; Cmd+Q everywhere else is untouched.
-- Inside a stream, Cmd reaches the Linux host as Super, and Omarchy binds
-- nothing to Super+Q (Super+W closes windows), so nothing is lost there.
--
-- The replacement chord is posted with RIGHT-side modifiers: Aqua Voice's
-- hotkey is LEFT Ctrl + LEFT Shift, so the synthetic chord cannot start a
-- dictation. Moonlight accepts either side.

local M = {}

local MOONLIGHT = "com.moonlight-stream.Moonlight"
local Q = hs.keycodes.map["q"]
local ev = hs.eventtap.event
local tap

local function sendMoonlightQuit()
    local mods = { "rightctrl", "rightalt", "rightshift" }
    for _, m in ipairs(mods) do ev.newKeyEvent(m, true):post() end
    ev.newKeyEvent({ "ctrl", "alt", "shift" }, "q", true):post()
    ev.newKeyEvent({ "ctrl", "alt", "shift" }, "q", false):post()
    for i = #mods, 1, -1 do ev.newKeyEvent(mods[i], false):post() end
end

function M.start()
    tap = hs.eventtap.new({ ev.types.keyDown }, function(e)
        if e:getKeyCode() ~= Q then return false end
        local f = e:getFlags()
        if not (f.cmd and not f.ctrl and not f.alt and not f.shift) then return false end
        local app = hs.application.frontmostApplication()
        if not app or app:bundleID() ~= MOONLIGHT then return false end
        -- Post outside the tap callback so our own events are not re-entrant.
        hs.timer.doAfter(0, sendMoonlightQuit)
        return true -- swallow the Cmd+Q so it never reaches the host
    end)
    tap:start()
    M.tap = tap
    return M
end

return M
