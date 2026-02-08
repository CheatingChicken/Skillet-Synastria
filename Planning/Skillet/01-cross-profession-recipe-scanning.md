# Cross-Profession Recipe Scanning

## Overview
Enable scanning and searching recipes across ALL professions without requiring the user to open each profession window individually.

## Current State
- Recipes are loaded only when profession window is open
- Data stored in `SkilletStitch.data[profession]` keyed by profession name
- User must manually open each profession to populate data
- Search is limited to currently open profession

## Desired State
- Load all recipe data for all known professions on login/demand
- Search across all professions simultaneously
- Display results with profession name alongside recipe name
- Filter and sort across profession boundaries

---

## Testing Requirements

### Phase 1: API Validation
**Test Functions Needed:**
```lua
-- Test 1: Can we get recipes for professions we haven't opened?
/script local recipes = Custom_GetProfessionRecipes(164) -- Blacksmithing
/script if recipes then print("Got " .. #recipes .. " recipes") end

-- Test 2: Get ALL recipes across all professions
/script local allRecipes = Custom_GetProfessionRecipes(-1)
/script if allRecipes then print("Total recipes: " .. #allRecipes) end

-- Test 3: Get recipe info without opening window
/script local recipes = Custom_GetProfessionRecipes(164)
/script if recipes then
    local skillId, name, itemId = Custom_GetProfessionRecipeInfo(recipes[1])
    print("Recipe: " .. (name or "nil"))
end

-- Test 4: Performance test - how long does full scan take?
/script local start = debugprofilestop()
/script local recipes = Custom_GetProfessionRecipes(-1)
/script local elapsed = debugprofilestop() - start
/script print("Scan took: " .. elapsed .. "ms")
```

**Expected Results:**
- ✅ Returns recipe spell IDs for professions not currently open
- ✅ Returns comprehensive list when professionId = -1
- ✅ Recipe info available without window open
- ✅ Performance acceptable (target: <500ms for full scan)

**Failure Scenarios:**
- ❌ Returns nil for professions not opened → Need to open each profession once
- ❌ Slow performance (>2 seconds) → Need caching strategy
- ❌ Incomplete data → Need to validate against known recipe counts

### Phase 2: Data Consistency
**Tests:**
```lua
-- Compare custom API data vs traditional window-based data
/script -- Open Blacksmithing window first
/script local customRecipes = Custom_GetProfessionRecipes(164)
/script local windowRecipes = GetNumTradeSkills()
/script print("Custom API: " .. #customRecipes .. " | Window: " .. windowRecipes)

-- Verify spell IDs match expected values
-- Check if reagent data matches
```

**Questions to Answer:**
1. Do spell IDs remain consistent across sessions?
2. Are specialty recipes (e.g., Mooncloth Tailoring) included?
3. Are unlearned recipes filtered out?
4. How are header/category entries handled?

---

## Code Changes Required

### 1. New Module: RecipeDatabase.lua
**Purpose:** Centralized recipe data management using custom APIs

**Location:** `Skillet - Synastria/RecipeDatabase.lua`

**Structure:**
```lua
-- RecipeDatabase.lua
local RecipeDB = {}
Skillet.RecipeDB = RecipeDB

-- Cache structure
RecipeDB.cache = {
    recipes = {},      -- [spellId] = {full recipe data}
    byProfession = {}, -- [professionId] = {spellId array}
    byItem = {},       -- [itemId] = spellId
    lastUpdate = 0,
    version = 1
}

-- Load all recipes from custom API
function RecipeDB:LoadAllRecipes()
    local spellIds = Custom_GetProfessionRecipes(-1)
    -- Process and cache
end

-- Get recipes by profession
function RecipeDB:GetRecipesByProfession(professionId)
    return self.cache.byProfession[professionId]
end

-- Search across all professions
function RecipeDB:SearchRecipes(searchText, professionFilter)
    -- Search implementation
end
```

### 2. Modify SkilletStitch-1.1.lua
**Location:** Lines where data is populated on window open

**Current Code (approx line 600-700):**
```lua
-- Data is populated when CastTradeSkill is called
-- Relies on GetNumTradeSkills() and GetTradeSkillInfo(i)
```

