local addonName, _ = ...
local MiniMapRedux = _G.MiniMapRedux

-- LootSpec Data Text Module
local DataTexts
local function GetDataTexts()
    if not DataTexts and MiniMapRedux and MiniMapRedux.import then
        DataTexts = MiniMapRedux.import("DataTexts")
    end
    return DataTexts
end

-- Local storage for loot spec data
local lootSpecData = {
    specName = "",
    specIcon = nil,
    specID = 0,
    isCurrentSpec = false -- true when set to "Current Specialization"
}

-- Role colors
local roleColors = {
    TANK = {0.2, 0.6, 1},
    HEALER = {0.3, 1, 0.3},
    DAMAGER = {1, 0.5, 0.5},
}

-- Function to refresh loot spec data
local function RefreshLootSpecData()
    local success = pcall(function()
        local lootSpecID = GetLootSpecialization()

        if lootSpecID == 0 then
            -- Using current spec as loot spec
            lootSpecData.isCurrentSpec = true
            local currentSpecIndex = GetSpecialization()
            if currentSpecIndex then
                local specID, specName, _, icon, role = GetSpecializationInfo(currentSpecIndex)
                if specID then
                    lootSpecData.specName = specName or "Unknown"
                    lootSpecData.specIcon = icon
                    lootSpecData.specID = specID
                    lootSpecData.role = role
                end
            else
                lootSpecData.specName = "None"
                lootSpecData.specIcon = nil
                lootSpecData.specID = 0
                lootSpecData.role = nil
            end
        else
            -- Using a specific loot spec
            lootSpecData.isCurrentSpec = false
            local specID, specName, _, icon, role = GetSpecializationInfoByID(lootSpecID)
            if specID then
                lootSpecData.specName = specName or "Unknown"
                lootSpecData.specIcon = icon
                lootSpecData.specID = specID
                lootSpecData.role = role
            end
        end
    end)

    if not success then
        lootSpecData.specName = "Unknown"
        lootSpecData.specIcon = nil
        lootSpecData.specID = 0
        lootSpecData.isCurrentSpec = false
        lootSpecData.role = nil
    end
end

-- Event frame for loot spec updates
local lootSpecEventFrame = CreateFrame("Frame")
lootSpecEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
lootSpecEventFrame:RegisterEvent("PLAYER_LOOT_SPEC_UPDATED")
lootSpecEventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
lootSpecEventFrame:SetScript("OnEvent", function(self, event, ...)
    RefreshLootSpecData()
end)

-- Initialize
RefreshLootSpecData()

local lootSpecDataText = {
    name = "Loot Spec",
    color = {1, 0.8, 0.3},
    icon = "Interface\\Icons\\INV_Misc_Coin_02",
    update = function(frame)
        local DataTexts = GetDataTexts()
        if not DataTexts then return end

        if lootSpecData.specName ~= "" and lootSpecData.specName ~= "None" then
            local label = lootSpecData.isCurrentSpec and "Loot: " or "Loot: "
            local suffix = lootSpecData.isCurrentSpec and "" or " *"
            frame.text:SetText(label .. lootSpecData.specName .. suffix)

            -- Color by role
            local color = lootSpecData.role and roleColors[lootSpecData.role] or {1, 0.8, 0.3}
            frame.text:SetTextColor(color[1], color[2], color[3])
        else
            frame.text:SetText("Loot: None")
            frame.text:SetTextColor(0.7, 0.7, 0.7)
        end
    end,
    tooltip = function()
        local DataTexts = GetDataTexts()
        if not DataTexts then return end

        GameTooltip:SetText("Loot Specialization")

        if lootSpecData.isCurrentSpec then
            GameTooltip:AddLine("Current: " .. lootSpecData.specName .. " (follows active spec)", 0.3, 1, 0.3)
        else
            GameTooltip:AddLine("Current: " .. lootSpecData.specName, 1, 0.8, 0.3)
            GameTooltip:AddLine("Loot will drop for this spec regardless of active spec", 0.8, 0.8, 0.8, true)
        end

        GameTooltip:AddLine(" ")

        -- List all available specs
        local numSpecs = GetNumSpecializations()
        if numSpecs and numSpecs > 0 then
            GameTooltip:AddLine("Available Specs:", 0.8, 0.8, 0.8)
            for i = 1, numSpecs do
                local specID, specName, _, _, role = GetSpecializationInfo(i)
                if specID then
                    local color = roleColors[role] or {1, 1, 1}
                    local marker = ""
                    if lootSpecData.specID == specID then
                        marker = " |cffffd700<|r"
                    end
                    GameTooltip:AddLine("  " .. specName .. marker, color[1], color[2], color[3])
                end
            end
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click to cycle loot spec", 0.8, 0.8, 0.8)
    end,
    onClick = function()
        -- Cycle through loot specs: Current Spec -> Spec1 -> Spec2 -> ... -> Current Spec
        local success = pcall(function()
            local currentLootSpecID = GetLootSpecialization()
            local numSpecs = GetNumSpecializations()
            if not numSpecs or numSpecs == 0 then return end

            if currentLootSpecID == 0 then
                -- Currently "Current Spec", switch to first spec
                local specID = GetSpecializationInfo(1)
                if specID then
                    SetLootSpecialization(specID)
                end
            else
                -- Find current loot spec index and go to next
                local foundIndex = nil
                for i = 1, numSpecs do
                    local specID = GetSpecializationInfo(i)
                    if specID == currentLootSpecID then
                        foundIndex = i
                        break
                    end
                end

                if foundIndex and foundIndex < numSpecs then
                    -- Go to next spec
                    local nextSpecID = GetSpecializationInfo(foundIndex + 1)
                    if nextSpecID then
                        SetLootSpecialization(nextSpecID)
                    end
                else
                    -- Wrap around to "Current Specialization" (0)
                    SetLootSpecialization(0)
                end
            end
        end)

        if not success then
            print("|cff3399ffMiniMapRedux:|r Failed to change loot spec")
        end
    end
}

-- Register the loot spec data text - defer until DataTexts is available
local function RegisterDataText()
    local DataTexts = GetDataTexts()
    if DataTexts then
        DataTexts:RegisterDataText("lootspec", lootSpecDataText)
        if MiniMapRedux and MiniMapRedux.export then
            MiniMapRedux.export("LootSpecDataText", {})
        end
    else
        C_Timer.After(0.1, RegisterDataText)
    end
end

RegisterDataText()
