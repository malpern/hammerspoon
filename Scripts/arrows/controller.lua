--[[
    Controller module for the Arrows system
    
    This module coordinates all the components and handles:
    - Window lifecycle management
    - Event handling (keyboard events)
    - State management
    - Component coordination

    Return values:
    - All public functions MUST return explicit values
    - createWindow() returns boolean - true if window created successfully
    - init() returns nil but must initialize all components
    - cleanup() returns nil but must clean up all resources
    - checkCelebration() returns boolean - true if celebration triggered
    - resetState() returns nil but must reset all state fields
    - nil returns indicate bugs and are NOT valid
]]

local model = require("Scripts.arrows.model")
local view = require("Scripts.arrows.view")
local sound = require("Scripts.arrows.utils.sound")
local animation = require("Scripts.arrows.utils.animation")

---@class State
---@field activeWebview userdata|nil The currently active webview
---@field fadeTimer userdata|nil Timer for fading out the window
---@field deleteTimer userdata|nil Timer for deleting the window
---@field lastKeyPressed string|nil The last key that was pressed
---@field inKeySequence boolean Whether we're in a key sequence
---@field lastArrowPress string|nil The last arrow key that was pressed
---@field lastArrowTime number The timestamp of the last arrow press
---@field isHyperGenerated boolean Whether the current event was generated by hyper key
---@field position table The current window position
local State = {
	activeWebview = nil,
	fadeTimer = nil,
	deleteTimer = nil,
	lastKeyPressed = nil,
	inKeySequence = model.State.INITIAL.inKeySequence,
	lastArrowPress = nil,
	lastArrowTime = 0,
	isHyperGenerated = model.State.INITIAL.isHyperGenerated,
	position = nil,
}

local M = {}

-- Initialize state
local State = {
	activeWebview = nil,
	fadeTimer = nil,
	deleteTimer = nil,
	lastKeyPressed = nil,
	inKeySequence = model.State.INITIAL.inKeySequence,
	lastArrowPress = nil,
	lastArrowTime = 0,
	isHyperGenerated = model.State.INITIAL.isHyperGenerated,
	position = nil,
}

-- Expose state for testing
M.State = State

-- Reset state function
function M.resetState()
	State.activeWebview = nil
	State.fadeTimer = nil
	State.deleteTimer = nil
	State.lastKeyPressed = nil
	State.inKeySequence = model.State.INITIAL.inKeySequence
	State.lastArrowPress = nil
	State.lastArrowTime = 0
	State.isHyperGenerated = model.State.INITIAL.isHyperGenerated
	State.position = nil
end

-- Call resetState on module load
M.resetState()

-- Window position management
---@return table position The calculated window position
local function calculateWindowPosition()
	local style = model.Style.WINDOW
	local screen = hs.screen.mainScreen()
	local frame = screen:frame()

	-- Default position (top right)
	local position = {
		x = frame.x + frame.w - style.WIDTH - style.MARGIN,
		y = frame.y + style.MARGIN,
		w = style.WIDTH,
		h = style.HEIGHT,
	}

	-- Save position for next time
	State.position = position
	return position
end

-- Window lifecycle management
---@param direction string The direction to display (from model.Direction)
---@param keyType string The key type (from model.KeyType)
---@return boolean success Whether the window was created successfully
function M.createWindow(direction, keyType)
	-- Cancel existing timers
	if State.fadeTimer then
		State.fadeTimer:stop()
	end
	if State.deleteTimer then
		State.deleteTimer:stop()
	end

	-- Clean up existing webview
	if State.activeWebview then
		State.activeWebview:delete()
		State.activeWebview = nil
	end

	-- Calculate window position
	local pos = State.position or calculateWindowPosition()

	-- Create new webview
	local success, webview = pcall(function()
		local w = hs.webview.new(pos)
		if not w then
			error("Failed to create webview")
		end
		return w
	end)

	if not success or not webview then
		print("Failed to create webview:", webview)
		return false
	end

	-- Store webview in state and update exposed state
	State.activeWebview = webview
	M.State = State

	-- Configure webview
	local success, err = pcall(function()
		State.activeWebview:windowStyle({ "borderless", "closable", "nonactivating" })
		State.activeWebview:level(hs.drawing.windowLevels.floating)
		State.activeWebview:alpha(1.0)
		State.activeWebview:allowTextEntry(false)
		State.activeWebview:transparent(true)
		State.activeWebview:bringToFront()

		-- Generate and set HTML
		local html = view.generateWindowHtml(direction, keyType)
		State.activeWebview:html(html)
		State.activeWebview:show()

		-- Set up fade out
		State.fadeTimer = hs.timer.doAfter(model.Style.ANIMATION.DISPLAY_DURATION, function()
			animation.fadeOut(State.activeWebview, function()
				if State.activeWebview then
					State.activeWebview:delete()
					State.activeWebview = nil
				end
			end)
		end)
	end)

	if not success then
		print("Failed to configure webview:", err)
		if State.activeWebview then
			State.activeWebview:delete()
			State.activeWebview = nil
		end
		return false
	end

	return true
end

