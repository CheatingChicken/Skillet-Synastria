--[[

LibPossessions: A library for accessing inventory information from other mods
Copyright (c) 2007 Robert Clark <nogudnik@gmail.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

]] --

---@class LibPossessions
---@field cache table<number | string, number> Item count cache
---@field version string Library version string
---@field supportedAddons table<string, (fun(itemId: number): number | nil) | nil> Supported addon methods
---@field inventoryAddon string? Currently selected inventory addon

---@type string
local MAJOR_VERSION = "LibPossessions"
---@type number
local MINOR_VERSION = tonumber(("$Revision: 164 $"):match("(%d+)")) or 0
local COMMON_API    = "Common API" -- do not localize

-- Ace addons will store realm data under "realm - faction"
---@type string
local playerrealm   = (GetRealmName() or ""):trim()
---@type string | nil
local _, race       = UnitRace("player")
---@type string
local PLAYER        = (UnitName("player") or "Unknown") --[[@as string]]
---@type string
local faction
if race == "Orc" or race == "Scourge" or race == "Troll" or race == "Tauren" or race == "BloodElf" then
    faction = (FACTION_HORDE or "Horde") --[[@as string]]
else
    faction = (FACTION_ALLIANCE or "Alliance") --[[@as string]]
end

-- ========================================================================
--                              Utility Code
-- ========================================================================
--
-- Prints a message to the chat window.
--
---@param message string The message to print
---@return nil
local function print(message)
    ---@type string
    local s = "|cffffff7f" .. MAJOR_VERSION .. "-" .. tostring(MINOR_VERSION) .. "|r: "
    DEFAULT_CHAT_FRAME:AddMessage(s .. message)
end

--
-- Prints the provided message to the chat window if debugging is enabled
--
---@type boolean
local debug_on = false
---@param message string The message to debug print
---@return nil
local function debug(message)
    if debug_on then print(message) end
end

-- ========================================================================
--                            Sanity2 Methods
-- ========================================================================

-- Returns the total count of the provided item id across all characters
-- for which Sanity2 has data.
---@param item number Item ID
---@return number count Total count across characters
local function sanity_GetItemCount(item)
    ---@type string | nil
    local name = GetItemInfo(item)
    if not name then return 0 end

    ---@type table<string, table> | nil
    local owners = Sanity:GetOwnersFor(name)
    if not owners then return 0 end

    ---@type number
    local count = 0
    if not owners then return 0 end
    ---@type table<string, table>
    local ownersData = owners
    ---@type string, table
    for char, v in pairs(ownersData) do
        -- NB: We skip the current player. That info is dynamnic and should
        --     not be included in the values we return.
        if char ~= PLAYER then
            ---@type table<string | number, number>
            local locData = v
            ---@type string | number
            for loc in pairs(locData) do
                ---@type number
                local ct = (locData[loc] or 0)
                count = count + (tonumber(ct) or 0)
            end
        end
    end

    return count
end

-- ========================================================================
--                            Bagnon_Forever Methods
-- ========================================================================

-- Returns the total count of the provided item id across all characters
-- for which Bagnon_Forever has data.
---@param item number Item ID
---@return number count Total count
local function bagnondb_GetItemCount(item)
    ---@type string | nil
    local itemLink = select(2, GetItemInfo(item))
    if not itemLink then return 0 end

    ---@type number
    local count = 0
    ---@type string
    for playerName in BagnonDB:GetPlayers() do
        -- NB: We skip the current player. That info is dynamnic and should
        --     not be included in the values we return.
        if playerName ~= PLAYER then
            ---@diagnostic disable-next-line: need-check-nil
            for bag = 0, (NUM_BAG_SLOTS or 0) do
                ---@type number
                count = count + (BagnonDB:GetItemCount(itemLink, bag, playerName) or 0)
            end
        end
    end

    return count
end

-- ========================================================================
--                   Character Info Storage Methods
-- ========================================================================

