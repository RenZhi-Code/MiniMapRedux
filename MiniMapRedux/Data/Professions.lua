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
local profData = {
    professions = {},
}

local function RefreshProfData()
    profData.professions = {}

    local success = pcall(function()
        local prof1, prof2, archaeology, fishing, cooking = GetProfessions()
        local profIDs = { prof1, prof2, archaeology, fishing, cooking }

        for _, index in ipairs(profIDs) do
            if index then
                local name, icon, skillLevel, maxSkillLevel, _, _, skillLine = GetProfessionInfo(index)
                if name then
                    table.insert(profData.professions, {
                        name = name,
                        icon = icon,
                        skill = skillLevel or 0,
                        max = maxSkillLevel or 0,
                        skillLine = skillLine,
                        isPrimary = (index == prof1 or index == prof2),
                    })
                end
            end
        end
    end)
end

-- Events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("SKILL_LINES_CHANGED")
eventFrame:RegisterEvent("TRADE_SKILL_UPDATE")
eventFrame:SetScript("OnEvent", function()
    RefreshProfData()
end)

RefreshProfData()

local profDataText = {
    name = "Professions",
    color = {1, 0.6, 0},
    icon = "Interface\\Icons\\Trade_Engineering",
    update = function(frame)
        if not GetDataTexts() then return end

        if #profData.professions == 0 then
            frame.text:SetText("No Professions")
            frame.text:SetTextColor(0.5, 0.5, 0.5)
            return
        end

        -- Show primary professions
        local parts = {}
        for _, prof in ipairs(profData.professions) do
            if prof.isPrimary then
                table.insert(parts, string.format("%s %d/%d", prof.name, prof.skill, prof.max))
            end
        end

        if #parts > 0 then
            frame.text:SetText(table.concat(parts, " | "))
            frame.text:SetTextColor(1, 0.6, 0)
        else
            -- Show secondary if no primary
            local prof = profData.professions[1]
            frame.text:SetText(string.format("%s %d/%d", prof.name, prof.skill, prof.max))
            frame.text:SetTextColor(0.8, 0.8, 0.8)
        end
    end,
    tooltip = function()
        if not GetDataTexts() then return end

        GameTooltip:SetText("Professions")

        if #profData.professions == 0 then
            GameTooltip:AddLine("No professions learned", 0.5, 0.5, 0.5)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Visit a profession trainer to learn one", 0.8, 0.8, 0.8)
        else
            -- Primary professions
            local hasPrimary = false
            for _, prof in ipairs(profData.professions) do
                if prof.isPrimary then
                    if not hasPrimary then
                        GameTooltip:AddLine(" ")
                        GameTooltip:AddLine("Primary:", 0.8, 0.8, 0.8)
                        hasPrimary = true
                    end
                    local pct = prof.max > 0 and (prof.skill / prof.max) * 100 or 0
                    local color = pct >= 100 and {0.3, 1, 0.3} or {1, 1, 1}
                    GameTooltip:AddLine(string.format("  %s: %d / %d (%.0f%%)", prof.name, prof.skill, prof.max, pct), color[1], color[2], color[3])
                end
            end

            -- Secondary professions
            local hasSecondary = false
            for _, prof in ipairs(profData.professions) do
                if not prof.isPrimary then
                    if not hasSecondary then
                        GameTooltip:AddLine(" ")
                        GameTooltip:AddLine("Secondary:", 0.8, 0.8, 0.8)
                        hasSecondary = true
                    end
                    local pct = prof.max > 0 and (prof.skill / prof.max) * 100 or 0
                    local color = pct >= 100 and {0.3, 1, 0.3} or {1, 1, 1}
                    GameTooltip:AddLine(string.format("  %s: %d / %d (%.0f%%)", prof.name, prof.skill, prof.max, pct), color[1], color[2], color[3])
                end
            end
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click to open Professions", 0.8, 0.8, 0.8)
    end,
    onClick = function()
        if ProfessionsFrame and ProfessionsFrame:IsShown() then
            pcall(HideUIPanel, ProfessionsFrame)
        elseif ToggleProfessionsBook then
            pcall(ToggleProfessionsBook)
        elseif C_TradeSkillUI and C_TradeSkillUI.OpenTradeSkill then
            local ok, prof1 = pcall(GetProfessions)
            if ok and prof1 then
                local ok2, _, _, _, _, _, _, skillLine = pcall(GetProfessionInfo, prof1)
                if ok2 and skillLine then
                    pcall(C_TradeSkillUI.OpenTradeSkill, skillLine)
                end
            end
        end
    end
}

local function RegisterDataText()
    local DataTexts = GetDataTexts()
    if DataTexts then
        DataTexts:RegisterDataText("professions", profDataText)
        if MiniMapRedux and MiniMapRedux.export then
            MiniMapRedux.export("ProfessionsDataText", {})
        end
    else
        C_Timer.After(0.1, RegisterDataText)
    end
end

RegisterDataText()
