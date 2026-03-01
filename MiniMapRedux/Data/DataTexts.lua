local addonName, _ = ...
local MiniMapRedux = _G.MiniMapRedux

-- DataTexts Module
-- Modular data text system for MiniMapRedux

local DataTexts = {
    texts = {},
    frames = {},
    updateInterval = 1, -- Update every second
}

-- Defer Options import until ADDON_LOADED event
local Options
local function GetOptions()
    if not Options then
        Options = MiniMapRedux.import("Options")
    end
    return Options
end

-- Data text frames storage
local dataTextFrames = {}
local minimapDataTexts = {}
local minimapDataBar = nil

-- Support for up to 10 customizable data bars
local customDataBars = {} -- Stores all custom data bars (1-10)
local customDataTexts = {} -- Stores data texts assigned to each bar

-- Cache addon data to reduce expensive scans
local addonDataCache = {}
local addonCacheTimestamp = 0
local ADDON_CACHE_DURATION = 3 -- Cache addon data for 3 seconds

-- Modern flat backdrop shared by all data bars
local MODERN_BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
}

-- SESSION STATISTICS TRACKING
local sessionStats = {
    startTime = 0,
    startXP = 0,
    startGold = 0,
    startLevel = 0,
    fpsHistory = {},
    latencyHistory = {},
    maxHistorySize = 120, -- Reduced from 300 to 120 (2 minutes at 1-second intervals) - saves ~60% memory
}

-- Initialize session tracking
local function InitializeSessionStats()
    sessionStats.startTime = GetTime()
    sessionStats.startXP = UnitXP("player")
    sessionStats.startGold = GetMoney()
    sessionStats.startLevel = UnitLevel("player")
    sessionStats.fpsHistory = {}
    sessionStats.latencyHistory = {}
end

-- Update session statistics with throttling
local function UpdateSessionStats()
    local now = GetTime()
    local fps = GetFramerate()
    local _, _, lagHome, lagWorld = GetNetStats()
    local maxLatency = math.max(lagHome or 0, lagWorld or 0)

    -- Add to history
    table.insert(sessionStats.fpsHistory, {time = now, value = fps})
    table.insert(sessionStats.latencyHistory, {time = now, value = maxLatency})

    -- Trim history to max size using circular buffer approach (more efficient than table.remove at index 1)
    if #sessionStats.fpsHistory > sessionStats.maxHistorySize then
        -- Remove oldest 10% when limit reached (batch removal more efficient than removing one at a time)
        local removeCount = math.floor(sessionStats.maxHistorySize * 0.1)
        for i = 1, removeCount do
            table.remove(sessionStats.fpsHistory, 1)
        end
    end
    if #sessionStats.latencyHistory > sessionStats.maxHistorySize then
        local removeCount = math.floor(sessionStats.maxHistorySize * 0.1)
        for i = 1, removeCount do
            table.remove(sessionStats.latencyHistory, 1)
        end
    end
end

-- Get session statistics
local function GetSessionStats()
    local currentTime = GetTime()
    local sessionDuration = currentTime - sessionStats.startTime
    local currentXP = UnitXP("player")
    local currentGold = GetMoney()
    local currentLevel = UnitLevel("player")
    
    -- Calculate gains
    local xpGained = 0
    local goldGained = currentGold - sessionStats.startGold
    local levelsGained = currentLevel - sessionStats.startLevel
    
    -- Handle level changes for XP calculation
    if levelsGained > 0 then
        -- Player leveled up, XP calculation is more complex
        xpGained = currentXP + (levelsGained * 1000000) -- Rough estimate
    else
        xpGained = currentXP - sessionStats.startXP
    end
    
    -- Calculate rates (per hour)
    local hoursPlayed = sessionDuration / 3600
    local xpPerHour = hoursPlayed > 0 and (xpGained / hoursPlayed) or 0
    local goldPerHour = hoursPlayed > 0 and (goldGained / hoursPlayed) or 0
    
    -- Calculate performance averages
    local avgFPS = 0
    local minFPS = 999
    local maxFPS = 0
    if #sessionStats.fpsHistory > 0 then
        local total = 0
        for _, entry in ipairs(sessionStats.fpsHistory) do
            total = total + entry.value
            minFPS = math.min(minFPS, entry.value)
            maxFPS = math.max(maxFPS, entry.value)
        end
        avgFPS = total / #sessionStats.fpsHistory
    end
    
    local avgLatency = 0
    local minLatency = 999
    local maxLatency = 0
    if #sessionStats.latencyHistory > 0 then
        local total = 0
        for _, entry in ipairs(sessionStats.latencyHistory) do
            total = total + entry.value
            minLatency = math.min(minLatency, entry.value)
            maxLatency = math.max(maxLatency, entry.value)
        end
        avgLatency = total / #sessionStats.latencyHistory
    end
    
    return {
        duration = sessionDuration,
        xpGained = xpGained,
        goldGained = goldGained,
        levelsGained = levelsGained,
        xpPerHour = xpPerHour,
        goldPerHour = goldPerHour,
        avgFPS = avgFPS,
        minFPS = minFPS == 999 and 0 or minFPS,
        maxFPS = maxFPS,
        avgLatency = avgLatency,
        minLatency = minLatency == 999 and 0 or minLatency,
        maxLatency = maxLatency
    }
end

-- Expose session stats functions to the module
DataTexts.InitializeSessionStats = InitializeSessionStats
DataTexts.GetSessionStats = GetSessionStats

