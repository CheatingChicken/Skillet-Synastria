# ArkInventoryRules_ItemLevel

*By the grace of the Omnissiah, this addon filters items by comparing them to your equipped gear's average item level.*

## Description

This addon provides the `belowavgilvl()` rule for ArkInventory, allowing you to automatically identify items that are below your current equipped average item level. Perfect for quickly finding vendor trash or outdated gear!

## Requirements

- **ArkInventory** (with ArkInventoryRules)

## Installation

Simply place this addon folder in your `Interface/AddOns` directory alongside the required dependencies.

## Usage

### Basic Rule: `belowavgilvl()`

Matches any item whose item level is below your equipped average.

**Example:**
```
belowavgilvl()
```
This will match all items that have a lower item level than the average of your currently equipped gear.

### Advanced Rule: `belowavgilvl(X)`

Matches items below a threshold adjusted by X levels from your equipped average.

**Examples:**
```
belowavgilvl(0)   -- Same as belowavgilvl(), below average
belowavgilvl(10)  -- Below average by at least 10 levels
belowavgilvl(-5)  -- Below average, but within 5 levels of it
```

### AHSet Comparison Rule: `belowahsetavgilvl()`

Matches any item whose item level is below the average of your **AHSet items** (AttuneHelper fallback gear).

**Example:**
```
belowahsetavgilvl()
```
This will match all items below the average item level of items in your AHSetList.

**Use Cases:**
- Find items that aren't good enough to be fallback gear
- Identify vendor trash relative to your saved equipment set
- Filter upgrades relative to your baseline gear

### Advanced AHSet Rule: `belowahsetavgilvl(X)`

Matches items below a threshold adjusted by X levels from your AHSet average.

**Examples:**
```
belowahsetavgilvl(0)   -- Same as belowahsetavgilvl()
belowahsetavgilvl(10)  -- Below AHSet average by at least 10 levels
belowahsetavgilvl(-5)  -- Within 5 levels below AHSet average
```

**Use Cases:**
- `belowavgilvl(10)` - Only catch items that are significantly outdated (10+ levels below average)
- `belowavgilvl(-10)` - Catch items close to your average (useful for "almost there" gear)

## How It Works

### `belowavgilvl()` - Equipped Gear Average

The addon:
1. Calculates the average item level of ALL your equipped items
2. **Ignores** empty slots, shirts, and tabards
3. Compares each item in your inventory against this average
4. Returns `true` for items below the threshold

### `belowahsetavgilvl()` - AHSet Average

The addon:
1. Calculates the average item level of items in your **AHSetList** (AttuneHelper fallback gear)
2. Only counts items that are currently equipped (to get accurate item levels)
3. Compares each item in your inventory against this average
4. Returns `true` for items below the threshold

**Note:** For `belowahsetavgilvl()` to work, your AHSet items should be equipped or the addon needs access to their item links.

### Slots Considered:
- Head, Neck, Shoulders, Back, Chest
- Wrists, Hands, Waist, Legs, Feet
- Both Rings (Finger0Slot, Finger1Slot)
- Both Trinkets (Trinket0Slot, Trinket1Slot)
- Main Hand, Off-Hand, Ranged

### Slots Excluded:
- **Shirt** (ShirtSlot) - Cosmetic only
- **Tabard** (TabardSlot) - Cosmetic only
- **Empty slots** - Not counted in average

## Example ArkInventory Rules

**Separate low-level items for easy vendoring:**
```
belowavgilvl()
```

**Find items below your AHSet baseline:**
```
belowahsetavgilvl()
```

**Find really outdated gear (relative to equipped):**
```
belowavgilvl(20)
```

**Find items significantly worse than your fallback gear:**
```
belowahsetavgilvl(15)
```

**Combine with quality filters:**
```
belowavgilvl() and q(<=uncommon)
belowahsetavgilvl() and q(<=rare)
```

**Exclude items you want to keep:**
```
belowavgilvl() and not ahset()
```

**Complex vendor rule using both averages:**
```
(belowavgilvl(10) or belowahsetavgilvl(5)) and q(<=rare)
```

**Find upgrade candidates (above AHSet average):**
```
not belowahsetavgilvl() and not ahset()
```

## Technical Notes

- The average is recalculated each time the rule is evaluated
- If you have no equipped items, the rule returns `false`
- The rule uses WoW's `GetItemInfo()` API to retrieve item levels
- Item level is the **base** item level, not affected by enchants or gems

## Practical Examples

**Scenario 1: Your average equipped iLvl is 200**
- An iLvl 190 item → `belowavgilvl()` returns `true`
- An iLvl 205 item → `belowavgilvl()` returns `false`
- An iLvl 180 item → `belowavgilvl(10)` returns `true` (below 190)
- Added `belowahsetavgilvl()` rule for filtering by AHSet average
- An iLvl 196 item → `belowavgilvl(-5)` returns `true` (below 195)

**Scenario 2: Vendor Setup**
Create a rule to auto-vendor items that are:
- Below your average
- Not in your equipment set
- Not heirloom quality

```
belowavgilvl() and not ahset() and not q(heirloom)
```

## Version History

**1.0** - Initial release
- Added `belowavgilvl()` rule for filtering by equipped average
- Support for threshold offset parameter
- Properly excludes shirts, tabards, and empty slots

---

*Praise the Omnissiah! May your inventory be free of obsolete relics.*
