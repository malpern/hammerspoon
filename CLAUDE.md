# Hammerspoon Config

## Dia Browser (company.thebrowser.dia)

### AppleScript is the right approach for Dia

Dia is Chromium-based and **ignores synthetic keystrokes** from `hs.eventtap.keyStroke` and `hs.eventtap.event.newKeyEvent`. These are CGEvents that Chromium silently drops.

What works:
- **AppleScript via `hs.osascript.applescript`** — Dia has a working AppleScript API
- **System Events `keystroke`** — goes through the accessibility layer, which Chromium respects

Prefer Dia's native AppleScript API over System Events keystrokes when possible:
- `tell application "Dia" to return URL of active tab of window 1`
- `tell application "Dia" to close active tab of window 1`
- `tell application "Dia" to make new tab in window 2 with properties {URL:"..."}`
- `tell application "Dia" to return name of window 1`

Note: Dia's AppleScript `name of window` returns just the page title. Hammerspoon's `window:title()` includes the profile prefix (e.g., "Smirk: Page Title"). Use Hammerspoon's window API for profile detection.

### Dia profile detection

- The **Personal** profile has **no prefix** in window titles — it's just the page title
- Other profiles like **Smirk** are prefixed: "Smirk: Page Title"
- Detect Personal by the **absence** of a known prefix, not by looking for "Personal:"

### Keyboard Maestro conflicts

Keyboard Maestro can intercept keystrokes before they reach Dia (or before Hammerspoon's System Events AppleScript delivers them). If synthetic keystrokes silently fail, check for KM macro conflicts. KM macros can be disabled via:
```applescript
tell application "Keyboard Maestro"
    set m to first macro whose name is "Macro Name"
    set enabled of m to false
end tell
```

## Hotkey scoping

`hs.window.filter` for enabling/disabling hotkeys is unreliable — the `windowFocused`/`windowUnfocused` events don't always fire. Prefer `hs.hotkey.bind` (always enabled) with an app bundle ID check at the top of the callback:
```lua
if not app or app:bundleID() ~= BUNDLE_ID then return end
```

## Debugging

Write logs to a file — `hs.logger` history is lost across `hs -c` sessions:
```lua
local LOGFILE = os.getenv("HOME") .. "/.hammerspoon/scriptname.log"
local function flog(msg)
    local f = io.open(LOGFILE, "a")
    if f then
        f:write(os.date("%H:%M:%S") .. " " .. msg .. "\n")
        f:close()
    end
end
```

## Reloading

`open -g hammerspoon://reload` or `hs -c "hs.reload()"`. The `require` cache can serve stale modules — a full `hs.reload()` is more reliable than re-requiring individual modules.
