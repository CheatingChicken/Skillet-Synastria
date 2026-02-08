# Recipe Discovery & Learning System

## Overview
Track which recipes the player knows, discovers, and learns across all professions, providing guidance on recipe completion and discovery paths.

## Current State
- Only sees recipes when profession window is open
- No tracking of unlearned recipes
- No visibility into how to obtain missing recipes
- Manual tracking of recipe completion

## Desired State
- Database of ALL profession recipes (learned and unlearned)
- Track player's recipe learning progress
- Show how to obtain each recipe (vendor, drop, quest, trainer)
- Guide for completing recipe collections
- Achievement tracking integration

---

## Testing Requirements

### Phase 1: Complete Recipe Database

**Test 1: Get all recipes for profession**
```lua
-- Test Custom_GetProfessionRecipes with -1 (all professions)
/script local allRecipes = Custom_GetProfessionRecipes(-1)
/script print("Total recipes across all professions: " .. #allRecipes)

-- Get breakdown by profession
/script local byProf = {}
/script for _, spellId in ipairs(allRecipes) do
    local skillId = Custom_GetProfessionRecipeInfo(spellId)
    byProf[skillId] = (byProf[skillId] or 0) + 1
end
/script for skillId, count in pairs(byProf) do
    print("Profession " .. skillId .. ": " .. count .. " recipes")
end
```

**Expected:** ✅ Returns comprehensive list of all recipes in game

---

**Test 2: Compare known vs unknown**
```lua
-- Open Alchemy window
/script local knownRecipes = {}
/script for i = 1, GetNumTradeSkills() do
    local link = GetTradeSkillItemLink(i)
    if link then
        local itemId = tonumber(link:match("item:(%d+)"))
        if itemId then
            local spellId = Custom_GetProfessionRecipeFromCraftedItem(itemId)
            if spellId then
                knownRecipes[spellId] = true
            end
        end
    end
end

/script local allAlchemy = Custom_GetProfessionRecipes(171)
/script local unknown = 0
/script for _, spellId in ipairs(allAlchemy) do
    if not knownRecipes[spellId] then
        unknown = unknown + 1
    end
end
/script print("Unknown Alchemy recipes: " .. unknown .. "/" .. #allAlchemy)
```

**Expected:** ✅ Accurate count of missing recipes

---

### Phase 2: Recipe Source Data

**Test 3: Recipe acquisition methods**
```lua
-- This data needs to be compiled manually or from external database
-- Custom APIs don't provide source information
-- Would need to maintain our own database

local recipeSources = {
    [12345] = {
        type = "Trainer",
        location = "Alchemy Trainer - Stormwind",
        cost = 50000, -- copper
    },
    [12346] = {
        type = "Drop",
        source = "Molten Core Trash",
        dropRate = 0.5,
    },
    [12347] = {
        type = "Quest",
        quest = "The Master Alchemist",
        faction = "Alliance",
    },
}
```

**Note:** This would require significant data compilation work

---

### Phase 3: Learning Detection

**Test 4: Detect when recipe is learned**
```lua
-- Register for events
/script local f = CreateFrame("Frame")
/script f:RegisterEvent("NEW_RECIPE_LEARNED")
/script f:SetScript("OnEvent", function(self, event, recipeId, recipeLevel)
    print("Learned recipe: " .. recipeId)
    
    -- Update our database
    if Skillet.RecipeDB then
        Skillet.RecipeDB:MarkLearned(recipeId)
    end
end)
```

**Expected:** ✅ Event fires when recipe learned, provides recipe ID

---

## Code Changes Required

### 1. Recipe Database Module
**New File:** `RecipeDatabase.lua`