local function GetCachedAddonData()
    local now = GetTime()
    if now - addonCacheTimestamp > ADDON_CACHE_DURATION then
        -- Refresh cache
        addonDataCache = {}
        addonCacheTimestamp = now
        
        -- Enable CPU profiling if not already enabled
        if GetCVar("scriptProfile") ~= "1" then
            SetCVar("scriptProfile", "1")
        end
        
        -- Update addon memory usage data
        UpdateAddOnMemoryUsage()
        UpdateAddOnCPUUsage()
        
        -- Calculate total memory and CPU usage across all addons
        local totalMemory = 0
        local totalCPU = 0
        local addonCount = C_AddOns.GetNumAddOns()
        
        for i = 1, addonCount do
            if C_AddOns.IsAddOnLoaded(i) then
                local memory = GetAddOnMemoryUsage(i)
                local cpu = GetAddOnCPUUsage(i)
                totalMemory = totalMemory + memory
                totalCPU = totalCPU + cpu
            end
        end
        
        addonDataCache.totalMemory = totalMemory
        addonDataCache.totalCPU = totalCPU
    end
    
    return addonDataCache
end

-- Reset CPU usage tracking for more accurate readings
local function ResetCPUUsage()
    -- Reset tracking to get fresh CPU usage data
    UpdateAddOnCPUUsage()
end

-- Available data texts registry
local availableDataTexts = {}

-- Register a data text
function DataTexts:RegisterDataText(key, config)
    -- Debug info
    availableDataTexts[key] = config
    -- Registered data text
    
    -- If we already have data text frames, create them now
    if dataTextFrames[key] then return end
    
    -- Create the frame for this data text using the local function
    local frame = self:CreateDataTextFrame(key, config, UIParent)
    dataTextFrames[key] = frame
    
    -- Hide by default until assigned to a position
    frame:Hide()
    
    -- Force refresh to show the data bar
    C_Timer.After(0.1, function()
        self:RefreshDataTexts()
    end)
end

-- Get available data texts
function DataTexts:GetAvailableDataTexts()
    -- Debug info
    return availableDataTexts
end

-- Debug function to list all registered data texts
function DataTexts:ListRegisteredDataTexts()
    -- Debug info
    local count = 0
    for key, config in pairs(availableDataTexts) do
        count = count + 1
        -- Registered data text
    end
    -- Registered data texts count
    -- Force show first data bar for debugging
    if customDataBars[1] then
        customDataBars[1]:Show()
    else
        -- Try to create first data bar
        local bar = self:CreateCustomDataBar(1)
        if bar then
            bar:Show()
        end
    end
end

-- Create a data text frame
function DataTexts:CreateDataTextFrame(key, config, parent)
    local frame = CreateFrame("Frame", "MiniMapReduxDataText" .. key, parent)
    frame:SetSize(100, 20) -- Default size, will be adjusted
    frame.config = config
    frame.key = key
    
    frame.text = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    frame.text:SetJustifyH("LEFT")
    frame.text:SetJustifyV("MIDDLE")
    
    -- Set default font size based on bar
    local fontSize = 13
    if parent == minimapDataBar then
        fontSize = 15 -- Larger for minimap
    end
    frame.text:SetFont("Interface\\AddOns\\MiniMapRedux\\UI\\Fonts\\BarlowCondensed-Bold.otf", fontSize, "OUTLINE")
    
    -- Set initial text color
    if config.color and type(config.color) == "table" and #config.color > 0 then
        -- Use table.unpack if available, otherwise fall back to unpack or manual unpacking
        if table and table.unpack then
            frame.text:SetTextColor(table.unpack(config.color))
        elseif unpack then
            frame.text:SetTextColor(unpack(config.color))
        else
            -- Manual unpacking for safety
            frame.text:SetTextColor(config.color[1] or 1, config.color[2] or 1, config.color[3] or 1)
        end
    else
        frame.text:SetTextColor(1, 1, 1) -- Default white
    end
    
    -- Icon support - DON'T create icons here, wait for UpdateDataTextIconVisibility
    -- This prevents icons from showing before settings are loaded
    frame.hasIcon = config.icon ~= nil
    
    -- Always position text for no icon initially
    frame.text:SetPoint("LEFT", frame, "LEFT", 2, 0)
    frame.text:SetPoint("RIGHT", frame, "RIGHT", -2, 0)
    
    -- Tooltip support
    frame:EnableMouse(true)
    frame:SetScript("OnEnter", function(self)
        if config.tooltip then
            GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
            config.tooltip()
            GameTooltip:Show()
        end
    end)
    frame:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    -- Click support
    if config.onClick then
        frame:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                config.onClick()
            end
        end)
    end
    
    return frame
end

-- Get current minimap scale
local function GetMinimapScale()
    if Minimap and Minimap.GetScale then
        return Minimap:GetScale()
    elseif Minimap then
        return Minimap:GetEffectiveScale() or 1
    end
    return 1
end

-- Get minimap width (actual visual width)
local function GetMinimapWidth()
    if Minimap then
        -- Return the actual width of the minimap without scaling
        -- This ensures the data bar matches the visual width regardless of scale
        local width = Minimap:GetWidth()
        -- Debug: Print width changes
        -- print("Minimap width: " .. tostring(width))
        return width
    end
    return 140 -- Default minimap width
end

-- Update minimap data bar size to match minimap
function DataTexts:UpdateMinimapDataBarScale()
    if not minimapDataBar then return end

    -- With the new positioning approach, we don't need to manually set width
    -- The data bar will automatically resize with the minimap
    -- Just ensure the positioning is correct
    minimapDataBar:ClearAllPoints()
    minimapDataBar:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", 0, -8)
    minimapDataBar:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", 0, -8)
end

