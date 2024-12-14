--[[
    Verification script for the Arrows system
    
    This script performs a complete system verification including:
    - Configuration validation
    - Component initialization
    - Integration testing
    - Manual test instructions
]]

local arrows = require("arrows")
local test = require("arrows.test")

-- Print utilities
local function printHeader(text)
	print("\n" .. string.rep("=", 70))
	print(text)
	print(string.rep("=", 70))
end

local function printStep(number, text)
	print(string.format("\n%d. %s", number, text))
end

local function printResult(success, message)
	print(string.format("%s %s", success and "✅" or "❌", message))
end

-- Verification steps
local function verifyConfiguration()
	printStep(1, "Verifying Configuration")

	-- Initialize with strict mode to catch all issues
	local success, error = arrows.init({ strict = true })
	if not success then
		printResult(false, "Configuration verification failed:")
		print(error)
		return false
	end

	printResult(true, "Configuration verified successfully")
	return true
end

local function runTests()
	printStep(2, "Running Integration Tests")

	local success = arrows.test()
	if not success then
		printResult(false, "Integration tests failed")
		return false
	end

	printResult(true, "All tests passed successfully")
	return true
end

local function checkState()
	printStep(3, "Checking System State")

	arrows.debug()
	return true
end

local function printManualTests()
	printStep(4, "Manual Test Instructions")
	print([[
Please verify the following functionality manually:

1. Basic Navigation:
   □ Press arrow keys - should show red indicators
   □ Press Hyper + hjkl - should show gray indicators
   □ Verify sound effects play for both

2. Sound Toggle:
   □ Double-press Escape - should toggle sound effects
   □ Verify alert message appears
   □ Double-press again - should re-enable sounds

3. Window Interaction:
   □ Click and drag indicator window
   □ Verify window stays in new position
   □ Restart Hammerspoon
   □ Verify window appears in last position

4. Celebration:
   □ Press an arrow key
   □ Quickly press corresponding vim key
   □ Verify celebration animation plays
   □ Verify success message appears

5. Visual Feedback:
   □ Verify smooth fade animations
   □ Check dark mode compatibility
   □ Test high contrast mode if available

Report any issues on GitHub or contact the maintainer.
]])
end

-- Main verification
local function main()
	printHeader("Starting Arrows System Verification")

	local configOk = verifyConfiguration()
	if not configOk then
		print("\n❌ Verification failed at configuration step")
		return false
	end

	local testsOk = runTests()
	if not testsOk then
		print("\n❌ Verification failed at testing step")
		return false
	end

	local stateOk = checkState()
	if not stateOk then
		print("\n❌ Verification failed at state check")
		return false
	end

	printManualTests()

	printHeader("Verification Complete")
	print([[
✅ Automatic verification steps completed successfully
⚠️ Please complete the manual verification steps above
📝 Report any issues or unexpected behavior

Thank you for verifying the Arrows system!
]])

	return true
end

-- Run verification
main()
