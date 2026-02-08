# Performance Improvements via Server-Side Processing

## Overview
Leverage Synastria's custom server APIs to offload computation-intensive tasks from client to server, improving addon performance and responsiveness.

## Current State
- All recipe scanning happens client-side
- Tradeskill window must be opened to access data
- Slow iteration through recipes
- Heavy Lua computation for crafting paths
- UI freezes during complex calculations

## Desired State
- Server handles recipe database queries
- Instant access to all profession data
- Fast crafting path analysis
- Smooth UI experience
- Reduced memory footprint

---

## Performance Bottlenecks (Current)

### Bottleneck 1: Recipe Scanning
```lua
-- SLOW: Must open tradeskill window and iterate
function ScanRecipes()
    CastSpellByName("Alchemy") -- Open window
    -- Wait for window...
    
    for i = 1, GetNumTradeSkills() do
        local name = GetTradeSkillInfo(i)
        local link = GetTradeSkillItemLink(i)
        -- ... process each recipe one by one
    end
    
    -- Repeat for each profession...
end
```

**Problem:**
- Requires opening each profession window
- Iterative processing (200+ recipes per profession)
- UI blocks during scan
- Consumes game events/bandwidth

---

### Bottleneck 2: Crafting Path Calculation
```lua
-- SLOW: Recursive tree traversal client-side
function GetCraftingTree(spellId, depth)
    -- Get reagents
    local reagents = GetReagents(spellId) -- Requires window open
    
    for reagentId, count in pairs(reagents) do
        -- Can this be crafted?
        local recipe = FindRecipeForItem(reagentId) -- More window opens!
        
        if recipe then
            GetCraftingTree(recipe.spellId, depth + 1) -- Recurse
        end
    end
end
```

**Problem:**
- Deep recursion in Lua (slow)
- Multiple profession window switches
- Exponential complexity for complex trees

---

### Bottleneck 3: Shopping List Generation
```lua
-- SLOW: Aggregating across professions
function GenerateShoppingList()
    local materials = {}
    
    for _, queueItem in ipairs(queue) do
        -- Must have profession window open
        local reagents = GetReagents(queueItem.spellId)
        
        for reagentId, count in pairs(reagents) do
            materials[reagentId] = (materials[reagentId] or 0) + count
            
            -- Check if craftable
            local recipe = FindRecipeForItem(reagentId) -- Window switch
            if recipe then
                -- Get sub-reagents...
            end
        end
    end
end
```

**Problem:**
- Repeated profession switching
- Nested loops with window dependencies
- UI freeze during calculation

---

## Server-Side Solutions

### Solution 1: Server-Side Recipe Cache

**Concept:** Server maintains complete recipe database, client queries instantly

```lua
-- FAST: Single API call, no windows
function GetAllRecipesInstant()
    local allRecipes = Custom_GetProfessionRecipes(-1) -- ALL professions, instant
    
    -- Returns array of spell IDs immediately
    -- No window required!
    
    return allRecipes
end
```

**Benefits:**
- No profession window required
- Instant access to all recipes
- Single API call vs hundreds of iterations

---

### Solution 2: Server-Side Path Calculation

**Concept:** Server calculates crafting trees server-side, returns complete data

```lua
-- Hypothetical: Request server calculate crafting tree
-- (This would require a NEW custom API to be implemented server-side)

function Custom_GetCraftingPath(spellId, depth)
    -- Server calculates full tree
    -- Returns complete structure
    
    return {
        spellId = 12345,
        name = "Iceblade Arrows",
        reagents = {
            [41163] = { -- Titanium Bar
                needed = 1,
                recipes = {
                    [55208] = "Smelt Titanium",
                    [60350] = "Transmute: Titanium",
                },
                subReagents = {
                    [36910] = { -- Titanium Ore
                        needed = 2,
                        recipes = {},
                        canMine = true,
                    }
                }
            }
        }
    }
end
```

**Benefits:**
- No client-side recursion
- Server can optimize algorithm
- Instant return of complete tree
- Reduced network traffic

---

### Solution 3: Batch Recipe Info Queries

**Concept:** Request multiple recipes in one call instead of individual queries

```lua
-- SLOW: Individual queries
for _, spellId in ipairs(recipeList) do
    local skillId, name, itemId = Custom_GetProfessionRecipeInfo(spellId)
    local reagents = Custom_GetProfessionRecipeReagents(spellId)
    local hasAttune, level = Custom_GetProfessionRecipeAttunement(spellId)
end

-- FAST: Batch query (would need new API)
function Custom_GetProfessionRecipesInfoBatch(spellIds)
    -- Server returns complete data for all recipes in one response
    return {
        [12345] = {
            skillId = 171,
            name = "Health Potion",
            itemId = 858,
            reagents = {[765] = 1, [785] = 1},
            attunement = {has = false, level = 0},
        },
        [12346] = { ... },
        -- etc
    }
end
```

**Benefits:**
- Reduced API calls (1 vs N)
- Less network overhead
- Faster UI updates

---

## Testing Requirements

