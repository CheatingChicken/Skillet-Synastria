# Enhanced Shopping List 2.0

## Overview
Transform the shopping list from a simple reagent display into an intelligent material acquisition assistant with global scope and smart sourcing recommendations.

## Current State
- Shows reagents needed for current queue
- Limited to single profession
- No vendor/AH/crafting recommendations
- Manual material gathering
- No cross-character inventory checking

## Desired State
- Global material aggregation across all queue professions
- Vendor vs craft vs buy recommendations
- Cost optimization suggestions
- Bank/alt character inventory integration
- Export to AddOn vendors (TSM, Auctionator)
- Smart gathering routes

---

## Testing Requirements

### Phase 1: Cross-Profession Material Aggregation

**Test 1: Mixed profession queue materials**
```lua
-- Create queue with multiple professions
/script -- Add Alchemy items (needs herbs)
/script -- Add Blacksmithing items (needs ore/bars)
/script -- Add Engineering items (needs various)

-- Generate shopping list
/script local shoppingList = Skillet:GenerateGlobalShoppingList()
/script for itemId, count in pairs(shoppingList) do
    local name = GetItemInfo(itemId)
    print(name .. ": " .. count)
end
```

**Expected:** ✅ Aggregated list of ALL materials needed across all professions

---

**Test 2: Recursive material expansion**
```lua
-- Queue item that requires craftable reagents
-- E.g., queue "Iceblade Arrows" which needs "Fel Iron Bars"
-- Fel Iron Bars craftable from "Fel Iron Ore"

function ExpandCraftableMaterials(shoppingList)
    local expanded = {}
    
    for itemId, count in pairs(shoppingList) do
        -- Can this be crafted?
        local recipes = Skillet.CraftPath:FindRecipesForItem(itemId)
        
        if #recipes > 0 then
            -- Get materials for this craft
            local subMats = Custom_GetProfessionRecipeReagents(recipes[1].spellId)
            if subMats then
                for subItemId, subCount in pairs(subMats) do
                    expanded[subItemId] = (expanded[subItemId] or 0) + (subCount * count)
                end
            end
        else
            -- Not craftable - add to final list
            expanded[itemId] = (expanded[itemId] or 0) + count
        end
    end
    
    return expanded
end

/script local base = {[itemId] = 10} -- 10 of something craftable
/script local raw = ExpandCraftableMaterials(base)
```

**Expected:** ✅ List shows base materials instead of craftable intermediates

---

### Phase 2: Source Detection

**Test 3: Vendor item detection**
```lua
-- Check if item is sold by vendor
function IsVendorItem(itemId)
    -- WoW API doesn't provide this directly
    -- Need to maintain a database or use external data
    
    local vendorItems = {
        [2880] = {vendor = "Reagent Vendor", cost = 200}, -- Weak Flux
        [3466] = {vendor = "Reagent Vendor", cost = 20},  -- Strong Flux
        -- etc
    }
    
    return vendorItems[itemId]
end

/script local info = IsVendorItem(2880)
/script if info then
    print("Sold by: " .. info.vendor .. " for " .. GetCoinTextureString(info.cost))
end
```

**Note:** Would need comprehensive vendor item database

---

**Test 4: Auction house price checking**
```lua
-- If TSM or Auctionator installed, get AH prices
if TSM_API then
    local price = TSM_API:GetCustomPriceValue("DBMarket", "i:" .. itemId)
    if price then
        print("AH Market Price: " .. GetCoinTextureString(price))
    end
elseif Auctionator and Auctionator.API and Auctionator.API.v1 then
    local price = Auctionator.API.v1.GetAuctionPriceByItemID("Skillet", itemId)
    if price then
        print("AH Price: " .. GetCoinTextureString(price))
    end
end
```

---

### Phase 3: Inventory Checking

**Test 5: Bank inventory**
```lua
-- Check bank for materials
function GetItemCountIncludingBank(itemId)
    local bags = GetItemCount(itemId, false) -- Bags only
    local bank = GetItemCount(itemId, true) - bags -- Bank only
    
    return bags, bank
end

/script local bags, bank = GetItemCountIncludingBank(itemId)
/script print(string.format("Bags: %d, Bank: %d, Total: %d", bags, bank, bags + bank))
```

