-- Core/Utils.lua - Utility functions

local MiniMapRedux = _G.MiniMapRedux
if not MiniMapRedux then return end

local Utils = {}

-- Throttle function execution
function Utils:Throttle(func, delay)
    local lastCall = 0
    return function(...)
        local now = GetTime()
        if now - lastCall >= delay then
            lastCall = now
            return func(...)
        end
    end
end

-- Debounce function execution
function Utils:Debounce(func, delay)
    local timer
    return function(...)
        local args = {...}
        if timer then
            timer:Cancel()
        end
        timer = C_Timer.NewTimer(delay, function()
            -- Use table.unpack if available, otherwise fall back to unpack or manual unpacking
            if table and table.unpack then
                func(table.unpack(args))
            elseif unpack then
                func(unpack(args))
            else
                -- Manual unpacking for safety - support up to 10 arguments
                func(args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10])
            end
        end)
    end
end

-- Safe frame creation
function Utils:CreateFrame(frameType, name, parent, template)
    local success, frame = pcall(CreateFrame, frameType, name, parent, template)
    if success then
        return frame
    else
        print("MiniMapRedux: Failed to create frame " .. (name or "unnamed"))
        return nil
    end
end

-- Check if a frame is valid
function Utils:IsValidFrame(frame)
    return type(frame) == "table" and 
           type(frame.IsObjectType) == "function" and 
           pcall(frame.IsObjectType, frame, "Frame")
end

-- Export the Utils module
MiniMapRedux.export("Utils", Utils)