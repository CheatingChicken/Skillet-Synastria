--[[
Name: SkilletStitch-1.1
Revision: $Rev: 165 $
Author(s): Nymbia (nymbia@gmail.com)
Website: http://www.wowace.com/wiki/Stitch-1.1
Documentation: http://www.wowace.com/wiki/Stitch-1.1
SVN: http://svn.wowace.com/wowace/trunk/Stitch-1.1/Stitch-1.1/
Description: Library for tradeskill information access and queueing.
Dependencies: AceLibrary, AceEvent-2.0
License: LGPL v2.1
Copyright (C) 2006-2007 Nymbia

  This version has been modified by nogudik@gmail.com for use in
  the Skillet mod and is no longer the identical to the version
  originally written by Nymbia.

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
]]

local MAJOR_VERSION = "SkilletStitch-1.1"
local MINOR_VERSION = "$Rev: 166 $" -- Synastria: Bumped for PT vendor extension

if not AceLibrary then error(MAJOR_VERSION .. " requires AceLibrary") end
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then return end
if not AceLibrary:HasInstance("AceEvent-2.0") then error(MAJOR_VERSION .. " requires AceEvent-2.0") end
---@type any
local AceEvent = AceLibrary("AceEvent-2.0")
---@type any|nil
local PT
if AceLibrary:HasInstance("LibPeriodicTable-3.1") then
    PT = AceLibrary("LibPeriodicTable-3.1")
end

---@class QueueEntry
---@field spellId number The spell ID for the recipe
---@field numcasts number Number of times to craft this recipe
---@field profession string The profession name
---@field name string The recipe display name (persists to SavedVariables)
---@field link string|nil The item link created by this recipe (optional, for cross-references)
---@field recipe Recipe|nil Optional recipe object (runtime only, does not serialize)
---@field isPrimary boolean|nil True if user-queued, false/nil if auto-generated subcraft (Synastria)
---@field conversionType string|nil Conversion type: "combine" or "split" (for Conversion profession)
---@field sourceId number|nil Source item ID (for conversions)
---@field outputId number|nil Output item ID (for conversions)
---@field sourceNeeded number|nil How many source items needed (for conversions)
---@field outputAmount number|nil How many output items created (for conversions)
---@field crystallizedId number|nil Crystallized item ID (backward compat)
---@field eternalId number|nil Eternal item ID (backward compat)
---@field crystallizedNeeded number|nil Crystallized count needed (backward compat)
---@field eternalsToMake number|nil Eternals to make (backward compat)

---@class CacheStats
---@field hits number Number of cache hits
---@field misses number Number of cache misses
---@field calculations number Number of calculations performed

---@class Recipe
---@field name string|nil Recipe name
---@field link string|nil Item link
---@field spellId number|nil Spell ID for the recipe
---@field profession string|nil Profession name
---@field index integer|nil Recipe index
---@field reagents Reagent[]|nil List of required reagents
---@field isVirtualConversion boolean|nil Whether this is a virtual conversion
---@field eternalId number|nil For conversions, the eternal item ID
---@field eternalsToMake number|nil For conversions, number of eternals to make
---@field crystallizedId number|nil For conversions, the crystallized item ID
---@field crystallizedNeeded number|nil For conversions, number of crystallized needed
---@field sourceId number|nil For conversions, source item ID
---@field outputId number|nil For conversions, output item ID
---@field toolItemId number|nil For conversions, the item ID to use (tool or source)
---@field encoded string|nil Encoded recipe data (old format)
---@field difficulty string|nil Difficulty level (computed via metamethod)
---@field nummade number|nil Number of items crafted per cast (computed via metamethod)
---@field texture string|nil Item texture (computed via metamethod)
---@field tools string|nil Required tools (computed via metamethod)
---@field numcraftable number|nil Number crafted items left (computed via metamethod)
---@field numcraftablewbank number|nil Number craftable with bank (computed via metamethod)
---@field numcraftablewalts number|nil Number craftable with alts (computed via metamethod)
---@field header boolean|nil Whether this is a UI header (group category)
---@field needsRescan boolean|nil Whether recipe needs rescanning

---@class Reagent
---@field name string|nil Reagent name
---@field link string|nil Item link
---@field needed number|nil Number required
---@field texture string|nil Item texture
---@field vendor boolean|nil Whether this is a vendor item
---@field num integer|nil Number in inventory (computed via metamethod)
---@field numwbank integer|nil Number in bank (computed via metamethod)
---@field numwalts integer|nil Number on alts (computed via metamethod)

---@class ReservedReagent
---@field name string Item name
---@field link string Item link
---@field count number Count of reserved items
---@field player string|nil Comma-separated list of players

---@class ReagentData
---@field name string Reagent name
---@field link string Item link
---@field needed number Number required
---@field vendor boolean Whether this is a vendor item

---@class RecipeData
---@field encoded string|nil Encoded recipe data (old format)
---@field reagents ReagentData[] Array of reagent data
---@field profession string|nil Profession name
---@field index integer|nil Recipe index
---@field name string|nil Recipe name override
---@field link string|nil Item link
---@field spellId number|nil Canonical recipe spell ID from GetTradeSkillRecipeLink (unique per recipe, avoids product-item ID collisions)

---@class SkilletStitch
---@field hooks table<string, function>|nil Event hooks
---@field data table<string, table<integer, RecipeData>>|nil Recipe data indexed by profession then recipe index
---@field queue QueueEntry[]|nil Queue of items to craft
---@field queueaddons table<string, boolean>
---@field datagatheraddons table<string, boolean>
---@field queueenabled boolean|nil Whether queue is enabled
---@field queuecasting boolean|nil Whether currently crafting from queue
---@field waitingForProfessionSwitch boolean|nil Whether waiting for profession window to open
---@field preCraftItemCount number|nil Item count before craft (for detecting completion)
---@field expectedCraftCount number|nil Expected number of items to craft
---@field craftAttemptTime number|nil Timestamp of last craft attempt
---@field lastCraftError string|nil Last craft error message
---@field customApiAvailable boolean|nil Whether Custom API is available
---@field customApiFailureReported boolean|nil Whether custom API failure has been reported
---@field RegisterEvent fun(self: SkilletStitch, event: string, handler?: string|function)|nil Event registration from AceEvent
---@field UnregisterEvent fun(self: SkilletStitch, event: string)|nil Event unregistration from AceEvent
---@field GetItemDataByIndex fun(self: SkilletStitch, profession: string, index: number): Recipe|nil|nil
---@field DecodeRecipe fun(self: SkilletStitch, datastring: RecipeData): Recipe|nil|nil
---@field ClearCraftabilityCache fun(self: SkilletStitch)|nil Clear the craftability cache
---@field InvalidateCacheForItems fun(self: SkilletStitch, itemIds: number[]): number|nil Invalidate cache for items
---@field GetCacheStats fun(self: SkilletStitch): CacheStats|nil Get cache statistics
---@field SetCachedCraftability fun(self: SkilletStitch, recipe: Recipe, key: string, value: number|nil)|nil Set cached value
---@field GetCachedCraftability fun(self: SkilletStitch, recipe: Recipe, key: string): number|nil|nil Get cached value
---@field GetItemDataBySpellId fun(self: SkilletStitch, spellId: number): Recipe|nil|nil
---@field GetItemDataByName fun(self: SkilletStitch, name: string, prof?: string|number): Recipe|nil|nil
---@field GetItemDataByPartialName fun(self: SkilletStitch, name: string): Recipe[]|nil|nil
---@field GetQueueInfo fun(self: SkilletStitch): QueueEntry[]|nil
---@field GetQueueItemInfo fun(self: SkilletStitch, index: number): table|nil|nil
---@field RemoveFromQueue fun(self: SkilletStitch, index: number)|nil
---@field ClearQueue fun(self: SkilletStitch)|nil
---@field ProcessQueue fun(self: SkilletStitch)|nil
---@field SetReservedReagentsList fun(self: SkilletStitch, reagents: ReservedReagent[]|nil)|nil
---@field CancelCast fun(self: SkilletStitch)|nil
---@field EnableDataGathering fun(self: SkilletStitch, addon: string)|nil
---@field DisableDataGathering fun(self: SkilletStitch, addon?: string)|nil
---@field EnableQueue fun(self: SkilletStitch, addon: string)|nil
---@field DisableQueue fun(self: SkilletStitch, addon?: string)|nil
---@field GetNumSkills fun(self: SkilletStitch, prof: string|nil): number|nil|nil
---@field PopulateRecipeInfoCache fun(self: SkilletStitch)|nil
---@field AddToQueue fun(self: SkilletStitch, spellId: number, numcasts: number, profession: string, addToTop?: boolean, link: string|nil)|nil
---@field GetNumQueuedItems fun(self: SkilletStitch, index?: number): number|nil
---@field SetAltCharacterItemLookupFunction fun(self: SkilletStitch, func: function)|nil
---@field TRADE_SKILL_SHOW fun(self: SkilletStitch)|nil
---@field OnUIError fun(self: SkilletStitch, errorType: string, message: string)|nil
---@field OnSpellcastFailed fun(self: SkilletStitch, event: string, unit: string, spellName: string, rank: string|number)|nil
---@field ProcessCraftCompletion fun(self: SkilletStitch)|nil
---@field ScanTrade fun(self: SkilletStitch)|nil
---@field FindProfessionSpellId fun(self: SkilletStitch, profession: string): number|nil|nil

---@type SkilletStitch
---@diagnostic disable-next-line: missing-fields
local SkilletStitch = {}
SkilletStitch.hooks = {}
SkilletStitch.queueaddons = {}
SkilletStitch.datagatheraddons = {}
-- Use to get item counts from alts. Requires compatible inventory mod/library.
---@type function|nil
local alt_lookup_function = nil

local difficultyt = {
    o = "optimal",
    m = "medium",
    e = "easy",
    t = "trivial",
}
---@type table<string, string>
local difficultyr = {
    optimal = "o",
    medium = "m",
    easy = "e",
    trivial = "t",
}
---@param link string The item link
---@return string squishedLink The squished link
local function squishlink(link)
    -- in:  |cffffffff|Hitem:13928:0:0:0:0:0:0:0|h[Grilled Squid]|h|r
    -- out: ffffff|13928|Grilled Squid
    ---@type string, string, string
    local color, id, name = link:match(
        "^|cff(......)|Hitem:(%d+):[^:]+:[^:]+:[^:]+:[^:]+:[^:]+:[^:]+:[^:]+:[^:]+|h%[([^%]]+)%]|h|r$")
    if id then
        return color .. "|" .. id .. "|" .. name
    else
        -- in:  |cffffffff|Henchant:7421|h[Runed Copper Rod]|h|r
        -- out: |-7421|Runed Copper Rod
        ---@type string, string
        id, name = link:match("^|cffffd000|Henchant:(%d+)|h%[([^%]]+)%]|h|r$")
        return "|-" .. id .. "|" .. name
    end
end
---@param link string The squished link
---@return string unsquishedLink The unsquished link string
---@return boolean|nil isenchant Optional isenchant boolean flag
local function unsquishlink(link)
    -- in:  ffffff|13928|Grilled Squid
    -- out: |cffffffff|Hitem:13928:0:0:0:0:0:0:0|h[Grilled Squid]|h|r  ,false
    ---@type string, string, string
    local color, id, name = link:match("^([^|].....)|(%d+)|(.+)$")
    if id then
        return "|cff" .. color .. "|Hitem:" .. id .. ":0:0:0:0:0:0:0:0|h[" .. name .. "]|h|r", false
    else
        -- in:  |-7421|Runed Copper Rod
        -- out: |cffffffff|Henchant:7421|h[Runed Copper Rod]|h|r ,true
        ---@type string, string
        id, name = link:match("^|%-(%d+)|(.+)$")
        if id then
            return "|cffffd000|Henchant:" .. id .. "|h[" .. name .. "]|h|r", true
        else
            return link
        end
    end
end

---@type ReservedReagent[]|nil
local reserved_reagents = nil

-- Synastria: Crystallized <-> Eternal conversion mappings
-- 10 Crystallized = 1 Eternal (and vice versa)
---@type table<number, number>
local CRYSTALLIZED_TO_ETERNAL = {
    [37700] = 35622, -- Crystallized Air -> Eternal Air
    [37701] = 35624, -- Crystallized Earth -> Eternal Earth
    [37702] = 36860, -- Crystallized Fire -> Eternal Fire
    [37704] = 35625, -- Crystallized Life -> Eternal Life
    [37703] = 35627, -- Crystallized Shadow -> Eternal Shadow
    [37705] = 35623, -- Crystallized Water -> Eternal Water
}

---@type table<number, number>
local ETERNAL_TO_CRYSTALLIZED = {
    [35622] = 37700, -- Eternal Air -> Crystallized Air
    [35624] = 37701, -- Eternal Earth -> Crystallized Earth
    [36860] = 37702, -- Eternal Fire -> Crystallized Fire
    [35625] = 37704, -- Eternal Life -> Crystallized Life
    [35627] = 37703, -- Eternal Shadow -> Crystallized Shadow
    [35623] = 37705, -- Eternal Water -> Crystallized Water
}

