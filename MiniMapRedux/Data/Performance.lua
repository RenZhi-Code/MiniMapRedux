local addonName, _ = ...
local MiniMapRedux = _G.MiniMapRedux

-- Performance Data Text Module
local DataTexts
local function GetDataTexts()
    if not DataTexts and MiniMapRedux and MiniMapRedux.import then
        DataTexts = MiniMapRedux.import("DataTexts")
    end
    return DataTexts
end

-- Local storage for performance data
local performanceData = {
    fps = 0,
    lagHome = 0,
    lagWorld = 0
}

-- Function to refresh performance data with error handling
local function RefreshPerformanceData()
    local DataTexts = GetDataTexts()
    if not DataTexts then return end
    
    local success, errorMessage = pcall(function()
        -- Get FPS and latency
        local fpsSuccess, fps = pcall(GetFramerate)
        if fpsSuccess and fps then
            performanceData.fps = fps
        else
            performanceData.fps = 0
        end
        
        local netStatsSuccess, _, _, lagHome, lagWorld = pcall(GetNetStats)
        if netStatsSuccess then
            performanceData.lagHome = lagHome or 0
            performanceData.lagWorld = lagWorld or 0
        else
            performanceData.lagHome = 0
            performanceData.lagWorld = 0
        end
    end)
    
    if not success then
        print("Performance data refresh failed: " .. tostring(errorMessage))
    end
end

-- Event frame for performance updates
local performanceEventFrame = CreateFrame("Frame")
performanceEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
performanceEventFrame:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
performanceEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
performanceEventFrame:SetScript("OnEvent", function(self, event, ...)
    RefreshPerformanceData()
end)

-- Initialize performance data
RefreshPerformanceData()

-- Remove the individual timer since we're using centralized updates
-- Timer to periodically update performance data
-- C_Timer.NewTicker(1, function()
--     RefreshPerformanceData()
-- end)

local performanceDataText = {
    name = "Performance",
    color = {1, 0.8, 0.3}, -- Orange
    icon = "Interface\\Icons\\Ability_Rogue_Sprint", -- Performance icon
    update = function(frame)
        local DataTexts = GetDataTexts()
        if not DataTexts then return end
        
        local maxLatency = math.max(performanceData.lagHome, performanceData.lagWorld)
        
        -- Display FPS and latency
        frame.text:SetText(string.format("FPS: %.0f | Latency: %d ms", performanceData.fps, maxLatency))
        
        -- Color based on performance
        local fpsColor = {1, 0.3, 0.3} -- Red for poor FPS
        if performanceData.fps > 30 then
            fpsColor = {1, 1, 0.3} -- Yellow for acceptable FPS
        end
        if performanceData.fps > 60 then
            fpsColor = {0.3, 1, 0.3} -- Green for good FPS
        end
        
        local latencyColor = {0.3, 1, 0.3} -- Green for low latency
        if maxLatency > 100 then
            latencyColor = {1, 1, 0.3} -- Yellow for medium latency
        end
        if maxLatency > 300 then
            latencyColor = {1, 0.3, 0.3} -- Red for high latency
        end
        
        -- Since we have two values, we'll use a compromise color
        local r = (fpsColor[1] + latencyColor[1]) / 2
        local g = (fpsColor[2] + latencyColor[2]) / 2
        local b = (fpsColor[3] + latencyColor[3]) / 2
        frame.text:SetTextColor(r, g, b)
    end,
    tooltip = function()
        local DataTexts = GetDataTexts()
        if not DataTexts then return end
        
        GameTooltip:SetText("Performance Metrics")
        
        GameTooltip:AddLine(string.format("FPS: %.1f", performanceData.fps), 1, 1, 1)
        GameTooltip:AddLine(string.format("Home Latency: %d ms", performanceData.lagHome), 1, 1, 1)
        GameTooltip:AddLine(string.format("World Latency: %d ms", performanceData.lagWorld), 1, 1, 1)
        
        -- Add performance recommendations
        GameTooltip:AddLine(" ")
        if performanceData.fps < 30 then
            GameTooltip:AddLine("FPS is low. Consider:", 1, 1, 0)
            GameTooltip:AddLine("- Reducing graphics settings", 0.8, 0.8, 0.8)
            GameTooltip:AddLine("- Disabling some addons", 0.8, 0.8, 0.8)
            GameTooltip:AddLine("- Closing other applications", 0.8, 0.8, 0.8)
        elseif performanceData.fps < 60 then
            GameTooltip:AddLine("FPS is acceptable but could be better", 1, 1, 0)
        else
            GameTooltip:AddLine("FPS is good!", 0.3, 1, 0.3)
        end
        
        if performanceData.lagHome > 100 or performanceData.lagWorld > 100 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Latency is high. Consider:", 1, 1, 0)
            GameTooltip:AddLine("- Checking your internet connection", 0.8, 0.8, 0.8)
            GameTooltip:AddLine("- Using a wired connection", 0.8, 0.8, 0.8)
            GameTooltip:AddLine("- Closing bandwidth-intensive applications", 0.8, 0.8, 0.8)
        end
        
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click to open system settings", 0.8, 0.8, 0.8)
    end,
    onClick = function()
        local DataTexts = GetDataTexts()
        if not DataTexts then return end
        
        -- Open appropriate system/performance UI
        local success, errorMessage = pcall(function()
            -- Try modern Settings Panel first (Dragonflight+)
            if Settings and Settings.OpenToCategory then
                Settings.OpenToCategory(Settings.GRAPHICS_CATEGORY_ID)
            elseif SettingsPanel then
                if SettingsPanel:IsShown() then
                    SettingsPanel:Hide()
                else
                    SettingsPanel:Show()
                end
            elseif InterfaceOptionsFrame then
                -- Fallback to older Interface Options
                if InterfaceOptionsFrame:IsShown() then
                    InterfaceOptionsFrame:Hide()
                else
                    InterfaceOptionsFrame:Show()
                    -- Try to switch to Graphics tab
                    if InterfaceOptionsGraphicsPanel then
                        InterfaceOptionsFrame_OpenToCategory(InterfaceOptionsGraphicsPanel)
                    end
                end
            else
                -- Final fallback: Game Menu
                if ToggleGameMenu then
                    ToggleGameMenu()
                end
            end
        end)

        if not success then
            print("Failed to open system settings: " .. tostring(errorMessage))
        end
    end
}

-- Register the performance data text - defer until DataTexts is available
local function RegisterDataText()
    local DataTexts = GetDataTexts()
    if DataTexts then
        DataTexts:RegisterDataText("performance", performanceDataText)
        -- Export an empty module (registration is enough)
        if MiniMapRedux and MiniMapRedux.export then
            MiniMapRedux.export("PerformanceDataText", {})
        end
    else
        -- Try again after a short delay
        C_Timer.After(0.1, RegisterDataText)
    end
end

-- Call register function
RegisterDataText()
