# Phase 1 Test Results - API Limitations Discovered

## Server Confirmation
**Source:** Server owner post
**Status:** Custom_GetProfessionRecipes returns INCOMPLETE data
**Reason:** Awaiting client update
**Coverage:** ~60% of recipes (e.g., 158 out of 261 for Blacksmithing)

---

## What's Missing from API

### Blacksmithing Missing Categories (103 recipes):
- Sharpening Stones (temporary weapon enhancements)
- Weightstones (temporary weapon enhancements)
- Skeleton Keys (lockpicking items)
- Weapon Chains (weapon enhancements)
- Armor Kits / Plating (armor enhancements)
- Socket enhancements
- Various crafted weapons

### Pattern Observed:
The API appears to prioritize **permanent equippable items** and exclude:
- Temporary enhancements
- Utility/consumable items
- Non-equippable profession items

---

## APIs That WORK Fully

✅ **Custom_GetProfessionRecipeInfo(spellId)**
- Returns complete recipe information
- Works for ANY valid spell ID
- 0.01ms performance

✅ **Custom_GetProfessionRecipeReagents(spellId)**
- Returns reagent requirements
- Works perfectly for shopping lists

✅ **Custom_GetProfessionRecipeFromCraftedItem(itemId)**
- Reverse lookup: item → spell ID
- Useful for queue processing

✅ **Custom_GetProfessionRecipeAttunement(spellId)**
- Returns forge level requirements
- Works for attunement checking

✅ **Custom_DoProfessionRecipe(spellId, count)** *(untested)*
- Spell-based crafting
- To be tested in Phase 2

---

## Revised Implementation Strategy

### ❌ CANNOT Implement (blocked by incomplete API):
1. **Cross-Profession Recipe Scanning** - Missing 40% of recipes
2. **Complete Recipe Database** - Data incomplete
3. **Global Recipe Search UI** - Would show incomplete results

### ✅ CAN Implement (using working APIs):
1. **Enhanced Shopping Lists** - Use Custom_GetProfessionRecipeReagents
2. **Spell-Based Crafting** - Use Custom_DoProfessionRecipe
3. **Attunement Integration** - Use Custom_GetProfessionRecipeAttunement
4. **Queue Optimization** - Use recipe info APIs
5. **Reverse Item Lookup** - Use Custom_GetProfessionRecipeFromCraftedItem

### 🔄 HYBRID Approach (window + API):
1. **Scan recipes from window** (traditional method - complete data)
2. **Enhance with API data** (reagents, attunement, spell IDs)
3. **Use spell-based crafting** for queue processing
4. **Store spell IDs** for future API-based operations

---

## Updated Roadmap

### Priority 1: Test Working APIs (Phase 2+)
1. **Test Custom_DoProfessionRecipe** ⭐ CRITICAL
   - Does it craft without window?
   - Does it bypass cooldowns?
   - Event handling?

2. **Test Custom_GetProfessionRecipeReagents**
   - Shopping list generation
   - Cross-profession material aggregation

3. **Test Custom_GetProfessionRecipeAttunement**
   - Forge level filtering
   - Queue validation

### Priority 2: Implement Window-Based Features
1. **Traditional recipe scanning** (keep existing system)
2. **Enhance scanned data** with API calls
3. **Store spell IDs** for each recipe
4. **Convert queue to spell-based** processing

### Priority 3: Wait for Server Update
1. Monitor for API completion announcement
2. Retest Custom_GetProfessionRecipes when updated
3. Implement cross-profession features THEN

---

## Lessons Learned

### What Worked:
- API performance is EXCEPTIONAL (0.70ms!)
- Individual recipe lookups work perfectly
- Spell ID system is reliable
- Server architecture is solid

### What Doesn't Work YET:
- Bulk recipe retrieval is incomplete
- ~40% of recipes missing from API
- Cannot rely on it for complete data

### Best Path Forward:
1. Use **window-based scanning** for discovery (complete)
2. Use **API calls** for individual recipe operations (fast)
3. Combine both for optimal performance
4. Revisit when server updates API

---

## Next Testing Session

**Focus:** Phase 2 - Spell-Based Crafting

**Commands to Test:**
```lua
-- Open a tradeskill window first
/script Skillet:TestServerSideBehavior(INDEX)
/script Skillet:MonitorCraftCalls(true)
-- Try crafting via API
/script Custom_DoProfessionRecipe(SPELLID, 1)
```

**Questions to Answer:**
1. Does Custom_DoProfessionRecipe work?
2. Does it bypass cooldowns?
3. Does it trigger craft events?
4. Can we queue without windows?

This will determine if we can implement the **spell-based queue processing** system!