-- Synastria: Extract item ID from item link for resource bank queries
---@param link string The item link
---@return number|nil itemId The item ID, or nil if not found
local function extract_item_id(link)
    if not link then return nil end
    local id = string.match(link, "item:(%d+)")
    return tonumber(id)
end

-- Synastria: Get count of items in resource bank
---@param link string The item link
---@return number count Count of items in resource bank
local function get_resource_bank_count(link)
    if not GetCustomGameData or not link then
        return 0
    end

    local itemId = extract_item_id(link)
    if not itemId then
        return 0
    end

    return GetCustomGameData(13, itemId) or 0
end

-- Synastria: Extract item ID from item link (alternative version for conversion code)
-- @param link: Item link string (e.g., "|cffffffff|Hitem:37700:0:0:0:0:0:0:0|h[Crystallized Air]|h|r")
-- @return: Item ID as number, or nil if not found
---@param link string|number The item link or item ID
---@return number|nil itemId The item ID, or nil if not found
local function get_item_id_from_link(link)
    if not link or type(link) ~= "string" then
        return nil
    end

    -- Try to extract item ID from link
    local itemId = link:match("|Hitem:(%d+):")
    if itemId then
        return tonumber(itemId)
    end

    -- Check if it's already a number
    if tonumber(link) then
        return tonumber(link)
    end

    return nil
end

