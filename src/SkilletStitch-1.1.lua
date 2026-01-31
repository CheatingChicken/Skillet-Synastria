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
local MINOR_VERSION = "$Rev: 166 $"  -- Synastria: Bumped for PT vendor extension

if not AceLibrary then error(MAJOR_VERSION .. " requires AceLibrary") end
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then return end
if not AceLibrary:HasInstance("AceEvent-2.0") then error(MAJOR_VERSION .. " requires AceEvent-2.0") end
local AceEvent = AceLibrary("AceEvent-2.0")
local PT
if AceLibrary:HasInstance("LibPeriodicTable-3.1") then
    PT = AceLibrary("LibPeriodicTable-3.1")
end

local SkilletStitch = {}
SkilletStitch.hooks = {}
-- Use to get item counts from alts. Requires compatible inventory mod/library.
local alt_lookup_function = nil

local difficultyt = {
    o = "optimal",
    m = "medium",
    e = "easy",
    t = "trivial",
}
local difficultyr = {
    optimal = "o",
    medium = "m",
    easy = "e",
    trivial = "t",
}
local function squishlink(link)
    -- in:  |cffffffff|Hitem:13928:0:0:0:0:0:0:0|h[Grilled Squid]|h|r
    -- out: ffffff|13928|Grilled Squid
    local color, id, name = link:match("^|cff(......)|Hitem:(%d+):[^:]+:[^:]+:[^:]+:[^:]+:[^:]+:[^:]+:[^:]+:[^:]+|h%[([^%]]+)%]|h|r$")
    if id then
        return color.."|"..id.."|"..name
    else
        -- in:  |cffffffff|Henchant:7421|h[Runed Copper Rod]|h|r
        -- out: |-7421|Runed Copper Rod
        id, name = link:match("^|cffffd000|Henchant:(%d+)|h%[([^%]]+)%]|h|r$")
        return "|-"..id.."|"..name
    end
end
local function unsquishlink(link)
    -- in:  ffffff|13928|Grilled Squid
    -- out: |cffffffff|Hitem:13928:0:0:0:0:0:0:0|h[Grilled Squid]|h|r  ,false
    local color, id, name = link:match("^([^|].....)|(%d+)|(.+)$")
    if id then
        return "|cff"..color.."|Hitem:"..id..":0:0:0:0:0:0:0:0|h["..name.."]|h|r", false
    else
        -- in:  |-7421|Runed Copper Rod
        -- out: |cffffffff|Henchant:7421|h[Runed Copper Rod]|h|r ,true
        id, name = link:match("^|%-(%d+)|(.+)$")
        if id then
            return "|cffffd000|Henchant:"..id.."|h["..name.."]|h|r",true
        else
            return link
        end
    end
end

local reserved_reagents = nil

-- Synastria: Crystallized <-> Eternal conversion mappings
-- 10 Crystallized = 1 Eternal (and vice versa)
local CRYSTALLIZED_TO_ETERNAL = {
    [37700] = 35622, -- Crystallized Air -> Eternal Air
    [37701] = 35624, -- Crystallized Earth -> Eternal Earth
    [37702] = 36860, -- Crystallized Fire -> Eternal Fire
    [37704] = 35625, -- Crystallized Life -> Eternal Life
    [37703] = 35627, -- Crystallized Shadow -> Eternal Shadow
    [37705] = 35623, -- Crystallized Water -> Eternal Water
}

local ETERNAL_TO_CRYSTALLIZED = {
    [35622] = 37700, -- Eternal Air -> Crystallized Air
    [35624] = 37701, -- Eternal Earth -> Crystallized Earth
    [36860] = 37702, -- Eternal Fire -> Crystallized Fire
    [35625] = 37704, -- Eternal Life -> Crystallized Life
    [35627] = 37703, -- Eternal Shadow -> Crystallized Shadow
    [35623] = 37705, -- Eternal Water -> Crystallized Water
}

-- Synastria: Extract item ID from item link for resource bank queries
local function extract_item_id(link)
    if not link then return nil end
    local id = string.match(link, "item:(%d+)")
    return tonumber(id)
end

