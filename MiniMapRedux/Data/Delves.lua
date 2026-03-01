local addonName, _ = ...
local MiniMapRedux = _G.MiniMapRedux

local DataTexts
local function GetDataTexts()
    if not DataTexts and MiniMapRedux and MiniMapRedux.import then
        DataTexts = MiniMapRedux.import("DataTexts")
    end
    return DataTexts
end

-- Local storage
local delveData = {
    companionLevel = 0,
    companionXP = 0,
    companionMaxXP = 0,
    companionName = "",
    hasCompanion = false,
}

-- Known currency IDs for Delve-related currencies
local DELVE_CURRENCIES = {
    -- These IDs may need updating as Blizzard changes them
    { id = 3028, name = "Restored Coffer Key" },     -- Delve keys
    { id = 2815, name = "Resonance Crystals" },       -- Companion upgrade
}

local function RefreshDelveData()
    delveData.hasCompanion = false

    local success = pcall(function()
        -- Try to get companion info via C_DelvesUI if available
        if C_DelvesUI then
            if C_DelvesUI.GetCompanionInfo then
                local info = C_DelvesUI.GetCompanionInfo()
                if info then
                    delveData.companionName = info.name or "Brann"
                    delveData.companionLevel = info.level or 0
                    delveData.companionXP = info.currentXP or 0
                    delveData.companionMaxXP = info.maxXP or 1
                    delveData.hasCompanion = true
                end
            end

            -- Fallback: try level getter
            if not delveData.hasCompanion and C_DelvesUI.GetCompanionLevel then
                local level = C_DelvesUI.GetCompanionLevel()
                if level and level > 0 then
                    delveData.companionLevel = level
                    delveData.companionName = "Brann"
                    delveData.hasCompanion = true
                end
            end
        end
    end)
end

-- Events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function()
    C_Timer.After(2, RefreshDelveData)
end)

RefreshDelveData()

local delveDataText = {
    name = "Delves",
    color = {0.4, 0.8, 1},
    icon = "Interface\\Icons\\INV_Misc_Lantern_01",
    update = function(frame)
        if not GetDataTexts() then return end

        if not C_DelvesUI then
            frame.text:SetText("|cff888888Delves N/A|r")
            return
        end

        if delveData.hasCompanion then
            frame.text:SetText(string.format("%s Lv%d", delveData.companionName, delveData.companionLevel))
            frame.text:SetTextColor(0.4, 0.8, 1)
        else
            -- Show key currency count if available
            local keyCount = 0
            for _, currency in ipairs(DELVE_CURRENCIES) do
                local info = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo(currency.id)
                if info and info.quantity then
                    keyCount = info.quantity
                    break
                end
            end

            if keyCount > 0 then
                frame.text:SetText(string.format("Keys: %d", keyCount))
                frame.text:SetTextColor(0.4, 0.8, 1)
            else
                frame.text:SetText("Delves")
                frame.text:SetTextColor(0.5, 0.5, 0.5)
            end
        end
    end,
    tooltip = function()
        if not GetDataTexts() then return end

        GameTooltip:SetText("Delves")

        if not C_DelvesUI then
            GameTooltip:AddLine("Delves system not available", 0.5, 0.5, 0.5)
            return
        end

        if delveData.hasCompanion then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Companion:", 0.8, 0.8, 0.8)
            GameTooltip:AddLine(string.format("  %s - Level %d", delveData.companionName, delveData.companionLevel), 0.4, 0.8, 1)

            if delveData.companionMaxXP > 0 then
                local pct = (delveData.companionXP / delveData.companionMaxXP) * 100
                GameTooltip:AddLine(string.format("  XP: %d / %d (%.0f%%)", delveData.companionXP, delveData.companionMaxXP, pct), 0.6, 0.6, 0.6)
            end
        end

        -- Show delve currencies
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Currencies:", 0.8, 0.8, 0.8)
        local hasCurrency = false
        for _, currency in ipairs(DELVE_CURRENCIES) do
            if C_CurrencyInfo then
                local info = C_CurrencyInfo.GetCurrencyInfo(currency.id)
                if info and info.name and info.name ~= "" then
                    GameTooltip:AddLine(string.format("  %s: %d", info.name, info.quantity or 0), 1, 1, 1)
                    hasCurrency = true
                end
            end
        end
        if not hasCurrency then
            GameTooltip:AddLine("  No delve currencies found", 0.5, 0.5, 0.5)
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click to open Group Finder", 0.8, 0.8, 0.8)
    end,
    onClick = function()
        PVEFrame_ToggleFrame("GroupFinderFrame", LFDParentFrame)
    end
}

local function RegisterDataText()
    local DataTexts = GetDataTexts()
    if DataTexts then
        DataTexts:RegisterDataText("delves", delveDataText)
        if MiniMapRedux and MiniMapRedux.export then
            MiniMapRedux.export("DelvesDataText", {})
        end
    else
        C_Timer.After(0.1, RegisterDataText)
    end
end

RegisterDataText()
