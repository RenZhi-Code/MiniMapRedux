-- Minimap - v7 (Calendar/Clock buttons: position at TOPLEFT when enabled, hide by default)
local addonName, _ = ...
local MiniMapRedux = _G.MiniMapRedux

local MinimapModule = {}

local hiddenFrame = CreateFrame("Frame")
hiddenFrame:Hide()

local Options
local function GetOptions()
    if not Options then
        Options = MiniMapRedux and MiniMapRedux.import and MiniMapRedux.import("Options")
    end
    return Options
end

local function CreateMinimapMask()
    local maskFile = "Interface\\AddOns\\MiniMapRedux\\Media\\MinimapMask"
    if not maskFile then
        local mediaDir = "Interface\\AddOns\\MiniMapRedux\\Media"
        CreateDir(mediaDir)
        
        local mask = CreateFrame("Frame")
        mask:SetSize(256, 256)
        local texture = mask:CreateTexture()
        texture:SetAllPoints()
        texture:SetColorTexture(1, 1, 1, 1)
        
        texture:SetTexture(maskFile)
    end
end

local function CreateMinimapBorder()
    if MiniMapRedux.minimapBorder then 
        MiniMapRedux.minimapBorder:Hide()
        MiniMapRedux.minimapBorder = nil
    end
    
    MiniMapRedux.minimapBorder = CreateFrame("Frame", "MiniMapReduxMinimapBorder", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    local border = MiniMapRedux.minimapBorder
    
    border:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)
    border:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 0, 0)
    border:SetFrameStrata("MEDIUM")
    border:SetFrameLevel(Minimap:GetFrameLevel() + 1)
    
    border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 4,
        insets = {left = 0, right = 0, top = 0, bottom = 0}
    })
    border:SetBackdropBorderColor(0, 0, 0, 1)

    -- Use a ticker instead of OnUpdate to reduce CPU usage (check every 0.5 seconds instead of every frame)
    border.lastScale = Minimap:GetScale()
    C_Timer.NewTicker(0.5, function()
        if not border or not Minimap then return end
        local scale = Minimap:GetScale()
        if border.lastScale ~= scale then
            border.lastScale = scale
            border:ClearAllPoints()
            border:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)
            border:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 0, 0)
        end
    end)

    border:Show()
    border:SetAlpha(1)
    
    border:EnableMouse(false)
    
    return border
end

