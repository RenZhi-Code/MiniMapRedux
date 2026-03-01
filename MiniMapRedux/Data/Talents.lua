local addonName, _ = ...
local MiniMapRedux = _G.MiniMapRedux

-- Talents Data Text Module
local DataTexts
local function GetDataTexts()
    if not DataTexts and MiniMapRedux and MiniMapRedux.import then
        DataTexts = MiniMapRedux.import("DataTexts")
    end
    return DataTexts
end

-- Local storage for talents data
local talentsData = {
    specIndex = 0,
    specName = "",
    specRole = "",
    hasTalents = false
}

-- Function to refresh talents data with error handling
local function RefreshTalentsData()
    local DataTexts = GetDataTexts()
    if not DataTexts then return end
    
    local success, errorMessage = pcall(function()
        local specIndexSuccess, specIndex = pcall(C_SpecializationInfo.GetSpecialization)
        if specIndexSuccess and specIndex and specIndex > 0 then
            talentsData.specIndex = specIndex
            
            local specInfoSuccess, specID, specName, _, _, _, role = pcall(C_SpecializationInfo.GetSpecializationInfo, specIndex)
            if specInfoSuccess and specID then
                talentsData.specName = specName or "Unknown"
                talentsData.specRole = role or ""
                talentsData.hasTalents = true
            else
                talentsData.specName = "Unknown"
                talentsData.specRole = ""
                talentsData.hasTalents = false
            end
        else
            talentsData.specIndex = 0
            talentsData.specName = ""
            talentsData.specRole = ""
            talentsData.hasTalents = false
        end
    end)
    
    if not success then
        print("Talents data refresh failed: " .. tostring(errorMessage))
        talentsData.specIndex = 0
        talentsData.specName = ""
        talentsData.specRole = ""
        talentsData.hasTalents = false
    end
end

-- Event frame for talents updates
local talentsEventFrame = CreateFrame("Frame")
talentsEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
talentsEventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
talentsEventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
talentsEventFrame:RegisterEvent("SPEC_INVOLUNTARILY_CHANGED")
talentsEventFrame:SetScript("OnEvent", function(self, event, ...)
    local DataTexts = GetDataTexts()
    if DataTexts then
        RefreshTalentsData()
    end
end)

-- Initialize talents data
RefreshTalentsData()

local talentsDataText = {
    name = "Talents",
    color = {0.5, 0.5, 1}, -- Blue
    icon = "Interface\\Icons\\Ability_Marksmanship", -- Talent icon
    update = function(frame)
        local DataTexts = GetDataTexts()
        if not DataTexts then return end
        
        if talentsData.hasTalents and talentsData.specName ~= "" then
            frame.text:SetText(string.format("Talents: %s", talentsData.specName))
            frame.text:SetTextColor(0.5, 0.5, 1) -- Blue
        else
            frame.text:SetText("Talents: None")
            frame.text:SetTextColor(0.7, 0.7, 0.7) -- Gray
        end
    end,
    tooltip = function()
        local DataTexts = GetDataTexts()
        if not DataTexts then return end
        
        GameTooltip:SetText("Talent Information")
        
        if talentsData.hasTalents and talentsData.specName ~= "" then
            GameTooltip:AddLine(talentsData.specName, 0.5, 0.5, 1)
            
            -- Get spec description with error handling
            local descSuccess, _, description = pcall(C_SpecializationInfo.GetSpecializationInfo, talentsData.specIndex)
            if descSuccess and description then
                GameTooltip:AddLine(description, 0.8, 0.8, 0.8, true)
            end
            
            -- Role information
            if talentsData.specRole ~= "" then
                local roleText = ""
                if talentsData.specRole == "TANK" then
                    roleText = "Tank"
                elseif talentsData.specRole == "HEALER" then
                    roleText = "Healer"
                elseif talentsData.specRole == "DAMAGER" then
                    roleText = "Damage Dealer"
                end
                
                if roleText ~= "" then
                    GameTooltip:AddLine("Role: " .. roleText, 1, 1, 1)
                end
            end
            
            -- Talent points information
            if C_ClassTalents and C_ClassTalents.GetActiveConfigID then
                local configSuccess, configID = pcall(C_ClassTalents.GetActiveConfigID)
                if configSuccess and configID then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine("Talent Tree Active", 1, 1, 1)
                end
            end
        else
            GameTooltip:AddLine("No specialization selected", 0.7, 0.7, 0.7)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Visit your class trainer to choose talents", 0.8, 0.8, 0.8)
        end
        
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click to open talent panel", 0.8, 0.8, 0.8)
    end,
    onClick = function()
        local DataTexts = GetDataTexts()
        if not DataTexts then return end
        
        -- Toggle talent panel with error handling
        local success, errorMessage = pcall(function()
            -- Try modern ToggleTalentFrame first (Dragonflight+)
            if ToggleTalentFrame then
                ToggleTalentFrame()
            elseif ClassTalentFrame then
                -- Modern Class Talent Frame (Dragonflight+)
                if ClassTalentFrame:IsShown() then
                    ClassTalentFrame:Hide()
                else
                    ClassTalentFrame:Show()
                end
            elseif PlayerTalentFrame then
                -- Legacy Talent Frame
                if PlayerTalentFrame:IsShown() then
                    PlayerTalentFrame:Hide()
                else
                    PlayerTalentFrame:Show()
                end
            else
                -- Load the talent UI if not loaded
                local loadSuccess = false
                if C_AddOns and C_AddOns.LoadAddOn then
                    -- Try modern talent UI first
                    loadSuccess = pcall(C_AddOns.LoadAddOn, "Blizzard_ClassTalentUI")
                    if not loadSuccess then
                        loadSuccess = pcall(C_AddOns.LoadAddOn, "Blizzard_TalentUI")
                    end
                elseif _G.LoadAddOn then
                    loadSuccess = pcall(_G.LoadAddOn, "Blizzard_ClassTalentUI")
                    if not loadSuccess then
                        loadSuccess = pcall(_G.LoadAddOn, "Blizzard_TalentUI")
                    end
                end

                if loadSuccess then
                    -- Try to show the frame after loading
                    if ToggleTalentFrame then
                        ToggleTalentFrame()
                    elseif ClassTalentFrame then
                        ClassTalentFrame:Show()
                    elseif PlayerTalentFrame then
                        PlayerTalentFrame:Show()
                    end
                else
                    -- Last resort: try the slash command
                    if _G.ChatFrame_OpenChat then
                        _G.ChatFrame_OpenChat("/talents")
                    end
                end
            end
        end)
        
        if not success then
            print("Failed to toggle talent frame: " .. tostring(errorMessage))
        end
    end
}

-- Register the talents data text - defer until DataTexts is available
local function RegisterDataText()
    local DataTexts = GetDataTexts()
    if DataTexts then
        DataTexts:RegisterDataText("talents", talentsDataText)
        -- Export an empty module (registration is enough)
        if MiniMapRedux and MiniMapRedux.export then
            MiniMapRedux.export("TalentsDataText", {})
        end
    else
        -- Try again after a short delay
        C_Timer.After(0.1, RegisterDataText)
    end
end

-- Call register function
RegisterDataText()
