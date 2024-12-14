--[[
    Installation script for Arrows system test environment
    
    This script:
    1. Backs up existing Hammerspoon configuration
    2. Installs test configuration
    3. Creates required directories and files
    4. Provides cleanup instructions
]]

local M = {}

-- Utility functions
local function printStep(text)
	print("\n" .. string.rep("-", 40))
	print(text)
	print(string.rep("-", 40))
end

local function runCommand(cmd)
	local handle = io.popen(cmd)
	local result = handle:read("*a")
	handle:close()
	return result
end

-- Installation steps
function M.backup()
	printStep("Backing up existing configuration")

	local timestamp = os.date("%Y%m%d_%H%M%S")
	local backupDir = os.getenv("HOME") .. "/.hammerspoon/backup_" .. timestamp

	-- Create backup directory
	runCommand(string.format("mkdir -p %s", backupDir))

	-- Backup existing configuration
	runCommand(string.format("cp -r %s/.hammerspoon/* %s/ 2>/dev/null || true", os.getenv("HOME"), backupDir))

	print("✅ Configuration backed up to: " .. backupDir)
	return backupDir
end

function M.createDirectories()
	printStep("Creating required directories")

	-- Create sound directories
	runCommand("mkdir -p ~/.hammerspoon/sounds/dissonant")

	-- Create placeholder sound files
	local soundFiles = {
		"up.wav",
		"down.wav",
		"left.wav",
		"right.wav",
		"up_deeper.wav",
		"dissonant/up.wav",
		"dissonant/down.wav",
		"dissonant/left.wav",
		"dissonant/right.wav",
	}

	for _, file in ipairs(soundFiles) do
		local path = string.format("~/.hammerspoon/sounds/%s", file)
		runCommand(string.format("touch %s", path))
	end

	print("✅ Directories and placeholder files created")
end

function M.installTestConfig()
	printStep("Installing test configuration")

	-- Copy test configuration
	runCommand("cp test_init.lua ~/.hammerspoon/init.lua")

	print("✅ Test configuration installed")
end

function M.install()
	printStep("Starting test environment installation")

	-- Perform installation steps
	local backupDir = M.backup()
	M.createDirectories()
	M.installTestConfig()

	-- Print completion message
	print([[

Installation Complete!
=====================

The test environment has been set up successfully:
- Your original configuration is backed up to: ]] .. backupDir .. [[

- Test configuration is installed
- Placeholder sound files are created

Next Steps:
1. Reload Hammerspoon configuration
2. Check the Hammerspoon console for test results
3. Follow the manual test instructions

To restore your original configuration:
1. Copy back your files from the backup directory
2. Reload Hammerspoon

To clean up test files:
1. Delete placeholder sound files:
   rm -rf ~/.hammerspoon/sounds/*
2. Remove test configuration:
   rm ~/.hammerspoon/init.lua

For more information, see Scripts/arrows/README.md
]])
end

-- Run installation if script is run directly
if not pcall(debug.getlocal, 4, 1) then
	M.install()
end

return M
