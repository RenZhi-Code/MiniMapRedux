local addonName, _ = ...
local MiniMapRedux = _G.MiniMapRedux

-- Bags Data Text Module
local DataTexts
local function GetDataTexts()
    if not DataTexts and MiniMapRedux and MiniMapRedux.import then
        DataTexts = MiniMapRedux.import("DataTexts")
    end
    return DataTexts
end

-- Local storage for bags data
local bagsData = {
    totalSlots = 0,
    usedSlots = 0,
    bagInfo = {}
}

-- Function to refresh bags data with error handling
local function RefreshBagsData()
    local DataTexts = GetDataTexts()
    if not DataTexts then return end
    
    local success, errorMessage = pcall(function()
        local totalSlots = 0
        local usedSlots = 0
        local bagInfo = {}
        
        -- Check all bags (0-4 for player bags, 5 for reagent bag)
        for i = 0, 5 do
            local bagSlotsSuccess, bagSlots = pcall(C_Container.GetContainerNumSlots, i)
            if bagSlotsSuccess and bagSlots and bagSlots > 0 then
                local bagUsed = 0
                for j = 1, bagSlots do
                    local itemInfoSuccess, itemInfo = pcall(C_Container.GetContainerItemInfo, i, j)
                    if itemInfoSuccess and itemInfo then
                        bagUsed = bagUsed + 1
                    end
                end
                
                totalSlots = totalSlots + bagSlots
                usedSlots = usedSlots + bagUsed
                
                -- Get bag information
                local bagLink = nil
                local inventoryID = nil
                
                if i >= 1 and i <= 4 then
                    -- Regular bags (1-4) map to inventory slots 31-34
                    inventoryID = 30 + i
                elseif i == 5 then
                    -- Reagent bag maps to inventory slot 35
                    inventoryID = 35
                end
                
                if inventoryID then
                    local linkSuccess, link = pcall(GetInventoryItemLink, "player", inventoryID)
                    if linkSuccess and link then
                        bagLink = link
                    end
                end
                
                local bagName, bagQuality = "Backpack", 1
                if bagLink then
                    local nameSuccess, name, _, quality = pcall(GetItemInfo, bagLink)
                    if nameSuccess and name then
                        bagName = name
                        bagQuality = quality or 1
                    end
                elseif i > 0 then
                    bagName = "Bag " .. i
                end
                
                table.insert(bagInfo, {
                    name = bagName,
                    total = bagSlots,
                    used = bagUsed,
                    quality = bagQuality
                })
            end
        end
        
        -- Store data
        bagsData.totalSlots = totalSlots
        bagsData.usedSlots = usedSlots
        bagsData.bagInfo = bagInfo
    end)
    
    if not success then
        print("Bags data refresh failed: " .. tostring(errorMessage))
    end
end

-- Event frame for bags updates
local bagsEventFrame = CreateFrame("Frame")
bagsEventFrame:RegisterEvent("BAG_UPDATE")
bagsEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
bagsEventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
bagsEventFrame:SetScript("OnEvent", function(self, event, ...)
    RefreshBagsData()
end)

-- Initialize bags data
RefreshBagsData()

local bagsDataText = {
    name = "Bags",
    color = {0.8, 0.6, 0.3}, -- Brown
    icon = "Interface\\Icons\\INV_Misc_Bag_08", -- Bag icon
    update = function(frame)
        local DataTexts = GetDataTexts()
        if not DataTexts then return end
        
        if bagsData.totalSlots > 0 then
            local freeSlots = bagsData.totalSlots - bagsData.usedSlots
            local percentFull = (bagsData.usedSlots / bagsData.totalSlots) * 100
            
            frame.text:SetText(string.format("Bags: %d/%d", freeSlots, bagsData.totalSlots))
            
            -- Color based on how full bags are
            if percentFull > 90 then
                frame.text:SetTextColor(1, 0.3, 0.3) -- Red for very full
            elseif percentFull > 75 then
                frame.text:SetTextColor(1, 1, 0.3) -- Yellow for quite full
            else
                frame.text:SetTextColor(0.8, 0.6, 0.3) -- Brown for normal
            end
        else
            frame.text:SetText("Bags: 0/0")
            frame.text:SetTextColor(0.7, 0.7, 0.7) -- Gray
        end
    end,
    tooltip = function()
        local DataTexts = GetDataTexts()
        if not DataTexts then return end
        
        GameTooltip:SetText("Bag Space")
        
        if bagsData.totalSlots > 0 then
            local freeSlots = bagsData.totalSlots - bagsData.usedSlots
            local percentFull = (bagsData.usedSlots / bagsData.totalSlots) * 100
            
            GameTooltip:AddLine(string.format("Total: %d/%d slots used (%.1f%%)", bagsData.usedSlots, bagsData.totalSlots, percentFull), 1, 1, 1)
            GameTooltip:AddLine(string.format("Free: %d slots", freeSlots), 1, 1, 1)
            
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Bags:", 0.8, 0.8, 0.8)
            
            for _, bag in ipairs(bagsData.bagInfo) do
                local color = ITEM_QUALITY_COLORS[bag.quality] or {r=1, g=1, b=1}
                local bagPercent = bag.total > 0 and (bag.used / bag.total) * 100 or 0
                GameTooltip:AddLine(
                    string.format("%s: %d/%d (%.0f%%)", bag.name, bag.used, bag.total, bagPercent),
                    color.r, color.g, color.b
                )
            end
            
            if percentFull > 90 then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("Warning: Bags nearly full!", 1, 0.3, 0.3)
            end
        else
            GameTooltip:AddLine("No bags equipped", 0.7, 0.7, 0.7)
        end
        
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click to open all bags", 0.8, 0.8, 0.8)
    end,
    onClick = function()
        -- Toggle all bags with error handling
        local success, errorMessage = pcall(ToggleAllBags)
        if not success then
            print("Failed to toggle bags: " .. tostring(errorMessage))
        end
    end
}

-- Register the bags data text - defer until DataTexts is available
local function RegisterDataText()
    local DataTexts = GetDataTexts()
    if DataTexts then
        DataTexts:RegisterDataText("bags", bagsDataText)
        -- Export an empty module (registration is enough)
        if MiniMapRedux and MiniMapRedux.export then
            MiniMapRedux.export("BagsDataText", {})
        end
    else
        -- Try again after a short delay
        C_Timer.After(0.1, RegisterDataText)
    end
end

-- Call register function
RegisterDataText()