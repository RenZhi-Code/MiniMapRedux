local addonName, _ = ...
local MiniMapRedux = _G.MiniMapRedux

-- Friends Data Text Module
local DataTexts
local function GetDataTexts()
    if not DataTexts and MiniMapRedux and MiniMapRedux.import then
        DataTexts = MiniMapRedux.import("DataTexts")
    end
    return DataTexts
end

local friendsDataText = {
    name = "Friends",
    color = {0.5, 0.5, 1}, -- Light blue
    icon = "Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon", -- Friends icon
    update = function(frame)
        local DataTexts = GetDataTexts()
        if not DataTexts then return end
        
        -- Initialize counters
        local regularWoWOnline = 0
        local bnetWoWOnline = 0
        local bnetTotalOnline = 0
        
        -- Count regular WoW friends
        local numWoWFriends = C_FriendList.GetNumFriends() or 0
        
        for i = 1, numWoWFriends do
            local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
            if friendInfo and friendInfo.connected then
                regularWoWOnline = regularWoWOnline + 1
            end
        end
        
        -- Count Battle.net friends with enhanced detection
        local bnetConnected = BNConnected and BNConnected() or false

        if bnetConnected and C_BattleNet and C_BattleNet.GetFriendAccountInfo then
            local numBNetFriends = BNGetNumFriends() or 0

            for i = 1, numBNetFriends do
                local accountInfo = C_BattleNet.GetFriendAccountInfo(i)

                if accountInfo then
                    -- Check each game account for this friend
                    local numGameAccounts = C_BattleNet.GetFriendNumGameAccounts(i) or 0

                    for j = 1, numGameAccounts do
                        local gameAccountInfo = C_BattleNet.GetFriendGameAccountInfo(i, j)

                        if gameAccountInfo and gameAccountInfo.isOnline then
                            -- Only count each friend once for total online
                            if j == 1 then
                                bnetTotalOnline = bnetTotalOnline + 1
                            end

                            -- Check if they're playing WoW
                            local isWoW = gameAccountInfo.clientProgram == BNET_CLIENT_WOW

                            if isWoW then
                                bnetWoWOnline = bnetWoWOnline + 1
                                break -- Only count once per friend
                            end
                        end
                    end
                end
            end
        end
        
        -- Total WoW players = Regular WoW friends + Battle.net friends playing WoW
        local totalWoWPlayers = regularWoWOnline + bnetWoWOnline
        local totalOnlineFriends = bnetTotalOnline + regularWoWOnline

        -- Show WoW players and BNet online if different
        if totalOnlineFriends > totalWoWPlayers and totalWoWPlayers > 0 then
            frame.text:SetText(string.format("Friends: %d WoW | %d BNet", totalWoWPlayers, totalOnlineFriends))
        elseif totalOnlineFriends > 0 and totalWoWPlayers == 0 then
            frame.text:SetText(string.format("Friends: %d BNet", totalOnlineFriends))
        else
            frame.text:SetText(string.format("Friends: %d", totalWoWPlayers))
        end

        if totalOnlineFriends > 0 then
            frame.text:SetTextColor(0, 1, 1) -- Cyan
        else
            frame.text:SetTextColor(0.7, 0.7, 0.7) -- Gray
        end
    end,
    tooltip = function(frame)
        local DataTexts = GetDataTexts()
        if not DataTexts then return end
        
        GameTooltip:SetText("Friends List")
        -- Make tooltip wider for better readability
        GameTooltip:SetMinimumWidth(350)
        
        -- Count friends using the same logic as update function
        local regularWoWOnline = 0
        local bnetWoWOnline = 0
        local bnetTotalOnline = 0
        local regularFriendsList = {}
        local bnetFriendsList = {}
        local numBNetFriends = 0 -- Move this to higher scope for debug info
        
        -- Count regular WoW friends
        local numWoWFriends = C_FriendList.GetNumFriends() or 0
        for i = 1, numWoWFriends do
            local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
            if friendInfo and friendInfo.connected then
                regularWoWOnline = regularWoWOnline + 1
                table.insert(regularFriendsList, {
                    name = friendInfo.name,
                    level = friendInfo.level,
                    class = friendInfo.className,
                    area = friendInfo.area,
                    isWow = true
                })
            end
        end
        
        -- Count Battle.net friends
        local bnetConnected = BNConnected and BNConnected() or false

        if bnetConnected and C_BattleNet and C_BattleNet.GetFriendAccountInfo then
            numBNetFriends = BNGetNumFriends() or 0

            for i = 1, numBNetFriends do
                local accountInfo = C_BattleNet.GetFriendAccountInfo(i)

                if accountInfo then
                    local friendName = accountInfo.accountName or accountInfo.battleTag or "Unknown"
                    local numGameAccounts = C_BattleNet.GetFriendNumGameAccounts(i) or 0
                    local friendOnline = false
                    local friendIsWoW = false

                    for j = 1, numGameAccounts do
                        local gameAccountInfo = C_BattleNet.GetFriendGameAccountInfo(i, j)

                        if gameAccountInfo and gameAccountInfo.isOnline then
                            -- Mark friend as online (count once)
                            if not friendOnline then
                                friendOnline = true
                                bnetTotalOnline = bnetTotalOnline + 1
                            end

                            -- Check if they're playing WoW
                            local isWoW = gameAccountInfo.clientProgram == BNET_CLIENT_WOW

                            if isWoW and not friendIsWoW then
                                friendIsWoW = true
                                bnetWoWOnline = bnetWoWOnline + 1
                            end

                            -- Add to friends list with detailed info (for first online game account)
                            if j == 1 or isWoW then
                                table.insert(bnetFriendsList, {
                                    name = friendName,
                                    character = gameAccountInfo.characterName,
                                    client = gameAccountInfo.clientProgram or "Unknown",
                                    realm = gameAccountInfo.realmName,
                                    zone = gameAccountInfo.areaName,
                                    isWow = isWoW
                                })

                                if isWoW then
                                    break -- Prefer WoW info, stop looking
                                end
                            end
                        end
                    end
                end
            end
        end
        
        -- Total WoW players = Regular WoW friends + Battle.net friends playing WoW
        local totalWoWOnline = regularWoWOnline + bnetWoWOnline
        local totalOnlineFriends = bnetTotalOnline + regularWoWOnline
        
        GameTooltip:AddLine(string.format("Battle.net: %d online", bnetTotalOnline), 0.5, 0.8, 1)
        GameTooltip:AddLine(string.format("WoW Players: %d online", totalWoWOnline), 0.5, 0.8, 1)
        GameTooltip:AddLine(string.format("Total Online: %d", totalOnlineFriends), 1, 1, 1)
        
        -- Show detailed list of all online friends
        if totalOnlineFriends > 0 then
            GameTooltip:AddLine(" ")
            
            -- Show regular WoW friends first
            if #regularFriendsList > 0 then
                GameTooltip:AddLine("WoW Friends:", 0.3, 1, 0.3)
                for _, friend in ipairs(regularFriendsList) do
                    local displayText = friend.name
                    if friend.level and friend.class then
                        displayText = string.format("%s (Lvl %d %s)", friend.name, friend.level, friend.class)
                    end
                    if friend.area then
                        displayText = displayText .. string.format(" in %s", friend.area)
                    end
                    GameTooltip:AddLine("  " .. displayText, 0.8, 0.8, 0.8)
                end
            end
            
            -- Show Battle.net friends
            if #bnetFriendsList > 0 then
                if #regularFriendsList > 0 then
                    GameTooltip:AddLine(" ")
                end
                GameTooltip:AddLine("Battle.net Friends:", 1, 1, 0)
                
                for _, friend in ipairs(bnetFriendsList) do
                    local displayText = friend.name
                    
                    -- Add character info if available
                    if friend.character and friend.character ~= "" then
                        displayText = displayText .. " (" .. friend.character
                        if friend.realm and friend.realm ~= "" then
                            displayText = displayText .. "-" .. friend.realm
                        end
                        displayText = displayText .. ")"
                    end
                    
                    -- Add game info
                    if friend.client and friend.client ~= "Unknown" and friend.client ~= "" then
                        displayText = displayText .. " [" .. friend.client .. "]"
                    end
                    
                    -- Add location info
                    if friend.zone and friend.zone ~= "" then
                        displayText = displayText .. " in " .. friend.zone
                    end
                    
                    -- Color based on game
                    local color = {0.8, 0.8, 0.8} -- Default gray
                    if friend.isWow then
                        color = {0.3, 1, 0.3} -- Green for WoW
                    elseif friend.client and string.find((friend.client or ""):lower(), "diablo") then
                        color = {1, 0.5, 0.5} -- Red for Diablo
                    elseif friend.client and string.find((friend.client or ""):lower(), "hearthstone") then
                        color = {0.5, 0.5, 1} -- Blue for Hearthstone
                    elseif friend.client and string.find((friend.client or ""):lower(), "starcraft") then
                        color = {1, 1, 0.5} -- Yellow for StarCraft
                    end
                    
                    GameTooltip:AddLine("  " .. displayText, color[1], color[2], color[3])
                end
            end
        end
        
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click to open friends panel", 0.8, 0.8, 0.8)
    end,
    onClick = function()
        -- Open friends panel
        if ToggleFriendsFrame then
            ToggleFriendsFrame()
        elseif FriendsFrame then
            if FriendsFrame:IsShown() then
                FriendsFrame:Hide()
            else
                FriendsFrame:Show()
            end
        end
    end
}

-- Register the friends data text - defer until DataTexts is available
local function RegisterDataText()
    local DataTexts = GetDataTexts()
    if DataTexts then
        DataTexts:RegisterDataText("friends", friendsDataText)
        -- Export an empty module (registration is enough)
        if MiniMapRedux and MiniMapRedux.export then
            MiniMapRedux.export("FriendsDataText", {})
        end
    else
        -- Try again after a short delay
        C_Timer.After(0.1, RegisterDataText)
    end
end

-- Call register function
RegisterDataText()