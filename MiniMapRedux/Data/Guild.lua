local addonName, _ = ...
local MiniMapRedux = _G.MiniMapRedux

-- Guild Data Text Module
local DataTexts
local function GetDataTexts()
    if not DataTexts and MiniMapRedux and MiniMapRedux.import then
        DataTexts = MiniMapRedux.import("DataTexts")
    end
    return DataTexts
end

-- Local storage for guild data
local guildData = {
    onlineMembers = {},
    onlineCount = 0,
    totalMembers = 0
}

-- Function to refresh guild data
local function RefreshGuildData()
    local DataTexts = GetDataTexts()
    if not DataTexts then return end
    
    -- Wipe existing data
    table.wipe(guildData.onlineMembers)
    guildData.onlineCount = 0
    guildData.totalMembers = 0
    
    -- Check if player is in a guild
    if not IsInGuild() then
        return
    end
    
    -- Request guild roster update
    C_GuildInfo.GuildRoster()
    
    -- Get guild members
    local numMembers = GetNumGuildMembers()
    guildData.totalMembers = numMembers or 0
    
    for i = 1, numMembers do
        local name, rankName, rankIndex, level, classDisplayName, zone, publicNote, officerNote, isOnline, status, class, achievementPoints, achievementRank, isMobile, canSoR, repStanding, guid = GetGuildRosterInfo(i)
        
        if isOnline and name then
            guildData.onlineCount = guildData.onlineCount + 1
            
            -- Create member data table
            local memberData = {
                name = name,
                shortName = strsplit("-", name),
                level = level,
                class = class,
                classDisplayName = classDisplayName,
                zone = zone,
                rank = rankName,
                rankIndex = rankIndex,
                status = status, -- 0=Online, 1=AFK, 2=DND
                isMobile = isMobile,
                guid = guid,
                achievementPoints = achievementPoints,
                publicNote = publicNote,
                officerNote = officerNote,
                canSoR = canSoR,
                repStanding = repStanding
            }
            
            table.insert(guildData.onlineMembers, memberData)
        end
    end
    
    -- Sort guild members
    table.sort(guildData.onlineMembers, function(a, b)
        -- First sort by status (Online > AFK > DND)
        if a.status ~= b.status then
            return a.status < b.status
        end
        
        -- Then sort by rank index (higher rank first)
        if a.rankIndex ~= b.rankIndex then
            return a.rankIndex < b.rankIndex
        end
        
        -- Then sort by level (higher level first)
        if a.level ~= b.level then
            return a.level > b.level
        end
        
        -- Finally sort by name
        return a.shortName < b.shortName
    end)
end

-- Event frame for guild updates
local guildEventFrame = CreateFrame("Frame")
guildEventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
guildEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
guildEventFrame:RegisterEvent("PLAYER_GUILD_UPDATE")
guildEventFrame:SetScript("OnEvent", function(self, event, ...)
    -- Refresh guild data when events occur
    RefreshGuildData()
end)

-- Initialize guild data
RefreshGuildData()

