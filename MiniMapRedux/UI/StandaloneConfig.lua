local addonName, _ = ...
local MiniMapRedux = _G.MiniMapRedux

-- StandaloneConfig Module - Provides a detached configuration UI for MiniMapRedux
local StandaloneConfig = {}

-- Import dependencies - defer until available
local Options
local Debug

local function GetDependencies()
    if not Options and MiniMapRedux and MiniMapRedux.import then
        Options = MiniMapRedux.import("Options")
    end
    if not Debug and MiniMapRedux and MiniMapRedux.import then
        Debug = MiniMapRedux.import("Debug")
    end
    return Options, Debug
end

-- Create the standalone configuration window with modern UI design
function StandaloneConfig:CreateConfigWindow()
    local Options, Debug = GetDependencies()
    
    -- Debug info
    if Debug and Debug.enabled then
        Debug:Log("StandaloneConfig: Attempting to create config window")
    end
    
    if not Options then
        if Debug and Debug.enabled then
            Debug:Log("StandaloneConfig: Options module not available")
        end
        -- Options module not available
        return nil
    end
    
    if self.configFrame then 
        self.configFrame:Show()
        return self.configFrame
    end
    
    -- Main frame with modern design
    local frame = CreateFrame("Frame", "MiniMapReduxStandaloneConfig", UIParent, "BackdropTemplate")
    frame:SetSize(800, 600)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("HIGH")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    
    -- Modern dark gradient background
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        edgeSize = 2,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    frame:SetBackdropColor(0.05, 0.05, 0.1, 0.95)
    frame:SetBackdropBorderColor(0.3, 0.6, 1, 0.8)
    
    -- Animated glow effect
    local glow = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    glow:SetAllPoints(frame)
    glow:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 4,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    glow:SetBackdropBorderColor(0.3, 0.6, 1, 0.3)
    glow:SetFrameLevel(frame:GetFrameLevel() - 1)
    
    -- Animate the glow
    local glowAnimation = glow:CreateAnimationGroup()
    local fadeOut = glowAnimation:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(0.3)
    fadeOut:SetToAlpha(0.1)
    fadeOut:SetDuration(2)
    local fadeIn = glowAnimation:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0.1)
    fadeIn:SetToAlpha(0.3)
    fadeIn:SetDuration(2)
    fadeIn:SetStartDelay(2)
    glowAnimation:SetLooping("REPEAT")
    glowAnimation:Play()
    
    -- Modern header section with gradient
    local header = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    header:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
    header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
    header:SetHeight(60)
    header:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = nil,
        tile = false,
    })
    header:SetBackdropColor(0.1, 0.1, 0.2, 0.8)
    
    -- Header gradient effect
    local headerGradient = header:CreateTexture(nil, "BACKGROUND")
    headerGradient:SetAllPoints(header)
    headerGradient:SetTexture("Interface\\Buttons\\WHITE8X8")
    headerGradient:SetGradient("VERTICAL", CreateColor(0.2, 0.4, 0.8, 0.6), CreateColor(0.05, 0.1, 0.2, 0.3))
    
    -- Drag functionality for the header
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() frame:StartMoving() end)
    header:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)
    
    -- Modern title with shadow effect
    local titleShadow = header:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    titleShadow:SetPoint("CENTER", header, "CENTER", 1, -1)
    titleShadow:SetText("MiniMapRedux")
    titleShadow:SetTextColor(0, 0, 0, 0.8)
    
    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("CENTER", header, "CENTER", 0, 0)
    title:SetText("MiniMapRedux")
    title:SetTextColor(1, 1, 1, 1)
    
    local subtitle = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -2)
    subtitle:SetText("Configuration Panel")
    subtitle:SetTextColor(0.7, 0.8, 1, 0.9)
    
    -- Modern close button with Blizzard styling
    local closeButton = CreateFrame("Button", nil, header, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", header, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function() frame:Hide() end)
    
    -- Modern Tab System
    local tabContainer = CreateFrame("Frame", nil, frame)
    tabContainer:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 10, -10)
    tabContainer:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", -10, -10)
    tabContainer:SetHeight(40)
    
    local tabs = {}
    local tabContents = {}
    local activeTab = nil
    
    -- Tab data with Blizzard icons
    local tabData = {
        {name = "General", icon = "Interface\\Icons\\INV_Misc_Gear_01"},
        {name = "Minimap", icon = "Interface\\Minimap\\UI-Minimap-Background"},
        {name = "Data Bars", icon = "Interface\\Icons\\Trade_Engineering"},
        {name = "Data Texts", icon = "Interface\\Icons\\INV_Misc_Note_01"},
        {name = "Minimap Buttons", icon = "Interface\\Icons\\INV_Misc_GroupLooking"},
        {name = "Advanced", icon = "Interface\\Icons\\Trade_BlackSmithing"}
    }
    
    -- Create tab buttons
    for i, tabInfo in ipairs(tabData) do
        local tab = CreateFrame("Button", nil, tabContainer)
        tab.tabId = i
        tab:SetSize(122, 30)  -- 6 tabs fit within 780px usable width
        tab:SetPoint("LEFT", (i-1) * 127 + 5, 0)  -- 127px spacing (122 + 5px gap)

        -- Tab background
        local tabBg = tab:CreateTexture(nil, "BACKGROUND")
        tabBg:SetAllPoints()
        tabBg:SetTexture("Interface\\Buttons\\WHITE8X8")
        tabBg:SetVertexColor(0.15, 0.15, 0.25, 0.8)
        tab.background = tabBg

        -- Tab border
        local tabBorder = CreateFrame("Frame", nil, tab, "BackdropTemplate")
        tabBorder:SetAllPoints()
        tabBorder:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        tabBorder:SetBackdropBorderColor(0.3, 0.3, 0.4, 0.6)
        tab.border = tabBorder

        -- Tab text (no icon - text only, centered)
        local tabText = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        tabText:SetPoint("CENTER", 0, 0)
        tabText:SetText(tabInfo.name)
        tabText:SetTextColor(0.8, 0.8, 0.9, 1)
        tab.text = tabText

        -- Tab hover and click effects
        tab:SetScript("OnEnter", function(self)
            if self ~= activeTab then
                self.background:SetVertexColor(0.2, 0.2, 0.35, 0.9)
                self.border:SetBackdropBorderColor(0.4, 0.6, 1, 0.8)
                self.text:SetTextColor(1, 1, 1, 1)
            end
        end)

        tab:SetScript("OnLeave", function(self)
            if self ~= activeTab then
                self.background:SetVertexColor(0.15, 0.15, 0.25, 0.8)
                self.border:SetBackdropBorderColor(0.3, 0.3, 0.4, 0.6)
                self.text:SetTextColor(0.8, 0.8, 0.9, 1)
            end
        end)

        tab:SetScript("OnClick", function(self)
            StandaloneConfig:SelectTab(self, tabs, tabContents)
        end)

        tabs[i] = tab
    end
    
    -- Content area for tabs
    local contentArea = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    contentArea:SetPoint("TOPLEFT", tabContainer, "BOTTOMLEFT", 0, -5)
    contentArea:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
    contentArea:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    contentArea:SetBackdropColor(0.08, 0.08, 0.15, 0.9)
    contentArea:SetBackdropBorderColor(0.3, 0.3, 0.4, 0.5)
    
    -- Store references for tab system
    frame.tabs = tabs
    frame.tabContents = tabContents
    frame.contentArea = contentArea
    
    -- Create tab contents
    StandaloneConfig:CreateTabContents(frame, Options)
    
    -- Select first tab by default
    StandaloneConfig:SelectTab(tabs[1], tabs, tabContents)
    
    local versionText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    versionText:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
    versionText:SetText("01.03.26.60")
    versionText:SetTextColor(0.5, 0.5, 0.6, 0.8)
    
    self.configFrame = frame
    return frame
