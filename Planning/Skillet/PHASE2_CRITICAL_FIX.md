# Phase 2 Testing - Critical Fix: Spell ID vs Window Index

## Root Cause Identified

**Problem**: The testing UI was passing tradeskill window **indices** (1, 2, 3...) instead of **spell IDs** to `Custom_DoProfessionRecipe()`.

## API Signature (from SYNASTRIA_CUSTOM_API.md)

```lua
Custom_DoProfessionRecipe(spellId, [repeatCount])
```

**Parameters:**
- `spellId` - The crafting SPELL ID (e.g., 45545 for Frostweave Bandage, 53831 for Titansteel Bar)
- `repeatCount` - Optional, how many times to craft

## What Was Wrong

### Before (Incorrect):
```lua
local function FindMostCraftableRecipe(minCrafts)
    -- ... scan recipes ...
    return i, recipeName, craftable  -- ❌ Returning window index!
end

-- Usage:
local recipeId = FindMostCraftableRecipe(100)
Custom_DoProfessionRecipe(recipeId, 1)  -- ❌ Passing window index (1, 2, 3...)
```

**Result**: 
- `pcall()` succeeded (syntactically valid Lua function call)
- Nothing crafted (server rejected invalid spell ID)
- Confused debugging about SecureActionButtonTemplate, textures, SetPoint anchoring

### After (Fixed):
```lua
local function FindMostCraftableRecipe(minCrafts)
    -- ... scan recipes ...
    return recipe.spellId, recipeName, craftable  -- ✅ Returning spell ID!
end

-- Usage:
local spellId = FindMostCraftableRecipe(100)
Custom_DoProfessionRecipe(spellId, 1)  -- ✅ Passing spell ID (e.g., 45545)
```

## Changes Made

### 1. Fixed FindMostCraftableRecipe() - Line 60
```lua
-- OLD:
bestRecipeId = i

-- NEW:
bestSpellId = recipe.spellId
```

### 2. Added GetRecipeSpellIdByName() - Lines 70-99
```lua
local function GetRecipeSpellIdByName(recipeName, profession)
    local trade = Skillet.stitch:GetTradeIDFromName(profession)
    local numRecipes = Skillet.stitch:GetNumRecipes(trade)
    
    for i = 1, numRecipes do
        local recipe = Skillet.stitch:GetItemDataByIndex(trade, i)
        if recipe and recipe.name == recipeName then
            return recipe.spellId  -- Returns spell ID, not index
        end
    end
    
    return nil
end
```

### 3. Removed SecureActionButtonTemplate (Not Needed)

**Before**: Tests 2 and 3 used `SecureActionButtonTemplate` with `PreClick/PostClick` handlers
**After**: Simple `UIPanelButtonTemplate` with `OnClick` handlers

**Reason**: `Custom_DoProfessionRecipe` is a **regular Lua function**, not a secure action. SecureActionButtonTemplate is only needed for:
- Casting spells in combat
- Using items in combat
- Targeting units in combat
- Protected actions that require hardware events

### 4. Updated Test 2 - Windowless Crafting
```lua
dialog.testWindowlessButton:SetScript("OnClick", function()
    local spellId, recipeName, craftable = FindMostCraftableRecipe(100)
    
    -- Close window to test windowless crafting
    HideUIPanel(TradeSkillFrame)
    
    -- Call with SPELL ID
    local success = Custom_DoProfessionRecipe(spellId, 1)
    if success then
        AddTestResult("Windowless", true, string.format("✓ Crafted %s!", recipeName))
    end
end)
```

### 5. Updated Test 3 - Cooldown Respect
```lua
local spellId = GetRecipeSpellIdByName("Flask of Endless Rage", "Alchemy")
local success = Custom_DoProfessionRecipe(spellId, 1)

-- Check cooldown after craft using Custom_GetProfessionRecipeInfo
local recipeInfo = Custom_GetProfessionRecipeInfo(spellId)
if recipeInfo.cooldownRemaining > 0 then
    AddTestResult("Cooldown", true, "✓ Cooldown applied")
end
```

### 6. Test 4 Already Fixed
Test 4 calls `FindMostCraftableRecipe()` which now returns spell ID, so it's automatically corrected.

## Recipe Data Structure

The Skillet recipe object has these key properties:
```lua
recipe = {
    spellId = 45545,           -- ✅ THIS is what Custom_DoProfessionRecipe needs
    name = "Frostweave Bandage",
    numcraftable = 250,
    -- ... other properties
}
```

**Tradeskill Window Index** (1, 2, 3...):
- Used for UI positioning
- Used by `GetTradeSkillInfo(i)`, `DoTradeSkill(i, count)`
- **NOT** the same as spell ID

**Spell ID** (45545, 53831, etc.):
- Unique identifier for the crafting spell
- Required by `Custom_DoProfessionRecipe(spellId, count)`
- Can be used without tradeskill window open

## Lesson Learned

**ALWAYS consult API documentation BEFORE implementation.**

The SYNASTRIA_CUSTOM_API.md file clearly stated:
> "Craft a recipe using its spell ID. Can specify spell ID directly (no recipe index needed)"

Hours of debugging button visibility, SecureActionButtonTemplate, texture issues, SetPoint anchoring - all chasing the wrong problem. The buttons were working correctly, they were just receiving the wrong data type.

## Next Steps

1. `/reload` to load updated code
2. Open First Aid profession
3. Run `/skillet test`
4. Click Test 2 - should now show:
   ```
   Attempting Frostweave Bandage (Spell ID: 45545, 250 craftable)...
   ✓ Crafted Frostweave Bandage without window!
   ```
5. Verify materials consumed and item created

## Impact

If Test 2 now works correctly, this validates:
- ✅ Windowless crafting is possible
- ✅ Can craft without window switching
- ✅ Can implement spell-based queue processing
- ✅ Can build multi-profession queue support
- ✅ Major UX improvement unlocked

This is the **critical validation** needed to proceed with the entire spell-based crafting implementation strategy.
