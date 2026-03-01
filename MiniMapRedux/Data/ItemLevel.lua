local addonName, _ = ...
local MiniMapRedux = _G.MiniMapRedux

-- ItemLevel Data Text Module
local ItemLevel = {}

-- Check if Item Level API is available (only Retail/TWW)
local function IsItemLevelAvailable()
    return GetAverageItemLevel ~= nil
end

-- Get item level data
local function GetItemLevelData()
    if not IsItemLevelAvailable() then
        return {
            equipped = 0,
            overall = 0
        }
    end

    local avgItemLevel, avgItemLevelEquipped = GetAverageItemLevel()

    return {
        equipped = avgItemLevelEquipped or 0,
        overall = avgItemLevel or 0
    }
end

-- Format the item level text
local function FormatItemLevelText(data, options)
    local showIcons = options and options:get("showDataTextIcons")
    local icon = showIcons and "|TInterface\\Icons\\INV_Misc_ArmorKit_17:14:14:0:0|t " or ""

    -- Show equipped and overall if they differ
    local equipped = string.format("%.1f", data.equipped)
    local overall = string.format("%.1f", data.overall)

    if data.overall > data.equipped + 1 then
        return icon .. "iLvl: " .. equipped .. " (" .. overall .. ")"
    end
    return icon .. "iLvl: " .. equipped
end

-- Get tooltip lines
local function GetItemLevelTooltip()
    if not IsItemLevelAvailable() then
        return {
            { text = "Item Level", color = {1, 1, 1} },
            { text = " ", color = {1, 1, 1} },
            { text = "Not available in this game version", color = {0.6, 0.6, 0.6} },
        }
    end

    local data = GetItemLevelData()

    return {
        { text = "Item Level", color = {1, 1, 1} },
        { text = " ", color = {1, 1, 1} },
        { text = "Equipped: " .. string.format("%.1f", data.equipped), color = {0.3, 1, 0.3} },
        { text = "Overall: " .. string.format("%.1f", data.overall), color = {0.3, 0.8, 1} },
        { text = " ", color = {1, 1, 1} },
        { text = "Overall includes items in bags", color = {0.6, 0.6, 0.6} },
    }
end

-- Click handler
local function OnItemLevelClick(button)
    if button == "LeftButton" then
        -- Open character frame to equipment tab
        if not CharacterFrame:IsShown() then
            ToggleCharacter("PaperDollFrame")
        end
    end
end

-- Update function
function ItemLevel:Update()
    if not IsItemLevelAvailable() then
        return "|cff888888iLvl N/A|r"
    end

    local Options = MiniMapRedux.import("Options")
    if not Options then return "" end

    local data = GetItemLevelData()
    return FormatItemLevelText(data, Options)
end

-- Get tooltip
function ItemLevel:GetTooltip()
    return GetItemLevelTooltip()
end

-- Click handler
function ItemLevel:OnClick(button)
    OnItemLevelClick(button)
end

-- Events to listen for
function ItemLevel:GetEvents()
    if not IsItemLevelAvailable() then
        return {}
    end

    return {
        "PLAYER_EQUIPMENT_CHANGED",
        "PLAYER_AVG_ITEM_LEVEL_UPDATE",
        "PLAYER_ENTERING_WORLD"
    }
end

-- Build the data text config in the format DataTexts expects
local itemLevelDataText = {
    name = "Item Level",
    color = {0.3, 0.8, 1},
    icon = "Interface\\Icons\\INV_Misc_ArmorKit_17",
    update = function(frame)
        if not IsItemLevelAvailable() then
            frame.text:SetText("|cff888888iLvl N/A|r")
            return
        end
        local Options = MiniMapRedux.import("Options")
        if not Options then return end
        local data = GetItemLevelData()
        frame.text:SetText(FormatItemLevelText(data, Options))
    end,
    tooltip = function()
        local lines = GetItemLevelTooltip()
        GameTooltip:SetText(lines[1].text)
        for i = 2, #lines do
            local line = lines[i]
            GameTooltip:AddLine(line.text, line.color[1], line.color[2], line.color[3])
        end
    end,
    onClick = function()
        OnItemLevelClick("LeftButton")
    end
}

-- Register the item level data text - defer until DataTexts is available
local function RegisterDataText()
    local DataTexts = MiniMapRedux and MiniMapRedux.import("DataTexts")
    if DataTexts and DataTexts.RegisterDataText then
        DataTexts:RegisterDataText("itemlevel", itemLevelDataText)
        if MiniMapRedux.export then
            MiniMapRedux.export("ItemLevel", ItemLevel)
        end
    else
        C_Timer.After(0.1, RegisterDataText)
    end
end

RegisterDataText()

return ItemLevel