-- Synastria: Get convertible item count for crafting calculations
-- This prevents infinite loops by NOT recursively converting
-- @param itemId: The item ID we're looking for
-- @param includeBank: Whether to include bank in the count
-- @return: Total count including conversions (but avoiding infinite loops)
---@param itemId number The item ID to get count for
---@param includeBank boolean|nil Whether to include bank items (default: false)
---@return number count Total count including conversions
local function get_item_count_with_conversions(itemId, includeBank)
    if type(itemId) ~= "number" then
        return 0
    end

    -- Get base count for the requested item
    ---@type number
    local baseCount = GetItemCount(itemId, includeBank) or 0
    ---@type number
    local rbankCount = (GetCustomGameData and GetCustomGameData(13, itemId)) or 0
    ---@type number
    local totalCount = baseCount + rbankCount

    -- Synastria: Check queued conversions that will produce this item
    ---@type SkilletStitch
    local lib = AceLibrary("SkilletStitch-1.1")
    if lib and lib.queue then
        for i = 1, #lib.queue do
            local entry = lib.queue[i]
            if entry.recipe and entry.recipe.isVirtualConversion then
                -- Check if this conversion will produce the item we're looking for
                if entry.recipe.eternalId == itemId then
                    -- This conversion will make Eternals that we need
                    totalCount = totalCount + entry.recipe.eternalsToMake
                end
            end
        end
    end

    -- Check if this item can be converted FROM another item
    local convertFromId = nil
    local conversionRatio = 1

    -- Check if we need Eternal and have Crystallized (10 Crystallized = 1 Eternal)
    if ETERNAL_TO_CRYSTALLIZED[itemId] then
        -- We need an Eternal, check if we have Crystallized
        convertFromId = ETERNAL_TO_CRYSTALLIZED[itemId]
        conversionRatio = 10 -- Need 10 Crystallized to make 1 Eternal
        -- Check if we need Crystallized and have Eternal (1 Eternal = 10 Crystallized)
    elseif CRYSTALLIZED_TO_ETERNAL[itemId] then
        -- We need Crystallized, check if we have Eternal
        convertFromId = CRYSTALLIZED_TO_ETERNAL[itemId]
        conversionRatio = 0.1 -- 1 Eternal makes 10 Crystallized
    end

    -- If we can convert, add the converted amount
    if convertFromId then
        ---@type number
        local convertibleBase = GetItemCount(convertFromId, includeBank) or 0
        ---@type number
        local convertibleRbank = (GetCustomGameData and GetCustomGameData(13, convertFromId)) or 0
        ---@type number
        local convertibleTotal = convertibleBase + convertibleRbank

        -- Synastria: Subtract any Crystallized that are queued to be converted
        -- (they won't be available for other conversions)
        if lib and lib.queue then
            for i = 1, #lib.queue do
                local entry = lib.queue[i]
                if entry.recipe and entry.recipe.isVirtualConversion then
                    if entry.recipe.crystallizedId == convertFromId then
                        -- This queued conversion will use up some of the Crystallized
                        ---@type number
                        convertibleTotal = convertibleTotal - (entry.recipe.crystallizedNeeded or 0)
                    end
                end
            end
        end

        -- Add the converted amount to our total
        -- If ratio is 10, we divide by 10 (10 crystallized = 1 eternal)
        -- If ratio is 0.1, we multiply by 10 (1 eternal = 10 crystallized)
        ---@type number
        local convertedAmount = math.floor(convertibleTotal / conversionRatio)
        ---@type number
        totalCount = totalCount + convertedAmount
    end

    return totalCount
end

-- Returns the count of reagents of type 'link' that have
-- already been reserved
---@param link string The reagent item link
---@return number count Number of reserved items
local function get_reserved_reagent_count(link)
    local count = 0

    if reserved_reagents then
        for i = #reserved_reagents, 1, -1 do
            if reserved_reagents[i].link == link then
                count = reserved_reagents[i].count
                break
            end
        end
    end

    return count
end

---@type table<string, number|nil>
local craftabilityCache = {}

-- Forward declare cache for use in clearCraftabilityCache and other functions
---@type table<string, table<integer, Recipe>>
local cache

---@type CacheStats
local cacheStats = {
    hits = 0,
    misses = 0,
    calculations = 0
}

local function clearCraftabilityCache()
    -- Also clear the recipe cache to force fresh recipe objects
    if cache then
        ---@type string, any
        for profession, _ in pairs(cache) do
            cache[profession] = nil
        end
    end
end

-- Synastria: Selectively invalidate cache entries for recipes that use specific items
---@param itemIds number[] Array of item IDs to invalidate
---@return number count Number of cache entries invalidated
local function invalidateCacheForItems(itemIds)
    if not itemIds or #itemIds == 0 then
        return 0
    end

    -- Convert item IDs to a lookup table for faster checking
    ---@type table<number, boolean>
    local itemLookup = {}
    for _, itemId in ipairs(itemIds) do
        itemLookup[itemId] = true
    end

    ---@type number
    local invalidatedCount = 0
    ---@type number
    local cacheEntryCount = 0

    -- Count cache entries
    ---@type number
    local cacheCount = 0
    for _ in pairs(craftabilityCache) do
        cacheCount = cacheCount + 1
    end
    cacheEntryCount = cacheCount
    -- craftabilityCache has entries (debug output removed)

    -- Iterate through all cached entries
    for cacheKey, _ in pairs(craftabilityCache) do
        -- Cache key format: "profession:index:numcraftable"
        ---@type string|nil, string|nil, string|nil
        local profession, indexStr, key = cacheKey:match("^(.+):(%d+):(.+)$")
        if profession and indexStr then
            ---@type number|nil
            local index = tonumber(indexStr)
            -- Use GetItemDataByIndex to get full recipe with reagents
            if index then
                ---@type SkilletStitch
                local lib = AceLibrary("SkilletStitch-1.1")
                local recipe = lib:GetItemDataByIndex(profession, index)

                if recipe and recipe.reagents then
                    -- Check if this recipe uses any of the affected items as reagents
                    ---@type boolean
                    local usesAffectedItem = false
                    ---@type number
                    local reagentCount = 0
                    for _, reagent in ipairs(recipe.reagents) do
                        ---@type number
                        local rcount = reagentCount + 1
                        reagentCount = rcount
                        ---@type number|nil
                        local reagentId = tonumber((reagent.link or ""):match("item:(%d+)"))
                        if reagentId and itemLookup[reagentId] then
                            -- Recipe uses affected item (debug output removed)
                            usesAffectedItem = true
                            break
                        end
                    end

                    if usesAffectedItem then
                        craftabilityCache[cacheKey] = nil
                        ---@type number
                        local icount = invalidatedCount + 1
                        invalidatedCount = icount
                    elseif reagentCount == 0 then
                        -- Recipe has no reagents in cache (debug output removed)
                    end
                else
                    -- Could not find recipe (debug output removed)
                end
            end
        end
    end

    return invalidatedCount
end

-- Synastria: Get cache statistics
---@return CacheStats stats Cache statistics object
local function getCacheStats()
    return cacheStats
end

-- Synastria: Get cached craftability value
---@param recipe Recipe The recipe object
---@param key string The cache key
---@return number|nil cached The cached value, or nil if not cached
local function getCachedCraftability(recipe, key)
    if not recipe.profession or not recipe.index then
        return nil
    end
    ---@type string
    local cacheKey = string.format("%s:%d:%s", recipe.profession, recipe.index, key)
    local cached = craftabilityCache[cacheKey]
    if cached ~= nil then
        cacheStats.hits = cacheStats.hits + 1
    end
    return cached
end

-- Synastria: Set cached craftability value
---@param recipe Recipe The recipe object
---@param key string The cache key
---@param value number|nil The value to set
local function setCachedCraftability(recipe, key, value)
    if not recipe.profession or not recipe.index then
        return
    end
    ---@type string
    local cacheKey = string.format("%s:%d:%s", recipe.profession, recipe.index, key)
    craftabilityCache[cacheKey] = value
end

local itemmeta = {
    __index = function(self, key)
        ---@type Recipe
        self = self
        if key == "numcraftable" then
            -- Check cache first
            local cached = getCachedCraftability(self, key)
            if cached ~= nil then
                cacheStats.hits = cacheStats.hits + 1
                return cached
            end

            cacheStats.misses = cacheStats.misses + 1
            cacheStats.calculations = cacheStats.calculations + 1

            local num = 0
            for _, v in ipairs(self.reagents) do
                if v.vendor == false then
                    local available = v.num

                    -- Synastria: DO NOT check sub-reagent craftability here
                    -- That causes recursive calculations and freezing
                    -- Only the background calculation process should populate the cache
                    -- which is then used by all recipes via the cache check above

                    local max = math.floor(available / v.needed) * self.nummade
                    if num == 0 or max < num then
                        num = max
                    end
                end
            end
            if num == 0 then
                for _, v in ipairs(self.reagents) do
                    local max = math.floor(v.num / v.needed) * self.nummade
                    if max < num then
                        num = max
                    end
                end
            end

            -- Cache the result
            setCachedCraftability(self, key, num)
            return num
        elseif key == "numcraftablewbank" then
            -- Check cache first
            ---@type number|nil
            local cached = getCachedCraftability(self, key)
            if cached ~= nil then
                cacheStats.hits = cacheStats.hits + 1
                return cached
            end

            cacheStats.misses = cacheStats.misses + 1
            cacheStats.calculations = cacheStats.calculations + 1

            local num = 0
            for _, v in ipairs(self.reagents) do
                if v.vendor == false then
                    local available = v.numwbank

                    -- Synastria: DO NOT check sub-reagent craftability here
                    -- Only the background calculation process should populate the cache

                    local max = math.floor(available / v.needed) * self.nummade
                    if num == 0 or max < num then
                        num = max
                    end
                end
            end
            if num == 0 then
                for _, v in ipairs(self.reagents) do
                    local max = math.floor(v.numwbank / v.needed) * self.nummade
                    if max < num then
                        num = max
                    end
                end
            end

            -- Cache the result
            setCachedCraftability(self, key, num)
            return num
        elseif key == "numcraftablewalts" and alt_lookup_function then
            ---@type number
            local num = 0
            for _, v in ipairs(self.reagents) do
                if v.vendor == false then
                    local max = math.floor(v.numwalts / v.needed) * self.nummade
                    if num == 0 or max < num then
                        num = max
                    end
                end
            end
            if num == 0 then
                for _, v in ipairs(self.reagents) do
                    local max = math.floor(v.numwalts / v.needed) * self.nummade
                    if max < num then
                        num = max
                    end
                end
            end
            return num
        end
    end
}
local reagentmeta = {
    __index = function(self, key)
        local count = 0
        local reserved = get_reserved_reagent_count(self.link)

        if key == "num" then
            -- Synastria: Get item ID from link and use conversion-aware counting
            local itemId = get_item_id_from_link(self.link)
            if itemId then
                count = get_item_count_with_conversions(itemId, false)
            else
                -- Fallback to old method if we can't extract item ID
                count = GetItemCount(self.link) + get_resource_bank_count(self.link)
            end
        elseif key == "numwbank" then
            -- Synastria: Get item ID from link and use conversion-aware counting (with bank)
            local itemId = get_item_id_from_link(self.link)
            if itemId then
                count = get_item_count_with_conversions(itemId, true)
            else
                -- Fallback to old method if we can't extract item ID
                count = GetItemCount(self.link, true) + get_resource_bank_count(self.link)
            end
        elseif key == "numraw" then
            -- Synastria: RAW inventory (bags + resbank) WITHOUT queue reservation subtraction
            -- Used by calculation code to apply NET reservations (consumption - production)
            local itemId = get_item_id_from_link(self.link)
            if itemId then
                count = get_item_count_with_conversions(itemId, false)
            else
                -- Fallback to old method if we can't extract item ID
                count = GetItemCount(self.link) + get_resource_bank_count(self.link)
            end
            return count -- Return raw count WITHOUT subtracting reserved
        elseif key == "numwbankraw" then
            -- Synastria: RAW inventory (bags + bank + resbank) WITHOUT queue reservation subtraction
            local itemId = get_item_id_from_link(self.link)
            if itemId then
                count = get_item_count_with_conversions(itemId, true)
            else
                -- Fallback to old method if we can't extract item ID
                count = GetItemCount(self.link, true) + get_resource_bank_count(self.link)
            end
            return count -- Return raw count WITHOUT subtracting reserved
        elseif key == "numwalts" and alt_lookup_function ~= nil then
            count = alt_lookup_function(self.link) or 0
        end

        return math.max(0, count - reserved)
    end
}

-- Synastria: SpellId index for fast recipe lookup by spellId
-- Maps spellId -> {profession, index} for O(1) recipe retrieval
-- Must be declared before cache to be accessible in cache's __index metamethod
---@type table<number, {profession: string, index: integer}>
local spellIdIndex = {}

---@type table<string, table<integer, Recipe>>
cache = setmetatable({}, {
    __index = function(self, prof)
        ---@type table<string, table<integer, Recipe>>
        self = self
        ---@type string
        prof = prof
        if prof == "UNKNOWN" then
            return
        end
        self[prof] = setmetatable({}, {
            __mode = 'v',
            __index = function(self, key)
                ---@type table<integer, Recipe>
                self = self
                ---@type integer
                key = key
                ---@type SkilletStitch
                local l = AceLibrary("SkilletStitch-1.1")
                if not l.data then
                    l.data = {}
                end
                if not l.data[prof] then
                    l.data[prof] = {}
                end
                local datastring = l.data[prof][key]
                if not datastring then
                    return
                end

                self[key] = l:DecodeRecipe(datastring)
                -- this is used to work down the list of reagents when recursively crafting items
                self[key].index = key
                -- Synastria: Also set profession for cache key matching
                self[key].profession = prof

                -- Synastria: Update spellId index for fast lookup
                local recipe = self[key]
                if recipe and recipe.spellId then
                    ---@type number
                    local spellId = recipe.spellId
                    spellIdIndex[spellId] = { profession = prof, index = key }
                end

                return self[key]
            end
        })
        return self[prof]
    end
})

-- Synastria: Simple recipe info cache for cross-profession queuing
-- Stores just name and link for each recipe when profession is scanned
---@type table<string, table<number, {name: string, link: string}>>
local recipeInfoCache = {}

-- Synastria: Populate the recipe info cache from database on load
-- This function extracts name and link from the stored recipe data

local function PopulateRecipeInfoCache()
    ---@type SkilletStitch
    local l = AceLibrary("SkilletStitch-1.1")
    if not l.data then
        return
    end

    ---@type string, table<integer, string|table>
    for profession, recipes in pairs(l.data) do
        if not recipeInfoCache[profession] then
            recipeInfoCache[profession] = {}
        end

        for index, data in pairs(recipes) do
            -- If data is already in new table format, use it directly
            ---@type string|table
            if type(data) == "table" and data.name and data.link then
                recipeInfoCache[profession][index] = {
                    name = data.name,
                    link = data.link
                }
            end
            -- If data is in old encoded string format, we'll need to rescan
            -- Don't try to decode - just wait for rescan
        end
    end

    -- Cache loaded silently
end

-- Synastria: Check if profession data needs rescanning (has old encoded string format)
---@param profession string The profession name
---@return boolean needsScan True if profession data needs rescanning
local function needsRecipeScan(profession)
    ---@type SkilletStitch
    local l = AceLibrary("SkilletStitch-1.1")
    if not l.data or not l.data[profession] then
        return false -- No data at all, will scan when opened
    end

    -- Check if any recipe is still in encoded string format
    ---@type integer, string|table
    for index, data in pairs(l.data[profession]) do
        if type(data) == "string" then
            return true -- Found old format, needs rescan
        end
    end

    return false
end

-- API

function SkilletStitch:PopulateRecipeInfoCache()
    PopulateRecipeInfoCache()
end

-- Decode a recipe from table format with encoded metadata and reagents
---@param datastring RecipeData Recipe data table with encoded metadata + reagent list
---@return Recipe|nil recipe The decoded recipe object
function SkilletStitch:DecodeRecipe(datastring)
    if not datastring then
        return
    end

    -- Only handle new table format - old string format is purged on addon load
    if type(datastring) ~= "table" then
        return nil
    end

    if datastring.encoded and datastring.reagents and #datastring.reagents > 0 then
        -- We have both encoded and non-empty reagent data
        -- Decode the encoded string for recipe metadata, then use stored reagents
        ---@type string, string
        local itemchunk, _ = datastring.encoded:match("^([^;]-;[^;]-;[^;]-;[^;]-;)(.-)$")
        ---@type string, string, string, string, string|nil
        local nameoverride, link, difficultychar, numcrafted, tools = itemchunk:match(
            "^([^;]-);([^;]+);(%a)(%d+);([^;]-);$")
        ---@type boolean|nil
        local isenchant

        link, isenchant = unsquishlink(link)
        if nameoverride:len() == 0 then
            nameoverride = link:match("%|h%[([^%]]+)%]%|h")
        end
        if tools and tools:len() == 0 then
            tools = nil
        end
        ---@type string|nil
        local texture
        if isenchant then
            texture = "Interface\\Icons\\Spell_Holy_GreaterHeal"
        else
            texture = select(10, GetItemInfo(link))
        end

        -- Synastria: Extract spell ID from recipe link.
        -- PRIORITY: use the per-recipe spell ID stored at scan time (from GetTradeSkillRecipeLink).
        -- This avoids the collision where Custom_GetProfessionRecipeFromCraftedItem returns the SAME
        -- spell ID for all recipes that produce the same item (e.g., "Smelt Titanium" and
        -- "Transmute: Titanium" both produce Titanium Bar / item 36909).
        ---@type number|nil
        local spellId = datastring.spellId -- Prefer: canonical per-recipe ID stored at scan time
        if not spellId and link then
            -- Fallback 1: enchant spell link (Enchanting profession uses |Henchant:ID|h as product link)
            spellId = tonumber(link:match("|Henchant:(%d+)|h"))

            -- Fallback 2: Custom API reverse lookup by item ID.
            -- WARNING: Only used when no scanned spell ID is available (old save data / scan failure).
            -- This fallback is INTENTIONALLY SKIPPED when datastring.spellId is present because
            -- Custom_GetProfessionRecipeFromCraftedItem returns one shared ID for all recipes that
            -- produce the same item, which causes spellIdIndex last-write-wins collisions.
            if not spellId and Custom_GetProfessionRecipeFromCraftedItem then
                ---@type number|nil
                local itemId = tonumber(link:match("|Hitem:(%d+)"))
                if itemId then
                    spellId = Custom_GetProfessionRecipeFromCraftedItem(itemId)
                end
            end
        end

        -- Use local variables for profession and index
        ---@type string|nil
        local profession = datastring.profession or nil
        ---@type integer|nil
        local index = datastring.index or nil

        -- Synastria: Prefer directly stored nummade (more reliable than parsing encoded string)
        ---@type number
        local nummadeValue = datastring.nummade or tonumber(numcrafted) or 1

        local s = setmetatable({
            name = nameoverride,
            difficulty = difficultyt[difficultychar],
            nummade = nummadeValue,
            link = link,
            spellId = spellId, -- Synastria: Store spell ID for Custom API
            tools = tools,
            texture = texture,
            profession = profession,
            index = index,
            reagents = {} -- Synastria: Initialize reagents table (modern format)
        }, itemmeta)

        -- Synastria: Use pre-scanned reagents with vendor info (modern format)
        for _, reagentData in ipairs(datastring.reagents) do
            local texture = select(10, GetItemInfo(reagentData.link))
            table.insert(s.reagents, setmetatable({
                name = reagentData.name,
                link = reagentData.link,
                needed = reagentData.needed,
                -- num is calculated dynamically via reagentmeta __index
                texture = texture,
                vendor = reagentData.vendor, -- Synastria: Use stored vendor flag
            }, reagentmeta))
        end

        return s
    elseif datastring.encoded then
        -- We have encoded metadata but no reagent data
        -- Decode the encoded string to get recipe metadata (without reagent details)
        ---@type string, string
        local itemchunk, _ = datastring.encoded:match("^([^;]-;[^;]-;[^;]-;[^;]-;)(.-)$")
        if not itemchunk then
            return nil
        end

        ---@type string, string, string, string, string|nil
        local nameoverride, link, difficultychar, numcrafted, tools = itemchunk:match(
            "^([^;]-);([^;]+);(%a)(%d+);([^;]-);$")
        if not nameoverride then
            return nil
        end

        ---@type boolean|nil
        local isenchant

        link, isenchant = unsquishlink(link)
        if nameoverride:len() == 0 then
            nameoverride = link:match("%|h%[([^%]]+)%]%|h")
        end
        if tools and tools:len() == 0 then
            tools = nil
        end
        ---@type string|nil
        local texture
        if isenchant then
            texture = "Interface\\Icons\\Spell_Holy_GreaterHeal"
        else
            texture = select(10, GetItemInfo(link))
        end

        -- Synastria: Extract spell ID from recipe link.
        -- PRIORITY: use the per-recipe spell ID stored at scan time (from GetTradeSkillRecipeLink).
        -- See the first DecodeRecipe branch above for the full explanation of the collision bug.
        ---@type number|nil
        local spellId = datastring.spellId -- Prefer: canonical per-recipe ID stored at scan time
        if not spellId and link then
            -- Fallback 1: enchant spell link
            spellId = tonumber(link:match("|Henchant:(%d+)|h"))

            -- Fallback 2: Custom API reverse lookup (intentionally skipped when scanned ID is present)
            if not spellId and Custom_GetProfessionRecipeFromCraftedItem then
                ---@type number|nil
                local itemId = tonumber(link:match("|Hitem:(%d+)"))
                if itemId then
                    spellId = Custom_GetProfessionRecipeFromCraftedItem(itemId)
                end
            end
        end

        -- Use local variables for profession and index
        ---@type string|nil
        local profession = datastring.profession or nil
        ---@type integer|nil
        local index = datastring.index or nil

        -- Synastria: Prefer directly stored nummade (more reliable than parsing encoded string)
        ---@type number
        local nummadeValue = datastring.nummade or tonumber(numcrafted) or 1

        local s = setmetatable({
            name = nameoverride,
            difficulty = difficultyt[difficultychar],
            nummade = nummadeValue,
            link = link,
            spellId = spellId,
            tools = tools,
            texture = texture,
            profession = profession,
            index = index,
            reagents = {}
        }, itemmeta)

        return s
    else
        -- Minimal table without encoded data
        -- This means the recipe hasn't been scanned yet with the new system
        -- Return a minimal valid recipe object to prevent errors
        -- Mark it as needing rescan
        ---@type Recipe|table
        local minimal = {
            name = datastring.name,
            link = datastring.link,
            needsRescan = true,
        }
        -- Return empty recipe with just name/link to prevent crashes
        return setmetatable(minimal, itemmeta)
    end
end

---@param prof string|nil The profession name (optional)
---@return number|nil numSkills Number of skills, or nil if profession not found
function SkilletStitch:GetNumSkills(prof)
    if not self.data then
        return nil
    elseif not self.data[prof] then
        return nil
    else
        return #self.data[prof]
    end
end

-- Tells the Stitch library that the provided list of reagents
-- have already be reserved/spoken for and cannot be included
-- when computing the craftable item counts.
---@param reagents ReservedReagent[]|nil List of reserved reagents
function SkilletStitch:SetReservedReagentsList(reagents)
    reserved_reagents = reagents
    -- Synastria: Removed debug spam - this gets called very frequently
end

-- Synastria: Clear the craftability cache

function SkilletStitch:ClearCraftabilityCache()
    clearCraftabilityCache()
end

-- Synastria: Invalidate cache for recipes that use specific items
---@param itemIds number[] Array of item IDs to invalidate
---@return number count Number of cache entries invalidated
function SkilletStitch:InvalidateCacheForItems(itemIds)
    return invalidateCacheForItems(itemIds)
end

-- Synastria: Get cache statistics
---@return CacheStats stats Cache statistics (hits, misses, calculations)
function SkilletStitch:GetCacheStats()
    return getCacheStats()
end

-- Synastria: Set cached craftability value (for background calculation)
---@param recipe Recipe The recipe object
---@param key string The cache key
---@param value number|nil The value to cache
function SkilletStitch:SetCachedCraftability(recipe, key, value)
    setCachedCraftability(recipe, key, value)
end

-- Synastria: Get cached craftability value (for background calculation)
---@param recipe Recipe The recipe object
---@param key string The cache key
---@return number|boolean|nil value The cached value, or nil if not cached
function SkilletStitch:GetCachedCraftability(recipe, key)
    return getCachedCraftability(recipe, key)
end

---@param addon string The addon name requesting data gathering
function SkilletStitch:EnableDataGathering(addon)
    assert(tostring(addon), "Usage: EnableDataGathering('addon')")
    self.datagatheraddons[addon] = true
    -- Only register events if AceEvent methods are available
    if self.RegisterEvent then
        self:RegisterEvent("TRADE_SKILL_SHOW")
        self:RegisterEvent("CHAT_MSG_SKILL")
    end
    if not self.data then
        self.data = {}
    end
end

---@param addon string|nil The addon name (nil to disable all addons' data gathering)
function SkilletStitch:DisableDataGathering(addon)
    if not addon then
        self.data = nil
        self.datagatheraddons = {}
        return
    end
    assert(tostring(addon), "Usage: DisableDataGathering(['addon'])")
    self.datagatheraddons[addon] = false
    if next(self.datagatheraddons) then
        return
    end
    -- Only unregister events if AceEvent methods are available
    if self.UnregisterEvent then
        self:UnregisterEvent("TRADE_SKILL_SHOW")
        self:UnregisterEvent("CHAT_MSG_SKILL")
    end
    self.data = nil
end

---@param addon string The addon name requesting queue
function SkilletStitch:EnableQueue(addon)
    assert(tostring(addon), "Usage: EnableQueue('addon')")
    self.queueaddons[addon] = true
    -- NOTE: Events are registered by Skillet addon (which has AceEvent-2.0)
    -- not by this library. Skillet's event handlers call our methods.
    if Skillet and Skillet:IsDevMode() then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[EVENTS] Queue enabled - events routed through Skillet addon|r")
    end
    -- Synastria: Don't create new queue table - LoadQueue will set it from database
    -- if not self.queue then
    --     self.queue = {}
    -- end
    self.queueenabled = true
end

---@param addon string|nil The addon name (nil to disable all addons' queue)
function SkilletStitch:DisableQueue(addon)
    if not addon then
        self.queue = nil
        self.queueaddons = {}
        self.queueenabled = false
        return
    end
    assert(tostring(addon), "Usage: DisableDataGathering(['addon'])")
    self.queueaddons[addon] = false
    if next(self.queueaddons) then
        return
    end
    -- Only unregister events if AceEvent methods are available
    if self.UnregisterEvent then
        self:UnregisterEvent("BAG_UPDATE")
        self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    end
    self.queueenabled = false
    self.queue = nil
end

-- Get recipe data by profession and index
---@param profession string|number The profession name or ID
---@param index number The recipe index within the profession
---@return Recipe|nil recipe The recipe data, or nil if not found
function SkilletStitch:GetItemDataByIndex(profession, index)
    assert(tonumber(index) and profession, "Usage: GetItemDataByIndex('profession', index)")
    return cache[profession][index]
end

-- Synastria: Get recipe data by spellId (fast O(1) lookup)
---@param spellId number The recipe spell ID
---@return Recipe|nil recipe The recipe data, or nil if not found
function SkilletStitch:GetItemDataBySpellId(spellId)
    assert(tonumber(spellId), "Usage: GetItemDataBySpellId(spellId)")

    local lookup = spellIdIndex[spellId]
    if not lookup then
        return nil
    end

    -- Use the indexed profession/index to retrieve from cache
    return cache[lookup.profession][lookup.index]
end

-- Get recipe data by name (searches all professions)
---@param name string The recipe or item name to search for
---@param prof string|number|nil Optional profession ID to limit search
---@return Recipe|nil recipe The recipe data, or nil if not found
function SkilletStitch:GetItemDataByName(name, prof)
    assert(tostring(name), "Usage: GetItemDataByName('name')")

    -- Synastria: Track all matching recipes to implement profession priority
    ---@type {profession: string, recipe: Recipe}[]
    local matches = {}

    if cache then
        for k, v in pairs(cache) do
            if not prof or k == prof then
                for l, w in pairs(v) do
                    if w.name == name then
                        table.insert(matches, { profession = k, recipe = cache[k][l] })
                    end
                end
            end
        end
    end

    -- If no exact match in cache, search data
    if #matches == 0 then
        ---@type string
        name = string.gsub(name, "([%.%(%)%%%+%-%*%?%[%]%^%$])", "%%%1")
        ---@type string, string|table
        for k, v in pairs(self.data) do
            if not prof or k == prof then
                for l, w in pairs(v) do
                    -- Synastria: Handle both old string format and new table format
                    ---@type string|nil
                    local chunk
                    if type(w) == "table" then
                        -- New format: {name, link, encoded}
                        if w.encoded then
                            chunk = w.encoded:match("^([^;]-;[^;]-;)")
                        else
                            -- No encoded data, skip this entry
                            chunk = ""
                        end
                    elseif type(w) == "string" then
                        -- Old format: encoded string
                        chunk = w:match("^([^;]-;[^;]-;)")
                    else
                        -- Invalid format, skip
                        chunk = ""
                    end

                    if chunk and (chunk:match("^" .. name) or chunk:match("|" .. name .. ";")) then
                        table.insert(matches, { profession = k, recipe = cache[k][l] })
                    end
                end
            end
        end
    end

    -- Synastria: If multiple recipes found, prefer Smelting/Mining over other professions (especially Alchemy)
    -- This handles cases like Titanium Bar (smelting vs transmute)
    if #matches > 1 then
        -- First priority: Smelting recipe
        for _, match in ipairs(matches) do
            if match.profession == "Smelting" then
                return match.recipe
            end
        end

        -- Second priority: Mining recipe (in case recipes are stored under Mining)
        for _, match in ipairs(matches) do
            if match.profession == "Mining" then
                return match.recipe
            end
        end

        -- Third priority: Filter out transmutations with cooldowns when searching for subcrafts
        -- This ensures we don't queue cooldown transmutes as dependencies
        ---@type {profession: string, recipe: Recipe}[]
        local nonCooldownMatches = {}
        for _, match in ipairs(matches) do
            ---@type boolean
            local isTransmute = match.recipe.name and match.recipe.name:match("^Transmute:")
            ---@type boolean
            local hasCooldown = false

            -- Hardcoded exception: Transmute: Titanium has no cooldown
            local isTransmuteTitanium = match.recipe.name and match.recipe.name:match("^Transmute: Titanium")

            if isTransmute and not isTransmuteTitanium and match.recipe.index and match.profession then
                -- Check if this transmutation has a cooldown
                -- We need to temporarily switch to the profession to check cooldown
                local currentTrade = GetTradeSkillLine()
                if currentTrade ~= match.profession then
                    -- Can't reliably check cooldown without opening the profession
                    -- Conservative approach: assume transmutes have cooldowns
                    hasCooldown = true
                else
                    local cooldown = GetTradeSkillCooldown(match.recipe.index)
                    hasCooldown = (cooldown and cooldown > 0) and true or false
                end
            end

            if not (isTransmute and hasCooldown) then
                table.insert(nonCooldownMatches, match)
            end
        end

        -- Return first non-cooldown match, or first match if all have cooldowns
        if #nonCooldownMatches > 0 then
            return nonCooldownMatches[1].recipe
        else
            return matches[1].recipe
        end
    elseif #matches == 1 then
        return matches[1].recipe
    end

    -- No matches found
    return nil
end

---@type Recipe[]
local result = {}

---@param name string The partial recipe or item name to search for
---@return Recipe[]|nil results Array of matching recipes, or nil if none found
function SkilletStitch:GetItemDataByPartialName(name)
    ---@type number
    for k, _ in pairs(result) do
        result[k] = nil
    end
    assert(tostring(name), "Usage: GetItemDataByPartialName('name')")
    name = name:gsub("([%.%(%)%%%+%-%*%?%[%]%^%$])", "%%%1")
    for k, v in pairs(self.data) do
        for l, w in pairs(v) do
            -- Only match on string format data (old encoded format)
            if type(w) == "string" then
                local chunk = w:match("([^;]-;[^;]-;)")
                if chunk and (chunk:match("^" .. name) or chunk:match("%|h%[" .. name .. "%]%|h")) then
                    table.insert(result, cache[k][l])
                end
            end
        end
    end
    if #result == 0 then
        return
    else
        return result
    end
end

---@return QueueEntry[] queue The current queue
function SkilletStitch:GetQueueInfo()
    return self.queue
end

---@param index number The queue item index
---@return table|nil queueInfo Recipe info from queue item, or nil
function SkilletStitch:GetQueueItemInfo(index)
    -- Synastria: Get recipe info from spell ID using Custom API
    ---@type QueueEntry|nil
    local queueEntry = self.queue[index]
    if not queueEntry then
        return nil
    end

    ---@type number
    local spellId = queueEntry["spellId"]
    if not spellId then
        return nil
    end

    -- Use Custom API to get recipe info
    if Custom_GetProfessionRecipeInfo then
        local skillId, name, itemId, craftCount, canCraft, verb, header, difficulty = Custom_GetProfessionRecipeInfo(
            spellId)
        if name then
            -- Return a recipe-like structure
            return {
                name = name,
                spellId = spellId,
                itemId = itemId,
                craftCount = craftCount,
                canCraft = canCraft,
                header = header,
                difficulty = difficulty
            }
        end
    end

    return nil
end

---@param index number The queue index to remove
function SkilletStitch:RemoveFromQueue(index)
    -- Synastria: Check if we're removing a conversion to invalidate cache
    ---@type QueueEntry|nil
    local removedEntry = self.queue[index]
    ---@type boolean|nil
    local isConversion = removedEntry and removedEntry.recipe and removedEntry.recipe.isVirtualConversion

    table.remove(self.queue, index)
    if #self.queue == 0 then
        self:ClearQueue()
    end

    -- Synastria: Clear craftability cache if we removed a conversion
    if isConversion then
        clearCraftabilityCache()
    end
end

function SkilletStitch:ClearQueue()
    -- Synastria: Clear the table contents while keeping the same reference
    -- for unified queue across professions
    if self.queue then
        ---@type integer
        for k in pairs(self.queue) do
            self.queue[k] = nil
        end
    end
    -- Queue cleared (debug output removed)
    AceEvent:TriggerEvent("SkilletStitch_Queue_Complete")
end

function SkilletStitch:ProcessQueue()
    if Skillet and Skillet:IsDevMode() then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF00FF[DEBUG] ProcessQueue called|r")
    end

    -- Synastria: Pause craftability calculations while processing queue
    if Skillet and Skillet.CraftCalc then
        Skillet.CraftCalc:PauseCalculation()
    end

    if not self.queue[1] or type(self.queue[1]) ~= "table" then
        if Skillet and Skillet:IsDevMode() then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG] Queue empty or invalid|r")
        end
        -- Synastria: Clear the table contents while keeping the same reference
        if self.queue then
            ---@type integer
            for k in pairs(self.queue) do
                self.queue[k] = nil
            end
        end
        -- Invalid queue cleared (debug output removed)
        AceEvent:TriggerEvent("SkilletStitch_Queue_Complete")
        return
    end

    -- Synastria: Check if this is a conversion recipe (handled by Start button)
    local queueItem = self.queue[1]
    if queueItem.profession == "Conversion" or (queueItem.recipe and queueItem.recipe.isVirtualConversion) then
        -- Synastria: Conversion ready - Start button will handle withdraw/use/deposit
        if queueItem.recipe and queueItem.recipe.sourceId and queueItem.recipe.outputId then
            if Skillet and Skillet:IsDevMode() then
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Skillet] Conversion ready - click Start to process|r")
            end
            AceEvent:TriggerEvent("SkilletStitch_Queue_Complete")
        else
            -- Missing conversion data - remove from queue
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Skillet] Invalid conversion data - removing from queue|r")
            self:RemoveFromQueue(1)
            if #self.queue > 0 then
                self:ProcessQueue()
            else
                AceEvent:TriggerEvent("SkilletStitch_Queue_Complete")
            end
        end
        return
    end

    -- Synastria: Get spell ID from queue item
    ---@type number
    local spellId = self.queue[1]["spellId"]
    if Skillet and Skillet:IsDevMode() then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF00FF[DEBUG] Queue item: spellId=" .. tostring(spellId) .. "|r")
    end

    -- Synastria: Validate spell ID (non-conversion recipes must have one)
    if not spellId or type(spellId) ~= "number" then
        if Skillet and Skillet:IsDevMode() then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG] Invalid spell ID in queue item - removing|r")
        end
        self:RemoveFromQueue(1)
        if #self.queue > 0 then
            self:ProcessQueue()
        else
            AceEvent:TriggerEvent("SkilletStitch_Queue_Complete")
        end
        return
    end

    -- Synastria: Fallback to traditional profession switching if windowless not available
    -- For traditional crafting, we need the profession window open
    local tradeskill = GetTradeSkillLine()

    -- Synastria: If we can't determine profession from spell ID, skip this item
    if not tradeskill or tradeskill == "" then
        DEFAULT_CHAT_FRAME:AddMessage(
            "|cFFFFAA00[Skillet] No profession window open - cannot process without windowless crafting|r")
        -- Remove the item and continue
        self:RemoveFromQueue(1)
        if #self.queue > 0 then
            self:ProcessQueue()
        else
            AceEvent:TriggerEvent("SkilletStitch_Queue_Complete")
        end
        return
    end

    -- Synastria: For traditional mode, check if we need to switch professions
    -- This is a fallback path if windowless crafting is not available
    --[[
    if false then -- Disabled traditional profession switching for now
        -- nextProfession is not defined in this context; this block is intentionally disabled
    end
    ]]

    -- We're in the right profession, reset switch flag
    self.waitingForProfessionSwitch = false

    -- We're ready to craft, set up state
    self.queuecasting = true
    self.craftAttemptTime = GetTime() -- Track when we attempted the craft

    -- Synastria: Store pre-craft inventory count for bulk detection
    -- Get spell ID and use Custom API to determine item ID
    ---@type number
    local spellId = self.queue[1]["spellId"]
    ---@type number
    local numcasts = self.queue[1]["numcasts"]

    ---@type number|nil
    self.craftedItemId = nil -- Store item ID for proactive polling

    -- Synastria: Extract itemId from queue link as primary source (most reliable)
    local queueItemLink = self.queue[1]["link"]
    if queueItemLink then
        local extractedItemId = tonumber(queueItemLink:match("item:(%d+)"))
        if extractedItemId then
            self.craftedItemId = extractedItemId
        end
    end

    if spellId and Custom_GetProfessionRecipeInfo then
        local skillId, name, itemId, craftCount = Custom_GetProfessionRecipeInfo(spellId)

        -- Use extracted itemId if available, otherwise fall back to API
        if not self.craftedItemId and itemId then
            self.craftedItemId = itemId
        end

        if self.craftedItemId then
            local bagCount = GetItemCount(self.craftedItemId, true) or 0
            local bankCount = 0

            -- Synastria: Add resource bank count if available
            if GetCustomGameData then
                bankCount = GetCustomGameData(13, self.craftedItemId) or 0
            end

            self.preCraftItemCount = bagCount + bankCount
            self.expectedCraftCount = numcasts

            if Skillet and Skillet:IsDevMode() then
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[CRAFT] Pre-craft tracking: itemId=" ..
                    self.craftedItemId .. ", count=" .. self.preCraftItemCount .. "|r")
            end
        else
            -- Synastria: Some recipes have no item output (enchanting, inscription research)
            -- This is expected - we'll rely on UNIT_SPELLCAST_SUCCEEDED for completion
            if Skillet and Skillet:IsDevMode() then
                DEFAULT_CHAT_FRAME:AddMessage(
                    "|cFFFFAA00[CRAFT] No item output for spell " ..
                    spellId .. " - will use spell cast success for detection|r")
            end
        end
    else
        if not spellId then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[CRAFT] ERROR: No spell ID in queue item!|r")
        elseif not Custom_GetProfessionRecipeInfo then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[CRAFT] ERROR: Custom_GetProfessionRecipeInfo not available!|r")
        end
    end

    -- Synastria: Start repeating timer to check for craft failures
    -- Checks every 0.5 seconds if craft has timed out or failed
    if not AceEvent:IsEventScheduled("SkilletStitch_CraftMonitor") then
        AceEvent:ScheduleRepeatingEvent("SkilletStitch_CraftMonitor", function()
            self:CheckCraftStatus()
        end, 0.5, self)
    end

    -- Synastria: Try windowless crafting with Custom_DoProfessionRecipe

    -- Synastria: Use Custom_DoProfessionRecipe if we have spell ID and API flag is enabled
    if spellId and Skillet.customApiAvailable then
        if not Custom_DoProfessionRecipe then
            -- API not available - disable flag and inform user
            Skillet.customApiAvailable = false
            if not Skillet.customApiFailureReported then
                DEFAULT_CHAT_FRAME:AddMessage(
                    "|cFFFF0000[Skillet] Custom_DoProfessionRecipe not available - falling back to traditional crafting with profession switching.|r")
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Skillet] Windowless crafting disabled until next /reload|r")
                Skillet.customApiFailureReported = true
            end
        else
            if Skillet and Skillet:IsDevMode() then
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[CRAFT] Calling Custom_DoProfessionRecipe(spellId=" ..
                    spellId .. ", numcasts=" .. numcasts .. ")|r")
            end
            local success = Custom_DoProfessionRecipe(spellId, numcasts)
            if success then
                if Skillet and Skillet:IsDevMode() then
                    DEFAULT_CHAT_FRAME:AddMessage(
                        "|cFF00FF00[CRAFT] Custom_DoProfessionRecipe succeeded - using windowless mode|r")
                end
                -- Windowless crafting succeeded - no cast bar exists!
                -- Set flag to skip cast bar checks in monitoring
                self.windowlessCrafting = true
                self.expectedSpellId = spellId -- Store spell ID for event matching

                -- NOTE: UNIT_SPELLCAST_SUCCEEDED is already registered on Skillet addon
                -- and routed to OnSpellcastSucceeded - no need to register here
                if Skillet and Skillet:IsDevMode() then
                    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[EVENTS] Windowless mode enabled - spell ID " ..
                        spellId .. "|r")
                end

                -- Synastria: Schedule PROACTIVE inventory checks for instant crafts (e.g., First Aid)
                -- Some crafts complete so fast that events don't fire reliably
                -- Extended polling: Check at 100ms, 300ms, 600ms, 1000ms, 1500ms, 2000ms
                if self.craftedItemId then
                    if Skillet and Skillet:IsDevMode() then
                        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[CRAFT] Scheduling proactive inventory checks (itemId=" ..
                            self.craftedItemId .. ")|r")
                    end

                    local function checkInventory(checkNumber)
                        if not self.queuecasting or not self.windowlessCrafting then
                            if Skillet and Skillet:IsDevMode() then
                                DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[POLL #" ..
                                    checkNumber .. "] Craft already completed or canceled|r")
                            end
                            return
                        end

                        local currentCount = GetItemCount(self.craftedItemId, true) or 0
                        if GetCustomGameData then
                            currentCount = currentCount + (GetCustomGameData(13, self.craftedItemId) or 0)
                        end

                        if Skillet and Skillet:IsDevMode() then
                            -- DEBUG: Also try GetItemCount without includeBank flag
                            local bagsOnly = GetItemCount(self.craftedItemId, false) or 0
                            local bagsAndBank = GetItemCount(self.craftedItemId, true) or 0

                            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[POLL #" ..
                                checkNumber ..
                                "] Inventory check: pre=" ..
                                tostring(self.preCraftItemCount) ..
                                ", now=" ..
                                currentCount .. " (bags=" .. bagsOnly .. ", bags+bank=" .. bagsAndBank .. ")|r")
                        end

                        if currentCount > (self.preCraftItemCount or 0) then
                            if Skillet and Skillet:IsDevMode() then
                                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[POLL #" ..
                                    checkNumber .. "] Inventory increased! Triggering completion.|r")
                            end
                            self:ProcessCraftCompletion()
                        end
                    end

                    -- Schedule 6 checks: 100ms, 300ms, 600ms, 1000ms, 1500ms, 2000ms
                    AceEvent:ScheduleEvent("SkilletStitch_Poll1", function() checkInventory(1) end, 0.1, self)
                    AceEvent:ScheduleEvent("SkilletStitch_Poll2", function() checkInventory(2) end, 0.3, self)
                    AceEvent:ScheduleEvent("SkilletStitch_Poll3", function() checkInventory(3) end, 0.6, self)
                    AceEvent:ScheduleEvent("SkilletStitch_Poll4", function() checkInventory(4) end, 1.0, self)
                    AceEvent:ScheduleEvent("SkilletStitch_Poll5", function() checkInventory(5) end, 1.5, self)
                    AceEvent:ScheduleEvent("SkilletStitch_Poll6", function() checkInventory(6) end, 2.0, self)
                else
                    -- Synastria: No item output (enchanting, inscription research) - rely on UNIT_SPELLCAST_SUCCEEDED
                    if Skillet and Skillet:IsDevMode() then
                        DEFAULT_CHAT_FRAME:AddMessage(
                            "|cFFFFAA00[CRAFT] No craftedItemId - relying on spell cast success|r")
                    end
                end

                return
            else
                DEFAULT_CHAT_FRAME:AddMessage(
                    "|cFFFF0000[CRAFT] Custom_DoProfessionRecipe failed - falling back to traditional|r")
            end
            -- If Custom_DoProfessionRecipe failed, fall back to traditional DoTradeSkill
        end
    end

    -- Fallback: Traditional DoTradeSkill (requires profession window open and tradeskill index)
    -- This path should rarely be used now that we have windowless crafting
    -- Failures caught by:
    -- 1. UI_ERROR_MESSAGE event (visible errors)
    -- 2. Repeating timer checking cast status (si failures)
    -- 3. Inventory change detection (success verification)
    DEFAULT_CHAT_FRAME:AddMessage(
        "|cFFFFAA00[Skillet] WARNING: Falling back to traditional DoTradeSkill - this requires profession window open!|r")
    -- Note: We no longer store index in queue, so traditional crafting won't work
    -- This is expected - windowless crafting should always be available on Synastria server
