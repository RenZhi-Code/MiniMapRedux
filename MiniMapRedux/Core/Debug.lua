-- Core/Debug.lua - Debug utilities for performance monitoring

local MiniMapRedux = _G.MiniMapRedux
if not MiniMapRedux then return end

local Debug = {
    enabled = false,
    log = {},
    showConfigDebugging = true  -- Always show config-related debug messages even when debug mode is off
}

-- Enable or disable debug mode
function Debug:SetEnabled(enabled)
    self.enabled = enabled
    if enabled then
        print("MiniMapRedux: Debug mode enabled")
    else
        print("MiniMapRedux: Debug mode disabled")
    end
end

-- Log a message if debug is enabled
function Debug:Log(message)
    if not self.enabled then return end
    
    local timestamp = date("%H:%M:%S")
    local logEntry = string.format("[%s] %s", timestamp, message)
    table.insert(self.log, logEntry)
    
    -- Keep only the last 100 entries
    if #self.log > 100 then
        table.remove(self.log, 1)
    end
    
    print("MiniMapRedux Debug: " .. message)
end

-- Get debug log
function Debug:GetLog()
    return self.log
end

-- Clear debug log
function Debug:ClearLog()
    table.wipe(self.log)
end

-- Export the Debug module
MiniMapRedux.export("Debug", Debug)

-- Log a configuration-specific message (always shown even when debug is disabled)
function Debug:LogConfig(message)
    local timestamp = date("%H:%M:%S")
    local logEntry = string.format("[%s][CONFIG] %s", timestamp, message)
    table.insert(self.log, logEntry)
    
    -- Keep only the last 100 entries
    if #self.log > 100 then
        table.remove(self.log, 1)
    end
    
    -- Config debug messages disabled for cleaner chat
    -- if self.showConfigDebugging or self.enabled then
    --     print("MiniMapRedux Config Debug: " .. message)
    -- end
end

-- Dump current module status to help diagnose issues
function Debug:DumpModuleStatus()
    if not MiniMapRedux then
        print("MiniMapRedux global not available")
        return
    end
    
    print("===== MiniMapRedux Module Status =====")
    if type(MiniMapRedux.modules) ~= "table" then
        print("Module table not available")
        return
    end
    
    local moduleCount = 0
    local availableModules = {}
    
    for name, module in pairs(MiniMapRedux.modules) do
        moduleCount = moduleCount + 1
        table.insert(availableModules, name)
    end
    
    print(string.format("Total modules: %d", moduleCount))
    table.sort(availableModules)
    
    print("Available modules:")
    for _, name in ipairs(availableModules) do
        print("  - " .. name)
    end
    
    print("===============================")
    
    -- Check specific critical modules
    local criticalModules = {"ConfigPanel", "StandaloneConfig", "Options", "Bootstrap", "ModuleLoader"}
    print("Critical modules status:")
    
    for _, moduleName in ipairs(criticalModules) do
        local module = MiniMapRedux.import(moduleName)
        if module then
            print(string.format("  - %s: Available", moduleName))
        else
            print(string.format("  - %s: NOT AVAILABLE", moduleName))
        end
    end
    
    print("===============================")
end

-- Test module system (replaces ModuleTest functionality)
function Debug:TestModules()
    if not MiniMapRedux then
        print("MiniMapRedux global not available")
        return
    end
    
    print("Testing MiniMapRedux module system...")
    
    -- Test core modules
    local coreModules = {
        "Core", "Events", "API", "Debug", "Utils", "Performance",
        "ConfigValidator", "ModuleLoader", "Options", "ConfigPanel"
    }
    
    for _, moduleName in ipairs(coreModules) do
        local module = MiniMapRedux.import(moduleName)
        if module then
            print("✓ " .. moduleName .. " loaded successfully")
        else
            print("✗ " .. moduleName .. " not found")
        end
    end
    
    -- Test data text modules
    local dataTextModules = {
        "DataTexts", "FriendsDataText", "MemoryDataText", "PerformanceDataText",
        "ClockDataText", "GoldDataText", "CoordinatesDataText", "DurabilityDataText",
        "GuildDataText", "MailDataText", "ExperienceDataText", "BagsDataText",
        "TalentsDataText", "ReputationDataText", "CurrencyDataText", "SessionDataText"
    }
    
    for _, moduleName in ipairs(dataTextModules) do
        local module = MiniMapRedux.import(moduleName)
        if module then
            print("✓ " .. moduleName .. " loaded successfully")
        else
            print("○ " .. moduleName .. " not loaded yet (may be normal)")
        end
    end
    
    print("Module test completed.")
end