end

-- Tab selection function
function StandaloneConfig:SelectTab(selectedTab, tabs, tabContents)
    -- Update tab appearances
    for i, tab in ipairs(tabs) do
        if tab == selectedTab then
            -- Active tab styling
            tab.background:SetVertexColor(0.3, 0.5, 0.8, 1)
            tab.border:SetBackdropBorderColor(0.5, 0.7, 1, 1)
            tab.text:SetTextColor(1, 1, 1, 1)
        else
            -- Inactive tab styling
            tab.background:SetVertexColor(0.15, 0.15, 0.25, 0.8)
            tab.border:SetBackdropBorderColor(0.3, 0.3, 0.4, 0.6)
            tab.text:SetTextColor(0.8, 0.8, 0.9, 1)
        end
    end
    
    -- Show/hide tab contents
    for i, content in ipairs(tabContents) do
        if i == selectedTab.tabId then
            content:Show()
        else
            content:Hide()
        end
    end
end

-- Create modern tab contents
function StandaloneConfig:CreateTabContents(frame, Options)
    local contentArea = frame.contentArea
    local tabContents = frame.tabContents
    
    -- TAB 1: General Settings
    local generalTab = CreateFrame("ScrollFrame", nil, contentArea, "UIPanelScrollFrameTemplate")
    generalTab:SetAllPoints(contentArea)
    generalTab:SetClampedToScreen(true)
    
    local generalContent = CreateFrame("Frame", nil, generalTab)
    generalContent:SetSize(contentArea:GetWidth() - 30, 400)
    generalTab:SetScrollChild(generalContent)
    
    StandaloneConfig:CreateGeneralContent(generalContent, Options)
    tabContents[1] = generalTab
    
    -- TAB 2: Minimap Settings
    local minimapTab = CreateFrame("ScrollFrame", nil, contentArea, "UIPanelScrollFrameTemplate")
    minimapTab:SetAllPoints(contentArea)
    local minimapContent = CreateFrame("Frame", nil, minimapTab)
    minimapContent:SetSize(contentArea:GetWidth() - 30, 400)
    minimapTab:SetScrollChild(minimapContent)
    StandaloneConfig:CreateMinimapContent(minimapContent, Options)
    tabContents[2] = minimapTab
    
    -- TAB 3: Data Bars Settings  
    local databarsTab = CreateFrame("ScrollFrame", nil, contentArea, "UIPanelScrollFrameTemplate")
    databarsTab:SetAllPoints(contentArea)
    local databarsContent = CreateFrame("Frame", nil, databarsTab)
    databarsContent:SetSize(contentArea:GetWidth() - 30, 600)
    databarsTab:SetScrollChild(databarsContent)
    StandaloneConfig:CreateDataBarsContent(databarsContent, Options)
    tabContents[3] = databarsTab
    
    -- TAB 4: Data Text Assignments
    local dataTextsTab = CreateFrame("ScrollFrame", nil, contentArea, "UIPanelScrollFrameTemplate")
    dataTextsTab:SetAllPoints(contentArea)
    local dataTextsContent = CreateFrame("Frame", nil, dataTextsTab)
    dataTextsContent:SetSize(contentArea:GetWidth() - 30, 600)
    dataTextsTab:SetScrollChild(dataTextsContent)
    StandaloneConfig:CreateDataTextsContent(dataTextsContent, Options)
    tabContents[4] = dataTextsTab
    
    -- TAB 5: Button Settings
    local buttonsTab = CreateFrame("ScrollFrame", nil, contentArea, "UIPanelScrollFrameTemplate")
    buttonsTab:SetAllPoints(contentArea)
    local buttonsContent = CreateFrame("Frame", nil, buttonsTab)
    buttonsContent:SetSize(contentArea:GetWidth() - 30, 400)
    buttonsTab:SetScrollChild(buttonsContent)
    StandaloneConfig:CreateButtonsContent(buttonsContent, Options)
    tabContents[5] = buttonsTab
    
    -- TAB 6: Advanced Settings
    local advancedTab = CreateFrame("ScrollFrame", nil, contentArea, "UIPanelScrollFrameTemplate")
    advancedTab:SetAllPoints(contentArea)
    local advancedContent = CreateFrame("Frame", nil, advancedTab)
    advancedContent:SetSize(contentArea:GetWidth() - 30, 300)
    advancedTab:SetScrollChild(advancedContent)
    StandaloneConfig:CreateAdvancedContent(advancedContent, Options)
    tabContents[6] = advancedTab
end

-- Helper function to create modern checkboxes with visual feedback
function StandaloneConfig:CreateModernCheckbox(parent, text, x, y, getValue, setValue, tooltip)
    local checkbox = CreateFrame("CheckButton", nil, parent)
    checkbox:SetSize(20, 20)  -- Small square checkbox
    checkbox:SetPoint("TOPLEFT", x, y)
    
    -- Create a simple square frame for the checkbox
    local bg = checkbox:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetVertexColor(0.1, 0.1, 0.1, 0.8)  -- Dark background
    
    -- Border
    local border = CreateFrame("Frame", nil, checkbox, "BackdropTemplate")
    border:SetAllPoints()
    border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    border:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Red X for unchecked state
    local redX = checkbox:CreateTexture(nil, "ARTWORK")
    redX:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-NotReady")
    redX:SetAllPoints()
    redX:SetVertexColor(1, 0, 0)  -- Red color
    
    -- Green checkmark for checked state
    local greenCheck = checkbox:CreateTexture(nil, "ARTWORK")
    greenCheck:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    greenCheck:SetAllPoints()
    greenCheck:SetVertexColor(0, 1, 0)  -- Green color
    greenCheck:Hide()
    
    -- Checkbox text
    local label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", checkbox, "RIGHT", 8, 0)
    label:SetText(text)
    label:SetTextColor(0.9, 0.9, 1, 1)
    
    -- Update visual state
    local function updateVisualState()
        local isChecked = getValue()
        checkbox:SetChecked(isChecked)
        
        if isChecked then
            redX:Hide()
            greenCheck:Show()
        else
            greenCheck:Hide()
            redX:Show()
        end
    end
    
    checkbox:SetScript("OnClick", function()
        setValue(checkbox:GetChecked())
        updateVisualState()
    end)
    
    checkbox:SetScript("OnEnter", function()
        border:SetBackdropBorderColor(1, 1, 1, 1)  -- White border on hover
        if tooltip then
            GameTooltip:SetOwner(checkbox, "ANCHOR_RIGHT")
            GameTooltip:SetText(tooltip)
            GameTooltip:Show()
        end
    end)
    
    checkbox:SetScript("OnLeave", function()
        border:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)  -- Normal border
        GameTooltip:Hide()
    end)
    
    -- Initial state
    updateVisualState()
    return checkbox
end

