-- ButtonManager - v10 (Memory optimized: table reuse patterns, reduced allocations)
local frame = CreateFrame("Frame")
local addonName, _ = ...
local MiniMapRedux = _G.MiniMapRedux

MiniMapRedux.buttonInfo = {}

local wipe = table.wipe
local unpack = table.unpack
local GetTime = GetTime
local MouseIsOver = MouseIsOver
local C_Timer = C_Timer

local VERSION_COUNTER = 1
local UPDATE_INTERVAL = 1
local BUTTON_BAR_CHECK_INTERVAL = 0.5  -- Increased from 0.2 to 0.5 (less CPU usage)
local BORDER_CHECK_INTERVAL = 5
local CACHE_DURATION = 0.15  -- Increased from 0.1 to 0.15 (better caching)

-- Cache frequently accessed data
local mouseOverCache = {}
local cacheTimestamp = 0

-- Cache frequently accessed options to reduce table lookups
local optionsCache = {}
local optionsCacheTime = 0
local OPTIONS_CACHE_DURATION = 0.25  -- Cache options for 250ms

-- Table reuse pools to reduce memory allocations
local childrenTablePool = {}
local sortTablePool = {}

-- String interning for commonly used strings (reduces memory duplication)
local internedStrings = {
    Unknown = "Unknown",
    Addon = "Addon",
    Blizzard = "Blizzard",
    UNKNOWN = "UNKNOWN",
    Minimap = "Minimap",
    MinimapCluster = "MinimapCluster",
}

-- Helper functions for table pool management
local function GetPooledTable(pool)
    local tbl = table.remove(pool)
    if tbl then
        wipe(tbl)
        return tbl
    end
    return {}
end

local function ReturnPooledTable(pool, tbl)
    if tbl and #pool < 5 then  -- Limit pool size to 5 tables
        wipe(tbl)
        table.insert(pool, tbl)
    end
end

local masterTimer = 0

local isCollecting = false
local collectionTimer = nil

local autoHideUpdateTimer = nil
local blizzardAutoHideUpdateTimer = nil

local hideTimer = nil
local blizzardHideTimer = nil

local function fade(self, elapsed)
    self.timer = self.timer - elapsed
    if self.timer <= 0 then
        self:SetScript("OnUpdate", nil)
        self:SetAlpha(self.endAlpha)
        if self.endAlpha == 0 then
            self:Hide()
        end
    else
        self:SetAlpha(self.endAlpha - self.deltaAlpha * self.timer)
    end
end

local function frameFade(self, delay, endAlpha)
    if not self or not self.SetAlpha then return end
    self.timer = delay
    self.endAlpha = endAlpha
    self.deltaAlpha = (endAlpha - self:GetAlpha()) / delay
    self:SetScript("OnUpdate", fade)
end

local function frameFadeStop(self, alpha)
    if not self or not self.SetAlpha then return end
    self:SetScript("OnUpdate", nil)
    self:SetAlpha(alpha)
end

-- Button collection retry mechanism
local collectionRetryTimer = nil
local collectionAttempts = 0
local MAX_COLLECTION_ATTEMPTS = 3  -- Reduced from 5 to 3 (less retry overhead)

-- Global scan throttling (expensive operation)
local globalScanCounter = 0
local GLOBAL_SCAN_INTERVAL = 5  -- Only do full _G scan every 5th collection

local ButtonCollection = {
    collectedButtons = {},
    processedButtons = {},
    buttonTypes = {},
}

local function ExportButtonCollection()
    if MiniMapRedux and MiniMapRedux.export then
        local success, err = pcall(function()
            MiniMapRedux.export("ButtonCollection", ButtonCollection)
        end)
        
        if not success then
        end
    else
        C_Timer.After(0.1, ExportButtonCollection)
    end
end

local Options
local function GetOptions()
    if not Options and MiniMapRedux and MiniMapRedux.import then
        Options = MiniMapRedux.import("Options")
    end
    return Options
end

-- Cached option getter for frequently accessed options (reduces table lookups)
local function GetCachedOption(key)
    local now = GetTime()
    if now - optionsCacheTime > OPTIONS_CACHE_DURATION then
        -- Cache expired, clear it
        for k in pairs(optionsCache) do
            optionsCache[k] = nil
        end
        optionsCacheTime = now
    end

    if optionsCache[key] == nil then
        local options = GetOptions()
        if options then
            optionsCache[key] = options:get(key)
        end
    end

    return optionsCache[key]
end

local function ShouldStayOnMinimap(buttonName)
    local options = GetOptions()
    if not options or not buttonName then return false end

    if buttonName:match("Mail") or buttonName == "MinimapClusterIndicatorFrameMailFrame" then
        return options:get("showMailIcon")
    end

    if buttonName:match("CraftingOrder") then
        return options:get("showCraftingOrderIcon")
    end

    if buttonName:match("InstanceDifficulty") or buttonName:match("GuildInstanceDifficulty") or
       buttonName:match("ChallengeMode") then
        return options:get("showInstanceDifficulty")
    end

    if buttonName == "ExpansionLandingPageMinimapButton" or buttonName == "GarrisonLandingPageMinimapButton" then
        return options:get("showMissionsButton")
    end

    if buttonName == "GameTimeFrame" then
        return options:get("showCalendarButton")
    end

    if buttonName == "AddonCompartmentFrame" then
        return options:get("showAddonCompartment")
    end

    if buttonName:match("ZoomIn") or buttonName:match("ZoomOut") then
        return options:get("showZoomButtons")
    end

    return false
end

local isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
local isClassicEra = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
-- Mists of Pandaria Classic = 14
-- Other classic variants: TBC, Wrath, Cata use their own WOW_PROJECT constants

