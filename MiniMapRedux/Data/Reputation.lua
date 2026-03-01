local addonName, _ = ...
local MiniMapRedux = _G.MiniMapRedux

-- Reputation Data Text Module
local DataTexts
local function GetDataTexts()
    if not DataTexts and MiniMapRedux and MiniMapRedux.import then
        DataTexts = MiniMapRedux.import("DataTexts")
    end
    return DataTexts
end

-- Local storage for reputation data
local reputationData = {
    name = "",
    reaction = 0,
    currentStanding = 0,
    currentReactionThreshold = 0,
    nextReactionThreshold = 0
}

-- Function to refresh reputation data with error handling
local function RefreshReputationData()
    local DataTexts = GetDataTexts()
    if not DataTexts then return end
    
    local success, errorMessage = pcall(function()
        -- Get the player's current watched faction using the new API
        local watchedSuccess, watchedFaction = pcall(C_Reputation.GetWatchedFactionData)
        if watchedSuccess and watchedFaction and watchedFaction.name and watchedFaction.reaction then
            reputationData.name = watchedFaction.name or ""
            reputationData.reaction = watchedFaction.reaction or 0
            reputationData.currentStanding = watchedFaction.currentStanding or 0
            reputationData.currentReactionThreshold = watchedFaction.currentReactionThreshold or 0
            reputationData.nextReactionThreshold = watchedFaction.nextReactionThreshold or 0
        else
            reputationData.name = ""
            reputationData.reaction = 0
            reputationData.currentStanding = 0
            reputationData.currentReactionThreshold = 0
            reputationData.nextReactionThreshold = 0
        end
    end)
    
    if not success then
        print("Reputation data refresh failed: " .. tostring(errorMessage))
        reputationData.name = ""
        reputationData.reaction = 0
        reputationData.currentStanding = 0
        reputationData.currentReactionThreshold = 0
        reputationData.nextReactionThreshold = 0
    end
end

-- Event frame for reputation updates
local reputationEventFrame = CreateFrame("Frame")
reputationEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
reputationEventFrame:RegisterEvent("UPDATE_FACTION")
reputationEventFrame:SetScript("OnEvent", function(self, event, ...)
    local DataTexts = GetDataTexts()
    if DataTexts then
        RefreshReputationData()
    end
end)

-- Initialize reputation data
RefreshReputationData()

