local addonName, _ = ...
local MiniMapRedux = _G.MiniMapRedux

local ConfigPanel = {}
local function CreateConfigPanel()
    local panel = CreateFrame("Frame")
    panel.name = "MiniMapRedux"
    
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("MiniMapRedux Configuration")
    
    local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetText("Configure your MiniMapRedux settings")
    desc:SetWidth(400)
    desc:SetJustifyH("LEFT")
    
    local version = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    version:SetPoint("BOTTOMRIGHT", -16, 16)
    version:SetText("Version: " .. (MiniMapRedux.version or "1.0.0"))
    
    local resetButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetButton:SetPoint("BOTTOMLEFT", 16, 16)
    resetButton:SetSize(100, 22)
    resetButton:SetText("Reset Settings")
    resetButton:SetScript("OnClick", function()
        local Options = MiniMapRedux and MiniMapRedux.import("Options")
        if Options then
            Options:reset()
        end
    end)
    
    return panel
end

function ConfigPanel.ShowConfigPanel()
    local Debug = MiniMapRedux and MiniMapRedux.import and MiniMapRedux.import("Debug")
    
    if Debug and Debug.enabled then
        Debug:Log("ConfigPanel: Attempting to show configuration panel")
    end
    
    local panel = ConfigPanel.panel or CreateConfigPanel()
    ConfigPanel.panel = panel
    
    if not panel then
        if Debug and Debug.enabled then
            Debug:Log("ConfigPanel: Failed to create panel")
        end
        return
    end
    
    -- Try to use Settings API first
    if Settings and Settings.RegisterCanvasLayoutCategory then
        if Debug and Debug.enabled then
            Debug:Log("ConfigPanel: Using Settings API")
        end
        
        local category = Settings.RegisterCanvasLayoutCategory(panel, "MiniMapRedux")
        if category then
            Settings.OpenToCategory(category)
        else
            if Debug and Debug.enabled then
                Debug:Log("ConfigPanel: Failed to register category with Settings API")
            end
        end
    else
        if Debug and Debug.enabled then
            Debug:Log("ConfigPanel: Using Interface Options API")
        end
        
        if not panel.isRegistered then
            panel.isRegistered = true
            InterfaceOptions_AddCategory(panel)
        end
        
        if InterfaceOptionsFrame_Show and InterfaceOptionsFrame_OpenToCategory then
            InterfaceOptionsFrame_Show()
            InterfaceOptionsFrame_OpenToCategory(panel)
        else
            if Debug and Debug.enabled then
                Debug:Log("ConfigPanel: Interface Options API functions not available")
            end
        end
    end
end

local function ExportConfigPanel()
    if MiniMapRedux and MiniMapRedux.export then
        local Debug = MiniMapRedux.import and MiniMapRedux.import("Debug")
        
        MiniMapRedux.export("ConfigPanel", ConfigPanel)
        
        if Debug and Debug.enabled then
            Debug:Log("ConfigPanel: Module exported successfully")
        end
    else
        local attempts = (ConfigPanel.exportAttempts or 0) + 1
        ConfigPanel.exportAttempts = attempts
        
        if attempts > 20 then
            return
        end
        
        C_Timer.After(0.2, ExportConfigPanel)
    end
end

ExportConfigPanel()

