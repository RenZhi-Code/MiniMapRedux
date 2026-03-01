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
local lockoutData = {
    raids = {},
    dungeons = {},
    totalLockouts = 0,
}

local function RefreshLockoutData()
    lockoutData.raids = {}
    lockoutData.dungeons = {}
    lockoutData.totalLockouts = 0

    local success = pcall(function()
        RequestRaidInfo()
        local numSaved = GetNumSavedInstances() or 0

        for i = 1, numSaved do
            local name, _, reset, difficulty, locked, extended, _, isRaid, maxPlayers, diffName, numBosses, numDefeated = GetSavedInstanceInfo(i)
            if locked or extended then
                local entry = {
                    name = name or "Unknown",
                    reset = reset or 0,
                    difficulty = diffName or difficulty or "",
                    maxPlayers = maxPlayers or 0,
                    numBosses = numBosses or 0,
                    numDefeated = numDefeated or 0,
                    isExtended = extended,
                }

                if isRaid then
                    table.insert(lockoutData.raids, entry)
                else
                    table.insert(lockoutData.dungeons, entry)
                end

                lockoutData.totalLockouts = lockoutData.totalLockouts + 1
            end
        end
    end)
end

local function FormatResetTime(seconds)
    if not seconds or seconds <= 0 then return "Expired" end
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    if days > 0 then
        return string.format("%dd %dh", days, hours)
    else
        local mins = math.floor((seconds % 3600) / 60)
        return string.format("%dh %dm", hours, mins)
    end
end

-- Events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("UPDATE_INSTANCE_INFO")
eventFrame:RegisterEvent("INSTANCE_LOCK_START")
eventFrame:RegisterEvent("INSTANCE_LOCK_STOP")
eventFrame:RegisterEvent("INSTANCE_LOCK_WARNING")
eventFrame:SetScript("OnEvent", function()
    RefreshLockoutData()
end)

C_Timer.After(3, function()
    RequestRaidInfo()
    RefreshLockoutData()
end)

local lockoutDataText = {
    name = "Lockouts",
    color = {1, 0.5, 0},
    icon = "Interface\\Icons\\INV_Misc_Key_10",
    update = function(frame)
        if not GetDataTexts() then return end

        if lockoutData.totalLockouts > 0 then
            local raidCount = #lockoutData.raids
            local dungeonCount = #lockoutData.dungeons
            if raidCount > 0 and dungeonCount > 0 then
                frame.text:SetText(string.format("Lockouts: %dR %dD", raidCount, dungeonCount))
            elseif raidCount > 0 then
                frame.text:SetText(string.format("Lockouts: %d Raid", raidCount))
            else
                frame.text:SetText(string.format("Lockouts: %d Dng", dungeonCount))
            end
            frame.text:SetTextColor(1, 0.5, 0)
        else
            frame.text:SetText("Lockouts: 0")
            frame.text:SetTextColor(0.5, 0.5, 0.5)
        end
    end,
    tooltip = function()
        if not GetDataTexts() then return end

        GameTooltip:SetText("Instance Lockouts")

        if lockoutData.totalLockouts == 0 then
            GameTooltip:AddLine("No active lockouts", 0.5, 0.5, 0.5)
        end

        -- Raids
        if #lockoutData.raids > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Raids:", 0.8, 0.8, 0.8)
            for _, raid in ipairs(lockoutData.raids) do
                local progress = string.format("%d/%d", raid.numDefeated, raid.numBosses)
                local color = raid.numDefeated >= raid.numBosses and {0.3, 1, 0.3} or {1, 1, 1}
                GameTooltip:AddLine(string.format("  %s (%s)", raid.name, raid.difficulty), color[1], color[2], color[3])
                GameTooltip:AddLine(string.format("    Progress: %s | Reset: %s", progress, FormatResetTime(raid.reset)), 0.6, 0.6, 0.6)
            end
        end

        -- Dungeons
        if #lockoutData.dungeons > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Dungeons:", 0.8, 0.8, 0.8)
            for _, dungeon in ipairs(lockoutData.dungeons) do
                local progress = string.format("%d/%d", dungeon.numDefeated, dungeon.numBosses)
                GameTooltip:AddLine(string.format("  %s (%s)", dungeon.name, dungeon.difficulty), 1, 1, 1)
                GameTooltip:AddLine(string.format("    Progress: %s | Reset: %s", progress, FormatResetTime(dungeon.reset)), 0.6, 0.6, 0.6)
            end
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click to open social panel", 0.8, 0.8, 0.8)
    end,
    onClick = function()
        -- Open the social panel's raid tab to view lockouts
        pcall(ToggleFriendsFrame, 4)
    end
}

local function RegisterDataText()
    local DataTexts = GetDataTexts()
    if DataTexts then
        DataTexts:RegisterDataText("lockouts", lockoutDataText)
        if MiniMapRedux and MiniMapRedux.export then
            MiniMapRedux.export("LockoutsDataText", {})
        end
    else
        C_Timer.After(0.1, RegisterDataText)
    end
end

RegisterDataText()
