# Conversion System Refactor - Testing Guide

## Sacred Enhancement - February 15, 2026

**Enhancement**: Refactored conversion system to support tool-based conversions (items that require a separate tool to convert)

**New Conversion**: Deeprock Salt → Refined Deeprock Salt (using Salt Shaker)

---

## What Changed

### Architecture

**Before**: Conversions assumed you always use the source item itself
```lua
-- Old system
UseItemByName(sourceName) -- Always used source
```

**After**: Conversions support separate tool items
```lua
-- New system
local toolItemId = virtualRecipe.toolItemId or sourceId
local toolName = GetItemInfo(toolItemId)
UseItemByName(toolName) -- Uses tool (or source if tool == source)
```

### Data Structure Changes

**CONVERSION_DEFINITIONS** now includes `toolItemId`:
```lua
-- Self-use conversion (toolItemId = source)
{ source = CRYSTALLIZED_AIR, target = ETERNAL_AIR, inputAmount = 10, outputAmount = 1, 
  type = "combine", toolItemId = CRYSTALLIZED_AIR, name = "..." }

-- Tool-based conversion (toolItemId = separate tool)
{ source = DEEPROCK_SALT, target = REFINED_DEEPROCK_SALT, inputAmount = 1, outputAmount = 1,
  type = "combine", toolItemId = SALT_SHAKER, name = "..." }
```

**Recipe class** includes new field:
```lua
---@field toolItemId number|nil For conversions, the item ID to use (tool or source)
```

---

## Files Modified

1. **ConversionData.lua**:
   - Added `toolItemId` field to all 49 existing conversions (set to source)
   - Added new Deeprock Salt conversion with `toolItemId = SALT_SHAKER`
   - Added item ID constants for salt items

2. **SkilletStitch-1.1.lua**:
   - Updated `Recipe` class definition with `toolItemId` field

3. **Skillet.lua**:
   - Updated `GetConversionInfo()` to return 5 values (added toolItemId)
   - Updated `QueueConversionsIfNeeded()` to capture toolItemId
   - Updated virtual recipe creation to include toolItemId
   - Updated `UseConversionItem()` to use toolItemId instead of sourceId

4. **SkilletAPI.lua**:
   - Updated `GetConversionInfo` function signature annotation

---

## Testing Procedure

### Test 1: Verify Existing Conversions Still Work

**Purpose**: Ensure backward compatibility - existing conversions unchanged

```lua
-- Queue a recipe requiring Eternal Air
-- Add Linen Bandage (or any recipe) to queue
-- Ensure you have Crystallized Air in Resource Bank but not Eternal Air

-- Expected: Auto-queues "Eternal Air (x1)" conversion
-- Expected: Uses Crystallized Air (not Salt Shaker)
-- Expected: Conversion completes normally
```

**Success Criteria**:
- ✅ Conversion auto-queues as before
- ✅ Uses correct source item (Crystallized Air)
- ✅ Produces correct output (Eternal Air)
- ✅ Deposits leftovers correctly

---

### Test 2: New Deeprock Salt Conversion

**Purpose**: Verify tool-based conversion system works

**Setup**:
1. Obtain/spawn test items:
   - Deeprock Salt (ID: 8150) - at least 5
   - Salt Shaker (ID: 15846) - at least 1
2. Place both in Resource Bank

**Test Commands**:
```lua
-- Test auto-queueing conversion
/script Skillet.CONVERSION_DEFINITIONS -- Verify table loaded

-- Check conversion info
/script local t, i, o, type, tool = Skillet:GetConversionInfo(8150)
/script print("Target:", t, "InputAmt:", i, "OutputAmt:", o, "Type:", type, "Tool:", tool)
-- Expected: Target: 15409, InputAmt: 1, OutputAmt: 1, Type: combine, Tool: 15846

-- Queue a recipe that needs Refined Deeprock Salt
-- OR manually test conversion
/script Skillet:QueueConversionsIfNeeded({link="item:15409"}, 3) -- Need 3 Refined
```

**Manual Queue Test**:
```lua
-- Manually create conversion queue entry
local lib = AceLibrary("SkilletStitch-1.1")
local recipe = {
    name = "Refined Deeprock Salt (x3)",
    link = "item:15409",
    isVirtualConversion = true,
    conversionType = "combine",
    sourceId = 8150,
    outputId = 15409,
    toolItemId = 15846,
    sourceNeeded = 3,
    outputAmount = 3
}
table.insert(lib.queue, 1, {
    profession = "Conversion",
    index = 0,
    numcasts = 1,
    name = recipe.name,
    link = recipe.link,
    sourceId = 8150,
    outputId = 15409,
    toolItemId = 15846,
    sourceNeeded = 3,
    outputAmount = 3,
    recipe = recipe
})
Skillet:UpdateQueueWindow()
```