-- Returns the total count of the provided item id across all characters
-- for which Character Info Storage has data.
---@param itemid number Item ID
---@return number count Total count
local function characterinfostorage_GetItemCount(itemid)
    ---@type number
    local count = 0
    ---@type string[]
    local characters = CharacterInfoStorage:GetCharacters()

    ---@type string
    for _, name in pairs(characters) do
        -- NB: We skip the current player. That info is dynamnic and should
        --     not be included in the values we return.
        if name ~= PLAYER then
            local has = CharacterInfoStorage:GetNumItems(name, itemid)
            count = count + CharacterInfoStorage:GetNumItems(name, itemid)
        end
    end

    return count
end

-- ========================================================================
--                        BankItems Methods
-- ========================================================================
---@param itemid number Item ID
---@return number count Total count
local function bankitems_GetItemCount(itemid)
    ---@type number
    local count = 0

    -- List of bag numbers used internally by BankItems
    -- Don't include bag 103 (contains items on AH)
    ---@type integer[]
    local BAGNUMBERS = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 100, 101, 102, -2 }

    -- kind of icky, this requires way too much knowledge about the
    -- internal structure of the BankItems data storage. This is extracted
    -- from the BankItems_Search method

    playerrealm = strtrim(playerrealm)

    ---@type string, table
    for key, bankPlayer in pairs(BankItems_Save) do
        ---@type string, string
        local player, realm = strsplit("|", key)

        -- NB: We skip the current player. That info is dynamnic and should
        --     not be included in the values we return.
        if player ~= PLAYER then
            if type(bankPlayer) == "table" and realm == playerrealm then
                for num = 1, 28 do
                    ---@type BankItemSlot | nil
                    local slot = bankPlayer[num] --[[@as BankItemSlot | nil]]
                    if slot then
                        ---@type number | nil
                        local id = select(3, string.find(slot.link, "|Hitem:(%d+):"))
                        if tonumber(id) == itemid then
                            count = count + (slot.count or 1)
                        end
                    end
                end
                for _, bagNum in ipairs(BAGNUMBERS) do
                    ---@type BankItemBag | nil
                    local theBag = bankPlayer["Bag" .. bagNum] --[[@as BankItemBag | nil]]
                    if theBag then
                        ---@type number
                        local realSize = (theBag.size or 0)
                        if bagNum == 101 or bagNum == 103 then
                            realSize = #theBag
                        end
                        ---@type integer
                        for bagItem = 1, realSize do
                            ---@type BankItemSlot | nil
                            local slot = theBag[bagItem] --[[@as BankItemSlot | nil]]
                            if slot then
                                ---@type number | nil
                                local id = select(3, string.find(slot.link, "|Hitem:(%d+):"))
                                if tonumber(id) == itemid then
                                    count = count + (slot.count or 1)
                                end
                            end
                        end
                    end
                end
            end
        end -- player ~= PLAYER
    end

    return count
end

-- ========================================================================
--                        Possessions Methods
-- ========================================================================
---@param itemid number Item ID
---@return number count Total count
local function possessions_GetItemCount(itemid)
    ---@type number
    local count = 0

    if not PossessionsData or not PossessionsData[playerrealm] then
        -- error message here?
        return 0
    end

    ---@type table<string, PossessionsCharData>
    local realmData = PossessionsData[playerrealm] --[[@as table<string, PossessionsCharData>]]
    ---@type string, PossessionsCharData
    for charName, charData in pairs(realmData) do
        -- NB: We skip the current player. That info is dynamnic and should
        --     not be included in the values we return.
        if charName ~= PLAYER then
            ---@type table<number, PossessionsBagItem[]>
            local bagData = charData.items --[[@as table<number, PossessionsBagItem[]>]]
            ---@type number, PossessionsBagItem[]
            for _, bag in pairs(bagData) do
                ---@type PossessionsBagItem
                for _, item in pairs(bag) do
                    ---@type string | nil
                    local idStr = item[1]
                    if idStr then
                        ---@type string | nil
                        local matchStr = idStr:match("^(%d+):?")
                        ---@type number
                        local id = 0
                        if matchStr then
                            id = tonumber(matchStr) or 0
                        end
                        if itemid == id then
                            count = count + (item[3] or 0)
                        end
                    end
                end
            end
        end
    end

    return count
