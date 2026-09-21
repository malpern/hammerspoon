-- moonlight-keys.lua
-- Make a Moonlight stream to the linux box behave like a Mac app.
--
--   Cmd+Q     end the stream (Moonlight's own Ctrl+Option+Shift+Q)
--   fn+Esc    back to the Mac: minimize the stream (Moonlight's Ctrl+Option+Shift+D)
--   Cmd+V     unchanged -- it is Omarchy's universal paste -- but the clipboards are
--             synced, so it pastes whatever was copied last on EITHER machine
--
-- Keys are only intercepted while Moonlight is frontmost. Inside a stream Cmd reaches
-- linux as Super, so a Cmd shortcut is only safe here if Omarchy binds nothing to it
-- (Super+Q is free; Super+W closes windows). fn is the one modifier that never reaches
-- linux at all, which is why the escape hatch lives on it.
--
-- Moonlight's chords are posted with RIGHT-side modifiers: Aqua Voice's dictation hotkey
-- is LEFT Ctrl + LEFT Shift, so a synthetic chord cannot start a dictation. Moonlight
-- accepts either side.
--
-- Clipboard sync runs over ssh to `~/.local/bin/clip-sync` on linux (dotfiles repo):
--   Moonlight comes to the front  -> push the Mac clipboard to linux, if it changed
--   Moonlight leaves the front    -> pull linux's clipboard to the Mac, if it changed
-- Text only. Anything a password manager marks concealed or transient never leaves the Mac.

local M = {}

local MOONLIGHT = "com.moonlight-stream.Moonlight"
local SSH = "/usr/bin/ssh"
local HOST = "linux"
local MAX_BYTES = 1024 * 1024
-- nspasteboard.org markers set by 1Password, Bitwarden, Keychain Access and friends.
local PRIVATE_TYPES = {
    ["org.nspasteboard.ConcealedType"] = true,
    ["org.nspasteboard.TransientType"] = true,
}

local ev = hs.eventtap.event
local keycode = hs.keycodes.map
local log = hs.logger.new("moonlight", "info")

-- ---------------------------------------------------------------- keys

local function sendMoonlightChord(key)
    local mods = { "rightctrl", "rightalt", "rightshift" }
    for _, m in ipairs(mods) do ev.newKeyEvent(m, true):post() end
    ev.newKeyEvent({ "ctrl", "alt", "shift" }, key, true):post()
    ev.newKeyEvent({ "ctrl", "alt", "shift" }, key, false):post()
    for i = #mods, 1, -1 do ev.newKeyEvent(mods[i], false):post() end
end

local function moonlightFrontmost()
    local app = hs.application.frontmostApplication()
    return app ~= nil and app:bundleID() == MOONLIGHT
end

-- keycode -> { exact modifier set, Moonlight chord key }
local BINDINGS = {
    [keycode["q"]] = { mods = { cmd = true }, chord = "q" },      -- end stream
    [keycode["escape"]] = { mods = { fn = true }, chord = "d" },  -- minimize
}

local function modsMatch(flags, want)
    for _, m in ipairs({ "cmd", "ctrl", "alt", "shift", "fn" }) do
        if (flags[m] and true or false) ~= (want[m] and true or false) then return false end
    end
    return true
end

-- ----------------------------------------------------------- clipboard

local lastChange = -1  -- so the first activation always pushes the current Mac clipboard
local lastSynced = nil -- text known to be on both clipboards
local entered = false  -- never pull before a push: a stale linux clipboard must not
                       -- overwrite the Mac's just because Hammerspoon reloaded mid-stream
local busy = false

local function isPrivate()
    for _, t in ipairs(hs.pasteboard.contentTypes() or {}) do
        if PRIVATE_TYPES[t] then return true end
    end
    return false
end

local function push()
    local cc = hs.pasteboard.changeCount()
    if cc == lastChange then return end
    lastChange = cc
    if isPrivate() then log.i("push skipped: concealed/transient clipboard"); return end
    local text = hs.pasteboard.readString()
    if not text or text == "" or #text > MAX_BYTES or text == lastSynced then return end
    -- Via a 0600 temp file, not task:setInput(): setInput writes asynchronously, and the
    -- closeInput() that must follow it can land first, so ssh saw EOF, succeeded, and
    -- linux got an EMPTY clipboard. The shell removes the file whatever ssh does.
    local path = os.tmpname()
    local f = io.open(path, "w")
    if not f then log.w("push failed: cannot write temp file"); return end
    f:write(text)
    f:close()
    hs.execute("/bin/chmod 600 " .. path)
    hs.task.new("/bin/sh", function(code, _, err)
        if code == 0 then lastSynced = text else log.w("push failed: " .. (err or code)) end
    end, { "-c", SSH .. ' -o BatchMode=yes -o ConnectTimeout=3 ' .. HOST ..
        ' "~/.local/bin/clip-sync set" < "$1"; rc=$?; rm -f "$1"; exit $rc', "_", path }):start()
end

local function pull()
    if busy then return end
    busy = true
    hs.task.new(SSH, function(code, out, err)
        busy = false
        if code ~= 0 then log.w("pull failed: " .. (err or code)); return end
        if not out or out == "" or out == lastSynced or #out > MAX_BYTES then return end
        hs.pasteboard.setContents(out)
        lastSynced = out
        lastChange = hs.pasteboard.changeCount() -- our own write is not a new Mac copy
    end, { "-o", "BatchMode=yes", "-o", "ConnectTimeout=3", HOST, "~/.local/bin/clip-sync get" }):start()
end

-- --------------------------------------------------------------- start

function M.start()
    M.tap = hs.eventtap.new({ ev.types.keyDown }, function(e)
        local b = BINDINGS[e:getKeyCode()]
        if not b or not modsMatch(e:getFlags(), b.mods) or not moonlightFrontmost() then
            return false
        end
        -- Post outside the tap callback so our own events are not re-entrant.
        hs.timer.doAfter(0, function() sendMoonlightChord(b.chord) end)
        return true -- swallow it so it never reaches the host
    end)
    M.tap:start()

    M.watcher = hs.application.watcher.new(function(_, event, app)
        if not app or app:bundleID() ~= MOONLIGHT then return end
        if event == hs.application.watcher.activated then
            entered = true
            push()
        elseif entered and (event == hs.application.watcher.deactivated
            or event == hs.application.watcher.hidden) then
            pull()
        end
    end)
    M.watcher:start()
    return M
end

return M
