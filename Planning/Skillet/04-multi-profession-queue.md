# Multi-Profession Queue System

## Overview
Enable queueing and processing items from multiple professions in a single unified queue, eliminating profession switching overhead.

## Current State
- Queue is profession-agnostic in storage (unified queue)
- But processing requires correct profession window to be open
- Queue items store profession + index (window-dependent)
- User must manually switch professions during processing

## Desired State
- Queue items from any profession at any time
- Process queue intelligently across professions
- Minimize profession window switches
- Optimize craft order for efficiency

---

## Testing Requirements

### Phase 1: Queue Storage & Retrieval

**Test 1: Mixed profession queue**
```lua
-- Add items from multiple professions to queue
/script -- Open Alchemy
/script Skillet:QueueItems() -- Add 5x Health Potion
/script -- Open Blacksmithing
/script Skillet:QueueItems() -- Add 3x Iron Sword
/script -- Open Tailoring  
/script Skillet:QueueItems() -- Add 2x Linen Bag

/script -- Check queue contents
/script for i, item in ipairs(Skillet.stitch.queue) do
    print(i .. ": " .. item.recipe.name .. " (Prof: " .. item.profession .. ")")
end
```

**Expected:** ✅ Queue contains items from all three professions in order added

---

**Test 2: Queue persistence**
```lua
-- Create mixed queue, reload UI
/script -- Build mixed queue
/script ReloadUI()
-- After reload:
/script -- Check queue still has all items
```

**Expected:** ✅ Queue survives reload with all profession data intact

---

### Phase 2: Spell ID Conversion

**Test 3: Convert queue items to spell IDs**
```lua
-- For each queue item, try to get spell ID
function ConvertQueueToSpellIds()
    for i, queueItem in ipairs(Skillet.stitch.queue) do
        local recipe = Skillet.stitch:GetItemDataByIndex(
            queueItem.profession, 
            queueItem.index
        )
        
        if recipe and recipe.link then
            local itemId = tonumber(recipe.link:match("item:(%d+)"))
            if itemId then
                local spellId = Custom_GetProfessionRecipeFromCraftedItem(itemId)
                if spellId then
                    print("Item " .. i .. ": " .. recipe.name .. " = Spell " .. spellId)
                    queueItem.spellId = spellId
                else
                    print("Item " .. i .. ": NO SPELL ID FOUND")
                end
            end
        end
    end
end

/script ConvertQueueToSpellIds()
```

**Questions:**
- Do ALL queue items get spell IDs?
- Are spell IDs stable across sessions?
- What about enchants/non-item recipes?

---

### Phase 3: Processing Mixed Queue

**Test 4: Process without window switching**
```lua
-- If Custom_DoProfessionRecipe works:
/script -- Create mixed queue
/script -- Start processing
/script Skillet:ProcessQueue()
-- Monitor: Does it craft from all professions?
```

**Expected (best case):** ✅ All items craft without opening windows  
**Expected (realistic):** ⚠️ May need to open first profession window

---

**Test 5: Intelligent profession switching**
```lua
-- Queue: Alchemy, Alchemy, Blacksmith, Alchemy, Blacksmith
-- Optimal order: Alchemy x3, Blacksmith x2
-- Test reordering

function OptimizeQueueByProfession()
    local byProf = {}
    
    for _, item in ipairs(queue) do
        local prof = item.profession
        if not byProf[prof] then
            byProf[prof] = {}
        end
        table.insert(byProf[prof], item)
    end
    
    -- Rebuild queue profession by profession
    local newQueue = {}
    for prof, items in pairs(byProf) do
        for _, item in ipairs(items) do
            table.insert(newQueue, item)
        end
    end
    
    return newQueue
end
```

---

## Code Changes Required

### 1. Queue Item Enhancement
**File:** `SkilletStitch-1.1.lua`

**Current Structure:**
```lua
queue[i] = {
    profession = "Alchemy",
    index = 15,
    numcasts = 5,
    recipe = {name = "...", link = "..."}
}
```

**Enhanced Structure:**
```lua
queue[i] = {
    profession = "Alchemy",  -- Keep for display/fallback
    index = 15,              -- Keep for fallback
    spellId = 12345,         -- NEW: Primary identifier
    numcasts = 5,
    recipe = {
        name = "Health Potion",
        link = "|cff...",
        spellId = 12345,
        skillId = 171,       -- NEW: Profession skill ID
        itemId = 858         -- NEW: Created item ID
    }
}
```

---

### 2. Enhanced AddToQueue
**File:** `SkilletStitch-1.1.lua`

