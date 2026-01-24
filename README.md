# Skillet - Synastria Edition

A fork of Skillet for the Synastria WoW 3.3.5 (WotLK) private server, featuring integration with custom server features.

## Features

### Core Skillet Features
- Clean, efficient tradeskill window replacement
- Queue system for batch crafting
- Shopping list generation
- Inventory and bank tracking
- Recipe filtering and sorting

### Synastria Integration

#### Resource Bank Support
Full integration with Synastria's Resource Bank system:
- Craftability counts include Resource Bank materials
- Shopping lists account for Resource Bank items
- Queue prerequisites check Resource Bank availability
- Green-colored count display for items available in Resource Bank

#### Profession Selector
Quick-switch profession buttons (adapted from ScootsCraft):
- Fast profession switching without opening spellbook
- Visual highlighting of active profession
- Supports all 12 primary professions

#### Advanced Equipment Filtering
Powerful filtering options for crafted equipment:

**Attunability Filters:**
- **All Equipment** - Show all craftable items
- **Attuneable (Acc)** - Show only equipment attuneable by any character on your account
- **Attuneable (Char)** - Show only equipment attuneable by the current character

**Forge Level Filters:**
- **All Forge Levels** - No forge filtering
- **Unattuned** - Show only unattuned equipment
- **<= Baseline** - Show equipment up to Baseline forge level
- **<= Titanforged** - Show equipment up to Titanforged
- **<= Warforged** - Show equipment up to Warforged
- **<= Lightforged** - Show equipment up to Lightforged

**Equipment Only Toggle:**
- Filter to show only equippable items (weapons, armor, trinkets, etc.)

## Installation

1. Download or clone this repository
2. Copy the `Skillet - Synastria` folder from the `src` directory to your WoW `Interface\AddOns\` folder
3. Restart WoW or type `/reload` in-game

## Credits

- **Original Skillet** - Created by Likelyhood and maintained by the Skillet development team
- **ScootsCraft** - Profession selector and filter concepts adapted from ScootsCraft
- **Synastria Integration** - Custom server feature integration

## License

This addon is based on Skillet, which is licensed under the GNU General Public License v3.0.

## Support

For issues specific to the Synastria server integration, please report them via the repository's issue tracker.

For general Skillet issues, please refer to the original Skillet project.
