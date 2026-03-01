local addonName, _ = ...
local MiniMapRedux = _G.MiniMapRedux

-- Gold Data Text Module
local DataTexts
local function GetDataTexts()
    if not DataTexts and MiniMapRedux and MiniMapRedux.import then
        DataTexts = MiniMapRedux.import("DataTexts")
    end
    return DataTexts
end

-- Saved variables for storing gold data across characters
local GoldTrackerDB

-- Local storage for current session data
local goldData = {
    money = 0,
    warbankGold = 0
}

-- Function to get current character identifier
local function GetCharacterKey()
    local name = UnitName("player")
    local realm = GetRealmName()
    return name .. "-" .. realm
end

-- Function to save current character's gold data
local function SaveCharacterGold()
    -- Ensure we have access to the saved variables
    if not GoldTrackerDB then
        GoldTrackerDB = _G.MiniMapRedux_GoldTrackerDB
    end
    
    if not GoldTrackerDB then return end
    
    local characterKey = GetCharacterKey()
    local currentTime = time()
    
    GoldTrackerDB.characters[characterKey] = {
        name = UnitName("player"),
        realm = GetRealmName(),
        class = select(2, UnitClass("player")),
        level = UnitLevel("player"),
        money = goldData.money,
        lastSeen = currentTime
    }
    
    GoldTrackerDB.lastUpdate = currentTime
end

-- Function to refresh gold data with error handling
local function RefreshGoldData()
    local DataTexts = GetDataTexts()
    if not DataTexts then return end
    
    local success, errorMessage = pcall(function()
        local moneySuccess, money = pcall(GetMoney)
        if moneySuccess and money then
            goldData.money = money
            -- Save character gold data
            SaveCharacterGold()
        else
            goldData.money = 0
        end
        
        -- Get warbound bank gold if available (C_Bank.FetchDepositedMoney introduced in 10.0)
        goldData.warbankGold = 0
        if C_Bank and C_Bank.FetchDepositedMoney then
            local warbankSuccess, warbankMoney = pcall(C_Bank.FetchDepositedMoney, Enum.BankType.Account)
            if warbankSuccess and warbankMoney then
                goldData.warbankGold = warbankMoney
            end
        end
    end)
    
    if not success then
        print("Gold data refresh failed: " .. tostring(errorMessage))
        goldData.money = 0
    end
end

-- Event frame for gold updates
local goldEventFrame = CreateFrame("Frame")
goldEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
goldEventFrame:RegisterEvent("PLAYER_MONEY")
goldEventFrame:RegisterEvent("SEND_MAIL_MONEY_CHANGED")
goldEventFrame:RegisterEvent("TRADE_MONEY_CHANGED")
goldEventFrame:RegisterEvent("BANKFRAME_OPENED") -- Update when bank is opened
goldEventFrame:RegisterEvent("BANKFRAME_CLOSED")
-- Only register ACCOUNT_MONEY in retail (Warbound bank feature)
if C_Bank and C_Bank.HasMaxWithdrawDailyLimit then
    goldEventFrame:RegisterEvent("ACCOUNT_MONEY")
end
goldEventFrame:SetScript("OnEvent", function(self, event, ...)
    -- Initialize saved variables when player enters world
    if event == "PLAYER_ENTERING_WORLD" then
        -- Small delay to ensure saved variables are loaded
        C_Timer.After(2, function()
            -- Ensure we have access to the saved variables
            if not GoldTrackerDB then
                GoldTrackerDB = _G.MiniMapRedux_GoldTrackerDB or {
                    characters = {},
                    lastUpdate = 0
                }
                -- Make sure the global variable is set
                _G.MiniMapRedux_GoldTrackerDB = GoldTrackerDB
            end
            
            -- Small delay to ensure data is ready
            C_Timer.After(1, function()
                RefreshGoldData()
            end)
        end)
    else
        RefreshGoldData()
    end
end)

-- Function to format money amounts
local function FormatMoney(amount)
    if not amount then return "0|cffeda55fc|r" end
    
    local gold = math.floor(amount / 10000)
    local silver = math.floor((amount % 10000) / 100)
    local copper = amount % 100
    
    local moneyString = ""
    if gold > 0 then
        moneyString = moneyString .. string.format("%d|cffffd700g|r ", gold)
    end
    if silver > 0 or gold > 0 then
        moneyString = moneyString .. string.format("%d|cffc7c7cfs|r ", silver)
    end
    moneyString = moneyString .. string.format("%d|cffeda55fc|r", copper)
    
    return moneyString
end

