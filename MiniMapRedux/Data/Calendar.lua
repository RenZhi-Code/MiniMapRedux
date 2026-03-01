local addonName, _ = ...
local MiniMapRedux = _G.MiniMapRedux

local DataTexts
local function GetDataTexts()
    if not DataTexts and MiniMapRedux and MiniMapRedux.import then
        DataTexts = MiniMapRedux.import("DataTexts")
    end
    return DataTexts
end

-- Local storage
local calendarData = {
    nextEvent = nil,
    todayEvents = {},
    numPending = 0,
}

local function RefreshCalendarData()
    calendarData.nextEvent = nil
    calendarData.todayEvents = {}
    calendarData.numPending = 0

    local success = pcall(function()
        local currentCalendarTime = C_DateAndTime.GetCurrentCalendarTime()
        if not currentCalendarTime then return end

        local month = currentCalendarTime.month
        local day = currentCalendarTime.monthDay
        local year = currentCalendarTime.year

        C_Calendar.SetAbsMonth(month, year)
        local numEvents = C_Calendar.GetNumDayEvents(0, day)

        for i = 1, numEvents do
            local event = C_Calendar.GetDayEvent(0, day, i)
            if event then
                local entry = {
                    title = event.title or "Unknown Event",
                    calendarType = event.calendarType,
                    sequenceType = event.sequenceType,
                    eventType = event.eventType,
                }

                table.insert(calendarData.todayEvents, entry)

                if event.calendarType == "PLAYER" or event.calendarType == "GUILD_EVENT" then
                    calendarData.numPending = calendarData.numPending + 1
                    if not calendarData.nextEvent then
                        calendarData.nextEvent = entry
                    end
                end
            end
        end

        -- Check pending invites
        local numInvites = C_Calendar.GetNumPendingInvites()
        if numInvites and numInvites > 0 then
            calendarData.numPending = calendarData.numPending + numInvites
        end
    end)
end

-- Events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("CALENDAR_UPDATE_EVENT_LIST")
eventFrame:RegisterEvent("CALENDAR_UPDATE_PENDING_INVITES")
eventFrame:RegisterEvent("CALENDAR_NEW_EVENT")
eventFrame:SetScript("OnEvent", function()
    RefreshCalendarData()
end)

C_Timer.After(5, RefreshCalendarData)

local calendarDataText = {
    name = "Calendar",
    color = {1, 0.8, 0.3},
    icon = "Interface\\Icons\\INV_Misc_PocketWatch_01",
    update = function(frame)
        if not GetDataTexts() then return end

        if calendarData.numPending > 0 then
            frame.text:SetText(string.format("Events: %d", calendarData.numPending))
            frame.text:SetTextColor(1, 0.8, 0)
        elseif #calendarData.todayEvents > 0 then
            frame.text:SetText(string.format("Today: %d events", #calendarData.todayEvents))
            frame.text:SetTextColor(0.8, 0.8, 0.8)
        else
            -- Show current date
            local dateStr = date("%b %d")
            frame.text:SetText(dateStr)
            frame.text:SetTextColor(0.6, 0.6, 0.6)
        end
    end,
    tooltip = function()
        if not GetDataTexts() then return end

        GameTooltip:SetText("Calendar")
        GameTooltip:AddLine(date("%A, %B %d, %Y"), 1, 1, 1)

        if calendarData.numPending > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(string.format("%d pending invitation(s)", calendarData.numPending), 1, 0.8, 0)
        end

        if #calendarData.todayEvents > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Today's Events:", 0.8, 0.8, 0.8)
            for _, event in ipairs(calendarData.todayEvents) do
                local color = {1, 1, 1}
                if event.calendarType == "HOLIDAY" then
                    color = {0.3, 0.8, 1}
                elseif event.calendarType == "PLAYER" then
                    color = {0.3, 1, 0.3}
                elseif event.calendarType == "GUILD_EVENT" then
                    color = {0.3, 1, 0.3}
                end
                GameTooltip:AddLine("  " .. event.title, color[1], color[2], color[3])
            end
        else
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("No events today", 0.5, 0.5, 0.5)
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click to open Calendar", 0.8, 0.8, 0.8)
    end,
    onClick = function()
        ToggleCalendar()
    end
}

local function RegisterDataText()
    local DataTexts = GetDataTexts()
    if DataTexts then
        DataTexts:RegisterDataText("calendar", calendarDataText)
        if MiniMapRedux and MiniMapRedux.export then
            MiniMapRedux.export("CalendarDataText", {})
        end
    else
        C_Timer.After(0.1, RegisterDataText)
    end
end

RegisterDataText()
