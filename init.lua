require("hs.ipc")

hs.loadSpoon("ReloadConfiguration")
-- spoon.ReloadConfiguration:start()  -- Removed auto-reload on file changes

-- Load the custom scripts using require instead of dofile
local dismissNotif = require("Scripts.dismissNotification")
--require("Scripts.2browser-windows")
require("Scripts.mouse-highlight")
-- require("Scripts.birthdayCountdown")
require("Scripts.arrows")
