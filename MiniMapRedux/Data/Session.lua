local addonName, _ = ...
local MiniMapRedux = _G.MiniMapRedux

-- Session Data Text Module
local DataTexts
local function GetDataTexts()
    if not DataTexts and MiniMapRedux and MiniMapRedux.import then
        DataTexts = MiniMapRedux.import("DataTexts")
    end
    return DataTexts
end

-- Local storage for session data
local sessionData = {
    duration = 0,
    xpGained = 0,
    goldGained = 0,
    levelsGained = 0,
    xpPerHour = 0,
    goldPerHour = 0,
    avgFPS = 0,
    minFPS = 0,
    maxFPS = 0,
    avgLatency = 0,
    minLatency = 0,
    maxLatency = 0,
    currenciesGained = {} -- Track all currencies gained this session
}

-- Currency tracking
local startCurrencies = {} -- Currency amounts at session start

-- Function to initialize tracked currencies (scan currencies player has)
local function InitializeTrackedCurrencies()
    startCurrencies = {}

    -- Check if currency API is available (not in Classic Era)
    if not C_CurrencyInfo or not C_CurrencyInfo.GetCurrencyListSize then
        return
    end

    -- Get all currency IDs from the player's currency list (covers all visible currencies)
    local currencyList = C_CurrencyInfo.GetCurrencyListSize()
    for i = 1, currencyList do
        local currencyInfo = C_CurrencyInfo.GetCurrencyListInfo(i)
        if currencyInfo and not currencyInfo.isHeader and currencyInfo.currencyTypesID and currencyInfo.currencyTypesID > 0 then
            startCurrencies[currencyInfo.currencyTypesID] = currencyInfo.quantity or 0
        end
    end
end

