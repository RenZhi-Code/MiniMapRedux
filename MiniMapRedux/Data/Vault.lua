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
local vaultData = {
    raid = { unlocked = 0, total = 3 },
    mythic = { unlocked = 0, total = 3 },
    pvp = { unlocked = 0, total = 3 },
    totalUnlocked = 0,
    hasRewards = false,
}

local function RefreshVaultData()
    if not C_WeeklyRewards then return end

    local success = pcall(function()
        local activities = C_WeeklyRewards.GetActivities()
        if not activities then return end

        vaultData.raid = { unlocked = 0, total = 3 }
        vaultData.mythic = { unlocked = 0, total = 3 }
        vaultData.pvp = { unlocked = 0, total = 3 }
        vaultData.totalUnlocked = 0

        for _, activity in ipairs(activities) do
            local category
            if activity.type == Enum.WeeklyRewardChestThresholdType.Raid then
                category = vaultData.raid
            elseif activity.type == Enum.WeeklyRewardChestThresholdType.MythicPlus then
                category = vaultData.mythic
            elseif activity.type == Enum.WeeklyRewardChestThresholdType.RankedPvP then
                category = vaultData.pvp
            end

            if category and activity.progress >= activity.threshold then
                category.unlocked = category.unlocked + 1
                vaultData.totalUnlocked = vaultData.totalUnlocked + 1
            end
        end

        vaultData.hasRewards = C_WeeklyRewards.HasAvailableRewards()
    end)

    if not success then
        vaultData.totalUnlocked = 0
        vaultData.hasRewards = false
    end
end

-- Events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("WEEKLY_REWARDS_UPDATE")
eventFrame:SetScript("OnEvent", function()
    RefreshVaultData()
end)

C_Timer.After(3, RefreshVaultData)

local function GetVaultColor()
    if vaultData.hasRewards then return 1, 0.8, 0 end        -- Gold: ready to claim
    if vaultData.totalUnlocked >= 9 then return 0, 1, 0 end  -- Green: all done
    if vaultData.totalUnlocked >= 3 then return 1, 1, 0 end  -- Yellow: some progress
    if vaultData.totalUnlocked > 0 then return 1, 0.5, 0 end -- Orange: started
    return 0.5, 0.5, 0.5                                      -- Gray: nothing
end

local vaultDataText = {
    name = "Great Vault",
    color = {1, 0.8, 0},
    icon = "Interface\\Icons\\Achievement_Dungeon_GloryoftheRaider",
    update = function(frame)
        if not GetDataTexts() then return end
        if not C_WeeklyRewards then
            frame.text:SetText("|cff888888Vault N/A|r")
            return
        end

        local r, g, b = GetVaultColor()
        if vaultData.hasRewards then
            frame.text:SetText("Vault: READY!")
        else
            -- Show per-category breakdown
            frame.text:SetText(string.format("Vault: R%d M%d P%d",
                vaultData.raid.unlocked, vaultData.mythic.unlocked, vaultData.pvp.unlocked))
        end
        frame.text:SetTextColor(r, g, b)
    end,
    tooltip = function()
        if not GetDataTexts() then return end

        GameTooltip:SetText("Great Vault Progress")

        if not C_WeeklyRewards then
            GameTooltip:AddLine("Not available", 0.5, 0.5, 0.5)
            return
        end

        if vaultData.hasRewards then
            GameTooltip:AddLine("Rewards available to claim!", 1, 0.8, 0)
        end

        GameTooltip:AddLine(" ")

        -- Raid
        local raidColor = vaultData.raid.unlocked > 0 and {0.3, 1, 0.3} or {0.5, 0.5, 0.5}
        GameTooltip:AddLine(string.format("Raid: %d/%d", vaultData.raid.unlocked, vaultData.raid.total), raidColor[1], raidColor[2], raidColor[3])

        -- M+
        local mythicColor = vaultData.mythic.unlocked > 0 and {0.3, 1, 0.3} or {0.5, 0.5, 0.5}
        GameTooltip:AddLine(string.format("Mythic+: %d/%d", vaultData.mythic.unlocked, vaultData.mythic.total), mythicColor[1], mythicColor[2], mythicColor[3])

        -- PvP
        local pvpColor = vaultData.pvp.unlocked > 0 and {0.3, 1, 0.3} or {0.5, 0.5, 0.5}
        GameTooltip:AddLine(string.format("PvP: %d/%d", vaultData.pvp.unlocked, vaultData.pvp.total), pvpColor[1], pvpColor[2], pvpColor[3])

        -- Detailed progress
        if C_WeeklyRewards.GetActivities then
            local activities = C_WeeklyRewards.GetActivities()
            if activities then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("Details:", 0.8, 0.8, 0.8)
                for _, activity in ipairs(activities) do
                    local typeName = "Unknown"
                    if activity.type == Enum.WeeklyRewardChestThresholdType.Raid then
                        typeName = "Raid"
                    elseif activity.type == Enum.WeeklyRewardChestThresholdType.MythicPlus then
                        typeName = "M+"
                    elseif activity.type == Enum.WeeklyRewardChestThresholdType.RankedPvP then
                        typeName = "PvP"
                    end
                    local progress = math.min(activity.progress, activity.threshold)
                    local done = activity.progress >= activity.threshold
                    local color = done and {0.3, 1, 0.3} or {1, 1, 1}
                    GameTooltip:AddLine(string.format("  %s: %d/%d%s", typeName, progress, activity.threshold, done and " ✓" or ""), color[1], color[2], color[3])
                end
            end
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click to open Great Vault", 0.8, 0.8, 0.8)
    end,
    onClick = function()
        if WeeklyRewardsFrame and WeeklyRewardsFrame:IsShown() then
            WeeklyRewardsFrame:Hide()
        elseif WeeklyRewards_ShowUI then
            pcall(WeeklyRewards_ShowUI)
        end
    end
}

local function RegisterDataText()
    local DataTexts = GetDataTexts()
    if DataTexts then
        DataTexts:RegisterDataText("vault", vaultDataText)
        if MiniMapRedux and MiniMapRedux.export then
            MiniMapRedux.export("VaultDataText", {})
        end
    else
        C_Timer.After(0.1, RegisterDataText)
    end
end

RegisterDataText()
