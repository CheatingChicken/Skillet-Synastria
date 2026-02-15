-- ʕ •ᴥ•ʔ✿ ArkInventory Rules - AttuneHelper Integration ✿ ʕ •ᴥ•ʔ
-- Praise the Omnissiah! This module bridges the sacred AHSetList with ArkInventory's rule system.

---@diagnostic disable: undefined-global

---@class ArkInventoryRulesModule
---@field OnEnable fun(self: ArkInventoryRulesModule, ...)
---@field ahset fun(...: any): boolean

---@type table<string, table>
_G.ArkInventoryRules = _G.ArkInventoryRules or {}

---@type table<string, string>
_G.AHSetList = _G.AHSetList or {}

---@type table<string, unknown>
_G.AttuneHelperDB = _G.AttuneHelperDB or {}

---@type table<string, unknown>
_G.ArkInventory = _G.ArkInventory or { Localise = {} }

---@type table<string, table>
_G.StaticPopupDialogs = _G.StaticPopupDialogs or {}

---@type table<string, function>
_G.SlashCmdList = _G.SlashCmdList or {}

---@type function | nil
local CreateFrame = _G.CreateFrame

---@type function | nil
local GetItemInfo = _G.GetItemInfo

---@type function | nil
local StaticPopup_Show = _G.StaticPopup_Show

---@type function | nil
local GetInventorySlotInfo = _G.GetInventorySlotInfo

---@type function | nil
local GetInventoryItemLink = _G.GetInventoryItemLink

---@type function | nil
local GetContainerNumSlots = _G.GetContainerNumSlots

---@type function | nil
local GetContainerItemLink = _G.GetContainerItemLink

---@type function | nil
local PickupContainerItem = _G.PickupContainerItem

---@type function | nil
local PickupInventoryItem = _G.PickupInventoryItem

---@diagnostic enable: undefined-global
---@diagnostic disable: need-check-nil

---@type ArkInventoryRulesModule
local rule = ArkInventoryRules:NewModule('ArkInventoryRules_AttuneHelper')

---@type boolean Debug flag - set to true to enable debug messages
local DEBUG_AHSET = false

---@param ... any Arguments to print
---@return nil
local function DebugPrint(...)
    if DEBUG_AHSET then
        print("|cff00ff00[AHSet Debug]|r", ...)
    end
end

-- ʕ •ᴥ•ʔ✿ Registration function ✿ ʕ •ᴥ•ʔ
---@return nil
local function RegisterRules()
    if not ArkInventoryRules then
        print("|cffff0000[ArkInventoryRules_AttuneHelper]|r ERROR: ArkInventoryRules not loaded!")
        return
    end

    ArkInventoryRules.Register(rule, 'AHSET', rule.ahset)
    print("|cffffd200[ArkInventoryRules_AttuneHelper]|r Module loaded, ahset() rule registered")
    print(
        "|cffffd200[ArkInventoryRules_AttuneHelper]|r To enable debug: /run ArkInventoryRules_AttuneHelper_EnableDebug()")
end

-- ʕ •ᴥ•ʔ✿ Register the ahset() rule when the addon loads ✿ ʕ •ᴥ•ʔ
---@return nil
function rule:OnEnable()
    RegisterRules()
end

-- ʕ •ᴥ•ʔ✿ Fallback registration via event ✿ ʕ •ᴥ•ʔ
---@type Frame
local frame = CreateFrame("Frame") or error("Failed to create frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "ArkInventoryRules" or addonName == "ArkInventoryRules_AttuneHelper" then
        -- Try registration after a short delay to ensure everything is loaded
        if ArkInventoryRules and ArkInventoryRules.Register then
            RegisterRules()
            frame:UnregisterEvent("ADDON_LOADED")
        end
    end
end)

-- Global function to enable debugging
---@return nil
function ArkInventoryRules_AttuneHelper_EnableDebug()
    DEBUG_AHSET = true
    print("|cff00ff00[AHSet Debug]|r Debug mode enabled!")
end

-- Global function to disable debugging
---@return nil
function ArkInventoryRules_AttuneHelper_DisableDebug()
    DEBUG_AHSET = false
    print("|cffff0000[AHSet Debug]|r Debug mode disabled!")
end

-- Global function to manually trigger registration (for debugging)
---@return nil
function ArkInventoryRules_AttuneHelper_ForceRegister()
    print("|cffffd200[ArkInventoryRules_AttuneHelper]|r Manually triggering registration...")
    RegisterRules()
end

