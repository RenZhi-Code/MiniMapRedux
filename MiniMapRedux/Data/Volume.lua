local addonName, _ = ...
local MiniMapRedux = _G.MiniMapRedux

local DataTexts
local function GetDataTexts()
    if not DataTexts and MiniMapRedux and MiniMapRedux.import then
        DataTexts = MiniMapRedux.import("DataTexts")
    end
    return DataTexts
end

local volumeDataText = {
    name = "Volume",
    color = {0.8, 0.8, 1},
    icon = "Interface\\Icons\\INV_Misc_Ear_NightElf_02",
    update = function(frame)
        if not GetDataTexts() then return end

        local enabled = GetCVar("Sound_EnableAllSound") == "1"
        local master = tonumber(GetCVar("Sound_MasterVolume")) or 0
        local pct = math.floor(master * 100 + 0.5)

        if not enabled then
            frame.text:SetText("Muted")
            frame.text:SetTextColor(1, 0.3, 0.3)
        else
            frame.text:SetText(string.format("Vol: %d%%", pct))
            if pct > 50 then
                frame.text:SetTextColor(0.3, 1, 0.3)
            elseif pct > 0 then
                frame.text:SetTextColor(1, 0.8, 0.3)
            else
                frame.text:SetTextColor(0.5, 0.5, 0.5)
            end
        end
    end,
    tooltip = function()
        if not GetDataTexts() then return end

        GameTooltip:SetText("Volume Control")

        local enabled = GetCVar("Sound_EnableAllSound") == "1"
        local master = tonumber(GetCVar("Sound_MasterVolume")) or 0
        local music = tonumber(GetCVar("Sound_MusicVolume")) or 0
        local sfx = tonumber(GetCVar("Sound_SFXVolume")) or 0
        local ambience = tonumber(GetCVar("Sound_AmbienceVolume")) or 0
        local dialog = tonumber(GetCVar("Sound_DialogVolume")) or 0

        if not enabled then
            GameTooltip:AddLine("All Sound: MUTED", 1, 0.3, 0.3)
        else
            GameTooltip:AddLine("All Sound: Enabled", 0.3, 1, 0.3)
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Volumes:", 0.8, 0.8, 0.8)
        GameTooltip:AddLine(string.format("  Master: %d%%", math.floor(master * 100 + 0.5)), 1, 1, 1)
        GameTooltip:AddLine(string.format("  Music: %d%%", math.floor(music * 100 + 0.5)), 0.8, 0.8, 0.8)
        GameTooltip:AddLine(string.format("  Effects: %d%%", math.floor(sfx * 100 + 0.5)), 0.8, 0.8, 0.8)
        GameTooltip:AddLine(string.format("  Ambience: %d%%", math.floor(ambience * 100 + 0.5)), 0.8, 0.8, 0.8)
        GameTooltip:AddLine(string.format("  Dialog: %d%%", math.floor(dialog * 100 + 0.5)), 0.8, 0.8, 0.8)

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click to toggle mute", 0.8, 0.8, 0.8)
    end,
    onClick = function()
        local enabled = GetCVar("Sound_EnableAllSound") == "1"
        if enabled then
            SetCVar("Sound_EnableAllSound", "0")
        else
            SetCVar("Sound_EnableAllSound", "1")
        end
    end
}

-- Events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("SOUNDKIT_FINISHED")
eventFrame:RegisterEvent("CVAR_UPDATE")
eventFrame:SetScript("OnEvent", function() end) -- Just ensure frame exists for updates

local function RegisterDataText()
    local DataTexts = GetDataTexts()
    if DataTexts then
        DataTexts:RegisterDataText("volume", volumeDataText)
        if MiniMapRedux and MiniMapRedux.export then
            MiniMapRedux.export("VolumeDataText", {})
        end
    else
        C_Timer.After(0.1, RegisterDataText)
    end
end

RegisterDataText()