-- Helper function to create modern sliders
function StandaloneConfig:CreateModernSlider(parent, text, x, y, minVal, maxVal, getValue, setValue, tooltip)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(280, 50)
    container:SetPoint("TOPLEFT", x, y)
    
    -- Slider title
    local title = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 0, 0)
    title:SetText(text)
    title:SetTextColor(0.9, 0.9, 1, 1)
    
    -- Value display
    local valueText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    valueText:SetPoint("TOPRIGHT", 0, 0)
    valueText:SetTextColor(0.3, 0.6, 1, 1)
    
    -- Create slider
    local slider = CreateFrame("Slider", nil, container, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 0, -25)
    slider:SetSize(260, 20)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)
    
    -- Custom thumb texture for modern look
    local thumb = slider:GetThumbTexture()
    thumb:SetTexture("Interface\\Buttons\\WHITE8X8")
    thumb:SetSize(16, 16)
    thumb:SetVertexColor(0.3, 0.6, 1, 1)
    
    -- Update function
    local function updateSlider()
        local currentValue = getValue()
        slider:SetValue(currentValue)
        if text == "Background Opacity" then
            valueText:SetText(currentValue .. "%")
        else
            valueText:SetText(currentValue .. "px")
        end
    end
    
    slider:SetScript("OnValueChanged", function(self, value)
        setValue(math.floor(value))
        updateSlider()
    end)
    
    -- Tooltip support
    if tooltip then
        slider:SetScript("OnEnter", function()
            GameTooltip:SetOwner(slider, "ANCHOR_RIGHT")
            GameTooltip:SetText(tooltip)
            GameTooltip:Show()
        end)
        
        slider:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    
    -- Initial update
    updateSlider()
    return container
end

