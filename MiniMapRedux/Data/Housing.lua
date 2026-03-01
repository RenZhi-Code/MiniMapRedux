local addonName, _ = ...
local MiniMapRedux = _G.MiniMapRedux

-- Housing Data Text Module
local Housing = {}

-- Check if Housing API is available
local function IsHousingAvailable()
    return C_Housing ~= nil
end

-- Get housing data
local function GetHousingData()
    if not IsHousingAvailable() then
        return nil
    end

    -- Try to get current house info (using pcall for safety)
    local success, hasHouse = pcall(function()
        return C_Housing.GetCurrentHouseInfo and C_Housing.GetCurrentHouseInfo() ~= nil
    end)

    if not success or not hasHouse then
        return {
            hasHouse = false,
            level = 0,
            favor = 0,
            maxFavor = 0
        }
    end

    -- Get house level and favor
    local favor, maxFavor = 0, 100
    if C_Housing.GetCurrentHouseLevelFavor then
        local success2, favorData = pcall(C_Housing.GetCurrentHouseLevelFavor)
        if success2 and favorData then
            favor = favorData or 0
        end
    end

    -- Try to determine house level (if API provides it)
    local level = 1

    return {
        hasHouse = true,
        level = level,
        favor = favor,
        maxFavor = maxFavor
    }
end

-- Format the housing text
local function FormatHousingText(data, options)
    if not data then
        return "|cff888888No Housing|r"
    end

    if not data.hasHouse then
        return "|cff888888No House|r"
    end

    local showIcons = options and options:get("showDataTextIcons")
    local icon = showIcons and "|TInterface\\Icons\\INV_Misc_Key_14:14:14:0:0|t " or ""

    -- Show level and favor
    local favorPercent = (data.favor / data.maxFavor) * 100

    -- Color based on favor progress
    local color = "|cff00ff00" -- Green
    if favorPercent < 30 then
        color = "|cffff4444" -- Red
    elseif favorPercent < 70 then
        color = "|cffffff44" -- Yellow
    end

    return icon .. "Lvl " .. data.level .. " " .. color .. string.format("%.0f%%|r", favorPercent)
end

-- Get tooltip lines
local function GetHousingTooltip()
    local data = GetHousingData()

    if not data or not data.hasHouse then
        return {
            { text = "Housing System", color = {1, 1, 1} },
            { text = " ", color = {1, 1, 1} },
            { text = "No house available", color = {0.6, 0.6, 0.6} },
            { text = " ", color = {1, 1, 1} },
            { text = "Left-Click: Open Housing UI", color = {0.3, 1, 0.3} },
        }
    end

    local favorPercent = (data.favor / data.maxFavor) * 100

    return {
        { text = "Housing Progress", color = {1, 1, 1} },
        { text = " ", color = {1, 1, 1} },
        { text = "House Level: " .. data.level, color = {0.3, 0.8, 1} },
        { text = "Favor: " .. data.favor .. " / " .. data.maxFavor .. " (" .. string.format("%.1f%%", favorPercent) .. ")", color = {0.3, 1, 0.3} },
        { text = " ", color = {1, 1, 1} },
        { text = "Earn favor to level up your house", color = {0.6, 0.6, 0.6} },
        { text = "and unlock new features", color = {0.6, 0.6, 0.6} },
        { text = " ", color = {1, 1, 1} },
        { text = "Left-Click: Open Housing UI", color = {0.3, 1, 0.3} },
    }
end

-- Click handler
local function OnHousingClick(button)
    if button == "LeftButton" then
        -- Try to open housing UI
        if C_Housing and C_Housing.OpenHousingUI then
            local success = pcall(C_Housing.OpenHousingUI)
            if not success then
                print("|cff3399ffMiniMapRedux:|r Housing UI not available")
            end
        else
            -- Fallback: show message if API not available
            print("|cff3399ffMiniMapRedux:|r Housing UI not available")
        end
    end
end

-- Update function
function Housing:Update()
    if not IsHousingAvailable() then
        return "|cff888888Housing N/A|r"
    end

    local Options = MiniMapRedux.import("Options")
    local data = GetHousingData()

    return FormatHousingText(data, Options)
end

-- Get tooltip
function Housing:GetTooltip()
    return GetHousingTooltip()
end

-- Click handler
function Housing:OnClick(button)
    OnHousingClick(button)
end

-- Events to listen for
function Housing:GetEvents()
    -- Return empty table if Housing API not available
    if not IsHousingAvailable() then
        return {}
    end

    return {
        "PLAYER_ENTERING_WORLD",
        -- Housing-specific events (may need to be updated based on actual API)
        -- "HOUSING_FAVOR_CHANGED",
        -- "HOUSING_LEVEL_CHANGED",
    }
end

-- Build the data text config in the format DataTexts expects
local housingDataText = {
    name = "Housing Progress",
    color = {0.3, 0.8, 1},
    icon = "Interface\\Icons\\INV_Misc_Key_14",
    update = function(frame)
        if not IsHousingAvailable() then
            frame.text:SetText("|cff888888Housing N/A|r")
            return
        end
        local Options = MiniMapRedux.import("Options")
        local data = GetHousingData()
        frame.text:SetText(FormatHousingText(data, Options))
    end,
    tooltip = function()
        local lines = GetHousingTooltip()
        GameTooltip:SetText(lines[1].text)
        for i = 2, #lines do
            local line = lines[i]
            GameTooltip:AddLine(line.text, line.color[1], line.color[2], line.color[3])
        end
    end,
    onClick = function()
        OnHousingClick("LeftButton")
    end
}

-- Register the housing data text - defer until DataTexts is available
local function RegisterDataText()
    local DataTexts = MiniMapRedux and MiniMapRedux.import("DataTexts")
    if DataTexts and DataTexts.RegisterDataText then
        DataTexts:RegisterDataText("housing", housingDataText)
        if MiniMapRedux.export then
            MiniMapRedux.export("Housing", Housing)
        end
    else
        C_Timer.After(0.1, RegisterDataText)
    end
end

RegisterDataText()

return Housing
