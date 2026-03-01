local addonName, _ = ...
local MiniMapRedux = _G.MiniMapRedux

-- Coordinates Data Text Module
local DataTexts
local function GetDataTexts()
    if not DataTexts and MiniMapRedux and MiniMapRedux.import then
        DataTexts = MiniMapRedux.import("DataTexts")
    end
    return DataTexts
end

-- Local storage for coordinates data
local coordinatesData = {
    x = 0,
    y = 0,
    zone = "",
    subzone = ""
}

-- Function to refresh coordinates data with error handling
local function RefreshCoordinatesData()
    local DataTexts = GetDataTexts()
    if not DataTexts then return end
    
    local success, errorMessage = pcall(function()
        -- Get zone information
        local zoneSuccess, zone = pcall(GetZoneText)
        if zoneSuccess and zone then
            coordinatesData.zone = zone
        else
            coordinatesData.zone = ""
        end
        
        local subzoneSuccess, subzone = pcall(GetSubZoneText)
        if subzoneSuccess and subzone then
            coordinatesData.subzone = subzone
        else
            coordinatesData.subzone = ""
        end
        
        -- Get player coordinates using the new map API
        local mapIDSuccess, mapID = pcall(C_Map.GetBestMapForUnit, "player")
        if mapIDSuccess and mapID then
            local positionSuccess, position = pcall(C_Map.GetPlayerMapPosition, mapID, "player")
            if positionSuccess and position then
                local x, y = position:GetXY()
                if x and y and x > 0 and y > 0 then
                    coordinatesData.x = x
                    coordinatesData.y = y
                else
                    coordinatesData.x = 0
                    coordinatesData.y = 0
                end
            else
                coordinatesData.x = 0
                coordinatesData.y = 0
            end
        else
            coordinatesData.x = 0
            coordinatesData.y = 0
        end
    end)
    
    if not success then
        print("Coordinates data refresh failed: " .. tostring(errorMessage))
        coordinatesData.x = 0
        coordinatesData.y = 0
        coordinatesData.zone = ""
        coordinatesData.subzone = ""
    end
end

-- Event frame for coordinates updates
local coordinatesEventFrame = CreateFrame("Frame")
coordinatesEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
coordinatesEventFrame:RegisterEvent("ZONE_CHANGED")
coordinatesEventFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
coordinatesEventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
coordinatesEventFrame:SetScript("OnEvent", function(self, event, ...)
    RefreshCoordinatesData()
end)

-- Initialize coordinates data
RefreshCoordinatesData()

-- Timer to periodically update coordinates data
C_Timer.NewTicker(1, function()
    RefreshCoordinatesData()
end)

local coordinatesDataText = {
    name = "Coordinates",
    color = {0.3, 0.8, 1}, -- Blue
    icon = "Interface\\Icons\\INV_Misc_Map_01", -- Map icon
    update = function(frame)
        local DataTexts = GetDataTexts()
        if not DataTexts then return end
        
        if coordinatesData.x > 0 and coordinatesData.y > 0 then
            -- Convert to percentages
            local coordX = math.floor(coordinatesData.x * 100)
            local coordY = math.floor(coordinatesData.y * 100)
            frame.text:SetText(string.format("Coords: %d, %d", coordX, coordY))
            frame.text:SetTextColor(0.3, 0.8, 1) -- Blue
        else
            frame.text:SetText("Coords: N/A")
            frame.text:SetTextColor(0.7, 0.7, 0.7) -- Gray
        end
    end,
    tooltip = function()
        local DataTexts = GetDataTexts()
        if not DataTexts then return end
        
        GameTooltip:SetText("Player Coordinates")
        
        if coordinatesData.x > 0 and coordinatesData.y > 0 then
            local coordX = coordinatesData.x * 100
            local coordY = coordinatesData.y * 100
            GameTooltip:AddLine(string.format("X: %.1f%%", coordX), 1, 1, 1)
            GameTooltip:AddLine(string.format("Y: %.1f%%", coordY), 1, 1, 1)
            
            -- Add zone information
            if coordinatesData.zone and coordinatesData.zone ~= "" then
                GameTooltip:AddLine("Zone: " .. coordinatesData.zone, 0.8, 0.8, 0.8)
            end
            
            -- Add subzone information
            if coordinatesData.subzone and coordinatesData.subzone ~= "" and coordinatesData.subzone ~= coordinatesData.zone then
                GameTooltip:AddLine("Area: " .. coordinatesData.subzone, 0.8, 0.8, 0.8)
            end
        else
            GameTooltip:AddLine("Coordinates not available", 0.7, 0.7, 0.7)
            GameTooltip:AddLine("Try opening the world map", 0.8, 0.8, 0.8)
        end
        
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click to open world map", 0.8, 0.8, 0.8)
    end,
    onClick = function()
        -- Open world map with error handling
        local success, errorMessage = pcall(function()
            -- Use modern ToggleWorldMap if available
            if ToggleWorldMap then
                ToggleWorldMap()
            elseif C_Map and C_Map.ToggleWorldMap then
                C_Map.ToggleWorldMap()
            elseif WorldMapFrame then
                if WorldMapFrame:IsShown() then
                    WorldMapFrame:Hide()
                else
                    WorldMapFrame:Show()
                end
            else
                -- Last resort: try the slash command
                if _G.ChatFrame_OpenChat then
                    _G.ChatFrame_OpenChat("/worldmap")
                end
            end
        end)
        
        if not success then
            print("Failed to toggle world map: " .. tostring(errorMessage))
        end
    end
}

-- Register the coordinates data text - defer until DataTexts is available
local function RegisterDataText()
    local DataTexts = GetDataTexts()
    if DataTexts then
        DataTexts:RegisterDataText("coordinates", coordinatesDataText)
        -- Export an empty module (registration is enough)
        if MiniMapRedux and MiniMapRedux.export then
            MiniMapRedux.export("CoordinatesDataText", {})
        end
    else
        -- Try again after a short delay
        C_Timer.After(0.1, RegisterDataText)
    end
end

-- Call register function
RegisterDataText()