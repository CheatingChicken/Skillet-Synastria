# Attunement-Aware Crafting & Recipe Filtering

## Overview
Integrate forge level (attunement) requirements into recipe displays, queue processing, and shopping lists.

## Current State
- No visibility into forge level requirements
- Can queue items that cannot be crafted due to low attunement
- Shopping list doesn't warn about forge restrictions
- Manual checking against forge NPCs

## Desired State
- Display forge level for all recipes requiring attunement
- Prevent queueing impossible recipes
- Warn when materials are ready but forge level insufficient
- Track player's current attunement levels
- Filter recipes by available forges

---

## Testing Requirements

### Phase 1: Attunement Data Validation

**Test 1: Get recipe forge requirements**
```lua
-- Test Custom_GetProfessionRecipeAttunement
local testRecipes = {
    [12345] = "Basic Recipe (no attunement)",
    [12346] = "Advanced Recipe (Forge 1)",
    [12347] = "Master Recipe (Forge 3)",
}

for spellId, name in pairs(testRecipes) do
    local hasAttune, attuneLevel = Custom_GetProfessionRecipeAttunement(spellId)
    
    if hasAttune then
        print(name .. " requires Forge Level " .. attuneLevel)
    else
        print(name .. " has NO attunement requirement")
    end
end
```

**Questions:**
- Does it return correct levels?
- What about recipes with no attunement (nil or false)?

---

**Test 2: Player attunement levels**
```lua
-- Test Custom_GetPlayerAttunement
local professions = {
    [171] = "Alchemy",
    [164] = "Blacksmithing",
    [202] = "Engineering",
}

for skillId, profName in pairs(professions) do
    local hasAttune, attuneLevel = Custom_GetPlayerAttunement(skillId)
    
    if hasAttune then
        print(profName .. " attunement: Level " .. attuneLevel)
    else
        print(profName .. " attunement: NONE (level 0)")
    end
end
```

**Expected:** ✅ Returns player's current forge levels for each profession

---

### Phase 2: Recipe Filtering

**Test 3: Filter recipes by attunement**
```lua
-- Can we craft this recipe based on attunement?
function CanCraftWithAttunement(spellId)
    local skillId = Custom_GetProfessionRecipeInfo(spellId)
    if not skillId then return false end
    
    local recipeHasAttune, recipeLevel = Custom_GetProfessionRecipeAttunement(spellId)
    local playerHasAttune, playerLevel = Custom_GetPlayerAttunement(skillId)
    
    if not recipeHasAttune then
        -- No attunement needed
        return true
    end
    
    -- Check if player level is sufficient
    playerLevel = playerLevel or 0
    return playerLevel >= recipeLevel
end

-- Test with various recipes
local recipes = Custom_GetProfessionRecipes(171) -- Alchemy
for _, spellId in ipairs(recipes) do
    local canCraft = CanCraftWithAttunement(spellId)
    local _, name = Custom_GetProfessionRecipeInfo(spellId)
    print(name .. ": " .. (canCraft and "CAN CRAFT" or "BLOCKED"))
end
```

**Expected:** ✅ Correctly identifies blocked vs available recipes

---

### Phase 3: Queue Validation

**Test 4: Queue attunement warnings**
```lua
-- Add recipe to queue that requires higher forge level
/script -- Open tradeskill
/script -- Find recipe requiring Forge 3
/script -- Player only has Forge 1
/script Skillet:QueueItems() -- Try to queue it

-- Should we:
-- A) Allow queueing but warn?
-- B) Block queueing entirely?
-- C) Allow queueing with "disabled" status?
```

**Decision:** Probably allow queueing but show warning and disable processing until attunement met

---

## Code Changes Required

### 1. Recipe Data Enhancement
**File:** `SkilletStitch-1.1.lua`

```lua
-- Enhance GetItemDataByIndex to include attunement
function SkilletStitch:GetItemDataByIndex(profession, index)
    local data = self:GetRecipeDataUncached(profession, index)
    
    -- EXISTING: Get basic recipe data
    
    -- NEW: Add attunement data if available
    if Custom_GetProfessionRecipeAttunement and data.spellId then
        local hasAttune, attuneLevel = Custom_GetProfessionRecipeAttunement(data.spellId)
        data.requiresAttunement = hasAttune or false
        data.attunementLevel = attuneLevel or 0
        
        -- Check if player can craft
        if hasAttune then
            local skillId = select(1, Custom_GetProfessionRecipeInfo(data.spellId))
            local playerHasAttune, playerLevel = Custom_GetPlayerAttunement(skillId)
            data.playerAttunementLevel = playerLevel or 0
            data.canCraftAttunement = (playerLevel or 0) >= attuneLevel
        else
            data.canCraftAttunement = true -- No attunement needed
        end
    end
    
    return data
end
```

