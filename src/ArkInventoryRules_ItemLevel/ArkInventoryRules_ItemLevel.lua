-- ʕ •ᴥ•ʔ✿ ArkInventory Rules - Item Level Filter ✿ ʕ •ᴥ•ʔ
-- Praise the Omnissiah! This module provides item level filtering based on equipped gear average.

---@diagnostic disable: undefined-global

---@class ArkInventoryRulesModule
---@field OnEnable fun(self: ArkInventoryRulesModule, ...)
---@field belowavgilvl fun(...: any): boolean
---@field belowahsetavgilvl fun(...: any): boolean

---@type table<string, table>
_G.ArkInventoryRules = _G.ArkInventoryRules or {}

---@type table<string, string>
_G.AHSetList = _G.AHSetList or {}

---@type table<string, unknown>
_G.ArkInventory = _G.ArkInventory or { Localise = {} }

---@type function | nil
local CreateFrame = _G.CreateFrame

---@type function | nil
local GetItemInfo = _G.GetItemInfo

---@type function | nil
local GetInventorySlotInfo = _G.GetInventorySlotInfo

---@type function | nil
local GetInventoryItemLink = _G.GetInventoryItemLink

---@diagnostic enable: undefined-global
---@diagnostic disable: need-check-nil

---@type ArkInventoryRulesModule
local rule = ArkInventoryRules:NewModule('ArkInventoryRules_ItemLevel')

-- ʕ •ᴥ•ʔ✿ Registration function ✿ ʕ •ᴥ•ʔ
---@return nil
local function RegisterRules()
    if not ArkInventoryRules then
        print("|cffff0000[ArkInventoryRules_ItemLevel]|r ERROR: ArkInventoryRules not loaded!")
        return
    end

    ArkInventoryRules.Register(rule, 'BELOWAVGILVL', rule.belowavgilvl)
    ArkInventoryRules.Register(rule, 'BELOWAHSETAVGILVL', rule.belowahsetavgilvl)
    print(
        "|cffffd200[ArkInventoryRules_ItemLevel]|r Module loaded, belowavgilvl() and belowahsetavgilvl() rules registered")
end

-- ʕ •ᴥ•ʔ✿ Register the belowavgilvl() rule when the addon loads ✿ ʕ •ᴥ•ʔ
---@return nil
function rule:OnEnable()
    RegisterRules()
end

-- ʕ •ᴥ•ʔ✿ Fallback registration via event ✿ ʕ •ᴥ•ʔ
---@type Frame
local frame = CreateFrame("Frame") or error("Failed to create frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "ArkInventoryRules" or addonName == "ArkInventoryRules_ItemLevel" then
        if ArkInventoryRules and ArkInventoryRules.Register then
            RegisterRules()
            frame:UnregisterEvent("ADDON_LOADED")
        end
    end
end)

-- ʕ •ᴥ•ʔ✿ Helper function to calculate average equipped item level ✿ ʕ •ᴥ•ʔ
---@return number Average item level or 0 if no items equipped
local function CalculateEquippedAverageItemLevel()
    -- Define all equipment slots we want to consider
    ---@type string[]
    local equipmentSlots = {
        "HeadSlot",
        "NeckSlot",
        "ShoulderSlot",
        "BackSlot",
        "ChestSlot",
        "WristSlot",
        "HandsSlot",
        "WaistSlot",
        "LegsSlot",
        "FeetSlot",
        "Finger0Slot",
        "Finger1Slot",
        "Trinket0Slot",
        "Trinket1Slot",
        "MainHandSlot",
        "SecondaryHandSlot",
        "RangedSlot"
        -- Explicitly excluding: ShirtSlot, TabardSlot
    }

    ---@type number
    local totalItemLevel = 0
    ---@type integer
    local itemCount = 0

    -- Iterate through each equipment slot
    for _, slotName in ipairs(equipmentSlots) do
        ---@type integer | nil
        local slotID = GetInventorySlotInfo(slotName)
        if slotID then
            ---@type string | nil
            local itemLink = GetInventoryItemLink("player", slotID)
            if itemLink then
                -- Get item info to extract item level
                ---@type string | nil, string | nil, integer | nil, integer | nil
                local _, _, _, itemLevel = GetItemInfo(itemLink)

                if itemLevel and itemLevel > 0 then
                    totalItemLevel = totalItemLevel + itemLevel
                    itemCount = itemCount + 1
                end
            end
        end
    end

    -- Return average, or 0 if no items equipped
    if itemCount > 0 then
        return totalItemLevel / itemCount
    else
        return 0
    end
end