**Expected:** ✅ Accurate counts for bags and bank separately

---

**Test 6: Alt character inventory (if possible)**
```lua
-- This requires saved variables tracking
-- Each character saves their inventory on logout
-- Main character reads from saved variables

SkilletAltInventory = SkilletAltInventory or {}

-- On logout (each character):
function Skillet:SaveInventorySnapshot()
    local charKey = UnitName("player") .. "-" .. GetRealmName()
    SkilletAltInventory[charKey] = {}
    
    -- Scan all bags
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemId = GetContainerItemID(bag, slot)
            if itemId then
                local _, count = GetContainerItemInfo(bag, slot)
                SkilletAltInventory[charKey][itemId] = (SkilletAltInventory[charKey][itemId] or 0) + count
            end
        end
    end
    
    -- Scan bank if accessible
    -- ... similar logic
end

-- On main character:
function Skillet:GetAltInventory(itemId)
    local total = 0
    local byChar = {}
    
    for charKey, inventory in pairs(SkilletAltInventory) do
        if charKey ~= (UnitName("player") .. "-" .. GetRealmName()) then
            local count = inventory[itemId] or 0
            if count > 0 then
                byChar[charKey] = count
                total = total + count
            end
        end
    end
    
    return total, byChar
end
```

---

## Code Changes Required

### 1. Enhanced Shopping List Generator
**File:** `UI/ShoppingList.lua`

```lua
function Skillet:GenerateGlobalShoppingList(options)
    options = options or {}
    local expandCraftables = options.expandCraftables or false
    local includeBank = options.includeBank or true
    local includeAlts = options.includeAlts or false
    
    local materials = {}
    
    -- Aggregate from ALL queue items
    for _, queueItem in ipairs(Skillet.stitch.queue) do
        if queueItem.spellId then
            local reagents = Custom_GetProfessionRecipeReagents(queueItem.spellId)
            
            if reagents then
                for itemId, count in pairs(reagents) do
                    local needed = count * queueItem.numcasts
                    materials[itemId] = (materials[itemId] or 0) + needed
                end
            end
        end
    end
    
    -- Expand craftable materials if requested
    if expandCraftables and Skillet.CraftPath then
        materials = self:ExpandCraftableMaterials(materials)
    end
    
    -- Subtract what we have
    local shoppingList = {}
    for itemId, needed in pairs(materials) do
        local have = self:GetTotalItemCount(itemId, includeBank, includeAlts)
        local shortage = needed - have
        
        if shortage > 0 then
            shoppingList[itemId] = {
                needed = needed,
                have = have,
                shortage = shortage,
                sources = self:GetItemSources(itemId)
            }
        end
    end
    
    return shoppingList
end

function Skillet:ExpandCraftableMaterials(materials)
    local expanded = {}
    
    for itemId, count in pairs(materials) do
        -- Check if craftable
        local recipes = Skillet.CraftPath:FindRecipesForItem(itemId)
        
        if #recipes > 0 and Skillet.db.profile.expand_craftables then
            -- Get best recipe (cheapest, most accessible, etc.)
            local bestRecipe = recipes[1] -- Simple: just use first
            local reagents = Custom_GetProfessionRecipeReagents(bestRecipe.spellId)
            
            if reagents then
                -- Calculate how many crafts needed
                local _, _, itemId, _, _, minMade, maxMade = Custom_GetProfessionRecipeInfo(bestRecipe.spellId)
                local avgMade = (minMade + maxMade) / 2
                local craftsNeeded = math.ceil(count / avgMade)
                
                -- Add reagents
                for reagentId, reagentCount in pairs(reagents) do
                    expanded[reagentId] = (expanded[reagentId] or 0) + (reagentCount * craftsNeeded)
                end
            else
                -- Can't get reagents - add as is
                expanded[itemId] = (expanded[itemId] or 0) + count
            end
        else
            -- Not craftable or user wants to see it as is
            expanded[itemId] = (expanded[itemId] or 0) + count
        end
    end
    
    return expanded
end

function Skillet:GetTotalItemCount(itemId, includeBank, includeAlts)
    local count = 0
    
    -- Bags
    count = count + GetItemCount(itemId, false)
    
    -- Bank
    if includeBank then
        count = count + (GetItemCount(itemId, true) - GetItemCount(itemId, false))
    end
    
    -- Alts
    if includeAlts and SkilletAltInventory then
        local altCount = 0
        for charKey, inventory in pairs(SkilletAltInventory) do
            if charKey ~= (UnitName("player") .. "-" .. GetRealmName()) then
                altCount = altCount + (inventory[itemId] or 0)
            end
        end
        count = count + altCount
    end
    
    return count
end

function Skillet:GetItemSources(itemId)
    local sources = {}
    
    -- Vendor
    local vendorInfo = self:GetVendorInfo(itemId)
    if vendorInfo then
        table.insert(sources, {
            type = "vendor",
            vendor = vendorInfo.vendor,
            cost = vendorInfo.cost,
            priority = 1, -- Highest priority (cheapest, most reliable)
        })
    end
    
    -- Craftable
    local recipes = Skillet.CraftPath and Skillet.CraftPath:FindRecipesForItem(itemId)
    if recipes and #recipes > 0 then
        for _, recipe in ipairs(recipes) do
            table.insert(sources, {
                type = "craft",
                recipe = recipe,
                priority = 2,
            })
        end
    end
    
    -- Auction House
    local ahPrice = self:GetAHPrice(itemId)
    if ahPrice then
        table.insert(sources, {
            type = "ah",
            price = ahPrice,
            priority = 3,
        })
    end
    
    -- Farmable (gathering profession)
    local farmInfo = self:GetFarmInfo(itemId)
    if farmInfo then
        table.insert(sources, {
            type = "farm",
            method = farmInfo.method, -- Mining, Herbalism, etc.
            zones = farmInfo.zones,
            priority = 4,
        })
    end
    
    -- Sort by priority
    table.sort(sources, function(a, b) return a.priority < b.priority end)
    
    return sources
end
```