end

-- Synastria: Find spell ID for a profession name
---@param professionName string The profession name (e.g., "Alchemy", "Smelting")
---@return number|nil spellId The spell ID for the profession, or nil if not known
function SkilletStitch:FindProfessionSpellId(professionName)
    -- Synastria: Map profession names - Mining skill opens "Smelting" window
    local professionMapping = {
        ["Mining"] = "Smelting",  -- Mining profession opens Smelting tradeskill
        ["Smelting"] = "Smelting" -- Already correct
    }

    -- Use mapped name if available
    local mappedName = professionMapping[professionName] or professionName

    local professionSpellIds = {
        ["Runeforging"] = { 53428 },
        ["Alchemy"] = { 51304, 28596, 11611, 3464, 3101, 2259 },
        ["Blacksmithing"] = { 51300, 29844, 9785, 3538, 3100, 2018 },
        ["Enchanting"] = { 51313, 28029, 13920, 7413, 7412, 7411 },
        ["Engineering"] = { 51306, 30350, 12656, 4038, 4037, 4036 },
        ["Inscription"] = { 45363, 45361, 45360, 45359, 45358, 45357 },
        ["Jewelcrafting"] = { 51311, 28897, 28895, 28894, 25230, 25229 },
        ["Leatherworking"] = { 51302, 32549, 10662, 3811, 3104, 2108 },
        ["Tailoring"] = { 51309, 26790, 12180, 3910, 3909, 3908 },
        ["Cooking"] = { 51296, 33359, 18260, 3413, 3102, 2550 },
        ["First Aid"] = { 45542, 27028, 10846, 7924, 3274, 3273 },
        ["Smelting"] = { 2656, 2655, 2654, 2653, 2652, 2575 } -- Mining/Smelting spell IDs
    }

    local spellIdCollection = professionSpellIds[mappedName]
    if not spellIdCollection then
        return nil
    end

    -- Find which spell rank the player knows
    for _, spellId in ipairs(spellIdCollection) do
        if IsSpellKnown(spellId) then
            return spellId
        end
    end

    return nil