-- Synastria: Get count of items in resource bank
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
local function get_item_count_with_conversions(itemId, includeBank)
    if type(itemId) ~= "number" then
        return 0
    end
    
    -- Get base count for the requested item
    local baseCount = GetItemCount(itemId, includeBank) or 0
    local rbankCount = (GetCustomGameData and GetCustomGameData(13, itemId)) or 0
    local totalCount = baseCount + rbankCount
    
    -- Synastria: Check queued conversions that will produce this item
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
        local convertibleBase = GetItemCount(convertFromId, includeBank) or 0
        local convertibleRbank = (GetCustomGameData and GetCustomGameData(13, convertFromId)) or 0
        local convertibleTotal = convertibleBase + convertibleRbank
        
        -- Synastria: Subtract any Crystallized that are queued to be converted
        -- (they won't be available for other conversions)
        if lib and lib.queue then
            for i = 1, #lib.queue do
                local entry = lib.queue[i]
                if entry.recipe and entry.recipe.isVirtualConversion then
                    if entry.recipe.crystallizedId == convertFromId then
                        -- This queued conversion will use up some of the Crystallized
                        convertibleTotal = convertibleTotal - entry.recipe.crystallizedNeeded
                    end
                end
            end
        end
        
        -- Add the converted amount to our total
        -- If ratio is 10, we divide by 10 (10 crystallized = 1 eternal)
        -- If ratio is 0.1, we multiply by 10 (1 eternal = 10 crystallized)
        local convertedAmount = math.floor(convertibleTotal / conversionRatio)
        totalCount = totalCount + convertedAmount
    end
    
    return totalCount
end

-- Returns the count of reagents of type 'link' that have
-- already been reserved
local function get_reserved_reagent_count(link)
    local count = 0

    if reserved_reagents then
        for i=#reserved_reagents, 1, -1 do
            if reserved_reagents[i].link == link then
                count = reserved_reagents[i].count
                break
            end
        end
    end

    return count
end

-- Synastria: Cache for craftability calculations to avoid recalculation
local craftabilityCache = {}
local cacheStats = {
    hits = 0,
    misses = 0,
    calculations = 0
}

-- Synastria: Clear the craftability cache
local function clearCraftabilityCache()
    craftabilityCache = {}
    cacheStats = {
        hits = 0,
        misses = 0,
        calculations = 0
    }
    -- Also clear the recipe cache to force fresh recipe objects
    if cache then
        for profession, _ in pairs(cache) do
            cache[profession] = nil
        end
    end
end

-- Synastria: Selectively invalidate cache entries for recipes that use specific items
local function invalidateCacheForItems(itemIds)
    if not itemIds or #itemIds == 0 then
        return 0
    end
    
    -- Convert item IDs to a lookup table for faster checking
    local itemLookup = {}
    for _, itemId in ipairs(itemIds) do
        itemLookup[tonumber(itemId)] = true
    end
    
    local invalidatedCount = 0
    local cacheEntryCount = 0
    
    -- Count cache entries
    for _ in pairs(craftabilityCache) do
        cacheEntryCount = cacheEntryCount + 1
    end
    -- craftabilityCache has entries (debug output removed)
    
    -- Iterate through all cached entries
    for cacheKey, _ in pairs(craftabilityCache) do
        -- Cache key format: "profession:index:numcraftable"
        local profession, indexStr, key = cacheKey:match("^(.+):(%d+):(.+)$")
        if profession and indexStr then
            local index = tonumber(indexStr)
            -- Use GetItemDataByIndex to get full recipe with reagents
            local lib = AceLibrary("SkilletStitch-1.1")
            local recipe = lib:GetItemDataByIndex(profession, index)
            
            if recipe then
                -- Check if this recipe uses any of the affected items as reagents
                local usesAffectedItem = false
                local reagentCount = 0
                for _, reagent in ipairs(recipe) do
                    reagentCount = reagentCount + 1
                    local reagentId = tonumber((reagent.link or ""):match("item:(%d+)"))
                    if reagentId and itemLookup[reagentId] then
                        -- Recipe uses affected item (debug output removed)
                        usesAffectedItem = true
                        break
                    end
                end
                
                if usesAffectedItem then
                    craftabilityCache[cacheKey] = nil
                    invalidatedCount = invalidatedCount + 1
                elseif reagentCount == 0 then
                    -- Recipe has no reagents in cache (debug output removed)
                end
            else
                -- Could not find recipe (debug output removed)
            end
        end
    end
    
    return invalidatedCount
end

-- Synastria: Get cache statistics
local function getCacheStats()
    return cacheStats
end

-- Synastria: Get cached craftability value
local function getCachedCraftability(recipe, key)
    if not recipe.profession or not recipe.index then
        return nil
    end
    local cacheKey = string.format("%s:%d:%s", recipe.profession, recipe.index, key)
    local cached = craftabilityCache[cacheKey]
    if cached ~= nil then
        cacheStats.hits = cacheStats.hits + 1
    end
    return cached
end

-- Synastria: Set cached craftability value
local function setCachedCraftability(recipe, key, value)
    if not recipe.profession or not recipe.index then
        return
    end
    local cacheKey = string.format("%s:%d:%s", recipe.profession, recipe.index, key)
    craftabilityCache[cacheKey] = value
end

local itemmeta = {
    __index = function(self,key)
        if key == "numcraftable" then
            -- Check cache first
            local cached = getCachedCraftability(self, key)
            if cached ~= nil then
                cacheStats.hits = cacheStats.hits + 1
                return cached
            end
            
            cacheStats.misses = cacheStats.misses + 1
            cacheStats.calculations = cacheStats.calculations + 1
            
            local num = 1000
            for _,v in ipairs(self) do
                if v.vendor == false then
                    local available = v.num
                    
                    -- Synastria: DO NOT check sub-reagent craftability here
                    -- That causes recursive calculations and freezing
                    -- Only the background calculation process should populate the cache
                    -- which is then used by all recipes via the cache check above
                    
                    local max = math.floor(available/v.needed)*self.nummade
                    if max < num then
                        num = max
                    end
                end
            end
            if num == 1000 then
                for _,v in ipairs(self) do
                    local max = math.floor(v.num/v.needed)*self.nummade
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
            local cached = getCachedCraftability(self, key)
            if cached ~= nil then
                cacheStats.hits = cacheStats.hits + 1
                return cached
            end
            
            cacheStats.misses = cacheStats.misses + 1
            cacheStats.calculations = cacheStats.calculations + 1
            
            local num = 1000
            for _,v in ipairs(self) do
                if v.vendor == false then
                    local available = v.numwbank
                    
                    -- Synastria: DO NOT check sub-reagent craftability here
                    -- Only the background calculation process should populate the cache
                    
                    local max = math.floor(available/v.needed)*self.nummade
                    if max < num then
                        num = max
                    end
                end
            end
            if num == 1000 then
                for _,v in ipairs(self) do
                    local max = math.floor(v.numwbank/v.needed)*self.nummade
                    if max < num then
                        num = max
                    end
                end
            end
            
            -- Cache the result
            setCachedCraftability(self, key, num)
            return num
        elseif key == "numcraftablewalts" and alt_lookup_function then
            local num = 1000
            for _,v in ipairs(self) do
                if v.vendor == false then
                    local max = math.floor(v.numwalts/v.needed)*self.nummade
                    if max < num then
                        num = max
                    end
                end
            end
            if num == 1000 then
                for _,v in ipairs(self) do
                    local max = math.floor(v.numwalts/v.needed)*self.nummade
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
    __index = function(self,key)
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
                count = GetItemCount(self.link,true) + get_resource_bank_count(self.link)
            end
        elseif key == "numwalts" and alt_lookup_function ~= nil then
            count = alt_lookup_function(self.link) or 0
        end

        return math.max(0, count - reserved)
    end
}
local cache = setmetatable({},{
    __index = function(self,prof)
        if prof == "UNKNOWN" then
            return
        end
        self[prof] = setmetatable({},{
            __mode = 'v',
            __index = function(self,key)
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

                return self[key]
            end
        })
        return self[prof]
    end
})

-- Synastria: Simple recipe info cache for cross-profession queuing
-- Stores just name and link for each recipe when profession is scanned
local recipeInfoCache = {}

-- Synastria: Populate the recipe info cache from database on load
-- This function extracts name and link from the stored recipe data
local function PopulateRecipeInfoCache()
    local l = AceLibrary("SkilletStitch-1.1")
    if not l.data then
        return
    end
    
    for profession, recipes in pairs(l.data) do
        if not recipeInfoCache[profession] then
            recipeInfoCache[profession] = {}
        end
        
        for index, data in pairs(recipes) do
            -- If data is already in new table format, use it directly
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
local function needsRecipeScan(profession)
    local l = AceLibrary("SkilletStitch-1.1")
    if not l.data or not l.data[profession] then
        return false -- No data at all, will scan when opened
    end
    
    -- Check if any recipe is still in encoded string format
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

function SkilletStitch:DecodeRecipe(datastring)
    if not datastring then
        return
    end
    
    -- Synastria: Handle new table format with reagents
    if type(datastring) == "table" then
        -- New format stores {name, link, encoded, reagents}
        if datastring.encoded and datastring.reagents and #datastring.reagents > 0 then
            -- We have both encoded and non-empty reagent data
            -- Decode the encoded string for recipe metadata, then use stored reagents
            local itemchunk, _ = datastring.encoded:match("^([^;]-;[^;]-;[^;]-;[^;]-;)(.-)$")
            local nameoverride, link, difficultychar, numcrafted, tools = itemchunk:match("^([^;]-);([^;]+);(%a)(%d+);([^;]-);$")
            local isenchant
            
            link,isenchant = unsquishlink(link)
            if nameoverride:len() == 0 then
                nameoverride = link:match("%|h%[([^%]]+)%]%|h")
            end
            if tools:len() == 0 then
                tools = nil
            end
            local texture
            if isenchant then
                texture = "Interface\\Icons\\Spell_Holy_GreaterHeal"
            else
                texture = select(10,GetItemInfo(link))
            end
            
            local s = setmetatable({
                name = nameoverride,
                difficulty = difficultyt[difficultychar],
                nummade = tonumber(numcrafted),
                link = link,
                tools = tools,
                texture = texture,
                profession = prof,
                index = key,
            },itemmeta)
            
            -- Synastria: Use pre-scanned reagents with vendor info
            for _, reagentData in ipairs(datastring.reagents) do
                local texture = select(10, GetItemInfo(reagentData.link))
                table.insert(s,setmetatable({
                    name = reagentData.name,
                    link = reagentData.link,
                    needed = reagentData.needed,
                    texture = texture,
                    vendor = reagentData.vendor,  -- Synastria: Use stored vendor flag
                },reagentmeta))
            end
            
            return s
        elseif datastring.encoded then
            -- Recursively call with the encoded string to get full recipe data (old format)
            return self:DecodeRecipe(datastring.encoded)
        else
            -- Minimal table without encoded data
            -- This means the recipe hasn't been scanned yet with the new system
            -- Return a minimal valid recipe object to prevent errors
            -- Mark it as needing rescan
            local minimal = {
                name = datastring.name,
                link = datastring.link,
                needsRescan = true,
            }
            -- Return empty recipe with just name/link to prevent crashes
            return setmetatable(minimal, itemmeta)
        end
    end

    local itemchunk, reagentchunk = datastring:match("^([^;]-;[^;]-;[^;]-;[^;]-;)(.-)$")
    local nameoverride, link, difficultychar, numcrafted, tools = itemchunk:match("^([^;]-);([^;]+);(%a)(%d+);([^;]-);$")
    local isenchant

    link,isenchant = unsquishlink(link)
    if nameoverride:len() == 0 then
        nameoverride = link:match("%|h%[([^%]]+)%]%|h")
    end
    if tools:len() == 0 then
        tools = nil
    end
    local texture
    if isenchant then
        texture = "Interface\\Icons\\Spell_Holy_GreaterHeal"
    else
        texture = select(10,GetItemInfo(link))
    end

    local s = setmetatable({
        name = nameoverride,
        difficulty = difficultyt[difficultychar],
        nummade = tonumber(numcrafted),
        link = link,
        tools = tools,
        texture = texture,
        profession = prof,
        index = key,
    },itemmeta)
    for reagentnum, reagentlink in reagentchunk:gmatch("([^;]+);([^;]+);") do
        reagentlink = unsquishlink(reagentlink)
        local texture = select(10, GetItemInfo(reagentlink))
        local vendor = false
        
        -- Synastria: Use PeriodicTable for vendor detection
        -- Check both the base PT vendor set and our Skillet extension
        if PT then
            vendor = (PT:ItemInSet(reagentlink,"Tradeskill.Mat.BySource.Vendor") or PT:ItemInSet(reagentlink,"Skillet.Vendor.Extended")) and true or false
        end

        table.insert(s,setmetatable({
            name = reagentlink:match("%|h%[([^%]]+)%]%|h"),
            link = reagentlink,
            needed = tonumber(reagentnum),
            texture = texture,
            vendor = vendor,
        },reagentmeta))
    end

    return s
end

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
function SkilletStitch:SetReservedReagentsList(reagents)
    reserved_reagents = reagents
    -- Synastria: Removed debug spam - this gets called very frequently
end

-- Synastria: Clear the craftability cache
function SkilletStitch:ClearCraftabilityCache()
    clearCraftabilityCache()
end

-- Synastria: Invalidate cache for recipes that use specific items
function SkilletStitch:InvalidateCacheForItems(itemIds)
    return invalidateCacheForItems(itemIds)
end

-- Synastria: Get cache statistics
function SkilletStitch:GetCacheStats()
    return getCacheStats()
end

-- Synastria: Set cached craftability value (for background calculation)
function SkilletStitch:SetCachedCraftability(recipe, key, value)
    setCachedCraftability(recipe, key, value)
end

-- Synastria: Get cached craftability value (for background calculation)
function SkilletStitch:GetCachedCraftability(recipe, key)
    return getCachedCraftability(recipe, key)
end

function SkilletStitch:EnableDataGathering(addon)
    assert(tostring(addon),"Usage: EnableDataGathering('addon')")
    self.datagatheraddons[addon] = true
    self:RegisterEvent("TRADE_SKILL_SHOW")
    self:RegisterEvent("CHAT_MSG_SKILL")
    if not self.data then
        self.data = {}
    end
end

function SkilletStitch:DisableDataGathering(addon)
    if not addon then
        self.data = nil
        self.datagatheraddons = {}
        return
    end
    assert(tostring(addon),"Usage: DisableDataGathering(['addon'])")
    self.datagatheraddons[addon] = false
    if next(self.datagatheraddons) then
        return
    end
    self:UnregisterEvent("TRADE_SKILL_SHOW")
    self:UnregisterEvent("CHAT_MSG_SKILL")
    self.data = nil
end

function SkilletStitch:EnableQueue(addon)
    assert(tostring(addon),"Usage: EnableQueue('addon')")
    self.queueaddons[addon] = true
    -- Synastria: Use BAG_UPDATE for reliable craft detection
    self:RegisterEvent("BAG_UPDATE", "OnBagUpdate")
    -- Synastria: Don't create new queue table - LoadQueue will set it from database
    -- if not self.queue then
    --     self.queue = {}
    -- end
    self.queueenabled = true
end

function SkilletStitch:DisableQueue(addon)
    if not addon then
        self.queue = nil
        self.queueaddons = {}
        self.queueenabled = false
        return
    end
    assert(tostring(addon),"Usage: DisableDataGathering(['addon'])")
    self.queueaddons[addon] = false
    if next(self.queueaddons) then
        return
    end
    self:UnregisterEvent("BAG_UPDATE")
    self.queueenabled = false
    self.queue = nil
end

function SkilletStitch:GetItemDataByIndex(profession, index)
    assert(tonumber(index) and profession,"Usage: GetItemDataByIndex('profession', index)")
    return cache[profession][index]
end

function SkilletStitch:GetItemDataByName(name,prof)
    assert(tostring(name) ,"Usage: GetItemDataByName('name')")
    
    -- Synastria: Track all matching recipes to implement profession priority
    local matches = {}
    
    for k,v in pairs(cache) do
        if not prof or k==prof then
            for l,w in pairs(v) do
                if w.name == name then
                    table.insert(matches, {profession = k, recipe = cache[k][l]})
                end
            end
        end
    end
    
    -- If no exact match in cache, search data
    if #matches == 0 then
        name = string.gsub(name, "([%.%(%)%%%+%-%*%?%[%]%^%$])", "%%%1")
        for k,v in pairs(self.data) do
            if not prof or k==prof then
                for l,w in pairs(v) do
                    -- Synastria: Handle both old string format and new table format
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
                    
                    if chunk and (chunk:match("^"..name) or chunk:match("|"..name..";")) then
                        table.insert(matches, {profession = k, recipe = cache[k][l]})
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
        
        -- If no Smelting or Mining, return first match
        return matches[1].recipe
    elseif #matches == 1 then
        return matches[1].recipe
    end
    
    -- No matches found
    return nil
end

local result = {}
function SkilletStitch:GetItemDataByPartialName(name)
    for k,_ in pairs(result) do
        result[k] = nil
    end
    assert(tostring(name),"Usage: GetItemDataByPartialName('name')")
    name = name:gsub("([%.%(%)%%%+%-%*%?%[%]%^%$])", "%%%1")
    for k,v in pairs(self.data) do
        for l,w in pairs(v) do
            local chunk = w:match("([^;]-;[^;]-;)")
            if chunk:match("^"..name) or chunk:match("%|h%["..name.."%]%|h") then
                table.insert(result,cache[k][l])
            end
        end
    end
    if #result == 0 then
        return
    else
        return result
    end
end

function SkilletStitch:GetQueueInfo()
    return self.queue
end

function SkilletStitch:GetQueueItemInfo(index)
    -- Synastria: Handle virtual recipes (conversions, etc.) that store their data in .recipe field
    local queueEntry = self.queue[index]
    if queueEntry and queueEntry.recipe and queueEntry.recipe.isVirtualConversion then
        -- Virtual recipe - return the recipe data directly
        return queueEntry.recipe
    end
    -- Normal recipe - lookup from cache
    return cache[self.queue[index]["profession"]][self.queue[index]["index"]]
end

function SkilletStitch:RemoveFromQueue(index)
    -- Synastria: Check if we're removing a conversion to invalidate cache
    local removedEntry = self.queue[index]
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
    for k in pairs(self.queue) do
        self.queue[k] = nil
    end
    -- Queue cleared (debug output removed)
    AceEvent:TriggerEvent("SkilletStitch_Queue_Complete")
end

function SkilletStitch:ProcessQueue()
    if not self.queue[1] or type(self.queue[1]) ~= "table" then
        -- Synastria: Clear the table contents while keeping the same reference
        for k in pairs(self.queue) do
            self.queue[k] = nil
        end
        -- Invalid queue cleared (debug output removed)
        AceEvent:TriggerEvent("SkilletStitch_Queue_Complete")
        return
    end
    
    -- Synastria: Check if this is a virtual conversion recipe BEFORE profession check
    local recipe = self.queue[1]["recipe"]
    if recipe and recipe.isVirtualConversion then
        -- This is a conversion task, show the crafting prompt which handles conversions
        Skillet:ShowStartCraftingPrompt()
        return
    end
    
    local nextProfession = self.queue[1]["profession"]
    
    -- Synastria: Hardcoded exception - never try to switch to "Conversion" profession
    if nextProfession == "Conversion" then
        -- This shouldn't happen as we handle conversions above, but safety check
        if recipe and recipe.isVirtualConversion then
            Skillet:ShowStartCraftingPrompt()
        else
            -- Invalid conversion entry, remove it
            self:RemoveFromQueue(1)
            if table.getn(self.queue) > 0 then
                self:ProcessQueue()
            else
                AceEvent:TriggerEvent("SkilletStitch_Queue_Complete")
            end
        end
        return
    end
    
    local tradeskill = GetTradeSkillLine()
    
    -- Synastria: Check if we need to switch professions
    if tradeskill ~= nextProfession then
        -- Verify profession is valid and available
        if not nextProfession or nextProfession == "UNKNOWN" then
            -- Invalid profession in queue (debug output removed)
            self:RemoveFromQueue(1)
            if table.getn(self.queue) > 0 then
                self:ProcessQueue()  -- Try next item
            else
                AceEvent:TriggerEvent("SkilletStitch_Queue_Complete")
            end
            return
        end
        
        -- Check if we're already waiting for a profession switch
        if self.waitingForProfessionSwitch then
            return  -- Don't spam profession switches
        end
        
        -- Show prompt for user to switch profession
        self.waitingForProfessionSwitch = true
        
        -- Find the spell ID for this profession
        local spellId = self:FindProfessionSpellId(nextProfession)
        if spellId then
            Skillet:ShowProfessionSwitchPrompt(nextProfession, spellId, "queue")
        else
            -- Cannot find spell (debug output removed)
            self:RemoveFromQueue(1)
            self.waitingForProfessionSwitch = false
            if table.getn(self.queue) > 0 then
                self:ProcessQueue()
            else
                AceEvent:TriggerEvent("SkilletStitch_Queue_Complete")
            end
        end
        return
    end
    
    -- We're in the right profession, reset switch flag
    self.waitingForProfessionSwitch = false
    
    -- We're in the right profession, process the craft
    self.queuecasting = true
    self.craftAttemptTime = GetTime()  -- Synastria: Track when we attempted the craft
    
    -- Synastria: Store pre-craft inventory count for bulk detection
    local recipe = self.queue[1]["recipe"]
    local queueIndex = self.queue[1]["index"]
    local queueProfession = self.queue[1]["profession"]
    
    if recipe and recipe.link then
        local itemId = extract_item_id(recipe.link)
        
        if itemId then
            local bagCount = GetItemCount(itemId, true) or 0
            local bankCount = 0
            
            -- Synastria: Add resource bank count if available
            if GetCustomGameData then
                bankCount = GetCustomGameData(13, itemId) or 0
            end
            
            self.preCraftItemCount = bagCount + bankCount
            self.expectedCraftCount = self.queue[1]["numcasts"]
        end
    end
    
    -- Synastria: Track when we attempt the craft (for timeout detection)
    self.craftAttemptTime = GetTime()
    
    -- Synastria: Start repeating timer to check for craft failures
    -- Checks every 0.5 seconds if craft has timed out or failed
    if not AceEvent:IsEventScheduled("SkilletStitch_CraftMonitor") then
        AceEvent:ScheduleRepeatingEvent("SkilletStitch_CraftMonitor", function()
            self:CheckCraftStatus()
        end, 0.5, self)
    end
    
    -- Synastria: Call DoTradeSkill - failures caught by:
    -- 1. UI_ERROR_MESSAGE event (visible errors)
    -- 2. Repeating timer checking cast status (silent failures)
    -- 3. Inventory change detection (success verification)
    DoTradeSkill(self.queue[1]["index"], self.queue[1]["numcasts"])
end

-- Synastria: Find spell ID for a profession name
function SkilletStitch:FindProfessionSpellId(professionName)
    -- Synastria: Map profession names - Mining skill opens "Smelting" window
    local professionMapping = {
        ["Mining"] = "Smelting",  -- Mining profession opens Smelting tradeskill
        ["Smelting"] = "Smelting" -- Already correct
    }
    
    -- Use mapped name if available
    local mappedName = professionMapping[professionName] or professionName
    
    local professionSpellIds = {
        ["Runeforging"] = {53428},
        ["Alchemy"] = {51304, 28596, 11611, 3464, 3101, 2259},
        ["Blacksmithing"] = {51300, 29844, 9785, 3538, 3100, 2018},
        ["Enchanting"] = {51313, 28029, 13920, 7413, 7412, 7411},
        ["Engineering"] = {51306, 30350, 12656, 4038, 4037, 4036},
        ["Inscription"] = {45363, 45361, 45360, 45359, 45358, 45357},
        ["Jewelcrafting"] = {51311, 28897, 28895, 28894, 25230, 25229},
        ["Leatherworking"] = {51302, 32549, 10662, 3811, 3104, 2108},
        ["Tailoring"] = {51309, 26790, 12180, 3910, 3909, 3908},
        ["Cooking"] = {51296, 33359, 18260, 3413, 3102, 2550},
        ["First Aid"] = {45542, 27028, 10846, 7924, 3274, 3273},
        ["Smelting"] = {2656, 2655, 2654, 2653, 2652, 2575}  -- Mining/Smelting spell IDs
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
    ]]--

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
    
    -- After 2.0 seconds, check if we're actually casting (catastrophic failure fallback)
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
    
    -- Get current inventory count
    local recipe = self.queue[1] and self.queue[1]["recipe"]
    if not recipe or not recipe.link then
        return
    end
    
    local itemId = extract_item_id(recipe.link)
    if not itemId then
        return
    end
    
    local currentCount = GetItemCount(itemId, true) or 0
    
    -- Add resource bank count if available
    if GetCustomGameData then
        currentCount = currentCount + (GetCustomGameData(13, itemId) or 0)
    end
    
    -- If inventory increased, craft completed
    if currentCount > self.preCraftItemCount then
        -- Call completion processing directly
        self:ProcessCraftCompletion()
    end
