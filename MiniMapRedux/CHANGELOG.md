# MiniMapRedux Changelog

## 01.03.26.60

### Bug Fixes
- **Fixed font size not applying on startup** - Data bar font sizes from settings were never applied on addon load. The `RefreshDataTexts()` function now calls `UpdateDataBarFontSizes()` so saved font sizes are applied on every refresh, including startup and login/logout.
- **Fixed Housing data text not displaying** - Housing and ItemLevel data texts were registered with a `module` config pattern that the DataTexts system doesn't understand. Rewrote both to use the standard `update`/`tooltip`/`onClick` config format matching all other working data texts.
- **Fixed ItemLevel data text not displaying** - Same root cause as Housing above.
- **Fixed Session negative gold showing no minus sign** - When spending gold during a session, the tooltip showed the amount in red but without a `-` sign. Now correctly shows `-` for losses.

### New Data Texts (14 new)
- **Keystone** - Current M+ keystone level & dungeon name, color-coded by difficulty. Shows M+ rating. Tooltip shows weekly best, rating, and current affixes. Click opens Group Finder.
- **Great Vault** - Progress breakdown by category (R0 M2 P1). Shows "READY!" when rewards available. Tooltip shows per-threshold details. Click opens Great Vault.
- **Speed** - Live movement speed percentage. Green when buffed above 100%. Click opens character panel.
- **WoW Token** - Current token market price, auto-refreshes every 5 minutes. Click opens Shop.
- **Repair Cost** - Estimated repair cost, color-coded by affordability (green/yellow/red). Tooltip shows per-slot durability breakdown.
- **Quests** - Active quest count vs max (e.g., "Quests: 22/35"). Turns red when nearly full. Tooltip lists tracked quests with completion status.
- **Professions** - Primary profession names and skill levels. Tooltip shows all professions with progress percentages.
- **PvP Rating** - Highest rated bracket and rating, color-coded by rank (Combatant through Gladiator). Tooltip shows all brackets with win/loss records.
- **Lockouts** - Instance lockout count with raid/dungeon breakdown (e.g., "2R 1D"). Tooltip shows full details with boss progress and reset timers.
- **Delves** - Companion name and level, or key count. Tooltip shows delve currencies.
- **Renown** - Shows lowest renown faction and level, or "All Maxed". Tooltip lists all major factions with progress.
- **Played** - Total time played (e.g., "45d 12h"). Tooltip shows total and current level breakdown. Suppresses /played chat spam.
- **Calendar** - Shows pending events/invites count, or current date. Tooltip lists today's events colored by type. Click opens Calendar.
- **Volume** - Master volume percentage with mute toggle on click. Tooltip shows all volume channels.
- **Loot Spec** - Current loot specialization, role-colored. Shows `*` when locked to a non-active spec. Click cycles through specs.

### Data Text Display Improvements
- **Experience** - Now shows level, XP%, and rested XP on bar: `Lv72 XP: 45% R: 30%` (rested in blue). At max level shows `Lv80 Max`.
- **Durability** - Shows lowest item durability when significantly lower than average: `Dur: 85% (Low: 12%)`. Colors based on worst piece.
- **Friends** - Shows BNet online count alongside WoW count: `Friends: 3 WoW | 7 BNet`.
- **Mail** - Shows first sender name and count: `Mail: PlayerName +2` instead of just "Mail: New".
- **Item Level** - Added "iLvl:" label prefix. Shows overall ilvl when higher than equipped: `iLvl: 528.5 (535.2)`.
- **Speed** - Added "Speed:" label prefix for clarity.
- **Lockouts** - Shows raid vs dungeon breakdown: `Lockouts: 2R 1D`.
- **Keystone** - Appends M+ rating in gold: `+12 Ara-Kara (2450)`. Shows rating even without a key.
- **Great Vault** - Shows per-category breakdown: `Vault: R2 M3 P0` instead of just total count.

### Config UI
- Added new "Dungeons & PvP" category for Keystone, Vault, Lockouts, Delves, and PvP Rating.
- Renamed "System Performance" to "System & Misc", now includes WoW Token, Volume, and Housing.
- Added ItemLevel and Loot Spec to "Character Information" category.
- Added Renown, Speed, Quests, and Calendar to "World & Location" category.

### Performance
- **Removed brute-force currency scan** - Session data text was iterating through currency IDs 1-3000 with pcall on each at startup. Now uses the currency list API which covers all player currencies.
- **Stopped per-second currency scanning** - Currency changes are now only tracked via the `CURRENCY_DISPLAY_UPDATE` event instead of scanning every second.

### Font
- **Switched to BarlowCondensed-Bold** - All data text fonts now use the bundled `BarlowCondensed-Bold.otf` instead of the default Blizzard `FRIZQT__.TTF`. The condensed font fits more information in the same bar space.

---

## 01.02.26.51

### Bug Fixes
- **Fixed minimap data bar showing as empty box** - The `DataTexts:Initialize()` function was calling `CreateCustomDataBar()` and `PositionDataTextsOnBar()` without the required `self:` prefix, causing a silent error that prevented data bars from populating. This was the root cause of the empty bar issue reported since 11/26/2025.
- **Fixed clock always displaying 24-hour military time** - Added a configurable clock format option. Users can now switch between 12-hour (AM/PM) and 24-hour display via `/mmr config` > Minimap tab > Clock Settings.
- **Fixed OnUpdate performance waste** - The minimap square mask texture (`SetMaskTexture`) and `Show()` calls were being re-applied every single second. Now applied once and cached.

### Patch 12.0.0 / 12.0.1 API Compatibility
- **Minimap zoom** - `Minimap_ZoomIn()` / `Minimap_ZoomOut()` now have safe fallbacks for clients where these functions may not exist. Falls back to `Minimap.ZoomIn:Click()` or direct `Minimap:SetZoom()`.
- **Resize API** - Deprecated `SetMinResize()` / `SetMaxResize()` replaced with `SetResizeBounds()` as primary path, keeping legacy calls as fallback for Classic clients only.
- **Tracking menu** - Right-click tracking now prioritizes the modern `MinimapCluster.Tracking.Button` path (11.0+) before falling back to legacy `ToggleDropDownMenu` / `MiniMapTrackingDropDown`.
- **TOC updated** - Interface versions now include `120000` and `120001` for Patch 12.0.0 and 12.0.1 support.

### New Features
- **12-hour clock format** - New "Use 12-hour format (AM/PM)" checkbox in `/mmr config` > Minimap tab. Displays time as `3:45 PM` instead of `15:45`.
- **Enhanced clock tooltip** - Now shows both 12hr and 24hr formats, local date, UTC offset, server time, and time-of-day description.

### UI Fixes
- **Config panel tabs** - Reduced tab width so all 6 tabs fit within the configuration window frame instead of overflowing.