-- Create minimap data bar
local function CreateMinimapDataBar()
    if minimapDataBar then return minimapDataBar end

    -- Create the databar
    minimapDataBar = CreateFrame("Frame", "MiniMapReduxMinimapDataBar", Minimap, BackdropTemplateMixin and "BackdropTemplate")
    
    -- Match the minimap exactly
    minimapDataBar:SetHeight(24)
    minimapDataBar:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", 0, -8)
    minimapDataBar:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", 0, -8)
    minimapDataBar:SetFrameStrata("MEDIUM")
    minimapDataBar:SetFrameLevel(Minimap:GetFrameLevel() + 2)
    
    minimapDataBar:SetBackdrop(MODERN_BACKDROP)
    minimapDataBar:SetBackdropColor(0.05, 0.05, 0.08, 0.85)
    minimapDataBar:SetBackdropBorderColor(0.15, 0.15, 0.15, 0.6)

    -- Make it draggable if not locked
    minimapDataBar:EnableMouse(true)
    minimapDataBar:RegisterForDrag("LeftButton")
    minimapDataBar:SetMovable(true)
    
    -- Special mouse handling for fully transparent bars
    minimapDataBar:SetScript("OnEnter", function(self)
        local opacity = Options:get("minimapDataBarOpacity") or 0.9
        if opacity <= 0 then
            -- Temporarily show a faint outline during mouse hover for zero opacity bars
            if self:GetBackdrop() == nil then
                self:SetBackdrop(MODERN_BACKDROP)
                self:SetBackdropColor(0.05, 0.05, 0.08, 0.1)
                self:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.2)
            end
        end
    end)

    minimapDataBar:SetScript("OnLeave", function(self)
        local opacity = Options:get("minimapDataBarOpacity") or 0.9
        if opacity <= 0 then
            -- Return to fully transparent state
            self:SetBackdrop(nil)
        end
    end)
    
    minimapDataBar:SetScript("OnDragStart", function(self)
        if not GetOptions():get("lockDataBars") then
            self:StartMoving()
        end
    end)
    minimapDataBar:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Save the new position
        local point, relativeTo, relativePoint, x, y = self:GetPoint()
        if point then
            -- Store the position in saved variables
            local Options = GetOptions()
            Options:set("minimapDataBarPosition", {point, relativeTo and relativeTo:GetName() or nil, relativePoint, x, y})
        end
    end)
    
    return minimapDataBar
end

