# Spell-Based Crafting (Window-Free)

## Overview
Enable crafting using spell IDs directly via `Custom_DoProfessionRecipe()`, eliminating the need to have tradeskill windows open and switching between professions.

## Current State
- Crafting requires tradeskill window to be open
- Uses `DoTradeSkill(index, count)` with window-relative recipe index
- Queue processing must switch profession windows
- Index-based system is fragile (changes if new recipes learned)

## Desired State
- Craft using stable spell IDs: `Custom_DoProfessionRecipe(spellId, count)`
- No tradeskill window required (needs testing)
- Queue processes items from multiple professions without window switching
- More reliable (spell IDs don't change)

---

## Testing Requirements

### Phase 1: Basic Functionality Tests

**Test 1: Does it work without window open?**
```lua
-- Close all tradeskill windows
/script CloseTradeSkill()

-- Try to craft Linen Bandage (First Aid, spell ID varies)
-- First, find the spell ID
/script local recipes = Custom_GetProfessionRecipes(129) -- First Aid
/script if recipes then 
    local spellId = recipes[1]
    print("Testing spell ID: " .. spellId)
    -- Try to craft
    local result = Custom_DoProfessionRecipe(spellId, 1)
    print("Result: " .. tostring(result))
end
```

**Expected:** ✅ Crafting succeeds without window open  
**Fallback:** ❌ Must open window first → Need to track when to open windows

---

**Test 2: Does it work across professions?**
```lua
-- Craft from Alchemy, then immediately from Blacksmithing
/script local alchRecipes = Custom_GetProfessionRecipes(171) -- Alchemy
/script local bsRecipes = Custom_GetProfessionRecipes(164) -- Blacksmithing
/script Custom_DoProfessionRecipe(alchRecipes[1], 1)
/script C_Timer.After(2, function() Custom_DoProfessionRecipe(bsRecipes[1], 1) end)
```

**Expected:** ✅ Both crafts succeed without opening windows  
**Questions:**
- Does it queue crafts or execute immediately?
- Can we chain crafts from different professions?
- What's the minimum delay between crafts?

---

**Test 3: Cooldown behavior**
```lua
-- Find a recipe with cooldown
/script local recipes = Custom_GetProfessionRecipes(171) -- Alchemy
/script for _, spellId in ipairs(recipes) do
    local _, name = Custom_GetProfessionRecipeInfo(spellId)
    if name and name:match("^Transmute:") then
        print("Testing: " .. name .. " (ID: " .. spellId .. ")")
        -- Try to craft twice
        Custom_DoProfessionRecipe(spellId, 1)
        C_Timer.After(1, function()
            local result = Custom_DoProfessionRecipe(spellId, 1)
            print("Second attempt result: " .. tostring(result))
        end)
        break
    end
end
```

**Expected:** ❓ Unknown - this is KEY to test  
**Possibilities:**
- ✅ Bypasses cooldown (best case)
- ❌ Respects cooldown, returns nil
- ⚠️ Server error/disconnect

---

**Test 4: Event triggering**
```lua
-- Monitor events during Custom_DoProfessionRecipe
local frame = CreateFrame("Frame")
frame:RegisterEvent("TRADE_SKILL_UPDATE")
frame:RegisterEvent("UNIT_SPELLCAST_START")
frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
frame:SetScript("OnEvent", function(self, event, ...)
    print("Event: " .. event .. " | Args: " .. table.concat({...}, ", "))
end)

-- Then craft something
/script Custom_DoProfessionRecipe(spellId, 1)
```

**Questions:**
- Does it trigger the same events as DoTradeSkill?
- Can we detect when crafting completes?
- Are there new events we should monitor?

---

**Test 5: Error handling**
```lua
-- Test various error conditions

-- No materials
/script local result = Custom_DoProfessionRecipe(invalidSpellId, 1)
/script print("No materials result: " .. tostring(result))

-- Invalid spell ID
/script local result = Custom_DoProfessionRecipe(999999, 1)
/script print("Invalid ID result: " .. tostring(result))

-- Craft count too high
/script local result = Custom_DoProfessionRecipe(validSpellId, 999)
/script print("High count result: " .. tostring(result))
```

**Expected:** nil returns for errors, no client crashes

---

### Phase 2: Performance & Reliability Tests

**Test 6: Rapid crafting**
```lua
-- Can we craft multiple items quickly?
/script for i = 1, 5 do
    Custom_DoProfessionRecipe(spellId, 1)
end
```

**Questions:**
- Does it queue or batch crafts?
- Is there rate limiting?
- Do we get all items or just one?

---

**Test 7: Multi-profession queue simulation**
```lua
-- Simulate queue with mixed professions
local queue = {
    {spellId = alchemySpell, count = 2},
    {spellId = blacksmithSpell, count = 1},
    {spellId = alchemySpell2, count = 3},
}

for _, item in ipairs(queue) do
    Custom_DoProfessionRecipe(item.spellId, item.count)
    -- Wait between crafts?
end
```

---

## Code Changes Required

### 1. Queue Data Structure Changes
**File:** `SkilletStitch-1.1.lua`

**Current Queue Item:**
```lua
queue[i] = {
    profession = "Alchemy",
    index = 15,
    numcasts = 5,
    recipe = {name = "...", link = "..."}
}
```

**New Queue Item:**
```lua
queue[i] = {
    profession = "Alchemy",  -- Keep for compatibility
    index = 15,              -- Keep for compatibility
    spellId = 12345,         -- NEW: Primary identifier
    numcasts = 5,
    recipe = {
        name = "...",
        link = "...",
        spellId = 12345      -- Redundant but convenient
    }
}
```

**Migration Strategy:**
- Add spellId field to new queue items
- Keep old fields for backward compatibility
- During queue processing, prefer spellId if available

---

### 2. AddToQueue Modification
**File:** `SkilletStitch-1.1.lua` (approx line 1400)

**Current:**
```lua
function SkilletStitch:AddToQueue(index, count, profession, addToTop)
    local item = {
        ["profession"] = profession,
        ["index"] = index,
        ["numcasts"] = count,
    }
    -- Add to queue
end
```

**Modified:**
```lua
function SkilletStitch:AddToQueue(index, count, profession, addToTop, spellId)
    -- NEW: Get spell ID if not provided
    if not spellId and Custom_GetProfessionRecipeFromCraftedItem then
        -- Try to look up spell ID
        local recipe = self:GetItemDataByIndex(profession, index)
        if recipe and recipe.link then
            local itemId = tonumber(recipe.link:match("item:(%d+)"))
            if itemId then
                spellId = Custom_GetProfessionRecipeFromCraftedItem(itemId)
            end
        end
    end
    
    local item = {
        ["profession"] = profession,
        ["index"] = index,
        ["numcasts"] = count,
        ["spellId"] = spellId,  -- NEW
    }
    
    -- Add to queue
end
```

---

### 3. ProcessQueue Modification
**File:** `SkilletStitch-1.1.lua` (approx line 1130-1145)

**Current:**
```lua
function SkilletStitch:ProcessQueue()
    -- Lots of validation
    -- Eventually:
    DoTradeSkill(self.queue[1]["index"], self.queue[1]["numcasts"])
end
```

**Modified:**
```lua
function SkilletStitch:ProcessQueue()
    if #self.queue == 0 then return end
    
    local queueItem = self.queue[1]
    
    -- NEW: Try Custom_DoProfessionRecipe first if available
    if Custom_DoProfessionRecipe and queueItem.spellId then
        Skillet:DebugLog("Using Custom_DoProfessionRecipe for spell " .. queueItem.spellId)
        local success = Custom_DoProfessionRecipe(queueItem.spellId, queueItem.numcasts)
        
        if success then
            -- Craft initiated successfully
            -- Set up monitoring to detect completion
            return
        else
            -- Failed - fall back to traditional method
            Skillet:DebugLog("Custom_DoProfessionRecipe failed, falling back to DoTradeSkill")
        end
    end
    
    -- EXISTING: Traditional DoTradeSkill method
    -- Ensure correct profession window is open
    -- Call DoTradeSkill(index, numcasts)
end
```

---

### 4. Profession Window Management
**New File:** `ProfessionWindowManager.lua`

**Purpose:** Manage opening/closing profession windows only when needed

```lua
local WindowMgr = {}
Skillet.WindowMgr = WindowMgr

WindowMgr.currentProfession = nil
WindowMgr.needsWindow = false

-- Check if we need to open a profession window
function WindowMgr:IsWindowNeeded()
    -- If using Custom_DoProfessionRecipe, no window needed
    if Custom_DoProfessionRecipe then
        return false
    end
    return true
end

-- Open specific profession window
function WindowMgr:OpenProfession(professionName)
    if not self:IsWindowNeeded() then
        return true -- No window needed, success
    end
    
    -- Find and cast profession spell
    local spellId = Skillet.stitch:FindProfessionSpellId(professionName)
    if spellId then
        CastSpell(spellId, "spell")
        self.currentProfession = professionName
        return true
    end
    
    return false
end
```

---

### 5. Event Monitoring Updates
**File:** `Skillet.lua` (event handlers)

**Add New Events:**
```lua
-- If Custom_DoProfessionRecipe triggers different events
if Custom_DoProfessionRecipe then
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    self:RegisterEvent("UNIT_SPELLCAST_FAILED")
end

-- Handle new events
function Skillet:UNIT_SPELLCAST_SUCCEEDED(unit, ...)
    if unit ~= "player" then return end
    
    -- Check if this was a profession craft
    local spellId = select(3, ...)
    if self:IsQueuedSpell(spellId) then
        -- Crafting succeeded, update queue
        self:OnCraftSucceeded(spellId)
    end
end
```

---

### 6. Queue UI Updates
**File:** `UI/QueueFrame.lua`

**Add Indicator:**
```lua
-- Show which method will be used for crafting
local methodText = queueFrame:CreateFontString()
if queueItem.spellId and Custom_DoProfessionRecipe then
    methodText:SetText("(Spell-Based)")
    methodText:SetTextColor(0, 1, 0) -- Green
else
    methodText:SetText("(Index-Based)")
    methodText:SetTextColor(1, 1, 0) -- Yellow
end
```

---

## Implementation Plan

### Step 1: Testing & Validation (4-6 hours)
1. Run all functionality tests
2. Document Custom_DoProfessionRecipe behavior
3. Identify limitations and edge cases
4. Create test report

### Step 2: Data Structure Updates (2-3 hours)
1. Add spellId field to queue items
2. Update AddToQueue signature
3. Add spell ID lookup functions
4. Test backward compatibility

### Step 3: ProcessQueue Refactoring (4-5 hours)
1. Implement spell-based crafting path
2. Add fallback logic
3. Update event monitoring
4. Test both code paths

### Step 4: Window Management (3-4 hours)
1. Create WindowManager module
2. Implement smart window opening
3. Test window-free operation
4. Handle edge cases

### Step 5: UI & Polish (2-3 hours)
1. Add visual indicators
2. Update tooltips
3. Add debug logging
4. Performance optimization

**Total Estimated Time:** 15-21 hours

---

## Risks & Mitigations

### Risk 1: Custom_DoProfessionRecipe Doesn't Work as Expected
**Scenarios:**
- Requires window open anyway
- Only works for certain professions
- Has undocumented limitations

**Mitigation:**
- Thorough testing phase before implementation
- Keep fallback to DoTradeSkill
- Feature flag to disable if issues found

### Risk 2: Event Handling Changes
**Scenario:** Different events triggered, breaking completion detection

**Mitigation:**
- Monitor all events during testing
- Implement multiple completion detection methods
- Timeout-based fallback

### Risk 3: Queue Corruption
**Scenario:** Spell IDs don't match recipes, queue breaks

**Mitigation:**
- Validate spell IDs before adding to queue
- Add recovery mechanism
- Allow manual queue editing

---

## Success Criteria

✅ **Must Have:**
1. Queue processes using Custom_DoProfessionRecipe when available
2. Fallback to DoTradeSkill works correctly
3. No loss of existing functionality
4. Spell IDs correctly mapped to recipes

✅ **Nice to Have:**
1. No profession window opening required
2. Faster queue processing
3. Multi-profession queue support
4. Better error handling

---

## Testing Checklist

Before merging:
- [ ] Spell-based crafting works without window
- [ ] Fallback to index-based works
- [ ] Events properly detected
- [ ] Queue saves/loads correctly with spell IDs
- [ ] Error cases handled gracefully
- [ ] Performance acceptable
- [ ] Works with all professions
- [ ] Cooldowns handled correctly
- [ ] No crashes or disconnects
- [ ] Backward compatible with old queues

---

## Future Enhancements

1. Parallel crafting from multiple professions
2. Optimize craft order across professions
3. Intelligent window management (minimize opens)
4. Batch crafting improvements
5. Better progress indicators
