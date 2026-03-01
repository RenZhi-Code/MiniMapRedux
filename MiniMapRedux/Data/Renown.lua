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
local renownData = {
    factions = {},
    totalMaxed = 0,
    lowestFaction = nil,
}

-- Known renown faction IDs (TWW / Midnight - update as needed)
local RENOWN_FACTIONS = {
    -- The War Within
    2590, -- Council of Dornogal
    2570, -- Hallowfall Arathi
    2600, -- Severed Threads
    2605, -- Assembly of the Deeps
    -- Add Midnight factions here as they release
}

local function RefreshRenownData()
    renownData.factions = {}
    renownData.totalMaxed = 0
    renownData.lowestFaction = nil

    local success = pcall(function()
        if not C_MajorFactions or not C_MajorFactions.GetMajorFactionData then return end

        for _, factionID in ipairs(RENOWN_FACTIONS) do
            local data = C_MajorFactions.GetMajorFactionData(factionID)
            if data then
                local isMaxed = data.renownLevel >= (data.renownLevelThreshold or 999)
                local entry = {
                    id = factionID,
                    name = data.name or "Unknown",
                    level = data.renownLevel or 0,
                    maxLevel = data.renownLevelThreshold or 0,
                    isMaxed = isMaxed,
                }

                table.insert(renownData.factions, entry)

                if isMaxed then
                    renownData.totalMaxed = renownData.totalMaxed + 1
                end

                if not renownData.lowestFaction or entry.level < renownData.lowestFaction.level then
                    renownData.lowestFaction = entry
                end
            end
        end
    end)
end

-- Events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("MAJOR_FACTION_RENOWN_LEVEL_CHANGED")
eventFrame:RegisterEvent("MAJOR_FACTION_UNLOCKED")
eventFrame:RegisterEvent("UPDATE_FACTION")
eventFrame:SetScript("OnEvent", function()
    RefreshRenownData()
end)

C_Timer.After(3, RefreshRenownData)

local renownDataText = {
    name = "Renown",
    color = {0.3, 0.8, 1},
    icon = "Interface\\Icons\\Achievement_Reputation_01",
    update = function(frame)
        if not GetDataTexts() then return end

        if not C_MajorFactions then
            frame.text:SetText("|cff888888Renown N/A|r")
            return
        end

        if #renownData.factions == 0 then
            frame.text:SetText("Renown: --")
            frame.text:SetTextColor(0.5, 0.5, 0.5)
            return
        end

        local allMaxed = renownData.totalMaxed == #renownData.factions
        if allMaxed then
            frame.text:SetText("Renown: All Maxed")
            frame.text:SetTextColor(0.3, 1, 0.3)
        elseif renownData.lowestFaction then
            frame.text:SetText(string.format("%s: %d", renownData.lowestFaction.name, renownData.lowestFaction.level))
            frame.text:SetTextColor(0.3, 0.8, 1)
        end
    end,
    tooltip = function()
        if not GetDataTexts() then return end

        GameTooltip:SetText("Renown Progress")

        if not C_MajorFactions then
            GameTooltip:AddLine("Renown system not available", 0.5, 0.5, 0.5)
            return
        end

        if #renownData.factions == 0 then
            GameTooltip:AddLine("No renown factions found", 0.5, 0.5, 0.5)
            return
        end

        GameTooltip:AddLine(string.format("Maxed: %d/%d", renownData.totalMaxed, #renownData.factions), 0.8, 0.8, 0.8)

        GameTooltip:AddLine(" ")
        for _, faction in ipairs(renownData.factions) do
            local color
            if faction.isMaxed then
                color = {0.3, 1, 0.3}
            else
                color = {1, 1, 1}
            end

            local maxStr = faction.maxLevel > 0 and ("/" .. faction.maxLevel) or ""
            GameTooltip:AddLine(string.format("  %s: %d%s%s", faction.name, faction.level, maxStr, faction.isMaxed and " (Max)" or ""), color[1], color[2], color[3])
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click to open Reputation panel", 0.8, 0.8, 0.8)
    end,
    onClick = function()
        ToggleCharacter("ReputationFrame")
    end
}

local function RegisterDataText()
    local DataTexts = GetDataTexts()
    if DataTexts then
        DataTexts:RegisterDataText("renown", renownDataText)
        if MiniMapRedux and MiniMapRedux.export then
            MiniMapRedux.export("RenownDataText", {})
        end
    else
        C_Timer.After(0.1, RegisterDataText)
    end
end

RegisterDataText()