-- ʕ •ᴥ•ʔ✿ BELOWAVGILVL Rule Implementation ✿ ʕ •ᴥ•ʔ
-- Returns true if the item's level is below the average of equipped items
-- Usage: belowavgilvl() - matches items below equipped average
-- Usage: belowavgilvl(X) - matches items below (average - X), useful for threshold adjustment
---@return boolean Whether the item is below average equipped level
function rule.belowavgilvl(...)
    -- Ensure we're evaluating an item
    if not ArkInventoryRules.Object.h or ArkInventoryRules.Object.class ~= 'item' then
        return false
    end

    ---@type string
    local fn = 'belowavgilvl'
    ---@type integer
    local ac = select('#', ...)

    -- Get the item level of the current item being evaluated
    ---@type string | nil, string | nil, integer | nil, integer | nil
    local _, _, _, currentItemLevel = GetItemInfo(ArkInventoryRules.Object.h)

    if not currentItemLevel or currentItemLevel == 0 then
        return false
    end

    -- Calculate the average item level of equipped gear
    ---@type number
    local averageEquippedLevel = CalculateEquippedAverageItemLevel()

    if averageEquippedLevel == 0 then
        -- No equipped items to compare against
        return false
    end

    -- If no arguments, compare directly to average
    if ac == 0 then
        return currentItemLevel < averageEquippedLevel
    end

    -- If offset argument provided, adjust the threshold
    ---@type any
    local offset = select(1, ...)
    if type(offset) ~= "number" then
        error(string.format(ArkInventory.Localise["RULE_FAILED_ARGUMENT_IS_INVALID"], fn, 1,
            string.format("%s", ArkInventory.Localise["NUMBER"]), 0))
    end

    -- Compare against (average - offset)
    -- Positive offset means "below average by at least X levels"
    -- Negative offset means "below average, but within X levels of it"
    return currentItemLevel < (averageEquippedLevel - offset)
end

-- ʕ •ᴥ•ʔ✿ Helper function to calculate average AHSet item level ✿ ʕ •ᴥ•ʔ
---@return number Average item level or 0 if no items found
local function CalculateAHSetAverageItemLevel()
    -- Ensure AHSetList exists
    if not AHSetList then
        return 0
    end

    ---@type number
    local totalItemLevel = 0
    ---@type integer
    local itemCount = 0

    -- Iterate through all items in AHSetList
    for itemName, slotName in pairs(AHSetList) do
        -- Try to get the item link from equipped items first
        ---@type integer | nil
        local slotID = GetInventorySlotInfo(slotName)
        if slotID then
            ---@type string | nil
            local itemLink = GetInventoryItemLink("player", slotID)
            if itemLink then
                -- Verify this is actually the item we're looking for
                ---@type string | nil
                local equippedName = GetItemInfo(itemLink)
                if equippedName == itemName then
                    -- Get item level
                    ---@type string | nil, string | nil, integer | nil, integer | nil
                    local _, _, _, equippedItemLevel = GetItemInfo(itemLink)
                    if equippedItemLevel and equippedItemLevel > 0 then
                        totalItemLevel = totalItemLevel + equippedItemLevel
                        itemCount = itemCount + 1
                    end
                end
            end
        end
    end

    -- Return average, or 0 if no items found
    if itemCount > 0 then
        return totalItemLevel / itemCount
    else
        return 0
    end
end

-- ʕ •ᴥ•ʔ✿ BELOWAHSETAVGILVL Rule Implementation ✿ ʕ •ᴥ•ʔ
-- Returns true if the item's level is below the average of AHSet items
-- Usage: belowahsetavgilvl() - matches items below AHSet average
-- Usage: belowahsetavgilvl(X) - matches items below (average - X)
---@return boolean Whether the item is below average AHSet level
function rule.belowahsetavgilvl(...)
    -- Ensure we're evaluating an item
    if not ArkInventoryRules.Object.h or ArkInventoryRules.Object.class ~= 'item' then
        return false
    end

    ---@type string
    local fn = 'belowahsetavgilvl'
    ---@type integer
    local ac = select('#', ...)

    -- Get the item level of the current item being evaluated
    ---@type string | nil, string | nil, integer | nil, integer | nil
    local _, _, _, currentItemLevel = GetItemInfo(ArkInventoryRules.Object.h)

    if not currentItemLevel or currentItemLevel == 0 then
        return false
    end

    -- Calculate the average item level of AHSet items
    ---@type number
    local averageAHSetLevel = CalculateAHSetAverageItemLevel()

    if averageAHSetLevel == 0 then
        -- No AHSet items to compare against
        return false
    end

    -- If no arguments, compare directly to average
    if ac == 0 then
        return currentItemLevel < averageAHSetLevel
    end

    -- If offset argument provided, adjust the threshold
    ---@type any
    local offset = select(1, ...)
    if type(offset) ~= "number" then
        error(string.format(ArkInventory.Localise["RULE_FAILED_ARGUMENT_IS_INVALID"], fn, 1,
            string.format("%s", ArkInventory.Localise["NUMBER"]), 0))
    end

    -- Compare against (average - offset)
    return currentItemLevel < (averageAHSetLevel - offset)
end