-- Create customizable data bar (supports up to 10 bars)
function DataTexts:CreateCustomDataBar(barNumber)
    -- Debug info
    -- Validate bar number
    if barNumber < 1 or barNumber > 10 then
        return nil
    end
    
    -- Check if bar already exists
    if customDataBars[barNumber] then 
        -- Data bar already exists
        return customDataBars[barNumber]
    end
    
    -- Creating new data bar
    -- Create unique bar name
    local barName = "DataBar" .. barNumber
    local bar = CreateFrame("Frame", "MiniMapRedux" .. barName, UIParent, BackdropTemplateMixin and "BackdropTemplate")
    bar:SetSize(300, 24) -- Will be resized based on content
    bar.barNumber = barNumber -- Store bar number for reference
    
    -- Check if we have a saved position
    local savedPosition = GetOptions():get("DataBar" .. barNumber .. "Position")
    if savedPosition and type(savedPosition) == "table" then
        local point, relativeToName, relativePoint, x, y
        if table and table.unpack then
            point, relativeToName, relativePoint, x, y = table.unpack(savedPosition)
        elseif unpack then
            point, relativeToName, relativePoint, x, y = unpack(savedPosition)
        else
            -- Manual unpacking for safety
            point, relativeToName, relativePoint, x, y = savedPosition[1], savedPosition[2], savedPosition[3], savedPosition[4], savedPosition[5]
        end
        local relativeTo = relativeToName and _G[relativeToName] or UIParent
        bar:SetPoint(point, relativeTo, relativePoint, x, y)
    else
        -- Default positions - stagger them vertically
        local defaultPositions = {
            {"TOPLEFT", UIParent, "TOPLEFT", 32, -192},  -- Bar 1
            {"TOPLEFT", UIParent, "TOPLEFT", 32, -224},  -- Bar 2
            {"TOPLEFT", UIParent, "TOPLEFT", 32, -256},  -- Bar 3
            {"TOPLEFT", UIParent, "TOPLEFT", 32, -288},  -- Bar 4
            {"TOPLEFT", UIParent, "TOPLEFT", 32, -320},  -- Bar 5
            {"TOPLEFT", UIParent, "TOPLEFT", 32, -352},  -- Bar 6
            {"TOPLEFT", UIParent, "TOPLEFT", 32, -384},  -- Bar 7
            {"TOPLEFT", UIParent, "TOPLEFT", 32, -416},  -- Bar 8
            {"TOPLEFT", UIParent, "TOPLEFT", 32, -448},  -- Bar 9
            {"TOPLEFT", UIParent, "TOPLEFT", 32, -480},  -- Bar 10
        }
        -- Use table.unpack if available, otherwise fall back to unpack or manual unpacking
        local pointData = defaultPositions[barNumber]
        if table and table.unpack then
            bar:SetPoint(table.unpack(pointData))
        elseif unpack then
            bar:SetPoint(unpack(pointData))
        else
            -- Manual unpacking for safety
            bar:SetPoint(pointData[1], pointData[2], pointData[3], pointData[4], pointData[5])
        end
    end
    
    bar:SetFrameStrata("MEDIUM")
    bar:SetFrameLevel(10)
    
    bar:SetBackdrop(MODERN_BACKDROP)
    bar:SetBackdropColor(0.05, 0.05, 0.08, 0.85)

    -- Different border colors for each bar to make them distinguishable
    local borderColors = {
        {0.5, 0.5, 1, 0.5},   -- Blue for Bar 1
        {1, 0.5, 0.5, 0.5},   -- Red for Bar 2
        {0.5, 1, 0.5, 0.5},   -- Green for Bar 3
        {1, 1, 0.5, 0.5},     -- Yellow for Bar 4
        {1, 0.5, 1, 0.5},     -- Magenta for Bar 5
        {0.5, 1, 1, 0.5},     -- Cyan for Bar 6
        {1, 0.7, 0.3, 0.5},   -- Orange for Bar 7
        {0.7, 0.3, 1, 0.5},   -- Purple for Bar 8
        {0.3, 1, 0.7, 0.5},   -- Light Green for Bar 9
        {1, 0.3, 0.7, 0.5},   -- Pink for Bar 10
    }
    local colorData = borderColors[barNumber]
    bar:SetBackdropBorderColor(colorData[1], colorData[2], colorData[3], colorData[4])
    
    -- Make it draggable if not locked
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetMovable(true)
    
    -- Special mouse handling for fully transparent bars
    bar:SetScript("OnEnter", function(self)
        local opacity = Options:get("dataBar" .. self.barNumber .. "Opacity") or 0.9
        if opacity <= 0 then
            -- Temporarily show a faint outline during mouse hover for zero opacity bars
            if self:GetBackdrop() == nil then
                self:SetBackdrop(MODERN_BACKDROP)
                self:SetBackdropColor(0.05, 0.05, 0.08, 0.1)

                -- Use appropriate border color
                local borderColors = {
                    {0.5, 0.5, 1, 0.2},   -- Blue for Bar 1
                    {1, 0.5, 0.5, 0.2},   -- Red for Bar 2
                    {0.5, 1, 0.5, 0.2},   -- Green for Bar 3
                    {1, 1, 0.5, 0.2},     -- Yellow for Bar 4
                    {1, 0.5, 1, 0.2},     -- Magenta for Bar 5
                    {0.5, 1, 1, 0.2},     -- Cyan for Bar 6
                    {1, 0.7, 0.3, 0.2},   -- Orange for Bar 7
                    {0.7, 0.3, 1, 0.2},   -- Purple for Bar 8
                    {0.3, 1, 0.7, 0.2},   -- Light Green for Bar 9
                    {1, 0.3, 0.7, 0.2},   -- Pink for Bar 10
                }
                local colorData = borderColors[self.barNumber]
                self:SetBackdropBorderColor(colorData[1], colorData[2], colorData[3], colorData[4])
            end
        end
    end)
    
    bar:SetScript("OnLeave", function(self)
        local opacity = Options:get("dataBar" .. self.barNumber .. "Opacity") or 0.9
        if opacity <= 0 then
            -- Return to fully transparent state
            self:SetBackdrop(nil)
        end
    end)
    
    bar:SetScript("OnDragStart", function(self)
        if not GetOptions():get("lockDataBars") then
            self:StartMoving()
        end
    end)
    bar:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Save the new position
        local point, relativeTo, relativePoint, x, y = self:GetPoint()
        if point then
            -- Store the position in saved variables
            local Options = GetOptions()
            Options:set("DataBar" .. self.barNumber .. "Position", {point, relativeTo and relativeTo:GetName() or nil, relativePoint, x, y})
        end
    end)
    
    -- Add title text for identification
    local titleText = bar:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    titleText:SetPoint("TOP", bar, "TOP", 0, -2)
    titleText:SetText("Data Bar " .. barNumber)
    titleText:SetTextColor(0.8, 0.8, 0.8)
    titleText:SetFont("Interface\\AddOns\\MiniMapRedux\\UI\\Fonts\\BarlowCondensed-Bold.otf", 8, "OUTLINE")
    bar.titleText = titleText
    
    local mover = CreateFrame("Frame", nil, bar, "BackdropTemplate")
    mover:SetSize(12, 12)
    mover:SetPoint("RIGHT", bar, "RIGHT", -4, 0)
    mover:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    mover:SetBackdropColor(1, 0, 0, 0.8)
    mover:SetBackdropBorderColor(0.5, 0, 0, 1)
    mover:EnableMouse(true)
    mover:RegisterForDrag("LeftButton")
    mover:SetScript("OnDragStart", function(self)
        if not GetOptions():get("lockDataBars") then
            bar:StartMoving()
        end
    end)
    mover:SetScript("OnDragStop", function(self)
        bar:StopMovingOrSizing()
        local point, relativeTo, relativePoint, x, y = bar:GetPoint()
        if point then
            local Options = GetOptions()
            Options:set("DataBar" .. bar.barNumber .. "Position", {point, relativeTo and relativeTo:GetName() or nil, relativePoint, x, y})
        end
    end)
    mover:SetScript("OnEnter", function(self)
        self:SetBackdropColor(1, 0.3, 0.3, 1)
    end)
    mover:SetScript("OnLeave", function(self)
        self:SetBackdropColor(1, 0, 0, 0.8)
    end)
    bar.mover = mover
    
    if GetOptions():get("lockDataBars") then
        mover:Hide()
    else
        mover:Show()
    end
    
    -- Store in our tables
    customDataBars[barNumber] = bar
    customDataTexts[barNumber] = {}
    
    -- Debug info - show the bar immediately
    bar:Show()
    -- Created data bar
    
    -- Debug info
    return bar
end

-- Position data texts on a specific bar
function DataTexts:PositionDataTextsOnBar(barNumber)
    local bar = customDataBars[barNumber]
    if not bar or GetOptions():get("showDataBar" .. barNumber) ~= true then return end
    
    local spacing = 8
    local totalWidth = spacing
    local framesToPosition = {}
    
    -- Collect frames that need positioning
    for key, frame in pairs(customDataTexts[barNumber]) do
        if frame:IsShown() then
            table.insert(framesToPosition, frame)
        end
    end
    
    -- Sort frames by key for consistent positioning
    table.sort(framesToPosition, function(a, b)
        return a.key < b.key
    end)
    
    -- Position frames
    local xOffset = spacing
    for _, frame in ipairs(framesToPosition) do
        frame:ClearAllPoints()
        frame:SetPoint("LEFT", bar, "LEFT", xOffset, 0)
        
        -- Calculate proper width based on content
        local textWidth = frame.text:GetStringWidth()
        local frameWidth = textWidth + 4 -- Minimum padding
        
        -- Add icon width if present
        if frame.icon then
            frameWidth = frameWidth + 20 -- Icon width (16) + spacing (4)
        else
            frameWidth = frameWidth + 4 -- Just padding
        end
        
        frame:SetWidth(frameWidth)
        xOffset = xOffset + frameWidth + spacing
        totalWidth = totalWidth + frameWidth + spacing
    end
    
    -- Adjust bar width
    bar:SetWidth(math.max(200, totalWidth))
