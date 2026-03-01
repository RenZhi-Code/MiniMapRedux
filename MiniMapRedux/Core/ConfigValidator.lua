-- Core/ConfigValidator.lua - Configuration validation utilities

local MiniMapRedux = _G.MiniMapRedux
if not MiniMapRedux then return end

local ConfigValidator = {}

-- Validate a numeric value
function ConfigValidator:ValidateNumber(value, min, max, default)
    if type(value) ~= "number" then
        return default
    end
    
    if min and value < min then
        return min
    end
    
    if max and value > max then
        return max
    end
    
    return value
end

-- Validate a boolean value
function ConfigValidator:ValidateBoolean(value, default)
    if type(value) ~= "boolean" then
        return default
    end
    return value
end

-- Validate a string value
function ConfigValidator:ValidateString(value, allowedValues, default)
    if type(value) ~= "string" then
        return default
    end
    
    if allowedValues then
        local found = false
        for _, allowed in ipairs(allowedValues) do
            if value == allowed then
                found = true
                break
            end
        end
        if not found then
            return default
        end
    end
    
    return value
end

-- Validate data text position
function ConfigValidator:ValidateDataTextPosition(position, default)
    local validPositions = {
        minimap = true,
        DataBar1 = true,
        DataBar2 = true,
        DataBar3 = true,
        DataBar4 = true,
        DataBar5 = true,
        DataBar6 = true,
        DataBar7 = true,
        DataBar8 = true,
        DataBar9 = true,
        DataBar10 = true,
        hide = true
    }
    
    if not validPositions[position] then
        return default or "DataBar1"
    end
    
    return position
end

-- Export the ConfigValidator
MiniMapRedux.export("ConfigValidator", ConfigValidator)