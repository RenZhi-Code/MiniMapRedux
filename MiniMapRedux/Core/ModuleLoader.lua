local MiniMapRedux = _G.MiniMapRedux
if not MiniMapRedux then 
    return 
end

local ModuleLoader = {
    loadedModules = {},
    initOrder = {
        "Options",
        "Events",
        "API",
        "Debug",
        "Utils",
        "Performance",
        "ConfigValidator",
        "Test",
        "ConfigPanel",
        "StandaloneConfig",
        "Minimap",
        "ButtonManager",
        "BarManager",
        "DataTexts"
    }
}

function ModuleLoader:LoadModule(name)
    if self.loadedModules[name] then
        return self.loadedModules[name]
    end
    
    local success, module = pcall(MiniMapRedux.import, name)
    if success and module then
        self.loadedModules[name] = module
        return module
    else
        return nil
    end
end

function ModuleLoader:InitializeModules()
    local Debug = MiniMapRedux.import("Debug")
    
    for _, moduleName in ipairs(self.initOrder) do
        if Debug and Debug.enabled then
            Debug:Log("ModuleLoader: Initializing " .. moduleName)
        end
        
        local module = self:LoadModule(moduleName)
        local initFunc = module and (module.InitializeModule or module.Initialize)
        if module and type(initFunc) == "function" then
            local success, err = pcall(initFunc, module)
            if not success then
                if Debug then
                    Debug:LogConfig("Error initializing module " .. moduleName .. ": " .. tostring(err))
                end
            else
                if Debug and Debug.enabled then
                    Debug:Log("ModuleLoader: Successfully initialized " .. moduleName)
                end
            end
        elseif not module then
            if Debug then
                Debug:LogConfig("Module not found: " .. moduleName)
            end
        elseif type(initFunc) ~= "function" then
            if Debug and Debug.enabled then
                Debug:Log("ModuleLoader: " .. moduleName .. " has no Initialize function")
            end
        end
    end
    
    self:VerifyCriticalModules()
end

function ModuleLoader:VerifyCriticalModules()
    local criticalModules = {"ConfigPanel", "StandaloneConfig", "Options"}
    local missingModules = {}
    
    for _, moduleName in ipairs(criticalModules) do
        local module = MiniMapRedux.import(moduleName)
        if not module then
            table.insert(missingModules, moduleName)
        end
    end
    
    if #missingModules > 0 then
        local Debug = MiniMapRedux.import("Debug")
        local missingList = table.concat(missingModules, ", ")
        
        if Debug then
            Debug:LogConfig("Critical modules still missing after initialization: " .. missingList)
        end
    end
end

function ModuleLoader:GetLoadedModules()
    return self.loadedModules
end

MiniMapRedux.export("ModuleLoader", ModuleLoader)

return ModuleLoader