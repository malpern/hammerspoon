--[[
    Test module for the Arrows system
    
    This module provides integration tests and debugging utilities to ensure
    all components work together correctly.

    Return values for test functions:
    - All test functions MUST return boolean
    - true indicates test passed
    - false indicates test failed
    - nil is NOT a valid return value and indicates a bug
]]

local model = require("Scripts.arrows.model")
local sound = require("Scripts.arrows.utils.sound")
local animation = require("Scripts.arrows.utils.animation")
local view = require("Scripts.arrows.view")
local controller = require("Scripts.arrows.controller")

local M = {}

-- Test utilities
local function printHeader(text)
	print("\n" .. string.rep("=", 50))
	print(text)
	print(string.rep("=", 50))
end

local function printResult(name, success, message)
	print(string.format("%s %s: %s", success and "✅" or "❌", name, message or (success and "Success" or "Failed")))
end

-- Component tests
--[[
    Tests the View component's HTML generation functionality
    @return {boolean} true if all view tests pass, false otherwise
    Note: Must explicitly return false if any test fails
]]
local function testView()
	printHeader("Testing View Component")

	-- Test HTML generation
	local success = true
	local message = ""

	-- Test VIM mode (Symbol first, then Label)
	local windowHtml = view.generateWindowHtml(model.Direction.UP, model.KeyType.VIM)
	if not windowHtml:match("⬆") then
		success = false
		message = message .. "Missing arrow symbol in VIM mode\n"
	end
	if not windowHtml:match("K") then
		success = false
		message = message .. "Missing key letter in VIM mode\n"
	end

	-- Test ARROW mode (Label first, then Symbol)
	windowHtml = view.generateWindowHtml(model.Direction.UP, model.KeyType.ARROW)
	if not windowHtml:match("⬆") then
		success = false
		message = message .. "Missing arrow symbol in ARROW mode\n"
	end
	if not windowHtml:match("K") then
		success = false
		message = message .. "Missing key letter in ARROW mode\n"
	end

	printResult("View HTML Generation", success, message)
	return success
end

--[[
    Tests the Sound component's initialization and loading
    @return {boolean} true if all sound tests pass, false otherwise
    Note: Must explicitly return false if any test fails
]]
local function testSound()
	printHeader("Testing Sound Component")

	-- Test sound initialization
	local success = sound.init()
	printResult("Sound Initialization", success)

	-- Test sound loading
	local hasAllSounds = true
	local message = ""

	for direction in pairs(model.Direction) do
		if direction ~= "BACK" then
			local dirLower = string.lower(direction)
			if not sound.sounds[dirLower] then
				hasAllSounds = false
				message = message .. "Missing sound for " .. direction .. "\n"
			end
			if not sound.dissonantSounds[dirLower] then
				hasAllSounds = false
				message = message .. "Missing dissonant sound for " .. direction .. "\n"
			end
		end
	end

	if not sound.backSound then
		hasAllSounds = false
		message = message .. "Missing back sound\n"
	end

	printResult("Sound Loading", hasAllSounds, message)
	return success and hasAllSounds
end

--[[
    Tests the Animation component's functionality
    @return {boolean} true if all animation tests pass, false otherwise
    Note: Must explicitly return false if any test fails
]]
local function testAnimation()
	printHeader("Testing Animation Component")

	-- Test celebration script generation
	local success = true
	local message = ""

	-- Create a test webview
	local testWebview = hs.webview.new({ x = 0, y = 0, w = 100, h = 100 })
	testWebview:show()

	-- Test fade animation
	animation.fadeOut(testWebview, function()
		testWebview:delete()
	end)

	-- Test celebration
	local celebrationSuccess = animation.triggerCelebration()
	if not celebrationSuccess then
		success = false
		message = message .. "Celebration animation failed\n"
	end

	printResult("Animation Tests", success, message)
	return success
end

