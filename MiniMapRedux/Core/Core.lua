local MiniMapRedux = {}

MiniMapRedux.modules = {}
MiniMapRedux.version = "1.0.0"

function MiniMapRedux.export(name, module)
    if name == nil then
        error("Module name cannot be nil")
    end
    if MiniMapRedux.modules[name] ~= nil then
        error("Module already exists: " .. name)
    end
    if type(module) ~= "table" then
        error("Module needs to be table: " .. name)
    end
    MiniMapRedux.modules[name] = module
    return module
end

function MiniMapRedux.import(name)
    if name == nil then
        error("Module name cannot be nil")
    end
    local module = MiniMapRedux.modules[name]
    return module
end

_G.MiniMapRedux = MiniMapRedux

return MiniMapRedux