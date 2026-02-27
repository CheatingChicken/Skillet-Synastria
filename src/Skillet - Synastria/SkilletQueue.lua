--[[

Skillet: A tradeskill window replacement.
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

local AceEvent = AceLibrary("AceEvent-2.0")

-- Synastria: Helper function to find which profession a recipe belongs to
local function find_profession_for_recipe(item)
    if not item or not item.index then
        return nil
    end

    -- Search through all professions by checking each one
    -- We'll use GetItemDataByIndex to verify the recipe exists in that profession
    local knownProfessions = {
        "Alchemy", "Blacksmithing", "Enchanting", "Engineering",
        "Jewelcrafting", "Leatherworking", "Tailoring", "Cooking",
        "First Aid", "Smelting", "Mining"
    }

    for _, profession in ipairs(knownProfessions) do
        local recipeData = Skillet.stitch:GetItemDataByIndex(profession, item.index)
        if recipeData and recipeData.link == item.link then
            return profession
        end
    end

    return nil
end

-- Adds the recipe to the queue of recipes to be processed. If the recipe
-- is already in the queue, then the count of items to be created is increased,
-- otherwise the recipe is added it the end
--
-- If there are item needs to make the recipe that are not currently in your
-- inventory, but you can craft them, then they are added to the queue before the
-- requested recipe.
---@param spellId number|string The spell ID to queue
---@param recipe Recipe The recipe object being queued
---@param count number The quantity to queue
---@param profession string|nil The profession context
---@param addToTop boolean|nil Whether to add to top of queue
---@param isPrimary boolean|nil True if user-queued, false if auto-generated subcraft
local function add_items_to_queue(spellId, recipe, count, profession, addToTop, isPrimary)
    assert(tonumber(spellId) and recipe and tonumber(count),
        "Usage: add_items_to_queue(spellId, recipe, count, profession, addToTop, isPrimary)")

    -- Synastria: Ensure queue is loaded before adding items
    if not Skillet.stitch.queue then
        ---@type string
        local tradeskill = profession or Skillet.currentTrade or ""
        Skillet:LoadQueue(Skillet.db.server.queues, tradeskill)
    end

    -- if we need mats that are not in the inventory, but are craftable, add
    -- the mats to the queue first

    if Skillet:IsDevMode() then
        Skillet:Print("Adding " .. count .. "x" .. recipe.link)
    end

    -- Log crafting tree calculation for this recipe
    local recipeDisplayName = recipe.name or "Unknown"
    Skillet:DebugLog(string.format("[CRAFTING_TREE] %-40s x%d", recipeDisplayName, count), "|cFF00FF00")

    if Skillet.db.profile.queue_craftable_reagents then
        -- Synastria: SIMPLIFIED ARCHITECTURE - Take clean snapshot, calculate needs, queue individually
        -- 1. Snapshot what queue currently consumes (no complex exclusions)
        -- 2. Calculate what THIS craft needs
        -- 3. Queue each subreagent individually
        -- 4. Let AddToQueue handle the merging

        ---@type Reagent[]
        local reagents = recipe.reagents or {}

        -- Now process each reagent independently
        for i = 1, #reagents, 1 do
            ---@type Reagent
            local reagent = reagents[i]

            if not reagent then
                break
            end

            -- What we need for THIS craft (just the delta being added)
            local needed = (reagent.needed * count)

            -- What we have in inventory + resource bank
            local have = GetItemCount(reagent.link, true)
            local itemId = tonumber(string.match(reagent.link, "item:(%d+)"))
            if GetCustomGameData and itemId then
                have = have + (GetCustomGameData(13, itemId) or 0)
            end

            -- What the queue will PRODUCE (items that will be crafted)
            ---@type number
            local queueProduction = 0
            if itemId and Skillet.GetQueuedItemProduction then
                queueProduction = Skillet:GetQueuedItemProduction(itemId)
            end

            -- What the queue will CONSUME (items already allocated to other recipes)
            ---@type number
            local queueConsumption = 0
            if itemId and Skillet.GetQueuedReagentConsumption then
                queueConsumption = Skillet:GetQueuedReagentConsumption(itemId)
            end

            -- Net available from queue = production - consumption
            local queueNet = queueProduction - queueConsumption

            -- Calculate shortage: need - have - netQueueAvailable
            local shortage = math.max(0, needed - have - queueNet)

            -- DETAILED DEBUG LOGGING
            local itemName = reagent.name or ("Item#" .. (itemId or "?"))
            if Skillet:IsDevMode() then
                DEFAULT_CHAT_FRAME:AddMessage(string.format(
                    "|cFFFFAA00[SHORTAGE CALC] %s:|r |cFFFFFFFFneed=%d, have=%d, qProd=%d, qCons=%d, qNet=%d, shortage=%d|r",
                    itemName, needed, have, queueProduction, queueConsumption, queueNet, shortage))
            end

            Skillet:DebugLog(string.format(
                "[Queue Check] %s: have %d, queueProd %d, queueCons %d, queueNet %d, need %d, shortage %d",
                itemName, have, queueProduction, queueConsumption, queueNet, needed, shortage))

            if shortage > 0 then
                -- Synastria: We have a shortage - check if we can satisfy through conversion
                -- BUT: Don't queue conversions for ingredients when we're currently
                -- queueing a conversion itself (prevents infinite loops)
                local isQueuingConversion = recipe.isVirtualConversion or false
                if not isQueuingConversion then
                    ---@type boolean
                    local conversionQueued = Skillet:QueueConversionsIfNeeded(reagent, shortage)
                end

                -- Synastria: Search all professions (with profession priority in GetItemDataByName)
                -- This ensures smelting recipes are preferred over transmutes
                local item = Skillet.stitch:GetItemDataByName(reagent.name)
                local subreagentQueued = "NO"
                if item then
                    subreagentQueued = "YES"
                end

                -- Log this reagent's shortage and subcraft decision
                Skillet:DebugLog(string.format("  %-35s need=%2d shortage=%2d subcraft=%s", itemName, needed, shortage,
                    subreagentQueued))

                -- Compare item IDs instead of full links (links may have different color codes)
                ---@type Recipe|nil
                local item_check = item
                if item_check then
                    local itemId = tonumber((item_check.link or ""):match("item:(%d+)"))
                    local reagentId = tonumber((reagent.link or ""):match("item:(%d+)"))

                    if itemId and reagentId and itemId == reagentId then
                        -- Synastria: Additional safety check - never queue transmutes with cooldowns as subcrafts
                        local isTransmute = item_check.name and item_check.name:match("^Transmute:")
                        local shouldSkip = false

                        -- Hardcoded exception: Transmute: Titanium has no cooldown
                        local isTransmuteTitanium = item_check.name and item_check.name:match("^Transmute: Titanium")

                        if isTransmute and not isTransmuteTitanium then
                            -- Check if this transmute has a cooldown
                            local itemProfession = find_profession_for_recipe(item_check)
                            if itemProfession and item_check.index then
                                local currentTrade = GetTradeSkillLine()
                                if currentTrade == itemProfession then
                                    -- We're in the right profession, check cooldown
                                    local cooldown = GetTradeSkillCooldown(item_check.index)
                                    if cooldown and cooldown > 0 then
                                        shouldSkip = true
                                        if Skillet:IsDevMode() then
                                            Skillet:Print("Skipping transmute with cooldown as subcraft: " ..
                                                item_check.name)
                                        end
                                    end
                                else
                                    -- Conservative: assume transmutes have cooldowns if we can't check
                                    shouldSkip = true
                                    if Skillet:IsDevMode() then
                                        Skillet:Print("Skipping transmute (can't verify cooldown): " .. item_check.name)
                                    end
                                end
                            end
                        end

                        if shouldSkip then
                            -- Skip this recipe, don't queue it
                        else
                            -- Verify item has the necessary structure
                            if not item_check.index then
                                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[QUEUE ERROR] Item missing index: " ..
                                    reagent.name .. "|r")
                            elseif type(item_check) ~= "table" then
                                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[QUEUE ERROR] Item is not a table: " ..
                                    reagent.name .. "|r")
                            else
                                -- we can craft this
                                -- the extra check for an exact name match is because the
                                -- Stitch search will fall back on a wild card across all
                                -- skills if an exact match is not found

                                -- Try and guard against infinite recursion here. This will
                                -- not prevent the error, but will help detect it and generate
                                -- more meaningful error
                                local recipeId = tonumber((recipe.link or ""):match("item:(%d+)"))
                                if recipeId then
                                    assert(recipeId ~= itemId, "Recursive loop detected: Recipe item ID " ..
                                        recipeId .. " has reagent with same ID " .. itemId)
                                end

                                -- Synastria: Find which profession this recipe belongs to
                                local itemProfession = find_profession_for_recipe(item_check)

                                -- Synastria: Queue the subreagent individually
                                -- CRITICAL: Subreagents MUST be added to the TOP (before parent recipe)
                                -- This ensures correct crafting order (dependencies first)
                                -- ALSO: Mark as NOT primary (auto-generated subcraft)
                                -- NOTE: 'shortage' is the amount we need to queue
                                add_items_to_queue(item_check.spellId, item_check, shortage, itemProfession,
                                    true, false) -- addToTop=true, isPrimary=false
                            end
                        end
                    end
                end
            end
        end
    end

    -- Synastria: Pass recipe.link so AddToQueue can use Custom API for cross-profession lookups
    -- Also pass isPrimary flag to distinguish user-queued vs auto-generated subcrafts
    local numericSpellId = tonumber(spellId) or 0
    ---@type string
    local finalLink = recipe.link or ""
    ---@diagnostic disable-next-line: param-type-mismatch
    Skillet.stitch:AddToQueue(numericSpellId, count, profession, addToTop, finalLink, isPrimary)

    -- XXX: This is a bit hacky, try to think of something smarter
    Skillet:SaveQueue(Skillet.db.server.queues, Skillet.currentTrade)
