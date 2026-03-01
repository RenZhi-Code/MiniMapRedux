local addonName, _ = ...
local MiniMapRedux = _G.MiniMapRedux

-- MouseCache Module
-- Handles mouse over caching to reduce expensive MouseIsOver calls

local MouseCache = {
    cache = {},
    cacheTimestamp = 0,
    CACHE_DURATION = 0.1
}

local function GetTime()
    return _G.GetTime()
end

local function wipe(tbl)
    return _G.table.wipe(tbl)
end

local function MouseIsOver(frame)
    return _G.MouseIsOver(frame)
end

function MouseCache.GetCachedMouseIsOver(frame)
    -- Check if frame is a valid object with required methods
    if not frame or type(frame) ~= "table" then
        return false
    end
    
    -- Additional validation to ensure frame is actually a UI frame with proper methods
    if not frame.IsMouseOver or type(frame.IsMouseOver) ~= "function" then
        -- If frame doesn't have IsMouseOver method, check if it's a valid frame type
        local frameType = frame.GetObjectType and frame:GetObjectType()
        if not frameType or (frameType ~= "Frame" and frameType ~= "Button" and frameType ~= "CheckButton" and frameType ~= "StatusBar") then
            return false
        end
        
        -- If it's a valid frame type but missing IsMouseOver, try alternative methods
        if not frame.IsMouseOver then
            -- Try to use MouseIsOver function if available
            if MouseIsOver and type(MouseIsOver) == "function" then
                local success, result = pcall(MouseIsOver, frame)
                if success then
                    return result
                else
                    return false
                end
            else
                return false
            end
        end
    end
    
    local now = GetTime()
    if now - self.cacheTimestamp > self.CACHE_DURATION then
        wipe(self.cache)
        self.cacheTimestamp = now
    end
    
    local frameKey = tostring(frame)
    if self.cache[frameKey] == nil then
        -- Use pcall to safely call IsMouseOver and handle any errors
        local success, result = pcall(function() 
            return frame:IsMouseOver()
        end)
        
        if success then
            self.cache[frameKey] = result
        else
            -- If there's an error calling IsMouseOver, default to false
            self.cache[frameKey] = false
        end
    end
    return self.cache[frameKey]
end

function MouseCache.ClearCache()
    wipe(self.cache)
    self.cacheTimestamp = GetTime()
end

-- Export the module - defer until MiniMapRedux is available
local function ExportModule()
    if MiniMapRedux and MiniMapRedux.export then
        MiniMapRedux.export("MouseCache", MouseCache)
    else
        -- Try again after a short delay
        C_Timer.After(0.1, ExportModule)
    end
end

-- Call export function
ExportModule()