### Phase 1: Benchmark Current Performance

**Test 1: Recipe scan timing**
```lua
function BenchmarkRecipeScan()
    local start = debugprofilestop()
    
    -- Scan all Alchemy recipes
    CastSpellByName("Alchemy")
    C_Timer.After(1, function() -- Wait for window
        for i = 1, GetNumTradeSkills() do
            local name = GetTradeSkillInfo(i)
            local link = GetTradeSkillItemLink(i)
        end
        
        local elapsed = debugprofilestop() - start
        print("Scan time: " .. elapsed .. "ms")
    end)
end

/script BenchmarkRecipeScan()
```

**Expected:** Probably 1000-3000ms for one profession

---

**Test 2: Custom API scan timing**
```lua
function BenchmarkCustomAPIScan()
    local start = debugprofilestop()
    
    local recipes = Custom_GetProfessionRecipes(171) -- Alchemy
    
    for _, spellId in ipairs(recipes) do
        local info = Custom_GetProfessionRecipeInfo(spellId)
        local reagents = Custom_GetProfessionRecipeReagents(spellId)
    end
    
    local elapsed = debugprofilestop() - start
    print("Custom API scan time: " .. elapsed .. "ms")
end

/script BenchmarkCustomAPIScan()
```

**Expected:** Should be faster (no window), but still N API calls

---

### Phase 2: Optimize Critical Paths

**Test 3: Cached vs uncached performance**
```lua
-- Test with caching
local recipeCache = {}

function GetRecipeInfoCached(spellId)
    if recipeCache[spellId] then
        return recipeCache[spellId]
    end
    
    local info = Custom_GetProfessionRecipeInfo(spellId)
    local reagents = Custom_GetProfessionRecipeReagents(spellId)
    
    recipeCache[spellId] = {
        info = info,
        reagents = reagents,
    }
    
    return recipeCache[spellId]
end

-- Benchmark
local start = debugprofilestop()

for i = 1, 100 do
    GetRecipeInfoCached(12345) -- Same recipe
end

local elapsed = debugprofilestop() - start
print("100 cached lookups: " .. elapsed .. "ms")
```

**Expected:** First call slow, rest instant

---

## Code Changes Required

### 1. Recipe Cache System
**New File:** `RecipeCache.lua`

```lua
local Cache = {}
Skillet.RecipeCache = Cache

-- Persistent cache (saved variables)
SkilletRecipeCacheData = SkilletRecipeCacheData or {
    version = 1,
    recipes = {}, -- [spellId] = {full data}
    lastUpdate = 0,
}

function Cache:Initialize()
    -- Check if cache needs refresh (weekly or on patch)
    if self:NeedsRefresh() then
        self:FullRefresh()
    end
end

function Cache:NeedsRefresh()
    local age = time() - SkilletRecipeCacheData.lastUpdate
    local oneWeek = 604800
    
    return age > oneWeek or SkilletRecipeCacheData.version < 1
end

function Cache:FullRefresh()
    if not Custom_GetProfessionRecipes then return end
    
    Skillet:Print("Refreshing recipe cache...")
    local start = debugprofilestop()
    
    local allRecipes = Custom_GetProfessionRecipes(-1)
    local count = 0
    
    for _, spellId in ipairs(allRecipes) do
        local data = self:FetchRecipeData(spellId)
        if data then
            SkilletRecipeCacheData.recipes[spellId] = data
            count = count + 1
        end
    end
    
    SkilletRecipeCacheData.lastUpdate = time()
    local elapsed = debugprofilestop() - start
    
    Skillet:Print(string.format("Cached %d recipes in %.0fms", count, elapsed))
end

function Cache:FetchRecipeData(spellId)
    local skillId, name, itemId, minSkill, canCraft, minMade, maxMade = Custom_GetProfessionRecipeInfo(spellId)
    if not skillId then return nil end
    
    local reagents = Custom_GetProfessionRecipeReagents(spellId)
    local hasAttune, attuneLevel = Custom_GetProfessionRecipeAttunement(spellId)
    
    return {
        skillId = skillId,
        name = name,
        itemId = itemId,
        minSkill = minSkill,
        minMade = minMade,
        maxMade = maxMade,
        reagents = reagents,
        hasAttunement = hasAttune,
        attunementLevel = attuneLevel,
    }
end

function Cache:Get(spellId)
    return SkilletRecipeCacheData.recipes[spellId]
end

function Cache:GetAll(skillId)
    local results = {}
    
    for spellId, data in pairs(SkilletRecipeCacheData.recipes) do
        if not skillId or data.skillId == skillId then
            results[spellId] = data
        end
    end
    
    return results
end
```

---

### 2. Lazy Loading System
**File:** `SkilletStitch-1.1.lua`