---

### 2. New Module: AttunementManager.lua
**File:** `Skillet - Synastria/AttunementManager.lua`

```lua
local Attune = {}
Skillet.Attune = Attune

-- Cache player attunement levels
Attune.cache = {
    lastUpdate = 0,
    levels = {} -- [skillId] = level
}

function Attune:GetPlayerLevel(skillId)
    -- Update cache every 5 minutes
    if GetTime() - self.cache.lastUpdate > 300 then
        self:RefreshCache()
    end
    
    return self.cache.levels[skillId] or 0
end

function Attune:RefreshCache()
    if not Custom_GetPlayerAttunement then return end
    
    local professions = {171, 164, 333, 202, 755, 165, 197, 185, 129}
    
    for _, skillId in ipairs(professions) do
        local hasAttune, level = Custom_GetPlayerAttunement(skillId)
        self.cache.levels[skillId] = level or 0
    end
    
    self.cache.lastUpdate = GetTime()
end

function Attune:GetRecipeRequirement(spellId)
    if not Custom_GetProfessionRecipeAttunement then
        return false, 0
    end
    
    local hasAttune, level = Custom_GetProfessionRecipeAttunement(spellId)
    return hasAttune or false, level or 0
end

function Attune:CanCraftRecipe(spellId)
    local hasAttune, requiredLevel = self:GetRecipeRequirement(spellId)
    
    if not hasAttune then
        return true -- No attunement needed
    end
    
    local skillId = select(1, Custom_GetProfessionRecipeInfo(spellId))
    if not skillId then return false end
    
    local playerLevel = self:GetPlayerLevel(skillId)
    
    return playerLevel >= requiredLevel
end

function Attune:GetBlockReason(spellId)
    local hasAttune, requiredLevel = self:GetRecipeRequirement(spellId)
    
    if not hasAttune then
        return nil -- Not blocked
    end
    
    local skillId = select(1, Custom_GetProfessionRecipeInfo(spellId))
    if not skillId then return "Unknown profession" end
    
    local playerLevel = self:GetPlayerLevel(skillId)
    
    if playerLevel < requiredLevel then
        return string.format(
            "Requires Forge Level %d (you have %d)",
            requiredLevel,
            playerLevel
        )
    end
    
    return nil -- Not blocked
end

-- Get all forge NPCs and their levels
function Attune:GetForgeLocations()
    -- This would need to be manually maintained or loaded from data file
    return {
        [1] = {
            name = "Basic Forge",
            level = 1,
            locations = {
                {zone = "Ironforge", npc = "Forge Master Bob"},
                {zone = "Orgrimmar", npc = "Forge Master Grog"},
            }
        },
        [2] = {
            name = "Advanced Forge",
            level = 2,
            locations = {
                {zone = "Dalaran", npc = "Master Smith"},
            }
        },
        -- etc
    }
end
```

---

### 3. Queue Validation
**File:** `SkilletStitch-1.1.lua`

```lua
function SkilletStitch:AddToQueue(index, count, profession, addToTop, spellId)
    -- Get full recipe info
    local recipe = self:GetItemDataByIndex(profession, index)
    if not recipe then return end
    
    -- NEW: Check attunement
    if Skillet.Attune and spellId then
        local canCraft = Skillet.Attune:CanCraftRecipe(spellId)
        local blockReason = Skillet.Attune:GetBlockReason(spellId)
        
        if blockReason then
            -- Warn but allow queueing
            Skillet:Print("Warning: " .. recipe.name .. " - " .. blockReason)
        end
        
        recipe.attunementBlocked = not canCraft
        recipe.attunementReason = blockReason
    end
    
    -- Continue with normal queue logic
    local queueItem = {
        profession = profession,
        index = index,
        numcasts = count,
        spellId = spellId,
        recipe = recipe,
        blocked = recipe.attunementBlocked or false,
        blockReason = recipe.attunementReason
    }
    
    -- Add to queue
    if addToTop then
        table.insert(self.queue, 1, queueItem)
    else
        table.insert(self.queue, queueItem)
    end
end
```