```lua
local RecipeDB = {}
Skillet.RecipeDB = RecipeDB

-- Persistent storage (saved variables)
SkilletRecipeDBData = SkilletRecipeDBData or {
    recipes = {},           -- [spellId] = {full recipe data}
    playerKnown = {},       -- [spellId] = true/false
    lastScan = 0,
    version = 1,
}

function RecipeDB:Initialize()
    -- Scan all professions on first load or when version changes
    if not SkilletRecipeDBData.lastScan or SkilletRecipeDBData.version < 1 then
        self:FullScan()
    end
    
    -- Register for learning events
    self.frame = CreateFrame("Frame")
    self.frame:RegisterEvent("NEW_RECIPE_LEARNED")
    self.frame:RegisterEvent("TRADE_SKILL_SHOW")
    self.frame:SetScript("OnEvent", function(self, event, ...)
        RecipeDB:OnEvent(event, ...)
    end)
end

function RecipeDB:FullScan()
    if not Custom_GetProfessionRecipes then
        Skillet:Print("Cannot scan recipes - custom API not available")
        return
    end
    
    Skillet:Print("Scanning all profession recipes...")
    
    local allRecipes = Custom_GetProfessionRecipes(-1)
    local count = 0
    
    for _, spellId in ipairs(allRecipes) do
        local skillId, name, itemId, minSkill, canCraft = Custom_GetProfessionRecipeInfo(spellId)
        
        if skillId and name then
            SkilletRecipeDBData.recipes[spellId] = {
                spellId = spellId,
                skillId = skillId,
                name = name,
                itemId = itemId,
                minSkill = minSkill,
                profession = self:GetProfessionName(skillId),
            }
            
            -- Check attunement
            if Custom_GetProfessionRecipeAttunement then
                local hasAttune, level = Custom_GetProfessionRecipeAttunement(spellId)
                SkilletRecipeDBData.recipes[spellId].requiresAttunement = hasAttune
                SkilletRecipeDBData.recipes[spellId].attunementLevel = level
            end
            
            -- Get reagents
            if Custom_GetProfessionRecipeReagents then
                SkilletRecipeDBData.recipes[spellId].reagents = Custom_GetProfessionRecipeReagents(spellId)
            end
            
            count = count + 1
        end
    end
    
    SkilletRecipeDBData.lastScan = time()
    Skillet:Print(string.format("Scanned %d recipes", count))
end

function RecipeDB:UpdateKnownRecipes()
    -- Clear known status
    wipe(SkilletRecipeDBData.playerKnown)
    
    -- Scan each profession the player has
    local professions = {171, 164, 333, 202, 755, 165, 197, 185, 129}
    
    for _, skillId in ipairs(professions) do
        -- Check if player has this profession
        local skillName = self:GetProfessionName(skillId)
        if skillName then
            -- Get all recipes for this profession
            local recipes = Custom_GetProfessionRecipes(skillId)
            
            for _, spellId in ipairs(recipes) do
                local _, _, _, _, canCraft = Custom_GetProfessionRecipeInfo(spellId)
                
                -- If canCraft is not nil, player knows the recipe
                if canCraft ~= nil then
                    SkilletRecipeDBData.playerKnown[spellId] = true
                end
            end
        end
    end
end

function RecipeDB:OnEvent(event, ...)
    if event == "NEW_RECIPE_LEARNED" then
        local recipeId = ...
        SkilletRecipeDBData.playerKnown[recipeId] = true
        
        -- Notify user
        local recipe = SkilletRecipeDBData.recipes[recipeId]
        if recipe then
            Skillet:Print("Learned recipe: " .. recipe.name)
        end
        
    elseif event == "TRADE_SKILL_SHOW" then
        -- Rescan known recipes when profession window opens
        C_Timer.After(0.5, function()
            self:UpdateKnownRecipes()
        end)
    end
end

function RecipeDB:MarkLearned(spellId)
    SkilletRecipeDBData.playerKnown[spellId] = true
end

function RecipeDB:IsKnown(spellId)
    return SkilletRecipeDBData.playerKnown[spellId] or false
end

function RecipeDB:GetRecipe(spellId)
    return SkilletRecipeDBData.recipes[spellId]
end

function RecipeDB:GetAllRecipes(skillId)
    local results = {}
    
    for spellId, recipe in pairs(SkilletRecipeDBData.recipes) do
        if not skillId or recipe.skillId == skillId then
            table.insert(results, recipe)
        end
    end
    
    return results
end

function RecipeDB:GetUnknownRecipes(skillId)
    local results = {}
    
    for spellId, recipe in pairs(SkilletRecipeDBData.recipes) do
        if (not skillId or recipe.skillId == skillId) and not self:IsKnown(spellId) then
            table.insert(results, recipe)
        end
    end
    
    return results
end

function RecipeDB:GetCompletionStats(skillId)
    local total = 0
    local known = 0
    
    for spellId, recipe in pairs(SkilletRecipeDBData.recipes) do
        if not skillId or recipe.skillId == skillId then
            total = total + 1
            if self:IsKnown(spellId) then
                known = known + 1
            end
        end
    end
    
    return known, total, (known / total * 100)
end

function RecipeDB:GetProfessionName(skillId)
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

### 2. Recipe Source Data
**New File:** `RecipeSourceData.lua`

```lua
-- This would be a MASSIVE data file
-- Would need to be compiled from external sources (WoWHead, etc.)

