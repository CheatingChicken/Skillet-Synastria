# Advanced Material & Crafting Path Analysis

## Overview
Leverage custom APIs to provide deep, cross-profession analysis of crafting paths, material requirements, and alternative sourcing options.

## Current State
- Material checking limited to current profession
- Subcraft detection only searches current profession
- Manual calculation of multi-step crafting paths
- No alternative recipe suggestions
- Limited visibility into material bottlenecks

## Desired State
- Intelligent subcraft detection across ALL professions
- Alternative recipe finder (multiple ways to get same item)
- Bottleneck identification ("Need 10 more X to craft everything")
- Cost optimization (vendor vs craft vs transmute)
- Multi-step path visualization

---

## Testing Requirements

### Phase 1: Reagent Data Validation

**Test 1: Reagent accuracy**
```lua
-- Compare reagents from Custom API vs window-based
/script local spellId = 12345
/script local customReagents = Custom_GetProfessionRecipeReagents(spellId)
/script -- Open tradeskill window, find same recipe
/script local windowReagents = {} -- parse from GetTradeSkillReagentInfo
/script -- Compare
```

**Expected:** ✅ Identical reagent data

---

**Test 2: Nested reagent lookup**
```lua
-- Find all reagents recursively for a complex recipe
function GetAllReagentsRecursive(spellId, depth)
    if depth > 10 then return {} end -- Prevent infinite recursion
    
    local reagents = Custom_GetProfessionRecipeReagents(spellId)
    if not reagents then return {} end
    
    local all = {}
    for itemId, count in pairs(reagents) do
        all[itemId] = (all[itemId] or 0) + count
        
        -- Check if this reagent is craftable
        local craftSpellId = Custom_GetProfessionRecipeFromCraftedItem(itemId)
        if craftSpellId then
            local subReagents = GetAllReagentsRecursive(craftSpellId, depth + 1)
            for subItemId, subCount in pairs(subReagents) do
                all[subItemId] = (all[subItemId] or 0) + (subCount * count)
            end
        end
    end
    
    return all
end

-- Test with complex item like Iceblade Arrows
/script local reagents = GetAllReagentsRecursive(spellId)
/script for itemId, count in pairs(reagents) do
    print(GetItemInfo(itemId) .. ": " .. count)
end
```

**Expected:** ✅ Complete material tree including base materials

---

### Phase 2: Cross-Profession Detection

**Test 3: Find all recipes that create specific item**
```lua
-- Find all ways to get Titanium Bar
local function FindAllRecipesForItem(itemId)
    local allRecipes = Custom_GetProfessionRecipes(-1) -- All professions
    local matches = {}
    
    for _, spellId in ipairs(allRecipes) do
        local _, _, craftedItemId = Custom_GetProfessionRecipeInfo(spellId)
        if craftedItemId == itemId then
            table.insert(matches, spellId)
        end
    end
    
    return matches
end

/script local titaniumBarId = 41163
/script local recipes = FindAllRecipesForItem(titaniumBarId)
/script for _, spellId in ipairs(recipes) do
    local skillId, name = Custom_GetProfessionRecipeInfo(spellId)
    print(name .. " (Skill: " .. skillId .. ")")
end
```

**Expected:** Shows both Smelting and Transmute recipes

---

**Test 4: Material availability with crafting**
```lua
-- Calculate how many times we can craft including subcrafts
function CalculateCraftableWithSubcrafts(spellId)
    local reagents = Custom_GetProfessionRecipeReagents(spellId)
    if not reagents then return 0 end
    
    local minCraftable = 999999
    
    for itemId, needed in pairs(reagents) do
        local have = GetItemCount(itemId, true) -- Include bank
        
        -- Can we craft this reagent?
        local reagentSpellId = Custom_GetProfessionRecipeFromCraftedItem(itemId)
        if reagentSpellId then
            local _, _, _, _, canCraftReagent = Custom_GetProfessionRecipeInfo(reagentSpellId)
            have = have + (canCraftReagent or 0)
        end
        
        local craftable = math.floor(have / needed)
        minCraftable = math.min(minCraftable, craftable)
    end
    
    return minCraftable
end

/script local count = CalculateCraftableWithSubcrafts(spellId)
/script print("Can craft " .. count .. " times (including subcrafts)")
```

---

## Code Changes Required

### 1. New Module: CraftingPathAnalyzer.lua
**File:** `Skillet - Synastria/CraftingPathAnalyzer.lua`