-- Function to calculate total gold across all tracked characters
local function GetTotalTrackedGold()
    -- Ensure we have access to the saved variables
    if not GoldTrackerDB then
        GoldTrackerDB = _G.MiniMapRedux_GoldTrackerDB
    end
    
    if not GoldTrackerDB then return 0 end
    
    local total = 0
    for _, character in pairs(GoldTrackerDB.characters) do
        total = total + (character.money or 0)
    end
    return total
end

-- Function to get other characters (excluding current)
local function GetOtherCharacters()
    -- Ensure we have access to the saved variables
    if not GoldTrackerDB then
        GoldTrackerDB = _G.MiniMapRedux_GoldTrackerDB
    end
    
    if not GoldTrackerDB then return {} end
    
    local currentChar = GetCharacterKey()
    local others = {}
    
    for key, character in pairs(GoldTrackerDB.characters) do
        if key ~= currentChar and character.name and character.money then
            table.insert(others, character)
        end
    end
    
    -- Sort by gold amount (highest first)
    table.sort(others, function(a, b)
        return (a.money or 0) > (b.money or 0)
    end)
    
    return others
end

local goldDataText = {
    name = "Gold",
    color = {1, 0.8, 0.3}, -- Gold color
    icon = "Interface\\Icons\\INV_Misc_Coin_01", -- Gold icon
    update = function(frame)
        local DataTexts = GetDataTexts()
        if not DataTexts then return end
        
        -- Format gold string for current character
        local goldString = FormatMoney(goldData.money)
        frame.text:SetText("Gold: " .. goldString)
        frame.text:SetTextColor(1, 0.8, 0.3) -- Gold color
    end,
    tooltip = function()
        local DataTexts = GetDataTexts()
        if not DataTexts then return end
        
        GameTooltip:SetText("Gold Information")
        
        -- Current character gold
        GameTooltip:AddLine("Current Character: " .. FormatMoney(goldData.money), 1, 1, 1)
        
        -- Warbound bank gold (if accessible)
        if goldData.warbankGold > 0 then
            GameTooltip:AddLine("Warbound Bank: " .. FormatMoney(goldData.warbankGold), 0.9, 0.8, 1)
        end
        
        -- Total tracked gold
        local totalTracked = GetTotalTrackedGold()
        GameTooltip:AddLine("Total Tracked: " .. FormatMoney(totalTracked), 1, 1, 1)
        
        -- Combined total (character + warbound + other chars)
        if goldData.warbankGold > 0 then
            local grandTotal = totalTracked + goldData.warbankGold
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Grand Total: " .. FormatMoney(grandTotal), 1, 0.8, 0.3)
        end
        
        -- Show other tracked characters
        local otherChars = GetOtherCharacters()
        if #otherChars > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Other Characters:", 0.8, 0.8, 0.8)
            
            for _, character in ipairs(otherChars) do
                local charString = character.name .. " - " .. FormatMoney(character.money)
                GameTooltip:AddLine(charString, 0.9, 0.9, 0.9)
            end
        else
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("No other characters tracked yet", 0.7, 0.7, 0.7)
        end
        
        -- Information about tracking
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Note: Gold amounts are tracked automatically", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("when you log into each character.", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Data is stored locally on this machine.", 0.8, 0.8, 0.8)
        
        -- Add some context
        local gold = math.floor(goldData.money / 10000)
        GameTooltip:AddLine(" ")
        if gold > 1000 then
            GameTooltip:AddLine("You're quite wealthy!", 0.3, 1, 0.3)
        elseif gold > 100 then
            GameTooltip:AddLine("You're doing well financially", 1, 1, 0.3)
        else
            GameTooltip:AddLine("Keep grinding for more gold!", 1, 0.8, 0.3)
        end
        
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click to open bags", 0.8, 0.8, 0.8)
    end,
    onClick = function()
        -- Open all bags with error handling
        local success, errorMessage = pcall(OpenAllBags)
        if not success then
            print("Failed to open bags: " .. tostring(errorMessage))
        end
    end
}

-- Register the gold data text - defer until DataTexts is available
local function RegisterDataText()
    local DataTexts = GetDataTexts()
    if DataTexts then
        DataTexts:RegisterDataText("gold", goldDataText)
        -- Export an empty module (registration is enough)
        if MiniMapRedux and MiniMapRedux.export then
            MiniMapRedux.export("GoldDataText", {})
        end
    else
        -- Try again after a short delay
        C_Timer.After(0.1, RegisterDataText)
    end
end

-- Call register function
RegisterDataText()