function MinimapModule.SetupSquareMinimap()
    if not Minimap then return end

    -- Ensure minimap is visible and properly parented (Critical for Classic)
    -- Following BasicMinimap's approach for maximum compatibility
    Minimap:SetParent(UIParent)
    Minimap:Show()

    if MinimapCluster then
        MinimapCluster:SetParent(UIParent)
        MinimapCluster:Show()
    end

    -- Set square mask for minimap
    Minimap:SetMaskTexture('Interface\\BUTTONS\\WHITE8X8')

    -- Create border
    CreateMinimapBorder()

    -- Configure MinimapCluster if it exists
    if MinimapCluster then
        -- Disable mouse on cluster (BasicMinimap does this)
        if MinimapCluster.EnableMouse then
            MinimapCluster:EnableMouse(false)
        end

        if MinimapCluster.SetClampedToScreen then
            MinimapCluster:SetClampedToScreen(false)
        end

        -- SetResizeBounds is the modern API (10.0+), SetMinResize/SetMaxResize are deprecated
        if MinimapCluster.SetResizeBounds then
            MinimapCluster:SetResizeBounds(0, 0, 9999, 9999)
        elseif MinimapCluster.SetMinResize then
            MinimapCluster:SetMinResize(0, 0)
            if MinimapCluster.SetMaxResize then
                MinimapCluster:SetMaxResize(9999, 9999)
            end
        end
    end

    if Minimap.SetClampedToScreen then
        Minimap:SetClampedToScreen(false)
    end
    
    if MinimapCompassTexture then
        MinimapCompassTexture:Hide()
    end
    if MinimapNorthTag then
        MinimapNorthTag:Hide()
    end

    -- Hide MinimapBorderTop (visible in Classic Era)
    if MinimapCluster and MinimapCluster.BorderTop then
        MinimapCluster.BorderTop:Hide()
    end
    if MinimapBorderTop then
        MinimapBorderTop:Hide()
    end
    
    Minimap:EnableMouseWheel(true)
    Minimap:SetScript("OnMouseWheel", function(self, delta)
        if delta > 0 then
            -- Minimap_ZoomIn may not exist in all clients (deprecated in 12.0+)
            if Minimap_ZoomIn then
                Minimap_ZoomIn()
            elseif Minimap.ZoomIn and Minimap.ZoomIn.Click then
                Minimap.ZoomIn:Click()
            else
                local zoom = Minimap:GetZoom()
                if zoom < Minimap:GetZoomLevels() - 1 then
                    Minimap:SetZoom(zoom + 1)
                end
            end
        else
            if Minimap_ZoomOut then
                Minimap_ZoomOut()
            elseif Minimap.ZoomOut and Minimap.ZoomOut.Click then
                Minimap.ZoomOut:Click()
            else
                local zoom = Minimap:GetZoom()
                if zoom > 0 then
                    Minimap:SetZoom(zoom - 1)
                end
            end
        end
    end)
    
    Minimap:HookScript("OnEnter", function(self)
        if GetOptions():get("hideButtonBar") then
            local ButtonManager = MiniMapRedux.import("ButtonManager")
            ButtonManager.UpdateBarVisibility()
        end
    end)

    Minimap:HookScript("OnLeave", function(self)
        if GetOptions():get("hideButtonBar") then
            C_Timer.After(0.1, function()
                local ButtonManager = MiniMapRedux.import("ButtonManager")
                ButtonManager.UpdateBarVisibility()
            end)
        end
    end)
    
    Minimap:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" then
            -- Modern tracking menu (11.0+ / Retail)
            if MinimapCluster and MinimapCluster.Tracking then
                local tracking = MinimapCluster.Tracking
                -- Try the modern tracking button click
                if tracking.Button and tracking.Button:IsVisible() then
                    tracking.Button:Click()
                    return
                elseif tracking:IsVisible() then
                    tracking:Click()
                    return
                end
            end

            -- Legacy tracking dropdown (Classic/older clients)
            if ToggleDropDownMenu and MiniMapTrackingDropDown then
                ToggleDropDownMenu(1, nil, MiniMapTrackingDropDown, "cursor")
                return
            end

            if MiniMapTrackingButton and MiniMapTrackingButton:IsVisible() then
                MiniMapTrackingButton:Click()
                return
            end

            -- Fallback: try other known tracking frames
            local trackingFrames = {
                _G["MiniMapTrackingFrame"],
                _G["MinimapTracking"],
                _G["MinimapClusterTracking"],
                _G["MinimapClusterTrackingButton"]
            }

            for _, frame in ipairs(trackingFrames) do
                if frame and frame.Click then
                    frame:Click()
                    return
                end
            end
        end
    end)
    
    if Minimap and GetOptions():get("minimapScale") then
        Minimap:SetScale(GetOptions():get("minimapScale"))
        if MinimapCluster then
            MinimapCluster:SetScale(GetOptions():get("minimapScale"))
        end
    end

    -- Frame strata and level setup (defensive for Classic compatibility)
    if Minimap.SetFrameStrata then
        Minimap:SetFrameStrata("LOW")
    end
    if MinimapCluster then
        if MinimapCluster.SetFrameStrata then
            MinimapCluster:SetFrameStrata("LOW")
        end
        if MinimapCluster.SetFrameLevel then
            MinimapCluster:SetFrameLevel(1)
        end
    end
    if Minimap.SetFrameLevel then
        Minimap:SetFrameLevel(2)
    end
    
    if not Minimap.minimapimousScaleHooked then
        local originalSetScale = Minimap.SetScale
        Minimap.SetScale = function(self, scale)
            originalSetScale(self, scale)
            C_Timer.After(0.1, function()
                MinimapModule.UpdateUIElementVisibility()
            end)
        end
        Minimap.minimapimousScaleHooked = true
    end
    
    if MinimapCluster and not MinimapCluster.minimapimousScaleHooked then
        local originalSetScale = MinimapCluster.SetScale
        MinimapCluster.SetScale = function(self, scale)
            originalSetScale(self, scale)
            C_Timer.After(0.1, function()
                MinimapModule.UpdateUIElementVisibility()
            end)
        end
        MinimapCluster.minimapimousScaleHooked = true
    end

    if not MinimapModule.iconHooksInstalled then
        local function CreateShowHook(frame)
            if frame and not frame.mmrShowHooked then
                hooksecurefunc(frame, "Show", function(self)
                    C_Timer.After(0.1, function()
                        local options = GetOptions()
                        if not options then return end

                        -- Check for IndicatorFrame existence (not available in Classic)
                        if MinimapCluster and MinimapCluster.IndicatorFrame then
                            if self == MinimapCluster.IndicatorFrame.MailFrame then
                                if not options:get("showMailIcon") then
                                    self:Hide()
                                end
                            elseif self == MinimapCluster.IndicatorFrame.CraftingOrderFrame then
                                if not options:get("showCraftingOrderIcon") then
                                    self:Hide()
                                end
                            end
                        end

                        if MinimapCluster and self == MinimapCluster.InstanceDifficulty then
                            if not options:get("showInstanceDifficulty") then
                                self:SetParent(hiddenFrame)
                            end
                        elseif self == _G.ExpansionLandingPageMinimapButton then
                            if not options:get("showMissionsButton") then
                                self:SetParent(hiddenFrame)
                            end
                        elseif self == _G.GameTimeFrame then
                            if not options:get("showCalendarButton") then
                                self:SetParent(hiddenFrame)
                            end
                        elseif self == _G.AddonCompartmentFrame then
                            if not options:get("showAddonCompartment") then
                                self:SetParent(hiddenFrame)
                            end
                        end
                    end)
                end)
                frame.mmrShowHooked = true
            end
        end

        if MinimapCluster and MinimapCluster.IndicatorFrame then
            if MinimapCluster.IndicatorFrame.MailFrame then
                CreateShowHook(MinimapCluster.IndicatorFrame.MailFrame)
            end
            if MinimapCluster.IndicatorFrame.CraftingOrderFrame then
                CreateShowHook(MinimapCluster.IndicatorFrame.CraftingOrderFrame)
            end
        end

        if MinimapCluster and MinimapCluster.InstanceDifficulty then
            CreateShowHook(MinimapCluster.InstanceDifficulty)
        end

        if _G.ExpansionLandingPageMinimapButton then
            CreateShowHook(_G.ExpansionLandingPageMinimapButton)
        end

        if _G.GameTimeFrame then
            CreateShowHook(_G.GameTimeFrame)
        end

        if _G.AddonCompartmentFrame then
            CreateShowHook(_G.AddonCompartmentFrame)
        end

        MinimapModule.iconHooksInstalled = true
    end

    C_Timer.After(0.2, function()
        MinimapModule.UpdateIconVisibility()
    end)
