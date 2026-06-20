require("hs.ipc")

hs.loadSpoon("ReloadConfiguration")
-- spoon.ReloadConfiguration:start()  -- Removed auto-reload on file changes

-- Load the custom scripts using require instead of dofile
-- local dismissNotif = require("Scripts.dismissNotification")  -- disabled: hardcoded coords + keylogger
--require("Scripts.2browser-windows")
require("Scripts.mouse-highlight")
-- require("Scripts.birthdayCountdown")
-- require("Scripts.arrows")  -- disabled

-- ProfileRouter (managed in its own repo: ~/local-code/ProfileRouter,
-- symlinked into Spoons/). Create ~/.hammerspoon/routes/<profile>.txt files to
-- activate it; until then it just warns "No route files found".
hs.loadSpoon("ProfileRouter")
spoon.ProfileRouter:start()
spoon.ProfileRouter:bindHotkeys({ cycleTab = { { "ctrl" }, "s" } })