---

### 4. Queue Processing Skip
**File:** `SkilletStitch-1.1.lua`

```lua
function SkilletStitch:ProcessQueue()
    if #self.queue == 0 then return end
    
    local queueItem = self.queue[1]
    
    -- NEW: Skip blocked items
    if queueItem.blocked then
        Skillet:Print("Skipping " .. queueItem.recipe.name .. " - " .. (queueItem.blockReason or "Blocked"))
        
        -- Option 1: Move to end of queue
        table.remove(self.queue, 1)
        table.insert(self.queue, queueItem)
        
        -- Option 2: Remove entirely
        -- table.remove(self.queue, 1)
        
        -- Try next item
        self:ProcessQueue()
        return
    end
    
    -- Continue with normal processing
end
```

---

### 5. UI: Recipe List Coloring
**File:** `UI/RecipeList.lua`

```lua
function Skillet:UpdateRecipeRow(row, recipe)
    -- EXISTING: Set name, icon, etc.
    
    -- NEW: Color code based on attunement
    if recipe.requiresAttunement then
        if not recipe.canCraftAttunement then
            -- Blocked by attunement - gray out
            row.name:SetTextColor(0.5, 0.5, 0.5)
            
            -- Add forge icon
            if not row.forgeIcon then
                row.forgeIcon = row:CreateTexture()
                row.forgeIcon:SetSize(16, 16)
                row.forgeIcon:SetPoint("RIGHT", row, "RIGHT", -5, 0)
            end
            
            row.forgeIcon:SetTexture("Interface\\Icons\\INV_Misc_EngGizmos_30") -- Forge icon
            row.forgeIcon:Show()
            
            -- Tooltip
            row:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine(recipe.name)
                GameTooltip:AddLine(
                    string.format(
                        "|cffff0000Requires Forge Level %d|r",
                        recipe.attunementLevel
                    ),
                    1, 1, 1
                )
                GameTooltip:AddLine(
                    string.format(
                        "Your level: %d",
                        recipe.playerAttunementLevel
                    ),
                    0.5, 0.5, 0.5
                )
                GameTooltip:Show()
            end)
        else
            -- Can craft - show forge level indicator
            if recipe.attunementLevel > 0 then
                if not row.forgeBadge then
                    row.forgeBadge = row:CreateFontString()
                    row.forgeBadge:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
                    row.forgeBadge:SetPoint("RIGHT", row, "RIGHT", -5, 0)
                end
                
                row.forgeBadge:SetText("[F" .. recipe.attunementLevel .. "]")
                row.forgeBadge:SetTextColor(1, 0.82, 0) -- Gold
                row.forgeBadge:Show()
            end
        end
    end
end
```

---

### 6. UI: Attunement Status Window
**File:** `UI/AttunementFrame.lua`

