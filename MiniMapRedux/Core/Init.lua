-- Core/Init.lua - Initialization script to ensure proper module loading order

-- Starting initialization

-- This file ensures that core modules are loaded before others
-- It's loaded early in the TOC file to set up the foundation

local MiniMapRedux = _G.MiniMapRedux
if not MiniMapRedux then
    print("MiniMapRedux: Error - Core system not found")
    return
end

-- Core system initialized silently

-- Initialize the module loader
local ModuleLoader = MiniMapRedux.import("ModuleLoader")
if ModuleLoader then
    -- Module loader ready
    
    -- Since ModuleLoader is available, we can start initializing modules
    -- This will help ensure proper startup sequence
    if type(ModuleLoader.InitializeModules) == "function" then
        ModuleLoader:InitializeModules()
    end
else
    print("MiniMapRedux: Module loader not available yet")
end

-- Initialization complete silently