-- Synastria: Attunability and Forge Level Filtering (from ScootsCraft)
-- This file adds filtering UI for attuneable items and forge levels

-- Filter options
local ATTUNABILITY_FILTER_CHOICES = {
    {nil, 'All Equipment'},
    {'account', 'Attuneable (Acc)'},
    {'character', 'Attuneable (Char)'},
}

local FORGE_FILTER_CHOICES = {
    {nil, 'All Forge Levels'},
    {-1, 'Unattuned'},
    {0, '<= Baseline'},
    {1, '<= Titanforged'},
    {2, '<= Warforged'},
    {3, '<= Lightforged'}
}

-- Initialize attunability dropdown
local function SetAttunabilityFilterValues(self, level, menuList)
    local info = UIDropDownMenu_CreateInfo()
    
    for _, choice in ipairs(ATTUNABILITY_FILTER_CHOICES) do
        info.text = choice[2]
        info.func = function()
            UIDropDownMenu_SetText(Skillet.attunabilityFilterDropdown, choice[2])
            Skillet:SetAttunabilityFilter(choice[1])
        end
        UIDropDownMenu_AddButton(info, level)
    end
end

-- Initialize forge level dropdown
local function SetForgeFilterValues(self, level, menuList)
    local info = UIDropDownMenu_CreateInfo()
    
    for _, choice in ipairs(FORGE_FILTER_CHOICES) do
        info.text = choice[2]
        info.func = function()
            UIDropDownMenu_SetText(Skillet.forgeFilterDropdown, choice[2])
            Skillet:SetForgeFilter(choice[1])
        end
        UIDropDownMenu_AddButton(info, level)
    end
end

-- Create the attunability and forge filter dropdowns
function Skillet:CreateAttunabilityFilters(parent)
    -- Attunability filter dropdown
    self.attunabilityFilterDropdown = CreateFrame('Frame', 'SkilletAttunabilityFilter', parent, 'UIDropDownMenuTemplate')
    self.attunabilityFilterDropdown:SetPoint('LEFT', SkilletSortAscButton, 'RIGHT', 0, 0)
    UIDropDownMenu_Initialize(self.attunabilityFilterDropdown, SetAttunabilityFilterValues)
    UIDropDownMenu_SetWidth(self.attunabilityFilterDropdown, 120)
    UIDropDownMenu_SetText(self.attunabilityFilterDropdown, 'All Equipment')
    
    -- Forge filter dropdown
    self.forgeFilterDropdown = CreateFrame('Frame', 'SkilletForgeFilter', parent, 'UIDropDownMenuTemplate')
    self.forgeFilterDropdown:SetPoint('TOP', self.attunabilityFilterDropdown, 'BOTTOM', 0, 10)
    UIDropDownMenu_Initialize(self.forgeFilterDropdown, SetForgeFilterValues)
    UIDropDownMenu_SetWidth(self.forgeFilterDropdown, 120)
    UIDropDownMenu_SetText(self.forgeFilterDropdown, 'All Forge Levels')
end

-- Set attunability filter
function Skillet:SetAttunabilityFilter(filterValue)
    if not self.currentTrade then return end
    
    self:SetTradeSkillOption(self.currentTrade, "attunabilityfilter", filterValue)
    self:UpdateTradeSkillWindow()
end

-- Set forge filter
function Skillet:SetForgeFilter(filterValue)
    if not self.currentTrade then return end
    
    self:SetTradeSkillOption(self.currentTrade, "forgefilter", filterValue)
    self:UpdateTradeSkillWindow()
end

