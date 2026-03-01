-- Core/Bootstrap.lua - Bootstrap system to ensure proper initialization order

local Bootstrap = {}

function Bootstrap:Initialize()
    -- Bootstrap initialization started silently
    
    -- Ensure MiniMapRedux global exists
    if not _G.MiniMapRedux then
        print("MiniMapRedux: Error - Core system not initialized")
        return false
    end
    
    local MiniMapRedux = _G.MiniMapRedux
    
    -- Check for Debug module and initialize it early if available
    local Debug = MiniMapRedux.import("Debug")
    if Debug then
        Debug:LogConfig("Bootstrap initialization started")
    end
    
    -- Verify critical modules
    local criticalModules = {
        "Options",
        "ModuleLoader",
        "ConfigPanel",
        "StandaloneConfig"
    }
    
    local missingModules = {}
    for _, moduleName in ipairs(criticalModules) do
        local module = MiniMapRedux.import(moduleName)
        if not module then
            table.insert(missingModules, moduleName)
            if Debug then
                Debug:LogConfig("Critical module missing: " .. moduleName)
            else
                print("MiniMapRedux: Critical module missing: " .. moduleName)
            end
        end
    end
    
    if #missingModules > 0 then
        local missingList = table.concat(missingModules, ", ")
        print("MiniMapRedux: WARNING - Missing critical modules: " .. missingList)
    end
    
    -- Use ModuleLoader for initialization if available
    local ModuleLoader = MiniMapRedux.import("ModuleLoader")
    if ModuleLoader and type(ModuleLoader.InitializeModules) == "function" then
        -- ModuleLoader will handle initialization in the correct order
        ModuleLoader:InitializeModules()
    else
        -- Fall back to manual initialization if ModuleLoader is not available
        self:InitializeCoreModules(MiniMapRedux)
        self:InitializeUIModules(MiniMapRedux)
        self:InitializeDataModules(MiniMapRedux)
    end
    
    -- Bootstrap initialization completed silently
    return true
end

function Bootstrap:InitializeCoreModules(MiniMapRedux)
    local coreModules = {
        "Events", "API", "Debug", "Utils", "Performance", "ConfigValidator", "Test"
    }
    
    for _, moduleName in ipairs(coreModules) do
        local module = MiniMapRedux.import(moduleName)
        if module then
            print("MiniMapRedux: " .. moduleName .. " initialized")
        else
            print("MiniMapRedux: " .. moduleName .. " not available")
        end
    end
end

function Bootstrap:InitializeUIModules(MiniMapRedux)
    local uiModules = {
        "Options", "ConfigPanel", "StandaloneConfig"
    }
    
    for _, moduleName in ipairs(uiModules) do
        local module = MiniMapRedux.import(moduleName)
        if module then
            print("MiniMapRedux: " .. moduleName .. " initialized")
            -- Call Initialize if it exists
            if type(module.Initialize) == "function" then
                local success, err = pcall(module.Initialize, module)
                if not success then
                    print("MiniMapRedux: Error initializing " .. moduleName .. ": " .. tostring(err))
                end
            end
        else
            print("MiniMapRedux: " .. moduleName .. " not available")
        end
    end
end

function Bootstrap:InitializeDataModules(MiniMapRedux)
    local dataModules = {
        "DataTexts", "ButtonManager", "BarManager", "Minimap"
    }
    
    for _, moduleName in ipairs(dataModules) do
        print("MiniMapRedux: Initializing " .. moduleName)
        local module = MiniMapRedux.import(moduleName)
        if module then
            print("MiniMapRedux: " .. moduleName .. " imported")
            -- Call Initialize if it exists
            if type(module.Initialize) == "function" then
                print("MiniMapRedux: Calling Initialize for " .. moduleName)
                local success, err = pcall(module.Initialize, module)
                if not success then
                    print("MiniMapRedux: Error initializing " .. moduleName .. ": " .. tostring(err))
                else
                    print("MiniMapRedux: Successfully initialized " .. moduleName)
                end
            else
                print("MiniMapRedux: " .. moduleName .. " has no Initialize function")
            end
        else
            print("MiniMapRedux: " .. moduleName .. " not available")
        end
    end
end

-- Export the Bootstrap
if _G.MiniMapRedux then
    _G.MiniMapRedux.export("Bootstrap", Bootstrap)
end

-- Bootstrap module loaded silently

return Bootstrap