local ButtonIdentification = {
    blizzardButtons = {
        GameTimeFrame = "Calendar",
        MinimapClusterCalendar = "Calendar",
        CalendarButtonFrame = "Calendar",

        TimeManagerClockButton = "Clock",
        MinimapClusterClock = "Clock",

        MinimapTracking = "Tracking",
        MinimapClusterTracking = "Tracking",
        MiniMapTracking = "Tracking",
        MinimapClusterTrackingButton = "Tracking",
        MiniMapTrackingFrame = "Tracking",
        MinimapTrackingFrame = "Tracking",
        MinimapBackdrop = "Tracking",
        MinimapClusterIndicatorFrame = "Tracking",

        QueueStatusButton = "Queue",
        QueueStatusMinimapButton = "Queue",
        MiniMapLFGFrame = "Queue",
        MinimapQueueFrame = "Queue",
        EyeTemplate = "Queue",

        MinimapToggleButton = "Map",
        MiniMapWorldMapButton = "Map",
        MinimapClusterWorldMap = "Map",

        MiniMapCraftingOrderFrame = "Crafting",

        AddonCompartmentFrame = "AddonCompartment",
        MinimapClusterAddonCompartment = "AddonCompartment",

        -- Social
        QuickJoinToastButton = "Social",
        QuickJoinFrame = "Social",
        MinimapClusterSocialButton = "Social",

        -- Ping
        MinimapPingFrame = "Ping",
        MinimapPing = "Ping",

        -- Widgets
        UIWidgetBelowMinimapContainerFrame = "Widget",
        UIWidgetTopCenterContainerFrame = "Widget",

        -- Instance Difficulty (NOTE: These are intentionally excluded - should stay visible on minimap)
        -- MiniMapInstanceDifficulty = "Difficulty",  -- Excluded - stays on minimap
        -- MinimapClusterInstanceDifficulty = "Difficulty",  -- Excluded - stays on minimap
        -- GuildInstanceDifficulty = "Difficulty",  -- Excluded - stays on minimap
        -- MiniMapChallengeMode = "Difficulty",  -- Excluded - stays on minimap

        -- Classic Era/Vanilla specific
        MiniMapBattlefieldFrame = "PvP", -- Battleground queue (Classic)
        MiniMapTrackingIcon = "Tracking", -- Classic tracking icon
        MiniMapTrackingBackground = "Tracking", -- Classic tracking background

        -- TBC/Wrath/Cata/MoP Classic specific (additional frames not in Retail)
        MiniMapVoiceChatFrame = "VoiceChat", -- Voice chat button (TBC+)
        MiniMapRecordingButton = "Recording", -- Recording button (all versions)

        -- Zoom Controls
        MinimapZoomIn = "Zoom",
        MinimapZoomOut = "Zoom",
        MinimapZoomHitArea = "Zoom",

        -- Zone Text
        MinimapZoneTextButton = "Zone",
        MinimapZoneText = "Zone",
        MinimapClusterZoneTextButton = "Zone",

        -- Minimap Container (Beta/Future)
        MinimapClusterMinimapContainer = "Container",
        MinimapContainer = "Container",

        -- Border Elements
        MinimapClusterBorderTop = "Border",
        MinimapBorderTop = "Border",

        -- Expansion Landing Pages
        ExpansionLandingPageMinimapButton = "Expansion",
        GarrisonLandingPageMinimapButton = "Expansion",
        OrderHallCommandBar = "Expansion",

        -- Future-proof: Account Banker (Patch 11.0.0+)
        MinimapAccountBankerButton = "Banker"
    },
    
    buttonPatterns = {
        -- LibDataBroker icons (current and future versions)
        "^LibDBIcon%d+_",

        -- Generic minimap button patterns
        "MinimapButton",
        "MinimapFrame",
        "MinimapIcon",
        "[-_]Minimap[-_]",
        "Minimap$",

        -- Expansion-specific landing pages (future-proof)
        "Summary.*Button$",
        "^Khaz.*Summary.*Button",
        "LandingPage.*Minimap",
        "Report.*Button$",

        -- Common addon patterns
        "^Cell",
        "^Kaliel",
        "^Quazzi",
        "^WeakAuras",
        "Tracker.*Button",

        -- Future Blizzard frames
        "^MiniMap.*Frame$",
        "^Minimap.*Button$",
        "^MinimapCluster.*Button$",
        "UI.*Button",
        "Widget.*Minimap",

        -- Crafting/Professional services (TWW+)
        "Craft.*Order.*Button",
        "Profession.*Button",

        -- Account-wide features (11.0.0+)
        "Account.*Button"
    }
}

function ButtonCollection:isButtonCollected(button)
    -- Safely get the button name, handling cases where GetName might not exist
    local name
    if button.GetName and type(button.GetName) == "function" then
        name = button:GetName()
    else
        -- If GetName method doesn't exist, try to get name from the global namespace
        for globalName, globalValue in pairs(_G) do
            if globalValue == button and type(globalName) == "string" then
                name = globalName
                break
            end
        end
    end
    
    return name and self.processedButtons[name]
end

function ButtonCollection:addButton(button, buttonType)
    if not button then return end
    
    -- Safely get the button name, handling cases where GetName might not exist
    local name
    if button.GetName and type(button.GetName) == "function" then
        name = button:GetName()
    else
        -- If GetName method doesn't exist, try to get name from the global namespace
        for globalName, globalValue in pairs(_G) do
            if globalValue == button and type(globalName) == "string" then
                name = globalName
                break
            end
        end
        
        -- If still no name, create a unique identifier
        if not name then
            name = "UnnamedButton_" .. tostring(button):gsub("table: ", ""):gsub("userdata: ", "")
        end
    end
    
    if not name or self.processedButtons[name] then return end

    table.insert(self.collectedButtons, button)
    self.processedButtons[name] = true
    self.buttonTypes[name] = buttonType
end

function ButtonCollection:restore(restoreBlizzardButtons)
    -- If restoreBlizzardButtons is nil, restore all buttons (default behavior)
    -- If restoreBlizzardButtons is false, only restore addon buttons and keep blizzard buttons collected
    local options = GetOptions()
    local shouldRestoreBlizzardButtons = restoreBlizzardButtons
    if shouldRestoreBlizzardButtons == nil then
        shouldRestoreBlizzardButtons = true
    end
    
    for _, button in ipairs(self.collectedButtons) do
        -- Check if this is a blizzard button
        local isBlizzardButton = false
        local buttonName = "Unknown"
        if button.GetName and type(button.GetName) == "function" then
            buttonName = button:GetName() or "Unknown"
        else
            -- If GetName method doesn't exist, try to get name from the global namespace
            for globalName, globalValue in pairs(_G) do
                if globalValue == button and type(globalName) == "string" then
                    buttonName = globalName
                    break
                end
            end
        end
        
        if ButtonIdentification and ButtonIdentification.blizzardButtons and 
           ButtonIdentification.blizzardButtons[buttonName] then
            isBlizzardButton = true
        end
        
        -- If we should restore blizzard buttons or this is not a blizzard button, restore it
        if shouldRestoreBlizzardButtons or not isBlizzardButton then
            if button.minimapimousOriginal then
                local orig = button.minimapimousOriginal

                button:SetParent(orig.parent)
                button:SetScale(orig.scale)
                if button.SetFrameStrata then
                    button:SetFrameStrata(orig.strata)
                end
                if button.SetFrameLevel then
                    button:SetFrameLevel(orig.level)
                end
                
                button:ClearAllPoints()
                for _, pointData in ipairs(orig.points) do
                    -- Use table.unpack if available, otherwise fall back to unpack or manual unpacking
                    local point, relativeTo, relativePoint, x, y
                    if table and table.unpack then
                        point, relativeTo, relativePoint, x, y = table.unpack(pointData)
                    elseif unpack then
                        point, relativeTo, relativePoint, x, y = unpack(pointData)
                    else
                        -- Manual unpacking for safety
                        point, relativeTo, relativePoint, x, y = pointData[1], pointData[2], pointData[3], pointData[4], pointData[5]
                    end
                    button:SetPoint(point, relativeTo, relativePoint, x, y)
                end
                
                button.minimapimousOriginal = nil
            end
            
            -- Restore original minimap button visibility
            if button.minimapOriginalInfo then
                button:SetAlpha(button.minimapOriginalInfo.alpha or 1)
                button:EnableMouse(button.minimapOriginalInfo.mouseEnabled ~= false)
                if button.minimapOriginalInfo.shown then
                    button:Show()
                else
                    button:Hide()
                end
                button.minimapOriginalInfo = nil
            end
            
            -- Restore original tooltip scripts if they were stored
            if button.minimapOriginalTooltipScripts then
                if button.minimapOriginalTooltipScripts.OnEnter then
                    button:SetScript("OnEnter", button.minimapOriginalTooltipScripts.OnEnter)
                end
                if button.minimapOriginalTooltipScripts.OnLeave then
                    button:SetScript("OnLeave", button.minimapOriginalTooltipScripts.OnLeave)
                end
                button.minimapOriginalTooltipScripts = nil
            end
            
            -- Restore original Show function if it was hooked (for UIWidgetBelowMinimapContainerFrame)
            if button.minimapReduxOriginalShow then
                button.Show = button.minimapReduxOriginalShow
                button.minimapReduxOriginalShow = nil
                button.minimapReduxHideHooked = nil
            end
        end
    end
    self:clear()
end

function ButtonCollection:clear()
    wipe(self.collectedButtons)
    wipe(self.processedButtons)
    wipe(self.buttonTypes)
end

function ButtonIdentification:isValidFrame(frame)
    if type(frame) ~= "table" then return false end
    if not frame.IsObjectType or type(frame.IsObjectType) ~= "function" then return false end
    
    -- Safely call IsObjectType with pcall
    local success, isFrame = pcall(function() return frame:IsObjectType("Frame") end)
    if not success or not isFrame then return false end
    
    return true
