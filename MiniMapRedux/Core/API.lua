-- Core/API.lua - Core API Functions
-- Centralized API access with proper error handling

local MiniMapRedux = _G.MiniMapRedux
if not MiniMapRedux then return end

local API = {}

-- Safe API call with pcall
function API:SafeCall(func, ...)
    if type(func) ~= "function" then
        return false, "Not a function"
    end
    
    local success, result = pcall(func, ...)
    if success then
        return true, result
    else
        return false, result
    end
end

-- Get options module safely
function API:GetOptions()
    local success, options = self:SafeCall(MiniMapRedux.import, "Options")
    if success and options then
        return options
    else
        return nil, "Options module not available"
    end
end

-- Get data texts module safely
function API:GetDataTexts()
    local success, dataTexts = self:SafeCall(MiniMapRedux.import, "DataTexts")
    if success and dataTexts then
        return dataTexts
    else
        return nil, "DataTexts module not available"
    end
end

-- Export the API module
MiniMapRedux.export("API", API)