local addonName, _ = ...
local MiniMapRedux = _G.MiniMapRedux

local DataTexts
local function GetDataTexts()
    if not DataTexts and MiniMapRedux and MiniMapRedux.import then
        DataTexts = MiniMapRedux.import("DataTexts")
    end
    return DataTexts
end

local BASE_MOVEMENT_SPEED = 7.0

local speedDataText = {
    name = "Speed",
    color = {0.3, 1, 0.8},
    icon = "Interface\\Icons\\Ability_Rogue_Sprint",
    update = function(frame)
        if not GetDataTexts() then return end

        local currentSpeed = GetUnitSpeed("player")
        local speedPercent = (currentSpeed / BASE_MOVEMENT_SPEED) * 100

        if speedPercent > 100 then
            frame.text:SetText(string.format("Speed: %.0f%%", speedPercent))
            frame.text:SetTextColor(0.3, 1, 0.3)
        elseif speedPercent > 0 then
            frame.text:SetText(string.format("Speed: %.0f%%", speedPercent))
            frame.text:SetTextColor(1, 1, 1)
        else
            frame.text:SetText("Speed: Idle")
            frame.text:SetTextColor(0.5, 0.5, 0.5)
        end
    end,
    tooltip = function()
        if not GetDataTexts() then return end

        GameTooltip:SetText("Movement Speed")

        local currentSpeed = GetUnitSpeed("player")
        local speedPercent = (currentSpeed / BASE_MOVEMENT_SPEED) * 100

        GameTooltip:AddLine(string.format("Current: %.1f%%", speedPercent), 1, 1, 1)
        GameTooltip:AddLine(string.format("Raw: %.1f yd/s", currentSpeed), 0.8, 0.8, 0.8)

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Reference Speeds:", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("  Walking: 100%", 0.6, 0.6, 0.6)
        GameTooltip:AddLine("  Ground Mount: 200%", 0.6, 0.6, 0.6)
        GameTooltip:AddLine("  Flying Mount: 310%+", 0.6, 0.6, 0.6)

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click to open character panel", 0.8, 0.8, 0.8)
    end,
    onClick = function()
        pcall(ToggleCharacter, "PaperDollFrame")
    end
}

local function RegisterDataText()
    local DataTexts = GetDataTexts()
    if DataTexts then
        DataTexts:RegisterDataText("speed", speedDataText)
        if MiniMapRedux and MiniMapRedux.export then
            MiniMapRedux.export("SpeedDataText", {})
        end
    else
        C_Timer.After(0.1, RegisterDataText)
    end
end

RegisterDataText()
