-- Synastria: Equipment Slot Filtering
-- This file adds filtering UI for equipment slots (head, feet, legs, etc.)

-- Debug: Confirm this file is loaded
if Skillet then
    Skillet.slotFilterLoaded = true
end

-- Equipment slot filter options
local SLOT_FILTER_CHOICES = {
    { nil,                      'All Slots' },
    { 'WEAPONS_ALL',            'All Weapons' },
    { 'INVTYPE_CLOAK',          'Back' },
    { 'INVTYPE_BAG',            'Bag' },
    { 'INVTYPE_CHEST',          'Chest' },
    { 'INVTYPE_FEET',           'Feet' },
    { 'INVTYPE_FINGER',         'Finger' },
    { 'INVTYPE_HAND',           'Hands' },
    { 'INVTYPE_HEAD',           'Head' },
    { 'INVTYPE_HOLDABLE',       'Held In Off-hand' },
    { 'INVTYPE_LEGS',           'Legs' },
    { 'INVTYPE_WEAPONMAINHAND', 'Main Hand' },
    { 'INVTYPE_NECK',           'Neck' },
    { 'INVTYPE_WEAPONOFFHAND',  'Off Hand' },
    { 'INVTYPE_WEAPON',         'One-Hand' },
    { 'INVTYPE_RANGED',         'Ranged' },
    { 'INVTYPE_RELIC',          'Relic' },
    { 'INVTYPE_SHIELD',         'Shield' },
    { 'INVTYPE_SHOULDER',       'Shoulders' },
    { 'INVTYPE_THROWN',         'Thrown' },
    { 'INVTYPE_TRINKET',        'Trinket' },
    { 'INVTYPE_2HWEAPON',       'Two-Hand' },
    { 'INVTYPE_WAIST',          'Waist' },
    { 'INVTYPE_WRIST',          'Wrists' },
}

-- Weapon slot types for "All Weapons" filter
local WEAPON_SLOTS = {
    INVTYPE_WEAPON = true,
    INVTYPE_2HWEAPON = true,
    INVTYPE_WEAPONMAINHAND = true,
    INVTYPE_WEAPONOFFHAND = true,
    INVTYPE_RANGED = true,
    INVTYPE_THROWN = true,
}

-- Initialize slot filter dropdown values
local function SetSlotFilterValues(self, level, menuList)
    local info = UIDropDownMenu_CreateInfo()

    for _, choice in ipairs(SLOT_FILTER_CHOICES) do
        info.text = choice[2]
        info.func = function()
            UIDropDownMenu_SetText(Skillet.slotFilterDropdown, choice[2])
            Skillet:SetSlotFilter(choice[1])
        end
        UIDropDownMenu_AddButton(info, level)
    end
end

-- Create the slot filter dropdown (called from CreateTradeSkillWindow)
function Skillet:CreateSlotFilter(parent)
    -- Make sure SkilletSortAscButton exists first
    if not SkilletSortAscButton then
        self:Print("Error: SkilletSortAscButton not found when creating slot filter")
        return
    end

    -- Slot filter dropdown
    self.slotFilterDropdown = CreateFrame('Frame', 'SkilletSlotFilterDropdown', parent, 'UIDropDownMenuTemplate')
    self.slotFilterDropdown:SetPoint('LEFT', SkilletSortAscButton, 'RIGHT', -10, 0)
    UIDropDownMenu_Initialize(self.slotFilterDropdown, SetSlotFilterValues)
    UIDropDownMenu_SetWidth(self.slotFilterDropdown, 100)
    UIDropDownMenu_SetText(self.slotFilterDropdown, 'All Slots')
end

-- Set the slot filter
function Skillet:SetSlotFilter(filterValue)
    if not self.currentTrade then return end

    self:SetTradeSkillOption(self.currentTrade, "slotfilter", filterValue)
    self:UpdateTradeSkillWindow()
end

-- Update slot filter dropdown to show current value
function Skillet:UpdateSlotFilterUI()
    if not self.slotFilterDropdown or not self.currentTrade then return end

    local filterValue = self:GetTradeSkillOption(self.currentTrade, "slotfilter")

    -- Find the display text for this filter value
    local displayText = 'All Slots' -- default
    for _, choice in ipairs(SLOT_FILTER_CHOICES) do
        if choice[1] == filterValue then
            displayText = choice[2]
            break
        end
    end

    UIDropDownMenu_SetText(self.slotFilterDropdown, displayText)
end

-- Check if an item matches the slot filter
function Skillet:MatchesSlotFilter(recipeIndex)
    local filterValue = self:GetTradeSkillOption(self.currentTrade, "slotfilter")

    if not filterValue then
        return true -- No filter active, show all items
    end

    -- Get the crafted item link
    local itemLink = self:GetTradeskillItemLink(recipeIndex)
    if not itemLink then
        return false -- Hide items with no link when filter is active
    end

    local itemId = self:GetItemIDFromLink(itemLink)
    if not itemId then
        return false -- Hide if we can't get item ID
    end

    -- Check if it's equippable
    local isEquippable = IsEquippableItem(itemId) or IsEquippableItem(itemLink)
    if not isEquippable then
        return false -- Hide non-equippable items when slot filter is active
    end

    -- Get the equipment slot type
    local _, _, _, _, _, _, _, _, equipSlot = GetItemInfo(itemId)
    if not equipSlot then
        -- Try getting it from the link if itemId didn't work
        _, _, _, _, _, _, _, _, equipSlot = GetItemInfo(itemLink)
    end

    if not equipSlot or equipSlot == "" then
        -- DEBUG: Print what we got
        self:Print("DEBUG: No equipSlot for itemId=" .. tostring(itemId) .. " link=" .. tostring(itemLink))
        return false -- Hide if we can't determine slot
    end

    -- Special handling for "All Weapons" filter
    if filterValue == "WEAPONS_ALL" then
        local isWeapon = WEAPON_SLOTS[equipSlot]
        if not isWeapon then
            self:Print("DEBUG: Not a weapon - equipSlot='" .. tostring(equipSlot) .. "' itemId=" .. tostring(itemId))
        end
        return isWeapon or false
    end

    -- Check if the slot matches the filter
    return (equipSlot == filterValue)
end
