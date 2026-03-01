local addonName, _ = ...
local MiniMapRedux = _G.MiniMapRedux

-- Currency Data Text Module
local DataTexts
local function GetDataTexts()
    if not DataTexts and MiniMapRedux and MiniMapRedux.import then
        DataTexts = MiniMapRedux.import("DataTexts")
    end
    return DataTexts
end

-- Local storage for currency data
local currencyData = {
    currencies = {}
}

-- Function to refresh currency data with error handling
local function RefreshCurrencyData()
    local DataTexts = GetDataTexts()
    if not DataTexts then return end
    
    local success, errorMessage = pcall(function()
        local currencies = {}
        
        -- Define currencies to track
        local currenciesToShow = {
            {id = 1602, name = "Conquest Points"}, -- Conquest
            {id = 1792, name = "Honor Points"},    -- Honor
            {id = 1191, name = "Valor Points"},    -- Valor
            {id = 1828, name = "Renown"},          -- Renown
            {id = 2029, name = "Dragon Isles Supplies"}, -- Dragon Isles Supplies
        }
        
        for _, currency in ipairs(currenciesToShow) do
            local currencyInfoSuccess, currencyInfo = pcall(C_CurrencyInfo.GetCurrencyInfo, currency.id)
            if currencyInfoSuccess and currencyInfo and currencyInfo.name and currencyInfo.quantity and currencyInfo.discovered then
                table.insert(currencies, {
                    id = currency.id,
                    name = currencyInfo.name,
                    quantity = currencyInfo.quantity,
                    quantityEarnedThisWeek = currencyInfo.quantityEarnedThisWeek or 0,
                    maxWeeklyQuantity = currencyInfo.maxWeeklyQuantity or 0,
                    maxQuantity = currencyInfo.maxQuantity or 0,
                    discovered = currencyInfo.discovered
                })
            end
        end
        
        currencyData.currencies = currencies
    end)
    
    if not success then
        print("Currency data refresh failed: " .. tostring(errorMessage))
        currencyData.currencies = {}
    end
end

-- Event frame for currency updates
local currencyEventFrame = CreateFrame("Frame")
currencyEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
currencyEventFrame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
currencyEventFrame:RegisterEvent("PLAYER_MONEY")
currencyEventFrame:SetScript("OnEvent", function(self, event, ...)
    local DataTexts = GetDataTexts()
    if DataTexts then
        RefreshCurrencyData()
    end
end)

-- Initialize currency data
RefreshCurrencyData()

local currencyDataText = {
    name = "Currency",
    color = {1, 0.8, 0.3}, -- Gold
    icon = "Interface\\Icons\\INV_Misc_Coin_05", -- Currency icon
    update = function(frame)
        local DataTexts = GetDataTexts()
        if not DataTexts then return end
        
        -- Find the most relevant currency to display
        local primaryCurrency = nil
        local priorityOrder = {1602, 1792, 1191, 1828, 2029} -- Conquest, Honor, Valor, Renown, Dragon Isles Supplies
        
        for _, priorityID in ipairs(priorityOrder) do
            for _, currency in ipairs(currencyData.currencies) do
                if currency.id == priorityID and currency.quantity > 0 then
                    primaryCurrency = currency
                    break
                end
            end
            if primaryCurrency then break end
        end
        
        -- If no priority currency found, use the first available
        if not primaryCurrency and #currencyData.currencies > 0 then
            primaryCurrency = currencyData.currencies[1]
        end
        
        if primaryCurrency and primaryCurrency.quantity > 0 then
            -- Format the currency amount
            local formattedAmount = primaryCurrency.quantity
            if primaryCurrency.quantity >= 1000 then
                formattedAmount = string.format("%.1fk", primaryCurrency.quantity / 1000)
            end
            
            frame.text:SetText(string.format("%s: %s", primaryCurrency.name, formattedAmount))
            frame.text:SetTextColor(1, 0.8, 0.3) -- Gold
        else
            frame.text:SetText("Currency: None")
            frame.text:SetTextColor(0.7, 0.7, 0.7) -- Gray
        end
    end,
    tooltip = function()
        local DataTexts = GetDataTexts()
        if not DataTexts then return end
        
        GameTooltip:SetText("Currency Information")
        
        local hasCurrencies = false
        
        for _, currency in ipairs(currencyData.currencies) do
            if currency.name and currency.quantity and currency.discovered then
                hasCurrencies = true
                
                local color = {1, 1, 1} -- Default white
                
                -- Special coloring for specific currencies
                if currency.id == 1602 then -- Conquest
                    color = {1, 0.3, 0.3} -- Red
                elseif currency.id == 1792 then -- Honor
                    color = {0.3, 0.3, 1} -- Blue
                elseif currency.id == 1191 then -- Valor
                    color = {0.8, 0.6, 1} -- Purple
                end
                
                local text = string.format("%s: %d", currency.name, currency.quantity)
                
                -- Add weekly limits if applicable
                if currency.maxWeeklyQuantity and currency.maxWeeklyQuantity > 0 then
                    text = text .. string.format(" (%d/%d weekly)", currency.quantityEarnedThisWeek or 0, currency.maxWeeklyQuantity)
                end
                
                -- Add total cap if applicable
                if currency.maxQuantity and currency.maxQuantity > 0 and currency.maxQuantity < 1000000 then -- Don't show for unlimited currencies
                    text = text .. string.format(" (Max: %d)", currency.maxQuantity)
                end
                
                GameTooltip:AddLine(text, color[1], color[2], color[3])
            end
        end
        
        if not hasCurrencies then
            GameTooltip:AddLine("No tracked currencies", 0.7, 0.7, 0.7)
        end
        
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click to open currency panel", 0.8, 0.8, 0.8)
    end,
    onClick = function()
        -- Toggle currency panel with error handling
        local success, errorMessage = pcall(function()
            -- Try modern ToggleTokenFrame first
            if ToggleTokenFrame then
                ToggleTokenFrame()
            elseif TokenFrame then
                if TokenFrame:IsShown() then
                    TokenFrame:Hide()
                else
                    TokenFrame:Show()
                end
            else
                -- Load the token UI if not loaded
                local loadSuccess = false
                if C_AddOns and C_AddOns.LoadAddOn then
                    loadSuccess = pcall(C_AddOns.LoadAddOn, "Blizzard_TokenUI")
                elseif _G.LoadAddOn then
                    loadSuccess = pcall(_G.LoadAddOn, "Blizzard_TokenUI")
                end
                if loadSuccess then
                    -- Try to show the frame after loading
                    if ToggleTokenFrame then
                        ToggleTokenFrame()
                    elseif TokenFrame then
                        TokenFrame:Show()
                    end
                else
                    -- Last resort: try the slash command
                    if _G.ChatFrame_OpenChat then
                        _G.ChatFrame_OpenChat("/tokens")
                    end
                end
            end
        end)
        
        if not success then
            print("Failed to toggle currency frame: " .. tostring(errorMessage))
        end
    end
}

-- Register the currency data text - defer until DataTexts is available
local function RegisterDataText()
    local DataTexts = GetDataTexts()
    if DataTexts then
        DataTexts:RegisterDataText("currency", currencyDataText)
        -- Export an empty module (registration is enough)
        if MiniMapRedux and MiniMapRedux.export then
            MiniMapRedux.export("CurrencyDataText", {})
        end
    else
        -- Try again after a short delay
        C_Timer.After(0.1, RegisterDataText)
    end
end

-- Call register function
RegisterDataText()
