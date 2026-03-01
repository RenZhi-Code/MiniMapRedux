local addonName, _ = ...
local MiniMapRedux = _G.MiniMapRedux

-- Mail Data Text Module
local DataTexts
local function GetDataTexts()
    if not DataTexts and MiniMapRedux and MiniMapRedux.import then
        DataTexts = MiniMapRedux.import("DataTexts")
    end
    return DataTexts
end

-- Local storage for mail data
local mailData = {
    hasNewMail = false,
    senders = {}
}

-- Function to refresh mail data with error handling
local function RefreshMailData()
    local DataTexts = GetDataTexts()
    if not DataTexts then return end
    
    local success, errorMessage = pcall(function()
        local hasMailSuccess, hasNewMail = pcall(HasNewMail)
        if hasMailSuccess and hasNewMail then
            mailData.hasNewMail = hasNewMail
        else
            mailData.hasNewMail = false
        end
        
        -- Get senders information
        local sender1, sender2, sender3 = nil, nil, nil
        local senderSuccess, s1, s2, s3 = pcall(GetLatestThreeSenders)
        if senderSuccess then
            sender1, sender2, sender3 = s1, s2, s3
        end
        
        mailData.senders = {sender1, sender2, sender3}
    end)
    
    if not success then
        print("Mail data refresh failed: " .. tostring(errorMessage))
        mailData.hasNewMail = false
        mailData.senders = {}
    end
end

-- Event frame for mail updates
local mailEventFrame = CreateFrame("Frame")
mailEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
mailEventFrame:RegisterEvent("UPDATE_PENDING_MAIL")
mailEventFrame:RegisterEvent("MAIL_INBOX_UPDATE")
mailEventFrame:RegisterEvent("MAIL_SHOW")
mailEventFrame:RegisterEvent("MAIL_CLOSED")
mailEventFrame:SetScript("OnEvent", function(self, event, ...)
    RefreshMailData()
end)

-- Initialize mail data
RefreshMailData()

local mailDataText = {
    name = "Mail",
    color = {1, 1, 0.3}, -- Yellow
    icon = "Interface\\Icons\\INV_Letter_15", -- Mail icon
    update = function(frame)
        local DataTexts = GetDataTexts()
        if not DataTexts then return end
        
        if mailData.hasNewMail then
            -- Show first sender name on bar if available
            local firstSender = nil
            local senderCount = 0
            for _, sender in ipairs(mailData.senders) do
                if sender then
                    senderCount = senderCount + 1
                    if not firstSender then firstSender = sender end
                end
            end

            if firstSender then
                if senderCount > 1 then
                    frame.text:SetText(string.format("Mail: %s +%d", firstSender, senderCount - 1))
                else
                    frame.text:SetText("Mail: " .. firstSender)
                end
            else
                frame.text:SetText("Mail: New!")
            end
            frame.text:SetTextColor(1, 1, 0.3) -- Yellow
        else
            frame.text:SetText("Mail: None")
            frame.text:SetTextColor(0.7, 0.7, 0.7) -- Gray
        end
    end,
    tooltip = function()
        local DataTexts = GetDataTexts()
        if not DataTexts then return end
        
        GameTooltip:SetText("Mail Status")
        
        if mailData.hasNewMail then
            GameTooltip:AddLine("You have new mail!", 1, 1, 0.3)
            
            local hasSenders = false
            for _, sender in ipairs(mailData.senders) do
                if sender then
                    hasSenders = true
                end
            end
            
            if hasSenders then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("From:", 0.8, 0.8, 0.8)
                for _, sender in ipairs(mailData.senders) do
                    if sender then
                        GameTooltip:AddLine("- " .. sender, 1, 1, 1)
                    end
                end
            end
            
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Return mail expires in:", 0.8, 0.8, 0.8)
            -- Note: Exact expiration time isn't available through API
            GameTooltip:AddLine("30 days after receipt", 1, 1, 1)
        else
            GameTooltip:AddLine("No new mail", 0.7, 0.7, 0.7)
        end
        
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click to open social panel", 0.8, 0.8, 0.8)
    end,
    onClick = function()
        -- Open the social/friends panel - mailbox requires being at a mailbox NPC
        pcall(ToggleFriendsFrame)
    end
}

-- Register the mail data text - defer until DataTexts is available
local function RegisterDataText()
    local DataTexts = GetDataTexts()
    if DataTexts then
        DataTexts:RegisterDataText("mail", mailDataText)
        -- Export an empty module (registration is enough)
        if MiniMapRedux and MiniMapRedux.export then
            MiniMapRedux.export("MailDataText", {})
        end
    else
        -- Try again after a short delay
        C_Timer.After(0.1, RegisterDataText)
    end
end

-- Call register function
RegisterDataText()