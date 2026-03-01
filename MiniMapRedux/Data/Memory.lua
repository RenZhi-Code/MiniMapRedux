local addonName, _ = ...
local MiniMapRedux = _G.MiniMapRedux

-- Memory Data Text Module
local DataTexts
local function GetDataTexts()
    if not DataTexts and MiniMapRedux and MiniMapRedux.import then
        DataTexts = MiniMapRedux.import("DataTexts")
    end
    return DataTexts
end

-- Local storage for memory data
local memoryData = {
    totalMemory = 0,
    addonMemory = {}
}

-- Function to refresh memory data with error handling
local function RefreshMemoryData()
    local DataTexts = GetDataTexts()
    if not DataTexts then return end
    
    local success, errorMessage = pcall(function()
        -- Get memory usage in KB
        local memoryKB = 0
        local addonMemory = {}
        
        -- Try to update memory usage
        local updateSuccess = pcall(UpdateAddOnMemoryUsage)
        if not updateSuccess then
            return
        end
        
        local numAddOnsSuccess, numAddOns = pcall(C_AddOns.GetNumAddOns)
        if not numAddOnsSuccess or not numAddOns then
            return
        end
        
        for i = 1, numAddOns do
            local isLoadedSuccess, isLoaded = pcall(C_AddOns.IsAddOnLoaded, i)
            if isLoadedSuccess and isLoaded then
                local memorySuccess, memory = pcall(GetAddOnMemoryUsage, i)
                if memorySuccess and memory then
                    memoryKB = memoryKB + memory
                    local nameSuccess, name = pcall(C_AddOns.GetAddOnInfo, i)
                    if nameSuccess and name then
                        table.insert(addonMemory, {name = name, memory = memory})
                    end
                end
            end
        end
        
        -- Store data
        memoryData.totalMemory = memoryKB
        memoryData.addonMemory = addonMemory
        
        -- Sort by memory usage (descending)
        table.sort(memoryData.addonMemory, function(a, b)
            return a.memory > b.memory
        end)
    end)
    
    if not success then
        print("Memory data refresh failed: " .. tostring(errorMessage))
    end
end

-- Event frame for memory updates
local memoryEventFrame = CreateFrame("Frame")
memoryEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
memoryEventFrame:RegisterEvent("ADDON_LOADED")
memoryEventFrame:SetScript("OnEvent", function(self, event, ...)
    RefreshMemoryData()
end)

-- Initialize memory data
RefreshMemoryData()

-- Remove individual timer since we're using centralized updates
-- Timer to periodically update memory data
-- C_Timer.NewTicker(5, function()
--     RefreshMemoryData()
-- end)

local memoryDataText = {
    name = "Memory",
    color = {0.3, 1, 0.8}, -- Green
    icon = "Interface\\Icons\\INV_Misc_Book_01", -- Memory icon
    update = function(frame)
        local DataTexts = GetDataTexts()
        if not DataTexts then return end
        
        local memoryMB = memoryData.totalMemory / 1024
        frame.text:SetText(string.format("Memory: %.1f MB", memoryMB))
        
        -- Color based on memory usage
        if memoryMB < 50 then
            frame.text:SetTextColor(0.3, 1, 0.3) -- Green for low usage
        elseif memoryMB < 100 then
            frame.text:SetTextColor(1, 1, 0.3) -- Yellow for medium usage
        else
            frame.text:SetTextColor(1, 0.3, 0.3) -- Red for high usage
        end
    end,
    tooltip = function()
        local DataTexts = GetDataTexts()
        if not DataTexts then return end
        
        GameTooltip:SetText("Memory Usage")
        
        local totalMemoryMB = memoryData.totalMemory / 1024
        GameTooltip:AddLine(string.format("Total Memory: %.2f MB", totalMemoryMB), 1, 1, 1)
        
        -- Calculate average and peak memory usage
        if #memoryData.addonMemory > 0 then
            local totalMemory = 0
            local peakMemory = 0
            local peakAddon = ""
            
            for _, addon in ipairs(memoryData.addonMemory) do
                totalMemory = totalMemory + addon.memory
                if addon.memory > peakMemory then
                    peakMemory = addon.memory
                    peakAddon = addon.name
                end
            end
            
            local averageMemory = totalMemory / #memoryData.addonMemory
            local averageMemoryMB = averageMemory / 1024
            local peakMemoryMB = peakMemory / 1024
            
            GameTooltip:AddLine(string.format("Average: %.2f MB", averageMemoryMB), 0.8, 0.8, 0.8)
            GameTooltip:AddLine(string.format("Peak: %.2f MB (%s)", peakMemoryMB, peakAddon), 0.8, 0.8, 0.8)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("AddOns by Memory Usage:", 1, 1, 0)
            
            -- Show all addons sorted by memory usage (highest to lowest)
            for i = 1, #memoryData.addonMemory do
                local addon = memoryData.addonMemory[i]
                local memoryMB = addon.memory / 1024
                local color = {0.8, 0.8, 0.8}
                
                -- Color code based on memory usage
                if memoryMB > 5 then
                    color = {1, 0.3, 0.3} -- Red for high usage
                elseif memoryMB > 2 then
                    color = {1, 1, 0.3} -- Yellow for medium usage
                else
                    color = {0.3, 1, 0.3} -- Green for low usage
                end
                
                GameTooltip:AddLine(string.format("%s: %.2f MB", addon.name, memoryMB), color[1], color[2], color[3])
            end
        else
            GameTooltip:AddLine("No AddOns loaded", 0.7, 0.7, 0.7)
        end
        
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click to collect garbage", 0.8, 0.8, 0.8)
    end,
    onClick = function()
        local DataTexts = GetDataTexts()
        if not DataTexts then return end
        
        -- Collect garbage to free memory
        local success = pcall(collectgarbage, "collect")
        
        if success then
            -- Show confirmation
            if MiniMapRedux.buttonBar then
                print("Memory collected")
            else
                DEFAULT_CHAT_FRAME:AddMessage("MiniMapRedux: Memory collected", 0.3, 1, 0.3)
            end
            
            -- Refresh memory data after collection
            C_Timer.After(0.5, function()
                RefreshMemoryData()
            end)
        else
            print("Failed to collect memory")
        end
    end
}

-- Register the memory data text - defer until DataTexts is available
local function RegisterDataText()
    local DataTexts = GetDataTexts()
    if DataTexts then
        DataTexts:RegisterDataText("memory", memoryDataText)
        -- Export an empty module (registration is enough)
        if MiniMapRedux and MiniMapRedux.export then
            MiniMapRedux.export("MemoryDataText", {})
        end
    else
        -- Try again after a short delay
        C_Timer.After(0.1, RegisterDataText)
    end
end

-- Call register function
RegisterDataText()