end

function MinimapModule.UpdateIconVisibility()
    local options = GetOptions()
    if not options then return end

    -- Ensure IndicatorFrame is visible and properly set up (Retail)
    if MinimapCluster and MinimapCluster.IndicatorFrame then
        MinimapCluster.IndicatorFrame:SetParent(Minimap)
        MinimapCluster.IndicatorFrame:Show()
    end

    if MinimapCluster and MinimapCluster.IndicatorFrame and MinimapCluster.IndicatorFrame.MailFrame then
        if options:get("showMailIcon") then
            MinimapCluster.IndicatorFrame.MailFrame:SetParent(MinimapCluster.IndicatorFrame)
            MinimapCluster.IndicatorFrame.MailFrame:ClearAllPoints()
            MinimapCluster.IndicatorFrame.MailFrame:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 5, 5)
            -- Don't force show - let the game control visibility based on mail status
        else
            MinimapCluster.IndicatorFrame.MailFrame:Hide()
        end
    end

    if _G.MiniMapMailFrame then
        if options:get("showMailIcon") then
            _G.MiniMapMailFrame:SetParent(Minimap)
            _G.MiniMapMailFrame:ClearAllPoints()
            _G.MiniMapMailFrame:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 5, 5)
            -- Don't force show - let the game control visibility based on mail status
        else
            _G.MiniMapMailFrame:SetParent(hiddenFrame)
        end
    end

    if _G.MinimapMailIcon then
        if options:get("showMailIcon") then
            _G.MinimapMailIcon:SetParent(Minimap)
            _G.MinimapMailIcon:ClearAllPoints()
            _G.MinimapMailIcon:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 5, 5)
            -- Don't force show - let the game control visibility based on mail status
        else
            _G.MinimapMailIcon:SetParent(hiddenFrame)
        end
    end

    if MinimapCluster and MinimapCluster.IndicatorFrame and MinimapCluster.IndicatorFrame.CraftingOrderFrame then
        if options:get("showCraftingOrderIcon") then
            MinimapCluster.IndicatorFrame.CraftingOrderFrame:SetParent(MinimapCluster.IndicatorFrame)
            MinimapCluster.IndicatorFrame.CraftingOrderFrame:ClearAllPoints()
            MinimapCluster.IndicatorFrame.CraftingOrderFrame:SetPoint("BOTTOM", Minimap, "BOTTOM", 0, 2)
            -- Don't force show - let the game control visibility based on crafting order status
        else
            MinimapCluster.IndicatorFrame.CraftingOrderFrame:Hide()
        end
    end

    if MinimapCluster and MinimapCluster.InstanceDifficulty then
        if options:get("showInstanceDifficulty") then
            MinimapCluster.InstanceDifficulty:SetParent(Minimap)
            MinimapCluster.InstanceDifficulty:ClearAllPoints()
            MinimapCluster.InstanceDifficulty:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -5, -5)
            MinimapCluster.InstanceDifficulty:Show()
        else
            MinimapCluster.InstanceDifficulty:SetParent(hiddenFrame)
        end
    end
    if _G.MiniMapInstanceDifficulty then
        if options:get("showInstanceDifficulty") then
            _G.MiniMapInstanceDifficulty:SetParent(Minimap)
            _G.MiniMapInstanceDifficulty:ClearAllPoints()
            _G.MiniMapInstanceDifficulty:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -5, -5)
            _G.MiniMapInstanceDifficulty:Show()
        else
            _G.MiniMapInstanceDifficulty:SetParent(hiddenFrame)
        end
    end
    if _G.GuildInstanceDifficulty then
        if options:get("showInstanceDifficulty") then
            _G.GuildInstanceDifficulty:SetParent(Minimap)
            _G.GuildInstanceDifficulty:ClearAllPoints()
            _G.GuildInstanceDifficulty:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -5, -5)
            _G.GuildInstanceDifficulty:Show()
        else
            _G.GuildInstanceDifficulty:SetParent(hiddenFrame)
        end
    end
    if _G.MiniMapChallengeMode then
        if options:get("showInstanceDifficulty") then
            _G.MiniMapChallengeMode:SetParent(Minimap)
            _G.MiniMapChallengeMode:ClearAllPoints()
            _G.MiniMapChallengeMode:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -5, -5)
            _G.MiniMapChallengeMode:Show()
        else
            _G.MiniMapChallengeMode:SetParent(hiddenFrame)
        end
    end

    if _G.ExpansionLandingPageMinimapButton then
        if options:get("showMissionsButton") then
            _G.ExpansionLandingPageMinimapButton:SetParent(Minimap)
            _G.ExpansionLandingPageMinimapButton:Show()
        else
            _G.ExpansionLandingPageMinimapButton:SetParent(hiddenFrame)
        end
    elseif _G.GarrisonLandingPageMinimapButton then
        if options:get("showMissionsButton") then
            _G.GarrisonLandingPageMinimapButton:SetParent(Minimap)
            _G.GarrisonLandingPageMinimapButton:Show()
        else
            _G.GarrisonLandingPageMinimapButton:SetParent(hiddenFrame)
        end
    end

    if _G.GameTimeFrame then
        if options:get("showCalendarButton") then
            _G.GameTimeFrame:SetParent(Minimap)
            _G.GameTimeFrame:ClearAllPoints()
            _G.GameTimeFrame:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 2, -2)
            _G.GameTimeFrame:Show()
        else
            _G.GameTimeFrame:SetParent(hiddenFrame)
        end
    end

    -- Time/Clock button (Classic)
    if _G.TimeManagerClockButton then
        if options:get("showCalendarButton") then
            _G.TimeManagerClockButton:SetParent(Minimap)
            _G.TimeManagerClockButton:ClearAllPoints()
            _G.TimeManagerClockButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 2, -2)
            _G.TimeManagerClockButton:Show()
        else
            _G.TimeManagerClockButton:SetParent(hiddenFrame)
            _G.TimeManagerClockButton:Hide()
        end
    end

    if MinimapCluster and MinimapCluster.Clock then
        if options:get("showCalendarButton") then
            MinimapCluster.Clock:SetParent(Minimap)
            MinimapCluster.Clock:ClearAllPoints()
            MinimapCluster.Clock:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 2, -2)
            MinimapCluster.Clock:Show()
        else
            MinimapCluster.Clock:SetParent(hiddenFrame)
            MinimapCluster.Clock:Hide()
        end
    end

    if _G.AddonCompartmentFrame then
        if options:get("showAddonCompartment") then
            _G.AddonCompartmentFrame:SetParent(Minimap)
            _G.AddonCompartmentFrame:Show()
        else
            _G.AddonCompartmentFrame:SetParent(hiddenFrame)
        end
    end

    if Minimap.ZoomIn and Minimap.ZoomOut then
        if options:get("showZoomButtons") then
            Minimap.ZoomIn:SetParent(Minimap)
            Minimap.ZoomOut:SetParent(Minimap)
            Minimap.ZoomIn:Show()
            Minimap.ZoomOut:Show()
        else
            Minimap.ZoomIn:SetParent(hiddenFrame)
            Minimap.ZoomOut:SetParent(hiddenFrame)
        end
    end
    if _G.MinimapZoomIn and _G.MinimapZoomOut then
        if options:get("showZoomButtons") then
            _G.MinimapZoomIn:SetParent(Minimap)
            _G.MinimapZoomOut:SetParent(Minimap)
            _G.MinimapZoomIn:Show()
            _G.MinimapZoomOut:Show()
        else
            _G.MinimapZoomIn:SetParent(hiddenFrame)
            _G.MinimapZoomOut:SetParent(hiddenFrame)
        end
    end
