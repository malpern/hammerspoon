--[[
    Cleanup script for Arrows system test environment
    
    This script:
    1. Finds and lists available backups
    2. Removes test files
    3. Optionally restores a backup
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

-- Find available backups
function M.findBackups()
    printStep("Finding available backups")
    
    local backups = {}
    local result = runCommand("ls -1d ~/.hammerspoon/backup_* 2>/dev/null")
    
    for backup in result:gmatch("[^\n]+") do
        table.insert(backups, backup)
    end
    
    if #backups > 0 then
        print("Found backups:")
        for i, backup in ipairs(backups) do
            print(string.format("%d. %s", i, backup))
        end
    else
        print("No backups found")
    end
    
    return backups
end

-- Clean up test files
function M.cleanupFiles()
    printStep("Cleaning up test files")
    
    -- Remove sound files
    runCommand("rm -rf ~/.hammerspoon/sounds/*")
    print("✅ Sound files removed")
    
    -- Remove test configuration
    runCommand("rm -f ~/.hammerspoon/init.lua")
    print("✅ Test configuration removed")
end

-- Restore backup
function M.restoreBackup(backupPath)
    printStep("Restoring backup")
    
    if not backupPath then
        print("❌ No backup path provided")
        return false
    end
    
    -- Check if backup exists
    local exists = runCommand(string.format("test -d %s && echo yes || echo no", backupPath))
    if exists:match("no") then
        print("❌ Backup directory not found: " .. backupPath)
        return false
    end
    
    -- Restore files
    runCommand(string.format("cp -r %s/* ~/.hammerspoon/ 2>/dev/null || true", backupPath))
    print("✅ Backup restored from: " .. backupPath)
    
    return true
end

-- Main cleanup function
function M.cleanup(options)
    options = options or {}
    printStep("Starting cleanup")
    
    -- Find backups
    local backups = M.findBackups()
    
    -- Clean up test files
    M.cleanupFiles()
    
    -- Restore backup if requested
    if options.restore then
        if #backups > 0 then
            local latestBackup = backups[#backups]
            if M.restoreBackup(latestBackup) then
                runCommand(string.format("rm -rf %s", latestBackup))
                print("✅ Backup directory removed: " .. latestBackup)
            end
        else
            print("⚠️ No backups available to restore")
        end
    end
    
    -- Print completion message
    print([[

Cleanup Complete!
================

Test environment has been cleaned up:
- Test files removed
- Sound files removed]] ..
(options.restore and [[

Your original configuration has been restored.
Please reload Hammerspoon to apply the changes.]] or [[

To restore your configuration:
1. Choose a backup from the list above
2. Run this script with restore option:
   hs.execute('hs ~/.hammerspoon/Scripts/arrows/cleanup_test.lua --restore')]]) .. [[

For more information, see Scripts/arrows/README.md
]])
end

-- Parse command line arguments
if not pcall(debug.getlocal, 4, 1) then
    local restore = false
    for _, arg in ipairs(arg) do
        if arg == "--restore" then
            restore = true
            break
        end
    end
    M.cleanup({ restore = restore })
end

return M 