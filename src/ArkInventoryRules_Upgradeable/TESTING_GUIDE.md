# ArkInventory Rules Testing Guide

## Overview
The ArkInventory Rules addons now include a comprehensive testing command that allows you to test all three rule functions against a specific item.

## Testing Command

### Syntax
```
/aiu test <itemId>
/aiu test [itemlink]
```

### Parameters
- **itemId**: Numeric item ID (e.g., `2944`, `28428`)
- **itemlink**: Full WoW item link (e.g., `|cffffffff|Hitem:2944:0:0:0:0:0:0:0:0:0:0:0:0|h[Cursed Eye of Paleth]|h|r`)

## Examples

### Test by Item ID
```
/aiu test 2944
```

### Test by Item Link
Copy an item link from chat or your inventory and paste it:
```
/aiu test |cffffffff|Hitem:2944:0:0:0:0:0:0:0:0:0:0:0:0|h[Cursed Eye of Paleth]|h|r
```

## Output Format

The test command displays results for all three rule functions:

```
========== ArkInventory Rules Test ==========
Item ID: 2944
Item Link: item:2944:0:0:0:0:0:0:0:0:0:0:0:0

[1] upgradeable() rule:
  upgradeable(): TRUE
  upgradeable('char'): TRUE
  upgradeable('acc'): TRUE

[2] ahset() rule:
  ahset(): FALSE
  [N/A] ArkInventoryRules_AttuneHelper not loaded

[3] belowavgilvl() rule:
  belowavgilvl(): FALSE
  [N/A] ArkInventoryRules_ItemLevel not loaded

==========================================
```

### Result Interpretation

- **TRUE**: The item matches the filter criteria
- **FALSE**: The item does not match the filter criteria
- **[N/A]**: The addon providing that rule is not loaded

## Rule Descriptions

### upgradeable() Rule
Checks if an item is upgradeable (has an upgrade path in the database).

**Variants:**
- `upgradeable()` - Matches any upgradeable item
- `upgradeable('char')` - Matches upgradeable items where the final upgrade target can be attuned by the current character
- `upgradeable('acc')` - Matches upgradeable items where the final upgrade target can be attuned by any account member

### ahset() Rule
Checks if an item is in the AttuneHelper's equipment set list (AHSetList).

**Requirements:** ArkInventoryRules_AttuneHelper addon must be loaded.

### belowavgilvl() Rule
Checks if an item's item level is below the average equipped item level.

**Variants:**
- `belowavgilvl()` - Matches items below equipped average
- `belowahsetavgilvl()` - Matches items below the average of AHSet items

**Requirements:** ArkInventoryRules_ItemLevel addon must be loaded.

## Common Use Cases

### Testing Upgrade Detection
```
/aiu test 49888
```
(Tests the Shadow's Edge → Shadowmourne upgrade chain)

### Testing Attunable Upgrades
```
/aiu test 50375
```
(Tests the Ashen Band upgrade chain with attunement requirements)

### Testing Item Level Filtering
```
/aiu test 28428
```
(Tests a crafted item against item level thresholds)

## Troubleshooting

### Command Not Found
- Ensure ArkInventoryRules_Upgradeable addon is loaded
- Try: `/reload` to reload the UI

### [N/A] Results
- The optional rule addons are not loaded
- Load ArkInventoryRules_AttuneHelper for `ahset()` testing
- Load ArkInventoryRules_ItemLevel for `belowavgilvl()` testing

### Invalid Item ID/Link
- Double-check the item ID or link format
- Item links must start with `|c` (color code)
- Numeric IDs must be positive integers

## Database Information

The `upgradeable()` rule uses the **Scoots ID Upgradables** database which includes:
- **380+ upgrade mappings** across all item sources
- **10 data sheets**: Dalaran Rings, Sunmote Gear, Crafting, T10 Gear, T0.5 Gear, Brood of Nozdormu, Ashen Verdict, Questing, and Misc.
- Full upgrade chains (some items have multiple upgrade steps)

Example upgrade chains:
- Ashen Bands (3-step chain): Basic → Greater → Unmatched → Endless
- Shadow's Edge (1-step): Shadow's Edge → Shadowmourne
- Crafted items (multiple steps): Fireguard → Blazeguard → Blazefury