end

-- Save the current queue into the provided database
---@param db SkilletAllQueues
---@param tradeskill string
---@return nil
function Skillet:SaveQueue(db, tradeskill)
    local playerName = GetSafePlayerName()
    ---@type table<string, table>
    local playerData = db[playerName] or {}
    if not db[playerName] then
        db[playerName] = playerData
    end

    -- Synastria: Use unified queue across all professions
    if not playerData["AllProfessions"] then
        playerData["AllProfessions"] = {}
    end

    if self:IsDevMode() then
        DEFAULT_CHAT_FRAME:AddMessage(string.format(
            "|cFF00FFFF[SaveQueue] ===== SAVE STARTING ===== Queue has %d items|r",
            #self.stitch.queue))
    end

    -- Synastria: SIMPLIFIED APPROACH - Don't persist conversions at all!
    -- Conversions are ephemeral dependencies that should be regenerated on load
    -- Only save actual craft recipes with spellIds
    local cleanQueue = {}

    ---@type integer
    local skippedConversions = 0
    for i, entry in ipairs(self.stitch.queue) do
        if entry.profession == "Conversion" then
            -- Skip conversions - they'll be regenerated on load
            ---@type integer
            local newCount = skippedConversions + 1
            skippedConversions = newCount
            if self:IsDevMode() then
                DEFAULT_CHAT_FRAME:AddMessage(string.format(
                    "|cFFFFAA00[SaveQueue] Skipping conversion #%d: %s (will regenerate on load)|r",
                    skippedConversions, tostring(entry.name)))
            end
        else
            -- Normal recipe - build clean entry with ONLY primitive fields
            ---@type table
            local cleanEntry = {
                profession = entry.profession,
                index = entry.index or 0,
                numcasts = entry.numcasts or 1,
                name = entry.name,
                link = entry.link,
                spellId = entry.spellId,
                count = entry.count or 0,
                -- Any other primitive fields that exist
                recipeType = entry.recipeType or "",
                isPrimary = entry.isPrimary, -- Synastria: Preserve primary/subcraft distinction
                -- DO NOT INCLUDE: recipe (will be hydrated on load)
            }
            table.insert(cleanQueue, cleanEntry)
        end
    end

    if self:IsDevMode() then
        DEFAULT_CHAT_FRAME:AddMessage(string.format(
            "|cFF00FFFF[SaveQueue] Built clean table: %d recipes (skipped %d conversions)|r",
            #cleanQueue, skippedConversions))
    end

    -- Save the CLEAN table (conversions excluded)
    playerData["AllProfessions"] = cleanQueue

    if self:IsDevMode() then
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF00FF00[SaveQueue] ===== SAVE COMPLETE ===== Wrote %d recipes|r",
            #cleanQueue))
    end
end

-- Loads the queue for the provided tradeskill name from the database
---@param db SkilletAllQueues
---@param tradeskill string
---@return nil
function Skillet:LoadQueue(db, tradeskill)
    local playerName = GetSafePlayerName()
    ---@type table<string, table>
    local playerData = db[playerName] or {}
    if not db[playerName] then
        db[playerName] = playerData
    end

    -- Synastria: Use unified queue across all professions
    -- Always use the same table reference from the database
    if not playerData["AllProfessions"] then
        playerData["AllProfessions"] = {}
    end

    -- Always point to the database table to maintain a single unified queue
    self.stitch.queue = playerData["AllProfessions"]

    if self:IsDevMode() then
        DEFAULT_CHAT_FRAME:AddMessage(string.format(
            "|cFF00FFFF[LoadQueue] ===== LOAD STARTING ===== DB has %d recipes|r",
            #self.stitch.queue))

        -- Synastria: Log what we're loading (only recipes, conversions not saved)
        for i, entry in ipairs(self.stitch.queue) do
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFCCCCCC[LoadQueue RAW] #%d: prof=%s, name=%s, spellId=%s|r",
                i, tostring(entry.profession), tostring(entry.name), tostring(entry.spellId)))
        end
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF00FF00[LoadQueue] Found %d recipes in DB|r", #self.stitch.queue))
    end

    -- Synastria: Hydrate recipe objects from Custom API (they don't serialize to SavedVariables)
    -- This rebuilds the recipe data needed for consumption calculations
    if self:IsDevMode() then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF00FF[LoadQueue] ===== HYDRATION STARTING =====|r")
    end
    if Custom_GetProfessionRecipeInfo and Custom_GetProfessionRecipeReagents then
        if self:IsDevMode() then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[LoadQueue] Custom API available, proceeding with hydration...|r")
        end
        local hydratedCount = 0
        for i, entry in ipairs(self.stitch.queue) do
            -- Only hydrate normal recipes (conversions aren't saved)
            if entry.spellId and not entry.recipe then
                -- Build a minimal recipe object from API data
                local skillId, spellName, craftedItemId, craftedItemCount = Custom_GetProfessionRecipeInfo(entry.spellId)
                local reagentTable = Custom_GetProfessionRecipeReagents(entry.spellId)

                if spellName and reagentTable then
                    -- Convert reagent table { [itemId] = count } to reagent array for compatibility
                    ---@type table
                    local reagentArray = {}
                    for itemId, count in pairs(reagentTable) do
                        local itemName, itemLink = GetItemInfo(itemId)
                        table.insert(reagentArray, {
                            link = itemLink or ("item:" .. itemId),
                            name = itemName or ("Item #" .. itemId),
                            needed = count
                        })
                    end

                    -- Create hydrated recipe object
                    ---@type Recipe
                    local hydratedRecipe = {
                        spellId = entry.spellId,
                        name = spellName,
                        link = entry.link or "",
                        reagents = reagentArray,
                        nummade = craftedItemCount or 1
                    }

                    entry.recipe = hydratedRecipe
                    ---@diagnostic disable-next-line: assign-type-mismatch
                    hydratedCount = hydratedCount + 1

                    -- Update name/link if missing (backward compatibility with old queue entries)
                    if not entry.name or entry.name == "Unknown Recipe" then
                        entry.name = spellName
                    end
                    if not entry.link and craftedItemId and craftedItemId > 0 then
                        entry.link = "item:" .. craftedItemId
                    end
                end
            end
        end
        if self:IsDevMode() then
            DEFAULT_CHAT_FRAME:AddMessage(string.format(
                "|cFF00FF00[LoadQueue] ===== HYDRATION COMPLETE ===== Hydrated %d recipes|r", hydratedCount))
        end
    else
        if self:IsDevMode() then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[LoadQueue] Custom API NOT available - skipping hydration|r")
        end
    end

    -- Synastria: CRITICAL - Regenerate conversions dynamically for all loaded recipes
    -- IMPORTANT: Collect all unique reagents FIRST, then queue conversions
    -- If we call QueueConversionsIfNeeded per-recipe, it double-counts because recipes are already queued!
    if self:IsDevMode() then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF00FF[LoadQueue] ===== REGENERATING CONVERSIONS =====|r")
    end
    ---@type integer
    local conversionsAdded = 0

    -- Import Skillet reference
    local Skillet = _G.Skillet
    if Skillet and Skillet.QueueConversionsIfNeeded and Skillet.GetItemIDFromLink then
        -- Step 1: Build a set of items being crafted (to exclude from conversion checks)
        ---@type table<number, boolean>
        local itemsBeingCrafted = {}
        for _, entry in ipairs(self.stitch.queue) do
            if entry.spellId and entry.link then
                local itemId = Skillet:GetItemIDFromLink(entry.link)
                if itemId then
                    itemsBeingCrafted[itemId] = true
                end
            end
        end

        -- Step 2: Collect total needs per unique reagent across ALL queued recipes
        ---@class ReagentTotal
        ---@field reagent Reagent
        ---@field totalNeeded number

        ---@type table<number, ReagentTotal>
        local reagentTotals = {}

        for i, entry in ipairs(self.stitch.queue) do
            if entry.recipe and entry.recipe.reagents then
                if self:IsDevMode() then
                    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFAAAAAA[LoadQueue] Scanning recipe #%d: %s|r", i,
                        tostring(entry.name)))
                end
                for _, reagent in ipairs(entry.recipe.reagents) do
                    ---@cast reagent Reagent
                    if reagent and reagent.link and reagent.needed then
                        local itemId = Skillet:GetItemIDFromLink(reagent.link)
                        if itemId then
                            local totalNeeded = reagent.needed * (entry.numcasts or 1)
                            if not reagentTotals[itemId] then
                                reagentTotals[itemId] = {
                                    reagent = reagent,
                                    totalNeeded = 0
                                }
                            end
                            local reagentData = reagentTotals[itemId]
                            reagentData.totalNeeded = reagentData.totalNeeded + totalNeeded
                            if self:IsDevMode() then
                                DEFAULT_CHAT_FRAME:AddMessage(string.format(
                                    "|cFFCCCCCC[LoadQueue]   Reagent %s: +%d (total now: %d)|r",
                                    tostring(reagent.name or itemId), totalNeeded, reagentData.totalNeeded))
                            end
                        end
                    end
                end
            end
        end

        -- Step 3: Queue conversions ONLY for leaf reagents (not being crafted)
        local beforeCount = #self.stitch.queue
        for itemId, data in pairs(reagentTotals) do
            -- Skip if this reagent is being crafted in the queue
            if itemsBeingCrafted[itemId] then
                if self:IsDevMode() then
                    DEFAULT_CHAT_FRAME:AddMessage(string.format(
                        "|cFFFFAA00[LoadQueue] Skipping %s - being crafted in queue|r",
                        tostring(data.reagent.name or itemId)))
                end
            else
                if self:IsDevMode() then
                    DEFAULT_CHAT_FRAME:AddMessage(string.format(
                        "|cFF00FFFF[LoadQueue] Checking conversions for %s (need %d total)|r",
                        tostring(data.reagent.name or itemId), data.totalNeeded))
                end
                -- Pass true to skip queued consumption tracking (recipes already in queue!)
                Skillet:QueueConversionsIfNeeded(data.reagent, data.totalNeeded, true)
            end
        end
        local afterCount = #self.stitch.queue
        conversionsAdded = afterCount - beforeCount

        if self:IsDevMode() then
            DEFAULT_CHAT_FRAME:AddMessage(string.format(
                "|cFF00FF00[LoadQueue] ===== REGENERATION COMPLETE ===== Added %d conversions|r", conversionsAdded))
        end
    else
        if self:IsDevMode() then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[LoadQueue] ERROR: Skillet.QueueConversionsIfNeeded not found!|r")
        end
    end

    AceEvent:TriggerEvent("SkilletStitch_Queue_Add")
end

-- Queue the max number of craftable items for the currently selected skill
---@return nil
function Skillet:QueueAllItems()
    if self.currentTrade and self.selectedSkill then
        ---@type Recipe|nil
        local s = self.stitch:GetItemDataByIndex(self.currentTrade, self.selectedSkill)
        if s then
            local factor = s.nummade or 1
            local count = math.floor(s.numcraftable / factor) - self.stitch:GetNumQueuedItems(self.selectedSkill)
            if count > 0 then
                add_items_to_queue(s.spellId, s, count, self.currentTrade, false, true)
            end
            -- queued all that could be created, reset the create count
            -- back down to 0
            self:UpdateNumItemsSlider(0, false)
        end
    end
end

-- Queue and create the max number of craftable items for the currently selected skill
---@return nil
function Skillet:CreateAllItems()
    if self.currentTrade and self.selectedSkill then
        local s = self.stitch:GetItemDataByIndex(self.currentTrade, self.selectedSkill);
        if s then
            local factor = s.nummade or 1
            local count = math.floor(s.numcraftable / factor) - self.stitch:GetNumQueuedItems(self.selectedSkill)
            if count > 0 then
                -- Synastria: Add to TOP of queue (true parameter) so we can craft immediately
                add_items_to_queue(s.spellId, s, count, nil, true, true)
                self:ProcessQueue()
            end
            -- created all that could be created, reset the create count
            -- back down to 0
            self:UpdateNumItemsSlider(0, false)
        end
    end
end

-- Adds the currently selected number of items to the queue (without starting the queue)
---@return nil
function Skillet:QueueItems()
    self.numItemsToCraft = SkilletItemCountInputBox:GetNumber();

    if self.numItemsToCraft > 0 then
        if self.currentTrade and self.selectedSkill then
            local s = self.stitch:GetItemDataByIndex(self.currentTrade, self.selectedSkill);
            if s then
                -- Add to queue (not to top, and don't process)
                add_items_to_queue(s.spellId, s, self.numItemsToCraft, self.currentTrade, false, true)
            end
        end
    end
end

-- Adds the currently selected number of items to the queue and then starts the queue
---@return nil
function Skillet:CreateItems()
    self.numItemsToCraft = SkilletItemCountInputBox:GetNumber();

    if self.numItemsToCraft > 0 then
        if self.currentTrade and self.selectedSkill then
            local s = self.stitch:GetItemDataByIndex(self.currentTrade, self.selectedSkill);
            if s then
                -- Synastria: Add to TOP of queue (true parameter) so we can craft immediately
                add_items_to_queue(s.spellId, s, self.numItemsToCraft, nil, true, true)
                self:ProcessQueue();
            end
        end
    end
end

-- Starts Processing any items in the queue
---@return nil
function Skillet:ProcessQueue()
    local queue = self.stitch:GetQueueInfo()
    if not queue then
        return
    end

    self.stitch:ProcessQueue()
end

-- Clears the current queue, this will not cancel an
-- items currently being crafted.
---@return nil
function Skillet:EmptyQueue()
    self.stitch:ClearQueue()
    self:SaveQueue(self.db.server.queues, self.currentTrade)

    -- CRITICAL: Invalidate queue consumption cache so it's rebuilt on next calculation
    -- Without this, the cache shows stale values from before the clear
    if self.CraftCalc and self.CraftCalc.ClearCache then
        self.CraftCalc:ClearCache()
    end
end

-- Synastria: Optimize queue by recalculating subcrafts for all primary items
-- This clears all auto-generated subcrafts and regenerates them based on current inventory/queue state
---@return nil
function Skillet:OptimizeQueueOrder()
    local queue = self.stitch.queue
    if not queue or #queue == 0 then
        if self:IsDevMode() then
            self:Print("Queue is empty - nothing to optimize")
        end
        return
    end

    if self:IsDevMode() then
        self:Print("|cFF00FF00Optimizing queue order...|r")
    end

    -- OPTIMIZATION: Suppress UI updates during bulk operations
    local startTime = GetTime()
    self.suppressQueueUpdates = true

    -- TIMING: Step 1 - Extract primary items
    local t1_start = GetTime()
    ---@type QueueEntry[]
    local primaryItems = {}
    for i = 1, #queue do
        local entry = queue[i]
        if entry.isPrimary then
            table.insert(primaryItems, entry)
            if self:IsDevMode() then
                DEFAULT_CHAT_FRAME:AddMessage(string.format(
                    "|cFF00FFFF[Optimize] Primary: %s x%d|r",
                    entry.name or "Unknown", entry.numcasts or 1))
            end
        end
    end
    local t1_elapsed = GetTime() - t1_start

    if #primaryItems == 0 then
        self.suppressQueueUpdates = false
        if self:IsDevMode() then
            self:Print("|cFFFFAA00No primary items found - queue may contain only auto-generated subcrafts|r")
        end
        return
    end

    if self:IsDevMode() then
        self:Print(string.format("|cFF00FFFF Found %d primary items, clearing subcrafts...|r", #primaryItems))
    end

    -- TIMING: Step 2 - Clear queue and cache
    local t2_start = GetTime()
    self.stitch:ClearQueue()

    -- Invalidate cache
    if self.CraftCalc and self.CraftCalc.ClearCache then
        self.CraftCalc:ClearCache()
    end
    local t2_elapsed = GetTime() - t2_start

    -- TIMING: Step 3 - Resolve crafting tree and rebuild queue
    local t3_start = GetTime()

    -- PHASE 3A: Calculate gross requirements for all primaries
    ---@type table<number, number> itemId -> total quantity needed for all primaries
    local grossRequirements = {}
    ---@type table<number, {spellId: number, recipe: Recipe, count: number, profession: string}> Primary crafts (to add last)
    local primaryCrafts = {}

    for i = 1, #primaryItems do
        local entry = primaryItems[i]
        local recipe = entry.recipe

        -- Reconstruct recipe if needed
        if not recipe or not recipe.reagents then
            recipe = {
                spellId = entry.spellId,
                name = entry.name or "Unknown",
                link = entry.link or "",
                reagents = {},
                nummade = 1
            }

            if entry.spellId and Custom_GetProfessionRecipeReagents then
                local reagentsTable = Custom_GetProfessionRecipeReagents(entry.spellId)
                if reagentsTable then
                    recipe.reagents = {}
                    for itemId, count in pairs(reagentsTable) do
                        local itemName, itemLink = GetItemInfo(itemId)
                        table.insert(recipe.reagents, {
                            link = itemLink or ("item:" .. itemId),
                            name = itemName or ("Item #" .. itemId),
                            needed = count
                        })
                    end
                end
            end

            if entry.spellId and Custom_GetProfessionRecipeInfo then
                local _, _, _, craftedItemCount = Custom_GetProfessionRecipeInfo(entry.spellId)
                if craftedItemCount and craftedItemCount > 0 then
                    recipe.nummade = craftedItemCount
                end
            end
        end

        -- Store primary craft (add to queue later)
        table.insert(primaryCrafts, {
            spellId = entry.spellId,
            recipe = recipe,
            count = entry.numcasts,
            profession = entry.profession
        })

        -- Sum up reagent requirements
        for _, reagent in ipairs(recipe.reagents or {}) do
            local itemId = tonumber(string.match(reagent.link, "item:(%d+)"))
            if itemId then
                local needed = reagent.needed * entry.numcasts
                grossRequirements[itemId] = (grossRequirements[itemId] or 0) + needed
            end
        end
    end

    -- PHASE 3B: Plan subcrafts (what we need to craft to fulfill requirements)
    ---@type table<number, {spellId: number, count: number, recipe: Recipe}> itemId -> craft plan
    local plannedCrafts = {}
    ---@type table<number, number> itemId -> total we will produce from planned crafts
    local plannedProduction = {}

    local function planSubcrafts(depth)
        if depth > 10 then return end -- Prevent infinite recursion

        local addedPlans = false

        for itemId, totalNeeded in pairs(grossRequirements) do
            -- Skip if already planned
            if not plannedCrafts[itemId] then
                -- Check current inventory
                local have = GetItemCount("item:" .. itemId, true)
                if GetCustomGameData then
                    have = have + (GetCustomGameData(13, itemId) or 0)
                end

                -- Add planned production (items we'll craft in this optimization)
                have = have + (plannedProduction[itemId] or 0)

                local shortage = totalNeeded - have

                if shortage > 0 then
                    -- Check if this item is craftable
                    ---@type Recipe|nil
                    local craftableRecipe = nil
                    if Custom_GetProfessionRecipeFromCraftedItem then
                        local spellId = Custom_GetProfessionRecipeFromCraftedItem(itemId)
                        if spellId and Custom_GetProfessionRecipeInfo then
                            local skillId, name, craftedItemId, craftedItemCount = Custom_GetProfessionRecipeInfo(
                                spellId)
                            if craftedItemId == itemId then
                                -- Build recipe
                                craftableRecipe = {
                                    spellId = spellId,
                                    name = name,
                                    link = "item:" .. itemId,
                                    reagents = {},
                                    nummade = craftedItemCount or 1
                                }

                                -- Get reagents
                                local reagentTable = Custom_GetProfessionRecipeReagents(spellId)
                                if reagentTable then
                                    for reagentId, reagentCount in pairs(reagentTable) do
                                        local rName, rLink = GetItemInfo(reagentId)
                                        table.insert(craftableRecipe.reagents, {
                                            link = rLink or ("item:" .. reagentId),
                                            name = rName or ("Item #" .. reagentId),
                                            needed = reagentCount
                                        })
                                    end
                                end
                            end
                        end
                    end

                    if craftableRecipe then
                        local craftsNeeded = math.ceil(shortage / craftableRecipe.nummade)

                        -- Plan this craft
                        plannedCrafts[itemId] = {
                            spellId = craftableRecipe.spellId,
                            count = craftsNeeded,
                            recipe = craftableRecipe
                        }

                        -- Track production (what this will make)
                        plannedProduction[itemId] = craftsNeeded * craftableRecipe.nummade

                        -- Add reagent requirements to gross total
                        for _, reagent in ipairs(craftableRecipe.reagents) do
                            ---@type Reagent
                            reagent = reagent
                            local reagentId = tonumber(string.match(reagent.link, "item:(%d+)"))
                            if reagentId then
                                local reagentNeeded = reagent.needed * craftsNeeded
                                grossRequirements[reagentId] = (grossRequirements[reagentId] or 0) + reagentNeeded
                            end
                        end

                        addedPlans = true
                    end
                end
            end
        end

        -- Recurse if we added new plans
        if addedPlans then
            planSubcrafts(depth + 1)
        end
    end

    planSubcrafts(0)

    -- PHASE 3C: Add planned subcrafts to queue (dependencies first)
    for itemId, plan in pairs(plannedCrafts) do
        ---@diagnostic disable-next-line: param-type-mismatch
        self.stitch:AddToQueue(plan.spellId, plan.count, "Unknown", false, plan.recipe.link, false)
    end

    -- PHASE 3D: Add primary crafts to queue (at end, marked as primary)
    for i = 1, #primaryCrafts do
        local craft = primaryCrafts[i]
        ---@diagnostic disable-next-line: param-type-mismatch
        self.stitch:AddToQueue(craft.spellId, craft.count, craft.profession, false, craft.recipe.link, true)
    end

    local t3_elapsed = GetTime() - t3_start

    -- TIMING: Step 4 - Save and update UI
    local t4_start = GetTime()
    self.suppressQueueUpdates = false
    self:SaveQueue(self.db.server.queues, self.currentTrade)
    self:UpdateQueueWindow()

    -- Synastria: Update ResourceTracker with final optimized queue
    if self.AutoExportQueueToResourceTracker then
        self:AutoExportQueueToResourceTracker()
    end

    local t4_elapsed = GetTime() - t4_start

    local totalElapsed = GetTime() - startTime

    -- Output timing report in dev mode
    if self:IsDevMode() then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00========== OPTIMIZATION TIMING REPORT ==========|r")
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFFAA00Step 1 (Extract Primary):|r %.3fs (%.1f%%)",
            t1_elapsed, (t1_elapsed / totalElapsed) * 100))
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFFAA00Step 2 (Clear Queue):|r %.3fs (%.1f%%)",
            t2_elapsed, (t2_elapsed / totalElapsed) * 100))
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFFAA00Step 3 (Resolve Crafting Tree):|r %.3fs (%.1f%%)",
            t3_elapsed, (t3_elapsed / totalElapsed) * 100))
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFFAA00Step 4 (Save/UI):|r %.3fs (%.1f%%)",
            t4_elapsed, (t4_elapsed / totalElapsed) * 100))
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF00FF00TOTAL TIME:|r %.3fs", totalElapsed))
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00================================================|r")
    end

    if self:IsDevMode() then
        self:Print(string.format(
            "|cFF00FF00Queue optimized in %.2fs! All subcrafts recalculated with current inventory.|r",
            totalElapsed))
    end
