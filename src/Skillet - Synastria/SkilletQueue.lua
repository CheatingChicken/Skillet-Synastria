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

local QUEUE_DEBUG = false

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
local function add_items_to_queue(spellId, recipe, count, profession, addToTop)
    assert(tonumber(spellId) and recipe and tonumber(count),
        "Usage: add_items_to_queue(spellId, recipe, count, profession, addToTop)")

    -- Synastria: Ensure queue is loaded before adding items
    if not Skillet.stitch.queue then
        ---@type string
        local tradeskill = profession or Skillet.currentTrade or ""
        Skillet:LoadQueue(Skillet.db.server.queues, tradeskill)
    end

    -- if we need mats that are not in the inventory, but are craftable, add
    -- the mats to the queue first

    if QUEUE_DEBUG then
        Skillet:Print("Adding " .. count .. "x" .. recipe.link)
    end

    if Skillet.db.profile.queue_craftable_reagents then
        -- Synastria: Snapshot queue consumption BEFORE processing reagents
        -- This prevents exponential growth when auto-queuing dependencies
        ---@type table<number, number>
        local queueSnapshot = {}
        ---@type Reagent[]
        local reagents = recipe.reagents or {}

        for i = 1, #reagents, 1 do
            ---@type Reagent
            local reagent = reagents[i]
            if reagent then
                local itemId = tonumber(string.match(reagent.link, "item:(%d+)"))
                if itemId and Skillet.GetQueuedReagentConsumption then
                    queueSnapshot[itemId] = Skillet:GetQueuedReagentConsumption(itemId)
                end
            end
        end

        -- Now process reagents using the snapshot
        for i = 1, #reagents, 1 do
            ---@type Reagent
            local reagent = reagents[i]

            if not reagent then
                break
            end

            local needed = (reagent.needed * count)
            local have = GetItemCount(reagent.link, true)

            -- Synastria: Add resource bank count
            if GetCustomGameData then
                local itemId = tonumber(string.match(reagent.link, "item:(%d+)"))
                if itemId then
                    have = have + (GetCustomGameData(13, itemId) or 0)
                end
            end

            -- Synastria: Subtract items already allocated to queued recipes
            -- Use the snapshot taken BEFORE any modifications
            local itemId = tonumber(string.match(reagent.link, "item:(%d+)"))
            if itemId and queueSnapshot[itemId] then
                ---@type number
                local queuedConsumption = queueSnapshot[itemId]
                local haveBefore = have
                have = have - queuedConsumption

                -- Debug output
                local itemName = reagent.name or ("Item#" .. itemId)
                Skillet:DebugLog(string.format("[Queue Check] %s: bags %d, queued %d (snapshot), avail %d, need %d",
                    itemName, haveBefore, queuedConsumption, have, needed))
            end

            if have < needed then
                -- Synastria: Check if we can satisfy this need through conversion
                -- BUT: Don't queue conversions for ingredients when we're currently
                -- queueing a conversion itself (prevents infinite loops)
                local isQueuingConversion = recipe.isVirtualConversion or false
                if not isQueuingConversion then
                    ---@type boolean
                    local conversionQueued = Skillet:QueueConversionsIfNeeded(reagent, needed)
                end

                -- Synastria: Search all professions (with profession priority in GetItemDataByName)
                -- This ensures smelting recipes are preferred over transmutes
                local item = Skillet.stitch:GetItemDataByName(reagent.name)
                if item then
                    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[QUEUE DEBUG] Found craftable recipe for reagent: " ..
                        (reagent.name or "<unknown>") ..
                        " (itemId=" .. tostring((item.link or ""):match("item:(%d+)")) .. ")|r")
                else
                    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[QUEUE DEBUG] No craftable recipe found for reagent: " ..
                        (reagent.name or "<unknown>") .. "|r")
                end

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
                                        if QUEUE_DEBUG then
                                            Skillet:Print("Skipping transmute with cooldown as subcraft: " ..
                                                item_check.name)
                                        end
                                    end
                                else
                                    -- Conservative: assume transmutes have cooldowns if we can't check
                                    shouldSkip = true
                                    if QUEUE_DEBUG then
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

                                -- Debug: About to queue subcraft
                                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[QUEUE DEBUG] Queuing subcraft: " ..
                                    (item_check.name or "<unknown>") .. " x" .. (needed - have) .. "|r")

                                -- Synastria: Find which profession this recipe belongs to
                                local itemProfession = find_profession_for_recipe(item_check)

                                -- Synastria: When adding required ingredients, also pass addToTop
                                -- so they get added before the main recipe
                                add_items_to_queue(item_check.spellId, item_check, (needed - have), itemProfession,
                                    addToTop)
                            end
                        end
                    end
                end
            end
        end
    end

    -- Synastria: Pass recipe.link so AddToQueue can use Custom API for cross-profession lookups
    local numericSpellId = tonumber(spellId) or 0
    ---@type string
    local finalLink = recipe.link or ""
    ---@diagnostic disable-next-line: param-type-mismatch
    Skillet.stitch:AddToQueue(numericSpellId, count, profession, addToTop, finalLink)

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

    playerData["AllProfessions"] = self.stitch.queue
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
                add_items_to_queue(s.spellId, s, count, self.currentTrade)
            end
            -- queued all that could be created, reset the create count
            -- back down to 0
            self:UpdateNumItemsSlider(0, false);
        end
    end
end

-- Adds the currently selected number of items to the queue
---@return nil
function Skillet:QueueItems()
    self.numItemsToCraft = SkilletItemCountInputBox:GetNumber();

    if self.numItemsToCraft > 0 then
        if self.currentTrade and self.selectedSkill then
            local s = self.stitch:GetItemDataByIndex(self.currentTrade, self.selectedSkill);
            if s then
                add_items_to_queue(s.spellId, s, self.numItemsToCraft, self.currentTrade)
            end
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
                add_items_to_queue(s.spellId, s, count, nil, true)
                self:ProcessQueue()
            end
            -- created all that could be created, reset the create count
            -- back down to 0
            self:UpdateNumItemsSlider(0, false)
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
                add_items_to_queue(s.spellId, s, self.numItemsToCraft, nil, true)
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
