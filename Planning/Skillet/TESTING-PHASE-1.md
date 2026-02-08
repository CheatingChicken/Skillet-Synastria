# Testing Phase 1: Cross-Profession Recipe Scanning

## Status: READY TO TEST ✅

## Testing Functions Added
All testing functions have been added to `Skillet.lua` and are ready for in-game testing.

---

## Quick Start Guide

### 1. Load Into Game
1. Start WoW client
2. Log in with character that has professions
3. Addon should auto-load

### 2. Run Master Test Suite
```lua
/script Skillet:RunCrossProfessionTestSuite()
```

This will automatically run:
- ✅ API Validation Test
- ✅ Performance Benchmark
- ✅ Cross-Profession Search Test

---

## Individual Test Commands

### Test 1: API Validation
**Purpose:** Check if Custom_GetProfessionRecipes works without windows open

```lua
/script Skillet:TestCrossProfessionAPI()
```

**Expected Results:**
- ✅ Function exists
- ✅ Returns recipes for each profession (171=Alchemy, 164=Blacksmithing, etc.)
- ✅ Returns total count with professionId = -1
- ✅ Can get recipe info without window open

**Failure Modes:**
- ❌ Function doesn't exist → Server doesn't support this API
- ❌ Returns nil for professions → May need to open windows first
- ❌ Returns empty lists → Character doesn't have professions learned

---

### Test 2: Performance Benchmark
**Purpose:** Measure API speed for large-scale operations

```lua
/script Skillet:TestCrossProfessionPerformance()
```

**Expected Results:**
- ✅ Get all recipes in <100ms (EXCELLENT)
- ✅ Get all recipes in <500ms (ACCEPTABLE)
- ⚠️ Get all recipes in >500ms (SLOW - may need caching)

**Performance Targets:**
- All recipes scan: <100ms
- 100 recipe info calls: <200ms
- Average per recipe: <2ms

---

### Test 3: Data Consistency Check
**Purpose:** Compare Custom API data vs traditional window data

```lua
-- FIRST: Open a profession window (e.g., Alchemy)
/script Skillet:TestCrossProfessionDataConsistency()
```

**Expected Results:**
- ✅ Recipe counts match between window and API
- ✅ Recipe names accessible
- ✅ No missing recipes

**Critical Questions:**
1. Do counts match exactly?
2. Are specialty recipes included (e.g., Mooncloth Tailoring)?
3. Are unlearned recipes filtered out correctly?
4. Do spell IDs correspond to correct recipes?

---

### Test 4: Cross-Profession Search
**Purpose:** Test searching across all professions simultaneously

```lua
/script Skillet:TestCrossProfessionSearch("transmute")
/script Skillet:TestCrossProfessionSearch("potion")
/script Skillet:TestCrossProfessionSearch("belt")
```

**Expected Results:**
- ✅ Finds matches across multiple professions
- ✅ Search completes in <100ms
- ✅ Results show profession name correctly

**Test Variations:**
- Common words: "iron", "steel", "potion"
- Specific items: "titanium", "mongoose"
- Partial matches: "trans", "pot"

---

## Test Results Template

Copy this and fill in results:

```
=== CROSS-PROFESSION TEST RESULTS ===
Date: __________
Character: __________
Server: Synastria

TEST 1: API Validation
- Custom_GetProfessionRecipes exists: YES / NO
- Returns recipes without window: YES / NO
- Alchemy (171): ____ recipes
- Blacksmithing (164): ____ recipes
- All professions (-1): ____ total recipes
- Can get recipe info: YES / NO
- Notes: ___________________________________

TEST 2: Performance
- Get all recipes: ____ms
- Performance rating: EXCELLENT / ACCEPTABLE / SLOW
- 100 recipe info calls: ____ms
- Average per recipe: ____ms
- Notes: ___________________________________

TEST 3: Data Consistency
- Profession tested: __________
- Window count: ____ recipes
- API count: ____ recipes
- Counts match: YES / NO
- Sample recipes match: YES / NO
- Notes: ___________________________________

TEST 4: Search
- Search term: __________
- Results found: ____
- Search time: ____ms
- Professions represented: __________
- Notes: ___________________________________

CRITICAL FINDINGS:
1. ___________________________________
2. ___________________________________
3. ___________________________________

BLOCKERS:
- ___________________________________

READY FOR NEXT PHASE: YES / NO
```

---

## Success Criteria

### ✅ PASS Criteria
- [ ] Custom_GetProfessionRecipes exists and works
- [ ] Returns recipes for all professions without windows
- [ ] Performance <500ms for full scan
- [ ] Data matches window-based data
- [ ] Search works across professions

### ❌ FAIL Criteria
- API doesn't exist
- Returns nil/empty for all professions
- Performance >2 seconds
- Data inconsistencies >10%
- Crashes or errors

---

## Next Steps Based on Results

### If ALL TESTS PASS ✅
→ Proceed to implementation:
1. Create RecipeDatabase.lua module
2. Implement caching system
3. Add global search UI
4. Begin Phase 2 testing (Spell-Based Crafting)

### If PERFORMANCE SLOW ⚠️
→ Implement caching first:
1. Create local cache on first scan
2. Refresh weekly or on demand
3. Optimize search algorithms
4. Re-test performance

### If API MISSING ❌
→ Fallback strategy:
1. Use traditional window-based scanning
2. Request server-side API implementation
3. Implement background scanning system
4. Cache window data when opened

---

## Troubleshooting

### "Custom_GetProfessionRecipes does not exist"
- **Cause:** Server doesn't have this API implemented
- **Solution:** Contact server admin or use fallback mode

### "Returned nil for all professions"
- **Cause:** Character may not have professions learned, or API requires window to be opened once
- **Solution:** Open each profession window once, then retest

### "Counts don't match"
- **Cause:** Headers included in count, or specialty recipes filtered differently
- **Solution:** Investigate specific recipes that differ

### Performance issues
- **Cause:** Large dataset, slow API, network lag
- **Solution:** Implement client-side caching

---

## Additional Debug Commands

### Get raw recipe data
```lua
/script local r = Custom_GetProfessionRecipes(171); print("Alchemy:", r and #r or "nil")
```

### Check specific spell
```lua
/script local s,n,i = Custom_GetProfessionRecipeInfo(12345); print(n or "Not found")
```

### Monitor in real-time
```lua
/script Skillet:MonitorCraftCalls(true)  -- Enable monitoring
/script Skillet:MonitorCraftCalls(false) -- Disable
```

---

## Report Results

After testing, please document:
1. All test results (use template above)
2. Any unexpected behavior
3. Performance metrics
4. Recommendations for implementation

**By the Omnissiah, may your tests reveal the Machine God's truth!** ⚙️🔧