end

-- ========================================================================
--                        BankList Methods
-- ========================================================================
---@param itemid number Item ID
---@return number count Total count
local function banklist_GetItemCount(itemid)
    ---@type number
    local count = 0

    if not BankList.db or not BankList.db.realm or not BankList.db.realm.chars then
        -- error here?
        return 0
    end

    ---@type string, BankListCharData
    for charName, charData in pairs(BankList.db.realm.chars) do
        -- NB: We skip the current player. That info is dynamnic and should
        --     not be included in the values we return.
        if charName ~= PLAYER then
            ---@type BankListItemData[]
            for _, bag in pairs(charData.bags) do
                ---@type BankListItemData
                for _, itemData in pairs(bag) do
                    ---@type number | nil
                    local id = itemData.id:match('item:(%d+)')
                    if id then
                        ---@type number
                        id = tonumber(id) or 0
                        if id == itemid then
                            count = count + (itemData.count or 0)
                        end
                    end
                end
            end
        end
    end

    return count
end

-- ========================================================================
--                        OneView (OneBag) Methods
-- ========================================================================
---@param itemid number Item ID
---@return number count Total count
local function oneview_GetItemCount(itemid)
    ---@type number
    local count = 0

    ---@type table<number, table>
    local list = OneView.storage:GetCharListByServerId()
    ---@type number, table
    for serverId, v in pairs(list) do
        ---@type string
        local fact = (v.faction or "Alliance") --[[@as string]]
        ---@type table
        local charData = v
        ---@type integer
        for k in ipairs(charData) do
            ---@type string
            local v2 = charData[k]
            ---@type string | nil, string | nil
            local charName, charId = v2:match("([^%-]+) . (.+)")
            -- NB: We skip the current player. That info is dynamnic and should
            --     not be included in the values we return.
            if charName and charName ~= PLAYER then
                ---@type integer
                for bag = -1, 11 do
                    ---@type number, number, boolean, boolean, boolean
                    local itemId, size, isAmmo, isSoul, isProf = OneView.storage:BagInfo(fact,
                        (tonumber(charId) or 0) --[[@as number]], bag)
                    ---@type integer
                    for slot = 1, (tonumber(size) or 0) do
                        ---@type string | nil, number | nil
                        local bag_itemId, qty = OneView.storage:SlotInfo(fact, (tonumber(charId) or 0) --[[@as number]],
                            bag, slot)
                        if bag_itemId then
                            ---@type number
                            local id = tonumber(bag_itemId:match('item:(%d+)')) or -1
                            if id == itemid then
                                ---@type number
                                if type(qty) == "string" then qty = tonumber(qty) or 0 end
                                count = count + (qty or 0)
                            end
                        end
                    end
                end
            end
        end
    end

    return count
end

-- ========================================================================
--                        ArkInventory Methods
-- ========================================================================
---@type boolean
local ark_warned = false
---@param itemid number Item ID
---@return number count Total count
local function arkinventory_GetItemCount(itemid)
    ---@type string
    local r = (GetRealmName() or "") --[[@as string]]
    ---@type string
    local f = (UnitFactionGroup("player") or "Alliance") --[[@as string]]

    if not ArkInventory.Const.TOC or ArkInventory.Const.TOC < 30000 then
        -- this is the old ark format
        if not ark_warned then
            error(
                "Only version 3.01 (or later) of ArkInventory is supported. You will have to upgrade to be able to use it with Skillet.")
            ark_warned = true
        end
        return 0
    end

    ---@type number
    local item_count_total = 0

    ---@type number, ArkInventoryPlayer
    for pid, pd in ArkInventory.spairs(ArkInventory.db.global.player.realm[r].faction[f].name) do
        -- NB: We skip the current player. That info is dynamic and should
        --     not be included in the values we return.
        if pd.info.name ~= PLAYER and pd.info.realm == r and pd.info.faction == f then
            ---@type string, ArkInventoryLocationData
            for l, ld in pairs(pd.location) do
                if l ~= ArkInventory.Const.Location.Vault then
                    -- we don't want to include guild vaults
                    ---@type string, ArkInventoryBag
                    for b, bd in pairs(ld.bag) do
                        ---@type number, ArkInventorySlotData | nil
                        for s, sd in pairs(bd.slot) do
                            if sd and sd.h then
                                ---@type string | nil
                                local id = ArkInventory:ObjectStringDecodeItem(sd.h)
                                if id and itemid == tonumber(id) then
                                    -- print( sd.h .. " found [" .. sd.count .. "] in bag [" .. b .. "] slot [" .. s .. "] on [" .. pd.info.name .. "]" )
                                    item_count_total = item_count_total + (sd.count or 0)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return item_count_total