end

-- Update minimap data bar size to match minimap


-- Position minimap data texts
function DataTexts:PositionMinimapDataTexts()
    if not minimapDataBar or GetOptions():get("showMinimapDataBar") ~= true then return end

    -- Update data bar size to match minimap first
    self:UpdateMinimapDataBarScale()

    local spacing = 8
    local totalWidth = spacing
    local framesToPosition = {}
    
    -- Collect frames that need positioning
    for key, frame in pairs(minimapDataTexts) do
        if frame:IsShown() then
            table.insert(framesToPosition, frame)
        end
    end
    
    -- Sort frames by key for consistent positioning
    table.sort(framesToPosition, function(a, b)
        return a.key < b.key
    end)
    
    -- Position frames
    local xOffset = spacing
    for _, frame in ipairs(framesToPosition) do
        frame:ClearAllPoints()
        frame:SetPoint("LEFT", minimapDataBar, "LEFT", xOffset, 0)
        
        -- Calculate proper width based on content
        local textWidth = frame.text:GetStringWidth()
        local frameWidth = textWidth + 4 -- Minimum padding
        
        -- Add icon width if present
        if frame.icon then
            frameWidth = frameWidth + 20 -- Icon width (16) + spacing (4)
        else
            frameWidth = frameWidth + 4 -- Just padding
        end
        
        frame:SetWidth(frameWidth)
        xOffset = xOffset + frameWidth + spacing
        totalWidth = totalWidth + frameWidth + spacing
    end
    
    -- Adjust bar width
    minimapDataBar:SetWidth(math.max(100, totalWidth))
end

-- Refresh data texts (assign to positions)
function DataTexts:RefreshDataTexts()
    -- Debug info
    -- Check if data bars module is disabled
    if GetOptions():get("disableDataBarsModule") then
        -- Hide all existing frames
        for _, frame in pairs(dataTextFrames) do
            frame:Hide()
        end
        
        -- Hide minimap data bar
        if minimapDataBar then
            minimapDataBar:Hide()
        end
        
        -- Hide custom data bars
        for i = 1, 10 do
            if customDataBars[i] then
                customDataBars[i]:Hide()
            end
        end
        
        return
    end
    
    -- Prevent multiple rapid refreshes
    if self.refreshing then return end
    self.refreshing = true
    
    -- Hide all existing frames first
    for _, frame in pairs(dataTextFrames) do
        frame:Hide()
    end
    
    -- Clear position-specific tables
    table.wipe(minimapDataTexts)
    
    -- Clear all custom data text assignments
    for i = 1, 10 do
        if customDataTexts[i] then
            table.wipe(customDataTexts[i])
        end
    end
    
    local minimapCount = 0
    local barCounts = {}
    
    -- Initialize bar counts
    for i = 1, 10 do
        barCounts[i] = 0
    end
    
    -- Debug info - count available data texts
    local dataTextCount = 0
    for key, config in pairs(availableDataTexts) do
        dataTextCount = dataTextCount + 1
    end
    -- Available data texts count
    
    -- Assign data texts to their positions
    for key, config in pairs(availableDataTexts) do
        local position = GetOptions():get("dataText_" .. key .. "_position") or "DataBar1"
        -- Processing data text
        
        if position ~= "hide" then
            -- Create or reuse frame
            local frame = dataTextFrames[key]
            if not frame then
                frame = self:CreateDataTextFrame(key, config, UIParent)
                dataTextFrames[key] = frame
            end
            
            if position == "minimap" then
                -- Only show if minimap data bar is enabled
                if GetOptions():get("showMinimapDataBar") == true then
                    if not minimapDataBar then
                        CreateMinimapDataBar()
                    end
                    frame:SetParent(minimapDataBar)
                    -- Update frame strata to match new parent
                    frame:SetFrameStrata(minimapDataBar:GetFrameStrata())
                    frame:SetFrameLevel(minimapDataBar:GetFrameLevel() + 1)
                    minimapDataTexts[key] = frame
                    frame:Show()
                    minimapCount = minimapCount + 1
                end
            elseif string.match(position, "DataBar%d+") then
                -- Extract bar number from position string (e.g., "DataBar3" -> 3)
                local barNumber = tonumber(string.match(position, "%d+"))
                if barNumber and barNumber >= 1 and barNumber <= 10 then
                    -- Only show if this specific data bar is enabled
                    if GetOptions():get("showDataBar" .. barNumber) == true then
                        -- Create the bar if it doesn't exist
                        if not customDataBars[barNumber] then
                            self:CreateCustomDataBar(barNumber)
                        end
                        
                        -- Get the bar
                        local bar = customDataBars[barNumber]
                        if bar then
                            frame:SetParent(bar)
                            -- Update frame strata to match new parent
                            frame:SetFrameStrata(bar:GetFrameStrata())
                            frame:SetFrameLevel(bar:GetFrameLevel() + 1)
                            customDataTexts[barNumber][key] = frame
                            frame:Show()
                            barCounts[barNumber] = barCounts[barNumber] + 1
                            -- Assigned data text to bar
                        end
                    end
                end
            end
        end
    end
    
    -- Handle minimap data bar visibility
    -- Create minimap data bar if it doesn't exist and should be shown
    if GetOptions():get("showMinimapDataBar") == true and not minimapDataBar then
        CreateMinimapDataBar()
    end
    
    if minimapDataBar then
        -- Show the bar if the module is enabled and the bar should be shown
        -- Hide the bar if the data bars module is disabled or the specific bar is disabled
        if not GetOptions():get("disableDataBarsModule") and GetOptions():get("showMinimapDataBar") == true then
            minimapDataBar:Show()
        else
            minimapDataBar:Hide()
        end
    end
    
    -- Handle custom data bar visibility and positioning
    for i = 1, 10 do
        -- Create the bar if it doesn't exist and should be shown
        if GetOptions():get("showDataBar" .. i) == true and not customDataBars[i] then
            self:CreateCustomDataBar(i)
        end
        
        local bar = customDataBars[i]
        if bar then
            -- Show the bar if the module is enabled and the bar should be shown
            -- Hide the bar if the data bars module is disabled or the specific bar is disabled
            if not GetOptions():get("disableDataBarsModule") and GetOptions():get("showDataBar" .. i) == true then
                bar:Show()
                self:PositionDataTextsOnBar(i)
                -- Showing data bar
            else
                bar:Hide()
            end
        end
    end
    
    -- Position minimap data texts if bar is visible
    if minimapDataBar and minimapDataBar:IsShown() then
        self:PositionMinimapDataTexts()
    end
    
    -- Update lock states
    self:UpdateDataBarLocks()
    
    -- Force refresh data bar positioning when module is re-enabled
    C_Timer.After(0.01, function()
        if not GetOptions():get("disableDataBarsModule") then
            -- Position all enabled data bars
            for i = 1, 10 do
                if GetOptions():get("showDataBar" .. i) == true and customDataBars[i] then
                    self:PositionDataTextsOnBar(i)
                end
            end
            
            -- Position minimap data bar if enabled
            if GetOptions():get("showMinimapDataBar") == true and minimapDataBar then
                self:PositionMinimapDataTexts()
            end
        end
    end)
    
    -- Apply saved font sizes to all data text frames
    self:UpdateDataBarFontSizes()

    -- Reset refresh flag after a short delay
    C_Timer.After(0.1, function()
        self.refreshing = false
    end)
