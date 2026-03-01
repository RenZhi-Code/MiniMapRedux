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
local repairData = {
    cost = 0,
    canRepair = false,
}

local function FormatGold(copper)
    if not copper or copper == 0 then return "0g" end
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    if gold > 0 then
        return string.format("%d|cffffd700g|r %d|cffc7c7cfs|r", gold, silver)
    elseif silver > 0 then
        return string.format("%d|cffc7c7cfs|r", silver)
    end
    return string.format("%d|cffeda55fc|r", copper % 100)
end

local function RefreshRepairData()
    local success = pcall(function()
        local cost, canRepair = GetRepairAllCost()
        repairData.cost = cost or 0
        repairData.canRepair = canRepair or false
    end)

    if not success then
        repairData.cost = 0
        repairData.canRepair = false
    end
end

-- Events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
eventFrame:RegisterEvent("MERCHANT_SHOW")
eventFrame:RegisterEvent("MERCHANT_CLOSED")
eventFrame:SetScript("OnEvent", function()
    RefreshRepairData()
end)

RefreshRepairData()

local repairDataText = {
    name = "Repair Cost",
    color = {1, 0.5, 0.3},
    icon = "Interface\\Icons\\Trade_BlackSmithing",
    update = function(frame)
        if not GetDataTexts() then return end

        if repairData.cost > 0 then
            local gold = math.floor(repairData.cost / 10000)
            local currentGold = math.floor(GetMoney() / 10000)

            frame.text:SetText("Repair: " .. FormatGold(repairData.cost))
            -- Color based on affordability
            if gold > currentGold then
                frame.text:SetTextColor(1, 0.2, 0.2) -- Red: can't afford
            elseif gold > currentGold * 0.1 then
                frame.text:SetTextColor(1, 0.8, 0.3) -- Yellow: notable cost
            else
                frame.text:SetTextColor(0.3, 1, 0.3) -- Green: affordable
            end
        else
            frame.text:SetText("Repair: 0g")
            frame.text:SetTextColor(0.3, 1, 0.3)
        end
    end,
    tooltip = function()
        if not GetDataTexts() then return end

        GameTooltip:SetText("Repair Cost")

        if repairData.cost > 0 then
            GameTooltip:AddLine("Total Cost: " .. FormatGold(repairData.cost), 1, 0.8, 0.3)

            local currentMoney = GetMoney()
            local affordable = currentMoney >= repairData.cost
            if affordable then
                GameTooltip:AddLine("You can afford this repair", 0.3, 1, 0.3)
                local remaining = currentMoney - repairData.cost
                GameTooltip:AddLine("After repair: " .. FormatGold(remaining), 0.6, 0.6, 0.6)
            else
                GameTooltip:AddLine("Not enough gold!", 1, 0.2, 0.2)
                local shortfall = repairData.cost - currentMoney
                GameTooltip:AddLine("Need: " .. FormatGold(shortfall) .. " more", 1, 0.5, 0.5)
            end
        else
            GameTooltip:AddLine("No repairs needed", 0.3, 1, 0.3)
        end

        -- Per-slot breakdown
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Equipment Durability:", 0.8, 0.8, 0.8)
        for slot = 1, 18 do
            local current, maximum = GetInventoryItemDurability(slot)
            if current and maximum and maximum > 0 then
                local pct = (current / maximum) * 100
                local link = GetInventoryItemLink("player", slot)
                local name = link and link:match("%[(.-)%]") or "Slot " .. slot
                local color
                if pct > 50 then color = {0.3, 1, 0.3}
                elseif pct > 25 then color = {1, 1, 0.3}
                else color = {1, 0.3, 0.3} end
                GameTooltip:AddLine(string.format("  %s: %.0f%%", name, pct), color[1], color[2], color[3])
            end
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Visit a repair vendor to repair", 0.8, 0.8, 0.8)
    end,
    onClick = function()
        ToggleCharacter("PaperDollFrame")
    end
}

local function RegisterDataText()
    local DataTexts = GetDataTexts()
    if DataTexts then
        DataTexts:RegisterDataText("repair", repairDataText)
        if MiniMapRedux and MiniMapRedux.export then
            MiniMapRedux.export("RepairDataText", {})
        end
    else
        C_Timer.After(0.1, RegisterDataText)
    end
end

RegisterDataText()