local reputationDataText = {
    name = "Reputation",
    color = {1, 0.5, 1}, -- Purple
    icon = "Interface\\Icons\\Achievement_Reputation_01", -- Reputation icon
    update = function(frame)
        local DataTexts = GetDataTexts()
        if not DataTexts then return end
        
        if reputationData.name ~= "" and reputationData.reaction > 0 then
            -- Handle case where faction is at max reputation (e.g., Exalted)
            if reputationData.reaction == 8 or reputationData.nextReactionThreshold == 0 then
                frame.text:SetText(string.format("%s", _G["FACTION_STANDING_LABEL" .. reputationData.reaction] or "Unknown"))
                frame.text:SetTextColor(0, 1, 0) -- Bright green for exalted
            else
                if reputationData.name and reputationData.currentStanding and reputationData.nextReactionThreshold and reputationData.currentReactionThreshold then
                    local percent = ((reputationData.currentStanding - reputationData.currentReactionThreshold) / (reputationData.nextReactionThreshold - reputationData.currentReactionThreshold)) * 100
                    local reactionText = _G["FACTION_STANDING_LABEL" .. reputationData.reaction] or "Unknown"
                    
                    frame.text:SetText(string.format("%s: %d%%", reactionText, percent))
                    
                    -- Color based on reputation level
                    if reputationData.reaction >= 5 then
                        frame.text:SetTextColor(0.3, 1, 0.3) -- Green for friendly and above
                    elseif reputationData.reaction == 4 then
                        frame.text:SetTextColor(1, 1, 0.3) -- Yellow for neutral
                    else
                        frame.text:SetTextColor(1, 0.3, 0.3) -- Red for unfriendly and below
                    end
                else
                    frame.text:SetText("Reputation: None")
                    frame.text:SetTextColor(0.7, 0.7, 0.7) -- Gray
                end
            end
        else
            frame.text:SetText("Reputation: None")
            frame.text:SetTextColor(0.7, 0.7, 0.7) -- Gray
        end
    end,
    tooltip = function()
        local DataTexts = GetDataTexts()
        if not DataTexts then return end
        
        GameTooltip:SetText("Reputation Status")
        
        if reputationData.name ~= "" and reputationData.reaction > 0 then
            local reactionText = _G["FACTION_STANDING_LABEL" .. reputationData.reaction] or "Unknown"
            
            GameTooltip:AddLine(reputationData.name, 1, 1, 1)
            
            -- Handle case where faction is at max reputation (e.g., Exalted)
            if reputationData.reaction == 8 or reputationData.nextReactionThreshold == 0 then
                GameTooltip:AddLine(reactionText, 0, 1, 0)
                GameTooltip:AddLine("Maximum reputation reached", 0.8, 1, 0.8)
            else
                if reputationData.name and reputationData.currentStanding and reputationData.nextReactionThreshold and reputationData.currentReactionThreshold then
                    local current = reputationData.currentStanding - reputationData.currentReactionThreshold
                    local total = reputationData.nextReactionThreshold - reputationData.currentReactionThreshold
                    local percent = math.max(0, math.min(100, (current / total) * 100))
                    local remaining = reputationData.nextReactionThreshold - reputationData.currentStanding
                    
                    GameTooltip:AddLine(string.format("%s - %d%%", reactionText, percent), 1, 1, 1)
                    GameTooltip:AddLine(string.format("Progress: %d / %d", current, total), 1, 1, 1)
                    GameTooltip:AddLine(string.format("Remaining: %d", remaining), 1, 1, 1)
                    
                    -- Add Blizzard-style status bar
                    GameTooltip:AddLine(" ")
                    
                    -- Color based on reputation level
                    local r, g, b = 1, 1, 1
                    if reputationData.reaction >= 5 then
                        r, g, b = 0.3, 1, 0.3 -- Green for friendly and above
                    elseif reputationData.reaction == 4 then
                        r, g, b = 1, 1, 0.3 -- Yellow for neutral
                    else
                        r, g, b = 1, 0.3, 0.3 -- Red for unfriendly and below
                    end
                    
                    -- Create a 20-segment progress bar
                    local barLength = 20
                    local filledLength = math.floor((percent / 100) * barLength)
                    local emptyLength = barLength - filledLength
                    
                    -- Build the progress bar string
                    local statusBar = ""
                    for i = 1, filledLength do
                        statusBar = statusBar .. string.format("|cff%02x%02x%02x█|r", math.floor(r*255), math.floor(g*255), math.floor(b*255))
                    end
                    for i = 1, emptyLength do
                        statusBar = statusBar .. "|cff404040█|r"
                    end
                    GameTooltip:AddLine(statusBar)
                    
                    -- Next reputation level info
                    if reputationData.reaction < 8 then
                        local nextReactionText = _G["FACTION_STANDING_LABEL" .. (reputationData.reaction + 1)] or "Unknown"
                        GameTooltip:AddLine(" ")
                        GameTooltip:AddLine(string.format("Next: %s", nextReactionText), 0.8, 0.8, 0.8)
                    end
                end
            end
        else
            GameTooltip:AddLine("No watched faction", 0.7, 0.7, 0.7)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Set a watched faction in your reputation panel", 0.8, 0.8, 0.8)
        end
        
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click to open reputation panel", 0.8, 0.8, 0.8)
    end,
    onClick = function()
        local DataTexts = GetDataTexts()
        if not DataTexts then return end
        
        -- Toggle reputation panel with error handling
        local success, errorMessage = pcall(function()
            -- Try modern ToggleReputationFrame first
            if ToggleReputationFrame then
                ToggleReputationFrame()
            elseif ReputationFrame then
                if ReputationFrame:IsShown() then
                    ReputationFrame:Hide()
                else
                    ReputationFrame:Show()
                end
            else
                -- Load the reputation UI if not loaded
                local loadSuccess = false
                if C_AddOns and C_AddOns.LoadAddOn then
                    loadSuccess = pcall(C_AddOns.LoadAddOn, "Blizzard_ReputationUI")
                elseif _G.LoadAddOn then
                    loadSuccess = pcall(_G.LoadAddOn, "Blizzard_ReputationUI")
                end
                if loadSuccess then
                    -- Try to show the frame after loading
                    if ToggleReputationFrame then
                        ToggleReputationFrame()
                    elseif ReputationFrame then
                        ReputationFrame:Show()
                    end
                else
                    -- Last resort: try the slash command
                    if _G.ChatFrame_OpenChat then
                        _G.ChatFrame_OpenChat("/reputation")
                    end
                end
            end
        end)
        
        if not success then
            print("Failed to toggle reputation frame: " .. tostring(errorMessage))
        end
    end
}

-- Register the reputation data text - defer until DataTexts is available
local function RegisterDataText()
    local DataTexts = GetDataTexts()
    if DataTexts then
        DataTexts:RegisterDataText("reputation", reputationDataText)
        -- Export an empty module (registration is enough)
        if MiniMapRedux and MiniMapRedux.export then
            MiniMapRedux.export("ReputationDataText", {})
        end
    else
        -- Try again after a short delay
        C_Timer.After(0.1, RegisterDataText)
    end
end

-- Call register function
RegisterDataText()