local Sources = {}
Skillet.RecipeSources = Sources

-- Example structure:
Sources.data = {
    [12345] = {
        type = "Trainer",
        trainer = "Alchemist Gribble",
        location = "Undercity",
        coords = {51.8, 74.6},
        faction = "Horde",
        cost = 5000, -- copper
        skillRequired = 200,
    },
    [12346] = {
        type = "Drop",
        mob = "Molten Destroyer",
        zone = "Molten Core",
        dropRate = 0.5,
        notes = "Any trash mob in MC",
    },
    [12347] = {
        type = "Quest",
        quest = "The Master Alchemist",
        questId = 1234,
        faction = "Alliance",
        startNpc = "Master Alchemist",
        location = "Stormwind",
    },
    [12348] = {
        type = "Vendor",
        vendor = "Reagent Vendor",
        location = "Dalaran",
        cost = 50000,
        currency = "gold",
    },
    [12349] = {
        type = "World Drop",
        zones = {"Northrend"},
        notes = "Rare drop from level 80 mobs",
    },
}

function Sources:GetSource(spellId)
    return self.data[spellId]
end

function Sources:GetSourceText(spellId)
    local source = self:GetSource(spellId)
    if not source then return "Unknown" end
    
    if source.type == "Trainer" then
        return string.format("Trainer: %s (%s)", source.trainer, source.location)
    elseif source.type == "Drop" then
        return string.format("Drop: %s (%.1f%%)", source.mob or source.zone, source.dropRate or 0)
    elseif source.type == "Quest" then
        return string.format("Quest: %s", source.quest)
    elseif source.type == "Vendor" then
        return string.format("Vendor: %s (%s)", source.vendor, source.location)
    elseif source.type == "World Drop" then
        return "World Drop"
    else
        return source.type
    end
end
```

---

### 3. UI: Recipe Discovery Window
**New File:** `UI/RecipeDiscoveryFrame.lua`

```lua
local DiscoveryFrame = CreateFrame("Frame", "SkilletRecipeDiscovery", UIParent, "BasicFrameTemplate")
DiscoveryFrame:SetSize(600, 500)
DiscoveryFrame:SetPoint("CENTER")
DiscoveryFrame:Hide()

function DiscoveryFrame:Initialize()
    self.title = self:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.title:SetPoint("TOP", 0, -5)
    self.title:SetText("Recipe Discovery")
    
    -- Profession dropdown
    self.profDropdown = CreateFrame("Frame", "SkilletRecipeDiscoveryDropdown", self, "UIDropDownMenuTemplate")
    self.profDropdown:SetPoint("TOPLEFT", 10, -30)
    
    -- Filter buttons
    self:CreateFilterButtons()
    
    -- Recipe list (scrolling)
    self.scrollFrame = CreateFrame("ScrollFrame", nil, self, "UIPanelScrollFrameTemplate")
    self.scrollFrame:SetPoint("TOPLEFT", 10, -80)
    self.scrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)
    
    self.scrollChild = CreateFrame("Frame", nil, self.scrollFrame)
    self.scrollFrame:SetScrollChild(self.scrollChild)
    self.scrollChild:SetSize(550, 1)
    
    -- Stats display
    self.stats = self:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.stats:SetPoint("BOTTOM", 0, 10)
end

