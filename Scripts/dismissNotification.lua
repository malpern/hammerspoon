local M = {}

-- Add initialization debug message
print("Loading dismissNotification module...")

-- Add this near the top of your file after local M = {}
local keyLogger = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(e)
	local flags = e:getFlags()
	local keycode = e:getKeyCode()
	local char = e:getCharacters()
	print(string.format("Key pressed - keycode: %d, char: %s, flags: %s", keycode, char, hs.inspect(flags)))
	return false
end)
keyLogger:start()

-- Function to dismiss the first visible notification
function M.dismissNotification()
	-- Add more detailed debug message
	print("dismissNotification function called")
	hs.alert.show("Triggered: Control + Option + Command + Shift + Delete")

	-- Coordinates for the "X" button of the first notification
	local x = 3084.32421875
	local y = 47.4140625

	-- Move the mouse to the "X" button
	hs.mouse.setAbsolutePosition({ x = x, y = y })

	-- Add a small delay to ensure the mouse has moved
	hs.timer.usleep(200000) -- 200ms delay (adjust if necessary)

	-- Simulate a left mouse click to dismiss the notification
	hs.eventtap.leftClick({ x = x, y = y })

	-- Log that a notification was closed
	print("Notification dismissed at position: x=" .. x .. ", y=" .. y)
end

-- Test if the key combination is valid
local mods = { "ctrl", "alt", "cmd", "shift" }
local key = "delete"
print("Attempting to bind hotkey: " .. key .. " with modifiers: " .. hs.inspect(mods))

M.hotkey = hs.hotkey.bind(mods, key, function()
	print("Hotkey triggered")
	M.dismissNotification()
end)

-- More detailed binding check
if M.hotkey then
	print("Hotkey successfully bound to: Control + Option + Command + Shift + Delete")
	-- Print the hotkey details
	print("Hotkey details: " .. hs.inspect(M.hotkey))
else
	print("Failed to bind hotkey - hotkey object is nil")
end

return M
