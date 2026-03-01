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
local tokenData = {
    price = 0,
    lastUpdate = 0,
}

local function FormatGold(copper)
    if not copper or copper == 0 then return "0g" end
    local gold = math.floor(copper / 10000)
    if gold >= 1000 then
        return string.format("%dk|cffffd700g|r", math.floor(gold / 1000))
    end
    return string.format("%d|cffffd700g|r", gold)
end

local function RefreshTokenData()
    if not C_WowTokenPublic then return end

    local success = pcall(function()
        C_WowTokenPublic.UpdateMarketPrice()
        local price = C_WowTokenPublic.GetCurrentMarketPrice()
        if price and price > 0 then
            tokenData.price = price
            tokenData.lastUpdate = GetTime()
        end
    end)
end

-- Events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("TOKEN_MARKET_PRICE_UPDATED")
eventFrame:RegisterEvent("TOKEN_STATUS_CHANGED")
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "TOKEN_MARKET_PRICE_UPDATED" then
        local success = pcall(function()
            local price = C_WowTokenPublic.GetCurrentMarketPrice()
            if price and price > 0 then
                tokenData.price = price
                tokenData.lastUpdate = GetTime()
            end
        end)
    else
        RefreshTokenData()
    end
end)

C_Timer.After(5, RefreshTokenData)
-- Refresh every 5 minutes
C_Timer.NewTicker(300, RefreshTokenData)

local tokenDataText = {
    name = "WoW Token",
    color = {0, 0.8, 1},
    icon = "Interface\\Icons\\WoWToken01",
    update = function(frame)
        if not GetDataTexts() then return end

        if not C_WowTokenPublic then
            frame.text:SetText("|cff888888Token N/A|r")
            return
        end

        if tokenData.price > 0 then
            frame.text:SetText("Token: " .. FormatGold(tokenData.price))
            frame.text:SetTextColor(0, 0.8, 1)
        else
            frame.text:SetText("Token: --")
            frame.text:SetTextColor(0.5, 0.5, 0.5)
        end
    end,
    tooltip = function()
        if not GetDataTexts() then return end

        GameTooltip:SetText("WoW Token")

        if not C_WowTokenPublic then
            GameTooltip:AddLine("Not available", 0.5, 0.5, 0.5)
            return
        end

        if tokenData.price > 0 then
            local gold = math.floor(tokenData.price / 10000)
            local silver = math.floor((tokenData.price % 10000) / 100)
            GameTooltip:AddLine(string.format("Current Price: %d gold %d silver", gold, silver), 1, 0.8, 0.3)

            if tokenData.lastUpdate > 0 then
                local elapsed = GetTime() - tokenData.lastUpdate
                local mins = math.floor(elapsed / 60)
                if mins > 0 then
                    GameTooltip:AddLine(string.format("Updated: %dm ago", mins), 0.6, 0.6, 0.6)
                else
                    GameTooltip:AddLine("Updated: just now", 0.6, 0.6, 0.6)
                end
            end
        else
            GameTooltip:AddLine("Price data unavailable", 0.5, 0.5, 0.5)
            GameTooltip:AddLine("Try again in a moment", 0.6, 0.6, 0.6)
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click to open Shop", 0.8, 0.8, 0.8)
    end,
    onClick = function()
        if StoreFrame_Open then
            pcall(StoreFrame_Open)
        end
    end
}

local function RegisterDataText()
    local DataTexts = GetDataTexts()
    if DataTexts then
        DataTexts:RegisterDataText("wowtoken", tokenDataText)
        if MiniMapRedux and MiniMapRedux.export then
            MiniMapRedux.export("WoWTokenDataText", {})
        end
    else
        C_Timer.After(0.1, RegisterDataText)
    end
end

RegisterDataText()
