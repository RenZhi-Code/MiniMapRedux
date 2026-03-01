-- Core/Events.lua - Event Management System
-- Centralized event handling following Blizzard's coding standards

local MiniMapRedux = _G.MiniMapRedux
if not MiniMapRedux then return end

local Events = {}
local eventFrame = CreateFrame("Frame")

-- Event registry
local eventRegistry = {}

-- Register an event
function Events:RegisterEvent(event, handler)
    if not eventRegistry[event] then
        eventRegistry[event] = {}
        eventFrame:RegisterEvent(event)
    end
    table.insert(eventRegistry[event], handler)
end

-- Unregister an event
function Events:UnregisterEvent(event, handler)
    if eventRegistry[event] then
        for i, h in ipairs(eventRegistry[event]) do
            if h == handler then
                table.remove(eventRegistry[event], i)
                break
            end
        end
        -- If no handlers left, unregister the event
        if #eventRegistry[event] == 0 then
            eventFrame:UnregisterEvent(event)
            eventRegistry[event] = nil
        end
    end
end

-- Event handler
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if eventRegistry[event] then
        for _, handler in ipairs(eventRegistry[event]) do
            local success, err = pcall(handler, event, ...)
            if not success then
                print("MiniMapRedux: Error in event handler for " .. event .. ": " .. tostring(err))
            end
        end
    end
end)

-- Export the Events module
MiniMapRedux.export("Events", Events)