```lua
function SkilletStitch:AddToQueue(index, count, profession, addToTop, spellId)
    -- Get full recipe info
    local recipe = self:GetItemDataByIndex(profession, index)
    if not recipe then return end
    
    -- Enhance recipe with additional data
    if Custom_GetProfessionRecipeInfo and not spellId then
        -- Try to get spell ID from item ID
        local itemId = tonumber(recipe.link:match("item:(%d+)"))
        if itemId then
            spellId = Custom_GetProfessionRecipeFromCraftedItem(itemId)
        end
    end
    
    -- If we have spell ID, get full profession info
    local skillId, itemId, professionName
    if spellId and Custom_GetProfessionRecipeInfo then
        skillId, _, itemId = Custom_GetProfessionRecipeInfo(spellId)
        professionName = self:GetProfessionNameFromSkillId(skillId)
    end
    
    local queueItem = {
        profession = profession,
        index = index,
        numcasts = count,
        spellId = spellId,
        recipe = {
            name = recipe.name,
            link = recipe.link,
            spellId = spellId,
            skillId = skillId,
            itemId = itemId
        }
    }
    
    -- Add to queue
    if addToTop then
        table.insert(self.queue, 1, queueItem)
    else
        table.insert(self.queue, queueItem)
    end
end

-- Helper function
function SkilletStitch:GetProfessionNameFromSkillId(skillId)
    local map = {
        [171] = "Alchemy",
        [164] = "Blacksmithing",
        [333] = "Enchanting",
        [202] = "Engineering",
        [755] = "Jewelcrafting",
        [165] = "Leatherworking",
        [197] = "Tailoring",
        [185] = "Cooking",
        [129] = "First Aid",
    }
    return map[skillId]
end
```

---

### 3. Smart Queue Processor
**File:** `SkilletStitch-1.1.lua`

```lua
function SkilletStitch:ProcessQueue()
    if #self.queue == 0 then return end
    
    local queueItem = self.queue[1]
    
    -- Strategy 1: Try spell-based crafting (no window needed)
    if Custom_DoProfessionRecipe and queueItem.spellId then
        local success = self:ProcessQueueItemBySpell(queueItem)
        if success then return end
        
        -- Failed - try fallback methods
    end
    
    -- Strategy 2: Ensure correct profession window open
    local currentProf = GetTradeSkillLine()
    if currentProf ~= queueItem.profession then
        -- Need to switch professions
        if not self:OpenProfessionWindow(queueItem.profession) then
            Skillet:Print("Failed to open " .. queueItem.profession .. " window")
            return
        end
        
        -- Wait for window to open
        C_Timer.After(0.5, function()
            self:ProcessQueue() -- Retry
        end)
        return
    end
    
    -- Strategy 3: Traditional index-based crafting
    DoTradeSkill(queueItem.index, queueItem.numcasts)
end

function SkilletStitch:ProcessQueueItemBySpell(queueItem)
    if not Custom_DoProfessionRecipe or not queueItem.spellId then
        return false
    end
    
    local result = Custom_DoProfessionRecipe(queueItem.spellId, queueItem.numcasts)
    
    if result then
        -- Success - set up completion monitoring
        self.craftingSpellId = queueItem.spellId
        self.craftingCount = queueItem.numcasts
        return true
    end
    
    return false
end

function SkilletStitch:OpenProfessionWindow(professionName)
    -- Find profession spell
    local spellIds = {
        Alchemy = {51304, 28596, 11611, 3464, 3101, 2259},
        Blacksmithing = {51300, 29844, 9785, 3538, 3100, 2018},
        -- ... etc
    }
    
    local ids = spellIds[professionName]
    if not ids then return false end
    
    for _, spellId in ipairs(ids) do
        if IsSpellKnown(spellId) then
            CastSpell(spellId, "spell")
            return true
        end
    end
    
    return false
end
```

---

### 4. Queue Optimizer
**New File:** `QueueOptimizer.lua`

