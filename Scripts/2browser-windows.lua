-- Define the padding between windows
local padding = 10

-- Define the list of URLs you want to open
local urlList = {
	"https://gmail.com",
	"https://google.com",
	-- Add more URLs here as needed
	-- "https://example.com",
	-- "https://another-example.com",
}

-- Check if there's only 1 display and if the screen size matches the specified dimensions
local screen = hs.screen.mainScreen()
local screenFrame = screen:frame()
local onLaptop = (#hs.screen.allScreens() == 1) and (screenFrame.w == 1680) and (screenFrame.h == 1025)

-- Define function to arrange Arc windows
function arrangeArcWindows()
	-- Launch or focus Arc
	hs.application.launchOrFocus("Arc")
	hs.timer.usleep(1000000) -- Wait for 1 second to ensure Arc is fully launched

	-- -- Try to find Arc using both name and bundle ID
	-- local arcApp = hs.application.find('Arc') or hs.application.get('company.thebrowser.Browser')

	-- if not arcApp then
	--     hs.alert.show("Arc isn't running")
	--     hs.sound.getByName("Glass"):play()  -- Use "Glass" sound as an example
	--     return
	-- end

	-- Get the screen and its dimensions
	local screen = hs.screen.mainScreen()
	local screenFrame = screen:frame()

	-- Calculate window frames
	local leftWindowFrame = hs.geometry.rect(
		screenFrame.x + padding,
		screenFrame.y + padding,
		(screenFrame.w / 2) - (1.5 * padding),
		screenFrame.h - (2 * padding)
	)
	local rightWindowFrame = hs.geometry.rect(
		screenFrame.x + (screenFrame.w / 2) + (0.5 * padding),
		screenFrame.y + padding,
		(screenFrame.w / 2) - (1.5 * padding),
		screenFrame.h - (2 * padding)
	)

	-- Get all Arc windows
	local arcWindows = arcApp:allWindows()

	-- Open new windows if needed
	local numWindowsNeeded = #urlList - #arcWindows
	if numWindowsNeeded > 0 then
		for i = 1, numWindowsNeeded do
			if not openInArc(urlList[#arcWindows + i]) then
				return
			end
			hs.timer.usleep(1000000) -- 1 second delay
		end
	end

	-- Refresh the window list
	arcWindows = arcApp:allWindows()

	-- Ensure we have at least two windows
	if #arcWindows < 2 then
		local numWindowsNeeded = 2 - #arcWindows
		for i = 1, numWindowsNeeded do
			if not openInArc(urlList[i]) then
				return
			end
			hs.timer.usleep(1000000) -- 1 second delay
		end
	end

	-- Refresh the window list again
	arcWindows = arcApp:allWindows()

	-- Move the first Arc window to the left side
	if arcWindows[1] then
		arcWindows[1]:setFrame(leftWindowFrame)
		if onLaptop then
			arcWindows[1]:focus()
			hs.eventtap.keyStroke({ "cmd" }, "S")
		end
	end

	-- Move the second Arc window to the right side
	if arcWindows[2] then
		arcWindows[2]:setFrame(rightWindowFrame)
		if onLaptop then
			arcWindows[2]:focus()
			hs.eventtap.keyStroke({ "cmd" }, "S")
		end
	end
end

-- Bind a hotkey to arrange Arc windows (Ctrl + P)
hs.hotkey.bind({ "ctrl" }, "P", function()
	local success, error = pcall(arrangeArcWindows)
	if not success then
		hs.alert.show("Arc isn't running")
		hs.sound.getByName("Glass"):play() -- Use "Glass" sound as an example
		print("Error in arrangeArcWindows:", error)
	end
end)

-- Add this function at the top of your file
function openInArc(url)
	-- Ensure the URL has a proper scheme
	if not string.match(url, "^https?://") then
		url = "https://" .. url
	end

	local script = [[
        try
            tell application "Arc"
                activate
                make new window
                tell front window
                    make new tab with properties {URL:"]] .. url .. [["}
                end tell
            end tell
            return "Success"
        on error errMsg
            return "Error: " & errMsg
        end try
    ]]
	local success, result, rawResult = hs.osascript.applescript(script)
	if not success then
		hs.alert.show("Failed to open URL in Arc: " .. tostring(result))
	elseif string.sub(result, 1, 5) == "Error" then
		hs.alert.show("AppleScript error: " .. result)
		success = false
	end
	return success
end