-- ʕ •ᴥ•ʔ✿ AHSET Rule Implementation ✿ ʕ •ᴥ•ʔ
-- Returns true if the item is in AttuneHelper's AHSetList
-- Usage: ahset() - matches any item in the AHSetList
-- Usage: ahset("SlotName") - matches items designated for specific slot (e.g., "MainHandSlot")
---@return boolean Whether the item matches the ahset rule
function rule.ahset(...)
    DebugPrint("=== ahset() called ===")

    -- Ensure we're evaluating an item
    if not ArkInventoryRules.Object.h or ArkInventoryRules.Object.class ~= 'item' then
        DebugPrint("Not an item or no hyperlink")
        return false
    end

    DebugPrint("Item hyperlink:", ArkInventoryRules.Object.h)

    -- Ensure AHSetList exists (from AttuneHelper)
    if not AHSetList then
        DebugPrint("AHSetList is nil!")
        return false
    end

    DebugPrint("AHSetList exists, item count:",
        (function()
            local c = 0
            for _ in pairs(AHSetList) do c = c + 1 end
            return c
        end)())

    ---@type string
    local fn = 'ahset'
    ---@type integer
    local ac = select('#', ...)

    DebugPrint("Arguments count:", ac)

    -- Get the item name from the item link
    ---@type string | nil
    local itemName = GetItemInfo(ArkInventoryRules.Object.h)
    if not itemName then
        DebugPrint("GetItemInfo returned nil for hyperlink")
        return false
    end

    DebugPrint("Item name:", itemName)

    -- Check if item is in AHSetList
    ---@type string | nil
    local designatedSlot = AHSetList[itemName]
    if not designatedSlot then
        DebugPrint("Item not in AHSetList")
        -- Debug: show first few items in AHSetList
        if DEBUG_AHSET then
            local count = 0
            for name, slot in pairs(AHSetList) do
                if count < 3 then
                    DebugPrint("  AHSetList example:", name, "=>", slot)
                    count = count + 1
                end
            end
        end
        return false
    end

    DebugPrint("Item found in AHSetList, designated slot:", designatedSlot)

    -- If no arguments provided, return true (item is in the set)
    if ac == 0 then
        DebugPrint("No arguments, returning true")
        return true
    end

    -- If slot argument provided, check if it matches the designated slot
    ---@type any
    local arg = select(1, ...)
    DebugPrint("Checking slot argument:", arg)

    if type(arg) ~= "string" then
        error(string.format(ArkInventory.Localise["RULE_FAILED_ARGUMENT_IS_INVALID"], fn, 1,
            string.format("%s", ArkInventory.Localise["STRING"]), 0))
    end

    -- Normalize slot names for comparison (case-insensitive)
    ---@type string
    local normalizedArg = string.lower(arg)
    ---@type string
    local normalizedSlot = string.lower(designatedSlot)

    ---@type boolean
    local result = normalizedArg == normalizedSlot
    DebugPrint("Slot comparison:", normalizedArg, "vs", normalizedSlot, "=>", result)

    return result
end

-- ʕ •ᴥ•ʔ✿ AHSetList Management Commands ✿ ʕ •ᴥ•ʔ
-- These commands allow managing the AHSetList without modifying AttuneHelper

-- Setup AHSet clear confirmation dialog
---@type table
StaticPopupDialogs["ARKINV_AH_CLEAR_AHSET_CONFIRM"] = {
    text = "%s",
    button1 = "Clear All",
    button2 = "Cancel",
    OnAccept = function()
        ---@type integer
        local itemCount = 0
        for _ in pairs(AHSetList or {}) do
            itemCount = itemCount + 1
        end

        AHSetList = {}
        print("|cffffd200[ArkInventoryRules_AttuneHelper]|r Cleared " .. itemCount .. " item(s) from AHSetList.")
    end,
    OnCancel = function()
        print("|cffffd200[ArkInventoryRules_AttuneHelper]|r AHSet clear cancelled.")
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    preferredIndex = 3,
}

-- /ahsetclear command - Clear all items from AHSetList with confirmation
SLASH_ARKINV_AHSETCLEAR1 = "/ahsetclear"
SlashCmdList["ARKINV_AHSETCLEAR"] = function()
    -- Ensure AHSetList exists
    if not AHSetList then
        AHSetList = {}
        print(
            "|cffffd200[ArkInventoryRules_AttuneHelper]|r AHSetList doesn't exist yet (AttuneHelper may not be loaded).")
        return
    end

    -- Count items in AHSetList
    ---@type integer
    local itemCount = 0
    for _ in pairs(AHSetList) do
        itemCount = itemCount + 1
    end

    if itemCount == 0 then
        print("|cffffd200[ArkInventoryRules_AttuneHelper]|r AHSetList is already empty.")
        return
    end

    -- Show confirmation dialog
    ---@type string
    local confirmText = string.format("Clear ALL %d item(s) from your AHSet?", itemCount)
    if StaticPopup_Show then
        StaticPopup_Show("ARKINV_AH_CLEAR_AHSET_CONFIRM", confirmText)
    end