end

-- Update data text icon visibility
function DataTexts:UpdateDataTextIconVisibility()
    local showIcons = GetOptions():get("showDataTextIcons")
    if showIcons == nil then showIcons = true end -- Default to true
    
    for key, frame in pairs(dataTextFrames) do
        if frame and frame.config and frame.hasIcon then
            local config = frame.config
            
            if showIcons then
                -- Create icon if it doesn't exist
                if not frame.icon then
                    frame.icon = frame:CreateTexture(nil, "ARTWORK")
                    frame.icon:SetSize(16, 16)
                    frame.icon:SetPoint("LEFT", frame, "LEFT", 2, 0)
                    frame.icon:SetTexture(config.icon)
                end
                -- Show existing icon
                frame.icon:Show()
                frame.icon:SetTexture(config.icon)
                -- Position text to the right of the icon
                frame.text:ClearAllPoints()
                frame.text:SetPoint("LEFT", frame.icon, "RIGHT", 4, 0)
                frame.text:SetPoint("RIGHT", frame, "RIGHT", -2, 0)
            else
                -- Hide icons if disabled
                if frame.icon then
                    frame.icon:Hide()
                end
                -- Position text to take full width
                frame.text:ClearAllPoints()
                frame.text:SetPoint("LEFT", frame, "LEFT", 2, 0)
                frame.text:SetPoint("RIGHT", frame, "RIGHT", -2, 0)
            end
        end
    end
    
    -- Reposition all data texts
    self:PositionMinimapDataTexts()
    for i = 1, 10 do
        self:PositionDataTextsOnBar(i)
    end
end

-- Keep UpdateAllDataTexts but simplify it since we're calling it less frequently
function DataTexts:UpdateAllDataTexts()
    -- Update session statistics
    UpdateSessionStats()
    
    for key, frame in pairs(dataTextFrames) do
        if frame:IsShown() and frame.config and frame.config.update then
            frame.config.update(frame)
        end
    end
    
    -- Reduce repositioning frequency even more for better performance
    if math.random(1, 15) == 1 then -- Changed from 10 to 15 (every 15 seconds on average)
        self:PositionMinimapDataTexts()
        
        -- Position data texts on each custom bar
        for i = 1, 10 do
            self:PositionDataTextsOnBar(i)
        end
    end
end

-- Initialize data bars
function DataTexts:Initialize()
    -- Debug info
    
    -- Ensure lockDataBars has a default value
    local Options = GetOptions()
    if Options:get("lockDataBars") == nil then
        Options:set("lockDataBars", false)
    end
    
    -- Ensure first data bar is enabled by default so data texts appear
    if Options:get("showDataBar1") == nil then
        Options:set("showDataBar1", true)
    end
    
    -- Enable minimap data bar by default too
    if Options:get("showMinimapDataBar") == nil then
        Options:set("showMinimapDataBar", true)
    end
    
    -- Enable CPU profiling for performance tracking
    if GetCVar("scriptProfile") ~= "1" then
        SetCVar("scriptProfile", "1")
    end
    
    -- Reset CPU usage tracking periodically for more accurate readings
    -- This can stay as it's not performance intensive
    C_Timer.NewTicker(10, function()
        ResetCPUUsage()
    end)
    
    -- Initialize session statistics tracking
    InitializeSessionStats()
    
    -- Register mail events for immediate updates
    local mailEventFrame = CreateFrame("Frame")
    mailEventFrame:RegisterEvent("MAIL_INBOX_UPDATE")
    mailEventFrame:RegisterEvent("UPDATE_PENDING_MAIL")
    mailEventFrame:RegisterEvent("MAIL_CLOSED")
    mailEventFrame:SetScript("OnEvent", function(self, event, ...)
        -- Update mail data text immediately when mail events occur
        if dataTextFrames.mail and dataTextFrames.mail:IsShown() then
            local config = availableDataTexts.mail
            if config and config.update then
                config.update(dataTextFrames.mail)
            end
        end
    end)
    
    -- Register friends events for immediate updates
    local friendsEventFrame = CreateFrame("Frame")
    friendsEventFrame:RegisterEvent("FRIENDLIST_UPDATE")
    friendsEventFrame:RegisterEvent("BN_FRIEND_LIST_SIZE_CHANGED")
    friendsEventFrame:RegisterEvent("BN_FRIEND_INFO_CHANGED")
    friendsEventFrame:RegisterEvent("BN_FRIEND_ACCOUNT_ONLINE")
    friendsEventFrame:RegisterEvent("BN_FRIEND_ACCOUNT_OFFLINE")
    friendsEventFrame:SetScript("OnEvent", function(self, event, ...)
        -- Update friends data text immediately when friends events occur
        if dataTextFrames.friends and dataTextFrames.friends:IsShown() then
            local config = availableDataTexts.friends
            if config and config.update then
                config.update(dataTextFrames.friends)
            end
        end
    end)
    
    -- Initial refresh
    self:RefreshDataTexts()
    
    -- Apply icon visibility IMMEDIATELY - no delay
    self:UpdateDataTextIconVisibility()
    
    -- Apply icon visibility settings again after short delay to ensure all frames are created
    C_Timer.After(0.1, function()
        self:UpdateDataTextIconVisibility()
    end)
    
    -- Force create first data bar if enabled (ensures it appears)
    if Options:get("showDataBar1") then
        self:CreateCustomDataBar(1)
        self:PositionDataTextsOnBar(1)
    end
    
    -- Add a delayed refresh to ensure all data texts are registered
    C_Timer.After(1.0, function()
        self:RefreshDataTexts()
        -- Reapply icon visibility after delayed refresh
        self:UpdateDataTextIconVisibility()
    end)