end

-- ========================================================================
--                        Baggins_AnywhereBags Methods
-- ========================================================================

---@type fun(itemid: number): number
local baggins_GetItemCount
do
    ---@type boolean | nil
    local warned
    ---@param itemid number Item ID
    ---@return number count Item count
    function baggins_GetItemCount(itemid)
        if BagginsAnywhereBags.GetItemCount then
            return BagginsAnywhereBags:GetItemCount(itemid)
        end

        if not warned then
            ChatFrame1:AddMessage(MAJOR_VERSION ..
                ": Baggins_AnywhereBags needs to be upgraded to be able to count items on alts. (BagginsAnywhereBags.GetItemCount is missing)")
            warned = true
        end

        return 0
    end
end

-- ========================================================================
--                         Library Initialization
-- ========================================================================

---@type table | nil
local LibPossessions
---@type number | nil
local oldMinor
LibPossessions, oldMinor = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not LibPossessions then
    -- A copy of this particular library has already been loaded
    return
end

-- And put the newly created/discovered library into the global namespace
_G.LibPossessions = LibPossessions

-- And a place to cache item lookups, for speed.
---@type table<number | string, number>
local cache = LibPossessions.cache or ({ n = 0 })
LibPossessions.cache = cache

-- And the version of the library
LibPossessions.version = MAJOR_VERSION .. "-" .. MINOR_VERSION

-- @table supportedAddons
-- @brief A list of the inventory addons supported by this library
---@type table<string, fun(itemId: number): number>
LibPossessions.supportedAddons = {
    -- GetInventoryCount might be nil and that would remove the entry
    -- [COMMON_API]                = (GetInventoryCount or ""),
    ["CharacterInfoStorage"] = characterinfostorage_GetItemCount,
    ["Sanity2"]              = sanity_GetItemCount,
    ["BankItems"]            = bankitems_GetItemCount,
    ["Possessions"]          = possessions_GetItemCount,
    ["BankList"]             = banklist_GetItemCount,
    ["Bagnon_Forever"]       = bagnondb_GetItemCount,
    ["OneView"]              = oneview_GetItemCount, -- Requires OneBag and OneBank as well.
    ["ArkInventory"]         = arkinventory_GetItemCount,
    ["Baggins_AnywhereBags"] = baggins_GetItemCount,
}

-- Currently selected inventory addon
LibPossessions.inventoryAddon = LibPossessions.inventoryAddon or nil

--
-- Searches for a supported addon. Does nothing is an addon has
-- already been found
--
---@param lib LibPossessions The library instance
---@return nil
local function find_supported_addon(lib)
    if not lib.inventoryAddon then
        -- Always check for the common API first
        if GetInventoryCount then
            debug("Using common API")
            lib.inventoryAddon = COMMON_API
        else
            ---@type integer
            for i = 1, GetNumAddOns() do
                ---@type string
                local name = GetAddOnInfo(i)
                for k, v in pairs(lib.supportedAddons) do
                    if k == name and IsAddOnLoaded(name) then
                        -- found one!
                        lib:SetInventoryAddon(k)
                        return
                    end
                end
                -- debug("Skipped: " .. name)
            end

            -- no addon found
            lib.inventoryAddon = "None"
        end
    end
end

-- ========================================================================
--                              Public API
-- ========================================================================