-- Check if item matches attunability filter
function Skillet:MatchesAttunabilityFilter(recipeIndex)
    local filterValue = self:GetTradeSkillOption(self.currentTrade, "attunabilityfilter")
    
    if not filterValue then
        return true  -- No filter active
    end
    
    -- Get item link (the crafted item, not the recipe)
    local itemLink = self:GetTradeskillItemLink(recipeIndex)
    if not itemLink then
        return true  -- Can't check non-items, so pass them through
    end
    
    local itemId = self:GetItemIDFromLink(itemLink)
    if not itemId then
        return true
    end
    
    -- Check if equippable - try both item ID and link
    local isEquippable = IsEquippableItem(itemId) or IsEquippableItem(itemLink)
    if not isEquippable then
        return true  -- Non-equippable items pass through (ScootsCraft behavior)
    end
    
    -- Check attunability based on filter type
    local attuneChar = false
    local attuneAny = false
    
    -- First check if item has attuneable tags
    if GetItemTagsCustom then
        local tags = GetItemTagsCustom(itemId)
        if tags and bit.band(tags, 96) == 64 then
            -- Check if this character can attune it
            if CanAttuneItemHelper and CanAttuneItemHelper(itemId) > 0 then
                attuneChar = true
                attuneAny = true
            else
                -- Check if anyone on the account can attune it
                if IsAttunableBySomeone then
                    local check = IsAttunableBySomeone(itemId)
                    if check ~= nil and check ~= 0 then
                        attuneAny = true
                    end
                end
            end
        end
    end
    
    -- Apply the filter
    if filterValue == 'account' then
        return attuneAny
    elseif filterValue == 'character' then
        return attuneChar
    end
    
    return false
end

-- Check if item matches forge level filter
function Skillet:MatchesForgeFilter(recipeIndex)
    local filterValue = self:GetTradeSkillOption(self.currentTrade, "forgefilter")
    
    if not filterValue then
        return true  -- No filter active
    end
    
    -- Get item link (the crafted item, not the recipe)
    local itemLink = self:GetTradeskillItemLink(recipeIndex)
    if not itemLink then
        return true  -- Non-items pass the filter
    end
    
    local itemId = self:GetItemIDFromLink(itemLink)
    if not itemId then
        return true
    end
    
    -- Get forge level
    local forgeLevel = nil
    if GetItemAttuneForge then
        forgeLevel = GetItemAttuneForge(itemId)
    end
    
    if not forgeLevel then
        return filterValue == -1  -- Only pass if filter is set to "Unattuned"
    end
    
    -- Compare forge level
    return forgeLevel <= filterValue
end

