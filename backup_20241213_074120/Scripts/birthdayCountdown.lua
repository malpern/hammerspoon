-- Create a new menu bar item
local birthdayMenuItem = hs.menubar.new()
birthdayMenuItem:setTitle('🎂')

-- Function to update the countdown every second
local function updateCountdown()
    local currentDate = os.date('*t')
    local currentYear = currentDate.year
    if (currentDate.month > 7) or (currentDate.month == 7 and currentDate.day > 26) then
        currentYear = currentYear + 1
    end
    local birthday = os.time({year = currentYear, month = 7, day = 26})
    local daysUntilBirthday = math.ceil(os.difftime(birthday, os.time()) / (24 * 60 * 60))
    birthdayMenuItem:setTitle('🎂 ' .. daysUntilBirthday .. ' days')
end

-- Update the countdown every second
hs.timer.doEvery(1, updateCountdown)

return updateCountdown