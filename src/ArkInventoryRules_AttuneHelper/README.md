# ArkInventoryRules_AttuneHelper

*By the grace of the Omnissiah, this addon bridges the sacred AHSetList with ArkInventory's rule system.*

## Description

This addon provides the `ahset()` rule for ArkInventory, allowing you to filter and categorize items that are in your AttuneHelper equipment set.

## Requirements

- **ArkInventory** (with ArkInventoryRules)
- **AttuneHelper**

## Installation

Simply place this addon folder in your `Interface/AddOns` directory alongside the required dependencies.

## Usage

### Basic Rule: `ahset()`

Matches any item that is in your AttuneHelper equipment set (AHSetList).

**Example:**
```
ahset()
```
This will match all items that have been added to your AHSet via the `/ahset` command.

### Slot-Specific Rule: `ahset("SlotName")`

Matches items in your AHSet that are designated for a specific equipment slot.

**Examples:**
```
ahset("MainHandSlot")     -- Matches AHSet items for main hand
ahset("SecondaryHandSlot") -- Matches AHSet items for off-hand
ahset("HeadSlot")          -- Matches AHSet items for head slot
```

**Valid Slot Names:**
- `HeadSlot`
- `NeckSlot`
- `ShoulderSlot`
- `BackSlot`
- `ChestSlot`
- `WristSlot`
- `HandsSlot`
- `WaistSlot`
- `LegsSlot`
- `FeetSlot`
- `Finger0Slot` / `Finger1Slot`
- `Trinket0Slot` / `Trinket1Slot`
- `MainHandSlot`
- `SecondaryHandSlot`
- `RangedSlot`

## How It Works

The addon reads from the `AHSetList` saved variable that AttuneHelper maintains. When you add items to your equipment set using `/ahset`, they become available for filtering through this rule.

## Example ArkInventory Rules

**Separate your AHSet items into a dedicated category:**
```
ahset()
```

**Organize by slot:**
```
ahset("MainHandSlot") or ahset("SecondaryHandSlot")
```

**Combine with other rules:**
```
ahset() and mythic()
ahset() and attuned()
```

## Support

This addon integrates seamlessly with:
- **AttuneHelper**: For managing your equipment sets
- **ArkInventoryRules_Scoots**: Can be used alongside other custom rules

## Additional Commands

This addon also provides convenient commands for managing your AHSetList:

### `/ahsetclear` - Clear AHSet with Confirmation

Clears all items from your AHSetList after showing a confirmation dialog.

**Usage:**
```
/ahsetclear
```

**Features:**
- Shows count of items before clearing
- Confirmation dialog prevents accidental clears
- Works independently of AttuneHelper
- Safe to use - won't break anything if AHSetList doesn't exist

### `/ahsetequipall` - Disable Auto-Equip and Equip AHSet Items

Disables AttuneHelper's auto-equip feature and immediately equips all items from your AHSetList.

**Usage:**
```
/ahsetequipall
```

**Features:**
- Disables "Auto Equip Attunable After Combat" (same as `/ahtoggle`)
- Checks if items are already equipped in the correct slot
- Searches your bags for each item in AHSetList
- Equips items to their designated slots
- Reports status for each item (equipped/already equipped/not found)
- Shows detailed summary with three categories

**Example Output:**
```
[ArkInventoryRules_AttuneHelper] Auto-equip disabled.
[ArkInventoryRules_AttuneHelper] Already equipped: Dragonsteel Faceplate
[ArkInventoryRules_AttuneHelper] Equipped: Terokk's Nightmace to MainHandSlot
[ArkInventoryRules_AttuneHelper] Not found in bags: Valorous Redemption Gloves
[ArkInventoryRules_AttuneHelper] === Summary ===
[ArkInventoryRules_AttuneHelper] Newly equipped: 14
[ArkInventoryRules_AttuneHelper] Already equipped: 1
[ArkInventoryRules_AttuneHelper] Not found: 2
```

**Use Cases:**
- Quickly swap to your fallback gear set
- Prepare for activities where you don't want auto-equip
- Ensure your baseline gear is equipped before starting a new attuning session

**Note:** Items must be in your bags (not bank) to be equipped. Already-equipped items won't cause errors.

**Note:** These commands are provided by ArkInventoryRules_AttuneHelper for convenience. You don't need to modify AttuneHelper to use them.

## Version History

**1.0** - Initial release
- Added `ahset()` rule for filtering AHSetList items
- Support for slot-specific filtering

---

*Praise the Omnissiah! May your inventories be well-organized and your gear sets optimized.*