--[[
    Tests the Controller component's functionality
    @return {boolean} true if all controller tests pass, false otherwise
    Note: Must explicitly return false if any test fails
]]
local function testController()
	printHeader("Testing Controller Component")

	local success = true
	local message = ""

	-- Test window creation
	local windowCreated = controller.createWindow(model.Direction.UP, model.KeyType.VIM)
	if not windowCreated then
		success = false
		message = message .. "Window creation failed\n"
	elseif not controller.State.activeWebview then
		success = false
		message = message .. "Window created but not stored in state\n"
	end

	-- Test celebration check
	controller.checkCelebration(model.Direction.UP, model.KeyType.ARROW)
	controller.checkCelebration(model.Direction.UP, model.KeyType.VIM)

	-- Cleanup
	if controller.State.activeWebview then
		controller.State.activeWebview:delete()
		controller.State.activeWebview = nil
	end

	printResult("Controller Tests", success, message)
	return success
end

--[[
    Tests type validation for configuration and state
    @return {boolean} true if all type checks pass, false otherwise
    Note: Must explicitly return false if any validation fails
]]
local function testTypes()
	printHeader("Testing Type Validation")

	local success = true
	local message = ""

	-- Test KeyType enum values
	for key, value in pairs(model.KeyType) do
		if type(value) ~= "string" then
			success = false
			message = message .. string.format("KeyType.%s should be string, got %s\n", key, type(value))
		end
	end

	-- Test Direction enum values
	for key, value in pairs(model.Direction) do
		if type(value) ~= "string" then
			success = false
			message = message .. string.format("Direction.%s should be string, got %s\n", key, type(value))
		end
	end

	-- Test Style configuration
	local style = model.Style
	-- Font validation
	if type(style.FONT.FAMILY) ~= "string" then
		success = false
		message = message .. "Style.FONT.FAMILY should be string\n"
	end
	if type(style.FONT.WEIGHT) ~= "string" then
		success = false
		message = message .. "Style.FONT.WEIGHT should be string\n"
	end
	if not style.FONT.SIZES.SYMBOL or not style.FONT.SIZES.LABEL then
		success = false
		message = message .. "Style.FONT.SIZES missing required fields\n"
	end

	-- Color validation
	if not style.COLORS.BACKGROUND.DEFAULT or not style.COLORS.BACKGROUND.ARROW then
		success = false
		message = message .. "Style.COLORS.BACKGROUND missing required colors\n"
	end

	-- Window validation
	local requiredNumbers = { "WIDTH", "HEIGHT", "MARGIN", "BORDER_RADIUS", "PADDING" }
	for _, field in ipairs(requiredNumbers) do
		if type(style.WINDOW[field]) ~= "number" then
			success = false
			message = message .. string.format("Style.WINDOW.%s should be number\n", field)
		end
	end

	-- Animation timing validation
	local requiredTimings = { "FADE_DURATION", "FADE_STEPS", "DISPLAY_DURATION", "TRANSITION_DELAY" }
	for _, field in ipairs(requiredTimings) do
		if type(style.ANIMATION[field]) ~= "number" then
			success = false
			message = message .. string.format("Style.ANIMATION.%s should be number\n", field)
		end
		if style.ANIMATION[field] < 0 then
			success = false
			message = message .. string.format("Style.ANIMATION.%s should be positive\n", field)
		end
	end

	-- Test Timing configuration
	local timing = model.Timing
	-- Key timing validation
	if type(timing.KEY.HYPER_RESET) ~= "number" or timing.KEY.HYPER_RESET < 0 then
		success = false
		message = message .. "Invalid KEY.HYPER_RESET timing\n"
	end
	if type(timing.KEY.DOUBLE_PRESS) ~= "number" or timing.KEY.DOUBLE_PRESS < 0 then
		success = false
		message = message .. "Invalid KEY.DOUBLE_PRESS timing\n"
	end
	if type(timing.KEY.DEBOUNCE) ~= "number" or timing.KEY.DEBOUNCE < 0 then
		success = false
		message = message .. "Invalid KEY.DEBOUNCE timing\n"
	end

	-- Celebration timing validation
	if type(timing.CELEBRATION.TIMEOUT) ~= "number" or timing.CELEBRATION.TIMEOUT < 0 then
		success = false
		message = message .. "Invalid CELEBRATION.TIMEOUT timing\n"
	end
	if type(timing.CELEBRATION.DURATION) ~= "number" or timing.CELEBRATION.DURATION < 0 then
		success = false
		message = message .. "Invalid CELEBRATION.DURATION timing\n"
	end
	if type(timing.CELEBRATION.REPEAT_COUNT) ~= "number" or timing.CELEBRATION.REPEAT_COUNT < 1 then
		success = false
		message = message .. "Invalid CELEBRATION.REPEAT_COUNT\n"
	end
	if type(timing.CELEBRATION.REPEAT_DELAY) ~= "number" or timing.CELEBRATION.REPEAT_DELAY < 0 then
		success = false
		message = message .. "Invalid CELEBRATION.REPEAT_DELAY timing\n"
	end

	-- Test Sound configuration
	local sound = model.Sound
	-- Volume validation
	if type(sound.VOLUME.NORMAL) ~= "number" or sound.VOLUME.NORMAL < 0 or sound.VOLUME.NORMAL > 1 then
		success = false
		message = message .. "Invalid VOLUME.NORMAL (should be between 0 and 1)\n"
	end
	if type(sound.VOLUME.MUTED) ~= "number" or sound.VOLUME.MUTED ~= 0 then
		success = false
		message = message .. "Invalid VOLUME.MUTED (should be 0)\n"
	end

	-- Path validation
	if type(sound.PATHS.NORMAL) ~= "string" or not sound.PATHS.NORMAL:match("%%s") then
		success = false
		message = message .. "Invalid PATHS.NORMAL format\n"
	end
	if type(sound.PATHS.DISSONANT) ~= "string" or not sound.PATHS.DISSONANT:match("%%s") then
		success = false
		message = message .. "Invalid PATHS.DISSONANT format\n"
	end
	if type(sound.PATHS.BACK) ~= "string" or not sound.PATHS.BACK:match("%.wav$") then
		success = false
		message = message .. "Invalid PATHS.BACK format\n"
	end

	printResult("Type Validation", success, message)
	return success
