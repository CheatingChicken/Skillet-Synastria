# Skillet - Synastria Edition

A comprehensive fork of Skillet crafting addon specifically designed for the Synastria WoW 3.3.5 private server, with full integration of custom server features.

## 🌟 Synastria-Specific Features

### Resource Bank Integration
Full integration with Synastria's Resource Bank system:
- Automatically includes resource bank materials in craftability calculations
- Shows separate count columns: Inventory → Bank → **Resource Bank** → Alts
- Shopping list includes resource bank materials
- Queue system aware of resource bank availability

### Profession Management
**Scan All Professions** - Quickly scan all your character's professions with one click:
- Located next to the standard Rescan button
- Automatically cycles through all known professions
- Returns to your original profession when complete
- Updates crafting data for all professions

**Profession Selector** - Quick-switch between professions:
- Row of buttons for each profession you know
- Highlights active profession
- One-click profession switching

### Advanced Queue System
**Cross-Profession Queuing**:
- Queue items from multiple professions in a single queue
- Auto-switches professions when needed during crafting
- Shows profession name in green brackets for each queued item: `[Blacksmithing] Titansteel Bar`
- **Group Queue** button - Organizes queue by profession to minimize switches

**Synastria Bulk Crafting Detection**:
- Detects when Synastria server completes multiple crafts at once
- Automatically adjusts queue counts based on actual items crafted
- Prevents queue desync caused by bulk crafting

### Equipment Filtering
**Attunability Filter** - Filter items by attunement status:
- None (show all)
- Character Attuned - Items attuned to this character
- Account Attuned - Items attuned to any character on account

**Forge Level Filter** - Filter by required forge level:
- All levels
- Level -1 through Level 3
- Only shows items matching selected forge level

**Equipment Only Checkbox** - Hide non-equipment items when enabled

## 📝 Standard Skillet Features

All original Skillet functionality remains intact:
- Recipe categorization and search
- Queue multiple items for batch crafting
- Shopping lists for missing materials
- Reagent tracking across characters and bank
- "Hide uncraftable" filter
- Adjustable crafting counts with slider
- And more...

## 🔧 Installation

1. Download the latest release
2. Extract to `World of Warcraft\Interface\AddOns\`
3. Ensure folder is named exactly `Skillet - Synastria`
4. Restart WoW or reload UI (`/reload`)

## 📖 Usage

### Basic Crafting
1. Open any profession window
2. Browse or search for recipes
3. Select item and adjust count (slider or input box)
4. Click **Queue** to add to queue, or **Create** to craft immediately
5. Click **Start** to begin processing the queue

### Cross-Profession Crafting
1. **Optional**: Click **Scan All** to update all profession data
2. Queue items from different professions:
   - Switch to Blacksmithing, queue Titansteel Bars
   - Switch to Engineering, queue Jeeves
   - Switch to Alchemy, queue Flasks
3. **Optional**: Click **Group** to organize queue by profession
4. Click **Start** - addon will auto-switch professions as needed

### Filtering Equipment
1. Use the **Attunability** dropdown to filter by attunement
2. Use the **Forge Level** dropdown to filter by forge requirement
3. Check **Equipment Only** to hide non-equipment items
4. Combine filters for precise searching

## 🐛 Debugging

A hidden debug button is available for troubleshooting filter issues:
- Shows detailed filter information for selected recipe
- Displays item stats, attunability, forge level, and equipment status
- Contact developer if issues persist

## 🔄 Version History

### v1.1.0 - Cross-Profession Queue Update
- Added Scan All Professions button
- Implemented cross-profession queue with auto-switching
- Added profession grouping to minimize switches
- Implemented Synastria bulk crafting detection
- Added profession display in queue items
- Enhanced error handling for profession switching
- Improved queue processing reliability

### v1.0.0 - Initial Synastria Release
- Full Resource Bank integration
- Profession selector UI
- Attunability filtering
- Forge level filtering
- Equipment-only filter
- Debug system
- Initial GitHub release

## 🤝 Credits

- **Original Skillet**: Created by Nephthys and maintained by various contributors
- **Synastria Adaptation**: Modified for Synastria server features
- **ScootsCraft**: Profession selector and filter concepts adapted from ScootsCraft addon

## 📜 License

This is a derivative work based on the original Skillet addon. All modifications for Synastria compatibility are provided as-is for the Synastria community.

## 🔗 Links

- GitHub Repository: https://github.com/CheatingChicken/Skillet-Synastria
- Synastria Discord: [Join for support and updates]

## ⚠️ Known Limitations

- Cross-profession craftability calculations not yet implemented (displays current profession only)
- Profession switching requires waiting for tradeskill window to open (~1.5 seconds per switch)
- Bulk crafting detection relies on inventory comparison (may not detect all edge cases)

## 💡 Tips

- Use **Group** button before starting cross-profession queues to minimize switches
- **Scan All** is useful after logging in to update all profession data
- Queue items in logical groups (all blacksmithing, then all engineering, etc.) for efficiency
- The addon will skip queue items if it can't switch to the required profession after 3 attempts