end

function MinimapModule.UpdateUIElementVisibility()
    MinimapModule.UpdateIconVisibility()

    if MiniMapRedux.minimapBorder then
        MiniMapRedux.minimapBorder:Show()
    end
    
    if MinimapCluster then
        if MinimapCluster.ZoneText then
            MinimapCluster.ZoneText:Hide()
        end
        if MinimapCluster.ZoneTextButton then
            MinimapCluster.ZoneTextButton:Hide()
        end
        
        if MinimapCluster.Tracking then
            MinimapCluster.Tracking:Hide()
        end
        
        local trackingButtons = {
            _G["MinimapTracking"],
            _G["MinimapClusterTracking"], 
            _G["MiniMapTracking"],
            _G["MinimapClusterTrackingButton"],
            _G["MiniMapTrackingButton"],
            _G["MiniMapTrackingFrame"]
        }
        
        for _, button in ipairs(trackingButtons) do
            if button then
                button:Hide()
            end
        end
    end
    
    if Minimap then
        local trackingButtons = {
            _G["MinimapTracking"],
            _G["MinimapClusterTracking"], 
            _G["MiniMapTracking"],
            _G["MinimapClusterTrackingButton"],
            _G["MiniMapTrackingButton"],
            _G["MiniMapTrackingFrame"]
        }
        
        for _, button in ipairs(trackingButtons) do
            if button and button:GetParent() == Minimap then
                button:Hide()
            end
        end
    end
    
    if _G.MinimapToggleButton then
        _G.MinimapToggleButton:Hide()
        _G.MinimapToggleButton:SetParent(hiddenFrame)
    end
    if _G.MiniMapWorldMapButton then
        _G.MiniMapWorldMapButton:Hide()
        _G.MiniMapWorldMapButton:SetParent(hiddenFrame)
    end
    if MinimapCluster and MinimapCluster.WorldMap then
        MinimapCluster.WorldMap:Hide()
        MinimapCluster.WorldMap:SetParent(hiddenFrame)
    end
    
    -- TimeManagerClockButton and Clock are now controlled by showCalendarButton option
    -- They are handled in UpdateIconVisibility instead of being permanently hidden