end

-- Synastria: Separated completion processing called by BAG_UPDATE
function SkilletStitch:ProcessCraftCompletion()
    if not self.queuecasting then
        return
    end
    
    -- Cancel the craft monitoring timer
    if AceEvent:IsEventScheduled("SkilletStitch_CraftMonitor") then
        AceEvent:CancelScheduledEvent("SkilletStitch_CraftMonitor")
    end
    
    -- Clear timeout timer and craft attempt tracking
    self.craftAttemptTime = nil
    
    if not self.queue[1] then
        -- Synastria: Clear contents while keeping reference
        for k in pairs(self.queue) do
            self.queue[k] = nil
        end
        AceEvent:TriggerEvent("SkilletStitch_Queue_Complete")
        return
    end

        -- Synastria: Check for bulk completion by comparing inventory changes
        local actualCrafted = 1  -- Default to 1 if we can't detect
        if self.preCraftItemCount and self.expectedCraftCount then
            local recipe = self.queue[1]["recipe"]
            if recipe and recipe.link then
                local itemId = extract_item_id(recipe.link)
                if itemId then
                    local bagCount = GetItemCount(itemId, true) or 0
                    local bankCount = 0
                    if GetCustomGameData then
                        bankCount = GetCustomGameData(13, itemId) or 0
                    end
                    local postCraftItemCount = bagCount + bankCount
                    
                    local inventoryIncrease = postCraftItemCount - self.preCraftItemCount
                    
                    -- If we got more than 1 item, Synastria bulk crafted
                    if inventoryIncrease > 1 then
                        actualCrafted = inventoryIncrease
                    elseif inventoryIncrease == 1 then
                        actualCrafted = 1
                    end
                end
            end
            -- Clear tracking variables
            self.preCraftItemCount = nil
            self.expectedCraftCount = nil
        end

        -- Deduct the actual number of items crafted
        self.queue[1].numcasts = self.queue[1].numcasts - actualCrafted
        
        -- Synastria: Update ResourceTracker after crafting
        if Skillet and Skillet.UpdateResourceTrackerAfterCraft then
            local recipe = self.queue[1].recipe
            Skillet:UpdateResourceTrackerAfterCraft(recipe, actualCrafted)
        end

        if self.queue[1].numcasts < 1 then
            self:RemoveFromQueue(1)
            if table.getn(self.queue) > 0 then
                AceEvent:TriggerEvent("SkilletStitch_Queue_Continue", #self.queue)
                -- Synastria: Show crafting prompt for next item
                Skillet:ShowStartCraftingPrompt()
            else
                AceEvent:TriggerEvent("SkilletStitch_Queue_Complete")
            end
        else
            AceEvent:TriggerEvent("SkilletStitch_Queue_Continue", #self.queue)
            -- Synastria: Show crafting prompt for remaining items
            Skillet:ShowStartCraftingPrompt()
        end
        self.queuecasting = false
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
    if not self.queue or table.getn(self.queue) < 2 then
        return  -- No need to group if queue is empty or has only one item
    end
    
    -- Create profession-based groups
    local grouped = {}
    local professionOrder = {}
    
    for _, item in ipairs(self.queue) do
        local prof = item.profession
        if not grouped[prof] then
            grouped[prof] = {}
            table.insert(professionOrder, prof)
        end
        table.insert(grouped[prof], item)
    end
    
    -- Rebuild queue with items grouped by profession
    local newQueue = {}
    for _, prof in ipairs(professionOrder) do
        for _, item in ipairs(grouped[prof]) do
            table.insert(newQueue, item)
        end
    end
    
    self.queue = newQueue
    AceEvent:TriggerEvent("SkilletStitch_Queue_Update", #self.queue)
    DEFAULT_CHAT_FRAME:AddMessage("Queue grouped by profession to minimize switches")
end

--------------------
-- Internal Stuff --
--------------------
function SkilletStitch:GetIDFromLink(link)
    local id = string.match(link, "item:(%d+)")
    return tonumber(id)
end

function SkilletStitch:AddToQueue(index, times, profession)
    -- Synastria: Accept optional profession parameter for cross-profession queuing
    recenttrade = profession or GetTradeSkillLine()
    
    -- Synastria: REMOVED - This was clearing the queue when switching professions!
    -- For unified queue across all professions, we want to keep all items
    --[[
    if self.queue[1] and self.queue[1]["profession"] ~= recenttrade then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[QUEUE DEBUG] CLEARING QUEUE! First item profession (" .. (self.queue[1]["profession"] or "nil") .. ") != current (" .. (recenttrade or "nil") .. ")|r")
        self:ClearQueue()
    end
    ]]--
    
    if not times then
        times = 1
    end

    local found = false

    -- check to see if the item is already in the queue. If it is,
    -- then just increase the count
    for _,s in pairs(self.queue) do
        if s.profession == recenttrade and s.index == index then
            found = true
            s.numcasts = s.numcasts + times
            break
        end
    end

    if not found then
        local recipeData = nil
        
        -- Synastria: Map profession names for special cases (Mining -> Smelting)
        local professionMapping = {
            ["Mining"] = "Smelting",
            ["Smelting"] = "Smelting"
        }
        local mappedProfession = professionMapping[recenttrade] or recenttrade
        
        -- Synastria: Check the recipe info cache (populated when profession is scanned)
        -- Check both the original and mapped profession names
        if recipeInfoCache[mappedProfession] and recipeInfoCache[mappedProfession][index] then
            recipeData = recipeInfoCache[mappedProfession][index]
        elseif recipeInfoCache[recenttrade] and recipeInfoCache[recenttrade][index] then
            recipeData = recipeInfoCache[recenttrade][index]
        end
        
        -- If recipe data is a string or not a proper table, we need to fetch it
        if type(recipeData) ~= "table" or not recipeData.link then
            -- Only fetch from tradeskill window if we're in the correct profession
            local currentProfession = GetTradeSkillLine()
            
            if currentProfession == recenttrade then
                local name, _, _, _, _, _, _, _ = GetTradeSkillInfo(index)
                local link = GetTradeSkillItemLink(index)
                
                recipeData = {
                    name = name,
                    link = link
                }
                
                -- Synastria: Cache it for future use
                if not recipeInfoCache[recenttrade] then
                    recipeInfoCache[recenttrade] = {}
                end
                recipeInfoCache[recenttrade][index] = recipeData
            else
                -- Create minimal recipe data - will be updated when profession opens
                recipeData = {
                    name = "Unknown (" .. recenttrade .. " #" .. index .. ")",
                    link = nil,
                    needsRefresh = true  -- Flag to refresh when profession opens
                }
            end
        end
        
        table.insert(self.queue, {
            ["profession"] = recenttrade,
            ["index"] = index,
            ["numcasts"] = times,
            ["recipe"] = recipeData
        })
        
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00✓ QUEUED: " .. (recipeData.name or "Unknown") .. " x" .. times .. " [" .. recenttrade .. "]|r")
    end

    AceEvent:TriggerEvent("SkilletStitch_Queue_Add")
end

-- Returns the number of items (of the current index in the current tradeskill)
-- are queued
function SkilletStitch:GetNumQueuedItems(index)
    local count = 0

    for k,v in pairs(self.queue) do
        if v["index"] == index then
            count = count + tonumber(v["numcasts"])
        end
    end

    return count
end

function SkilletStitch:ScanTrade()
    local prof = GetTradeSkillLine()
    if prof == "UNKNOWN" then
        self.data[prof] = nil
    end
    if not self.data[prof] then
        self.data[prof] = {}
    end
    
    -- Synastria: Initialize recipe info cache for this profession
    if not recipeInfoCache[prof] then
        recipeInfoCache[prof] = {}
    end

    cache[prof] = nil
    local shred = false
    for i=1,GetNumTradeSkills() do
        local skillname, skilltype = GetTradeSkillInfo(i)
        if skilltype~="header" and skillname then
            local newstr = nil
            local link = GetTradeSkillItemLink(i)
            local reagents = {}  -- Synastria: Initialize reagents table
            
            if not link then
                shred = true
            else
                -- Synastria: Cache recipe name and link for cross-profession queuing
                recipeInfoCache[prof][i] = {
                    name = skillname,
                    link = link
                }
                
                local v1, _, v2, _, v3, _, v4 = GetTradeSkillTools(i)
                if v4 then
                    v1 = v1..", "..v2..", "..v3..", "..v4
                elseif v3 then
                    v1 = v1..", "..v2..", "..v3
                elseif v2 then
                    v1 = v1..", "..v2
                elseif v1 then
                    v1 = v1
                end
                local linkname = link:match("%|h%[([^%]]+)%]%|h")
                local squishedlink = squishlink(link)  -- Synastria: Keep original link, squish for encoding

                local minmade, maxmade = GetTradeSkillNumMade(i)

                if linkname == skillname then
                    newstr = ";"..squishedlink..";"..difficultyr[skilltype].. maxmade ..";"..(v1 or "")..";"
                else
                    newstr = skillname..";"..squishedlink..";"..difficultyr[skilltype].. maxmade .. ";"..(v1 or "")..";"
                end
                
                -- Synastria: Build reagents table with vendor info for new format
                for j=1,GetTradeSkillNumReagents(i) do
                    local reagentName, _, rcount, _ = GetTradeSkillReagentInfo(i,j)
                    local reagentLink = GetTradeSkillReagentItemLink(i,j)
                    if not reagentLink then
                        shred = true
                    else
                        -- Add to encoded string for backward compatibility
                        local squished = squishlink(reagentLink)
                        newstr = newstr..rcount..";"..squished..";"
                        
                        -- Synastria: Get vendor status from PeriodicTable for new format
                        local vendor = false
                        
                        -- Synastria: Use PeriodicTable for vendor detection
                        -- Check both the base PT vendor set and our Skillet extension
                        if PT then
                            vendor = (PT:ItemInSet(reagentLink,"Tradeskill.Mat.BySource.Vendor") or PT:ItemInSet(reagentLink,"Skillet.Vendor.Extended")) and true or false
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
            
            -- Synastria: Store both the encoded format (for backward compatibility) AND the new table format
            -- This happens regardless of whether link was nil or not (outside the if/else block)
            self.data[prof][i] = {
                name = skillname,
                link = link, -- Synastria: Store original unsquished link (may be nil if shred=true)
                encoded = newstr,  -- Keep encoded version for compatibility  
                reagents = reagents  -- Synastria: Store reagents with vendor info (may be empty if shred=true)
            }
        else
            self.data[prof][i] = nil
        end
    end
    if shred then
        for k,v in pairs(self.data[prof]) do
            self.data[prof][k] = nil
        end
        if not AceEvent:IsEventScheduled("SkilletStitch_AutoRescan") then
            AceEvent:ScheduleEvent("SkilletStitch_AutoRescan", self.SkilletStitch_AutoRescan, 3,self)
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
function SkilletStitch:SetAltCharacterItemLookupFunction(func)
    if func then
        alt_lookup_function = func
    end
end

----------------------
-- AceLibrary Stuff --
----------------------
local function activate(self, oldLib, oldDeactivate)
    if oldLib then
        self.data = oldLib.data
        self.datagatheraddons = oldLib.datagatheraddons
        self.queueaddons = oldLib.queueaddons
        self.queue = oldLib.queue
        self.queuecasting = oldLib.queuecasting
        self.hooks = oldLib.hooks
        self.queueenabled = oldLib.queueenabled
    end
    if not self.data then
        self.data = {}
    end
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

local function external(self, major, instance)
    if major == "AceEvent-2.0" then
        AceEvent = instance
        AceEvent:embed(self)
        self:UnregisterAllEvents()
        self:CancelAllScheduledEvents()
    end
end

AceLibrary:Register(SkilletStitch, MAJOR_VERSION, MINOR_VERSION, activate, nil, external)
SkilletStitch = nil

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