end

-- Removes an item from the queue
---@param id number
---@return nil
function Skillet:RemoveQueuedItem(id)
    local queue = self.stitch:GetQueueInfo();
    if not queue then
        -- this should never happen, log an error?
        return
    end

    if id == 1 then
        self.stitch:CancelCast()
    end

    self.stitch:RemoveFromQueue(id)
    self:SaveQueue(self.db.server.queues, self.currentTrade)

    -- CRITICAL: Invalidate queue consumption cache when removing items
    if self.CraftCalc and self.CraftCalc.ClearCache then
        self.CraftCalc:ClearCache()
    end

    self:UpdateQueueWindow()
end

-- Returns a table {playername, queues} containing all queued
-- items
---@return SkilletAllQueues
function Skillet:GetAllQueues()
    if not self.db.server.queues then
        return {}
    end

    return self.db.server.queues
end

-- Returns the list of queues for the specified player
---@param player string
---@return SkilletPlayerQueues
function Skillet:GetQueues(player)
    assert(tostring(player), "Usage: GetQueues('player_name')")

    if not self.db.server.queues then
        return {}
    end

    if not self.db.server.queues[player] then
        return {}
    end

    return self.db.server.queues[player]
end

-- Returns the list of queues for the current player
---@return SkilletPlayerQueues
function Skillet:GetPlayerQueues()
    local playerName = GetSafePlayerName()
    return self:GetQueues(playerName)