-- Debug function to output filter information
function Skillet:DebugFilterInfo()
    if not self.selectedSkill or self.selectedSkill < 0 then
        DEFAULT_CHAT_FRAME:AddMessage("No recipe selected")
        return
    end
    
    local recipeLink = self:GetTradeSkillRecipeLink(self.selectedSkill)
    local itemLink = self:GetTradeskillItemLink(self.selectedSkill)
    
    if not itemLink then
        DEFAULT_CHAT_FRAME:AddMessage("Selected recipe has no item link (not an item)")
        return
    end
    
    local itemId = self:GetItemIDFromLink(itemLink)
    if not itemId then
        DEFAULT_CHAT_FRAME:AddMessage("Could not extract item ID from link")
        return
    end
    
    local recipeName = self:GetTradeSkillInfo(self.selectedSkill)
    DEFAULT_CHAT_FRAME:AddMessage("=== DEBUG: " .. recipeName .. " (ID: " .. itemId .. ") ===")
    DEFAULT_CHAT_FRAME:AddMessage("Recipe Link: " .. tostring(recipeLink))
    DEFAULT_CHAT_FRAME:AddMessage("Item Link: " .. itemLink)
    
    -- Check if item is cached
    local itemName, itemLinkFromCache = GetItemInfo(itemId)
    DEFAULT_CHAT_FRAME:AddMessage("Item Cached: " .. tostring(itemName ~= nil))
    if itemName then
        DEFAULT_CHAT_FRAME:AddMessage("Item Name: " .. itemName)
    end
    
    -- Check if equippable (try both ID and link)
    local isEquippableById = IsEquippableItem(itemId)
    local isEquippableByLink = IsEquippableItem(itemLink)
    DEFAULT_CHAT_FRAME:AddMessage("IsEquippableItem(itemId): " .. tostring(isEquippableById))
    DEFAULT_CHAT_FRAME:AddMessage("IsEquippableItem(itemLink): " .. tostring(isEquippableByLink))
    local isEquippable = isEquippableById or isEquippableByLink
    
    -- Get custom tags
    local tags = nil
    if GetItemTagsCustom then
        tags = GetItemTagsCustom(itemId)
        DEFAULT_CHAT_FRAME:AddMessage("GetItemTagsCustom: " .. tostring(tags))
        if tags then
            DEFAULT_CHAT_FRAME:AddMessage("  bit.band(tags, 96): " .. tostring(bit.band(tags, 96)))
            DEFAULT_CHAT_FRAME:AddMessage("  Is attuneable tag (== 64): " .. tostring(bit.band(tags, 96) == 64))
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("GetItemTagsCustom: NOT AVAILABLE")
    end
    
    -- Check attunement functions
    local canAttuneHelper = nil
    if CanAttuneItemHelper then
        canAttuneHelper = CanAttuneItemHelper(itemId)
        DEFAULT_CHAT_FRAME:AddMessage("CanAttuneItemHelper: " .. tostring(canAttuneHelper))
    else
        DEFAULT_CHAT_FRAME:AddMessage("CanAttuneItemHelper: NOT AVAILABLE")
    end
    
    local isAttunableBySomeone = nil
    if IsAttunableBySomeone then
        isAttunableBySomeone = IsAttunableBySomeone(itemId)
        DEFAULT_CHAT_FRAME:AddMessage("IsAttunableBySomeone: " .. tostring(isAttunableBySomeone))
    else
        DEFAULT_CHAT_FRAME:AddMessage("IsAttunableBySomeone: NOT AVAILABLE")
    end
    
    -- Get forge level
    local forgeLevel = nil
    if GetItemAttuneForge then
        forgeLevel = GetItemAttuneForge(itemId)
        DEFAULT_CHAT_FRAME:AddMessage("GetItemAttuneForge: " .. tostring(forgeLevel))
    else
        DEFAULT_CHAT_FRAME:AddMessage("GetItemAttuneForge: NOT AVAILABLE")
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("--- ATTUNABILITY FILTER RESULTS ---")
    -- Test each attunability filter option
    for _, choice in ipairs(ATTUNABILITY_FILTER_CHOICES) do
        local filterValue = choice[1]
        local filterName = choice[2]
        
        -- Simulate the filter logic
        local result = true
        if filterValue then
            if not isEquippable then
                result = true  -- Non-equippable pass through (ScootsCraft behavior)
            else
                local attuneChar = false
                local attuneAny = false
                
                if tags and bit.band(tags, 96) == 64 then
                    if canAttuneHelper and canAttuneHelper > 0 then
                        attuneChar = true
                        attuneAny = true
                    else
                        if isAttunableBySomeone and isAttunableBySomeone ~= 0 then
                            attuneAny = true
                        end
                    end
                end
                
                if filterValue == 'account' then
                    result = attuneAny
                elseif filterValue == 'character' then
                    result = attuneChar
                else
                    result = false
                end
            end
        end
        
        DEFAULT_CHAT_FRAME:AddMessage("  " .. filterName .. ": " .. tostring(result))
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("--- FORGE FILTER RESULTS ---")
    -- Test each forge filter option
    for _, choice in ipairs(FORGE_FILTER_CHOICES) do
        local filterValue = choice[1]
        local filterName = choice[2]
        
        -- Simulate the filter logic
        local result = true
        if filterValue then
            if not forgeLevel then
                result = (filterValue == -1)  -- Only pass if filter is "Unattuned"
            else
                result = (forgeLevel <= filterValue)
            end
        end
        
        DEFAULT_CHAT_FRAME:AddMessage("  " .. filterName .. ": " .. tostring(result))
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("=================================")
end