end

function ButtonIdentification:isTomCatsButton(frameName)
    return frameName:match("^TomCats%-") ~= nil
end

function ButtonIdentification:nameEndsWithNumber(frameName)
    return frameName:match("%d$") ~= nil
end

function ButtonIdentification:nameMatchesButtonPattern(frameName)
    for _, pattern in ipairs(self.buttonPatterns) do
        if frameName:match(pattern) then
            return true
        end
    end
    return false
end

function ButtonIdentification:identifyButton(button)
    if not button then return nil end
    
    local name = button:GetName() or ""

    if GetOptions():get("whitelist") and GetOptions():get("whitelist")[name] then
        return "Addon"
    end
    
    if name:match("^Khaz.*Summary") or name:match("Summary.*Button$") then
        return "Addon"
    end
    
    -- Check if this is the tracking button and if we should move it
    if self.blizzardButtons[name] == "Tracking" then
        -- Always collect tracking buttons regardless of the moveTrackingButton setting
        -- The setting should control visibility, not collection
        return "Tracking"
    end
    
    if self.blizzardButtons[name] then
        return self.blizzardButtons[name]
    end
    
    if name:find("^LibDBIcon") then
        return "Addon"
    end
    
    if name ~= "" and not name:find("^Minimap") and not name:find("^MinimapCluster") then
        if not self:nameEndsWithNumber(name) or self:isTomCatsButton(name) then
            if self:nameMatchesButtonPattern(name) then
                return "Addon"
            end
        end
    end

    return nil
end

-- Forward declarations for functions that need to be exported
local UpdateBarVisibility, PositionButtons, CreateButtonBar, CollectMinimapButtons
local StartAutoHideUpdates, StopAutoHideUpdates, HideAllMinimapButtons, CheckBarVisibility

-- Export functions that need to be accessible from other modules - defer until MiniMapRedux is available
local function ExportModule()
    if MiniMapRedux and MiniMapRedux.export then
        local success, err = pcall(function()
            MiniMapRedux.export("ButtonManager", {
                UpdateBarVisibility = UpdateBarVisibility,
                PositionButtons = PositionButtons,
                CreateButtonBar = CreateButtonBar,
                CollectMinimapButtons = CollectMinimapButtons,
                StartAutoHideUpdates = StartAutoHideUpdates,
                StopAutoHideUpdates = StopAutoHideUpdates,
                HideAllMinimapButtons = HideAllMinimapButtons
            })
        end)
        
        if not success then
            -- Silent error handling
        end
        
        local success2, err2 = pcall(function()
            MiniMapRedux.export('ButtonIdentification', ButtonIdentification)
        end)
        
        if not success2 then
            -- Silent error handling
        end
        
        local success3, err3 = pcall(function()
            MiniMapRedux.export('ButtonCollection', ButtonCollection)
        end)
        
        if not success3 then
            -- Silent error handling
        end
    else
        -- Try again after a short delay
        C_Timer.After(0.1, ExportModule)
    end
end

-- Export will be called at the end of the file after all functions are defined


-- Optimized mouse over cache to reduce expensive MouseIsOver calls
local function GetCachedMouseIsOver(frame)
    -- Check if frame is a valid object with required methods
    if not frame or type(frame) ~= "table" then
        return false
    end
    
    -- Additional validation to ensure frame is actually a UI frame with proper methods
    if not frame.IsMouseOver or type(frame.IsMouseOver) ~= "function" then
        -- If frame doesn't have IsMouseOver method, check if it's a valid frame type
        local frameType = frame.GetObjectType and frame:GetObjectType()
        if not frameType or (frameType ~= "Frame" and frameType ~= "Button" and frameType ~= "CheckButton" and frameType ~= "StatusBar") then
            return false
        end
        
        -- If it's a valid frame type but missing IsMouseOver, try alternative methods
        if not frame.IsMouseOver then
            -- Try to use MouseIsOver function if available
            if MouseIsOver and type(MouseIsOver) == "function" then
                local success, result = pcall(MouseIsOver, frame)
                if success then
                    return result
                else
                    return false
                end
            else
                return false
            end
        end
    end
    
    local now = GetTime()
    if now - cacheTimestamp > CACHE_DURATION then
        wipe(mouseOverCache)
        cacheTimestamp = now
    end
    
    local frameKey = tostring(frame)
    if mouseOverCache[frameKey] == nil then
        -- Use pcall to safely call IsMouseOver and handle any errors
        local success, result = pcall(function() 
            return frame:IsMouseOver()
        end)
        
        if success then
            mouseOverCache[frameKey] = result
        else
            -- If there's an error calling IsMouseOver, default to false
            mouseOverCache[frameKey] = false
        end
    end
    return mouseOverCache[frameKey]
end

-- Throttle expensive operations using C_Timer
local function ThrottleOperation(func, interval)
    local timer
    return function()
        if timer then
            timer:Cancel()
        end
        timer = C_Timer.NewTimer(interval, function()
            func()
            timer = nil
        end)
    end
end

local buttonCategories = {
    ADDON = { priority = 1, color = {0.3, 1, 0.8}, name = "Addons" },
    BLIZZARD = { priority = 2, color = {0.8, 0.8, 1}, name = "Blizzard" },
    TOOL = { priority = 3, color = {1, 0.8, 0.3}, name = "Tools" },
    UNKNOWN = { priority = 4, color = {0.7, 0.7, 0.7}, name = "Other" }
}

local highPriorityButtons = {
    -- Tracking
    "MiniMapTrackingFrame",

    -- Calendar & Clock
    "GameTimeFrame",
    "TimeManagerClockButton",

    -- Mail (Excluded - stays on minimap)
    -- "MiniMapMailFrame",

    -- Crafting Orders (NEW in TWW/Midnight)
    "MiniMapCraftingOrderFrame",

    -- Queue/LFG
    "QueueStatusMinimapButton",
    -- "MiniMapLFGFrame", -- Excluded - visual container, not a clickable button
    "EyeTemplate",

    -- Widgets
    "UIWidgetBelowMinimapContainerFrame",
    "UIWidgetTopCenterContainerFrame",

    -- Instance Difficulty (Excluded - stays on minimap)
    -- "MiniMapInstanceDifficulty",
    -- "MinimapClusterInstanceDifficulty",
    -- "GuildInstanceDifficulty",
    -- "MiniMapChallengeMode",

    -- Expansion Landing Pages
    "ExpansionLandingPageMinimapButton",
    "GarrisonLandingPageMinimapButton",

    -- Social
    "QuickJoinToastButton",

    -- Addon Compartment
    "AddonCompartmentFrame",

    -- Account Banker (11.0.0+)
    "MinimapAccountBankerButton",

    -- Classic Era/Vanilla specific (EXCLUDED - visual elements, not buttons)
    -- "MiniMapBattlefieldFrame", -- Battleground queue icon (excluded)
    -- "MiniMapTrackingIcon", -- Classic tracking icon (excluded)
    -- "MiniMapTrackingBackground", -- Classic tracking background (excluded)

    -- TBC/Wrath/Cata/MoP Classic specific
    "MiniMapVoiceChatFrame", -- Voice chat button
    "MiniMapRecordingButton" -- Recording button
}

local function CategorizeButton(button)
    if not button then return "UNKNOWN" end
    
    -- Check if button is actually a frame with GetName method
    if type(button) ~= "table" or not button.GetName or not button.GetParent then
        return "UNKNOWN"
    end
    
    local name = button:GetName() or ""
    local parent = button:GetParent()
    
    for _, priorityName in ipairs(highPriorityButtons) do
        if name == priorityName then
            return "BLIZZARD"
        end
    end
    
    if name:match("^MiniMap") or name:match("^GameTime") or name:match("^Queue") then
        return "BLIZZARD"
    end
    
    if name:match("Tool") or name:match("Util") or name:match("Helper") then
        return "TOOL"
    end
    
    if parent and parent ~= Minimap and parent ~= UIParent then
        return "ADDON"
    end
    
    return "ADDON"
