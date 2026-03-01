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
local questData = {
    numQuests = 0,
    maxQuests = 35,
    numTracked = 0,
}

local function RefreshQuestData()
    local success = pcall(function()
        questData.numQuests = C_QuestLog.GetNumQuestLogEntries and select(1, C_QuestLog.GetNumQuestLogEntries()) or 0
        questData.maxQuests = C_QuestLog.GetMaxNumQuestsCanAccept and C_QuestLog.GetMaxNumQuestsCanAccept() or 35
        questData.numTracked = C_QuestLog.GetNumQuestWatches and C_QuestLog.GetNumQuestWatches() or 0
    end)

    if not success then
        questData.numQuests = 0
        questData.numTracked = 0
    end
end

-- Events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
eventFrame:RegisterEvent("QUEST_ACCEPTED")
eventFrame:RegisterEvent("QUEST_REMOVED")
eventFrame:RegisterEvent("QUEST_WATCH_LIST_CHANGED")
eventFrame:SetScript("OnEvent", function()
    RefreshQuestData()
end)

RefreshQuestData()

local questDataText = {
    name = "Quests",
    color = {1, 0.8, 0.3},
    icon = "Interface\\Icons\\INV_Misc_Book_09",
    update = function(frame)
        if not GetDataTexts() then return end

        frame.text:SetText(string.format("Quests: %d/%d", questData.numQuests, questData.maxQuests))

        local pct = questData.maxQuests > 0 and (questData.numQuests / questData.maxQuests) or 0
        if pct > 0.9 then
            frame.text:SetTextColor(1, 0.2, 0.2) -- Red: nearly full
        elseif pct > 0.7 then
            frame.text:SetTextColor(1, 0.8, 0.3) -- Yellow
        else
            frame.text:SetTextColor(0.3, 1, 0.3) -- Green
        end
    end,
    tooltip = function()
        if not GetDataTexts() then return end

        GameTooltip:SetText("Quest Log")
        GameTooltip:AddLine(string.format("Quests: %d / %d", questData.numQuests, questData.maxQuests), 1, 1, 1)
        GameTooltip:AddLine(string.format("Tracked: %d", questData.numTracked), 0.8, 0.8, 0.8)

        -- List tracked quests
        if questData.numTracked > 0 and C_QuestLog.GetNumQuestWatches then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Tracked Quests:", 0.8, 0.8, 0.8)

            for i = 1, C_QuestLog.GetNumQuestWatches() do
                local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
                if questID then
                    local title = C_QuestLog.GetTitleForQuestID(questID)
                    if title then
                        local isComplete = C_QuestLog.IsComplete(questID)
                        if isComplete then
                            GameTooltip:AddLine("  " .. title .. " (Complete)", 0.3, 1, 0.3)
                        else
                            GameTooltip:AddLine("  " .. title, 1, 1, 1)
                        end
                    end
                end
            end
        end

        local remaining = questData.maxQuests - questData.numQuests
        if remaining <= 5 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(string.format("Warning: Only %d quest slots remaining!", remaining), 1, 0.3, 0.3)
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click to open Quest Log", 0.8, 0.8, 0.8)
    end,
    onClick = function()
        ToggleQuestLog()
    end
}

local function RegisterDataText()
    local DataTexts = GetDataTexts()
    if DataTexts then
        DataTexts:RegisterDataText("quests", questDataText)
        if MiniMapRedux and MiniMapRedux.export then
            MiniMapRedux.export("QuestsDataText", {})
        end
    else
        C_Timer.After(0.1, RegisterDataText)
    end
end

RegisterDataText()