-- Celebration management
---@param direction string The direction to check (from model.Direction)
---@param keyType string The key type that was pressed (from model.KeyType)
---@return boolean triggered Whether a celebration was triggered
function M.checkCelebration(direction, keyType)
	local currentTime = hs.timer.secondsSinceEpoch()

	if keyType == model.KeyType.ARROW then
		-- Store the arrow press
		State.lastArrowPress = direction
		State.lastArrowTime = currentTime
		print(string.format("📝 Arrow key pressed: %s - Starting celebration window", direction))
	else
		-- Check if this vim motion matches a recent arrow press
		if State.lastArrowPress then
			local timeDiff = currentTime - State.lastArrowTime
			print(
				string.format(
					"⌨️  Vim motion: %s (Previous arrow: %s, Time diff: %.2fs)",
					direction,
					State.lastArrowPress,
					timeDiff
				)
			)

			if timeDiff < model.Timing.CELEBRATION.TIMEOUT and State.lastArrowPress == direction then
				print("🎯 Match found! Arrow + Vim combination detected")
				animation.triggerCelebration()
				-- Reset after celebration
				State.lastArrowPress = nil

				-- Show success feedback
				hs.alert.show("🎉 Great job! You used both arrow and vim keys!", 1)
			else
				if timeDiff >= model.Timing.CELEBRATION.TIMEOUT then
					print("⌛ Too slow - celebration window expired")
					hs.alert.show("⌛ Too slow! Try again faster!", 1)
				elseif State.lastArrowPress ~= direction then
					print("❌ No match - wrong direction")
					hs.alert.show("❌ Wrong direction! Try to match the arrow key!", 1)
				end
				State.lastArrowPress = nil
			end
		else
			print("ℹ️  Vim motion without recent arrow press")
		end
	end
end

-- Event handling
---@param event userdata The keyboard event
---@return boolean handled Whether the event was handled
local function handleHyperKey(event)
	local keyCode = event:getKeyCode()
	local flags = event:getFlags()

	-- Only process if ALL Hyper modifiers are pressed
	local isHyper = flags.cmd and flags.alt and flags.shift and flags.ctrl
	if not isHyper then
		return false
	end

	local direction = nil
	local arrowKeyCode = nil

	-- Map key codes to directions
	for dir, mapping in pairs(model.KeyMappings) do
		if keyCode == hs.keycodes.map[mapping.vim] then
			direction = dir
			arrowKeyCode = mapping.keycode
			break
		end
	end

	if direction then
		State.isHyperGenerated = true

		-- Show visual feedback and play sound
		M.createWindow(direction, model.KeyType.VIM)
		sound.playSound(direction, model.KeyType.VIM)

		-- Check for celebration before simulating arrow key
		M.checkCelebration(direction, model.KeyType.VIM)

		-- Simulate arrow key press
		local arrowEvent = hs.eventtap.event.newKeyEvent({}, arrowKeyCode, true)
		arrowEvent:post()

		-- Reset the flag after a short delay
		hs.timer.doAfter(model.Timing.KEY.HYPER_RESET, function()
			State.isHyperGenerated = false
		end)

		return true
	end

	return false
end

---@param event userdata The keyboard event
---@return boolean handled Whether the event was handled
local function handleArrowKey(event)
	if State.isHyperGenerated then
		return false
	end

	local keyCode = event:getKeyCode()
	local direction = nil

	-- Map key codes to directions
	for dir, mapping in pairs(model.KeyMappings) do
		if keyCode == mapping.keycode then
			direction = dir
			break
		end
	end

	if direction then
		-- Show visual feedback and play sound
		M.createWindow(direction, model.KeyType.ARROW)
		sound.playSound(direction, model.KeyType.ARROW)
		M.checkCelebration(direction, model.KeyType.ARROW)
	end

	return false -- Always return false to allow the key event to pass through
end

-- Initialize watchers and components
---@return nil
function M.init()
	-- Initialize state
	State = {
		activeWebview = nil,
		fadeTimer = nil,
		deleteTimer = nil,
		lastKeyPressed = nil,
		inKeySequence = model.State.INITIAL.inKeySequence,
		lastArrowPress = nil,
		lastArrowTime = 0,
		isHyperGenerated = model.State.INITIAL.isHyperGenerated,
		position = nil,
	}

	-- Create watchers
	M.hyperWatcher = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, handleHyperKey)
	M.arrowWatcher = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, handleArrowKey)

	-- Start watchers
	M.hyperWatcher:start()
	M.arrowWatcher:start()

	-- Show startup message
	hs.alert.show("🎮 Arrow Keys Enhancement Active!", 1)
end

-- Cleanup function
---@return nil
function M.cleanup()
	-- Stop watchers
	if M.hyperWatcher then
		M.hyperWatcher:stop()
	end
	if M.arrowWatcher then
		M.arrowWatcher:stop()
	end

	-- Clean up window
	if State.activeWebview then
		State.activeWebview:delete()
	end
	if State.fadeTimer then
		State.fadeTimer:stop()
	end
	if State.deleteTimer then
		State.deleteTimer:stop()
	end

	-- Reset state
	State = nil

	-- Show shutdown message
	hs.alert.show("👋 Arrow Keys Enhancement Deactivated", 1)
end

return M