---

### 2. Item Source Database
**New File:** `ItemSourceData.lua`

```lua
local Sources = {}
Skillet.ItemSources = Sources

-- Vendor items database
Sources.vendors = {
    -- Reagents
    [2880] = {vendor = "Trade Supplies", cost = 200}, -- Weak Flux
    [3466] = {vendor = "Trade Supplies", cost = 2000}, -- Strong Flux
    [4340] = {vendor = "Reagent Vendor", cost = 50}, -- Gray Dye
    -- ... many more
}

-- Farmable items
Sources.gathering = {
    [2770] = {method = "Mining", skill = 1, zones = {"Dun Morogh", "Durotar"}}, -- Copper Ore
    [2771] = {method = "Mining", skill = 65, zones = {"Westfall", "Barrens"}}, -- Tin Ore
    [765] = {method = "Herbalism", skill = 1, zones = {"Elwynn", "Mulgore"}}, -- Silverleaf
    -- ... many more
}

function Sources:GetVendorInfo(itemId)
    return self.vendors[itemId]
end

function Sources:GetFarmInfo(itemId)
    return self.gathering[itemId]
end
```

---

### 3. AH Integration Module
**New File:** `AHIntegration.lua`

```lua
local AH = {}
Skillet.AH = AH

function AH:GetPrice(itemId)
    -- Try TSM first
    if TSM_API then
        local price = TSM_API:GetCustomPriceValue("DBMarket", "i:" .. itemId)
        if price and price > 0 then
            return price, "TSM"
        end
    end
    
    -- Try Auctionator
    if Auctionator and Auctionator.API and Auctionator.API.v1 then
        Auctionator.API.v1.RegisterForDBUpdate("Skillet", function() end)
        local price = Auctionator.API.v1.GetAuctionPriceByItemID("Skillet", itemId)
        if price and price > 0 then
            return price, "Auctionator"
        end
    end
    
    return nil
end

function AH:CreateShoppingList(items)
    -- Export to TSM shopping list
    if TSM_API then
        local tsmList = {}
        for itemId, data in pairs(items) do
            table.insert(tsmList, "i:" .. itemId .. "#" .. data.shortage)
        end
        
        -- Create TSM shopping operation
        -- (TSM API for this is complex, would need more research)
    end
    
    -- Export to Auctionator shopping list
    if Auctionator and Auctionator.API and Auctionator.API.v1 then
        local auctionatorList = {}
        for itemId, data in pairs(items) do
            table.insert(auctionatorList, {
                searchString = GetItemInfo(itemId),
                quantity = data.shortage,
            })
        end
        
        Auctionator.API.v1.CreateShoppingList("Skillet Shopping", auctionatorList)
    end
end
```

