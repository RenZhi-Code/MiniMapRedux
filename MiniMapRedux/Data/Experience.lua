local addonName, _ = ...
local MiniMapRedux = _G.MiniMapRedux

-- Experience Data Text Module
local DataTexts
local function GetDataTexts()
    if not DataTexts and MiniMapRedux and MiniMapRedux.import then
        DataTexts = MiniMapRedux.import("DataTexts")
    end
    return DataTexts
end

-- Local storage for experience data
local experienceData = {
    playerLevel = 0,
    maxLevel = 0,
    currentXP = 0,
    maxXP = 0,
    renownLevel = 0,
    restedXP = 0
}

-- Function to refresh experience data with error handling
local function RefreshExperienceData()
    local DataTexts = GetDataTexts()
    if not DataTexts then return end
    
    local success, errorMessage = pcall(function()
        -- Get player level information
        local levelSuccess, playerLevel = pcall(UnitLevel, "player")
        if levelSuccess and playerLevel then
            experienceData.playerLevel = playerLevel
        else
            experienceData.playerLevel = 0
        end
        
        local maxLevelSuccess, maxLevel = pcall(GetMaxPlayerLevel)
        if maxLevelSuccess and maxLevel then
            experienceData.maxLevel = maxLevel
        else
            experienceData.maxLevel = 60 -- Default max level
        end
        
        -- Get XP information
        local currentXPSuccess, currentXP = pcall(UnitXP, "player")
        if currentXPSuccess and currentXP then
            experienceData.currentXP = currentXP
        else
            experienceData.currentXP = 0
        end
        
        local maxXPSuccess, maxXP = pcall(UnitXPMax, "player")
        if maxXPSuccess and maxXP then
            experienceData.maxXP = maxXP
        else
            experienceData.maxXP = 1 -- Avoid division by zero
        end
        
        -- Get renown level - only if player has a covenant
        experienceData.renownLevel = 0
        -- Check if player has a covenant first
        if C_Covenants and C_Covenants.GetActiveCovenantID then
            local covenantSuccess, covenantID = pcall(C_Covenants.GetActiveCovenantID)
            if covenantSuccess and covenantID and covenantID > 0 then
                -- Player has a covenant, now check for renown level
                if C_CovenantSanctumUI and C_CovenantSanctumUI.GetRenownLevel then
                    local renownSuccess, renownLevel = pcall(C_CovenantSanctumUI.GetRenownLevel)
                    if renownSuccess and renownLevel and type(renownLevel) == "number" then
                        experienceData.renownLevel = renownLevel
                    end
                end
            end
        end
        
        -- Get rested XP
        local restedXPSuccess, restedXP = pcall(GetXPExhaustion)
        if restedXPSuccess and restedXP then
            experienceData.restedXP = restedXP or 0
        else
            experienceData.restedXP = 0
        end
    end)
    
    if not success then
        print("Experience data refresh failed: " .. tostring(errorMessage))
        experienceData.playerLevel = 0
        experienceData.maxLevel = 60
        experienceData.currentXP = 0
        experienceData.maxXP = 1
        experienceData.renownLevel = 0
        experienceData.restedXP = 0
    end
end

-- Event frame for experience updates
local experienceEventFrame = CreateFrame("Frame")
experienceEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
experienceEventFrame:RegisterEvent("PLAYER_XP_UPDATE")
experienceEventFrame:RegisterEvent("PLAYER_LEVEL_UP")
-- Only register covenant event in Shadowlands+ (retail)
if C_Covenants and C_Covenants.GetActiveCovenantID then
    experienceEventFrame:RegisterEvent("COVENANT_SANCTUM_RENOWN_LEVEL_CHANGED")
end
experienceEventFrame:RegisterEvent("UPDATE_EXHAUSTION")
experienceEventFrame:SetScript("OnEvent", function(self, event, ...)
    RefreshExperienceData()
end)

-- Initialize experience data
RefreshExperienceData()