end

local function ShowEnhancedButtonTooltip(button)
    if not button then return end
    
    -- Check if button is actually a frame with required methods
    if type(button) ~= "table" or not button.GetName then
        return
    end
    
    local rawName = button:GetName() or "Unknown Button"
    local displayName = rawName
    
    -- Clean up LibDBIcon names to show friendly addon names
    if rawName:match("^LibDBIcon10_") then
        displayName = rawName:gsub("^LibDBIcon10_", "")
        
        -- Handle common addon name patterns
        if displayName == "WeakAuras" then
            displayName = "WeakAuras"
        elseif displayName == "Bartender4" then
            displayName = "Bartender"
        elseif displayName == "BugSack" then
            displayName = "BugSack"
        elseif displayName:match("^Cell") then
            displayName = "Cell"
        elseif displayName:match("^Kaliel") then
            displayName = "Kaliel's Tracker"
        elseif displayName:match("^Quazzi") then
            displayName = "QuazziUI"
        end
    elseif rawName == "GameTimeFrame" then
        displayName = "Calendar"
    elseif rawName == "TimeManagerClockButton" then
        displayName = "Clock"
    elseif rawName == "MinimapCluster_Tracking" or rawName:match("Track") then
        displayName = "Tracking"
    elseif rawName == "AddonCompartmentFrame" then
        displayName = "Addon Compartment"
    elseif rawName == "ExpansionLandingPageMinimapButton" then
        displayName = "Khaz Algar Summary"
    elseif rawName:match("Mail") then
        displayName = "Mail"
    elseif rawName:match("Queue") then
        displayName = "Group Finder"
    end
    
    -- Show simple, clean tooltip
    GameTooltip:SetOwner(button, "ANCHOR_LEFT")
    GameTooltip:SetText(displayName, 1, 1, 1)
    GameTooltip:AddLine("Click to use", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end

-- Auto-hide update management
StartAutoHideUpdates = function()
    if autoHideUpdateTimer then
        autoHideUpdateTimer:Cancel()
    end
    
    local function UpdateLoop()
        if GetCachedOption("hideButtonBar") then
            -- Call the visibility check directly without triggering the start/stop logic
            CheckBarVisibility()
            autoHideUpdateTimer = C_Timer.NewTimer(BUTTON_BAR_CHECK_INTERVAL, UpdateLoop)
        else
            autoHideUpdateTimer = nil
        end
    end
    
    UpdateLoop()
end

StopAutoHideUpdates = function()
    if autoHideUpdateTimer then
        autoHideUpdateTimer:Cancel()
        autoHideUpdateTimer = nil
    end
    
    -- Also cancel any pending hide timer
    if hideTimer then
        hideTimer:Cancel()
        hideTimer = nil
    end
end

-- Enhanced bar visibility checking with timer-based hiding
CheckBarVisibility = function()
    if not MiniMapRedux.buttonBar or not GetCachedOption("hideButtonBar") then
        return
    end

    local shouldShow = false

    -- Check if mouse is over minimap or button bar first (most common cases)
    if GetCachedMouseIsOver(Minimap) or GetCachedMouseIsOver(MiniMapRedux.buttonBar) then
        shouldShow = true
    else
        -- Only check buttons if mouse not over minimap/bar (less frequent)
        local buttons = MiniMapRedux.collectedAddonButtons
        if buttons then
            for _, button in ipairs(buttons) do
                if button and GetCachedMouseIsOver(button) then
                    shouldShow = true
                    break
                end
            end
        end
    end
    
    if shouldShow then
        -- Cancel any pending hide timer
        if hideTimer then
            hideTimer:Cancel()
            hideTimer = nil
        end
        
        -- Show and fade in the bar
        if not MiniMapRedux.buttonBar:IsShown() then
            MiniMapRedux.buttonBar:Show()
            frameFadeStop(MiniMapRedux.buttonBar, 1)
        else
            frameFadeStop(MiniMapRedux.buttonBar, 1)
        end
    else
        -- Start hide timer if not already running
        if not hideTimer and MiniMapRedux.buttonBar:IsShown() then
            hideTimer = C_Timer.NewTimer(0.75, function() -- 0.75 second delay like HidingBar
                hideTimer = nil
                if MiniMapRedux.buttonBar:IsShown() then
                    frameFade(MiniMapRedux.buttonBar, 0.3, 0) -- 0.3 second fade to fully transparent
                end
            end)
        end
    end
end

UpdateBarVisibility = function()
    -- Check if button bar module is disabled
    if GetCachedOption("disableButtonBarModule") then
        if MiniMapRedux.buttonBar then
            MiniMapRedux.buttonBar:Hide()
        end
        StopAutoHideUpdates()
        return
    end

    -- Check if button collection is disabled
    if not GetCachedOption("hideButtons") then
        if MiniMapRedux.buttonBar then
            MiniMapRedux.buttonBar:Hide()
        end
        StopAutoHideUpdates()
        return
    end

    if not MiniMapRedux.buttonBar then return end

    local hideButtonBar = GetCachedOption("hideButtonBar")
    
    -- Start or stop auto-hide updates based on setting
    if hideButtonBar and not autoHideUpdateTimer then
        StartAutoHideUpdates()
    elseif not hideButtonBar and autoHideUpdateTimer then
        StopAutoHideUpdates()
    end
    
    if hideButtonBar then
        -- Use the internal check function for auto-hide mode
        CheckBarVisibility()
    else
        -- Always show in non-auto-hide mode
        -- Cancel any pending hide timer
        if hideTimer then
            hideTimer:Cancel()
            hideTimer = nil
        end
        
        MiniMapRedux.buttonBar:Show()
        frameFadeStop(MiniMapRedux.buttonBar, 1)
        local buttons = MiniMapRedux.collectedAddonButtons
        if buttons then
            for _, button in ipairs(buttons) do
                -- Check if button is actually a frame with Show method before calling it
                if button and type(button) == "table" and button.Show then
                    button:Show()
                end
            end
        end
    end
end

PositionButtons = function(buttonList, bar)
    if not buttonList or not bar then return 0 end
    
    -- Get customization options
    local Options = GetOptions()
    local buttonSize = Options and Options:get("buttonBarButtonSize") or 26
    local backgroundOpacity = Options and Options:get("buttonBarBackgroundOpacity") or 85
    local orientation = Options and Options:get("buttonBarOrientation") or "VERTICAL"
    
    local padding = 6 -- Padding between buttons
    local minimapHeight = Minimap:GetHeight() * (Options and Options:get("minimapScale") or 1)
    local minimapWidth = Minimap:GetWidth() * (Options and Options:get("minimapScale") or 1)
    
    local totalButtons = #buttonList
    local barWidth, actualBarHeight
    local maxButtonsPerRow, buttonsPerRow, rowsNeeded
    local maxButtonsPerColumn, buttonsPerColumn, columnsNeeded
    
    if orientation == "HORIZONTAL" then
        -- Horizontal orientation: buttons arranged in rows
        local availableWidth = minimapWidth - (padding * 2)
        local buttonWithPadding = buttonSize + padding
        maxButtonsPerRow = math.max(1, math.floor(availableWidth / buttonWithPadding))
        rowsNeeded = math.ceil(totalButtons / maxButtonsPerRow)
        buttonsPerRow = math.ceil(totalButtons / rowsNeeded)
        
        -- Calculate dynamic bar dimensions for horizontal
        barWidth = math.min(totalButtons, maxButtonsPerRow) * buttonWithPadding + padding
        actualBarHeight = (buttonSize * rowsNeeded) + (padding * (rowsNeeded + 1))
    else
        -- Vertical orientation: buttons arranged in columns (default)
        local availableHeight = minimapHeight - (padding * 2)
        local buttonWithPadding = buttonSize + padding
        maxButtonsPerColumn = math.max(1, math.floor(availableHeight / buttonWithPadding))
        columnsNeeded = math.ceil(totalButtons / maxButtonsPerColumn)
        buttonsPerColumn = math.ceil(totalButtons / columnsNeeded)
        
        -- Calculate dynamic bar dimensions for vertical
        barWidth = (buttonSize * columnsNeeded) + (padding * (columnsNeeded + 1))
        actualBarHeight = math.min(totalButtons, maxButtonsPerColumn) * buttonWithPadding + padding
    end
    
    -- Ensure minimum dimensions for visibility
    barWidth = math.max(barWidth, buttonSize + padding)
    actualBarHeight = math.max(actualBarHeight, buttonSize + padding * 2)
    
    -- Update bar size dynamically
    bar:SetSize(barWidth, actualBarHeight)
    
    -- Update background opacity if it changed
    local alpha = backgroundOpacity / 100
    if alpha > 0 then
        if not bar.SetBackdrop then
            -- Re-add backdrop if it was removed
            bar:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true,
                tileSize = 16,
                edgeSize = 12,
                insets = {left = 4, right = 4, top = 4, bottom = 4}
            })
        end
        bar:SetBackdropColor(0.05, 0.05, 0.1, alpha * 0.85)
        bar:SetBackdropBorderColor(0.3, 0.6, 1, alpha * 0.8)
    elseif alpha == 0 then
        bar:SetBackdrop(nil)
    end
    
    for i, button in ipairs(buttonList) do
        -- Check if button is actually a frame with required methods
        if type(button) ~= "table" or not button.GetParent or not button.SetParent or not button.ClearAllPoints then
            -- Skip non-frame objects
            -- Skip non-frame objects
        elseif not button.SetScript then
            -- Skip frames that don't support scripts
            -- Skip frames that don't support scripts
        else
            if not button.minimapimousOriginal then
                -- Store original button properties
                local origWidth, origHeight = button:GetSize()
                button.minimapimousOriginal = {
                    parent = button.GetParent and button:GetParent() or nil,
                    points = {},
                    scale = button.GetScale and button:GetScale() or 1,
                    strata = button.GetFrameStrata and button:GetFrameStrata() or "MEDIUM",
                    level = button.GetFrameLevel and button:GetFrameLevel() or 1,
                    width = origWidth,
                    height = origHeight
                }

                if button.GetNumPoints then
                    for j = 1, button:GetNumPoints() do
                        local point, relativeTo, relativePoint, x, y = button:GetPoint(j)
                        table.insert(button.minimapimousOriginal.points, {point, relativeTo, relativePoint, x, y})
                    end
                end
            end

            -- Calculate scale based on original size (HidingBar approach)
            local origWidth = button.minimapimousOriginal.width or buttonSize
            local origHeight = button.minimapimousOriginal.height or buttonSize
            local maxOrigSize = origWidth > origHeight and origWidth or origHeight

            -- Safety check: some frames have 0 size, skip scaling them or use default scale
            if maxOrigSize == 0 or maxOrigSize ~= maxOrigSize then -- Check for zero or NaN
                maxOrigSize = buttonSize
            end

            local scale = buttonSize / maxOrigSize

            local xOffset, yOffset

            if orientation == "HORIZONTAL" then
                -- Horizontal layout: rows from left to right, then down
                local row = math.floor((i - 1) / buttonsPerRow)
                local col = (i - 1) % buttonsPerRow
                xOffset = padding + (col * (buttonSize + padding)) + (buttonSize / 2)
                yOffset = -(padding + (row * (buttonSize + padding)) + (buttonSize / 2))
            else
                -- Vertical layout: columns from top to bottom, then right
                local column = math.floor((i - 1) / buttonsPerColumn)
                local row = (i - 1) % buttonsPerColumn
                xOffset = padding + (column * (buttonSize + padding)) + (buttonSize / 2)
                yOffset = -(padding + (row * (buttonSize + padding)) + (buttonSize / 2))
            end

            -- Move button to the bar and position using CENTER anchor (HidingBar approach)
            button:SetParent(bar)
            button:ClearAllPoints()
            button:SetPoint("CENTER", bar, "TOPLEFT", xOffset, yOffset)

            -- Use SetScale instead of SetSize for proper proportional sizing (Classic compatibility)
            button:SetScale(scale)

            -- SetFrameLevel may not be available on all frame types (especially in Classic)
            if button.SetFrameLevel then
                button:SetFrameLevel(bar:GetFrameLevel() + i) -- Unique frame level per button to prevent overlap
            end
            -- SetFrameStrata may not be available on all frame types (especially in Classic)
            if button.SetFrameStrata then
                button:SetFrameStrata("HIGH")
            end
            
            -- Store original tooltip scripts to prevent errors
            if not button.minimapOriginalTooltipScripts then
                button.minimapOriginalTooltipScripts = {
                    OnEnter = button:GetScript("OnEnter"),
                    OnLeave = button:GetScript("OnLeave")
                }
            end
            
            -- Override tooltip scripts for buttons that have issues (like ExpansionLandingPageMinimapButton)
            local buttonName = button:GetName()
            if buttonName == "ExpansionLandingPageMinimapButton" or buttonName == "UIWidgetBelowMinimapContainerFrame" then
                -- Replace with safe tooltip handlers
                button:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
                    local tooltipText = self.tooltipText or self:GetName() or "Button"
                    GameTooltip:SetText(tooltipText, 1, 1, 1)
                    GameTooltip:Show()
                end)
                button:SetScript("OnLeave", function(self)
                    GameTooltip:Hide()
                end)
            end
            
            -- Ensure button is visible and interactive in the button bar
            button:Show()
            button:SetAlpha(1)
            button:EnableMouse(true)
            
            -- Only try to enable clicks if the button supports it
            if button.SetMouseClickEnabled then
                local success = pcall(function() button:SetMouseClickEnabled(true) end)
                if not success then
                    -- Click enabling not supported for this button
                end
            end
            
            -- Ensure button maintains original click behavior
            if button.SetScript then
                -- Don't override existing click handling - just ensure button is interactive
                -- The original scripts should remain intact for proper functionality
                
                -- Only re-register clicks if the button doesn't already have proper registration
                if button.RegisterForClicks then
                    local success = pcall(function() 
                        -- Use standard click registration that most buttons expect
                        button:RegisterForClicks("LeftButtonUp", "RightButtonUp") 
                    end)
                end
            end
            
            -- Ensure the button is responsive to mouse events (if supported)
            if button.SetHitRectInsets then
                local success = pcall(function() button:SetHitRectInsets(0, 0, 0, 0) end)
                if not success then
                    -- Hit rect not supported
                end
            end
            
            if button.SetClipsChildren then
                local success = pcall(function() button:SetClipsChildren(false) end)
                if not success then
                    -- Clips children not supported
                end
            end
            
            -- Button is already shown above, no need to call Show() again

            -- Don't override button tooltips - let the original addon handle them
            -- This preserves the detailed tooltip information from each addon button
            
            local category = CategorizeButton(button)
            local categoryInfo = buttonCategories[category] or buttonCategories.UNKNOWN
            
            if not button.categoryBorder and button.CreateFrame then
                button.categoryBorder = CreateFrame("Frame", nil, button, BackdropTemplateMixin and "BackdropTemplate")
                button.categoryBorder:SetAllPoints(button)
                if button.categoryBorder.SetFrameLevel and button.GetFrameLevel then
                    button.categoryBorder:SetFrameLevel(button:GetFrameLevel() - 1)
                end
                button.categoryBorder:SetBackdrop({
                    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                    edgeSize = 2,
                    insets = {left = 1, right = 1, top = 1, bottom = 1}
                })
            end
            
            if button.categoryBorder then
                button.categoryBorder:SetBackdropBorderColor(categoryInfo.color[1], categoryInfo.color[2], categoryInfo.color[3], 0.8)
            end
        end
    end
    
    UpdateBarVisibility()
    
    return #buttonList
