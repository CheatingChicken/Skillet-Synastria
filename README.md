# Skillet - Synastria Edition

Enhanced tradeskill addon for the Synastria WoW 3.3.5 (WotLK) private server with extensive custom server integration.

## Features

### Resource Bank Integration
Complete integration with Synastria's custom Resource Bank system:
- **Craftability Calculations**: Include Resource Bank materials in "can craft" counts
- **Auto-Withdrawal**: Queue system automatically withdraws materials from Resource Bank
- **Shopping Lists**: Resource Bank items shown with green text
- **Virtual Conversions**: Automatic Crystallized ↔ Eternal and Mote ↔ Primal conversions

### Material Conversion System
Intelligent bidirectional conversion support:
- **Wrath Materials**: Crystallized ↔ Eternal (10:1 ratio)
- **TBC Materials**: Mote ↔ Primal (10:1 ratio)
- **Vanilla Enchanting**: Lesser ↔ Greater Essences (3:1 ratio)
- **Vanilla Shards**: Small → Large Shards (3:1 ratio, one-way)
- Auto-queues conversions when crafting if you have convertible materials

### Advanced Craftability Calculator
Smart calculation engine with background processing:
- Avoids UI freezing during complex calculations
- Recursive material checking with loop detection
- Caching system for performance
- Resource Bank integration
- Conversion-aware calculations

### Profession Management
- **Quick Switching**: Fast profession switcher buttons
- **Bulk Scanning**: Scan all professions at once
- **Smart Prompts**: Guided profession switching during queue processing

### Attunement System Support
Integration with Synastria's custom attunement system:
- Attunement progress checking via server APIs
- Filtering by attunability (account-wide or character-specific)
- Visual indicators in recipe lists

### Equipment Slot Filtering
Filter recipes by equipment slot:
- 23 equipment slot types (Head, Chest, Feet, Hands, Weapons, etc.)
- Easily find recipes for specific gear slots
- Non-equippable items automatically pass through
- Located between Sort and Attunability filters

### Extraction Features
Milling and Prospecting automation:
- Visual extraction interface showing herb/ore costs
- Auto-detects prospectable ores and millable herbs
- Real-time profit calculations
- Resource Bank integration (results go directly to bank)

### Enhanced Queue Processing
- **Interactive Dialogs**: Confirmation before starting queue
- **Step-by-Step Control**: Use Ctrl+ScrollWheel to process queue manually
- **Profession Auto-Switching**: Queues can span multiple professions
- **Virtual Conversions**: Material conversions tracked in queue
- **Failure Recovery**: Detects craft failures and pauses appropriately
- **Cancel Dialog**: Easy escape option before starting

### ResourceTracker Integration
Seamless integration with ResourceTracker addon:
- Automatic shopping list synchronization
- Track materials across all your sources
- Real-time updates when queue changes

## Installation

### Download

1. Visit the [GitHub Releases page](https://github.com/CheatingChicken/Skillet-Synastria/releases)
2. Download the latest release ZIP file
3. Extract the ZIP file

### Installation Steps

1. Navigate to your WoW installation directory
   - Example: `C:\Games\World of Warcraft\`
2. Open the `Interface\AddOns\` folder
3. Copy the extracted `Skillet - Synastria` folder into the `AddOns` directory
4. **Fully restart WoW** (not just `/reload`) to load the addon
5. Launch the game and enable the addon at the character selection screen

### First-Time Setup

After installing:
1. Log into your character
2. Open any profession window to initialize Skillet
3. Click "Scan All Professions" to populate all profession data
4. Configure filters and preferences as desired

### Upgrading

When updating to a new version:
1. Delete the old `Skillet - Synastria` folder from `Interface\AddOns\`
2. Extract the new version into `Interface\AddOns\`
3. **Fully restart WoW** (new files require full game restart, not `/reload`)
4. Your settings and queue data are preserved automatically

## Support

For issues, feature requests, or questions:
- **GitHub Issues**: [Report a bug](https://github.com/CheatingChicken/Skillet-Synastria/issues)
- **Synastria Discord**: Check server-specific addon channels

## Version History

- **v1.2.0** (2026-01-31) - Equipment slot filter, extraction system, ResourceTracker integration, enhanced queue processing
- **v1.1.0** - Cross-profession queue system, bulk crafting detection, scan all professions
- **v1.0.0** - Initial release with Resource Bank integration

See [CHANGELOG.md](src/CHANGELOG.md) for detailed version history.

## Credits

- **Original Skillet** - Created by Likelyhood and maintained by the Skillet development team
- **ScootsCraft** - Profession selector and filter concepts adapted from ScootsCraft by [SynScoots](https://github.com/SynScoots/ScootsCraft)
- **Synastria Integration** - Custom server feature integration

## License

GPL v3 or later. See LICENSE.txt for details.