end

-- Integration tests
function M.runTests()
	printHeader("Starting Integration Tests")

	local results = {
		view = testView(),
		sound = testSound(),
		animation = testAnimation(),
		controller = testController(),
		types = testTypes(), -- Add type validation test
	}

	printHeader("Test Results Summary")
	for component, success in pairs(results) do
		printResult(component, success)
	end

	local allPassed = results.view and results.sound and results.animation and results.controller and results.types -- Include type validation in overall result

	print("\n" .. string.rep("-", 50))
	printResult(
		"All Tests",
		allPassed,
		allPassed and "All components working correctly" or "Some components need attention"
	)

	return allPassed
end

-- Debug utilities
function M.debugState()
	printHeader("Current System State")

	-- Check component states
	print("\nController State:")
	for key, value in pairs(controller.State) do
		if type(value) ~= "userdata" then
			print(string.format("  %s: %s", key, tostring(value)))
		end
	end

	print("\nSound State:")
	print(string.format("  Silent Mode: %s", tostring(sound.silentMode)))
	print(string.format("  Active Sound: %s", sound.activeSound and "Yes" or "No"))

	print("\nWindow Info:")
	if controller.State.activeWebview then
		local frame = controller.State.activeWebview:frame()
		print(string.format("  Position: x=%d, y=%d", frame.x, frame.y))
		print(string.format("  Size: w=%d, h=%d", frame.w, frame.h))
	else
		print("  No active window")
	end
end

return M