end

-- Function to scan minimap elements (debug output removed for cleaner chat)
local function DebugScanMinimapElements()
    -- Silent scanning for internal use only
end

-- Function to aggressively hide all minimap buttons
HideAllMinimapButtons = function()
    if not GetOptions():get("hideButtons") then return end
    
    -- Run debug scan first
    DebugScanMinimapElements()
    
    -- Hide all children of Minimap and MinimapCluster that look like buttons or backgrounds
    local function forceHideElement(element)
        if not element then return end
        
        local name = "unknown"
        if element.GetName then
            local success, result = pcall(function() return element:GetName() end)
            if success and result then
                name = result
            end
        end
        
        -- Skip essential minimap elements and our own button bar
        if name:match("MiniMapReduxButtonBar") or name:match("MiniMapRedux") then
            return
        end
        
        -- Skip the minimap itself, cluster, and essential minimap parts
        if name == "Minimap" or name == "MinimapCluster" then
            return
        end
        
        -- Only hide specific background elements that cause visual issues
        local hideableBackgrounds = {"MinimapCluster.BorderTop", "BorderTop", "MinimapBorder", "MinimapClusterBorder"}
        local shouldHide = false
        
        for _, bg in ipairs(hideableBackgrounds) do
            if name:find(bg) then
                shouldHide = true
                break
            end
        end
        
        if not shouldHide then
            return -- Don't hide this element
        end
        
        -- Hide the problematic background element
        if element.Hide then
            local success = pcall(function() element:Hide() end)
            if success then
                -- Hiding background element
            end
        end
    end
    
    -- Don't force-hide Minimap children - let the collection process handle them properly
    -- This prevents hiding essential Blizzard UI elements like mail, calendar, etc.
    -- Preserving Blizzard UI elements
    
    -- Hide collected buttons and problematic background elements
    if MinimapCluster then
        -- Always hide the background border that causes the bar at the top
        if MinimapCluster.BorderTop then
            forceHideElement(MinimapCluster.BorderTop)
        end
        
        local children = {MinimapCluster:GetChildren()}
        -- Checking MinimapCluster children
        for _, child in ipairs(children) do
            if child and child.GetName then
                local name = child:GetName() or "unknown"
                -- Hide collected buttons and the tracking button specifically
                if child == MinimapCluster.Tracking then
                    -- Hide tracking button since it's collected
                    forceHideElement(child)
                else
                    -- Check if this child was collected
                    for _, collectedButton in ipairs(ButtonCollection.collectedButtons) do
                        if child == collectedButton then
                            forceHideElement(child)
                            break
                        end
                    end
                end
            end
        end
    end
    
    -- Only target the specific background element that causes visual issues
    -- Don't force-hide buttons since the collection process handles them properly
    
    -- Hide the background border that causes the bar at the top
    if MinimapCluster and MinimapCluster.BorderTop then
        if MinimapCluster.BorderTop.Hide then
            MinimapCluster.BorderTop:Hide()
            -- Hiding background border
        end
    end
    
    -- Also check for other potential background elements
    local backgroundsToHide = {
        "MinimapClusterBorder",
        "MinimapBorder", 
        "MinimapClusterBackground"
    }
    
    for _, bgName in ipairs(backgroundsToHide) do
        local bgElement = _G[bgName]
        if bgElement and bgElement.Hide then
            bgElement:Hide()
            -- Hiding background element
        end
    end
    
    -- Also try the old variations in case they exist
    local trackingButtons = {
        "MinimapTracking",
        "MinimapClusterTracking", 
        "MiniMapTracking",
        "MinimapClusterTrackingButton",
        "MiniMapTrackingButton",
        "MiniMapTrackingFrame"
    }
    
    for _, buttonName in ipairs(trackingButtons) do
        local button = _G[buttonName]
        if button then
            forceHideElement(button)
            -- Hiding tracking button variation
        end
    end
    
    -- Hide background elements that create rectangular backgrounds
    local backgroundElements = {
        "TimeManagerClockTicker",
        "GameTimeCalendarInvitesTexture", 
        "GameTimeCalendarEventAlarmTexture",
        "MinimapCluster"
    }
    
    for _, elementName in ipairs(backgroundElements) do
        local element = _G[elementName]
        if element then
            -- Don't hide MinimapCluster itself, just check for background textures
            if elementName ~= "MinimapCluster" then
                forceHideElement(element)
            else
                -- For MinimapCluster, hide any background textures
                local bgTextures = {"bg", "Bg", "BG", "background", "Background", "backdrop", "Backdrop"}
                for _, bgName in ipairs(bgTextures) do
                    local bgElement = element[bgName]
                    if bgElement then
                        forceHideElement(bgElement)
                    end
                end
            end
        end
    end