-- Create modern dropdown for data text assignments
function StandaloneConfig:CreateDataTextDropdown(parent, text, dataTextKey, x, y, Options)
    -- Creating dropdown silently
    
    local dropdown = CreateFrame("Frame", nil, parent)
    dropdown:SetSize(300, 24)
    dropdown:SetPoint("TOPLEFT", x, y)
    
    -- Label for the dropdown
    local label = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", 0, 0)
    label:SetText(text .. ":")
    label:SetTextColor(0.9, 0.9, 1, 1)
    label:SetWidth(120)
    label:SetJustifyH("LEFT")
    
    -- Dropdown button
    local dropdownBtn = CreateFrame("Button", nil, dropdown)
    dropdownBtn:SetSize(150, 24)
    dropdownBtn:SetPoint("LEFT", label, "RIGHT", 10, 0)
    
    -- Dropdown background
    local dropdownBg = dropdownBtn:CreateTexture(nil, "BACKGROUND")
    dropdownBg:SetAllPoints()
    dropdownBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    dropdownBg:SetVertexColor(0.15, 0.15, 0.25, 0.9)
    
    -- Dropdown border
    local dropdownBorder = CreateFrame("Frame", nil, dropdownBtn, "BackdropTemplate")
    dropdownBorder:SetAllPoints()
    dropdownBorder:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    dropdownBorder:SetBackdropBorderColor(0.4, 0.4, 0.5, 0.8)
    
    -- Dropdown text
    local dropdownText = dropdownBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dropdownText:SetPoint("LEFT", 8, 0)
    dropdownText:SetTextColor(0.9, 0.9, 1, 1)
    
    -- Dropdown arrow
    local arrow = dropdownBtn:CreateTexture(nil, "OVERLAY")
    arrow:SetSize(12, 8)
    arrow:SetPoint("RIGHT", -8, 0)
    arrow:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")
    arrow:SetVertexColor(0.7, 0.7, 0.8, 1)
    
    -- Available positions
    local positions = {
        {value = "minimap", text = "Minimap"},
        {value = "hide", text = "Hidden"},
    }
    
    -- Add DataBar options
    for i = 1, 10 do
        table.insert(positions, {value = "DataBar" .. i, text = "Data Bar " .. i})
    end
    
    -- Update dropdown display
    local function updateDropdown()
        local currentPos = Options:get("dataText_" .. dataTextKey .. "_position") or "DataBar1"
        for _, pos in ipairs(positions) do
            if pos.value == currentPos then
                dropdownText:SetText(pos.text)
                break
            end
        end
    end
    
    -- Create dropdown menu
    local function showDropdownMenu()
        local menu = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        menu:SetSize(150, #positions * 24)
        menu:SetPoint("TOPLEFT", dropdownBtn, "BOTTOMLEFT", 0, 0)
        menu:SetFrameStrata("TOOLTIP")
        menu:SetFrameLevel(1000)
        
        -- Menu background
        menu:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false,
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        menu:SetBackdropColor(0.1, 0.1, 0.2, 0.95)
        menu:SetBackdropBorderColor(0.4, 0.4, 0.5, 1)
        
        -- Menu items
        for i, pos in ipairs(positions) do
            local item = CreateFrame("Button", nil, menu)
            item:SetSize(148, 24)
            item:SetPoint("TOPLEFT", 1, -(i-1) * 24 - 1)
            item:EnableMouse(true)
            
            local itemBg = item:CreateTexture(nil, "BACKGROUND")
            itemBg:SetAllPoints()
            itemBg:SetTexture("Interface\\Buttons\\WHITE8X8")
            itemBg:SetVertexColor(0.15, 0.15, 0.25, 0.8)
            
            local itemText = item:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            itemText:SetPoint("LEFT", 8, 0)
            itemText:SetText(pos.text)
            itemText:SetTextColor(0.9, 0.9, 1, 1)
            
            item:SetScript("OnClick", function(self, button)
                if not Options or not dataTextKey or not pos.value then
                    return
                end
                
                local optionKey = "dataText_" .. dataTextKey .. "_position"
                Options:set(optionKey, pos.value)
                
                -- Verify the setting was saved
                local savedValue = Options:get(optionKey)
                
                updateDropdown()
                menu:Hide()
                
                -- Clear active menu reference
                if dropdownBtn.activeMenu == menu then
                    dropdownBtn.activeMenu = nil
                end
                
                -- Refresh data texts
                local DataTexts = MiniMapRedux.import("DataTexts")
                if DataTexts and DataTexts.RefreshDataTexts then
                    DataTexts:RefreshDataTexts()
                end
            end)
            
            item:SetScript("OnEnter", function()
                itemBg:SetVertexColor(0.3, 0.3, 0.4, 1)
            end)
            
            item:SetScript("OnLeave", function()
                itemBg:SetVertexColor(0.15, 0.15, 0.25, 0.8)
            end)
        end
        
        -- Close menu when clicking outside
        local closeFrame = CreateFrame("Frame", nil, UIParent)
        closeFrame:SetAllPoints()
        closeFrame:SetFrameStrata("FULLSCREEN_DIALOG")
        closeFrame:SetFrameLevel(menu:GetFrameLevel() - 1)
        closeFrame:EnableMouse(true)
        closeFrame:SetScript("OnMouseDown", function()
            menu:Hide()
            closeFrame:Hide()
            if dropdownBtn.activeMenu == menu then
                dropdownBtn.activeMenu = nil
            end
        end)
        
        menu:SetScript("OnHide", function()
            closeFrame:Hide()
            if dropdownBtn.activeMenu == menu then
                dropdownBtn.activeMenu = nil
            end
        end)
        
        return menu
    end
    
    -- Dropdown button events
    dropdownBtn:SetScript("OnClick", function()
        -- Close any existing menu first
        if dropdownBtn.activeMenu then
            dropdownBtn.activeMenu:Hide()
            dropdownBtn.activeMenu = nil
        end
        
        -- Create and show new menu
        local menu = showDropdownMenu()
        dropdownBtn.activeMenu = menu
    end)
    
    dropdownBtn:SetScript("OnEnter", function()
        dropdownBg:SetVertexColor(0.2, 0.2, 0.35, 1)
        dropdownBorder:SetBackdropBorderColor(0.5, 0.5, 0.7, 1)
    end)
    
    dropdownBtn:SetScript("OnLeave", function()
        dropdownBg:SetVertexColor(0.15, 0.15, 0.25, 0.9)
        dropdownBorder:SetBackdropBorderColor(0.4, 0.4, 0.5, 0.8)
    end)
    
    -- Initial update
    updateDropdown()
    
    return dropdown
end

-- Create General tab content
function StandaloneConfig:CreateGeneralContent(content, Options)
    -- Section title
    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetText("General Settings")
    title:SetTextColor(0.3, 0.6, 1, 1)
    
    -- Module toggles with modern styling
        
    self:CreateModernCheckbox(content, "Enable Data Bars Module", 30, -90,
        function() return not Options:get("disableDataBarsModule") end,
        function(val)
            Options:set("disableDataBarsModule", not val)
            -- When enabling the module, ensure at least the first data bar is enabled
            if val then
                Options:set("showDataBar1", true)
                Options:set("showMinimapDataBar", true)
            end
            local DataTexts = MiniMapRedux.import("DataTexts")
            if DataTexts then
                -- Force clear the refreshing flag first
                DataTexts.refreshing = false
                if DataTexts.RefreshDataTexts then
                    DataTexts:RefreshDataTexts()
                end
                -- Add multiple delayed forced refreshes to ensure visibility
                if val then
                    C_Timer.After(0.1, function()
                        DataTexts.refreshing = false
                        DataTexts:RefreshDataTexts()
                        if DataTexts.ForceShowEnabledBars then
                            DataTexts:ForceShowEnabledBars()
                        end
                    end)
                    C_Timer.After(0.3, function()
                        DataTexts.refreshing = false
                        DataTexts:RefreshDataTexts()
                        if DataTexts.ForceShowEnabledBars then
                            DataTexts:ForceShowEnabledBars()
                        end
                    end)
                end
            end
        end,
        "Toggle data bars that show game information")
        
    -- Add minimap button collection option
    self:CreateModernCheckbox(content, "Enable Minimap Button Collection", 30, -120,
        function() return Options:get("hideButtons") end,
        function(val) 
            Options:set("hideButtons", val)
            local ButtonManager = MiniMapRedux.import("ButtonManager")
            if ButtonManager then
                if val and ButtonManager.CollectMinimapButtons then
                    C_Timer.After(0.1, ButtonManager.CollectMinimapButtons)
                else
                    -- Restore buttons to minimap if collection is disabled
                    local ButtonCollection = MiniMapRedux.import("ButtonCollection")
                    if ButtonCollection and ButtonCollection.restore then
                        local options = MiniMapRedux.import("Options")
                        if options and options.get then
                            -- If showBlizzardButtons is true, only restore addon buttons
                            ButtonCollection:restore(not options:get("showBlizzardButtons"))
                        else
                            ButtonCollection:restore(true)
                        end
                    end
                    -- Always update bar visibility when disabling collection
                    if ButtonManager.UpdateBarVisibility then
                        ButtonManager.UpdateBarVisibility()
                    end
                    -- Explicitly hide the button bar
                    if MiniMapRedux.buttonBar then
                        MiniMapRedux.buttonBar:Hide()
                    end
                end
            end
        end,
        "Collect minimap buttons into a dedicated button bar")
end

-- Create Minimap tab content
function StandaloneConfig:CreateMinimapContent(content, Options)
    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetText("Minimap Settings")
    title:SetTextColor(0.3, 0.6, 1, 1)
    
    -- Minimap Scale Slider with modern styling
    local scaleLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    scaleLabel:SetPoint("TOPLEFT", 30, -60)
    scaleLabel:SetText("Minimap Scale:")
    scaleLabel:SetTextColor(0.9, 0.9, 1, 1)
    
    local slider = CreateFrame("Slider", nil, content, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 30, -85)
    slider:SetSize(300, 20)
    slider:SetMinMaxValues(0.5, 2.0)
    slider:SetValueStep(0.1)
    slider:SetValue(Options:get("minimapScale"))
    
    -- Modern slider styling
    local sliderBg = slider:CreateTexture(nil, "BACKGROUND")
    sliderBg:SetAllPoints()
    sliderBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    sliderBg:SetVertexColor(0.2, 0.2, 0.3, 0.5)
    
    local valueLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    valueLabel:SetPoint("LEFT", slider, "RIGHT", 10, 0)
    valueLabel:SetText(floor(Options:get("minimapScale") * 100) .. "%")
    valueLabel:SetTextColor(0.3, 0.6, 1, 1)
    
    slider:SetScript("OnValueChanged", function(self, value)
        Options:set("minimapScale", value)
        valueLabel:SetText(floor(value * 100) .. "%")
        if Minimap then
            Minimap:SetScale(value)
            if MinimapCluster then
                MinimapCluster:SetScale(value)
            end
        end
    end)

    -- Enable Minimap Movement (for Classic Era - no Edit Mode)
    self:CreateModernCheckbox(content, "Enable Minimap Movement", 30, -120,
        function() return Options:get("enableMinimapMovement") end,
        function(val)
            Options:set("enableMinimapMovement", val)
            local MinimapModule = MiniMapRedux.import("Minimap")
            if MinimapModule and MinimapModule.SetMinimapMovable then
                MinimapModule.SetMinimapMovable(val)
                -- Also restore position when enabling movement
                if val and MinimapModule.RestoreMinimapPosition then
                    MinimapModule.RestoreMinimapPosition()
                end
            end
        end,
        "Allow dragging the minimap with left mouse button (for Classic Era)")

    -- Icon Visibility Section
    local iconTitle = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    iconTitle:SetPoint("TOPLEFT", 20, -140)
    iconTitle:SetText("Minimap Icon Visibility")
    iconTitle:SetTextColor(1, 0.8, 0.3, 1)

    local iconDesc = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    iconDesc:SetPoint("TOPLEFT", iconTitle, "BOTTOMLEFT", 10, -5)
    iconDesc:SetText("Control which icons are shown on the minimap")
    iconDesc:SetTextColor(0.8, 0.8, 0.8, 1)

    -- Mail Icon
    self:CreateModernCheckbox(content, "Show Mail Icon", 30, -180,
        function() return Options:get("showMailIcon") end,
        function(val)
            Options:set("showMailIcon", val)
            local MinimapModule = MiniMapRedux.import("Minimap")
            if MinimapModule and MinimapModule.UpdateIconVisibility then
                MinimapModule.UpdateIconVisibility()
            end
        end,
        "Show or hide the mail notification icon")

    -- Crafting Order Icon
    self:CreateModernCheckbox(content, "Show Crafting Order Icon", 30, -210,
        function() return Options:get("showCraftingOrderIcon") end,
        function(val)
            Options:set("showCraftingOrderIcon", val)
            local MinimapModule = MiniMapRedux.import("Minimap")
            if MinimapModule and MinimapModule.UpdateIconVisibility then
                MinimapModule.UpdateIconVisibility()
            end
        end,
        "Show or hide the crafting order notification icon")

    -- Instance Difficulty
    self:CreateModernCheckbox(content, "Show Instance Difficulty", 30, -240,
        function() return Options:get("showInstanceDifficulty") end,
        function(val)
            Options:set("showInstanceDifficulty", val)
            local MinimapModule = MiniMapRedux.import("Minimap")
            if MinimapModule and MinimapModule.UpdateIconVisibility then
                MinimapModule.UpdateIconVisibility()
            end
        end,
        "Show or hide the instance difficulty indicator")

    -- Missions/Expansion Landing Page Button
    self:CreateModernCheckbox(content, "Show Missions Button", 300, -180,
        function() return Options:get("showMissionsButton") end,
        function(val)
            Options:set("showMissionsButton", val)
            local MinimapModule = MiniMapRedux.import("Minimap")
            if MinimapModule and MinimapModule.UpdateIconVisibility then
                MinimapModule.UpdateIconVisibility()
            end
        end,
        "Show or hide the missions/expansion landing page button")

    -- Calendar Button
    self:CreateModernCheckbox(content, "Show Calendar Button", 300, -210,
        function() return Options:get("showCalendarButton") end,
        function(val)
            Options:set("showCalendarButton", val)
            local MinimapModule = MiniMapRedux.import("Minimap")
            if MinimapModule and MinimapModule.UpdateIconVisibility then
                MinimapModule.UpdateIconVisibility()
            end
        end,
        "Show or hide the calendar/game time button")

    -- Addon Compartment
    self:CreateModernCheckbox(content, "Show Addon Compartment", 300, -240,
        function() return Options:get("showAddonCompartment") end,
        function(val)
            Options:set("showAddonCompartment", val)
            local MinimapModule = MiniMapRedux.import("Minimap")
            if MinimapModule and MinimapModule.UpdateIconVisibility then
                MinimapModule.UpdateIconVisibility()
            end
        end,
        "Show or hide the addon compartment button")

    -- Zoom Buttons
    self:CreateModernCheckbox(content, "Show Zoom Buttons", 30, -270,
        function() return Options:get("showZoomButtons") end,
        function(val)
            Options:set("showZoomButtons", val)
            local MinimapModule = MiniMapRedux.import("Minimap")
            if MinimapModule and MinimapModule.UpdateIconVisibility then
                MinimapModule.UpdateIconVisibility()
            end
        end,
        "Show or hide the minimap zoom in/out buttons")

    -- Clock Settings Section
    local clockTitle = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    clockTitle:SetPoint("TOPLEFT", 20, -310)
    clockTitle:SetText("Clock Settings")
    clockTitle:SetTextColor(1, 0.8, 0.3, 1)

    local clockDesc = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    clockDesc:SetPoint("TOPLEFT", clockTitle, "BOTTOMLEFT", 10, -5)
    clockDesc:SetText("Configure how time is displayed in the clock data text")
    clockDesc:SetTextColor(0.8, 0.8, 0.8, 1)

    -- Clock Format Toggle (12hr vs 24hr)
    self:CreateModernCheckbox(content, "Use 12-hour format (AM/PM)", 30, -350,
        function() return Options:get("clockFormat") == "12hr" end,
        function(val)
            Options:set("clockFormat", val and "12hr" or "24hr")
            -- Refresh data texts to apply change immediately
            local DataTexts = MiniMapRedux.import("DataTexts")
            if DataTexts and DataTexts.UpdateAllDataTexts then
                DataTexts:UpdateAllDataTexts()
            end
        end,
        "Display time in 12-hour format with AM/PM instead of 24-hour military time")
end

-- Create Data Bars tab content  
function StandaloneConfig:CreateDataBarsContent(content, Options)
    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetText("Data Bars Settings")
    title:SetTextColor(0.3, 0.6, 1, 1)
    
    -- Minimap Data Bar Section
    local minimapTitle = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    minimapTitle:SetPoint("TOPLEFT", 20, -50)
    minimapTitle:SetText("Minimap Data Bar")
    minimapTitle:SetTextColor(1, 0.8, 0.3, 1)
    
    -- Creating Minimap Data Bar section
    
    self:CreateModernCheckbox(content, "Show Minimap Data Bar", 30, -75,
        function() return Options:get("showMinimapDataBar") end,
        function(val) 
            Options:set("showMinimapDataBar", val)
            local DataTexts = MiniMapRedux.import("DataTexts")
            if DataTexts and DataTexts.RefreshDataTexts then
                DataTexts:RefreshDataTexts()
            end
        end,
        "Show data texts on the minimap")
    
    -- Opacity slider for minimap data bar
    local minimapOpacityLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    minimapOpacityLabel:SetPoint("TOPLEFT", 50, -100)
    minimapOpacityLabel:SetText("Opacity:")
    minimapOpacityLabel:SetTextColor(0.8, 0.8, 0.9, 1)
    
    local minimapOpacitySlider = CreateFrame("Slider", nil, content, "OptionsSliderTemplate")
    minimapOpacitySlider:SetPoint("LEFT", minimapOpacityLabel, "RIGHT", 10, 0)
    minimapOpacitySlider:SetSize(100, 20)
    minimapOpacitySlider:SetMinMaxValues(0, 1)
    minimapOpacitySlider:SetValue(Options:get("minimapDataBarOpacity") or 0.9)
    minimapOpacitySlider:SetValueStep(0.1)
    
    minimapOpacitySlider:SetScript("OnValueChanged", function(self, value)
        Options:set("minimapDataBarOpacity", value)
        local DataTexts = MiniMapRedux.import("DataTexts")
        if DataTexts and DataTexts.UpdateDataBarOpacity then
            DataTexts:UpdateDataBarOpacity()
        end
    end)
    
    -- Font size slider for minimap data bar
    local minimapFontLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    minimapFontLabel:SetPoint("LEFT", minimapOpacitySlider, "RIGHT", 20, 0)
    minimapFontLabel:SetText("Font Size:")
    minimapFontLabel:SetTextColor(0.8, 0.8, 0.9, 1)
    
    local minimapFontSlider = CreateFrame("Slider", nil, content, "OptionsSliderTemplate")
    minimapFontSlider:SetPoint("LEFT", minimapFontLabel, "RIGHT", 10, 0)
    minimapFontSlider:SetSize(80, 20)
    minimapFontSlider:SetMinMaxValues(8, 20)
    minimapFontSlider:SetValue(Options:get("minimapDataBarFontSize") or 15)
    minimapFontSlider:SetValueStep(1)
    
    minimapFontSlider:SetScript("OnValueChanged", function(self, value)
        Options:set("minimapDataBarFontSize", value)
        local DataTexts = MiniMapRedux.import("DataTexts")
        if DataTexts and DataTexts.UpdateDataBarFontSizes then
            DataTexts:UpdateDataBarFontSizes()
        end
    end)
    
    -- Lock Data Bars checkbox - positioned in top right near minimap section
    self:CreateModernCheckbox(content, "Lock Data Bars", 400, -75,
        function() return Options:get("lockDataBars") end,
        function(val) 
            Options:set("lockDataBars", val)
            local DataTexts = MiniMapRedux.import("DataTexts")
            if DataTexts and DataTexts.UpdateDataBarLocks then
                DataTexts:UpdateDataBarLocks()
            end
        end,
        "Lock data bars in place to prevent accidental moving")
    
    -- Show/hide data text icons option
    self:CreateModernCheckbox(content, "Show Data Text Icons", 400, -105,
        function() return Options:get("showDataTextIcons") end,
        function(val) 
            Options:set("showDataTextIcons", val)
            local DataTexts = MiniMapRedux.import("DataTexts")
            if DataTexts and DataTexts.UpdateDataTextIconVisibility then
                DataTexts:UpdateDataTextIconVisibility()
            end
        end,
        "Toggle visibility of icons in data texts")
    
    -- Data Bars Section
    local barsTitle = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    barsTitle:SetPoint("TOPLEFT", 20, -140)
    barsTitle:SetText("Data Bars (1-10)")
    barsTitle:SetTextColor(1, 0.8, 0.3, 1)
    
    -- Creating Data Bars section
    
    local currentY = -170
    
    for i = 1, 10 do
        -- Data bar toggle
        self:CreateModernCheckbox(content, "Data Bar " .. i, 30, currentY,
            function() return Options:get("showDataBar" .. i) end,
            function(val) 
                Options:set("showDataBar" .. i, val)
                local DataTexts = MiniMapRedux.import("DataTexts")
                if DataTexts and DataTexts.RefreshDataTexts then
                    DataTexts:RefreshDataTexts()
                end
            end,
            "Toggle visibility of Data Bar " .. i)
        
        -- Opacity slider for this data bar
        local opacityLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        opacityLabel:SetPoint("TOPLEFT", 50, currentY - 25)
        opacityLabel:SetText("Opacity:")
        opacityLabel:SetTextColor(0.8, 0.8, 0.9, 1)
        
        local opacitySlider = CreateFrame("Slider", nil, content, "OptionsSliderTemplate")
        opacitySlider:SetPoint("LEFT", opacityLabel, "RIGHT", 10, 0)
        opacitySlider:SetSize(100, 20)
        opacitySlider:SetMinMaxValues(0, 1)
        opacitySlider:SetValue(Options:get("dataBar" .. i .. "Opacity") or 0.9)
        opacitySlider:SetValueStep(0.1)
        
        opacitySlider:SetScript("OnValueChanged", function(self, value)
            Options:set("dataBar" .. i .. "Opacity", value)
            local DataTexts = MiniMapRedux.import("DataTexts")
            if DataTexts and DataTexts.UpdateDataBarOpacity then
                DataTexts:UpdateDataBarOpacity()
            end
        end)
        
        -- Font size slider
        local fontLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fontLabel:SetPoint("LEFT", opacitySlider, "RIGHT", 20, 0)
        fontLabel:SetText("Font Size:")
        fontLabel:SetTextColor(0.8, 0.8, 0.9, 1)
        
        local fontSlider = CreateFrame("Slider", nil, content, "OptionsSliderTemplate")
        fontSlider:SetPoint("LEFT", fontLabel, "RIGHT", 10, 0)
        fontSlider:SetSize(80, 20)
        fontSlider:SetMinMaxValues(8, 20)
        fontSlider:SetValue(Options:get("dataBar" .. i .. "FontSize") or 13)
        fontSlider:SetValueStep(1)
        
        fontSlider:SetScript("OnValueChanged", function(self, value)
            Options:set("dataBar" .. i .. "FontSize", value)
            local DataTexts = MiniMapRedux.import("DataTexts")
            if DataTexts and DataTexts.UpdateDataBarFontSizes then
                DataTexts:UpdateDataBarFontSizes()
            end
        end)
        
        currentY = currentY - 60
    end
    
end

-- Create Data Texts tab content (moved from Data Bars tab)
function StandaloneConfig:CreateDataTextsContent(content, Options)
    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetText("Data Text Assignments")
    title:SetTextColor(0.3, 0.6, 1, 1)
    
    local desc = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
    desc:SetText("Assign each data text to a specific data bar or the minimap")
    desc:SetTextColor(0.8, 0.8, 0.8, 1)
    
    -- Get available data texts dynamically
    local DataTexts = MiniMapRedux.import("DataTexts")
    local availableDataTexts = {}
    
    if DataTexts and DataTexts.GetAvailableDataTexts then
        availableDataTexts = DataTexts:GetAvailableDataTexts()
        
        -- If no data texts are available, try to initialize the DataTexts module
        local count = 0
        for _ in pairs(availableDataTexts) do count = count + 1 end
        
        if count == 0 then
            if DataTexts.InitializeModule then
                DataTexts:InitializeModule()
                -- Try to get available data texts again
                availableDataTexts = DataTexts:GetAvailableDataTexts()
                -- Add a delayed refresh to ensure all data texts are registered
                C_Timer.After(1.0, function()
                    DataTexts:RefreshDataTexts()
                    -- Try to get available data texts again after the refresh
                    availableDataTexts = DataTexts:GetAvailableDataTexts()
                end)
            end
        end
    else
        -- DataTexts module not available or missing GetAvailableDataTexts
    end
    
    -- Define category mappings for organizing data texts
    local categoryMappings = {
        ["Character Information"] = {
            keys = {"experience", "gold", "durability", "talents", "bags", "itemlevel", "lootspec", "professions", "repair", "played"},
            color = {0.3, 1, 0.3, 1}
        },
        ["World & Location"] = {
            keys = {"coordinates", "clock", "reputation", "currency", "renown", "speed", "quests", "calendar"},
            color = {0.3, 0.8, 1, 1}
        },
        ["Social & Communication"] = {
            keys = {"friends", "guild", "mail"},
            color = {1, 0.6, 1, 1}
        },
        ["Dungeons & PvP"] = {
            keys = {"keystone", "vault", "lockouts", "delves", "pvprating"},
            color = {0.6, 0.2, 1, 1}
        },
        ["System & Misc"] = {
            keys = {"performance", "memory", "session", "wowtoken", "volume", "housing"},
            color = {1, 0.8, 0.3, 1}
        },
        ["Other"] = {
            keys = {},
            color = {0.8, 0.8, 0.8, 1}
        }
    }
    
    -- Organize available data texts into categories
    local organizedDataTexts = {}
    local usedKeys = {}
    
    -- First pass: assign known data texts to their categories
    for categoryName, categoryInfo in pairs(categoryMappings) do
        if categoryName ~= "Other" then
            organizedDataTexts[categoryName] = {
                color = categoryInfo.color,
                texts = {}
            }
            
            for _, key in ipairs(categoryInfo.keys) do
                if availableDataTexts[key] then
                    table.insert(organizedDataTexts[categoryName].texts, {
                        key = key,
                        name = availableDataTexts[key].name or key:gsub("^%l", string.upper)
                    })
                    usedKeys[key] = true
                end
            end
        end
    end
    
    -- Second pass: put any remaining data texts in "Other" category
    local otherTexts = {}
    for key, config in pairs(availableDataTexts) do
        if not usedKeys[key] then
            table.insert(otherTexts, {
                key = key,
                name = config.name or key:gsub("^%l", string.upper)
            })
        end
    end
    
    -- Add "Other" category if we have uncategorized data texts
    if #otherTexts > 0 then
        organizedDataTexts["Other"] = {
            color = categoryMappings["Other"].color,
            texts = otherTexts
        }
    end
    
    -- Create the UI dynamically
    local currentY = -60
    
    -- Sort categories for consistent display order
    local categoryOrder = {"Character Information", "World & Location", "Social & Communication", "System Performance", "Other"}
    
    for _, categoryName in ipairs(categoryOrder) do
        local category = organizedDataTexts[categoryName]
        if category and #category.texts > 0 then
            -- Category header
            local categoryHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            categoryHeader:SetPoint("TOPLEFT", 30, currentY)
            categoryHeader:SetText(categoryName)
            -- Use table.unpack if available, otherwise fall back to unpack or manual unpacking
            if table and table.unpack then
                categoryHeader:SetTextColor(table.unpack(category.color))
            elseif unpack then
                categoryHeader:SetTextColor(unpack(category.color))
            else
                -- Manual unpacking for safety
                categoryHeader:SetTextColor(category.color[1] or 1, category.color[2] or 1, category.color[3] or 1, category.color[4] or 1)
            end
            currentY = currentY - 25
            
            -- Data texts in this category
            for _, textInfo in ipairs(category.texts) do
                self:CreateDataTextDropdown(content, textInfo.name, textInfo.key, 50, currentY, Options)
                currentY = currentY - 30
            end
            
            currentY = currentY - 10 -- Extra space between categories
        end
    end
    
    -- If no data texts are available, show a message
    if not next(availableDataTexts) then
        local noDataText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noDataText:SetPoint("TOPLEFT", 30, -60)
        noDataText:SetText("No data texts are currently available. Make sure the Data Texts module is enabled.")
        noDataText:SetTextColor(1, 0.5, 0.5, 1)
    end
end

-- Create Buttons tab content
function StandaloneConfig:CreateButtonsContent(content, Options)
    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetText("Minimap Buttons")
    title:SetTextColor(0.3, 0.6, 1, 1)
    
    -- Auto-hide Feature
    self:CreateModernCheckbox(content, "Auto-hide Button Bar", 30, -60,
        function() return Options:get("hideButtonBar") end,
        function(val) 
            Options:set("hideButtonBar", val)
            local ButtonManager = MiniMapRedux.import("ButtonManager")
            if ButtonManager and ButtonManager.UpdateBarVisibility then
                ButtonManager.UpdateBarVisibility()
            end
        end,
        "Hide button bar when not hovering over it or minimap")
        
    -- Blizzard Button Handling
    self:CreateModernCheckbox(content, "Include Blizzard Buttons", 30, -90,
        function() return Options:get("showBlizzardButtons") end,
        function(val) 
            Options:set("showBlizzardButtons", val)
            -- Trigger button re-collection
            local ButtonManager = MiniMapRedux.import("ButtonManager")
            if ButtonManager and ButtonManager.CollectMinimapButtons then
                C_Timer.After(0.1, ButtonManager.CollectMinimapButtons)
            end
        end,
        "Include Blizzard's default minimap buttons in collection")
        
    -- Button Bar Position
    local positionLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    positionLabel:SetPoint("TOPLEFT", 30, -125)
    positionLabel:SetText("Button Bar Position:")
    
    local positionDropdown = CreateFrame("Frame", nil, content, "UIDropDownMenuTemplate")
    positionDropdown:SetPoint("TOPLEFT", 30, -145)
    positionDropdown:SetSize(120, 20)
    
    local function InitializePositionDropdown(self, level)
        local info = UIDropDownMenu_CreateInfo()
        
        local positions = {
            {text = "Left of Minimap", value = "LEFT"},
            {text = "Right of Minimap", value = "RIGHT"},
            {text = "Top of Minimap", value = "TOP"},
            {text = "Bottom of Minimap", value = "BOTTOM"},
            {text = "Top Right Corner", value = "TOPRIGHT"},
            {text = "Top Left Corner", value = "TOPLEFT"},
            {text = "Bottom Right Corner", value = "BOTTOMRIGHT"},
            {text = "Bottom Left Corner", value = "BOTTOMLEFT"},
        }
        
        for _, pos in ipairs(positions) do
            info.text = pos.text
            info.value = pos.value
            info.func = function()
                Options:set("barPosition", pos.value)
                UIDropDownMenu_SetSelectedValue(positionDropdown, pos.value)
                UIDropDownMenu_SetText(positionDropdown, pos.text)
                
                -- Immediately update button bar position
                local ButtonManager = MiniMapRedux.import("ButtonManager")
                if ButtonManager and MiniMapRedux.buttonBar then
                    MiniMapRedux.buttonBar:ClearAllPoints()
                    
                    -- Apply the new position immediately
                    if pos.value == "LEFT" then
                        MiniMapRedux.buttonBar:SetPoint("TOPRIGHT", Minimap, "TOPLEFT", -9, 0)
                    elseif pos.value == "TOP" then
                        MiniMapRedux.buttonBar:SetPoint("BOTTOM", Minimap, "TOP", 0, 9)
                    elseif pos.value == "BOTTOM" then
                        MiniMapRedux.buttonBar:SetPoint("TOP", Minimap, "BOTTOM", 0, -9)
                    elseif pos.value == "TOPRIGHT" then
                        MiniMapRedux.buttonBar:SetPoint("BOTTOMLEFT", Minimap, "TOPRIGHT", 9, 9)
                    elseif pos.value == "TOPLEFT" then
                        MiniMapRedux.buttonBar:SetPoint("BOTTOMRIGHT", Minimap, "TOPLEFT", -9, 9)
                    elseif pos.value == "BOTTOMRIGHT" then
                        MiniMapRedux.buttonBar:SetPoint("TOPLEFT", Minimap, "BOTTOMRIGHT", 9, -9)
                    elseif pos.value == "BOTTOMLEFT" then
                        MiniMapRedux.buttonBar:SetPoint("TOPRIGHT", Minimap, "BOTTOMLEFT", -9, -9)
                    else -- Default to RIGHT
                        MiniMapRedux.buttonBar:SetPoint("TOPLEFT", Minimap, "TOPRIGHT", 9, 0)
                    end
                    
                    -- Ensure the bar is visible
                    MiniMapRedux.buttonBar:Show()
                end
            end
            info.checked = (Options:get("barPosition") == pos.value)
            UIDropDownMenu_AddButton(info)
        end
    end
    
    UIDropDownMenu_Initialize(positionDropdown, InitializePositionDropdown)
    local currentPos = Options:get("barPosition") or "RIGHT"
    UIDropDownMenu_SetSelectedValue(positionDropdown, currentPos)
    
    -- Set display text based on current position
    local positionTexts = {
        LEFT = "Left of Minimap",
        RIGHT = "Right of Minimap",
        TOP = "Top of Minimap",
        BOTTOM = "Bottom of Minimap",
        TOPRIGHT = "Top Right Corner",
        TOPLEFT = "Top Left Corner",
        BOTTOMRIGHT = "Bottom Right Corner",
        BOTTOMLEFT = "Bottom Left Corner"
    }
    UIDropDownMenu_SetText(positionDropdown, positionTexts[currentPos] or "Right of Minimap")
    
    -- Button Bar Orientation
    local orientationLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    orientationLabel:SetPoint("TOPLEFT", 230, -125)
    orientationLabel:SetText("Button Layout:")
    
    local orientationDropdown = CreateFrame("Frame", nil, content, "UIDropDownMenuTemplate")
    orientationDropdown:SetPoint("TOPLEFT", 230, -145)
    orientationDropdown:SetSize(120, 20)
    
    local function InitializeOrientationDropdown(self, level)
        local info = UIDropDownMenu_CreateInfo()
        
        info.text = "Vertical"
        info.value = "VERTICAL"
        info.func = function()
            Options:set("buttonBarOrientation", "VERTICAL")
            UIDropDownMenu_SetSelectedValue(orientationDropdown, "VERTICAL")
            UIDropDownMenu_SetText(orientationDropdown, "Vertical")
            -- Trigger button re-positioning
            local ButtonManager = MiniMapRedux.import("ButtonManager")
            if ButtonManager and MiniMapRedux.buttonBar and MiniMapRedux.collectedAddonButtons then
                ButtonManager.PositionButtons(MiniMapRedux.collectedAddonButtons, MiniMapRedux.buttonBar)
            end
        end
        info.checked = (Options:get("buttonBarOrientation") == "VERTICAL" or Options:get("buttonBarOrientation") == nil)
        UIDropDownMenu_AddButton(info)
        
        info.text = "Horizontal"
        info.value = "HORIZONTAL"
        info.func = function()
            Options:set("buttonBarOrientation", "HORIZONTAL")
            UIDropDownMenu_SetSelectedValue(orientationDropdown, "HORIZONTAL")
            UIDropDownMenu_SetText(orientationDropdown, "Horizontal")
            -- Trigger button re-positioning
            local ButtonManager = MiniMapRedux.import("ButtonManager")
            if ButtonManager and MiniMapRedux.buttonBar and MiniMapRedux.collectedAddonButtons then
                ButtonManager.PositionButtons(MiniMapRedux.collectedAddonButtons, MiniMapRedux.buttonBar)
            end
        end
        info.checked = (Options:get("buttonBarOrientation") == "HORIZONTAL")
        UIDropDownMenu_AddButton(info)
    end
    
    UIDropDownMenu_Initialize(orientationDropdown, InitializeOrientationDropdown)
    local currentOrientation = Options:get("buttonBarOrientation") or "VERTICAL"
    UIDropDownMenu_SetSelectedValue(orientationDropdown, currentOrientation)
    UIDropDownMenu_SetText(orientationDropdown, currentOrientation == "HORIZONTAL" and "Horizontal" or "Vertical")
    
    -- Manual Refresh Button
    local refreshButton = CreateFrame("Button", nil, content)
    refreshButton:SetSize(120, 25)
    refreshButton:SetPoint("TOPLEFT", 30, -190)
    
    local refreshBg = refreshButton:CreateTexture(nil, "BACKGROUND")
    refreshBg:SetAllPoints()
    refreshBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    refreshBg:SetVertexColor(0.3, 0.6, 1, 0.8)
    
    local refreshText = refreshButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    refreshText:SetPoint("CENTER")
    refreshText:SetText("Refresh Buttons")
    refreshText:SetTextColor(1, 1, 1)
    
    refreshButton:SetScript("OnClick", function()
        local ButtonManager = MiniMapRedux.import("ButtonManager")
        if ButtonManager and ButtonManager.CollectMinimapButtons then
            ButtonManager.CollectMinimapButtons()
        end
    end)
    
    refreshButton:SetScript("OnEnter", function(self)
        refreshBg:SetVertexColor(0.4, 0.7, 1, 1)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Manually refresh button collection")
        GameTooltip:Show()
    end)
    
    refreshButton:SetScript("OnLeave", function(self)
        refreshBg:SetVertexColor(0.3, 0.6, 1, 0.8)
        GameTooltip:Hide()
    end)
    
    -- Button Customization Section
    local customizationTitle = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    customizationTitle:SetPoint("TOPLEFT", 20, -230)
    customizationTitle:SetText("Button Bar Customization")
    customizationTitle:SetTextColor(0.9, 0.9, 0.9, 1)
    
    -- Button Size Slider
    self:CreateModernSlider(content, "Button Size", 30, -270, 16, 40, 
        function() return Options:get("buttonBarButtonSize") or 26 end,
        function(val) 
            Options:set("buttonBarButtonSize", val)
            -- Refresh button bar if it exists
            local ButtonManager = MiniMapRedux.import("ButtonManager")
            if ButtonManager and MiniMapRedux.buttonBar and MiniMapRedux.collectedAddonButtons then
                ButtonManager.PositionButtons(MiniMapRedux.collectedAddonButtons, MiniMapRedux.buttonBar)
            end
        end,
        "Adjust the size of buttons in the button bar (16-40 pixels)"
    )
    
    -- Background Opacity Slider
    self:CreateModernSlider(content, "Background Opacity", 30, -330, 0, 100,
        function() return Options:get("buttonBarBackgroundOpacity") or 85 end,
        function(val)
            Options:set("buttonBarBackgroundOpacity", val)
            -- Refresh button bar background if it exists
            local ButtonManager = MiniMapRedux.import("ButtonManager")
            if ButtonManager and MiniMapRedux.buttonBar and MiniMapRedux.collectedAddonButtons then
                ButtonManager.PositionButtons(MiniMapRedux.collectedAddonButtons, MiniMapRedux.buttonBar)
            end
        end,
        "Adjust button bar background opacity (0 = no background, 100 = solid background)"
    )
end

-- Create Advanced tab content
function StandaloneConfig:CreateAdvancedContent(content, Options)
    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetText("Advanced Settings")
    title:SetTextColor(0.3, 0.6, 1, 1)
    
    local desc = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
    desc:SetText("Advanced configuration options for MiniMapRedux")
    desc:SetTextColor(0.8, 0.8, 0.8, 1)
    
    -- Reset button with modern styling
    local resetButton = CreateFrame("Button", nil, content)
    resetButton:SetSize(150, 35)
    resetButton:SetPoint("TOPLEFT", 30, -80)
    
    local resetBg = resetButton:CreateTexture(nil, "BACKGROUND")
    resetBg:SetAllPoints()
    resetBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    resetBg:SetVertexColor(0.8, 0.3, 0.3, 0.8)
    
    local resetText = resetButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    resetText:SetPoint("CENTER")
    resetText:SetText("Reset All Settings")
    resetText:SetTextColor(1, 1, 1, 1)
    
    resetButton:SetScript("OnClick", function()
        Options:reset()
        -- Refresh the UI
        if self.configFrame then
            self.configFrame:Hide()
            self.configFrame = nil
            self:ShowConfigWindow()
        end
    end)
    
    resetButton:SetScript("OnEnter", function()
        resetBg:SetVertexColor(1, 0.4, 0.4, 1)
    end)
    
    resetButton:SetScript("OnLeave", function()
        resetBg:SetVertexColor(0.8, 0.3, 0.3, 0.8)
    end)
    
    -- Add some information about what advanced settings do
    local infoText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    infoText:SetPoint("TOPLEFT", 30, -130)
    infoText:SetText("Use this option to reset all configuration settings to their default values. This cannot be undone.")
    infoText:SetTextColor(1, 0.8, 0.8, 1)
    infoText:SetWidth(400)
    infoText:SetJustifyH("LEFT")
end

-- Show the standalone configuration window
function StandaloneConfig:ShowConfigWindow()
    local Options, Debug = GetDependencies()
    
    -- Debug info
    if Debug and Debug.enabled then
        Debug:Log("StandaloneConfig: ShowConfigWindow called")
    end
    
    local frame = self:CreateConfigWindow()
    if not frame then
        if Debug and Debug.enabled then
            Debug:Log("StandaloneConfig: Failed to create config window")
        end
        
        -- Try the standard config panel as fallback
        local ConfigPanel = MiniMapRedux and MiniMapRedux.import and MiniMapRedux.import("ConfigPanel")
        if ConfigPanel and ConfigPanel.ShowConfigPanel then
            if Debug and Debug.enabled then
                Debug:Log("StandaloneConfig: Falling back to standard ConfigPanel")
            end
            ConfigPanel.ShowConfigPanel()
        else
            if Debug and Debug.enabled then
                Debug:Log("StandaloneConfig: ConfigPanel also not available")
            end
            -- Configuration panel not available
        end
        return
    end
    
    frame:Show()
    
    if Debug and Debug.enabled then
        Debug:Log("StandaloneConfig: Config window shown successfully")
    end
end

-- Close the standalone configuration window
function StandaloneConfig:CloseConfigWindow()
    if self.configFrame then
        self.configFrame:Hide()
    end
end

-- Toggle the standalone configuration window
function StandaloneConfig:ToggleConfigWindow()
    if self.configFrame and self.configFrame:IsShown() then
        self:CloseConfigWindow()
    else
        self:ShowConfigWindow()
    end
end

-- Export the module - defer until MiniMapRedux is available
local function ExportModule()
    if MiniMapRedux and MiniMapRedux.export then
        -- Try to import Debug module
        local Debug = MiniMapRedux.import and MiniMapRedux.import("Debug")
        
        -- Export the module
        MiniMapRedux.export("StandaloneConfig", StandaloneConfig)
        
        if Debug and Debug.enabled then
            Debug:Log("StandaloneConfig: Module exported successfully")
        end
        -- StandaloneConfig initialized silently
    else
        -- Keep track of attempts
        StandaloneConfig.exportAttempts = (StandaloneConfig.exportAttempts or 0) + 1
        
        -- Give up after too many attempts
        if StandaloneConfig.exportAttempts > 20 then
            -- Failed to export StandaloneConfig after multiple attempts
            return
        end
        
        -- Try again after a short delay
        C_Timer.After(0.2, ExportModule)
    end
end

-- Call export function
ExportModule()

return StandaloneConfig