local experienceDataText = {
    name = "Experience",
    color = {0.3, 1, 0.3}, -- Green
    icon = "Interface\\Icons\\Spell_Nature_AbolishMagic", -- Experience icon
    update = function(frame)
        local DataTexts = GetDataTexts()
        if not DataTexts then return end
        
        if experienceData.playerLevel >= experienceData.maxLevel then
            -- Player is max level
            if experienceData.renownLevel > 0 then
                frame.text:SetText(string.format("Lv%d | Renown: %d", experienceData.playerLevel, experienceData.renownLevel))
            else
                frame.text:SetText(string.format("Lv%d Max", experienceData.playerLevel))
            end
            frame.text:SetTextColor(0.3, 1, 0.3) -- Green
        else
            -- Player is not max level, show XP with rested info
            local xpPercent = (experienceData.currentXP / experienceData.maxXP) * 100
            local displayText = string.format("Lv%d XP: %.0f%%", experienceData.playerLevel, xpPercent)

            if experienceData.restedXP > 0 then
                local restedPercent = (experienceData.restedXP / experienceData.maxXP) * 100
                displayText = displayText .. string.format(" |cff4499ffR: %.0f%%|r", restedPercent)
            end

            frame.text:SetText(displayText)
            frame.text:SetTextColor(0.3, 1, 0.3) -- Green
        end
    end,
    tooltip = function()
        local DataTexts = GetDataTexts()
        if not DataTexts then return end
        
        GameTooltip:SetText("Experience Information")
        
        if experienceData.playerLevel >= experienceData.maxLevel then
            -- Player is max level
            GameTooltip:AddLine(string.format("Level %d (Maximum)", experienceData.playerLevel), 1, 1, 1)
            
            -- Only show renown information if player has a covenant and renown level > 0
            if experienceData.renownLevel > 0 then
                GameTooltip:AddLine(string.format("Covenant Renown Level: %d", experienceData.renownLevel), 1, 1, 1)
            else
                -- Check if player has a covenant at all
                local hasCovenant = false
                if C_Covenants and C_Covenants.GetActiveCovenantID then
                    local covenantSuccess, covenantID = pcall(C_Covenants.GetActiveCovenantID)
                    if covenantSuccess and covenantID and covenantID > 0 then
                        hasCovenant = true
                    end
                end
                
                if hasCovenant then
                    GameTooltip:AddLine("No Renown Progress", 0.8, 0.8, 0.8)
                else
                    GameTooltip:AddLine("No Covenant Selected", 0.8, 0.8, 0.8)
                end
            end
            
            if experienceData.restedXP > 0 then
                GameTooltip:AddLine(string.format("Rested XP: %d", experienceData.restedXP), 0.5, 0.8, 1)
            end
        else
            -- Player is not max level
            local xpPercent = (experienceData.currentXP / experienceData.maxXP) * 100
            local xpToNext = experienceData.maxXP - experienceData.currentXP
            
            GameTooltip:AddLine(string.format("Level %d", experienceData.playerLevel), 1, 1, 1)
            GameTooltip:AddLine(string.format("XP: %d / %d (%.1f%%)", experienceData.currentXP, experienceData.maxXP, xpPercent), 1, 1, 1)
            GameTooltip:AddLine(string.format("Remaining: %d", xpToNext), 1, 1, 1)
            
            if experienceData.restedXP > 0 then
                local restedPercent = (experienceData.restedXP / experienceData.maxXP) * 100
                GameTooltip:AddLine(string.format("Rested XP: %d (%.0f%%)", experienceData.restedXP, restedPercent), 0.5, 0.8, 1)
                GameTooltip:AddLine("You gain 2x XP for this amount", 0.8, 0.8, 0.8)
            end
            
            -- Calculate XP needed for next level
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(string.format("XP for next level: %d", experienceData.maxXP), 0.8, 0.8, 0.8)
        end
        
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click to toggle character panel", 0.8, 0.8, 0.8)
    end,
    onClick = function()
        -- Toggle character panel with error handling
        local success, errorMessage = pcall(function()
            -- Use modern ToggleCharacter function if available
            if ToggleCharacter then
                ToggleCharacter("PaperDollFrame")
            elseif CharacterFrame then
                if CharacterFrame:IsShown() then
                    CharacterFrame:Hide()
                else
                    CharacterFrame:Show()
                end
            else
                -- Last resort: try the slash command
                if _G.ChatFrame_OpenChat then
                    _G.ChatFrame_OpenChat("/character")
                end
            end
        end)
        
        if not success then
            print("Failed to toggle character frame: " .. tostring(errorMessage))
        end
    end
}

-- Register the experience data text - defer until DataTexts is available
local function RegisterDataText()
    local DataTexts = GetDataTexts()
    if DataTexts then
        DataTexts:RegisterDataText("experience", experienceDataText)
        -- Debug info
        -- Export an empty module (registration is enough)
        if MiniMapRedux and MiniMapRedux.export then
            MiniMapRedux.export("ExperienceDataText", {})
        end
    else
        -- Debug info
        -- Try again after a short delay
        C_Timer.After(0.1, RegisterDataText)
    end
end

-- Call register function
RegisterDataText()