**Changes:**
```lua
-- Add fallback to RecipeDB if custom API available
function SkilletStitch:GetItemDataByName(name, prof)
    -- EXISTING: Search in cache
    -- EXISTING: Search in self.data
    
    -- NEW: If Custom_GetProfessionRecipes exists, search there
    if Custom_GetProfessionRecipes and Skillet.RecipeDB then
        local results = Skillet.RecipeDB:SearchRecipes(name, prof)
        if results and #results > 0 then
            return results[1] -- or apply priority logic
        end
    end
    
    -- EXISTING: Fallback logic
end
```

### 3. Add Global Search UI
**New File:** `UI/GlobalRecipeSearch.lua`

**Features:**
- Search input box
- Profession filter dropdown (All, Alchemy, Blacksmithing, etc.)
- Results list showing: Recipe Name | Profession | Materials | Craftable
- "Open in Profession" button
- "Add to Queue" button

**Integration Point:**
Add button to main Skillet window: "Search All Recipes"

### 4. Update Main Frame
**File:** `UI/MainFrame.lua`

**Add Button:**
```lua
-- Around line 300-400 where other buttons are created
local searchAllButton = CreateFrame("Button", "SkilletSearchAllButton", ...)
searchAllButton:SetText("Search All")
searchAllButton:SetScript("OnClick", function()
    Skillet:ShowGlobalRecipeSearch()
end)
```

### 5. Update Queue System
**File:** `SkilletQueue.lua`

**Modify `add_items_to_queue`:**
```lua
-- Current: Relies on profession being open
-- Change: Use spell ID from RecipeDB if available

local function add_items_to_queue(skillIndex, recipe, count, profession, addToTop)
    -- NEW: If we have spell ID, store it
    local spellId = recipe.spellId or Skillet.RecipeDB:GetSpellIdByIndex(profession, skillIndex)
    
    -- Store spell ID in queue item for later use
    Skillet.stitch:AddToQueue(skillIndex, count, profession, addToTop, spellId)
end
```

### 6. Shopping List Enhancement
**File:** `UI/ShoppingList.lua`

**Change:**
```lua
-- Current: Only scans current profession
function Skillet:GetReagentsForQueuedRecipes()
    -- NEW: Use RecipeDB to get reagents across all professions
    if Skillet.RecipeDB then
        return Skillet.RecipeDB:GetGlobalShoppingList(queue)
    end
    
    -- EXISTING: Fallback to old method
end
```

---

## Implementation Plan

### Step 1: Create Test Suite (1-2 hours)
1. Create `Tests/RecipeAPITest.lua`
2. Add slash command: `/skillettest recipes`
3. Run all validation tests
4. Document results

### Step 2: Create RecipeDatabase Module (4-6 hours)
1. Create `RecipeDatabase.lua`
2. Implement data loading
3. Implement caching logic
4. Add search functions
5. Test with known recipes

### Step 3: Integrate with Existing Code (3-4 hours)
1. Modify `GetItemDataByName` to use RecipeDB
2. Update queue system to handle spell IDs
3. Test backward compatibility

### Step 4: Create Global Search UI (4-6 hours)
1. Design UI layout
2. Implement search functionality
3. Add result filtering/sorting
4. Connect to queue system

### Step 5: Testing & Refinement (2-3 hours)
1. Test with all professions
2. Performance profiling
3. Edge case handling
4. Bug fixes

**Total Estimated Time:** 14-21 hours

---

## Risks & Mitigations

### Risk 1: Custom API Not Available
**Mitigation:** Feature detection + graceful fallback
```lua
if not Custom_GetProfessionRecipes then
    -- Disable cross-profession features
    -- Show tooltip: "Requires Synastria server"
end
```

### Risk 2: Performance Issues
**Mitigation:** 
- Lazy loading (only load on demand)
- Cache aggressively
- Throttle searches (debounce input)

### Risk 3: Data Inconsistency
**Mitigation:**
- Validate against known recipe counts
- Periodic refresh
- User-triggered manual refresh

### Risk 4: Breaking Existing Functionality
**Mitigation:**
- Feature flags for new code paths
- Extensive testing with features disabled
- Rollback plan

---

## Success Criteria

✅ **Must Have:**
1. Search across all professions without opening windows
2. Results show correct profession name
3. No degradation of existing features
4. Performance <500ms for full search

✅ **Nice to Have:**
1. Results show craftability status
2. Filter by "Can Craft Now"
3. Sort by profession/difficulty/name
4. Save recent searches

---

## Future Enhancements

After initial implementation:
1. Filter by item class/subclass (weapons, armor, etc.)
2. Filter by attunement status
3. "Similar Recipes" suggestions
4. Recipe comparison view
5. Export search results