function DiscoveryFrame:CreateFilterButtons()
    local filters = {
        {text = "All", filter = "all"},
        {text = "Unknown", filter = "unknown"},
        {text = "Known", filter = "known"},
        {text = "Trainers", filter = "trainer"},
        {text = "Drops", filter = "drop"},
        {text = "Quests", filter = "quest"},
    }
    
    local x = 10
    for i, filterData in ipairs(filters) do
        local btn = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
        btn:SetSize(80, 22)
        btn:SetPoint("TOPLEFT", x, -50)
        btn:SetText(filterData.text)
        btn:SetScript("OnClick", function()
            self:ApplyFilter(filterData.filter)
        end)
        
        x = x + 85
    end
end

function DiscoveryFrame:Update(skillId, filter)
    filter = filter or "all"
    
    local recipes = Skillet.RecipeDB:GetAllRecipes(skillId)
    
    -- Apply filter
    local filtered = {}
    for _, recipe in ipairs(recipes) do
        local include = true
        
        if filter == "unknown" then
            include = not Skillet.RecipeDB:IsKnown(recipe.spellId)
        elseif filter == "known" then
            include = Skillet.RecipeDB:IsKnown(recipe.spellId)
        elseif filter ~= "all" then
            local source = Skillet.RecipeSources:GetSource(recipe.spellId)
            if source then
                include = source.type:lower() == filter
            else
                include = false
            end
        end
        
        if include then
            table.insert(filtered, recipe)
        end
    end
    
    -- Sort by name
    table.sort(filtered, function(a, b) return a.name < b.name end)
    
    -- Display
    self:DisplayRecipes(filtered)
    
    -- Update stats
    local known, total, percent = Skillet.RecipeDB:GetCompletionStats(skillId)
    self.stats:SetText(string.format(
        "Recipes: %d/%d (%.1f%%) | Showing: %d",
        known, total, percent, #filtered
    ))
end

