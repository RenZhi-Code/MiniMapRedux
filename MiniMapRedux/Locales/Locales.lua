local addonName, _ = ...
local MiniMapRedux = _G.MiniMapRedux

local L = {}
local locale = GetLocale()
local defaultLocale = {
    -- Addon Info
    ["ADDON_NAME"] = "MiniMapRedux",
    ["ADDON_DESC"] = "Configuration Panel",
    ["VERSION"] = "Version",
    
    -- General UI
    ["GENERAL"] = "General",
    ["MINIMAP"] = "Minimap",
    ["DATA_BARS"] = "Data Bars",
    ["DATA_TEXTS"] = "Data Texts",
    ["MINIMAP_BUTTONS"] = "Minimap Buttons",
    ["ADVANCED"] = "Advanced",
    ["SETTINGS"] = "Settings",
    ["CONFIGURATION"] = "Configuration",
    ["RESET_SETTINGS"] = "Reset Settings",
    ["RESET_ALL_SETTINGS"] = "Reset All Settings",
    
    -- General Settings
    ["GENERAL_SETTINGS"] = "General Settings",
    ["ENABLE_DATA_BARS_MODULE"] = "Enable Data Bars Module",
    ["DATA_BARS_MODULE_DESC"] = "Toggle data bars that show game information",
    ["ENABLE_MINIMAP_BUTTON_COLLECTION"] = "Enable Minimap Button Collection",
    ["MINIMAP_BUTTON_COLLECTION_DESC"] = "Collect minimap buttons into a dedicated button bar",
    
    -- Minimap Settings
    ["MINIMAP_SETTINGS"] = "Minimap Settings",
    ["MINIMAP_SCALE"] = "Minimap Scale",
    ["MINIMAP_ICON_VISIBILITY"] = "Minimap Icon Visibility",
    ["MINIMAP_ICON_VISIBILITY_DESC"] = "Control which icons are shown on the minimap",
    ["SHOW_MAIL_ICON"] = "Show Mail Icon",
    ["SHOW_MAIL_ICON_DESC"] = "Show or hide the mail notification icon",
    ["SHOW_CRAFTING_ORDER_ICON"] = "Show Crafting Order Icon",
    ["SHOW_CRAFTING_ORDER_ICON_DESC"] = "Show or hide the crafting order notification icon",
    ["SHOW_INSTANCE_DIFFICULTY"] = "Show Instance Difficulty",
    ["SHOW_INSTANCE_DIFFICULTY_DESC"] = "Show or hide the instance difficulty indicator",
    ["SHOW_MISSIONS_BUTTON"] = "Show Missions Button",
    ["SHOW_MISSIONS_BUTTON_DESC"] = "Show or hide the missions/expansion landing page button",
    ["SHOW_CALENDAR_BUTTON"] = "Show Calendar Button",
    ["SHOW_CALENDAR_BUTTON_DESC"] = "Show or hide the calendar/game time button",
    ["SHOW_ADDON_COMPARTMENT"] = "Show Addon Compartment",
    ["SHOW_ADDON_COMPARTMENT_DESC"] = "Show or hide the addon compartment button",
    ["SHOW_ZOOM_BUTTONS"] = "Show Zoom Buttons",
    ["SHOW_ZOOM_BUTTONS_DESC"] = "Show or hide the minimap zoom in/out buttons",
    
    -- Data Bars Settings
    ["DATA_BARS_SETTINGS"] = "Data Bars Settings",
    ["MINIMAP_DATA_BAR"] = "Minimap Data Bar",
    ["SHOW_MINIMAP_DATA_BAR"] = "Show Minimap Data Bar",
    ["SHOW_MINIMAP_DATA_BAR_DESC"] = "Show data texts on the minimap",
    ["LOCK_DATA_BARS"] = "Lock Data Bars",
    ["LOCK_DATA_BARS_DESC"] = "Lock data bars in place to prevent accidental moving",
    ["SHOW_DATA_TEXT_ICONS"] = "Show Data Text Icons",
    ["SHOW_DATA_TEXT_ICONS_DESC"] = "Toggle visibility of icons in data texts",
    ["DATA_BARS_1_10"] = "Data Bars (1-10)",
    ["DATA_BAR"] = "Data Bar",
    ["OPACITY"] = "Opacity",
    ["FONT_SIZE"] = "Font Size",
    ["TOGGLE_VISIBILITY"] = "Toggle visibility of Data Bar",
    
    -- Data Text Assignments
    ["DATA_TEXT_ASSIGNMENTS"] = "Data Text Assignments",
    ["DATA_TEXT_ASSIGNMENTS_DESC"] = "Assign each data text to a specific data bar or the minimap",
    ["NO_DATA_TEXTS_AVAILABLE"] = "No data texts are currently available. Make sure the Data Texts module is enabled.",
    
    -- Data Text Categories
    ["CHARACTER_INFORMATION"] = "Character Information",
    ["WORLD_LOCATION"] = "World & Location",
    ["SOCIAL_COMMUNICATION"] = "Social & Communication",
    ["DUNGEONS_PVP"] = "Dungeons & PvP",
    ["SYSTEM_MISC"] = "System & Misc",
    ["OTHER"] = "Other",

    -- Data Text Names
    ["EXPERIENCE"] = "Experience",
    ["GOLD"] = "Gold",
    ["DURABILITY"] = "Durability",
    ["TALENTS"] = "Talents",
    ["BAGS"] = "Bags",
    ["ITEM_LEVEL"] = "Item Level",
    ["LOOT_SPEC"] = "Loot Spec",
    ["PROFESSIONS"] = "Professions",
    ["REPAIR"] = "Repair",
    ["PLAYED"] = "Played",
    ["COORDINATES"] = "Coordinates",
    ["CLOCK"] = "Clock",
    ["REPUTATION"] = "Reputation",
    ["CURRENCY"] = "Currency",
    ["RENOWN"] = "Renown",
    ["SPEED"] = "Speed",
    ["QUESTS"] = "Quests",
    ["CALENDAR"] = "Calendar",
    ["FRIENDS"] = "Friends",
    ["GUILD"] = "Guild",
    ["MAIL"] = "Mail",
    ["KEYSTONE"] = "Keystone",
    ["VAULT"] = "Vault",
    ["LOCKOUTS"] = "Lockouts",
    ["DELVES"] = "Delves",
    ["PVP_RATING"] = "PvP Rating",
    ["PERFORMANCE"] = "Performance",
    ["MEMORY"] = "Memory",
    ["SESSION"] = "Session",
    ["WOW_TOKEN"] = "WoW Token",
    ["VOLUME"] = "Volume",
    ["HOUSING"] = "Housing",
    
    -- Data Text Positions
    ["POSITION_MINIMAP"] = "Minimap",
    ["POSITION_HIDDEN"] = "Hidden",
    ["POSITION_DATA_BAR"] = "Data Bar",
    
    -- Button Settings
    ["BUTTON_SETTINGS"] = "Button Settings",
    ["BACKGROUND_OPACITY"] = "Background Opacity",
    ["BACKGROUND_OPACITY_DESC"] = "Adjust button bar background opacity (0 = no background, 100 = solid background)",
    ["BUTTON_SIZE"] = "Button Size",
    ["BUTTON_SIZE_DESC"] = "Adjust the size of minimap buttons",
    ["BUTTON_ORIENTATION"] = "Button Orientation",
    
    -- Advanced Settings
    ["ADVANCED_SETTINGS"] = "Advanced Settings",
    ["ADVANCED_SETTINGS_DESC"] = "Advanced configuration options for MiniMapRedux",
    ["RESET_INFO"] = "Use this option to reset all configuration settings to their default values. This cannot be undone.",
    
    -- Data Text Display Formats
    ["BAGS_FORMAT"] = "Bags: %d/%d",
    ["BAGS_ZERO"] = "Bags: 0/0",
    ["LOCAL_TIME"] = "Local: %s",
    ["COORDS_FORMAT"] = "Coords: %d, %d",
    ["COORDS_NA"] = "Coords: N/A",
    ["CURRENCY_NONE"] = "Currency: None",
    ["MAX_LEVEL"] = "Max Level",
    ["GOLD_FORMAT"] = "Gold: %s",
    ["GUILD_FORMAT"] = "Guild: %s",
    ["GUILD_NONE"] = "Guild: None",
    ["MAIL_NEW"] = "Mail: New",
    ["MAIL_YES"] = "Mail: Yes",
    ["MAIL_NONE"] = "Mail: None",
    ["REPUTATION_NONE"] = "Reputation: None",
    
    -- Tooltips
    ["BAG_SPACE"] = "Bag Space",
    ["TOTAL_SLOTS"] = "Total: %d/%d slots used (%.1f%%)",
    ["FREE_SLOTS"] = "Free: %d slots",
    ["BAGS_LABEL"] = "Bags:",
    ["BAGS_NEARLY_FULL"] = "Warning: Bags nearly full!",
    ["NO_BAGS_EQUIPPED"] = "No bags equipped",
    ["CLICK_TO_OPEN_BAGS"] = "Click to open all bags",
    
    ["LOCAL_TIME_LABEL"] = "Local Time",
    ["SERVER_TIME"] = "Server: %s",
    ["CLICK_FOR_CALENDAR"] = "Click to open calendar",
    
    ["PLAYER_COORDINATES"] = "Player Coordinates",
    ["COORDS_NOT_AVAILABLE"] = "Coordinates not available",
    ["TRY_OPEN_MAP"] = "Try opening the world map",
    ["CLICK_TO_OPEN_MAP"] = "Click to open world map",
    
    ["CURRENCY_INFORMATION"] = "Currency Information",
    ["NO_CURRENCIES_TRACKED"] = "No currencies being tracked",
    
    ["EQUIPMENT_DURABILITY"] = "Equipment Durability",
    ["ALL_ITEMS_REPAIRED"] = "All items are fully repaired!",
    ["OVERALL_DURABILITY"] = "Overall: %.1f%%",
    ["EQUIPPED_ITEMS"] = "Equipped Items:",
    ["CLICK_TO_TOGGLE_CHAR"] = "Click to toggle character panel",
    
    ["EXPERIENCE_INFORMATION"] = "Experience Information",
    ["CURRENT_XP"] = "Current: %s / %s",
    ["REMAINING_XP"] = "Remaining: %s",
    ["PERCENT_TO_LEVEL"] = "%.1f%% to level %d",
    ["RESTED_XP"] = "Rested: %s (%.1f%%)",
    ["NO_RESTED_XP"] = "No rested XP",
    
    ["FRIENDS_LIST"] = "Friends List",
    ["ONLINE_FRIENDS"] = "Online: %d / %d",
    ["NO_FRIENDS_ONLINE"] = "No friends online",
    ["CLICK_TO_TOGGLE_SOCIAL"] = "Click to toggle social panel",
    
    ["GOLD_INFORMATION"] = "Gold Information",
    ["CURRENT_CHARACTER"] = "Current Character: %s",
    ["WARBOUND_BANK"] = "Warbound Bank: %s",
    ["TOTAL_TRACKED"] = "Total Tracked: %s",
    ["GRAND_TOTAL"] = "Grand Total: %s",
    ["OTHER_CHARACTERS"] = "Other Characters:",
    ["NO_OTHER_CHARS_TRACKED"] = "No other characters tracked yet",
    ["GOLD_TRACKING_NOTE"] = "Note: Gold amounts are tracked automatically",
    ["GOLD_TRACKING_NOTE2"] = "when you log into each character.",
    ["GOLD_TRACKING_NOTE3"] = "Data is stored locally on this machine.",
    ["YOURE_WEALTHY"] = "You're quite wealthy!",
    ["DOING_WELL"] = "You're doing well financially",
    ["KEEP_GRINDING"] = "Keep grinding for more gold!",
    
    ["GUILD_INFORMATION"] = "Guild Information",
    ["MEMBERS_ONLINE"] = "Members Online: %d / %d",
    ["GUILD_RANK"] = "Rank: %s",
    ["NO_GUILD"] = "Not in a guild",
    ["CLICK_TO_TOGGLE_GUILD"] = "Click to toggle guild panel",
    
    ["MAIL_STATUS"] = "Mail Status",
    ["YOU_HAVE_MAIL"] = "You have mail!",
    ["NEW_MAIL_AVAILABLE"] = "New mail available",
    ["NO_MAIL"] = "No mail",
    
    ["MEMORY_USAGE"] = "Memory Usage",
    ["ADDON_MEMORY"] = "Addon Memory: %.2f MB",
    ["TOTAL_MEMORY"] = "Total: %.2f MB",
    ["CLICK_TO_COLLECT"] = "Click to collect garbage",
    
    ["PERFORMANCE_METRICS"] = "Performance Metrics",
    ["FPS_LABEL"] = "FPS: %d",
    ["LATENCY_HOME"] = "Home: %d ms",
    ["LATENCY_WORLD"] = "World: %d ms",
    ["BANDWIDTH_IN"] = "Download: %.2f KB/s",
    ["BANDWIDTH_OUT"] = "Upload: %.2f KB/s",
    
    -- Messages
    ["CONFIG_PANEL_ERROR"] = "Error creating configuration panel",
    ["DATA_REFRESH_FAILED"] = "%s data refresh failed: %s",
    ["FAILED_TO_TOGGLE"] = "Failed to toggle %s: %s",
    ["FAILED_TO_OPEN"] = "Failed to open %s: %s",
}

L = defaultLocale
local function GetLocaleString(key)
    return L[key] or key
end

MiniMapRedux.L = setmetatable({}, {
    __index = function(t, k)
        return GetLocaleString(k)
    end
})

MiniMapRedux.Locale = L
MiniMapRedux.DefaultLocale = defaultLocale
function MiniMapRedux:RegisterLocale(localeCode, translations)
    if locale == localeCode then
        for k, v in pairs(translations) do
            L[k] = v
        end
    end
end
