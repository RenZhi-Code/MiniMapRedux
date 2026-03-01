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
local keystoneData = {
    hasKeystone = false,
    level = 0,
    mapID = 0,
    mapName = "",
    affixes = {},
    weeklyBest = 0,
    rating = 0,
}

-- Difficulty color thresholds
local function GetKeystoneColor(level)
    if level >= 12 then return 1, 0.5, 0 end      -- Orange (very high)
    if level >= 10 then return 0.6, 0.2, 1 end     -- Purple (high)
    if level >= 7 then return 0, 0.4, 1 end         -- Blue
    if level >= 4 then return 0, 0.8, 0 end         -- Green
    return 0.8, 0.8, 0.8                             -- Gray
end

local function RefreshKeystoneData()
    local success = pcall(function()
        -- Current keystone
        local mapID = C_MythicPlus.GetOwnedKeystoneMapID()
        if mapID then
            keystoneData.hasKeystone = true
            keystoneData.mapID = mapID
            keystoneData.level = C_MythicPlus.GetOwnedKeystoneLevel() or 0
            local name = C_ChallengeMode.GetMapUIInfo(mapID)
            keystoneData.mapName = name or "Unknown"
        else
            keystoneData.hasKeystone = false
            keystoneData.level = 0
            keystoneData.mapID = 0
            keystoneData.mapName = ""
        end

        -- Weekly best
        local weeklyBest = 0
        local mapTable = C_ChallengeMode.GetMapTable()
        if mapTable then
            for _, id in ipairs(mapTable) do
                local _, weekLevel = C_MythicPlus.GetWeeklyBestForMap(id)
                if weekLevel and weekLevel > weeklyBest then
                    weeklyBest = weekLevel
                end
            end
        end
        keystoneData.weeklyBest = weeklyBest

        -- Overall rating
        local ratingSummary = C_ChallengeMode.GetOverallDungeonScore and C_ChallengeMode.GetOverallDungeonScore()
        if ratingSummary then
            keystoneData.rating = ratingSummary.currentSeasonScore or ratingSummary or 0
            if type(keystoneData.rating) ~= "number" then
                keystoneData.rating = 0
            end
        end

        -- Affixes
        keystoneData.affixes = {}
        local affixIDs = C_MythicPlus.GetCurrentAffixes and C_MythicPlus.GetCurrentAffixes()
        if affixIDs then
            for _, affixInfo in ipairs(affixIDs) do
                local name, desc = C_ChallengeMode.GetAffixInfo(affixInfo.id)
                if name then
                    table.insert(keystoneData.affixes, { name = name, desc = desc })
                end
            end
        end
    end)

    if not success then
        keystoneData.hasKeystone = false
    end
end

-- Events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("CHALLENGE_MODE_MAPS_UPDATE")
eventFrame:RegisterEvent("CHALLENGE_MODE_MEMBER_INFO_UPDATED")
eventFrame:RegisterEvent("MYTHIC_PLUS_NEW_WEEKLY_RECORD")
eventFrame:RegisterEvent("BAG_UPDATE")
eventFrame:SetScript("OnEvent", function()
    RefreshKeystoneData()
end)

C_Timer.After(2, function()
    C_MythicPlus.RequestMapInfo()
    C_MythicPlus.RequestCurrentAffixes()
    RefreshKeystoneData()
end)

local keystoneDataText = {
    name = "Keystone",
    color = {0.6, 0.2, 1},
    icon = "Interface\\Icons\\INV_Relics_Hourglass",
    update = function(frame)
        if not GetDataTexts() then return end

        if keystoneData.hasKeystone then
            local r, g, b = GetKeystoneColor(keystoneData.level)
            local displayText = string.format("+%d %s", keystoneData.level, keystoneData.mapName)

            -- Append M+ rating if available
            if keystoneData.rating and keystoneData.rating > 0 then
                displayText = displayText .. string.format(" |cffffd700(%d)|r", keystoneData.rating)
            end

            frame.text:SetText(displayText)
            frame.text:SetTextColor(r, g, b)
        else
            -- Still show rating even without a key
            if keystoneData.rating and keystoneData.rating > 0 then
                frame.text:SetText(string.format("No Key |cffffd700(%d)|r", keystoneData.rating))
                frame.text:SetTextColor(0.5, 0.5, 0.5)
            else
                frame.text:SetText("No Key")
                frame.text:SetTextColor(0.5, 0.5, 0.5)
            end
        end
    end,
    tooltip = function()
        if not GetDataTexts() then return end

        GameTooltip:SetText("Mythic+ Keystone")

        if keystoneData.hasKeystone then
            local r, g, b = GetKeystoneColor(keystoneData.level)
            GameTooltip:AddLine(string.format("+%d %s", keystoneData.level, keystoneData.mapName), r, g, b)
        else
            GameTooltip:AddLine("No keystone in bags", 0.5, 0.5, 0.5)
        end

        if keystoneData.weeklyBest > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(string.format("Weekly Best: +%d", keystoneData.weeklyBest), 0.3, 1, 0.3)
        end

        if keystoneData.rating and keystoneData.rating > 0 then
            GameTooltip:AddLine(string.format("M+ Rating: %d", keystoneData.rating), 1, 0.8, 0.3)
        end

        if #keystoneData.affixes > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("This Week's Affixes:", 0.8, 0.8, 0.8)
            for _, affix in ipairs(keystoneData.affixes) do
                GameTooltip:AddLine("  " .. affix.name, 1, 1, 1)
            end
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click to open Group Finder", 0.8, 0.8, 0.8)
    end,
    onClick = function()
        PVEFrame_ToggleFrame("GroupFinderFrame", LFDParentFrame)
    end
}

local function RegisterDataText()
    local DataTexts = GetDataTexts()
    if DataTexts then
        DataTexts:RegisterDataText("keystone", keystoneDataText)
        if MiniMapRedux and MiniMapRedux.export then
            MiniMapRedux.export("KeystoneDataText", {})
        end
    else
        C_Timer.After(0.1, RegisterDataText)
    end
end

RegisterDataText()
