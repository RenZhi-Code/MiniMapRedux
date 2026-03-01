# MiniMap Redux

A clean and modern minimap enhancement addon for World of Warcraft with customizable data bars and intelligent button collection.

## Features

### Square Minimap
- Clean square minimap design with custom border
- Mousewheel zoom support
- Right-click for tracking menu
- Scalable from 50% to 200%
- MiniMap buttons hidden in a side bar

### Data Text Bars
- Minimap Data Bar: Attached below minimap (up to 3 data texts)
- First Data Bar: Movable, customizable positioning
- Second Data Bar: Optional additional bar
- 29 Data Text Types: Memory, Coordinates, Clock, Durability, Gold, Guild, Friends, Mail, Experience, Bags, Talents, Reputation, Currency, Session, Performance, Keystone, Great Vault, Speed, WoW Token, Repair Cost, Quests, Professions, PvP Rating, Lockouts, Delves, Renown, Played, Calendar, Volume, Loot Spec

### Enhanced Data Tracking
- Session Statistics: Track XP/gold gains, playtime, and performance over time
- Performance History: FPS and latency monitoring with min/max/average tracking
- Enhanced Tooltips: Detailed breakdowns for guild members by zone, addon performance, etc.

### Intelligent Button Collection
- Automatically collects addon buttons into a clean bar
- Supports LibDBIcon buttons
- Optional Blizzard button inclusion
- Hide bar with minimap hover functionality
- Smart positioning left or right of minimap

## Customization Options
- Individual font sizes for each data bar (8-20px)
- Full Opacity Range: Complete transparency support (0-100%)
- Flexible data text positioning (hide, minimap, first bar, second bar)
- Lock/unlock movable bars
- Smart Color Coding: Guild (green), Friends (cyan), performance indicators
- Faction-Aware Tooltips: Guild members color-coded by Alliance/Horde

## Installation
- Download the latest release
- Extract to World of Warcraft\_retail_\Interface\AddOns\
- Restart WoW or reload UI (/reload)
- Configure via /minimapredux or Interface > AddOns > MiniMapRedux

## Commands
- /mmr - Open configuration
- /reload - Reload UI if needed

## Data Text Features

### System & Performance
- **Memory**: Real-time addon memory/CPU usage with detailed performance breakdown
- **FPS/Performance**: Color-coded performance indicator (Green ≥60, Yellow 30-59, Red <30)
- **Session**: Playtime, XP/gold gains, and rates per hour
- **Performance**: Current FPS/latency with session statistics and performance tips

### World & Location
- **Coordinates**: Current player position with zone information
- **Clock**: Local time with server time in tooltip, click to open calendar
- **Calendar**: Shows pending events/invites count, or current date. Tooltip lists today's events colored by type. Click opens Calendar.
- **Speed**: Live movement speed percentage. Green when buffed above 100%. Click opens character panel. Added "Speed:" label prefix for clarity.

### Character Information
- **Durability**: Gear condition with color coding (Green ≥75%, Yellow 25-74%, Red <25%). Shows lowest item durability when significantly lower than average: `Dur: 85% (Low: 12%)`. Colors based on worst piece.
- **Gold**: Formatted currency display with session tracking
- **Experience**: Shows level, XP%, and rested XP on bar: `Lv72 XP: 45% R: 30%` (rested in blue). At max level shows `Lv80 Max`.
- **Bags**: Bag space usage with per-bag breakdown
- **Talents**: Unspent talent point notifications
- **Item Level**: Shows overall ilvl when higher than equipped: `iLvl: 528.5 (535.2)`. Added "iLvl:" label prefix.
- **Loot Spec**: Current loot specialization, role-colored. Shows `*` when locked to a non-active spec. Click cycles through specs.

### Social
- **Guild**: Online member count only (green), with enhanced tooltip showing members by zone
- **Friends**: WoW online friends count (cyan), with Battle.net details in tooltip. Shows BNet online count alongside WoW count: `Friends: 3 WoW | 7 BNet`.
- **Mail**: Unread mail indicator (display only, unclickable). Shows first sender name and count: `Mail: PlayerName +2` instead of just "Mail: New".

### Factions & Reputation
- **Reputation**: Watched faction progress
- **Currency**: Various game currencies (Honor, Flightstones, etc.)
- **Renown**: Shows lowest renown faction and level, or "All Maxed". Tooltip lists all major factions with progress.

### Dungeons & PvP
- **Keystone**: Current M+ keystone level & dungeon name, color-coded by difficulty. Shows M+ rating. Tooltip shows weekly best, rating, and current affixes. Click opens Group Finder. Appends M+ rating in gold: `+12 Ara-Kara (2450)`. Shows rating even without a key.
- **Great Vault**: Progress breakdown by category (R0 M2 P1). Shows "READY!" when rewards available. Tooltip shows per-threshold details. Click opens Great Vault. Shows per-category breakdown: `Vault: R2 M3 P0` instead of just total count.
- **PvP Rating**: Highest rated bracket and rating, color-coded by rank (Combatant through Gladiator). Tooltip shows all brackets with win/loss records.
- **Lockouts**: Instance lockout count with raid/dungeon breakdown (e.g., "2R 1D"). Tooltip shows full details with boss progress and reset timers. Shows raid vs dungeon breakdown: `Lockouts: 2R 1D`.
- **Delves**: Companion name and level, or key count. Tooltip shows delve currencies.

### System & Misc
- **Quests**: Active quest count vs max (e.g., "Quests: 22/35"). Turns red when nearly full. Tooltip lists tracked quests with completion status.
- **Professions**: Primary profession names and skill levels. Tooltip shows all professions with progress percentages.
- **Played**: Total time played (e.g., "45d 12h"). Tooltip shows total and current level breakdown. Suppresses /played chat spam.
- **WoW Token**: Current token market price, auto-refreshes every 5 minutes. Click opens Shop.
- **Repair Cost**: Estimated repair cost, color-coded by affordability (green/yellow/red). Tooltip shows per-slot durability breakdown.
- **Volume**: Master volume percentage with mute toggle on click. Tooltip shows all volume channels.

## Recent Updates
- Enhanced data texts: Guild shows online only, Friends shows WoW only
- Session tracking: XP/gold gains, performance history, playtime stats
- Full opacity range: Transparency from 0-100% (was 10-100%)
- Smart tooltips: Zone grouping for guild, game grouping for friends
- Performance monitoring: FPS/latency history with assessments
- Publication-ready: Professional code cleanup and optimization
- Simplified interface: Clean single-column layout for better usability
- Perfect minimap alignment: Data bar scaling matches minimap perfectly
- Added 14 new data texts: Keystone, Great Vault, Speed, WoW Token, Repair Cost, Quests, Professions, PvP Rating, Lockouts, Delves, Renown, Played, Calendar, Volume, Loot Spec