end

-- /ahsetequipall command - Disable auto-equip and equip all AHSet items
SLASH_ARKINV_AHSETEQUIPALL1 = "/ahsetequipall"
SlashCmdList["ARKINV_AHSETEQUIPALL"] = function()
    -- Ensure AHSetList exists
    if not AHSetList then
        print("|cffff0000[ArkInventoryRules_AttuneHelper]|r AHSetList doesn't exist (AttuneHelper may not be loaded).")
        return
    end

    -- Count items in AHSetList
    ---@type integer
    local itemCount = 0
    for _ in pairs(AHSetList) do
        itemCount = itemCount + 1
    end

    if itemCount == 0 then
        print("|cffffd200[ArkInventoryRules_AttuneHelper]|r AHSetList is empty, nothing to equip.")
        return
    end

    -- Disable auto-equip if AttuneHelperDB exists
    ---@type boolean
    local autoEquipWasEnabled = false
    if AttuneHelperDB and AttuneHelperDB["Auto Equip Attunable After Combat"] then
        autoEquipWasEnabled = AttuneHelperDB["Auto Equip Attunable After Combat"] == 1
        AttuneHelperDB["Auto Equip Attunable After Combat"] = 0
        print("|cffffd200[ArkInventoryRules_AttuneHelper]|r Auto-equip disabled.")
    end

    -- Equip all items in AHSetList
    ---@type integer
    local equippedCount = 0
    ---@type integer
    local alreadyEquippedCount = 0
    ---@type integer
    local notFoundCount = 0

    for itemName, slotName in pairs(AHSetList) do
        ---@type integer | nil
        local slotID = GetInventorySlotInfo(slotName)
        if slotID then
            -- Check if item is already equipped in the correct slot
            ---@type boolean
            local skipItem = false
            ---@type string | nil
            local currentlyEquippedLink = GetInventoryItemLink("player", slotID)
            if currentlyEquippedLink then
                ---@type string | nil
                local currentlyEquippedName = GetItemInfo(currentlyEquippedLink)
                if currentlyEquippedName == itemName then
                    alreadyEquippedCount = alreadyEquippedCount + 1
                    print("|cff808080[ArkInventoryRules_AttuneHelper]|r Already equipped: " .. itemName)
                    skipItem = true
                end
            end

            if not skipItem then
                -- Search bags for the item
                ---@type integer | nil
                local foundBag = nil
                ---@type integer | nil
                local foundSlot = nil

                for bag = 0, 4 do
                    ---@type integer | nil
                    local numSlots = GetContainerNumSlots(bag)
                    if numSlots then
                        for slot = 1, numSlots do
                            ---@type string | nil
                            local itemLink = GetContainerItemLink(bag, slot)
                            if itemLink then
                                ---@type string | nil
                                local bagItemName = GetItemInfo(itemLink)
                                if bagItemName == itemName then
                                    foundBag = bag
                                    foundSlot = slot
                                    break
                                end
                            end
                        end
                    end
                    if foundBag then break end
                end

                -- Equip if found
                if foundBag and foundSlot then
                    if PickupContainerItem then
                        PickupContainerItem(foundBag, foundSlot)
                    end
                    if PickupInventoryItem then
                        PickupInventoryItem(slotID)
                    end
                    equippedCount = equippedCount + 1
                    print("|cff00ff00[ArkInventoryRules_AttuneHelper]|r Equipped: " .. itemName .. " to " .. slotName)
                else
                    notFoundCount = notFoundCount + 1
                    print("|cffff9900[ArkInventoryRules_AttuneHelper]|r Not found in bags: " .. itemName)
                end
            end
        end
    end

    -- Summary
    print("|cffffd200[ArkInventoryRules_AttuneHelper]|r === Summary ===")
    print("|cffffd200[ArkInventoryRules_AttuneHelper]|r Newly equipped: " .. equippedCount)
    print("|cffffd200[ArkInventoryRules_AttuneHelper]|r Already equipped: " .. alreadyEquippedCount)
    if notFoundCount > 0 then
        print("|cffffd200[ArkInventoryRules_AttuneHelper]|r Not found: " .. notFoundCount)
    end
end