end

function MinimapModule.CreateMinimapBorder()
    return CreateMinimapBorder()
end

-- Enable/disable minimap movement (for Classic Era where Edit Mode doesn't exist)
function MinimapModule.SetMinimapMovable(enabled)
    if not Minimap then return end

    if enabled then
        -- Use Minimap frame directly for better compatibility
        Minimap:SetMovable(true)
        Minimap:EnableMouse(true)
        Minimap:RegisterForDrag("LeftButton")

        -- Set up drag handlers
        Minimap:SetScript("OnDragStart", function(self)
            self:StartMoving()
        end)
        Minimap:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            -- Save position
            local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
            local opts = GetOptions()
            if opts then
                opts:set("minimapPosition", {
                    point = point,
                    relativePoint = relativePoint,
                    xOfs = xOfs,
                    yOfs = yOfs
                })
            end
        end)
    else
        -- Disable movement - use Minimap frame
        if Minimap then
            Minimap:SetMovable(false)
            -- Keep mouse enabled for zoom and interactions
            Minimap:RegisterForDrag()
            Minimap:SetScript("OnDragStart", nil)
            Minimap:SetScript("OnDragStop", nil)
        end
    end
end

-- Restore saved minimap position
function MinimapModule.RestoreMinimapPosition()
    if not Minimap then return end

    local opts = GetOptions()
    if not opts then return end

    local pos = opts:get("minimapPosition")
    if pos and pos.point then
        Minimap:ClearAllPoints()
        Minimap:SetPoint(pos.point, _G.UIParent, pos.relativePoint, pos.xOfs, pos.yOfs)
    end
end

local function ExportModule()
    if MiniMapRedux and MiniMapRedux.export then
        MiniMapRedux.export("Minimap", MinimapModule)
    else
        C_Timer.After(0.1, ExportModule)
    end
end

ExportModule()