end

-- Internal

function SkilletStitch:SkilletStitch_AutoRescan()
    if InCombatLockdown() or IsTradeSkillLinked() then
        -- Do not try to scan skills when in combat or if the
        -- skill has been linked in chat.
        return
    end

    if AceEvent:IsEventScheduled("SkilletStitch_AutoRescan") then
        AceEvent:CancelScheduledEvent("SkilletStitch_AutoRescan")
    end

    self:ScanTrade()
end

function SkilletStitch:TRADE_SKILL_SHOW()
    -- Don't scan when opening a linked tradeskill
    if IsTradeSkillLinked() then
        return
    end

    local recenttrade = GetTradeSkillLine()
    -- Synastria: REMOVED - Don't clear queue when switching professions
    -- For unified queue across all professions, we want to keep all items
    --[[
    if self.queue[1] and type(self.queue[1]) == "table" and recenttrade ~= self.queue[1]["profession"] then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[QUEUE DEBUG] TRADE_SKILL_SHOW clearing queue! Current: " .. recenttrade .. ", Queue first: " .. self.queue[1]["profession"] .. "|r")
        self:ClearQueue()
    end
    ]] --

    self:ScanTrade()

    if self.data.UNKNOWN then
        self.data.UNKNOWN = nil
    end
end

function SkilletStitch:CHAT_MSG_SKILL()
    self:SkilletStitch_AutoRescan()