---

### 4. Enhanced Shopping List UI
**File:** `UI/ShoppingListFrame.lua`

```lua
local ShoppingFrame = CreateFrame("Frame", "SkilletShoppingListFrame", UIParent, "BasicFrameTemplate")
ShoppingFrame:SetSize(700, 600)
ShoppingFrame:SetPoint("CENTER")
ShoppingFrame:Hide()

function ShoppingFrame:Initialize()
    -- Title
    self.title = self:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.title:SetPoint("TOP", 0, -5)
    self.title:SetText("Shopping List 2.0")
    
    -- Options
    self:CreateOptions()
    
    -- Action buttons
    self:CreateActionButtons()
    
    -- Scrolling list
    self.scrollFrame = CreateFrame("ScrollFrame", nil, self, "UIPanelScrollFrameTemplate")
    self.scrollFrame:SetPoint("TOPLEFT", 10, -100)
    self.scrollFrame:SetPoint("BOTTOMRIGHT", -30, 80)
    
    self.scrollChild = CreateFrame("Frame", nil, self.scrollFrame)
    self.scrollFrame:SetScrollChild(self.scrollChild)
    self.scrollChild:SetSize(650, 1)
    
    -- Total cost display
    self.totalCost = self:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.totalCost:SetPoint("BOTTOM", 0, 45)
end

function ShoppingFrame:CreateOptions()
    -- Checkbox: Include Bank
    local bankCheck = CreateFrame("CheckButton", nil, self, "UICheckButtonTemplate")
    bankCheck:SetPoint("TOPLEFT", 10, -30)
    bankCheck.text:SetText("Include Bank")
    bankCheck:SetChecked(true)
    bankCheck:SetScript("OnClick", function()
        Skillet.db.profile.shopping_include_bank = bankCheck:GetChecked()
        ShoppingFrame:Update()
    end)
    
    -- Checkbox: Include Alts
    local altCheck = CreateFrame("CheckButton", nil, self, "UICheckButtonTemplate")
    altCheck:SetPoint("LEFT", bankCheck, "RIGHT", 150, 0)
    altCheck.text:SetText("Include Alts")
    altCheck:SetChecked(false)
    altCheck:SetScript("OnClick", function()
        Skillet.db.profile.shopping_include_alts = altCheck:GetChecked()
        ShoppingFrame:Update()
    end)
    
    -- Checkbox: Expand Craftables
    local craftCheck = CreateFrame("CheckButton", nil, self, "UICheckButtonTemplate")
    craftCheck:SetPoint("TOPLEFT", 10, -55)
    craftCheck.text:SetText("Show Raw Materials Only")
    craftCheck:SetChecked(false)
    craftCheck:SetScript("OnClick", function()
        Skillet.db.profile.expand_craftables = craftCheck:GetChecked()
        ShoppingFrame:Update()
    end)
end

function ShoppingFrame:CreateActionButtons()
    local y = 10
    
    -- Export to TSM
    local tsmBtn = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
    tsmBtn:SetSize(140, 25)
    tsmBtn:SetPoint("BOTTOMLEFT", 10, y)
    tsmBtn:SetText("Export to TSM")
    tsmBtn:SetScript("OnClick", function()
        Skillet.AH:CreateShoppingList(self.shoppingList)
        Skillet:Print("Shopping list exported to TSM")
    end)
    if not TSM_API then
        tsmBtn:Disable()
    end
    
    -- Export to Auctionator
    local auctBtn = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
    auctBtn:SetSize(140, 25)
    auctBtn:SetPoint("LEFT", tsmBtn, "RIGHT", 5, 0)
    auctBtn:SetText("Export to Auctionator")
    auctBtn:SetScript("OnClick", function()
        Skillet.AH:CreateShoppingList(self.shoppingList)
        Skillet:Print("Shopping list exported to Auctionator")
    end)
    if not Auctionator then
        auctBtn:Disable()
    end
    
    -- Copy to clipboard
    local copyBtn = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
    copyBtn:SetSize(140, 25)
    copyBtn:SetPoint("LEFT", auctBtn, "RIGHT", 5, 0)
    copyBtn:SetText("Copy List")
    copyBtn:SetScript("OnClick", function()
        self:CopyToClipboard()
    end)
end

function ShoppingFrame:Update()
    local options = {
        includeBank = Skillet.db.profile.shopping_include_bank,
        includeAlts = Skillet.db.profile.shopping_include_alts,
        expandCraftables = Skillet.db.profile.expand_craftables,
    }
    
    self.shoppingList = Skillet:GenerateGlobalShoppingList(options)
    
    self:DisplayItems(self.shoppingList)
    self:CalculateTotalCost(self.shoppingList)
end

function ShoppingFrame:DisplayItems(shoppingList)
    -- Clear existing
    for _, child in ipairs({self.scrollChild:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
    
    -- Sort by priority: vendor > craft > ah > farm
    local sorted = {}
    for itemId, data in pairs(shoppingList) do
        table.insert(sorted, {itemId = itemId, data = data})
    end
    
    table.sort(sorted, function(a, b)
        local aPriority = a.data.sources[1] and a.data.sources[1].priority or 99
        local bPriority = b.data.sources[1] and b.data.sources[1].priority or 99
        return aPriority < bPriority
    end)
    
    local y = 0
    for i, item in ipairs(sorted) do
        local row = self:CreateItemRow(item.itemId, item.data)
        row:SetPoint("TOPLEFT", 0, -y)
        row:SetParent(self.scrollChild)
        row:Show()
        
        y = y + 35
    end
    
    self.scrollChild:SetHeight(y)
end

function ShoppingFrame:CreateItemRow(itemId, data)
    local row = CreateFrame("Frame", nil, self.scrollChild)
    row:SetSize(630, 32)
    
    -- Background
    local bg = row:CreateTexture()
    bg:SetAllPoints()
    bg:SetColorTexture(0.1, 0.1, 0.1, 0.5)
    
    -- Icon
    local icon = row:CreateTexture()
    icon:SetSize(28, 28)
    icon:SetPoint("LEFT", 2, 0)
    icon:SetTexture(GetItemIcon(itemId))
    
    -- Name
    local name = row:CreateFontString()
    name:SetFont("Fonts\\FRIZQT__.TTF", 11)
    name:SetPoint("LEFT", icon, "RIGHT", 5, 6)
    name:SetWidth(180)
    name:SetJustifyH("LEFT")
    name:SetText(GetItemInfo(itemId) or ("Item #" .. itemId))
    
    -- Quantity needed
    local qty = row:CreateFontString()
    qty:SetFont("Fonts\\FRIZQT__.TTF", 10)
    qty:SetPoint("LEFT", icon, "RIGHT", 5, -8)
    qty:SetText(string.format("Need: |cffff0000%d|r (have %d)", data.shortage, data.have))
    qty:SetTextColor(0.7, 0.7, 0.7)
    
    -- Best source
    local source = row:CreateFontString()
    source:SetFont("Fonts\\FRIZQT__.TTF", 10)
    source:SetPoint("LEFT", name, "RIGHT", 10, 0)
    source:SetWidth(250)
    source:SetJustifyH("LEFT")
    
    if #data.sources > 0 then
        local bestSource = data.sources[1]
        
        if bestSource.type == "vendor" then
            local totalCost = bestSource.cost * data.shortage
            source:SetText("Vendor: " .. GetCoinTextureString(totalCost))
            source:SetTextColor(0, 1, 0) -- Green
        elseif bestSource.type == "craft" then
            source:SetText("Craft: " .. bestSource.recipe.info.name)
            source:SetTextColor(0, 0.8, 1) -- Blue
        elseif bestSource.type == "ah" then
            local totalCost = bestSource.price * data.shortage
            source:SetText("AH: ~" .. GetCoinTextureString(totalCost))
            source:SetTextColor(1, 0.82, 0) -- Gold
        elseif bestSource.type == "farm" then
            source:SetText("Farm: " .. bestSource.method)
            source:SetTextColor(0.5, 1, 0.5) -- Light green
        end
    else
        source:SetText("Unknown source")
        source:SetTextColor(0.5, 0.5, 0.5)
    end
    
    -- Action button
    local actionBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    actionBtn:SetSize(80, 20)
    actionBtn:SetPoint("RIGHT", -5, 0)
    
    if #data.sources > 0 then
        local bestSource = data.sources[1]
        
        if bestSource.type == "craft" then
            actionBtn:SetText("Add to Queue")
            actionBtn:SetScript("OnClick", function()
                -- Add craft to queue
                Skillet.stitch:AddToQueue(nil, math.ceil(data.shortage), nil, false, bestSource.recipe.spellId)
                Skillet:Print("Added " .. bestSource.recipe.info.name .. " to queue")
            end)
        else
            actionBtn:SetText("Info")
            actionBtn:SetScript("OnClick", function()
                -- Show detailed source info
            end)
        end
    else
        actionBtn:Disable()
    end
    
    return row
end

function ShoppingFrame:CalculateTotalCost(shoppingList)
    local total = 0
    local canCalculate = true
    
    for itemId, data in pairs(shoppingList) do
        if #data.sources > 0 then
            local bestSource = data.sources[1]
            
            if bestSource.type == "vendor" then
                total = total + (bestSource.cost * data.shortage)
            elseif bestSource.type == "ah" and bestSource.price then
                total = total + (bestSource.price * data.shortage)
            else
                canCalculate = false
            end
        else
            canCalculate = false
        end
    end
    
    if canCalculate then
        self.totalCost:SetText("Estimated Cost: " .. GetCoinTextureString(total))
    else
        self.totalCost:SetText("Estimated Cost: Unknown")
    end
end

function ShoppingFrame:CopyToClipboard()
    -- Create copyable text
    local text = "Skillet Shopping List:\n\n"
    
    for itemId, data in pairs(self.shoppingList) do
        local name = GetItemInfo(itemId) or ("Item #" .. itemId)
        text = text .. string.format("%s x%d\n", name, data.shortage)
    end
    
    -- Show in popup
    local popup = StaticPopup_Show("SKILLET_COPY_TEXT")
    if popup then
        popup.editBox:SetText(text)
        popup.editBox:HighlightText()
    end
end

-- Register popup
StaticPopupDialogs["SKILLET_COPY_TEXT"] = {
    text = "Copy this text (Ctrl+C):",
    button1 = "Close",
    hasEditBox = true,
    editBoxWidth = 350,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}
```