end

-- Update data bar lock states
function DataTexts:UpdateDataBarLocks()
    local isLocked = GetOptions():get("lockDataBars")
    
    -- Include minimap data bar in lock system - it is draggable
    if minimapDataBar then
        if isLocked then
            minimapDataBar:SetBackdropBorderColor(0.6, 0.15, 0.15, 0.8) -- Muted red when locked
        else
            minimapDataBar:SetBackdropBorderColor(0.15, 0.15, 0.15, 0.6) -- Subtle gray when unlocked
        end
    end

    -- Update all custom data bars
    for i = 1, 10 do
        local bar = customDataBars[i]
        if bar then
            if isLocked then
                bar:SetBackdropBorderColor(0.6, 0.15, 0.15, 0.8) -- Muted red when locked
                -- Hide title text when locked
                if bar.titleText then
                    bar.titleText:Hide()
                end
                -- Hide mover when locked
                if bar.mover then
                    bar.mover:Hide()
                end
            else
                -- Restore original border color
                local borderColors = {
                    {0.5, 0.5, 1},   -- Blue for Bar 1
                    {1, 0.5, 0.5},   -- Red for Bar 2
                    {0.5, 1, 0.5},   -- Green for Bar 3
                    {1, 1, 0.5},     -- Yellow for Bar 4
                    {1, 0.5, 1},     -- Magenta for Bar 5
                    {0.5, 1, 1},     -- Cyan for Bar 6
                    {1, 0.7, 0.3},   -- Orange for Bar 7
                    {0.7, 0.3, 1},   -- Purple for Bar 8
                    {0.3, 1, 0.7},   -- Light Green for Bar 9
                    {1, 0.3, 0.7},   -- Pink for Bar 10
                }
                local colorData = borderColors[i]
                if colorData then
                    bar:SetBackdropBorderColor(colorData[1], colorData[2], colorData[3], 0.5)
                end
                -- Show title text when unlocked
                if bar.titleText then
                    bar.titleText:Show()
                end
                -- Show mover when unlocked
                if bar.mover then
                    bar.mover:Show()
                end
            end
        end
    end
end

-- Update data bar opacity
function DataTexts:UpdateDataBarOpacity()
    if minimapDataBar then
        local opacity = Options:get("minimapDataBarOpacity")
        if opacity == nil then opacity = 0.9 end
        -- Only change backdrop opacity, not frame alpha to preserve text visibility
        if opacity <= 0 then
            -- Full transparency: hide background and border completely
            minimapDataBar:SetBackdrop(nil)
        else
            -- Normal opacity setting: restore backdrop if needed
            if not minimapDataBar:GetBackdrop() then
                minimapDataBar:SetBackdrop(MODERN_BACKDROP)
            end
            minimapDataBar:SetBackdropColor(0.05, 0.05, 0.08, 0.85 * opacity)
            minimapDataBar:SetBackdropBorderColor(0.15, 0.15, 0.15, 0.6 * opacity)
        end
    end
    
    -- Update all custom data bars
    for i = 1, 10 do
        local bar = customDataBars[i]
        if bar then
            local opacity = Options:get("dataBar" .. i .. "Opacity")
            if opacity == nil then opacity = 0.9 end
            -- Only change backdrop opacity, not frame alpha to preserve text visibility
            if opacity <= 0 then
                -- Full transparency: hide background and border completely
                bar:SetBackdrop(nil)
            else
                -- Normal opacity setting: restore backdrop if needed
                if not bar:GetBackdrop() then
                    bar:SetBackdrop(MODERN_BACKDROP)
                end

                bar:SetBackdropColor(0.05, 0.05, 0.08, 0.85 * opacity)

                -- Restore border color based on lock state
                local isLocked = GetOptions():get("lockDataBars")
                if isLocked then
                    bar:SetBackdropBorderColor(0.6, 0.15, 0.15, 0.8) -- Muted red when locked
                else
                    local borderColors = {
                        {0.5, 0.5, 1},   -- Blue for Bar 1
                        {1, 0.5, 0.5},   -- Red for Bar 2
                        {0.5, 1, 0.5},   -- Green for Bar 3
                        {1, 1, 0.5},     -- Yellow for Bar 4
                        {1, 0.5, 1},     -- Magenta for Bar 5
                        {0.5, 1, 1},     -- Cyan for Bar 6
                        {1, 0.7, 0.3},   -- Orange for Bar 7
                        {0.7, 0.3, 1},   -- Purple for Bar 8
                        {0.3, 1, 0.7},   -- Light Green for Bar 9
                        {1, 0.3, 0.7},   -- Pink for Bar 10
                    }
                    local colorData = borderColors[i]
                    if colorData then
                        bar:SetBackdropBorderColor(colorData[1], colorData[2], colorData[3], 0.5)
                    end
                end
            end
            -- Refresh positioning to account for opacity changes
            self:PositionDataTextsOnBar(i)
        end
    end
