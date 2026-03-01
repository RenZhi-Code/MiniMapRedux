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
local pvpData = {
    brackets = {},
    highestRating = 0,
    highestBracket = "",
    honorLevel = 0,
}

local BRACKET_NAMES = {
    [1] = "2v2",
    [2] = "3v3",
    [3] = "10v10",
    [4] = "Solo Shuffle",
}

local function GetRatingColor(rating)
    if rating >= 2400 then return 1, 0.5, 0 end      -- Orange (Gladiator)
    if rating >= 2100 then return 0.6, 0.2, 1 end     -- Purple (Duelist)
    if rating >= 1800 then return 0, 0.4, 1 end        -- Blue (Rival)
    if rating >= 1400 then return 0, 0.8, 0 end        -- Green (Challenger)
    if rating > 0 then return 1, 1, 1 end               -- White (Combatant)
    return 0.5, 0.5, 0.5                                 -- Gray
end

local function RefreshPvPData()
    pvpData.brackets = {}
    pvpData.highestRating = 0
    pvpData.highestBracket = ""

    local success = pcall(function()
        pvpData.honorLevel = UnitHonorLevel("player") or 0

        for bracketID = 1, 4 do
            local rating, seasonBest, weeklyBest, seasonPlayed, seasonWon, weeklyPlayed, weeklyWon = GetPersonalRatedInfo(bracketID)
            if rating then
                local bracketName = BRACKET_NAMES[bracketID] or ("Bracket " .. bracketID)
                pvpData.brackets[bracketID] = {
                    name = bracketName,
                    rating = rating or 0,
                    seasonBest = seasonBest or 0,
                    seasonPlayed = seasonPlayed or 0,
                    seasonWon = seasonWon or 0,
                    weeklyPlayed = weeklyPlayed or 0,
                    weeklyWon = weeklyWon or 0,
                }

                if rating and rating > pvpData.highestRating then
                    pvpData.highestRating = rating
                    pvpData.highestBracket = bracketName
                end
            end
        end
    end)
end

-- Events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PVP_RATED_STATS_UPDATE")
eventFrame:RegisterEvent("HONOR_LEVEL_UPDATE")
eventFrame:SetScript("OnEvent", function()
    RefreshPvPData()
end)

C_Timer.After(3, RefreshPvPData)

local pvpDataText = {
    name = "PvP Rating",
    color = {1, 0.3, 0.3},
    icon = "Interface\\Icons\\Achievement_PVP_A_01",
    update = function(frame)
        if not GetDataTexts() then return end

        if pvpData.highestRating > 0 then
            local r, g, b = GetRatingColor(pvpData.highestRating)
            frame.text:SetText(string.format("PvP: %d %s", pvpData.highestRating, pvpData.highestBracket))
            frame.text:SetTextColor(r, g, b)
        else
            frame.text:SetText(string.format("Honor: %d", pvpData.honorLevel))
            frame.text:SetTextColor(0.8, 0.5, 0.5)
        end
    end,
    tooltip = function()
        if not GetDataTexts() then return end

        GameTooltip:SetText("PvP Information")
        GameTooltip:AddLine(string.format("Honor Level: %d", pvpData.honorLevel), 1, 0.8, 0.3)

        local hasBrackets = false
        for bracketID = 1, 4 do
            local bracket = pvpData.brackets[bracketID]
            if bracket and bracket.rating > 0 then
                if not hasBrackets then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine("Rated Brackets:", 0.8, 0.8, 0.8)
                    hasBrackets = true
                end

                local r, g, b = GetRatingColor(bracket.rating)
                GameTooltip:AddLine(string.format("  %s: %d", bracket.name, bracket.rating), r, g, b)

                if bracket.seasonBest > bracket.rating then
                    GameTooltip:AddLine(string.format("    Season Best: %d", bracket.seasonBest), 0.6, 0.6, 0.6)
                end

                local winRate = bracket.seasonPlayed > 0 and (bracket.seasonWon / bracket.seasonPlayed * 100) or 0
                GameTooltip:AddLine(string.format("    Season: %dW/%dL (%.0f%%)", bracket.seasonWon, bracket.seasonPlayed - bracket.seasonWon, winRate), 0.6, 0.6, 0.6)
            end
        end

        if not hasBrackets then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("No rated games played this season", 0.5, 0.5, 0.5)
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click to open PvP panel", 0.8, 0.8, 0.8)
    end,
    onClick = function()
        PVEFrame_ToggleFrame("PVPUIFrame", HonorFrame)
    end
}

local function RegisterDataText()
    local DataTexts = GetDataTexts()
    if DataTexts then
        DataTexts:RegisterDataText("pvprating", pvpDataText)
        if MiniMapRedux and MiniMapRedux.export then
            MiniMapRedux.export("PvPRatingDataText", {})
        end
    else
        C_Timer.After(0.1, RegisterDataText)
    end
end

RegisterDataText()
