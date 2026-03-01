local addonName, _ = ...
local MiniMapRedux = _G.MiniMapRedux

-- Clock Data Text Module
local DataTexts
local function GetDataTexts()
    if not DataTexts and MiniMapRedux and MiniMapRedux.import then
        DataTexts = MiniMapRedux.import("DataTexts")
    end
    return DataTexts
end

local Options
local function GetOptions()
    if not Options and MiniMapRedux and MiniMapRedux.import then
        Options = MiniMapRedux.import("Options")
    end
    return Options
end

-- Local storage for clock data
local clockData = {
    hour = 0,
    minute = 0,
    hour24 = 0, -- always store 24hr for color logic
}

-- Format hour for 12hr display
local function FormatHour12(hour24)
    local hour12 = hour24 % 12
    if hour12 == 0 then hour12 = 12 end
    local ampm = hour24 >= 12 and "PM" or "AM"
    return hour12, ampm
end

-- Function to refresh clock data with error handling
local function RefreshClockData()
    local DataTexts = GetDataTexts()
    if not DataTexts then return end

    local success, errorMessage = pcall(function()
        clockData.hour24 = tonumber(date("%H")) or 0
        clockData.hour = clockData.hour24
        clockData.minute = tonumber(date("%M")) or 0
    end)

    if not success then
        clockData.hour24 = tonumber(date("%H")) or 0
        clockData.hour = clockData.hour24
        clockData.minute = tonumber(date("%M")) or 0
    end
end

-- Event frame for clock updates
local clockEventFrame = CreateFrame("Frame")
clockEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
clockEventFrame:RegisterEvent("CALENDAR_UPDATE_PENDING_INVITES")
clockEventFrame:SetScript("OnEvent", function(self, event, ...)
    RefreshClockData()
end)

-- Initialize clock data
RefreshClockData()

local clockDataText = {
    name = "Clock",
    color = {1, 1, 0.8}, -- Light yellow
    icon = "Interface\\Icons\\INV_Misc_PocketWatch_01",
    update = function(frame)
        local DataTexts = GetDataTexts()
        if not DataTexts then return end

        -- Refresh time data each update
        RefreshClockData()

        -- Check user preference for clock format
        local opts = GetOptions()
        local use24hr = true
        if opts then
            local fmt = opts:get("clockFormat")
            if fmt == "12hr" then
                use24hr = false
            end
        end

        local timeString
        if use24hr then
            timeString = string.format("%02d:%02d", clockData.hour24, clockData.minute)
        else
            local h12, ampm = FormatHour12(clockData.hour24)
            timeString = string.format("%d:%02d %s", h12, clockData.minute, ampm)
        end

        frame.text:SetText("Local: " .. timeString)

        -- Color based on time of day (always use 24hr value for logic)
        local hourColor = {1, 1, 1}
        if clockData.hour24 >= 6 and clockData.hour24 < 12 then
            hourColor = {1, 0.8, 0.3} -- Morning (yellow)
        elseif clockData.hour24 >= 12 and clockData.hour24 < 18 then
            hourColor = {0.3, 1, 0.3} -- Afternoon (green)
        elseif clockData.hour24 >= 18 and clockData.hour24 < 22 then
            hourColor = {1, 0.5, 0.3} -- Evening (orange)
        else
            hourColor = {0.5, 0.5, 1} -- Night (blue)
        end

        frame.text:SetTextColor(hourColor[1], hourColor[2], hourColor[3])
    end,
    tooltip = function()
        local DataTexts = GetDataTexts()
        if not DataTexts then return end

        GameTooltip:SetText("Local Time")

        local opts = GetOptions()
        local use24hr = true
        if opts then
            local fmt = opts:get("clockFormat")
            if fmt == "12hr" then
                use24hr = false
            end
        end

        -- Show local time in both formats in tooltip
        local time24 = string.format("%02d:%02d", clockData.hour24, clockData.minute)
        local h12, ampm = FormatHour12(clockData.hour24)
        local time12 = string.format("%d:%02d %s", h12, clockData.minute, ampm)

        if use24hr then
            GameTooltip:AddLine("Current Local Time: " .. time24, 1, 1, 1)
            GameTooltip:AddLine("12-hour format: " .. time12, 0.7, 0.7, 0.7)
        else
            GameTooltip:AddLine("Current Local Time: " .. time12, 1, 1, 1)
            GameTooltip:AddLine("24-hour format: " .. time24, 0.7, 0.7, 0.7)
        end

        -- Show local date
        local dateStr = date("%A, %B %d, %Y")
        if dateStr then
            GameTooltip:AddLine("Date: " .. dateStr, 0.8, 0.8, 0.8)
        end

        -- Show timezone offset
        local utcTime = date("!*t")
        local localTime = date("*t")
        if utcTime and localTime then
            local utcHour = utcTime.hour
            local localHour = localTime.hour
            local offset = localHour - utcHour
            -- Handle day boundary
            if offset > 12 then offset = offset - 24 end
            if offset < -12 then offset = offset + 24 end
            local sign = offset >= 0 and "+" or ""
            GameTooltip:AddLine("UTC Offset: " .. sign .. offset .. " hours", 0.7, 0.7, 0.7)
        end

        -- Add time of day description
        local timeDesc = "Night"
        if clockData.hour24 >= 6 and clockData.hour24 < 12 then
            timeDesc = "Morning"
        elseif clockData.hour24 >= 12 and clockData.hour24 < 18 then
            timeDesc = "Afternoon"
        elseif clockData.hour24 >= 18 and clockData.hour24 < 22 then
            timeDesc = "Evening"
        end

        GameTooltip:AddLine("Time of Day: " .. timeDesc, 0.8, 0.8, 0.8)

        -- Add game time if available
        local success, hour, minute = pcall(GetGameTime)
        if success and hour and minute then
            local gameTime
            if use24hr then
                gameTime = string.format("%02d:%02d", hour, minute)
            else
                local gh12, gampm = FormatHour12(hour)
                gameTime = string.format("%d:%02d %s", gh12, minute, gampm)
            end
            GameTooltip:AddLine("Server Time: " .. gameTime, 1, 1, 1)
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click to toggle time manager", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Use /mmr config to change clock format", 0.6, 0.6, 0.6)
    end,
    onClick = function()
        -- Toggle time manager with error handling
        local success, errorMessage = pcall(function()
            if TimeManagerFrame then
                if TimeManagerFrame:IsShown() then
                    TimeManagerFrame:Hide()
                else
                    TimeManagerFrame:Show()
                end
            else
                -- Fallback to opening calendar
                if CalendarFrame then
                    if CalendarFrame:IsShown() then
                        CalendarFrame:Hide()
                    else
                        CalendarFrame:Show()
                    end
                end
            end
        end)

        if not success then
            print("Failed to toggle time manager: " .. tostring(errorMessage))
        end
    end
}

-- Register the clock data text - defer until DataTexts is available
local function RegisterDataText()
    local DataTexts = GetDataTexts()
    if DataTexts then
        DataTexts:RegisterDataText("clock", clockDataText)
        -- Export an empty module (registration is enough)
        if MiniMapRedux and MiniMapRedux.export then
            MiniMapRedux.export("ClockDataText", {})
        end
    else
        -- Try again after a short delay
        C_Timer.After(0.1, RegisterDataText)
    end
end

-- Call register function
RegisterDataText()