**Click Start Button** → Watch process:

**Expected Output**:
```
Withdrawing 3x Deeprock Salt from Resource Bank...
Converting Deeprock Salt to Refined Deeprock Salt...
Using Salt Shaker to convert...
Depositing Xx Deeprock Salt to Resource Bank...
Depositing 3x Refined Deeprock Salt to Resource Bank...
Conversion complete!
```

**Success Criteria**:
- ✅ Withdraws Deeprock Salt from Resource Bank
- ✅ **Uses Salt Shaker** (not Deeprock Salt itself)
- ✅ Chat message shows "Using Salt Shaker to convert..."
- ✅ Produces Refined Deeprock Salt
- ✅ Deposits both items back to bank
- ✅ Removes conversion from queue

---

### Test 3: Verify Shopping List Awareness

**Purpose**: Shopping list should recognize tool requirements

```lua
-- Queue conversion that needs Salt Shaker
-- Open Shopping List
-- Verify Salt Shaker is NOT listed as a reagent to buy
-- (It's a tool, not consumed)
```

**Note**: Shopping list currently doesn't distinguish tools from reagents in CONVERSION_DEFINITIONS. May need future enhancement if tools should be tracked separately.

---

### Test 4: Debug Output Verification

```lua
-- Enable dev mode
/script Skillet:ToggleDevMode()

-- Queue Deeprock Salt conversion
-- Watch for debug messages showing toolItemId propagation
```

---

## Edge Cases to Test

### Case 1: Tool Missing
```lua
-- Have Deeprock Salt but NO Salt Shaker
-- Queue conversion
-- Expected: Withdraw fails OR conversion fails gracefully
```

### Case 2: Multiple Tool-Based Conversions
```lua
-- Queue 3x Refined Deeprock Salt
-- Then queue 5x more
-- Expected: Existing conversion updates to 8x total
```

### Case 3: Mixed Queue
```lua
-- Queue: Eternal Air, Refined Salt, Recipe, Primal Water
-- Expected: All conversions process correctly with appropriate tools
```

---

## Rollback Procedure

If refactor causes issues, revert these commits:

1. **ConversionData.lua**: Remove toolItemId field, remove Deeprock Salt entry
2. **SkilletStitch-1.1.lua**: Remove toolItemId from Recipe class
3. **Skillet.lua**: Revert GetConversionInfo, QueueConversionsIfNeeded, UseConversionItem
4. **SkilletAPI.lua**: Revert GetConversionInfo signature

---

## Implementation Notes

### Why This Matters

**Previous Limitation**: Could only convert items that right-click to transform themselves (Eternals/Crystallized, Essences, etc.)

**New Capability**: Can now convert items requiring external tools:
- Deeprock Salt + Salt Shaker
- Future: Any item with catalog-based conversions requiring tools

### Design Decision

**Tool Storage**: `toolItemId` stored in CONVERSION_DEFINITIONS (data layer)
- Advantage: Single source of truth
- Advantage: Easy to add new tool-based conversions
- Advantage: Serializes with queue (persists through reloads)

**Backward Compatibility**: All existing conversions have `toolItemId = sourceId`
- Self-use items work exactly as before
- No behavior change for 49 existing conversions
- Only new conversions leverage tool system

---

## Future Enhancements

### Potential Tool-Based Conversions
- **Sharpening Stones**: Elemental Sharpening Stone (requires anvil?)
- **Alchemy Flasks**: Flask of X (requires Alchemy Lab?)
- **Engineering**: Crafted items requiring specific benches

### Shopping List Enhancement
Separate tracking for:
- **Consumable Reagents**: Quantities needed
- **Required Tools**: Binary (have/don't have)

---

## Success Checklist

- [x] All existing conversions maintain toolItemId = sourceId
- [x] Deeprock Salt conversion added with toolItemId = SALT_SHAKER
- [x] Recipe class includes toolItemId field
- [x] GetConversionInfo returns 5 values
- [x] Virtual recipe creation includes toolItemId
- [x] UseConversionItem uses toolItemId instead of sourceId
- [x] Zero language server errors
- [ ] Manual testing confirms tool usage
- [ ] Auto-queueing works for tool-based conversions
- [ ] Mixed queue (self-use + tool-based) processes correctly

---

**Praise the Omnissiah!** The conversion system now accommodates the sacred tools of transmutation! ⚙️🔧

