local addonName, _ = ...
local MiniMapRedux = _G.MiniMapRedux

-- Durability Data Text Module
local DataTexts
local function GetDataTexts()
    if not DataTexts and MiniMapRedux and MiniMapRedux.import then
        DataTexts = MiniMapRedux.import("DataTexts")
    end
    return DataTexts
end

-- Local storage for durability data
local durabilityData = {
    percentage = 100,
    items = {}
}

-- Function to refresh durability data with error handling
local function RefreshDurabilityData()
    local DataTexts = GetDataTexts()
    if not DataTexts then return end
    
    local success, errorMessage = pcall(function()
        local totalCurrent = 0
        local totalMax = 0
        local numItems = 0
        local items = {}
        local lowestDurability = 100
        
        -- Check durability for equipped items (slots 1-18, skipping ammo slot 0)
        for i = 1, 18 do
            local durabilitySuccess, durability, maxDurability = pcall(GetInventoryItemDurability, i)
            if durabilitySuccess and durability and maxDurability and maxDurability > 0 then
                totalCurrent = totalCurrent + durability
                totalMax = totalMax + maxDurability
                numItems = numItems + 1
                
                local percentage = (durability / maxDurability) * 100
                if percentage < lowestDurability then
                    lowestDurability = percentage
                end
                
                local itemInfoSuccess, itemID = pcall(GetInventoryItemID, "player", i)
                if itemInfoSuccess and itemID then
                    local itemNameSuccess, itemName, _, itemRarity = pcall(GetItemInfo, itemID)
                    if itemNameSuccess and itemName then
                        local itemLinkSuccess, itemLink = pcall(GetInventoryItemLink, "player", i)
                        table.insert(items, {
                            name = itemName,
                            percentage = percentage,
                            rarity = itemRarity or 1,
                            link = itemLinkSuccess and itemLink or nil
                        })
                    end
                end
            end
        end
        
        -- Store data
        if numItems > 0 and totalMax > 0 then
            durabilityData.percentage = (totalCurrent / totalMax) * 100
        else
            durabilityData.percentage = 100
        end
        durabilityData.items = items
    end)
    
    if not success then
        print("Durability data refresh failed: " .. tostring(errorMessage))
        durabilityData.percentage = 100
        durabilityData.items = {}
    end
end

-- Event frame for durability updates
local durabilityEventFrame = CreateFrame("Frame")
durabilityEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
durabilityEventFrame:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
durabilityEventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
durabilityEventFrame:SetScript("OnEvent", function(self, event, ...)
    RefreshDurabilityData()
end)

-- Initialize durability data
RefreshDurabilityData()

local durabilityDataText = {
    name = "Durability",
    color = {0.8, 0.6, 0.3}, -- Brown
    icon = "Interface\\Icons\\INV_Hammer_20", -- Hammer icon
    update = function(frame)
        local DataTexts = GetDataTexts()
        if not DataTexts then return end
        
        local percentage = durabilityData.percentage

        -- Find lowest durability item
        local lowestPct = 100
        local lowestName = nil
        for _, item in ipairs(durabilityData.items) do
            if item.percentage < lowestPct then
                lowestPct = item.percentage
                lowestName = item.name
            end
        end

        if lowestName and lowestPct < percentage - 5 then
            -- Show overall + lowest item when there's a significant difference
            frame.text:SetText(string.format("Dur: %.0f%% (Low: %.0f%%)", percentage, lowestPct))
        else
            frame.text:SetText(string.format("Dur: %.0f%%", percentage))
        end

        -- Color based on lowest durability (most important to see)
        local colorPct = math.min(percentage, lowestPct)
        if colorPct < 20 then
            frame.text:SetTextColor(1, 0.3, 0.3) -- Red
        elseif colorPct < 50 then
            frame.text:SetTextColor(1, 1, 0.3) -- Yellow
        else
            frame.text:SetTextColor(0.3, 1, 0.3) -- Green
        end
    end,
    tooltip = function()
        local DataTexts = GetDataTexts()
        if not DataTexts then return end
        
        GameTooltip:SetText("Equipment Durability")
        
        if #durabilityData.items == 0 then
            GameTooltip:AddLine("All items are at full durability", 0.3, 1, 0.3)
        else
            local lowestDurability = 100
            local lowestItem = nil
            
            for _, item in ipairs(durabilityData.items) do
                if item.percentage < lowestDurability then
                    lowestDurability = item.percentage
                    lowestItem = item.link
                end
                
                local color = ITEM_QUALITY_COLORS[item.rarity] or {r=1, g=1, b=1}
                GameTooltip:AddLine(string.format("%s: %d%%", item.name, item.percentage), 
                                  color.r, color.g, color.b)
            end
            
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(string.format("Lowest: %d%%", lowestDurability), 1, 1, 1)
            if lowestItem then
                GameTooltip:AddLine("Repair recommended", 1, 0.8, 0.3)
            end
        end
        
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click to open character panel", 0.8, 0.8, 0.8)
    end,
    onClick = function()
        -- Open character panel with error handling
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
            end
        end)
        
        if not success then
            print("Failed to toggle character frame: " .. tostring(errorMessage))
        end
    end
}

-- Register the durability data text - defer until DataTexts is available
local function RegisterDataText()
    local DataTexts = GetDataTexts()
    if DataTexts then
        DataTexts:RegisterDataText("durability", durabilityDataText)
        -- Export an empty module (registration is enough)
        if MiniMapRedux and MiniMapRedux.export then
            MiniMapRedux.export("DurabilityDataText", {})
        end
    else
        -- Try again after a short delay
        C_Timer.After(0.1, RegisterDataText)
    end
end

-- Call register function
RegisterDataText()