end

-- Updates the list with the required number of items
-- of "link". If "name" is already in the list, the count in updated,
-- otherwise it is appended to the end of the list.
---@param list table<integer, SkilletQueuedItem> The list to update
---@param player string The player name
---@param name string The item name
---@param link string The item link
---@param needed number The count needed
---@return nil
local function update_queued_list(list, player, name, link, needed)
    for i = 1, #list, 1 do
        if list[i]["name"] == name then
            ---@type number
            local currentCount = list[i]["count"] or 0
            list[i]["count"] = currentCount + needed
            if list[i].player and not string.find(list[i].player, player) then
                list[i].player = list[i].player .. ", " .. player
            end
            return
        end
    end

    table.insert(list, {
        ["name"]   = name,
        ["link"]   = link,
        ["count"]  = needed,
        ["player"] = player,
    })
end

--
-- Checks the queued items and calculates how many of each reagent is required.
-- The table of reagents and counts is returned. The will examine the queues for
-- all professions, not just the currently selected on.
--
-- If the player name is not provided, then the queues for all players are checked.
--
-- The returned table contains:
--     name : name of the item
--     link : link for the item
--     count : how many of this item is needed
--     player : comma separated list of players that need the item for their queues
--
---@param playername string|nil Optional player name filter
---@return SkilletQueuedItem[]|nil
function Skillet:GetReagentsForQueuedRecipes(playername)
    local list = {}

    ---@type table<string, table>
    local allQueues = self:GetAllQueues()
    for player, playerqueues in pairs(allQueues) do
        -- check the unified queue
        if not playername or playername == player then
            -- Synastria: Use unified "AllProfessions" queue
            ---@type table|nil
            local queue = playerqueues["AllProfessions"]
            if queue and #queue > 0 then
                for i = 1, #queue, 1 do
                    ---@type SkilletQueueItem
                    local queueItem = queue[i]
                    local spellId = queueItem.spellId
                    ---@type number
                    local count = queueItem.numcasts

                    -- Synastria: Use Custom API to get reagents
                    -- Returns table mapping [itemId] = count
                    if spellId and Custom_GetProfessionRecipeReagents then
                        local reagents = Custom_GetProfessionRecipeReagents(spellId)
                        if reagents and type(reagents) == "table" then
                            -- Iterate using pairs() since it's a dictionary, not array
                            for itemId, reagentCount in pairs(reagents) do
                                ---@type number
                                local needed = count * reagentCount
                                if needed > 0 then
                                    -- Get item info from itemId
                                    local itemName, itemLink = GetItemInfo(itemId)
                                    if itemName and itemLink then
                                        update_queued_list(list, player, itemName, itemLink, needed)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return list
end
