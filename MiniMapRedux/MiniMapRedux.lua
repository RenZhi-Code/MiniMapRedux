local addonName, _ = ...

-- Detect WoW version
local function GetWoWVersion()
    -- Check for defined constants first
    if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
        return "Retail"
    elseif WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
        return "Classic Era"
    elseif WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC then
        return "TBC Classic"
    elseif WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC then
        return "Wrath Classic"
    elseif WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC then
        return "Cata Classic"
    end

    -- Check for MoP Classic constant (may not be defined in older clients)
    if _G.WOW_PROJECT_MISTS_OF_PANDARIA_CLASSIC and WOW_PROJECT_ID == _G.WOW_PROJECT_MISTS_OF_PANDARIA_CLASSIC then
        return "MoP Classic"
    end

    -- Fallback: check by numeric ID (14 is MoP Classic based on pattern)
    if WOW_PROJECT_ID == 14 then
        return "MoP Classic"
    end

    -- Last resort: use build info to determine version
    local version, build, date, tocVersion = GetBuildInfo()
    if tocVersion then
        if tocVersion >= 110000 then
            return "Retail (Build: " .. tocVersion .. ")"
        elseif tocVersion >= 50000 and tocVersion < 60000 then
            return "MoP Classic (Build: " .. tocVersion .. ")"
        elseif tocVersion >= 40000 and tocVersion < 50000 then
            return "Cata Classic (Build: " .. tocVersion .. ")"
        elseif tocVersion >= 30000 and tocVersion < 40000 then
            return "Wrath Classic (Build: " .. tocVersion .. ")"
        elseif tocVersion >= 20000 and tocVersion < 30000 then
            return "TBC Classic (Build: " .. tocVersion .. ")"
        elseif tocVersion >= 11200 and tocVersion < 20000 then
            return "Classic Era (Build: " .. tocVersion .. ")"
        end
    end

    return "Unknown (Project ID: " .. tostring(WOW_PROJECT_ID) .. ", TOC: " .. tostring(tocVersion) .. ")"
end

SLASH_MINIMAPREDUX1 = "/mmr"
SLASH_MINIMAPREDUX2 = "/minimapredux"