end

-- Synastria: Periodically check craft status (called by repeating timer)

function SkilletStitch:CheckCraftStatus()
    -- Only check if we're actively crafting from queue
    if not self.queuecasting then
        -- Cancel timer if not crafting
        if AceEvent:IsEventScheduled("SkilletStitch_CraftMonitor") then
            AceEvent:CancelScheduledEvent("SkilletStitch_CraftMonitor")
        end
        return
    end

    -- Check if we have a craft attempt time
    if not self.craftAttemptTime then
        return
    end

    local elapsed = GetTime() - self.craftAttemptTime

    -- Synastria: For windowless crafting, skip cast bar check (no cast bar exists!)
    -- Rely purely on BAG_UPDATE / inventory tracking for completion
    if self.windowlessCrafting then
        if Skillet and Skillet:IsDevMode() then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[CRAFT MONITOR] Windowless craft in progress - elapsed " ..
                string.format("%.1f", elapsed) .. "s|r")
        end

        -- After 5 seconds with no completion, something went wrong
        if elapsed > 5.0 then
            DEFAULT_CHAT_FRAME:AddMessage(
                "|cFFFF0000[CRAFT MONITOR] Windowless craft timeout (5s) - assuming completion failed|r")

            -- Cancel the monitoring timer
            if AceEvent:IsEventScheduled("SkilletStitch_CraftMonitor") then
                AceEvent:CancelScheduledEvent("SkilletStitch_CraftMonitor")
            end

            -- Cancel proactive inventory poll timers
            if AceEvent:IsEventScheduled("SkilletStitch_Poll1") then
                AceEvent:CancelScheduledEvent("SkilletStitch_Poll1")
            end
            if AceEvent:IsEventScheduled("SkilletStitch_Poll2") then
                AceEvent:CancelScheduledEvent("SkilletStitch_Poll2")
            end
            if AceEvent:IsEventScheduled("SkilletStitch_Poll3") then
                AceEvent:CancelScheduledEvent("SkilletStitch_Poll3")
            end
            if AceEvent:IsEventScheduled("SkilletStitch_Poll4") then
                AceEvent:CancelScheduledEvent("SkilletStitch_Poll4")
            end
            if AceEvent:IsEventScheduled("SkilletStitch_Poll5") then
                AceEvent:CancelScheduledEvent("SkilletStitch_Poll5")
            end
            if AceEvent:IsEventScheduled("SkilletStitch_Poll6") then
                AceEvent:CancelScheduledEvent("SkilletStitch_Poll6")
            end

            -- Reset crafting state
            self.queuecasting = false
            self.craftAttemptTime = nil
            self.preCraftItemCount = nil
            self.expectedCraftCount = nil
            self.windowlessCrafting = false

            -- Synastria: Move failed item to end of queue
            if self.queue[1] then
                local failedItem = tremove(self.queue, 1)
                tinsert(self.queue, failedItem)
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8800Windowless timeout - moved to end of queue|r")
            end

            -- Trigger error event
            AceEvent:TriggerEvent("SkilletStitch_Craft_Failed", "Windowless craft timeout")

            -- Continue processing next item in queue
            if #self.queue > 0 then
                AceEvent:TriggerEvent("SkilletStitch_Queue_Continue", #self.queue)
                -- Show prompt for next item
                Skillet:ShowStartCraftingPrompt()
            else
                AceEvent:TriggerEvent("SkilletStitch_Queue_Complete")
            end
        end
        return
    end

    -- Traditional crafting: After 2.0 seconds, check if we're actually casting (catastrophic failure fallback)
    if elapsed > 2.0 then
        local casting = UnitCastingInfo("player") or UnitChannelInfo("player")
        if not casting then
            -- Synastria: Store timeout error
            self.lastCraftError = "Craft failed - no cast detected! Stopping queue."

            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000Skillet: Craft failed - no cast detected! Stopping queue.|r")

            -- Cancel the monitoring timer
            if AceEvent:IsEventScheduled("SkilletStitch_CraftMonitor") then
                AceEvent:CancelScheduledEvent("SkilletStitch_CraftMonitor")
            end

            -- Reset crafting state
            self.queuecasting = false
            self.craftAttemptTime = nil
            self.preCraftItemCount = nil
            self.expectedCraftCount = nil

            -- Synastria: Move failed item to end of queue
            if self.queue[1] then
                local failedItem = tremove(self.queue, 1)
                tinsert(self.queue, failedItem)
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8800Timeout - moved to end of queue|r")
            end

            -- Trigger error event
            AceEvent:TriggerEvent("SkilletStitch_Craft_Failed", self.lastCraftError)

            -- Continue processing next item in queue
            if #self.queue > 0 then
                AceEvent:TriggerEvent("SkilletStitch_Queue_Continue", #self.queue)
                -- Show prompt for next item
                Skillet:ShowStartCraftingPrompt()
            else
                AceEvent:TriggerEvent("SkilletStitch_Queue_Complete")
            end
        end
    end
end

-- Synastria: UI_ERROR_MESSAGE handler for craft failure detection
---@param errorType string The error type
---@param message string The error message
function SkilletStitch:OnUIError(errorType, message)
    -- Only check if we're actively crafting from queue
    if not self.queuecasting then
        return
    end

    -- Check if this is a craft-related error
    -- Common error messages that indicate craft failure:
    -- "You need to be near a forge to do that"
    -- "You need to be near an anvil to do that"
    -- "Item is not ready yet" (cooldown)
    -- "Not enough mana/rage/energy"
    -- etc.
    if message then
        -- Synastria: Store the error message
        self.lastCraftError = message

        -- Cancel monitoring timer if running
        if AceEvent:IsEventScheduled("SkilletStitch_CraftMonitor") then
            AceEvent:CancelScheduledEvent("SkilletStitch_CraftMonitor")
        end

        -- Reset crafting state
        self.queuecasting = false
        self.craftAttemptTime = nil
        self.preCraftItemCount = nil
        self.expectedCraftCount = nil

        -- Synastria: Move failed item to end of queue
        if self.queue[1] then
            local failedItem = tremove(self.queue, 1)
            tinsert(self.queue, failedItem)
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8800Craft failed - moved to end of queue|r")
        end

        -- Trigger event to update dialog with error
        AceEvent:TriggerEvent("SkilletStitch_Craft_Failed", message)

        -- Continue processing next item in queue
        if #self.queue > 0 then
            AceEvent:TriggerEvent("SkilletStitch_Queue_Continue", #self.queue)
            -- Show prompt for next item
            Skillet:ShowStartCraftingPrompt()
        else
            AceEvent:TriggerEvent("SkilletStitch_Queue_Complete")
        end
    end
end

-- Synastria: Spell cast failure handler (UNIT_SPELLCAST_FAILED, UNIT_SPELLCAST_INTERRUPTED)
---@param event string The event name
---@param unit string The unit that attempted the spell
---@param spell string|nil The spell name
---@param rank string|nil The spell rank
function SkilletStitch:OnSpellcastFailed(event, unit, spell, rank)
    -- Only care about player spells
    if unit ~= "player" then
        return
    end

    -- Only check if we're actively crafting from queue
    if not self.queuecasting then
        return
    end

    -- Synastria: Store the error
    local errorMsg = "Spell cast failed: " .. (spell or "Unknown")
    self.lastCraftError = errorMsg

    -- Cancel monitoring timer if running
    if AceEvent:IsEventScheduled("SkilletStitch_CraftMonitor") then
        AceEvent:CancelScheduledEvent("SkilletStitch_CraftMonitor")
    end

    -- Reset crafting state
    self.queuecasting = false
    self.craftAttemptTime = nil
    self.preCraftItemCount = nil
    self.expectedCraftCount = nil

    -- Synastria: Move failed item to end of queue
    if self.queue[1] then
        local failedItem = tremove(self.queue, 1)
        tinsert(self.queue, failedItem)
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8800Spell failed - moved to end of queue|r")
    end

    -- Trigger event to update dialog with error
    AceEvent:TriggerEvent("SkilletStitch_Craft_Failed", errorMsg)

    -- Continue processing next item in queue
    if #self.queue > 0 then
        AceEvent:TriggerEvent("SkilletStitch_Queue_Continue", #self.queue)
        -- Show prompt for next item
        Skillet:ShowStartCraftingPrompt()
    else
        AceEvent:TriggerEvent("SkilletStitch_Queue_Complete")
    end
end

-- Synastria: Spell cast success handler for windowless crafting (UNIT_SPELLCAST_SUCCEEDED)
---@param event string The event name
---@param unit string The unit that cast the spell
---@param spell string|nil The spell name
---@param rank string|nil The spell rank
---@param lineId number|nil The spell lineId
---@param spellId number|nil The spell ID
function SkilletStitch:OnSpellcastSucceeded(event, unit, spell, rank, lineId, spellId)
    -- Only care about player spells
    if unit ~= "player" then
        return
    end

    -- Only check if we're actively crafting from queue with windowless mode
    if not self.queuecasting or not self.windowlessCrafting then
        return
    end

    -- Synastria: WoW 3.3.5 doesn't provide spellId in this event (always nil)
    -- We can't match by spellId, so just trust that if we're in windowless mode
    -- and queuecasting, this is our craft completing

    -- Use the craftedItemId we stored during ProcessQueue
    local itemId = self.craftedItemId

    -- Synastria: For recipes without item output (enchanting, inscription research, etc.)
    -- craftedItemId will be 0 or nil. In these cases, trust the spell cast success
    -- and trigger completion immediately without inventory checks.
    if not itemId or itemId == 0 then
        if Skillet and Skillet:IsDevMode() then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[SPELLCAST] Recipe with no item output - completing immediately|r")
        end
        -- Delay 300ms to allow server processing
        AceEvent:ScheduleEvent("SkilletStitch_SpellcastCompletion", function()
            self:ProcessCraftCompletion()
        end, 0.3, self)
        return
    end

    -- For recipes with item output, verify inventory changed before completing
    -- Trigger ProcessCraftCompletion with slight delay
    -- 300ms allows server inventory update for multi-craft batches
    AceEvent:ScheduleEvent("SkilletStitch_SpellcastCompletion", function()
        local bagCount = GetItemCount(itemId, true) or 0
        local bankCount = 0
        if GetCustomGameData then
            bankCount = GetCustomGameData(13, itemId) or 0
        end
        local currentCount = bagCount + bankCount

        if currentCount > (self.preCraftItemCount or 0) then
            self:ProcessCraftCompletion()
        end
    end, 0.3, self)
end

-- Synastria: BAG_UPDATE handler for reliable craft detection

function SkilletStitch:OnBagUpdate()
    -- Only check if we're actively crafting from queue
    if not self.queuecasting then
        return
    end

    -- Only check if we have pre-craft tracking data
    if not self.preCraftItemCount or not self.expectedCraftCount then
        return
    end

    -- Use the itemId we stored during ProcessQueue
    local itemId = self.craftedItemId

    if not itemId then
        if Skillet and Skillet:IsDevMode() then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[BAG_UPDATE] No craftedItemId available|r")
        end
        return
    end

    local currentCount = GetItemCount(itemId, true) or 0

    -- Add resource bank count if available
    if GetCustomGameData then
        ---@type number
        currentCount = currentCount + (GetCustomGameData(13, itemId) or 0)
    end

    -- If inventory increased, craft completed
    if currentCount > self.preCraftItemCount then
        self:ProcessCraftCompletion()
    end
end

-- Synastria: Separated completion processing called by BAG_UPDATE

function SkilletStitch:ProcessCraftCompletion()
    if not self.queuecasting then
        if Skillet and Skillet:IsDevMode() then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF00FF[COMPLETION] Ignoring - not queuecasting|r")
        end
        return
    end

    if Skillet and Skillet:IsDevMode() then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[COMPLETION] ProcessCraftCompletion called|r")
    end

    -- Cancel the craft monitoring timer
    if AceEvent:IsEventScheduled("SkilletStitch_CraftMonitor") then
        AceEvent:CancelScheduledEvent("SkilletStitch_CraftMonitor")
    end

    -- Cancel proactive inventory poll timers (if any are still scheduled)
    if AceEvent:IsEventScheduled("SkilletStitch_Poll1") then
        AceEvent:CancelScheduledEvent("SkilletStitch_Poll1")
    end
    if AceEvent:IsEventScheduled("SkilletStitch_Poll2") then
        AceEvent:CancelScheduledEvent("SkilletStitch_Poll2")
    end
    if AceEvent:IsEventScheduled("SkilletStitch_Poll3") then
        AceEvent:CancelScheduledEvent("SkilletStitch_Poll3")
    end
    if AceEvent:IsEventScheduled("SkilletStitch_Poll4") then
        AceEvent:CancelScheduledEvent("SkilletStitch_Poll4")
    end
    if AceEvent:IsEventScheduled("SkilletStitch_Poll5") then
        AceEvent:CancelScheduledEvent("SkilletStitch_Poll5")
    end
    if AceEvent:IsEventScheduled("SkilletStitch_Poll6") then
        AceEvent:CancelScheduledEvent("SkilletStitch_Poll6")
    end

    -- Cancel delayed SPELLCAST completion check (if BAG_UPDATE already processed)
    if AceEvent:IsEventScheduled("SkilletStitch_SpellcastCompletion") then
        AceEvent:CancelScheduledEvent("SkilletStitch_SpellcastCompletion")
    end

    -- Clear timeout timer and craft attempt tracking
    self.craftAttemptTime = nil

    if not self.queue[1] then
        -- Synastria: Clear contents while keeping reference
        if self.queue then
            ---@type integer
            for k in pairs(self.queue) do
                self.queue[k] = nil
            end
        end
        if Skillet and Skillet:IsDevMode() then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[COMPLETION] Queue empty - triggering complete|r")
        end
        AceEvent:TriggerEvent("SkilletStitch_Queue_Complete")
        return
    end

    if Skillet and Skillet:IsDevMode() then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[COMPLETION] Queue item present - numcasts=" ..
            tostring(self.queue[1].numcasts) .. "|r")
    end

    -- Synastria: Check for bulk completion by comparing inventory changes
    local actualCrafted = 1 -- Default to 1 if we can't detect
    if self.preCraftItemCount and self.expectedCraftCount then
        -- Synastria: Get item ID and nummade from spell ID
        ---@type number
        local spellId = self.queue[1]["spellId"]
        local itemId = nil
        local nummade = 1 -- Default: 1 item per craft

        if spellId and Custom_GetProfessionRecipeInfo then
            local skillId, name, recipeItemId, craftCount = Custom_GetProfessionRecipeInfo(spellId)
            itemId = recipeItemId
            nummade = craftCount or 1 -- Items created per craft
            if Skillet and Skillet:IsDevMode() then
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[COMPLETION] Recipe creates " .. nummade .. " items per craft|r")
            end
        end

        if itemId then
            local bagCount = GetItemCount(itemId, true) or 0
            local bankCount = 0
            if GetCustomGameData then
                bankCount = GetCustomGameData(13, itemId) or 0
            end
            local postCraftItemCount = bagCount + bankCount

            local inventoryIncrease = postCraftItemCount - self.preCraftItemCount

            if Skillet and Skillet:IsDevMode() then
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[COMPLETION] Inventory: " ..
                    self.preCraftItemCount .. " -> " .. postCraftItemCount .. " (+" .. inventoryIncrease .. " items)|r")
            end

            -- Synastria: Calculate actual crafts completed
            -- Server multi-casts ALL numcasts at once in one spell
            -- inventoryIncrease = number of ITEMS created
            -- actualCrafted = number of CRAFTS completed = items / nummade
            if inventoryIncrease > 0 then
                actualCrafted = math.floor(inventoryIncrease / nummade)
                if Skillet and Skillet:IsDevMode() then
                    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[COMPLETION] actualCrafted = " ..
                        inventoryIncrease .. " items / " .. nummade .. " per craft = " .. actualCrafted .. " crafts|r")
                end
            end
        end
        -- Clear tracking variables
        self.preCraftItemCount = nil
        self.expectedCraftCount = nil
    end

    if Skillet and Skillet:IsDevMode() then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[COMPLETION] actualCrafted=" .. actualCrafted .. "|r")
    end

    -- Deduct the actual number of items crafted
    local beforeNumcasts = self.queue[1].numcasts
    self.queue[1].numcasts = self.queue[1].numcasts - actualCrafted
    local afterNumcasts = self.queue[1].numcasts

    if Skillet and Skillet:IsDevMode() then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[COMPLETION] numcasts: " ..
            beforeNumcasts .. " -> " .. afterNumcasts .. " (after -" .. actualCrafted .. ")|r")
    end

    -- Synastria: Update ResourceTracker after crafting
    -- Get recipe info from spell ID for ResourceTracker
    if Skillet and Skillet.UpdateResourceTrackerAfterCraft then
        ---@type number
        local spellId = self.queue[1].spellId
        local recipeInfo = nil
        if spellId and Custom_GetProfessionRecipeInfo then
            local skillId, name, itemId, craftCount = Custom_GetProfessionRecipeInfo(spellId)
            if name then
                recipeInfo = {
                    name = name,
                    spellId = spellId,
                    itemId = itemId
                }
            end
        end
        if recipeInfo then
            Skillet:UpdateResourceTrackerAfterCraft(recipeInfo, actualCrafted)
        end
    end

    if self.queue[1].numcasts < 1 then
        if Skillet and Skillet:IsDevMode() then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[COMPLETION] numcasts < 1 - removing from queue|r")
        end
        self:RemoveFromQueue(1)
        if #self.queue > 0 then
            if Skillet and Skillet:IsDevMode() then
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[COMPLETION] " ..
                    #self.queue .. " items remaining - click 'Start Crafting' again to continue|r")
            end
            AceEvent:TriggerEvent("SkilletStitch_Queue_Continue", #self.queue)
            -- Synastria: CANNOT auto-continue - Custom_DoProfessionRecipe requires hardware event!
            -- Player must click 'Start Crafting' button again to trigger next craft
            -- This is a WoW protected function limitation to prevent botting
        else
            if Skillet and Skillet:IsDevMode() then
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[COMPLETION] Queue complete!|r")
            end
            AceEvent:TriggerEvent("SkilletStitch_Queue_Complete")
        end
    else
        -- Synastria: Server multi-casts ALL items at once, so numcasts should never be >= 1 after completion
        -- If we somehow get here, it means server didn't complete all requested crafts
        if Skillet and Skillet:IsDevMode() then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[COMPLETION] numcasts >= 1 (" ..
                self.queue[1].numcasts .. ") - click 'Start Crafting' again to continue|r")
        end
        AceEvent:TriggerEvent("SkilletStitch_Queue_Continue", #self.queue)
        -- Same limitation: Cannot auto-continue, requires player action
    end
    self.queuecasting = false
    self.windowlessCrafting = false -- Clear windowless flag after completion
    self.expectedSpellId = nil      -- Clear expected spell ID

    -- NOTE: UNIT_SPELLCAST_SUCCEEDED is always registered on Skillet addon
    -- no need to unregister it here - it will filter by queuecasting flag

    if Skillet and Skillet:IsDevMode() then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[COMPLETION] queuecasting=false, windowlessCrafting cleared|r")
    end
end

-- Synastria: StopCast removed - BAG_UPDATE handles craft completion reliably

-- Stop a trade skill currently in prograess. We cannot cancel the current
-- item as that requires a "SpellStopCasting" call which can only be
-- made from secure code. All this does is stop repeating after the current item

function SkilletStitch:CancelCast()
    StopTradeSkillRepeat()
end

-- Synastria: Group queue items by profession to minimize profession switches

function SkilletStitch:GroupQueueByProfession()
    if not self.queue or #self.queue < 2 then
        return -- No need to group if queue is empty or has only one item
    end

    -- Create profession-based groups
    ---@type table<string, QueueEntry[]>
    local grouped = {}
    ---@type string[]
    local professionOrder = {}

    ---@type integer, QueueEntry
    for _, item in ipairs(self.queue) do
        ---@type string
        local prof = item.profession
        if not grouped[prof] then
            grouped[prof] = {}
            table.insert(professionOrder, prof)
        end
        table.insert(grouped[prof], item)
    end

    -- Rebuild queue with items grouped by profession
    local newQueue = {}
    ---@type integer, string
    for _, prof in ipairs(professionOrder) do
        ---@type integer, QueueEntry
        for _, item in ipairs(grouped[prof]) do
            table.insert(newQueue, item)
        end
    end

    self.queue = newQueue
    AceEvent:TriggerEvent("SkilletStitch_Queue_Update", #self.queue)
    if Skillet and Skillet:IsDevMode() then
        DEFAULT_CHAT_FRAME:AddMessage("Queue grouped by profession to minimize switches")
    end
end

--------------------
-- Internal Stuff --
--------------------
---@param link string The item link to extract ID from
---@return number|nil itemId The item ID, or nil if not found
function SkilletStitch:GetIDFromLink(link)
    local id = string.match(link, "item:(%d+)")
    return tonumber(id)
end

-- Synastria: Convert profession skill ID to 3-letter tag
---@param skillId number The skill ID
---@return string tag 3-letter profession tag
local function GetProfessionTag(skillId)
    local professionNames = {
        [171] = "ALC", -- Alchemy
        [164] = "BLA", -- Blacksmithing
        [333] = "ENC", -- Enchanting
        [202] = "ENG", -- Engineering
        [755] = "JEW", -- Jewelcrafting
        [165] = "LEA", -- Leatherworking
        [197] = "TAI", -- Tailoring
        [185] = "COO", -- Cooking
        [129] = "AID", -- First Aid
        [186] = "MIN", -- Mining (Smelting)
    }
    return professionNames[skillId] or "???"
end

---@param spellId number The recipe spellId
---@param times number|nil Number of times to queue (default: 1)
---@param profession string|nil Profession name (optional)
---@param addToTop boolean|nil Whether to add to top of queue (default: false)
---@param itemLink string|nil Item link for cross-profession lookup (optional)
---@param isPrimary boolean|nil True if user-queued, false/nil if auto-generated subcraft
function SkilletStitch:AddToQueue(spellId, times, profession, addToTop, itemLink, isPrimary)
    -- Synastria: Accept optional profession parameter for cross-profession queuing
    -- addToTop parameter to add items to the front of the queue
    -- itemLink parameter for cross-profession spell ID lookup
    -- isPrimary parameter to distinguish user-queued vs auto-generated subcrafts
    local recenttrade = profession or GetTradeSkillLine()

    -- Synastria: REMOVED - This was clearing the queue when switching professions!
    -- For unified queue across all professions, we want to keep all items
    --[[
    if self.queue[1] and self.queue[1]["profession"] ~= recenttrade then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[QUEUE DEBUG] CLEARING QUEUE! First item profession (" .. (self.queue[1]["profession"] or "nil") .. ") != current (" .. (recenttrade or "nil") .. ")|r")
        self:ClearQueue()
    end
    ]] --

    if not times then
        times = 1
    end

    -- Use spellIdIndex to get profession/index for legacy lookups if needed
    if not spellId or not spellIdIndex[spellId] then
        DEFAULT_CHAT_FRAME:AddMessage(
            "|cFFFF0000[AddToQueue] ERROR: Cannot queue - no spell ID available or not indexed!|r")
        return
    end

    -- Synastria: Check for existing queue entry with same spell ID (deduplication)
    local found = false
    ---@type integer, QueueEntry
    for _, s in pairs(self.queue) do
        if s.spellId and s.spellId == spellId then
            found = true
            s.numcasts = s.numcasts + times
            -- Only show in dev mode
            if Skillet and Skillet:IsDevMode() then
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[AddToQueue] Increased existing queue entry to " ..
                    s.numcasts .. " casts|r")
            end
            break
        end
    end

    if not found then
        -- Synastria: Get profession/index from spellIdIndex AND fetch recipe object
        local lookup = spellIdIndex[spellId]
        local professionName = lookup and lookup.profession or "UNKNOWN"
        local index = lookup and lookup.index or nil
        local displayName = "Unknown Recipe"
        local itemLink = nil

        -- CRITICAL: Fetch the actual recipe object for queue entry (runtime data)
        ---@type Recipe|nil
        local recipeObject = nil
        if professionName and professionName ~= "UNKNOWN" and index then
            recipeObject = self:GetItemDataByIndex(professionName, index)
            -- Get name from recipe if available (most reliable source)
            if recipeObject and recipeObject.name then
                displayName = recipeObject.name
            end
            -- Get link from recipe if available
            if recipeObject and recipeObject.link then
                itemLink = recipeObject.link
            end
        end

        -- Try Custom API as fallback/override for name and profession tag
        if spellId and Custom_GetProfessionRecipeInfo then
            local skillId, name, itemId = Custom_GetProfessionRecipeInfo(spellId)
            if Skillet and Skillet:IsDevMode() then
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[AddQueue DEBUG] Custom API returned: skillId=" ..
                    tostring(skillId) .. ", name=" .. tostring(name) .. ", itemId=" .. tostring(itemId) .. "|r")
            end
            if name then
                displayName = name -- API name overrides scanned name
            end
            if skillId and type(skillId) == "number" then
                professionName = GetProfessionTag(skillId)
            end
            -- Generate link if we have itemId but no link yet
            if itemId and itemId > 0 and not itemLink then
                itemLink = "item:" .. itemId
            end
        end

        -- Store queue data with SERIALIZABLE display fields + runtime recipe reference
        ---@type QueueEntry
        local queueEntry = {
            ["spellId"] = spellId,
            ["numcasts"] = times,
            ["profession"] = professionName,
            ["name"] = displayName or "Unknown Recipe",
            ["link"] = itemLink or "",
            ["recipe"] = recipeObject,
            ["isPrimary"] = isPrimary or false -- Synastria: Track if user-queued vs auto-generated
        }

        if Skillet and Skillet:IsDevMode() then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[AddQueue DEBUG] Created entry: spellId=" ..
                tostring(queueEntry.spellId) ..
                ", name='" ..
                tostring(queueEntry.name) ..
                "', profession='" .. tostring(queueEntry.profession) .. "', link='" .. tostring(queueEntry.link) .. "'|r")
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[AddQueue DEBUG] Recipe object: " ..
                (queueEntry.recipe and "EXISTS" or "NIL") .. "|r")
        end

        if addToTop then
            table.insert(self.queue, 1, queueEntry)
        else
            table.insert(self.queue, queueEntry)
        end

        if Skillet and Skillet:IsDevMode() then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[AddQueue DEBUG] Queue size after insert: " .. #self.queue .. "|r")
        end

        -- Only show in dev mode
        if Skillet and Skillet:IsDevMode() then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[QUEUED] " ..
                displayName .. " x" .. times .. " (Spell ID: " .. tostring(spellId) .. ")|r")
        end
        if Skillet and Skillet:IsDevMode() then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[QUEUE DEBUG] Queue size after add: " .. #self.queue .. "|r")
        end
    end

    if Skillet and Skillet:IsDevMode() then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[QUEUE DEBUG] Triggering SkilletStitch_Queue_Add event, queue size=" ..
            #self.queue .. "|r")
    end
    AceEvent:TriggerEvent("SkilletStitch_Queue_Add")
