# Bugfix: Double Reagent Queueing (Complete Refactor)

**Date**: February 14, 2026  
**Issue**: Reagents were being double-queued in multiple scenarios:
1. When queueing a recipe that already exists in the queue
2. When queueing different recipes that share common reagents

## Root Cause

The original queue snapshot calculation had fundamental architectural flaws:
1. **Complex exclusion logic**: Tried to exclude the current recipe's consumption from a snapshot
2. **Inconsistent API usage**: Mixed Custom API and recipe object access
3. **Missing production tracking**: Only tracked consumption, not what queue would produce
4. **Cross-recipe contamination**: Snapshot calculation could affect wrong recipes

Example of the bug:
- Queue Moonsteel Broadsword (needs 4 Iron Bars) → Queues Smelt Iron x4
- Queue Massive Iron Axe (needs 14 Iron Bars) → Should queue Smelt Iron x10 more
- **BUG**: Instead incremented Heavy Leather by 14!

## The Solution: Simplified Architecture

**Complete refactor** following the principle: *"Let each component do ONE thing well."*

### New Flow
1. **Calculate needs for THIS craft only** (simple multiplication)
2. **Calculate what we have** (inventory + resource bank)
3. **Calculate what queue will PRODUCE** (new function)
4. **Calculate shortage** = need - have - queueProduction
5. **Queue each subreagent individually**
6. **Let AddToQueue handle merging** (existing deduplication logic)

### Key Changes

#### 1. New Function: GetQueuedItemProduction()
**File**: `Skillet.lua` (after GetQueuedReagentConsumption)

Calculates how many of an item the queue will **produce**, not consume. Critical for preventing double-queuing.

```lua
function Skillet:GetQueuedItemProduction(itemId)
    -- Uses Custom_GetProfessionRecipeInfo to find crafted item IDs
    -- Sums up (craftedItemCount * numCasts) for all matching queue entries
    -- Returns total that will be produced
end
```

#### 2. Simplified add_items_to_queue()
**File**: `SkilletQueue.lua` (lines 83-125)

**BEFORE (buggy)**:
```lua
-- Complex snapshot with exclusions (60+ lines)
local existingEntry = <find in queue>
local queueSnapshot = {}
for each reagent:
    totalConsumption = GetQueuedReagentConsumption(itemId)
    thisRecipeConsumption = <calculate from existingEntry.recipe>
    queueSnapshot[itemId] = totalConsumption - thisRecipeConsumption
-- Then use snapshot in shortage calculation
shortage = needed - have + queueSnapshot[itemId]
```

**AFTER (clean)**:
```lua
-- Simple production-based calculation (15 lines)
for each reagent:
    needed = reagent.needed * count
    have = inventory + resource_bank
    queueProduction = GetQueuedItemProduction(itemId)
    shortage = max(0, needed - have - queueProduction)
    if shortage > 0:
        queue subreagent with shortage amount
```

### Why This Works

**Scenario 1: Same Recipe Twice**
- Queue Steel Bar x1 (needs 1 Iron Bar)
  - need=1, have=0, queueProd=0 → shortage=1
  - Queue Smelt Iron x1 → queueProd becomes 1
- Queue Steel Bar x1 again
  - need=1, have=0, queueProd=1 → shortage=0
  - ✅ No additional Iron Bar queued (correct!)

**Scenario 2: Different Recipes, Shared Reagents**
- Queue Moonsteel Broadsword (needs 4 Iron Bar)
  - need=4, have=0, queueProd=0 → shortage=4
  - Queue Smelt Iron x4 → queueProd becomes 4
- Queue Massive Iron Axe (needs 14 Iron Bar)
  - need=14, have=0, queueProd=4 → shortage=10
  - Queue Smelt Iron x10 more → AddToQueue merges to 14 total
  - ✅ Correct! No contamination of Heavy Leather!

## Impact

**Files Changed**:
- `Skillet.lua`: Added GetQueuedItemProduction()
- `SkilletQueue.lua`: Complete refactor of add_items_to_queue()
- `SkilletAPI.lua`: Added type definition for GetQueuedItemProduction

**Lines of Code**:
- Removed: ~60 lines of complex snapshot logic
- Added: ~45 lines (new function + simplified logic)
- Net: Cleaner, more maintainable

**Benefits**:
- ✅ Fixes both double-queuing scenarios  
- ✅ Simpler, more maintainable logic  
- ✅ Separation of concerns  
- ✅ No cross-recipe contamination  

## Testing Scenarios

### Test Case 1: Same Recipe Twice
**Action**: Queue Steel Bar x1 → Queue Steel Bar x1 again

**Expected Debug Output**:
```
[Queue Check] Iron Bar: have 0, queueProd 0, need 1, shortage 1
[QUEUED] Smelt Iron x1
-- Second queue:
[QueueProduce] Iron Bar: 1 will be produced
[Queue Check] Iron Bar: have 0, queueProd 1, need 1, shortage 0
```
✅ No additional Iron Bar queued (queueProduction prevents it)

### Test Case 2: Different Recipes, Shared Reagents  
**Action**: Queue Moonsteel Broadsword x1 → Queue Massive Iron Axe x1

**Expected Debug Output**:
```
-- First: Moonsteel (needs 4 Iron Bar)
[Queue Check] Iron Bar: have 0, queueProd 0, need 4, shortage 4
[QUEUED] Smelt Iron x4

-- Second: Massive Axe (needs 14 Iron Bar)
[QueueProduce] Iron Bar: 4 will be produced
[Queue Check] Iron Bar: have 0, queueProd 4, need 14, shortage 10
[QUEUED] Smelt Iron x10
[AddToQueue] Increased existing queue entry to 14 casts
```
✅ Correctly queues 10 more (total 14)  
✅ Heavy Leather NOT affected

### Test Commands
```lua
-- Enable debug logging
/script Skillet:SetDevMode(true)

-- Clear and test
/script Skillet.stitch:ClearQueue(); Skillet:Print("Queue cleared")

-- Check production for an item
/script local prod = Skillet:GetQueuedItemProduction(3575); Skillet:Print("Iron Bar production: " .. prod)
```

## Related Issues

This bug "resurfaced" multiple times because the original approach was fundamentally flawed. This refactor addresses the root architectural issue, not just symptoms.

---

*By the Omnissiah's grace, the Machine Spirit is appeased through simplicity and clarity.*