```lua
local CraftPath = {}
Skillet.CraftPath = CraftPath

-- Find all recipes that create an item
function CraftPath:FindRecipesForItem(itemId)
    if not Custom_GetProfessionRecipes then return {} end
    
    local allRecipes = Custom_GetProfessionRecipes(-1)
    local matches = {}
    
    for _, spellId in ipairs(allRecipes) do
        local _, _, craftedItemId = Custom_GetProfessionRecipeInfo(spellId)
        if craftedItemId == itemId then
            table.insert(matches, {
                spellId = spellId,
                info = self:GetRecipeFullInfo(spellId)
            })
        end
    end
    
    return matches
end

-- Get complete crafting tree
function CraftPath:GetCraftingTree(spellId, maxDepth)
    maxDepth = maxDepth or 10
    local tree = {
        spellId = spellId,
        info = self:GetRecipeFullInfo(spellId),
        reagents = {}
    }
    
    if maxDepth <= 0 then return tree end
    
    local reagents = Custom_GetProfessionRecipeReagents(spellId)
    if reagents then
        for itemId, count in pairs(reagents) do
            local reagentRecipes = self:FindRecipesForItem(itemId)
            
            tree.reagents[itemId] = {
                needed = count,
                have = GetItemCount(itemId, true),
                recipes = reagentRecipes,
                craftingTree = {}
            }
            
            -- Recurse into craftable reagents
            for _, recipeInfo in ipairs(reagentRecipes) do
                local subTree = self:GetCraftingTree(recipeInfo.spellId, maxDepth - 1)
                table.insert(tree.reagents[itemId].craftingTree, subTree)
            end
        end
    end
    
    return tree
end

-- Find material bottlenecks
function CraftPath:FindBottlenecks(spellId, quantity)
    local reagents = Custom_GetProfessionRecipeReagents(spellId)
    if not reagents then return {} end
    
    local bottlenecks = {}
    
    for itemId, needed in pairs(reagents) do
        local totalNeeded = needed * quantity
        local have = GetItemCount(itemId, true)
        
        if have < totalNeeded then
            local shortage = totalNeeded - have
            local itemName = GetItemInfo(itemId) or ("Item #" .. itemId)
            
            table.insert(bottlenecks, {
                itemId = itemId,
                itemName = itemName,
                needed = totalNeeded,
                have = have,
                shortage = shortage,
                canCraft = self:FindRecipesForItem(itemId)
            })
        end
    end
    
    return bottlenecks
end

-- Calculate total raw materials needed (flattened tree)
function CraftPath:GetRawMaterials(spellId, quantity, includeVendor)
    local rawMats = {}
    
    local function processRecipe(recipeSpellId, count, depth)
        if depth > 10 then return end
        
        local reagents = Custom_GetProfessionRecipeReagents(recipeSpellId)
        if not reagents then return end
        
        for itemId, needed in pairs(reagents) do
            local totalNeeded = needed * count
            
            -- Check if craftable
            local recipes = self:FindRecipesForItem(itemId)
            
            if #recipes > 0 and not includeVendor then
                -- Craftable - recurse
                -- Use first recipe (could be smarter about selection)
                processRecipe(recipes[1].spellId, totalNeeded, depth + 1)
            else
                -- Not craftable or vendor item - add to raw materials
                rawMats[itemId] = (rawMats[itemId] or 0) + totalNeeded
            end
        end
    end
    
    processRecipe(spellId, quantity, 0)
    return rawMats
end
```

---

### 2. Enhanced SkilletCraftCalc.lua
**Add Alternative Recipe Detection**

```lua
-- In CalculateRecipeCraftability function
function SkilletCraftCalc:CalculateRecipeCraftability(recipe, lib, includeBank, verbose, depth, forceRecalc)
    -- EXISTING CODE for current profession
    
    -- NEW: Check for alternative recipes across professions
    if Custom_GetProfessionRecipes and Skillet.CraftPath then
        for _, reagent in ipairs(reagents) do
            local itemId = tonumber(reagent.link:match("item:(%d+)"))
            if itemId then
                local alternatives = Skillet.CraftPath:FindRecipesForItem(itemId)
                if #alternatives > 1 then
                    -- Multiple ways to get this item
                    -- Pick best option (most mats, no cooldown, etc.)
                    local bestOption = self:SelectBestRecipe(alternatives)
                    if bestOption then
                        -- Use alternative recipe for calculation
                    end
                end
            end
        end
    end
    
    -- EXISTING CODE continues
end
```

---

### 3. Shopping List Enhancement
**File:** `UI/ShoppingList.lua`