local guildDataText = {
    name = "Guild",
    color = {0.3, 1, 0.3}, -- Green
    icon = "Interface\\Icons\\Achievement_Guild_Perks_LordOfTheHoard", -- Guild icon
    update = function(frame)
        local DataTexts = GetDataTexts()
        if not DataTexts then return end
        
        -- Get guild information
        local guildName, guildRank, guildLevel = GetGuildInfo("player")
        
        if guildName then
            if guildData.onlineCount > 0 and guildData.totalMembers > 0 then
                frame.text:SetText(string.format("Guild: %d/%d", guildData.onlineCount, guildData.totalMembers))
            else
                frame.text:SetText("Guild: " .. guildName)
            end
            
            frame.text:SetTextColor(0.3, 1, 0.3) -- Green
        else
            frame.text:SetText("Guild: None")
            frame.text:SetTextColor(0.7, 0.7, 0.7) -- Gray
        end
    end,
    tooltip = function()
        local DataTexts = GetDataTexts()
        if not DataTexts then return end
        
        GameTooltip:SetText("Guild Information")
        
        local guildName, guildRank, guildLevel = GetGuildInfo("player")
        
        if guildName then
            GameTooltip:AddLine("Guild: " .. guildName, 0.3, 1, 0.3)
            GameTooltip:AddLine("Rank: " .. (guildRank or "Unknown"), 1, 1, 1)
            
            if guildLevel and guildLevel > 0 then
                GameTooltip:AddLine("Level: " .. guildLevel, 1, 1, 1)
            end
            
            if guildData.onlineCount > 0 and guildData.totalMembers > 0 then
                GameTooltip:AddLine(string.format("Members: %d/%d online", guildData.onlineCount, guildData.totalMembers), 1, 1, 1)
            end
            
            -- Show online members with status
            if guildData.onlineCount > 0 then
                GameTooltip:AddLine(" ")
                
                -- Group members by status
                local onlineMembers = {}
                local afkMembers = {}
                local dndMembers = {}
                
                for _, member in ipairs(guildData.onlineMembers) do
                    if member.status == 1 then
                        table.insert(afkMembers, member)
                    elseif member.status == 2 then
                        table.insert(dndMembers, member)
                    else
                        table.insert(onlineMembers, member)
                    end
                end
                
                -- Show online members
                if #onlineMembers > 0 then
                    GameTooltip:AddLine("Online:", 0, 1, 0)
                    for _, member in ipairs(onlineMembers) do
                        local classColor = RAID_CLASS_COLORS[member.class] or {r=1, g=1, b=1}
                        local zoneText = member.zone and (" in " .. member.zone) or ""
                        GameTooltip:AddLine("  " .. member.shortName .. " (Lvl " .. member.level .. ")" .. zoneText, classColor.r, classColor.g, classColor.b)
                    end
                end
                
                -- Show AFK members
                if #afkMembers > 0 then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine("Away:", 1, 1, 0)
                    for _, member in ipairs(afkMembers) do
                        local classColor = RAID_CLASS_COLORS[member.class] or {r=1, g=1, b=1}
                        local zoneText = member.zone and (" in " .. member.zone) or ""
                        GameTooltip:AddLine("  " .. member.shortName .. " (Lvl " .. member.level .. ")" .. zoneText .. " |T" .. FRIENDS_TEXTURE_AFK .. ":0|t", classColor.r, classColor.g, classColor.b)
                    end
                end
                
                -- Show DND members
                if #dndMembers > 0 then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine("Do Not Disturb:", 1, 0.5, 0)
                    for _, member in ipairs(dndMembers) do
                        local classColor = RAID_CLASS_COLORS[member.class] or {r=1, g=1, b=1}
                        local zoneText = member.zone and (" in " .. member.zone) or ""
                        GameTooltip:AddLine("  " .. member.shortName .. " (Lvl " .. member.level .. ")" .. zoneText .. " |T" .. FRIENDS_TEXTURE_DND .. ":0|t", classColor.r, classColor.g, classColor.b)
                    end
                end
            end
            
            -- Add guild motd if available
            local motd = GetGuildRosterMOTD()
            if motd and motd ~= "" then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("MOTD:", 1, 1, 0)
                GameTooltip:AddLine(motd, 0.8, 0.8, 0.8, true)
            end
        else
            GameTooltip:AddLine("Not in a guild", 0.7, 0.7, 0.7)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Click to open guild finder", 0.8, 0.8, 0.8)
        end
        
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click to open guild panel", 0.8, 0.8, 0.8)
    end,
    onClick = function()
        -- Open guild panel with proper error handling
        local success, errorMessage = pcall(function()
            if IsInGuild() then
                -- Player is in a guild, open guild panel
                if GuildFrame and GuildFrame.Show and GuildFrame.Hide then
                    if GuildFrame:IsShown() then
                        GuildFrame:Hide()
                    else
                        GuildFrame:Show()
                    end
                else
                    -- Load the guild UI if not loaded
                    local loadSuccess = false
                    if C_AddOns and C_AddOns.LoadAddOn then
                        loadSuccess = pcall(C_AddOns.LoadAddOn, "Blizzard_GuildUI")
                    elseif _G.LoadAddOn then
                        loadSuccess = pcall(_G.LoadAddOn, "Blizzard_GuildUI")
                    end
                    
                    if loadSuccess and GuildFrame and GuildFrame.Show then
                        GuildFrame:Show()
                    else
                        -- Fallback: try ToggleGuildFrame if available
                        if ToggleGuildFrame and type(ToggleGuildFrame) == "function" then
                            ToggleGuildFrame()
                        else
                            -- Last resort: try using the slash command
                            if _G.ChatFrame_OpenChat then
                                _G.ChatFrame_OpenChat("/g")
                            end
                        end
                    end
                end
            else
                -- Player is not in a guild, open guild finder
                if GuildFinderFrame and GuildFinderFrame.Show and GuildFinderFrame.Hide then
                    if GuildFinderFrame:IsShown() then
                        GuildFinderFrame:Hide()
                    else
                        GuildFinderFrame:Show()
                    end
                else
                    -- Load the guild finder UI if not loaded
                    local loadSuccess = false
                    if C_AddOns and C_AddOns.LoadAddOn then
                        loadSuccess = pcall(C_AddOns.LoadAddOn, "Blizzard_GuildUI") -- Guild finder is part of GuildUI
                    elseif _G.LoadAddOn then
                        loadSuccess = pcall(_G.LoadAddOn, "Blizzard_GuildUI")
                    end
                    
                    if loadSuccess and GuildFinderFrame and GuildFinderFrame.Show then
                        GuildFinderFrame:Show()
                    else
                        -- Fallback: try ToggleGuildFinder if available
                        if ToggleGuildFinder and type(ToggleGuildFinder) == "function" then
                            ToggleGuildFinder()
                        else
                            -- Last resort: try using the slash command
                            if _G.ChatFrame_OpenChat then
                                _G.ChatFrame_OpenChat("/gf")
                            end
                        end
                    end
                end
            end
        end)
        
        if not success then
            print("Failed to toggle guild frame: " .. tostring(errorMessage))
        end
    end
}

-- Register the guild data text - defer until DataTexts is available
local function RegisterDataText()
    local DataTexts = GetDataTexts()
    if DataTexts then
        DataTexts:RegisterDataText("guild", guildDataText)
        -- Export an empty module (registration is enough)
        if MiniMapRedux and MiniMapRedux.export then
            MiniMapRedux.export("GuildDataText", {})
        end
    else
        -- Try again after a short delay
        C_Timer.After(0.1, RegisterDataText)
    end
end

-- Call register function
RegisterDataText()