--
-- @method      SetInventoryAddon
-- @brief       Sets the name of the add on to be used for collecting
--              inventory information. This must be one of the addons
--              supported by this library.
-- @param addon Name of the addon to use.
-- @return      true if the addon is usable and false if it is not.
--
---@param self LibPossessions
---@param addon string The addon name
---@return boolean success Whether addon was successfully set
function LibPossessions:SetInventoryAddon(addon)
    if IsAddOnLoaded(addon) and self.supportedAddons[addon] then
        self.inventoryAddon = addon
        debug("Using " .. addon .. " as the inventory addon")
        return true
    else
        error(MAJOR_VERSION .. ": Cannot use " .. addon .. " as an inventory addon as it is not supported")
        return false
    end
end

--
-- @method      IsAvailable
-- @brief       Checks to see whether or not a support
--              inventory mod is available
-- @return      true is a supported mod was found or false otherwise
--
---@param self LibPossessions
---@return boolean available Whether an inventory addon is available
function LibPossessions:IsAvailable()
    if self.inventoryAddon == nil then
        find_supported_addon(self)
    end
    return self.inventoryAddon ~= nil and self.inventoryAddon ~= "None"
end

--
-- @method      GetVersion
-- @brief       Gets the version of the current library
-- @return      The vesion of the LibPossessions library currently in use.
--
---@param self LibPossessions
---@return string version The library version
function LibPossessions:GetVersion()
    return self.version
end

--
-- @method      GetSupportedAddons
-- @brief       Lists the addon supported by this library. Addons in the
--              list may or may not be loaded
-- @return      The list of supported inventory addon names
--
---@param self LibPossessions
---@return string[] addons List of supported addon names
function LibPossessions:GetSupportedAddons()
    ---@type string[]
    local addons = {}

    for name, _ in pairs(self.supportedAddons) do
        table.insert(addons, name)
    end

    return addons
end

--
-- @method      GetSelectedAddon
-- @brief       The name of the addon currently selected to provide
--              inventory information or nil if no addon is selected
-- @return      The name of the inventory addon currently being used
--
---@param self LibPossessions
---@return string? addonName The selected addon name or nil
function LibPossessions:GetSelectedAddon()
    if self.inventoryAddon == nil then
        find_supported_addon(self)
    end
    return self.inventoryAddon
end

--
-- @method      GetItemCount
-- @brief       Returns the number of items across all alts (including
--              the current character)
-- @param item  The itemID of the item your are interested
-- @return      The count of the specified it across all characters, or 0
--
---@param self LibPossessions
---@param item number | string Item ID or item link
---@return number total Total count across all characters
---@return number current Current character count
---@return number alts Alt count
function LibPossessions:GetItemCount(item)
    ---@type number
    if type(item) ~= "number" then item = tonumber(item) or 0 end

    -- count of the items the currect character has in their bags and
    -- inventory. This can change during the course of the session.
    ---@type number
    local current_character_count = (GetItemCount(item, true) or 0) --[[@as number]]

    ---@type number
    local alt_count = 0
    if not cache[item] then
        -- Item is not yet cached. Cache it now. We only store counts for
        -- alts, which cannot change during the course of a session.

        find_supported_addon(self)

        if self:IsAvailable() then
            ---@type fun(itemId: number): number | nil
            local method = self.supportedAddons[self.inventoryAddon]
            ---@type boolean, any
            local ok, count = pcall(method, item) --[[@as boolean, any]]
            if not ok then
                -- if there was an error, the second return value from pcall
                -- will be the error message.
                print("Unable to obtain items counts for " ..
                    item .. " using " .. self.inventoryAddon .. ": " .. count .. ". Will no longer use that addon")
                if self.inventoryAddon then
                    ---@type string
                    local addonName = self.inventoryAddon --[[@as string]]
                    self.supportedAddons[addonName] = nil -- remove it from the list
                end
                self.inventoryAddon = nil
                alt_count = 0
            else
                ---@type number
                alt_count = tonumber(count) or 0
                ---@diagnostic disable-next-line: need-check-nil
                cache[item] = alt_count
                cache.n = cache.n + 1
            end
        end
    else
        ---@type number
        alt_count = (cache[item] or 0) --[[@as number]]
    end

    return current_character_count + alt_count, current_character_count, alt_count
end