```lua
-- Add "Show Raw Materials" toggle
function Skillet:UpdateShoppingList()
    -- EXISTING: Get reagents for queue
    
    -- NEW: Option to show raw materials instead
    if SkilletDB.profile.show_raw_materials and Skillet.CraftPath then
        local rawMats = {}
        
        for _, queueItem in ipairs(queue) do
            if queueItem.spellId then
                local mats = Skillet.CraftPath:GetRawMaterials(
                    queueItem.spellId, 
                    queueItem.numcasts, 
                    false -- Don't include vendor items
                )
                
                for itemId, count in pairs(mats) do
                    rawMats[itemId] = (rawMats[itemId] or 0) + count
                end
            end
        end
        
        -- Display raw materials
        return self:DisplayRawMaterialsList(rawMats)
    end
    
    -- EXISTING: Display regular shopping list
end
```

---

### 4. New UI: Crafting Path Viewer
**File:** `UI/CraftingPathFrame.lua`

```lua
-- Visual tree view of crafting path
local PathFrame = CreateFrame("Frame", "SkilletCraftingPathFrame", UIParent)

function PathFrame:ShowCraftingPath(spellId)
    local tree = Skillet.CraftPath:GetCraftingTree(spellId, 5)
    
    -- Clear existing display
    self:ClearTree()
    
    -- Render tree recursively
    self:RenderTreeNode(tree, 0, 0)
end

function PathFrame:RenderTreeNode(node, x, y)
    -- Create visual representation
    -- - Recipe name
    -- - Reagent list
    -- - Lines connecting to sub-recipes
    -- - Color coding for availability
end
```

---

### 5. Bottleneck Analyzer UI
**File:** `UI/BottleneckFrame.lua`

```lua
-- Show what's blocking you from crafting
function Skillet:ShowBottlenecks()
    local frame = CreateFrame("Frame", "SkilletBottleneckFrame", UIParent)
    
    -- Analyze queue
    local allBottlenecks = {}
    for _, queueItem in ipairs(queue) do
        if queueItem.spellId then
            local bottlenecks = Skillet.CraftPath:FindBottlenecks(
                queueItem.spellId, 
                queueItem.numcasts
            )
            
            for _, bottleneck in ipairs(bottlenecks) do
                -- Aggregate bottlenecks
                local key = bottleneck.itemId
                if not allBottlenecks[key] then
                    allBottlenecks[key] = bottleneck
                else
                    allBottlenecks[key].shortage = allBottlenecks[key].shortage + bottleneck.shortage
                end
            end
        end
    end
    
    -- Display sorted by shortage amount
    self:DisplayBottlenecksList(allBottlenecks)
end

function Skillet:DisplayBottlenecksList(bottlenecks)
    -- Sort by shortage (worst first)
    local sorted = {}
    for _, bn in pairs(bottlenecks) do
        table.insert(sorted, bn)
    end
    table.sort(sorted, function(a, b) return a.shortage > b.shortage end)
    
    -- Display in scrolling list
    for i, bn in ipairs(sorted) do
        local row = CreateFrame("Button", nil, scrollFrame)
        
        -- Item icon and name
        local icon = row:CreateTexture()
        icon:SetTexture(GetItemIcon(bn.itemId))
        
        local nameText = row:CreateFontString()
        nameText:SetText(bn.itemName)
        
        -- Shortage amount (RED)
        local shortageText = row:CreateFontString()
        shortageText:SetText("Need " .. bn.shortage .. " more")
        shortageText:SetTextColor(1, 0, 0)
        
        -- Solutions
        if #bn.canCraft > 0 then
            local craftButton = CreateFrame("Button", nil, row)
            craftButton:SetText("Can Craft")
            craftButton:SetScript("OnClick", function()
                -- Open recipe or add to queue
            end)
        end
    end
end
```

---

## Implementation Plan

### Step 1: Core Module (4-6 hours)
1. Create CraftingPathAnalyzer.lua
2. Implement recipe lookup functions
3. Test tree generation
4. Validate data accuracy

### Step 2: Integration (3-4 hours)
1. Enhance SkilletCraftCalc
2. Update shopping list
3. Test with complex recipes

### Step 3: UI Components (6-8 hours)
1. Create path viewer frame
2. Create bottleneck analyzer
3. Add to main window
4. Polish visuals

### Step 4: Testing (2-3 hours)
1. Test with various recipes
2. Edge case handling
3. Performance optimization

**Total Estimated Time:** 15-21 hours

---

## Success Criteria

✅ **Must Have:**
1. Accurate multi-profession reagent detection
2. Bottleneck identification works
3. Performance acceptable for complex trees
4. No crashes with circular dependencies

✅ **Nice to Have:**
1. Visual crafting path tree
2. Alternative recipe suggestions
3. Cost comparison
4. "Smart craft" recommendations

---

## Future Enhancements

1. Recipe cost optimizer (gold cost calculation)
2. Time-to-craft estimator
3. Skill-up path optimizer
4. Material sourcing recommendations (vendor/AH/farm)
5. Export crafting plans