local Options = {}
local defaultOptions = {
    hideButtons = true,
    minimapScale = 1.0,
    barTransparency = 0.4,
    showBlizzardButtons = true,
    barPosition = "LEFT",
    anchorToMinimap = true,
    hideZoomButtons = false,
    hideCalendar = false,
    hideTime = false,
    hideAddonCompartment = false,
    detachBar = false,
    minimizeBar = false,
    autoCollapse = true,
    showDataTexts = false,
    hideButtonBar = true,  -- Auto-hide button bar by default
    moveTrackingButton = true,
    lockDataBars = false,
    showMinimapDataBar = true,
    showDataTextIcons = true,
    disableDataBarsModule = false,
    showMailIcon = false,
    showCraftingOrderIcon = false,
    showInstanceDifficulty = false,
    showMissionsButton = false,
    showCalendarButton = false,
    showAddonCompartment = false,
    showZoomButtons = false,
    enableMinimapMovement = false,
    minimapPosition = nil,

    buttonBarBackgroundOpacity = 85,
    buttonBarButtonSize = 26,
    buttonBarOrientation = "VERTICAL",
    separateBlizzardBar = true,
    blizzardBarPosition = "RIGHT",
    addonBarPosition = "LEFT",
    showDataBar1 = true,
    showDataBar2 = false,
    showDataBar3 = false,
    showDataBar4 = false,
    showDataBar5 = false,
    showDataBar6 = false,
    showDataBar7 = false,
    showDataBar8 = false,
    showDataBar9 = false,
    showDataBar10 = false,
    minimapDataBarOpacity = 0.9,
    minimapDataBarFontSize = 15,
    dataBar1Opacity = 0.9,
    dataBar2Opacity = 0.9,
    dataBar3Opacity = 0.9,
    dataBar4Opacity = 0.9,
    dataBar5Opacity = 0.9,
    dataBar6Opacity = 0.9,
    dataBar7Opacity = 0.9,
    dataBar8Opacity = 0.9,
    dataBar9Opacity = 0.9,
    dataBar10Opacity = 0.9,
    dataBar1FontSize = 13,
    dataBar2FontSize = 13,
    dataBar3FontSize = 13,
    dataBar4FontSize = 13,
    dataBar5FontSize = 13,
    dataBar6FontSize = 13,
    dataBar7FontSize = 13,
    dataBar8FontSize = 13,
    dataBar9FontSize = 13,
    dataBar10FontSize = 13,
    -- Default data text positions
    dataText_memory_position = "DataBar1",
    dataText_coordinates_position = "DataBar1",
    dataText_clock_position = "minimap",
    dataText_durability_position = "DataBar1",
    dataText_gold_position = "DataBar1",
    dataText_guild_position = "DataBar1",
    dataText_friends_position = "DataBar1",
    dataText_mail_position = "DataBar1",
    dataText_experience_position = "minimap",
    dataText_bags_position = "DataBar1",
    dataText_talents_position = "DataBar1",
    dataText_reputation_position = "DataBar1",
    dataText_currency_position = "DataBar1",
    dataText_session_position = "DataBar2",
    dataText_performance_position = "DataBar2",
    whitelist = {
        -- Common addon buttons that should always be collected
        ZygorGuidesViewerMapIcon = true,
        TrinketMenu_IconFrame = true,
        CodexBrowserIcon = true,
        ExpansionLandingPageMinimapButton = true,
        KhazSummaryButton = true,
        KhazAlgarSummaryButton = true,
        KhazSummaryMinimapButton = true,
        CellMinimapButton = true,
        KalielTrackerMinimapButton = true,
        QuazziUIMinimapButton = true,
        WeakAurasMinimapButton = true,
        Cell = true,
        KalielTracker = true,
        QuazziUI = true,
        WeakAuras = true,
    },
    blacklist = {},
    buttonScale = 1.0,
    version = 0,
}

function Options:init()
    if not _G.MiniMapReduxDB then
        _G.MiniMapReduxDB = {}
    end
    
    for key, value in pairs(defaultOptions) do
        if _G.MiniMapReduxDB[key] == nil then
            _G.MiniMapReduxDB[key] = value
        end
    end
    
    local dataTextKeys = {"memory", "coordinates", "clock", "durability", "gold", "guild", "friends", "mail", "experience", "bags", "talents", "reputation", "currency", "session", "performance"}
    for _, key in ipairs(dataTextKeys) do
        local optionKey = "dataText_" .. key .. "_position"
        local currentValue = _G.MiniMapReduxDB[optionKey]
        
        if currentValue == "other" then
            _G.MiniMapReduxDB[optionKey] = "DataBar1"
        elseif currentValue == "second" then
            _G.MiniMapReduxDB[optionKey] = "DataBar2"
        elseif currentValue == "third" then
            _G.MiniMapReduxDB[optionKey] = "DataBar1"
        elseif currentValue == nil then
            _G.MiniMapReduxDB[optionKey] = defaultOptions[optionKey]
        end
        
        local validPositions = {minimap = true}
        for i = 1, 10 do
            validPositions["DataBar" .. i] = true
        end
        validPositions["hide"] = true
        
        if not validPositions[_G.MiniMapReduxDB[optionKey]] then
            _G.MiniMapReduxDB[optionKey] = defaultOptions[optionKey] or "DataBar1"
        end
    end
    
    if not _G.MiniMapReduxDB.version or _G.MiniMapReduxDB.version < 3 then
        _G.MiniMapReduxDB.version = 3
    end

    if _G.MiniMapReduxDB.version == 3 then
        local iconOptions = {
            "showMailIcon",
            "showCraftingOrderIcon",
            "showInstanceDifficulty",
            "showMissionsButton",
            "showCalendarButton"
        }
        for _, key in ipairs(iconOptions) do
            if _G.MiniMapReduxDB[key] == true then
                _G.MiniMapReduxDB[key] = false
            end
        end
        _G.MiniMapReduxDB.version = 4
    end
end

function Options:get(key)
    if not _G.MiniMapReduxDB then
        return nil
    end
    return _G.MiniMapReduxDB[key]
end

function Options:set(key, value)
    if not _G.MiniMapReduxDB then
        _G.MiniMapReduxDB = {}
    end
    _G.MiniMapReduxDB[key] = value
end

function Options:getDefault(key)
    return defaultOptions[key]
end

function Options:reset()
    _G.MiniMapReduxDB = {}
    self:init()
end

local function ExportOptions()
    if MiniMapRedux and MiniMapRedux.export then
        MiniMapRedux.export("Options", Options)
    else
        C_Timer.After(0.1, ExportOptions)
    end
end

ExportOptions()

return ConfigPanel