end

-- Update data bar font sizes
function DataTexts:UpdateDataBarFontSizes()
    -- Update minimap data bar texts
    for key, frame in pairs(minimapDataTexts) do
        if frame and frame.text then
            local fontSize = GetOptions():get("minimapDataBarFontSize") or 15
            frame.text:SetFont("Interface\\AddOns\\MiniMapRedux\\UI\\Fonts\\BarlowCondensed-Bold.otf", fontSize, "OUTLINE")
        end
    end
    
    -- Update custom data bar texts
    for i = 1, 10 do
        if customDataTexts[i] then
            for key, frame in pairs(customDataTexts[i]) do
                if frame and frame.text then
                    local fontSize = GetOptions():get("dataBar" .. i .. "FontSize") or 13
                    frame.text:SetFont("Interface\\AddOns\\MiniMapRedux\\UI\\Fonts\\BarlowCondensed-Bold.otf", fontSize, "OUTLINE")
                end
            end
        end
        -- Refresh positioning to account for new text sizes
        self:PositionDataTextsOnBar(i)
    end
    
    -- Refresh positioning to account for new text sizes
    self:PositionMinimapDataTexts()
end

-- Initialize function for DataTexts module
function DataTexts:InitializeModule()
    -- Debug info
    -- Ensure lockDataBars has a default value
    local Options = GetOptions()
    if Options:get("lockDataBars") == nil then
        Options:set("lockDataBars", false)
    end
    
    -- Ensure first data bar is enabled by default so data texts appear
    if Options:get("showDataBar1") == nil then
        Options:set("showDataBar1", true)
    end
    
    -- Enable minimap data bar by default too
    if Options:get("showMinimapDataBar") == nil then
        Options:set("showMinimapDataBar", true)
    end
    
    -- Enable CPU profiling for performance tracking
    if GetCVar("scriptProfile") ~= "1" then
        SetCVar("scriptProfile", "1")
    end
    
    -- Reset CPU usage tracking periodically for more accurate readings
    C_Timer.NewTicker(10, function()
        ResetCPUUsage()
    end)
    
    -- Initialize session statistics tracking
    InitializeSessionStats()
    
    -- Add a delayed re-initialization to ensure it's properly set
    C_Timer.After(2, function()
        if sessionStats.startTime == 0 then
            InitializeSessionStats()
        end
    end)
    
    -- Register mail events for immediate updates
    local mailEventFrame = CreateFrame("Frame")
    mailEventFrame:RegisterEvent("MAIL_INBOX_UPDATE")
    mailEventFrame:RegisterEvent("UPDATE_PENDING_MAIL")
    mailEventFrame:RegisterEvent("MAIL_CLOSED")
    mailEventFrame:SetScript("OnEvent", function(self, event, ...)
        -- Update mail data text immediately when mail events occur
        if dataTextFrames.mail and dataTextFrames.mail:IsShown() then
            local config = availableDataTexts.mail
            if config and config.update then
                config.update(dataTextFrames.mail)
            end
        end
    end)
    
    -- Register friends events for immediate updates
    local friendsEventFrame = CreateFrame("Frame")
    friendsEventFrame:RegisterEvent("FRIENDLIST_UPDATE")
    friendsEventFrame:RegisterEvent("BN_FRIEND_LIST_SIZE_CHANGED")
    friendsEventFrame:RegisterEvent("BN_FRIEND_INFO_CHANGED")
    friendsEventFrame:RegisterEvent("BN_FRIEND_ACCOUNT_ONLINE")
    friendsEventFrame:RegisterEvent("BN_FRIEND_ACCOUNT_OFFLINE")
    friendsEventFrame:SetScript("OnEvent", function(self, event, ...)
        -- Update friends data text immediately when friends events occur
        if dataTextFrames.friends and dataTextFrames.friends:IsShown() then
            local config = availableDataTexts.friends
            if config and config.update then
                config.update(dataTextFrames.friends)
            end
        end
    end)
    
    -- Initial refresh
    self:RefreshDataTexts()
    
    -- Force create first data bar if enabled (ensures it appears)
    if Options:get("showDataBar1") then
        self:CreateCustomDataBar(1)
        self:PositionDataTextsOnBar(1)
    end
    
    -- Add a delayed refresh to ensure all data texts are registered
    C_Timer.After(1.0, function()
        self:RefreshDataTexts()
    end)
    
    -- Add another delayed refresh to ensure all data texts are registered
    C_Timer.After(2.0, function()
        self:RefreshDataTexts()
    end)
    
    -- Add a final refresh to ensure everything is set up
    C_Timer.After(3.0, function()
        self:RefreshDataTexts()
        -- Force show the first data bar
        if Options:get("showDataBar1") and customDataBars[1] then
            customDataBars[1]:Show()
            self:PositionDataTextsOnBar(1)
        end
    end)
    
    -- Debug info
end

-- Force show enabled data bars (for use when re-enabling module)
function DataTexts:ForceShowEnabledBars()
    -- Force show the first data bar if enabled
    if GetOptions():get("showDataBar1") == true and customDataBars[1] then
        customDataBars[1]:Show()
        self:PositionDataTextsOnBar(1)
    end

    -- Force show minimap data bar if enabled
    if GetOptions():get("showMinimapDataBar") == true then
        if not minimapDataBar then
            CreateMinimapDataBar()
        end
        if minimapDataBar then
            minimapDataBar:Show()
            self:PositionMinimapDataTexts()
        end
    end
end

-- Export the DataTexts module - defer until MiniMapRedux is available
local function ExportModule()
    if MiniMapRedux and MiniMapRedux.export then
        MiniMapRedux.export("DataTexts", DataTexts)
    else
        -- Try again after a short delay
        C_Timer.After(0.1, ExportModule)
    end
end

-- Call export function
ExportModule()