-- Function to update currency gains
local function UpdateCurrencyGains()
    sessionData.currenciesGained = {}

    -- Check if currency API is available (not in Classic Era)
    if not C_CurrencyInfo or not C_CurrencyInfo.GetCurrencyListSize then
        return
    end

    -- Scan current currencies from the player's currency list
    local currentCurrencies = {}
    local currencyList = C_CurrencyInfo.GetCurrencyListSize()

    for i = 1, currencyList do
        local currencyInfo = C_CurrencyInfo.GetCurrencyListInfo(i)
        if currencyInfo and not currencyInfo.isHeader and currencyInfo.currencyTypesID and currencyInfo.currencyTypesID > 0 then
            currentCurrencies[currencyInfo.currencyTypesID] = {
                quantity = currencyInfo.quantity or 0,
                name = currencyInfo.name,
                icon = currencyInfo.iconFileID,
                quality = currencyInfo.quality
            }
        end
    end

    -- Compare current with starting amounts
    for currencyID, startAmount in pairs(startCurrencies) do
        local current = currentCurrencies[currencyID]
        if current then
            local gained = current.quantity - startAmount

            if gained ~= 0 then
                table.insert(sessionData.currenciesGained, {
                    id = currencyID,
                    name = current.name,
                    gained = gained,
                    icon = current.icon,
                    quality = current.quality
                })
            end
        end
    end

    -- Check for new currencies gained during session (weren't there at start)
    for currencyID, current in pairs(currentCurrencies) do
        if not startCurrencies[currencyID] and current.quantity > 0 then
            table.insert(sessionData.currenciesGained, {
                id = currencyID,
                name = current.name,
                gained = current.quantity,
                icon = current.icon,
                quality = current.quality
            })
        end
    end

    -- Sort by absolute amount gained (most gained first)
    table.sort(sessionData.currenciesGained, function(a, b)
        return math.abs(a.gained) > math.abs(b.gained)
    end)
end

-- Function to format money amounts (copper to gold/silver/copper)
local function FormatMoney(amount)
    if not amount or amount == 0 then return "0|cffeda55fc|r" end
    
    local absAmount = math.abs(amount)
    local gold = math.floor(absAmount / 10000)
    local silver = math.floor((absAmount % 10000) / 100)
    local copper = absAmount % 100
    
    local moneyString = ""
    local sign = amount < 0 and "-" or ""
    
    if gold > 0 then
        moneyString = moneyString .. string.format("%s%d|cffffd700g|r ", sign, gold)
        sign = "" -- Only show sign once
    end
    if silver > 0 or gold > 0 then
        moneyString = moneyString .. string.format("%s%d|cffc7c7cfs|r ", sign, silver)
        sign = ""
    end
    moneyString = moneyString .. string.format("%s%d|cffeda55fc|r", sign, copper)
    
    return moneyString
end

-- Function to refresh session data with error handling
local function RefreshSessionData()
    local DataTexts = GetDataTexts()
    if not DataTexts then return end
    
    local success, errorMessage = pcall(function()
        -- Get session stats from DataTexts module
        if DataTexts.GetSessionStats then
            local sessionStatsSuccess, sessionStats = pcall(function() return DataTexts:GetSessionStats() end)
            if sessionStatsSuccess and sessionStats then
                sessionData.duration = sessionStats.duration or 0
                sessionData.xpGained = sessionStats.xpGained or 0
                sessionData.goldGained = sessionStats.goldGained or 0
                sessionData.levelsGained = sessionStats.levelsGained or 0
                sessionData.xpPerHour = sessionStats.xpPerHour or 0
                sessionData.goldPerHour = sessionStats.goldPerHour or 0
                sessionData.avgFPS = sessionStats.avgFPS or 0
                sessionData.minFPS = sessionStats.minFPS or 0
                sessionData.maxFPS = sessionStats.maxFPS or 0
                sessionData.avgLatency = sessionStats.avgLatency or 0
                sessionData.minLatency = sessionStats.minLatency or 0
                sessionData.maxLatency = sessionStats.maxLatency or 0
            else
                -- Reset to default values
                sessionData.duration = 0
                sessionData.xpGained = 0
                sessionData.goldGained = 0
                sessionData.levelsGained = 0
                sessionData.xpPerHour = 0
                sessionData.goldPerHour = 0
                sessionData.avgFPS = 0
                sessionData.minFPS = 0
                sessionData.maxFPS = 0
                sessionData.avgLatency = 0
                sessionData.minLatency = 0
                sessionData.maxLatency = 0
            end
        end
    end)
    
    if not success then
        print("Session data refresh failed: " .. tostring(errorMessage))
        sessionData.duration = 0
        sessionData.xpGained = 0
        sessionData.goldGained = 0
        sessionData.levelsGained = 0
        sessionData.xpPerHour = 0
        sessionData.goldPerHour = 0
        sessionData.avgFPS = 0
        sessionData.minFPS = 0
        sessionData.maxFPS = 0
        sessionData.avgLatency = 0
        sessionData.minLatency = 0
        sessionData.maxLatency = 0
    end
end

-- Event frame for session updates
local sessionEventFrame = CreateFrame("Frame")
sessionEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
sessionEventFrame:RegisterEvent("PLAYER_LEVEL_UP")
sessionEventFrame:RegisterEvent("CURRENCY_DISPLAY_UPDATE") -- Track currency changes
sessionEventFrame:SetScript("OnEvent", function(self, event, ...)
    local DataTexts = GetDataTexts()
    if DataTexts then
        if event == "PLAYER_ENTERING_WORLD" then
            -- Initialize session stats when player enters world
            C_Timer.After(1, function() -- Delay to ensure DataTexts is fully initialized
                InitializeTrackedCurrencies()
                RefreshSessionData()
            end)
        elseif event == "PLAYER_LEVEL_UP" then
            -- Increment levels gained when player levels up
            sessionData.levelsGained = sessionData.levelsGained + 1
        elseif event == "CURRENCY_DISPLAY_UPDATE" then
            -- Update currency tracking when currencies change
            UpdateCurrencyGains()
        end
    end
end)

-- Timer to periodically update session data
C_Timer.NewTicker(1, function()
    local DataTexts = GetDataTexts()
    if DataTexts then
        RefreshSessionData()
    end
end)

-- Add a safety check to ensure session stats are initialized
C_Timer.After(5, function()
    local DataTexts = GetDataTexts()
    if DataTexts and sessionData.duration == 0 then
        RefreshSessionData()
    end
end)

local sessionDataText = {
    name = "Session",
    color = {0.3, 0.8, 1}, -- Light Blue
    icon = "Interface\\Icons\\Achievement_BG_winWSG", -- Session icon
    update = function(frame)
        local DataTexts = GetDataTexts()
        if not DataTexts then return end

        local hours = math.floor(sessionData.duration / 3600)
        local minutes = math.floor((sessionData.duration % 3600) / 60)

        -- Format time string
        local timeString
        if hours > 0 then
            timeString = string.format("%dh %dm", hours, minutes)
        else
            timeString = string.format("%dm", minutes)
        end

        -- Build display with gold if any gained/lost
        local displayText = timeString
        if sessionData.goldGained ~= 0 then
            local absGold = math.abs(sessionData.goldGained)
            local gold = math.floor(absGold / 10000)
            local silver = math.floor((absGold % 10000) / 100)
            local sign = sessionData.goldGained < 0 and "-" or "+"
            local goldColor = sessionData.goldGained > 0 and "|cff00ff00" or "|cffff4444"

            if gold > 0 then
                displayText = displayText .. "  " .. goldColor .. sign .. gold .. "|cffffd700g|r"
            elseif silver > 0 then
                displayText = displayText .. "  " .. goldColor .. sign .. silver .. "|cffc7c7cfs|r"
            end
        end

        frame.text:SetText(displayText)
        frame.text:SetTextColor(0.3, 0.8, 1) -- Light Blue
    end,
    tooltip = function()
        local DataTexts = GetDataTexts()
        if not DataTexts then return end
        
        GameTooltip:SetText("Session Statistics")
        
        -- Session duration
        local hours = math.floor(sessionData.duration / 3600)
        local minutes = math.floor((sessionData.duration % 3600) / 60)
        local seconds = math.floor(sessionData.duration % 60)
        
        GameTooltip:AddLine(string.format("Session Time: %02d:%02d:%02d", hours, minutes, seconds), 1, 1, 1)
        
        -- XP Gains
        if sessionData.xpGained > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Experience Gained:", 0.8, 0.8, 0.8)
            GameTooltip:AddLine(string.format("  Total: %d", sessionData.xpGained), 1, 1, 1)
            if sessionData.xpPerHour > 0 then
                GameTooltip:AddLine(string.format("  Rate: %.0f/hour", sessionData.xpPerHour), 1, 1, 1)
            end
            if sessionData.levelsGained > 0 then
                GameTooltip:AddLine(string.format("  Levels: +%d", sessionData.levelsGained), 0.3, 1, 0.3)
            end
        end
        
        -- Gold Gains
        if sessionData.goldGained ~= 0 then
            local goldColor = sessionData.goldGained > 0 and {0.3, 1, 0.3} or {1, 0.3, 0.3}
            local goldSign = sessionData.goldGained > 0 and "+" or "-"

            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Gold:", 0.8, 0.8, 0.8)
            GameTooltip:AddLine(string.format("  Total: %s%s", goldSign, FormatMoney(math.abs(sessionData.goldGained))), goldColor[1], goldColor[2], goldColor[3])
            if sessionData.goldPerHour ~= 0 then
                local goldPerHourSign = sessionData.goldPerHour > 0 and "+" or "-"
                GameTooltip:AddLine(string.format("  Rate: %s%s/hour", goldPerHourSign, FormatMoney(math.abs(sessionData.goldPerHour))), 1, 1, 1)
            end
        end
        
        -- Currencies Gained
        if sessionData.currenciesGained and #sessionData.currenciesGained > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Currencies Gained:", 0.8, 0.8, 0.8)
            
            for _, currency in ipairs(sessionData.currenciesGained) do
                local color = currency.gained > 0 and {0.3, 1, 0.3} or {1, 0.3, 0.3}
                local sign = currency.gained > 0 and "+" or ""
                
                -- Format with icon if available
                local displayText = string.format("  %s: %s%d", currency.name, sign, currency.gained)
                GameTooltip:AddLine(displayText, color[1], color[2], color[3])
            end
        end
        
        -- Performance Stats
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Performance:", 0.8, 0.8, 0.8)
        
        -- FPS
        if sessionData.avgFPS > 0 then
            local fpsColor = sessionData.avgFPS > 30 and {0.3, 1, 0.3} or 
                            sessionData.avgFPS > 15 and {1, 1, 0.3} or {1, 0.3, 0.3}
            GameTooltip:AddLine(string.format("  FPS: Avg %.1f, Min %d, Max %d", 
                sessionData.avgFPS, sessionData.minFPS, sessionData.maxFPS), 
                fpsColor[1], fpsColor[2], fpsColor[3])
        end
        
        -- Latency
        if sessionData.avgLatency > 0 then
            local latencyColor = sessionData.avgLatency < 100 and {0.3, 1, 0.3} or 
                               sessionData.avgLatency < 300 and {1, 1, 0.3} or {1, 0.3, 0.3}
            GameTooltip:AddLine(string.format("  Latency: Avg %.0fms, Min %dms, Max %dms", 
                sessionData.avgLatency, sessionData.minLatency, sessionData.maxLatency), 
                latencyColor[1], latencyColor[2], latencyColor[3])
        end
        
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click to reset session stats", 0.8, 0.8, 0.8)
    end,
    onClick = function()
        local DataTexts = GetDataTexts()
        if not DataTexts then return end
        
        -- Reset session stats with error handling
        local success, errorMessage = pcall(function()
            if DataTexts.InitializeSessionStats then
                DataTexts:InitializeSessionStats()
                -- Reset currency tracking
                InitializeTrackedCurrencies()
                sessionData.currenciesGained = {}
                
                -- Force an immediate update
                if DataTexts.ticker then
                    DataTexts.ticker:Cancel()
                    DataTexts.ticker = C_Timer.NewTicker(DataTexts.updateInterval, function()
                        DataTexts:UpdateAllDataTexts()
                    end)
                end
                -- Refresh session data immediately
                C_Timer.After(0.1, function()
                    RefreshSessionData()
                end)
            end
        end)
        
        if not success then
            print("Failed to reset session stats: " .. tostring(errorMessage))
        end
    end
}

-- Register the session data text - defer until DataTexts is available
local function RegisterDataText()
    local DataTexts = GetDataTexts()
    if DataTexts then
        DataTexts:RegisterDataText("session", sessionDataText)
        -- Export an empty module (registration is enough)
        if MiniMapRedux and MiniMapRedux.export then
            MiniMapRedux.export("SessionDataText", {})
        end
    else
        -- Try again after a short delay
        C_Timer.After(0.1, RegisterDataText)
    end
end

-- Call register function
RegisterDataText()