SlashCmdList["MINIMAPREDUX"] = function(msg)
    local args = {strsplit(" ", msg:lower())}
    
    if args[1] == "config" or args[1] == "" or not args[1] then
        local StandaloneConfig = _G.MiniMapRedux and _G.MiniMapRedux.import("StandaloneConfig")
        if StandaloneConfig and StandaloneConfig.ShowConfigWindow then
            StandaloneConfig:ShowConfigWindow()
        else
            local ConfigPanel = _G.MiniMapRedux and _G.MiniMapRedux.import("ConfigPanel")
            if ConfigPanel and ConfigPanel.ShowConfigPanel then
                ConfigPanel.ShowConfigPanel()
            else
            end
        end
    elseif args[1] == "reset" then
        local Options = _G.MiniMapRedux and _G.MiniMapRedux.import("Options")
        if Options then
            Options:reset()
        end
    elseif args[1] == "debug" then
        local Debug = _G.MiniMapRedux and _G.MiniMapRedux.import("Debug")
        if Debug then
            if args[2] == "on" then
                Debug:SetEnabled(true)
            elseif args[2] == "off" then
                Debug:SetEnabled(false)
            elseif args[2] == "status" then
                Debug:DumpModuleStatus()
            else
            end
        end
    elseif args[1] == "test" then
        local Debug = _G.MiniMapRedux and _G.MiniMapRedux.import("Debug")
        if Debug and Debug.TestModules then
            Debug:TestModules()
        else
        end
    elseif args[1] == "fixconfig" or args[1] == "fixui" then
        local Debug = _G.MiniMapRedux and _G.MiniMapRedux.import("Debug")
        if Debug then
            Debug:SetEnabled(true)
            Debug:LogConfig("Manual configuration fix requested")
        end
        
        local ConfigPanel, StandaloneConfig
        
        if _G.MiniMapRedux then
            local Options = _G.MiniMapRedux.import("Options")
            if not Options then
                Options = {}
                _G.MiniMapRedux.export("Options", Options)
            end
            
            if not _G.MiniMapRedux.import("ConfigPanel") then
                ConfigPanel = {}
                _G.MiniMapRedux.export("ConfigPanel", ConfigPanel)
            end
            
            if not _G.MiniMapRedux.import("StandaloneConfig") then
                StandaloneConfig = {}
                _G.MiniMapRedux.export("StandaloneConfig", StandaloneConfig)
            end
            
            local loaded = LoadAddOnFile("Interface\\AddOns\\MiniMapRedux\\UI\\Config.lua")
            
            loaded = LoadAddOnFile("Interface\\AddOns\\MiniMapRedux\\UI\\StandaloneConfig.lua")
            
            if Debug then
                Debug:DumpModuleStatus()
            end
        else
        end
    elseif args[1] == "databars" or args[1] == "databar" then
        local Options = _G.MiniMapRedux and _G.MiniMapRedux.import("Options")
        if Options then
            if args[2] == "on" then
                Options:set("disableDataBarsModule", false)
                Options:set("showDataBar1", true)
                Options:set("showMinimapDataBar", true)
            elseif args[2] == "off" then
                Options:set("disableDataBarsModule", true)
            else
                local status = Options:get("disableDataBarsModule") and "disabled" or "enabled"
            end
            local DataTexts = _G.MiniMapRedux and _G.MiniMapRedux.import("DataTexts")
            if DataTexts and DataTexts.RefreshDataTexts then
                DataTexts.refreshing = false
                DataTexts:RefreshDataTexts()
                if args[2] == "on" then
                    C_Timer.After(0.1, function()
                        DataTexts.refreshing = false
                        DataTexts:RefreshDataTexts()
                        if DataTexts.ForceShowEnabledBars then
                            DataTexts:ForceShowEnabledBars()
                        end
                    end)
                end
            end
        end
    elseif args[1] == "buttons" then
        local ButtonManager = _G.MiniMapRedux and _G.MiniMapRedux.import("ButtonManager")
        if args[2] == "collect" then
            if ButtonManager and ButtonManager.CollectMinimapButtons then
                ButtonManager.CollectMinimapButtons()
            else
            end
        elseif args[2] == "status" then
            if ButtonManager and _G.MiniMapRedux.collectedAddonButtons then
            else
            end
        else
        end
    elseif args[1] == "datatexts" or args[1] == "datatext" then
        local DataTexts = _G.MiniMapRedux and _G.MiniMapRedux.import("DataTexts")
        if DataTexts then
            if args[2] == "list" then
                DataTexts:ListRegisteredDataTexts()
            elseif args[2] == "refresh" then
                DataTexts:RefreshDataTexts()
            else
            end
        else
        end
    elseif args[1] == "showbars" then
        local DataTexts = _G.MiniMapRedux and _G.MiniMapRedux.import("DataTexts")
        local Options = _G.MiniMapRedux and _G.MiniMapRedux.import("Options")
        if DataTexts and Options then
            Options:set("showDataBar1", true)
            Options:set("disableDataBarsModule", false)
            DataTexts:RefreshDataTexts()
            local bar = DataTexts.CreateCustomDataBar and DataTexts:CreateCustomDataBar(1)
            if bar then
                bar:Show()
            end
            DataTexts:ListRegisteredDataTexts()
        end
    elseif args[1] == "debugbars" then
        local DataTexts = _G.MiniMapRedux and _G.MiniMapRedux.import("DataTexts")
        if DataTexts then
            DataTexts:ListRegisteredDataTexts()
            DataTexts:RefreshDataTexts()
        end
    elseif args[1] == "gold" then
        if args[2] == "info" then
            print("Gold Tracker Debug Info:")
            if _G.MiniMapRedux_GoldTrackerDB then
                print("  Saved Variables Available: Yes")
                print("  Number of Characters Tracked: " .. tostring(#_G.MiniMapRedux_GoldTrackerDB.characters))
                for key, character in pairs(_G.MiniMapRedux_GoldTrackerDB.characters) do
                    print("    " .. key .. ": " .. tostring(character.money) .. " copper")
                end
            else
                print("  Saved Variables Available: No")
            end
        elseif args[2] == "reset" then
            _G.MiniMapRedux_GoldTrackerDB = {
                characters = {},
                lastUpdate = 0
            }
            print("Gold Tracker Data Reset")
        else
            print("Gold Tracker Commands:")
            print("  /mmr gold info - Show tracked gold information")
            print("  /mmr gold reset - Reset all tracked gold data")
        end
    else
    end
end

local initialized = false
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("VARIABLES_LOADED")
initFrame:RegisterEvent("PLAYER_LOGIN")

initFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "VARIABLES_LOADED" and not initialized then
        if not MiniMapRedux_GoldTrackerDB then
            MiniMapRedux_GoldTrackerDB = {
                characters = {},
                lastUpdate = 0
            }
        end
        
        local Bootstrap = _G.MiniMapRedux and _G.MiniMapRedux.import("Bootstrap")
        if Bootstrap then
            Bootstrap:Initialize()
        end
        
        local Options = _G.MiniMapRedux and _G.MiniMapRedux.import("Options")
        if Options then
            Options:init()
        end
        
        initialized = true
    elseif event == "PLAYER_LOGIN" then
        if _G.MiniMapRedux then
            local MinimapModule = _G.MiniMapRedux.import("Minimap")
            if MinimapModule then
                MinimapModule.SetupSquareMinimap()
                MinimapModule.UpdateUIElementVisibility()

                -- Restore saved position and enable movement if configured
                local Options = _G.MiniMapRedux.import("Options")
                if Options then
                    C_Timer.After(0.5, function()
                        MinimapModule.RestoreMinimapPosition()
                        if Options:get("enableMinimapMovement") then
                            MinimapModule.SetMinimapMovable(true)
                        end
                    end)
                end
            end
            
            local ButtonManager = _G.MiniMapRedux and _G.MiniMapRedux.import("ButtonManager")
            if ButtonManager and ButtonManager.CollectMinimapButtons then
                C_Timer.After(0.5, ButtonManager.CollectMinimapButtons)
            end
            
            local DataTexts = _G.MiniMapRedux and _G.MiniMapRedux.import("DataTexts")
            if DataTexts then
                C_Timer.After(0.1, function()
                    DataTexts:RefreshDataTexts()
                    C_Timer.After(1.0, function()
                        DataTexts:RefreshDataTexts()
                    end)
                end)
            end

            -- Display welcome message
            local versionString = GetWoWVersion()
            print("|cFFFF0000Mini|rMap|cFF33CCFFRedux|r Loaded! (" .. versionString .. ") Type |cFF00FF00/mmr|r for settings")
        end
    end
end)

local masterUpdateFrame = CreateFrame("Frame")
local updateTimer = 0
local UPDATE_INTERVAL = 1
local maskApplied = false

masterUpdateFrame:SetScript("OnUpdate", function(self, elapsed)
    updateTimer = updateTimer + elapsed
    if updateTimer >= UPDATE_INTERVAL then
        if Minimap then
            -- Only set mask once instead of every frame
            if not maskApplied then
                Minimap:SetMaskTexture('Interface\\BUTTONS\\WHITE8X8')
                maskApplied = true
            end

            if _G.MiniMapRedux then
                local DataTexts = _G.MiniMapRedux.import("DataTexts")
                if DataTexts then
                    DataTexts:UpdateAllDataTexts()
                end
            end
        end
        updateTimer = 0
    end
end)