function DiscoveryFrame:DisplayRecipes(recipes)
    -- Clear existing
    for _, child in ipairs({self.scrollChild:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
    
    local y = 0
    for i, recipe in ipairs(recipes) do
        local row = self:CreateRecipeRow(recipe)
        row:SetPoint("TOPLEFT", 0, -y)
        row:SetParent(self.scrollChild)
        row:Show()
        
        y = y + 30
    end
    
    self.scrollChild:SetHeight(y)
end

function DiscoveryFrame:CreateRecipeRow(recipe)
    local row = CreateFrame("Button", nil, self.scrollChild)
    row:SetSize(530, 28)
    
    -- Background
    local bg = row:CreateTexture()
    bg:SetAllPoints()
    bg:SetColorTexture(0.1, 0.1, 0.1, 0.5)
    row.bg = bg
    
    -- Icon
    local icon = row:CreateTexture()
    icon:SetSize(24, 24)
    icon:SetPoint("LEFT", 2, 0)
    if recipe.itemId then
        icon:SetTexture(GetItemIcon(recipe.itemId))
    end
    
    -- Name
    local name = row:CreateFontString()
    name:SetFont("Fonts\\FRIZQT__.TTF", 11)
    name:SetPoint("LEFT", icon, "RIGHT", 5, 0)
    name:SetWidth(200)
    name:SetJustifyH("LEFT")
    name:SetText(recipe.name)
    
    -- Known status
    local known = Skillet.RecipeDB:IsKnown(recipe.spellId)
    if known then
        name:SetTextColor(0.5, 1, 0.5) -- Green
    else
        name:SetTextColor(1, 1, 1)
    end
    
    -- Source
    local source = row:CreateFontString()
    source:SetFont("Fonts\\FRIZQT__.TTF", 10)
    source:SetPoint("LEFT", name, "RIGHT", 10, 0)
    source:SetWidth(250)
    source:SetJustifyH("LEFT")
    source:SetText(Skillet.RecipeSources:GetSourceText(recipe.spellId))
    source:SetTextColor(0.7, 0.7, 0.7)
    
    -- Highlight on hover
    row:SetScript("OnEnter", function(self)
        self.bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
        
        -- Show tooltip
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(recipe.name, 1, 1, 1)
        GameTooltip:AddLine("Spell ID: " .. recipe.spellId, 0.5, 0.5, 0.5)
        GameTooltip:AddLine("Skill Required: " .. (recipe.minSkill or 0), 1, 0.82, 0)
        
        if known then
            GameTooltip:AddLine("You know this recipe", 0, 1, 0)
        else
            GameTooltip:AddLine("You have not learned this recipe", 1, 0, 0)
            
            local sourceData = Skillet.RecipeSources:GetSource(recipe.spellId)
            if sourceData then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("How to obtain:", 1, 0.82, 0)
                GameTooltip:AddLine(Skillet.RecipeSources:GetSourceText(recipe.spellId), 1, 1, 1)
            end
        end
        
        GameTooltip:Show()
    end)
    
    row:SetScript("OnLeave", function(self)
        self.bg:SetColorTexture(0.1, 0.1, 0.1, 0.5)
        GameTooltip:Hide()
    end)
    
    return row
end
```

---

### 4. Main Window Integration
**File:** `UI/MainFrame.lua`

```lua
-- Add "Recipe Discovery" button to main window
local discoveryBtn = CreateFrame("Button", nil, SkilletFrame, "UIPanelButtonTemplate")
discoveryBtn:SetSize(120, 22)
discoveryBtn:SetPoint("TOPRIGHT", -10, -30)
discoveryBtn:SetText("Recipe Discovery")
discoveryBtn:SetScript("OnClick", function()
    if SkilletRecipeDiscovery:IsShown() then
        SkilletRecipeDiscovery:Hide()
    else
        local skillId = Skillet:GetCurrentProfessionSkillId()
        SkilletRecipeDiscovery:Update(skillId)
        SkilletRecipeDiscovery:Show()
    end
end)

-- Add completion percentage to profession tab
function Skillet:UpdateProfessionTab()
    -- EXISTING: Set tab name
    
    -- NEW: Add completion %
    if Skillet.RecipeDB then
        local skillId = self:GetCurrentProfessionSkillId()
        local known, total, percent = Skillet.RecipeDB:GetCompletionStats(skillId)
        
        local completion = tab:CreateFontString()
        completion:SetFont("Fonts\\FRIZQT__.TTF", 9)
        completion:SetPoint("BOTTOM", tab, "BOTTOM", 0, 2)
        completion:SetText(string.format("%.0f%%", percent))
        
        if percent == 100 then
            completion:SetTextColor(0, 1, 0) -- Green
        elseif percent >= 75 then
            completion:SetTextColor(1, 0.82, 0) -- Gold
        else
            completion:SetTextColor(1, 1, 1) -- White
        end
    end
end
```

---

## Implementation Plan

### Step 1: Recipe Database (4-6 hours)
1. Create RecipeDatabase.lua module
2. Implement scanning and caching
3. Add event handlers
4. Test with all professions

### Step 2: Recipe Source Data (8-12 hours)
**NOTE:** This is MASSIVE data entry work
1. Compile recipe source database (external tools)
2. Create RecipeSourceData.lua
3. Validate accuracy
4. Test lookups

### Step 3: Discovery UI (5-7 hours)
1. Create RecipeDiscoveryFrame
2. Implement filtering
3. Add source display
4. Test with various professions

### Step 4: Integration (2-3 hours)
1. Add to main window
2. Add completion tracking
3. Polish visuals

**Total Estimated Time:** 19-28 hours
*Note: Recipe source data compilation could take significantly longer depending on comprehensiveness*

---

## Success Criteria

✅ **Must Have:**
1. Track known/unknown recipes
2. Show completion percentage
3. Recipe discovery window functional
4. No performance issues

✅ **Nice to Have:**
1. Complete source data for all recipes
2. Location coordinates
3. Quest chains
4. Cost information

---

## Data Compilation Strategy

**Option 1: Manual Entry**
- Time consuming but accurate
- Use WoWHead as reference
- Focus on current content first

**Option 2: External Database Import**
- Use WoWHead API or similar
- Parse and convert to Lua format
- May have licensing concerns

**Option 3: Community Contribution**
- Create template for community to fill
- Crowdsource data collection
- Maintain in separate repository

---

## Future Enhancements

1. Track recipe acquisition dates
2. "Shopping list" for unlearned recipes
3. Recipe learning path optimizer
4. Integration with character goals
5. Multi-character tracking
6. Export/import recipe collections