end

-- Returns the number of items (of the current index in the current tradeskill)
-- are queued
---@param index number The recipe index in current tradeskill
---@return number count Number of queued items for this recipe
function SkilletStitch:GetNumQueuedItems(index)
    -- Synastria: Convert index to spell ID first
    local recipeLink = GetTradeSkillRecipeLink(index)
    if not recipeLink then
        return 0
    end

    local spellId = tonumber(recipeLink:match("|Henchant:(%d+)|h"))
    if not spellId then
        return 0
    end

    ---@type number
    local count = 0
    if self.queue then
        ---@type integer, QueueEntry
        for k, v in pairs(self.queue) do
            if v["spellId"] == spellId then
                ---@type number
                count = count + tonumber(v["numcasts"])
            end
        end
    end

    return count
end

function SkilletStitch:ScanTrade()
    local prof = GetTradeSkillLine()
    if not prof or prof == "UNKNOWN" then
        return
    end
    if self.data then
        if not self.data[prof] then
            self.data[prof] = {}
        end
    else
        self.data = {}
        self.data[prof] = {}
    end

    -- Synastria: Initialize recipe info cache for this profession
    if not recipeInfoCache[prof] then
        recipeInfoCache[prof] = {}
    end

    if cache then
        cache[prof] = nil
    end
    local shred = false
    for i = 1, GetNumTradeSkills() do
        local skillname, skilltype = GetTradeSkillInfo(i)
        if skilltype ~= "header" and skillname then
            local newstr = nil
            local link = GetTradeSkillItemLink(i)
            local reagents = {}        -- Synastria: Initialize reagents table
            local maxmade = 1          -- Synastria: Default to 1 item per craft
            ---@type number|nil
            local scannedSpellId = nil -- Synastria: will be set from GetTradeSkillRecipeLink

            if not link then
                shred = true
            else
                -- Synastria: Cache recipe name and link for cross-profession queuing
                recipeInfoCache[prof][i] = {
                    name = skillname,
                    link = link
                }

                -- Synastria: Store the recipe's own unique spell ID.
                -- GetTradeSkillRecipeLink returns |Henchant:SPELLID|h which is UNIQUE per recipe,
                -- unlike GetTradeSkillItemLink which shares item IDs across recipes that produce the
                -- same product (e.g. "Smelt Titanium" and "Transmute: Titanium" both produce item 36909).
                local recipeSpellLink = GetTradeSkillRecipeLink(i)
                if recipeSpellLink then
                    scannedSpellId = tonumber(recipeSpellLink:match("|Henchant:(%d+)|h"))
                end

                local v1, _, v2, _, v3, _, v4 = GetTradeSkillTools(i)
                ---@type string
                local tool1 = v1 or ""
                ---@type string
                local tool2 = v2 or ""
                ---@type string
                local tool3 = v3 or ""
                ---@type string
                local tool4 = v4 or ""
                if tool4 ~= "" then
                    ---@type string
                    tool1 = tool1 .. ", " .. tool2 .. ", " .. tool3 .. ", " .. tool4
                elseif tool3 ~= "" then
                    ---@type string
                    tool1 = tool1 .. ", " .. tool2 .. ", " .. tool3
                elseif tool2 ~= "" then
                    ---@type string
                    tool1 = tool1 .. ", " .. tool2
                elseif tool1 then
                    tool1 = tool1
                end
                local linkname = link:match("%|h%[([^%]]+)%]%|h")
                local squishedlink = squishlink(link) -- Synastria: Keep original link, squish for encoding

                local minmade
                minmade, maxmade = GetTradeSkillNumMade(i)

                if linkname == skillname then
                    newstr = ";" ..
                        squishedlink .. ";" .. difficultyr[skilltype] .. maxmade .. ";" .. (tool1 or "") .. ";"
                else
                    newstr = skillname ..
                        ";" .. squishedlink .. ";" .. difficultyr[skilltype] .. maxmade .. ";" .. (tool1 or "") .. ";"
                end

                -- Synastria: Build reagents table with vendor info for new format
                for j = 1, GetTradeSkillNumReagents(i) do
                    local reagentName, _, rcount, _ = GetTradeSkillReagentInfo(i, j)
                    local reagentLink = GetTradeSkillReagentItemLink(i, j)
                    if not reagentLink then
                        shred = true
                    else
                        -- Add to encoded string for backward compatibility
                        local squished = squishlink(reagentLink)
                        ---@type string
                        newstr = newstr .. rcount .. ";" .. squished .. ";"

                        -- Synastria: Get vendor status from PeriodicTable for new format
                        local vendor = false

                        -- Synastria: Use PeriodicTable for vendor detection
                        -- Check both the base PT vendor set and our Skillet extension
                        if PT then
                            vendor = (PT:ItemInSet(reagentLink, "Tradeskill.Mat.BySource.Vendor") or PT:ItemInSet(reagentLink, "Skillet.Vendor.Extended")) and
                                true or false
                        end

                        -- Store reagent in new format
                        table.insert(reagents, {
                            name = reagentName,
                            link = reagentLink,
                            needed = rcount,
                            vendor = vendor
                        })
                    end
                end
            end

            -- Synastria: Only write recipe data when we have a valid item link.
            -- If GetTradeSkillItemLink returned nil (link=nil), DON'T overwrite the existing
            -- valid entry for this index. Preserving stale data is much better than replacing
            -- it with a broken nil-link entry — the recipe stays visible while AutoRescan retries.
            if link then
                self.data[prof][i] = {
                    name = skillname,
                    link = link,             -- Synastria: Store original unsquished link
                    encoded = newstr,        -- Keep encoded version for compatibility
                    reagents = reagents,     -- Synastria: Store reagents with vendor info
                    nummade = maxmade,       -- Synastria: Store items created per craft
                    spellId = scannedSpellId -- Synastria: Canonical per-recipe spell ID
                }
            end
            -- else: keep whatever was in self.data[prof][i] before this scan
        else
            self.data[prof][i] = nil
        end
    end
    if shred then
        -- Synastria: DON'T wipe all recipe data on shred. Stale data is better than no data.
        -- GetTradeSkillItemLink can return nil very briefly after a craft (e.g. transmutation
        -- cooldown window, item link cache flush). Wiping all recipes causes the entire list
        -- to go blank for 3 seconds. Instead, preserve existing entries intact so the UI stays
        -- usable, trigger Scan_Complete so the UI refreshes with the stale-but-valid data,
        -- and schedule AutoRescan to do a proper fresh scan 3 seconds later.
        AceEvent:TriggerEvent("SkilletStitch_Scan_Complete", prof)
        if not AceEvent:IsEventScheduled("SkilletStitch_AutoRescan") then
            AceEvent:ScheduleEvent("SkilletStitch_AutoRescan", self.SkilletStitch_AutoRescan, 3, self)
        end
    else
        AceEvent:TriggerEvent("SkilletStitch_Scan_Complete", prof)
    end
