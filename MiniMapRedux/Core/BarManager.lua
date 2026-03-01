local addonName, _ = ...
local MiniMapRedux = _G.MiniMapRedux

-- BarManager Module
-- Handles button bar positioning and visibility

local BarManager = {}

-- Defer Options import until ADDON_LOADED event
local Options
local function GetOptions()
    if not Options and MiniMapRedux and MiniMapRedux.import then
        Options = MiniMapRedux.import("Options")
    end
    return Options
end

function BarManager.UpdateBarPosition()
    if MiniMapRedux.buttonBar then
        MiniMapRedux.buttonBar:ClearAllPoints()
        
        local Options = GetOptions()
        if not Options then return end
        
        if Options:get("barPosition") == "LEFT" then
            MiniMapRedux.buttonBar:SetPoint("TOPRIGHT", Minimap, "TOPLEFT", -9, 0)
        else
            MiniMapRedux.buttonBar:SetPoint("TOPLEFT", Minimap, "TOPRIGHT", 9, 0)
        end
        
        MiniMapRedux.buttonBar:Show()
        
        if MiniMapRedux.collectedAddonButtons then
            local ButtonManager = MiniMapRedux and MiniMapRedux.import and MiniMapRedux.import("ButtonManager")
            if ButtonManager then
                ButtonManager.PositionButtons(MiniMapRedux.collectedAddonButtons, MiniMapRedux.buttonBar)
            end
        end
    end
end

function BarManager.UpdateButtonBarVisibility()
    if MiniMapRedux.buttonBar and MiniMapRedux.buttonsCollected then
        MiniMapRedux.buttonBar:Show()
    end
end

-- Export the module - defer until MiniMapRedux is available
local function ExportModule()
    if MiniMapRedux and MiniMapRedux.export then
        MiniMapRedux.export("BarManager", BarManager)
    else
        -- Try again after a short delay
        C_Timer.After(0.1, ExportModule)
    end
end

-- Call export function
ExportModule()