```lua
-- New window showing all attunement levels
local AttuneFrame = CreateFrame("Frame", "SkilletAttunementFrame", UIParent)
AttuneFrame:SetSize(300, 400)
AttuneFrame:SetPoint("CENTER")
AttuneFrame:Hide()

function AttuneFrame:Update()
    -- Clear existing
    
    local y = -30
    local professions = {
        [171] = "Alchemy",
        [164] = "Blacksmithing",
        [333] = "Enchanting",
        [202] = "Engineering",
        [755] = "Jewelcrafting",
        [165] = "Leatherworking",
        [197] = "Tailoring",
    }
    
    for skillId, profName in pairs(professions) do
        local level = Skillet.Attune:GetPlayerLevel(skillId)
        
        -- Create row
        local row = CreateFrame("Frame", nil, self)
        row:SetSize(280, 30)
        row:SetPoint("TOPLEFT", 10, y)
        
        -- Icon
        local icon = row:CreateTexture()
        icon:SetSize(24, 24)
        icon:SetPoint("LEFT")
        icon:SetTexture(GetSpellTexture(skillId))
        
        -- Name
        local name = row:CreateFontString()
        name:SetFont("Fonts\\FRIZQT__.TTF", 12)
        name:SetPoint("LEFT", icon, "RIGHT", 5, 0)
        name:SetText(profName)
        
        -- Level
        local levelText = row:CreateFontString()
        levelText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
        levelText:SetPoint("RIGHT")
        levelText:SetText("Level " .. level)
        
        if level >= 3 then
            levelText:SetTextColor(0, 1, 0) -- Green
        elseif level >= 1 then
            levelText:SetTextColor(1, 0.82, 0) -- Gold
        else
            levelText:SetTextColor(0.5, 0.5, 0.5) -- Gray
        end
        
        y = y - 35
    end
    
    -- Add "Find Forge" button
    local findButton = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
    findButton:SetSize(120, 25)
    findButton:SetPoint("BOTTOM", 0, 10)
    findButton:SetText("Find Forges")
    findButton:SetScript("OnClick", function()
        Skillet.Attune:ShowForgeLocations()
    end)
end

function Skillet.Attune:ShowForgeLocations()
    -- Display list of forge NPCs and their locations
    local forges = self:GetForgeLocations()
    
    -- Create simple list window
    local frame = CreateFrame("Frame", "SkilletForgeLocations", UIParent, "BasicFrameTemplate")
    frame:SetSize(400, 500)
    frame:SetPoint("CENTER")
    
    -- Populate with forge data
    -- ... create scrolling list of forges
end
```

---

### 7. Shopping List Warning
**File:** `UI/ShoppingList.lua`

```lua
function Skillet:UpdateShoppingList()
    -- EXISTING: Get reagents
    
    -- NEW: Check if any queue items are blocked
    local blockedItems = {}
    for _, queueItem in ipairs(queue) do
        if queueItem.blocked then
            table.insert(blockedItems, queueItem)
        end
    end
    
    if #blockedItems > 0 then
        -- Add warning section at top
        local warning = CreateFrame("Frame", nil, shoppingFrame)
        warning:SetSize(shoppingFrame:GetWidth() - 20, 80)
        warning:SetPoint("TOP", 0, -10)
        
        local bg = warning:CreateTexture()
        bg:SetAllPoints()
        bg:SetColorTexture(0.8, 0.2, 0.2, 0.3) -- Red tint
        
        local text = warning:CreateFontString()
        text:SetFont("Fonts\\FRIZQT__.TTF", 11)
        text:SetPoint("CENTER")
        text:SetText(
            string.format(
                "|cffff0000Warning:|r %d items in queue blocked by attunement\n" ..
                "You have materials but cannot craft yet",
                #blockedItems
            )
        )
        text:SetJustifyH("CENTER")
        
        local viewButton = CreateFrame("Button", nil, warning, "UIPanelButtonTemplate")
        viewButton:SetSize(100, 20)
        viewButton:SetPoint("BOTTOM", 0, 5)
        viewButton:SetText("View Details")
        viewButton:SetScript("OnClick", function()
            AttuneFrame:Show()
            AttuneFrame:Update()
        end)
    end
    
    -- EXISTING: Display shopping list
end
```

---

## Implementation Plan

### Step 1: Attunement Manager (3-4 hours)
1. Create AttunementManager.lua
2. Implement caching system
3. Add recipe checking functions
4. Test API behavior

### Step 2: Recipe Integration (2-3 hours)
1. Enhance GetItemDataByIndex
2. Add attunement data to recipes
3. Test data accuracy

### Step 3: Queue Integration (2-3 hours)
1. Add validation to AddToQueue
2. Update ProcessQueue
3. Test blocking/skipping

### Step 4: UI Updates (4-6 hours)
1. Recipe list coloring
2. Attunement status window
3. Forge location finder
4. Shopping list warnings

### Step 5: Testing & Polish (2-3 hours)
1. Comprehensive testing
2. Edge cases
3. Visual polish

**Total Estimated Time:** 13-19 hours

---

## Success Criteria

✅ **Must Have:**
1. Display forge requirements on recipes
2. Prevent processing blocked items
3. Accurate attunement detection
4. No crashes

✅ **Nice to Have:**
1. Attunement status window
2. Forge location finder
3. Shopping list warnings
4. Visual indicators

---

## Future Enhancements

1. Attunement leveling guide
2. Track attunement progress
3. Suggest recipes to level attunement
4. Export/share attunement status
5. Attunement reminder notifications