```lua
-- Load recipe data on-demand instead of upfront

function SkilletStitch:GetRecipeData(spellId)
    -- Check cache first
    if Skillet.RecipeCache then
        local cached = Skillet.RecipeCache:Get(spellId)
        if cached then
            return cached
        end
    end
    
    -- Fetch from server if not cached
    return Skillet.RecipeCache:FetchRecipeData(spellId)
end

-- Preload commonly used recipes
function SkilletStitch:PreloadFrequentRecipes()
    -- Track which recipes user crafts most
    local frequent = Skillet.db.profile.frequent_recipes or {}
    
    for spellId, count in pairs(frequent) do
        if count > 10 then -- Crafted >10 times
            self:GetRecipeData(spellId) -- Ensure cached
        end
    end
end
```

---

### 3. Asynchronous Processing
**File:** `AsyncProcessor.lua`

```lua
local Async = {}
Skillet.Async = Async

-- Process heavy tasks across multiple frames
function Async:ProcessInChunks(items, processFunc, chunkSize, callback)
    chunkSize = chunkSize or 10
    local index = 1
    
    local function processChunk()
        local count = 0
        
        while index <= #items and count < chunkSize do
            processFunc(items[index], index)
            index = index + 1
            count = count + 1
        end
        
        if index <= #items then
            -- More to process
            C_Timer.After(0.01, processChunk)
        else
            -- Done
            if callback then
                callback()
            end
        end
    end
    
    processChunk()
end

-- Example: Process all recipes without UI freeze
function SkilletStitch:ScanRecipesAsync(profession)
    local recipes = Custom_GetProfessionRecipes(profession)
    
    Skillet.Async:ProcessInChunks(
        recipes,
        function(spellId, index)
            local data = Skillet.RecipeCache:FetchRecipeData(spellId)
            -- Process data
        end,
        20, -- 20 recipes per frame
        function()
            Skillet:Print("Scan complete!")
            self:UpdateDisplay()
        end
    )
end
```

---

### 4. Optimized Shopping List
**File:** `UI/ShoppingList.lua`

```lua
function Skillet:GenerateShoppingListOptimized()
    local materials = {}
    
    -- Use cached recipe data
    for _, queueItem in ipairs(Skillet.stitch.queue) do
        if queueItem.spellId then
            local recipeData = Skillet.RecipeCache:Get(queueItem.spellId)
            
            if recipeData and recipeData.reagents then
                for itemId, count in pairs(recipeData.reagents) do
                    local needed = count * queueItem.numcasts
                    materials[itemId] = (materials[itemId] or 0) + needed
                end
            end
        end
    end
    
    -- No profession windows needed!
    return materials
end
```

---

### 5. Memory Management
**File:** `MemoryManager.lua`

```lua
local Memory = {}
Skillet.Memory = Memory

function Memory:Optimize()
    -- Clear unused cache entries
    local accessed = Skillet.db.profile.recipe_access or {}
    local twoWeeksAgo = time() - 1209600
    
    for spellId, data in pairs(SkilletRecipeCacheData.recipes) do
        local lastAccess = accessed[spellId] or 0
        
        if lastAccess < twoWeeksAgo then
            -- Haven't accessed in 2 weeks - clear from cache
            SkilletRecipeCacheData.recipes[spellId] = nil
        end
    end
    
    -- Force garbage collection
    collectgarbage("collect")
end

-- Track recipe access
function Memory:TrackAccess(spellId)
    Skillet.db.profile.recipe_access = Skillet.db.profile.recipe_access or {}
    Skillet.db.profile.recipe_access[spellId] = time()
end

-- Run optimization periodically
C_Timer.NewTicker(3600, function() -- Every hour
    Skillet.Memory:Optimize()
end)
```

---

## Implementation Plan

### Step 1: Recipe Cache (4-5 hours)
1. Create RecipeCache.lua
2. Implement caching system
3. Add refresh logic
4. Test performance improvement

### Step 2: Lazy Loading (2-3 hours)
1. Modify data access patterns
2. Implement preloading
3. Test with various scenarios

### Step 3: Async Processing (3-4 hours)
1. Create AsyncProcessor.lua
2. Convert heavy operations
3. Test UI responsiveness

### Step 4: Optimize Existing Code (4-6 hours)
1. Update shopping list
2. Optimize queue processing
3. Remove unnecessary window dependencies
4. Profile and benchmark

### Step 5: Memory Management (2-3 hours)
1. Implement cache cleanup
2. Add access tracking
3. Test memory usage

**Total Estimated Time:** 15-21 hours

---

## Success Criteria

✅ **Must Have:**
1. 50%+ reduction in load times
2. No UI freezing during calculations
3. Reduced profession window dependencies
4. Memory usage under control

✅ **Nice to Have:**
1. 75%+ performance improvement
2. Zero profession window requirements
3. Automatic cache management
4. Background data updates

---

## Performance Targets

| Operation | Current | Target |
|-----------|---------|--------|
| Full recipe scan | 3000ms | <500ms |
| Shopping list generation | 1500ms | <100ms |
| Crafting path calculation | 2000ms | <200ms |
| UI update lag | 500ms | <50ms |
| Memory footprint | 15MB | <5MB |

---

## Future Optimizations

1. Request server-side batch APIs
2. Implement incremental updates
3. Background cache warming
4. Predictive preloading
5. Database compression
6. Network request pooling