end

-- @function         SetAltCharacterItemLookupFunction
-- @brief            Sets the fucntion to be used when looking up reagent counts
--                   from alternate characters. If not set, then no cross-character
--                   item counts are done and the corresponding fields are set to
--                   nil (not zero) to indicate that the data is not available.
-- @param func       The function to be used. The function should take an
--                   item link and return a count across all characters including
--                   the current one.
---@param func function|nil The function to lookup alt item counts
function SkilletStitch:SetAltCharacterItemLookupFunction(func)
    if func then
        alt_lookup_function = func
    end
end

----------------------
-- AceLibrary Stuff --
----------------------
-- Synastria: Detect and purge old string-based recipe format
---@param data table<string, table<integer, RecipeData|string>>|nil The data to check
---@return boolean hasOldFormat True if old format data was found and purged
local function purgeOldFormatData(data)
    if not data then
        return false
    end

    ---@type boolean
    local foundOldFormat = false

    ---@type string
    for profession, recipes in pairs(data) do
        if type(recipes) == "table" then
            ---@type integer, any
            for index, recipe in pairs(recipes) do
                -- Check if this is old string format (not a table with expected RecipeData fields)
                if type(recipe) == "string" then
                    foundOldFormat = true
                    recipes[index] = nil
                end
            end
        end
    end

    if foundOldFormat then
        DEFAULT_CHAT_FRAME:AddMessage(
            "|cFFFF9900[Skillet] Old recipe data format detected and purged. Professions will be rescanned.|r")
    end

    return foundOldFormat
end

---@param self SkilletStitch
---@param oldLib SkilletStitch|nil
---@param oldDeactivate function|nil
local function activate(self, oldLib, oldDeactivate)
    if oldLib then
        ---@type table<string, table<integer, RecipeData>>
        self.data = oldLib.data
        ---@type table<string, boolean>
        self.datagatheraddons = oldLib.datagatheraddons
        ---@type table<string, boolean>
        self.queueaddons = oldLib.queueaddons
        ---@type QueueEntry[]
        self.queue = oldLib.queue
        ---@type boolean
        self.queuecasting = oldLib.queuecasting
        ---@type table<string, function>
        self.hooks = oldLib.hooks
        ---@type boolean
        self.queueenabled = oldLib.queueenabled
    end
    if not self.data then
        self.data = {}
    end

    -- Synastria: On load, detect and purge any old format data
    purgeOldFormatData(self.data)
    if not self.queueenabled then
        self.queueenabled = false
    end
    if not self.queueaddons then
        self.queueaddons = {}
    end
    if not self.datagatheraddons then
        self.datagatheraddons = {}
    end
    -- Synastria: Don't initialize queue here - LoadQueue will set it from database
    -- if not self.queue then
    --     self.queue = {}
    -- end
    if not self.queuecasting then
        self.queuecasting = false
    end
    if oldDeactivate then
        oldDeactivate(oldLib)
    end
end

---@param self SkilletStitch
---@param major string
---@param instance any
local function external(self, major, instance)
    if major == "AceEvent-2.0" then
        AceEvent = instance
        AceEvent:embed(self)
        self:UnregisterAllEvents()
        self:CancelAllScheduledEvents()
    end
end

AceLibrary:Register(SkilletStitch, MAJOR_VERSION, MINOR_VERSION, activate, external)
-- Note: SkilletStitch is registered as a library singleton and persists after this assignment

--[[
self.data = {
    professionname = {

        --if name is the same as link

        [1] = ";link;diffnumcrafted;tools;reagent1num;reagent1link;reagent2num;reagent2link;",

        --if name is different from link

        [2] = "name;link;diffnummcrafted;tools;reagent1num;reagent1link;reagent2num;reagent2link;",

        --store difficulty as one letter
        --'o' = optimal
        --'m' = medium
        --'e' = easy
        --'t' = trivial

        index = {
            ["name"] = itemname,
            ["difficulty"] = "optimal",
            ["nummade"] = nummade,
            ["link"] = link,
            ["tools"] = "tools",
            ["texture"] = "texture",
            ["numcraftable"] = number,
            ["numcraftablewbank"] = number,
            ["numcraftablewalts"] = number or nil if not available
            [reagentindex] = {
                ["name"] = name,
                ["link"] = link,
                ["needed"] = num,
                ["texture"] = texture,
                ["num"] = number,
                ["numwbank"] = number,
                ["numwalts"] = number or nil if not available
                ['vendor'] = bool,
            },

            --nuking..
            ["numreagents"] = num,
            ["index"] = index,
            ["profession"] = profession,

        }
    }
}
]]