```lua
local QueueOpt = {}
Skillet.QueueOpt = QueueOpt

-- Reorder queue to minimize profession switching
function QueueOpt:OptimizeByProfession(queue)
    local byProf = {}
    local order = {} -- Track original order of professions
    
    -- Group by profession
    for _, item in ipairs(queue) do
        local prof = item.profession or "Unknown"
        if not byProf[prof] then
            byProf[prof] = {}
            table.insert(order, prof)
        end
        table.insert(byProf[prof], item)
    end
    
    -- Rebuild queue profession by profession
    local optimized = {}
    for _, prof in ipairs(order) do
        for _, item in ipairs(byProf[prof]) do
            table.insert(optimized, item)
        end
    end
    
    return optimized
end

-- Reorder by material availability
function QueueOpt:OptimizeByMaterials(queue)
    -- Sort items: craftable now first, then by material availability
    local sorted = {}
    for _, item in ipairs(queue) do
        table.insert(sorted, item)
    end
    
    table.sort(sorted, function(a, b)
        local aCanCraft = self:CanCraftNow(a)
        local bCanCraft = self:CanCraftNow(b)
        
        if aCanCraft ~= bCanCraft then
            return aCanCraft -- Craftable items first
        end
        
        -- Both craftable or both not - sort by profession to minimize switches
        return (a.profession or "") < (b.profession or "")
    end)
    
    return sorted
end

function QueueOpt:CanCraftNow(queueItem)
    if not queueItem.spellId then return false end
    
    local _, _, _, _, canCraft = Custom_GetProfessionRecipeInfo(queueItem.spellId)
    return canCraft and canCraft > 0
end
```

---

### 5. Queue UI Enhancements
**File:** `UI/QueueFrame.lua`

```lua
-- Add profession grouping headers
function Skillet:UpdateQueueDisplay()
    local currentProf = nil
    local index = 1
    
    for i, queueItem in ipairs(queue) do
        -- Add profession header when profession changes
        if queueItem.profession ~= currentProf then
            currentProf = queueItem.profession
            
            -- Create header
            local header = CreateFrame("Frame", nil, scrollFrame)
            header:SetHeight(20)
            
            local headerText = header:CreateFontString()
            headerText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
            headerText:SetText("--- " .. currentProf .. " ---")
            headerText:SetTextColor(1, 0.82, 0) -- Gold
            
            -- Add to display
        end
        
        -- Create normal queue item row
        self:CreateQueueItemRow(queueItem, index)
        index = index + 1
    end
end

-- Add optimize button
local optimizeButton = CreateFrame("Button", nil, queueFrame, "UIPanelButtonTemplate")
optimizeButton:SetText("Optimize Queue")
optimizeButton:SetScript("OnClick", function()
    local optimized = Skillet.QueueOpt:OptimizeByProfession(Skillet.stitch.queue)
    Skillet.stitch.queue = optimized
    Skillet:UpdateQueueDisplay()
    Skillet:SaveQueue(Skillet.db.server.queues, Skillet.currentTrade)
end)
```

---

### 6. Profession Indicator
**File:** `UI/MainFrame.lua`

```lua
-- Show which professions are in queue
function Skillet:UpdateProfessionIndicators()
    local profCounts = {}
    
    for _, item in ipairs(queue) do
        local prof = item.profession or "Unknown"
        profCounts[prof] = (profCounts[prof] or 0) + 1
    end
    
    -- Display badges
    local y = 0
    for prof, count in pairs(profCounts) do
        local badge = CreateFrame("Frame", nil, queueFrame)
        badge:SetSize(120, 20)
        badge:SetPoint("TOPRIGHT", -10, -y)
        
        local text = badge:CreateFontString()
        text:SetFont("Fonts\\FRIZQT__.TTF", 10)
        text:SetText(prof .. ": " .. count)
        
        local icon = self:GetProfessionIcon(prof)
        -- Draw icon
        
        y = y + 25
    end
end
```

---

## Implementation Plan

### Step 1: Queue Enhancement (3-4 hours)
1. Add spellId and additional fields to queue items
2. Update AddToQueue
3. Test queue persistence
4. Backward compatibility testing

### Step 2: Smart Processing (4-6 hours)
1. Implement spell-based processing
2. Add profession switching logic
3. Test with mixed queue
4. Event handling updates

### Step 3: Queue Optimizer (3-4 hours)
1. Create QueueOptimizer module
2. Implement optimization algorithms
3. Add UI controls
4. Testing

### Step 4: UI Updates (3-4 hours)
1. Add profession headers
2. Add optimization button
3. Add profession indicators
4. Visual polish

**Total Estimated Time:** 13-18 hours

---

## Success Criteria

✅ **Must Have:**
1. Queue items from multiple professions
2. Process mixed queue correctly
3. No loss of queue items
4. Profession switching works

✅ **Nice to Have:**
1. No profession window switching needed
2. Queue optimization works
3. Visual profession grouping
4. Smart craft order

---

## Future Enhancements

1. Priority system (urgent items first)
2. Parallel queue processing
3. "Craft while waiting" for cooldowns
4. Auto-craft on material acquisition
5. Schedule crafting (craft at specific times)