---

## Implementation Plan

### Step 1: Core Shopping List Logic (4-5 hours)
1. Enhance GenerateGlobalShoppingList
2. Implement ExpandCraftableMaterials
3. Add GetTotalItemCount with bank/alt support
4. Test aggregation

### Step 2: Item Source Database (6-8 hours)
1. Compile vendor item data
2. Compile gathering profession data
3. Create ItemSourceData.lua
4. Test lookups

### Step 3: AH Integration (3-4 hours)
1. Create AHIntegration.lua
2. Implement TSM integration
3. Implement Auctionator integration
4. Test price fetching

### Step 4: Enhanced UI (5-7 hours)
1. Create ShoppingListFrame
2. Implement sorting and display
3. Add action buttons
4. Add export functionality

### Step 5: Alt Character Integration (2-3 hours)
1. Implement inventory snapshot
2. Add cross-character lookup
3. Test multi-character scenarios

**Total Estimated Time:** 20-27 hours

---

## Success Criteria

✅ **Must Have:**
1. Aggregate materials across all queue professions
2. Show vendor vs craft recommendations
3. Bank inventory integration
4. No performance issues

✅ **Nice to Have:**
1. AH price integration
2. Alt character inventory
3. Export to TSM/Auctionator
4. Cost optimization

---

## Future Enhancements

1. Smart gathering routes (GatherMate integration)
2. Historical price tracking
3. "Best time to buy" recommendations
4. Bulk buying automation
5. Material stockpiling suggestions
6. Integration with inventory management addons