end

CreateButtonBar = function()
    if MiniMapRedux.buttonBar then
        -- Update existing bar with new settings
        local Options = GetOptions()
        local buttonSize = Options and Options:get("buttonBarButtonSize") or 26
        local backgroundOpacity = Options and Options:get("buttonBarBackgroundOpacity") or 85
        
        -- Update background opacity
        local alpha = backgroundOpacity / 100
        if alpha > 0 then
            if not MiniMapRedux.buttonBar.SetBackdrop then
                -- Re-add backdrop if it was removed
                MiniMapRedux.buttonBar:SetBackdrop({
                    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                    tile = true,
                    tileSize = 16,
                    edgeSize = 12,
                    insets = {left = 4, right = 4, top = 4, bottom = 4}
                })
            end
            MiniMapRedux.buttonBar:SetBackdropColor(0.05, 0.05, 0.1, alpha * 0.85)
            MiniMapRedux.buttonBar:SetBackdropBorderColor(0.3, 0.6, 1, alpha * 0.8)
        elseif alpha == 0 then
            MiniMapRedux.buttonBar:SetBackdrop(nil)
        end
        
        return MiniMapRedux.buttonBar
    end
    
    -- Create the button bar frame (MiniMapReduxButtonBar) - collects and organizes minimap buttons
    local bar = CreateFrame("Frame", "MiniMapReduxButtonBar", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    
    -- Get customization options
    local Options = GetOptions()
    local buttonSize = Options and Options:get("buttonBarButtonSize") or 26
    local backgroundOpacity = Options and Options:get("buttonBarBackgroundOpacity") or 85
    
    -- Dynamic sizing - will be updated when buttons are positioned
    local padding = 8
    local barWidth = buttonSize + padding
    bar:SetSize(barWidth, 100) -- Height will be dynamically updated
    
    -- Set background opacity (0-100 converted to 0.0-1.0)
    local alpha = backgroundOpacity / 100
    
    if alpha > 0 then
        bar:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 12,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        bar:SetBackdropColor(0.05, 0.05, 0.1, alpha * 0.85)
        bar:SetBackdropBorderColor(0.3, 0.6, 1, alpha * 0.8)
    else
        -- No background - buttons only
        bar:SetBackdrop(nil)
    end
    bar:SetFrameStrata("MEDIUM")
    bar:SetFrameLevel(Minimap:GetFrameLevel() + 2) -- Lower level so buttons can be above it
    
    bar:EnableMouse(true)
    bar:SetScript("OnEnter", function(self)
        if GetOptions():get("hideButtonBar") then
            -- Immediately trigger visibility check on mouse enter
            CheckBarVisibility()
        end
    end)
    
    bar:SetScript("OnLeave", function(self)
        if GetOptions():get("hideButtonBar") then
            -- Small delay before checking to allow mouse to move between related elements
            C_Timer.After(0.1, function()
                CheckBarVisibility()
            end)
        end
    end)
    
    -- Set initial position based on barPosition setting
    local barPosition = GetOptions():get("barPosition") or "RIGHT"
    
    -- Available anchor points for button bar positioning
    -- RIGHT: To the right of minimap (default)
    -- LEFT: To the left of minimap
    -- TOP: Above the minimap
    -- BOTTOM: Below the minimap
    -- TOPRIGHT: Top right corner of minimap
    -- TOPLEFT: Top left corner of minimap
    -- BOTTOMRIGHT: Bottom right corner of minimap
    -- BOTTOMLEFT: Bottom left corner of minimap
    
    if barPosition == "LEFT" then
        bar:SetPoint("TOPRIGHT", Minimap, "TOPLEFT", -9, 0)
    elseif barPosition == "TOP" then
        bar:SetPoint("BOTTOM", Minimap, "TOP", 0, 9)
    elseif barPosition == "BOTTOM" then
        bar:SetPoint("TOP", Minimap, "BOTTOM", 0, -9)
    elseif barPosition == "TOPRIGHT" then
        bar:SetPoint("BOTTOMLEFT", Minimap, "TOPRIGHT", 9, 9)
    elseif barPosition == "TOPLEFT" then
        bar:SetPoint("BOTTOMRIGHT", Minimap, "TOPLEFT", -9, 9)
    elseif barPosition == "BOTTOMRIGHT" then
        bar:SetPoint("TOPLEFT", Minimap, "BOTTOMRIGHT", 9, -9)
    elseif barPosition == "BOTTOMLEFT" then
        bar:SetPoint("TOPRIGHT", Minimap, "BOTTOMLEFT", -9, -9)
    else -- Default to RIGHT
        bar:SetPoint("TOPLEFT", Minimap, "TOPRIGHT", 9, 0)
    end
    
    MiniMapRedux.buttonBar = bar
    return bar
end

CollectMinimapButtons = function()
    
    if isCollecting then return end
    isCollecting = true
    
    if collectionTimer then
        collectionTimer:Cancel()
        collectionTimer = nil
    end
    
    -- Reduce initial delay from 0.1 to 0.05 seconds for faster activation
    collectionTimer = C_Timer.NewTimer(0.05, function()
        collectionTimer = nil
        
        local ButtonCollection = MiniMapRedux.import("ButtonCollection")
        local ButtonIdentification = MiniMapRedux.import("ButtonIdentification")
        
        if not GetOptions():get("hideButtons") then
            -- When hideButtons is false, restore all buttons and hide the bar
            ButtonCollection:restore(true) -- Restore all buttons
            -- Hide the button bar when button collection is disabled
            if MiniMapRedux.buttonBar then
                MiniMapRedux.buttonBar:Hide()
            end
            isCollecting = false
            return
        end
        
        if not MiniMapRedux.buttonBar then
            MiniMapRedux.buttonBar = CreateButtonBar()
        end

        ButtonCollection:clear()
        
        local collectedCount = 0
        
        -- Check if we have options
        local options = GetOptions()
        if not options then
            isCollecting = false
            return
        end
        
        -- Debug: Show collection attempt
        -- Starting button collection

        -- Only collect whitelist buttons when hideButtons is true
        if options:get("hideButtons") then
            for buttonName in pairs(options:get("whitelist")) do
                local button = _G[buttonName]
                if button then
                    ButtonCollection:addButton(button, "Addon")
                    collectedCount = collectedCount + 1
                    -- Collected whitelist button
                end
            end
        end

        -- Only collect expansion button when hideButtons is true and user doesn't want it on minimap
        if options:get("hideButtons") and not options:get("showMissionsButton") then
            local expansionButton = _G["ExpansionLandingPageMinimapButton"]
            if expansionButton then
                ButtonCollection:addButton(expansionButton, "Addon")
                collectedCount = collectedCount + 1
                -- Collected expansion button
            end
        end

        -- Only collect LibDBIcon buttons when hideButtons is true
        if options:get("hideButtons") then
            local libDBIconButtons = GetPooledTable(sortTablePool)
            for name, child in pairs(_G) do
                if type(name) == "string" and name:find("^LibDBIcon10_") then
                    table.insert(libDBIconButtons, child)
                end
            end
            table.sort(libDBIconButtons, function(a, b)
                local nameA, nameB = "", ""
                if a.GetName and type(a.GetName) == "function" then
                    nameA = a:GetName() or ""
                end
                if b.GetName and type(b.GetName) == "function" then
                    nameB = b:GetName() or ""
                end
                return nameA < nameB
            end)
            for _, button in ipairs(libDBIconButtons) do
                ButtonCollection:addButton(button, "Addon")
                collectedCount = collectedCount + 1
            end
            ReturnPooledTable(sortTablePool, libDBIconButtons)
        end

        local function processButton(button)
            if not button then return end

            local buttonType = ButtonIdentification:identifyButton(button)
            if not buttonType then return end

            local buttonName
            if button.GetName and type(button.GetName) == "function" then
                buttonName = button:GetName()
            else
                for globalName, globalValue in pairs(_G) do
                    if globalValue == button and type(globalName) == "string" then
                        buttonName = globalName
                        break
                    end
                end
            end

            if not buttonName then
                buttonName = "Unknown"
            end

            -- Exclude frames that shouldn't be in the button bar (visual elements, not actual buttons)
            if buttonName == "MiniMapLFGFrame" or
               buttonName == "MinimapBackdrop" or
               buttonName == "MiniMapBattlefieldFrame" or
               buttonName == "MiniMapBattlefieldFrameIcon" or
               buttonName == "MiniMapTrackingIcon" or
               buttonName == "MiniMapTrackingBackground" or
               buttonName == "MinimapZoneTextButton" or
               buttonName:match("^MiniMap.*Backdrop") or
               buttonName:match("^MiniMap.*Border") or
               buttonName:match("^MiniMap.*Background") or
               buttonName:match("^MiniMap.*Texture") or
               buttonName:match("Battlefield") or
               buttonName:match("ZoneText") then
                return
            end

            if ShouldStayOnMinimap(buttonName) then
                return
            end

            if buttonName and ButtonIdentification.blizzardButtons[buttonName] then
                if not options:get("showBlizzardButtons") then
                    return
                end
                buttonType = ButtonIdentification.blizzardButtons[buttonName]
                if options:get("hideButtons") then
                    ButtonCollection:addButton(button, buttonType)
                    collectedCount = collectedCount + 1
                end
            elseif options:get("hideButtons") then
                ButtonCollection:addButton(button, buttonType)
                collectedCount = collectedCount + 1
            end
        end

        local function hideFromMinimap(button)
            if not button or type(button) ~= "table" then return end

            local success1, buttonName = pcall(function() return button:GetName() end)
            if not success1 or not buttonName then return end

            local success2, parent = pcall(function() return button:GetParent() end)
            if not success2 then return end

            local isMinimapRelated = false
            if parent == Minimap or parent == MinimapCluster then
                isMinimapRelated = true
            elseif parent then
                local checkParent = parent
                for _ = 1, 5 do
                    local success, grandParent = pcall(function() return checkParent:GetParent() end)
                    if success and grandParent then
                        if grandParent == MinimapCluster or grandParent == Minimap then
                            isMinimapRelated = true
                            break
                        end
                        checkParent = grandParent
                    else
                        break
                    end
                end
            end

            if isMinimapRelated then
                if not button.minimapOriginalInfo then
                    local success3, shown = pcall(function() return button:IsShown() end)
                    local success4, alpha = pcall(function() return button:GetAlpha() end)
                    local success5, mouseEnabled = pcall(function() return button:IsMouseEnabled() end)

                    button.minimapOriginalInfo = {
                        shown = success3 and shown or false,
                        alpha = success4 and alpha or 1,
                        mouseEnabled = success5 and mouseEnabled or true
                    }
                end

                pcall(function() button:ClearAllPoints() end)

                local success6 = pcall(function() button:Hide() end)
            end
        end

        if options:get("hideButtons") and options:get("showBlizzardButtons") then
            for _, buttonName in ipairs(highPriorityButtons) do
                local button = _G[buttonName]
                if button and not ButtonCollection:isButtonCollected(button) then
                    local buttonType = ButtonIdentification.blizzardButtons[buttonName] or "BLIZZARD"
                    ButtonCollection:addButton(button, buttonType)
                    collectedCount = collectedCount + 1
                    hideFromMinimap(button)
                end
            end
            
            if UIWidgetBelowMinimapContainerFrame and not ButtonCollection:isButtonCollected(UIWidgetBelowMinimapContainerFrame) then
                ButtonCollection:addButton(UIWidgetBelowMinimapContainerFrame, "Widget")
                collectedCount = collectedCount + 1
                UIWidgetBelowMinimapContainerFrame:Hide()

                if not UIWidgetBelowMinimapContainerFrame.minimapReduxHideHooked then
                    UIWidgetBelowMinimapContainerFrame.minimapReduxHideHooked = true
                    UIWidgetBelowMinimapContainerFrame.minimapReduxOriginalShow = UIWidgetBelowMinimapContainerFrame.Show
                    UIWidgetBelowMinimapContainerFrame.Show = function(self)
                        if ButtonCollection:isButtonCollected(self) then
                            self:Hide()
                        else
                            self.minimapReduxOriginalShow(self)
                        end
                    end
                end
            end
        end

        if MinimapCluster then
            local children = GetPooledTable(childrenTablePool)
            local tempChildren = {MinimapCluster:GetChildren()}
            for i, child in ipairs(tempChildren) do
                children[i] = child
            end

            if MinimapCluster.Tracking then
                if not MinimapCluster.Tracking.GetName or not MinimapCluster.Tracking:GetName() then
                    MinimapCluster.Tracking.GetName = function() return "MinimapCluster_Tracking" end
                end

                if not ButtonCollection:isButtonCollected(MinimapCluster.Tracking) then
                    ButtonCollection:addButton(MinimapCluster.Tracking, "Tracking")
                    collectedCount = collectedCount + 1
                end

                hideFromMinimap(MinimapCluster.Tracking)
            end

            for _, child in ipairs(children) do
                local hasGetName = child.GetName and type(child.GetName) == "function"
                if child and hasGetName then
                    local name = child:GetName() or "Unnamed"
                end
                if child ~= MinimapCluster.Tracking then
                    processButton(child)
                    hideFromMinimap(child)
                end
            end

            ReturnPooledTable(childrenTablePool, children)
        end

        if Minimap then
            local children = GetPooledTable(childrenTablePool)
            local tempChildren = {Minimap:GetChildren()}
            for i, child in ipairs(tempChildren) do
                children[i] = child
            end

            for _, child in ipairs(children) do
                local hasGetName = child.GetName and type(child.GetName) == "function"
                if child and hasGetName then
                    local name = child:GetName() or "Unnamed"
                end
                processButton(child)
                hideFromMinimap(child)
            end

            ReturnPooledTable(childrenTablePool, children)
        end

        -- Throttle expensive _G scan - only run every 5th collection to catch late-loading addons
        globalScanCounter = globalScanCounter + 1
        if globalScanCounter >= GLOBAL_SCAN_INTERVAL then
            globalScanCounter = 0
            for name, obj in pairs(_G) do
                if type(name) == "string" and type(obj) == "table" and obj.GetObjectType and type(obj.GetObjectType) == "function" then
                    local success, objType = pcall(function() return obj:GetObjectType() end)
                    if success and (objType == "Button" or objType == "Frame") and obj.GetParent and type(obj.GetParent) == "function" then
                        local success2, parent = pcall(function() return obj:GetParent() end)
                        if success2 and parent and (parent == Minimap or parent == MinimapCluster) then
                            if not ButtonCollection:isButtonCollected(obj) then
                                processButton(obj)
                                hideFromMinimap(obj)
                            end
                        end
                    end
                end
            end
        end

        if MiniMapRedux.buttonBar and #ButtonCollection.collectedButtons > 0 then
            MiniMapRedux.buttonBar:Show()

            -- Sort buttons for neater grouping: Blizzard buttons first, then addons
            local sortedButtons = GetPooledTable(sortTablePool)
            for _, button in ipairs(ButtonCollection.collectedButtons) do
                table.insert(sortedButtons, button)
            end

            table.sort(sortedButtons, function(a, b)
                local nameA = a.GetName and a:GetName() or internedStrings.Unknown
                local nameB = b.GetName and b:GetName() or internedStrings.Unknown

                local typeA = ButtonCollection.buttonTypes[nameA] or internedStrings.UNKNOWN
                local typeB = ButtonCollection.buttonTypes[nameB] or internedStrings.UNKNOWN

                local isBlizzardA = ButtonIdentification.blizzardButtons[nameA] ~= nil
                local isBlizzardB = ButtonIdentification.blizzardButtons[nameB] ~= nil

                -- Group Blizzard buttons first
                if isBlizzardA and not isBlizzardB then
                    return true
                elseif not isBlizzardA and isBlizzardB then
                    return false
                end

                -- Within same group (both Blizzard or both addon), sort by type priority
                local categoryA = buttonCategories[typeA] or buttonCategories.UNKNOWN
                local categoryB = buttonCategories[typeB] or buttonCategories.UNKNOWN

                if categoryA.priority ~= categoryB.priority then
                    return categoryA.priority < categoryB.priority
                end

                -- Same priority, sort alphabetically by name
                return nameA < nameB
            end)

            local numButtons = PositionButtons(sortedButtons, MiniMapRedux.buttonBar)

            ReturnPooledTable(sortTablePool, sortedButtons)
            
            C_Timer.After(0.1, function()
                if MinimapCluster and MinimapCluster.BorderTop and MinimapCluster.BorderTop.Hide then
                    MinimapCluster.BorderTop:Hide()
                end
            end)
        elseif MiniMapRedux.buttonBar then
            MiniMapRedux.buttonBar:Hide()
        end
        
        MiniMapRedux.collectedAddonButtons = ButtonCollection.collectedButtons
        MiniMapRedux.buttonsCollected = (#ButtonCollection.collectedButtons > 0)
        
        if UIWidgetBelowMinimapContainerFrame and ButtonCollection:isButtonCollected(UIWidgetBelowMinimapContainerFrame) then
            if not MiniMapRedux.widgetHideTicker then
                MiniMapRedux.widgetHideTicker = C_Timer.NewTicker(0.5, function()
                    if UIWidgetBelowMinimapContainerFrame and ButtonCollection:isButtonCollected(UIWidgetBelowMinimapContainerFrame) then
                        if UIWidgetBelowMinimapContainerFrame:IsShown() then
                            UIWidgetBelowMinimapContainerFrame:Hide()
                        end
                    end
                end)
            end
        end
        
        UpdateBarVisibility()
        
        if collectedCount < 3 and collectionAttempts < MAX_COLLECTION_ATTEMPTS then
            collectionAttempts = collectionAttempts + 1
            local retryDelay = collectionAttempts * 2

            if collectionRetryTimer then
                collectionRetryTimer:Cancel()
            end

            collectionRetryTimer = C_Timer.NewTimer(retryDelay, function()
                collectionRetryTimer = nil
                CollectMinimapButtons()
            end)
        else
            collectionAttempts = 0
            -- Force garbage collection after successful collection to free up temporary tables
            collectgarbage("step", 500)
        end

        isCollecting = false
    end)
end

ExportModule()

