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
local playedData = {
    totalPlayed = 0,
    levelPlayed = 0,
    received = false,
}

-- Suppress chat output from /played
local chatFilter
local waitingForData = false

local function RequestPlayedTime()
    waitingForData = true

    -- Temporarily filter the chat output
    if not chatFilter then
        chatFilter = function(self, event, msg, ...)
            if waitingForData then
                return true -- suppress
            end
        end
        ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", chatFilter)
    end

    RequestTimePlayed()
end

-- Events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("TIME_PLAYED_MSG")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "TIME_PLAYED_MSG" then
        local totalTime, levelTime = ...
        playedData.totalPlayed = totalTime or 0
        playedData.levelPlayed = levelTime or 0
        playedData.received = true
        waitingForData = false
    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(5, RequestPlayedTime)
    end
end)

local function FormatPlayedTime(seconds)
    if not seconds or seconds == 0 then return "0m" end
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local mins = math.floor((seconds % 3600) / 60)

    if days > 0 then
        return string.format("%dd %dh", days, hours)
    elseif hours > 0 then
        return string.format("%dh %dm", hours, mins)
    else
        return string.format("%dm", mins)
    end
end

local playedDataText = {
    name = "Played",
    color = {0.8, 0.6, 1},
    icon = "Interface\\Icons\\Spell_Holy_BorrowedTime",
    update = function(frame)
        if not GetDataTexts() then return end

        if playedData.received then
            frame.text:SetText("Played: " .. FormatPlayedTime(playedData.totalPlayed))
            frame.text:SetTextColor(0.8, 0.6, 1)
        else
            frame.text:SetText("Played: --")
            frame.text:SetTextColor(0.5, 0.5, 0.5)
        end
    end,
    tooltip = function()
        if not GetDataTexts() then return end

        GameTooltip:SetText("Time Played")

        if not playedData.received then
            GameTooltip:AddLine("Waiting for data...", 0.5, 0.5, 0.5)
            RequestPlayedTime()
            return
        end

        -- Total played
        local totalDays = math.floor(playedData.totalPlayed / 86400)
        local totalHours = math.floor((playedData.totalPlayed % 86400) / 3600)
        local totalMins = math.floor((playedData.totalPlayed % 3600) / 60)
        GameTooltip:AddLine(string.format("Total: %d days, %d hours, %d minutes", totalDays, totalHours, totalMins), 1, 1, 1)

        -- Level played
        local levelDays = math.floor(playedData.levelPlayed / 86400)
        local levelHours = math.floor((playedData.levelPlayed % 86400) / 3600)
        local levelMins = math.floor((playedData.levelPlayed % 3600) / 60)
        GameTooltip:AddLine(string.format("This Level: %d days, %d hours, %d minutes", levelDays, levelHours, levelMins), 0.8, 0.8, 0.8)

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click to refresh", 0.8, 0.8, 0.8)
    end,
    onClick = function()
        RequestPlayedTime()
    end
}

local function RegisterDataText()
    local DataTexts = GetDataTexts()
    if DataTexts then
        DataTexts:RegisterDataText("played", playedDataText)
        if MiniMapRedux and MiniMapRedux.export then
            MiniMapRedux.export("PlayedDataText", {})
        end
    else
        C_Timer.After(0.1, RegisterDataText)
    end
end

RegisterDataText()
