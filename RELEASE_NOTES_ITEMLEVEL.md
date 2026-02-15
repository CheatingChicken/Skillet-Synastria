Initial release of ArkInventoryRules_ItemLevel addon.

## Features
- Filter items by comparing them to your equipped gear average item level
- Compare items against your AHSet (fallback gear) average
- Advanced threshold filtering with offset parameters
- Automatically identify vendor trash and outdated gear

## Filter Rules
- `belowavgilvl()` - Matches items below your equipped average item level
- `belowavgilvl(X)` - Matches items below (average - X) levels
- `belowahsetavgilvl()` - Matches items below your AHSet average item level
- `belowahsetavgilvl(X)` - Matches items below (AHSet average - X) levels

## Installation
Extract the ArkInventoryRules_ItemLevel folder to your WoW Interface/AddOns directory.

## Requirements
- ArkInventory
- ArkInventoryRules
