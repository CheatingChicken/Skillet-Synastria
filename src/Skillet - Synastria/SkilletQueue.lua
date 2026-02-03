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

]]--

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
---@param skillIndex number The recipe index
---@param recipe Recipe The recipe object
---@param count number Number of times to queue
---@param profession number The profession ID
---@param addToTop boolean|nil Whether to add to top of queue
local function add_items_to_queue(skillIndex, recipe, count, profession, addToTop)
    assert(tonumber(skillIndex) and recipe and tonumber(count),"Usage: add_items_to_queue(skillIndex, recipe, count, profession, addToTop)")

    -- Synastria: Ensure queue is loaded before adding items
    if not Skillet.stitch.queue then
        Skillet:LoadQueue(Skillet.db.server.queues, profession or Skillet.currentTrade)
    end

    -- if we need mats that are not in the inventory, but are craftable, add
    -- the mats to the queue first

    if QUEUE_DEBUG then
        Skillet:Print("Adding " .. count .. "x" .. recipe.link)
    end

    if Skillet.db.profile.queue_craftable_reagents then
        -- Synastria: Use modern reagents table format
        local reagents = recipe.reagents or {}
        for i=1, #reagents, 1 do
            reagent = reagents[i]

            if not reagent then
                break
            end

            local needed = (reagent.needed * count)
            local   have = GetItemCount(reagent.link, true)
            
            -- Synastria: Add resource bank count
            if GetCustomGameData then
                local itemId = tonumber(string.match(reagent.link, "item:(%d+)"))
                if itemId then
                    have = have + (GetCustomGameData(13, itemId) or 0)
                end
            end
            
            -- Synastria: Subtract items already allocated to queued recipes
            local itemId = tonumber(string.match(reagent.link, "item:(%d+)"))
            if itemId and Skillet.GetQueuedReagentConsumption then
                local queuedConsumption = Skillet:GetQueuedReagentConsumption(itemId)
                local haveBefore = have
                have = have - queuedConsumption
                
                -- Debug output
                local itemName = reagent.name or ("Item#" .. itemId)
                Skillet:Print(string.format("|cFF888888[Queue Check] %s: bags %d, queued %d, avail %d, need %d|r", 
                    itemName, haveBefore, queuedConsumption, have, needed))
            end

            if have < needed then
                -- Synastria: Check if we can satisfy this need through conversion
                -- BUT: Don't queue conversions for ingredients when we're currently 
                -- queueing a conversion itself (prevents infinite loops)
                local isQueuingConversion = recipe.isVirtualConversion
                if not isQueuingConversion then
                    local conversionQueued = Skillet:QueueConversionsIfNeeded(reagent, needed)
                end
                
                -- Synastria: Search all professions (with profession priority in GetItemDataByName)
                -- This ensures smelting recipes are preferred over transmutes
                local item = Skillet.stitch:GetItemDataByName(reagent.name, nil)

                if item then
                    -- Compare item IDs instead of full links (links may have different color codes)
                    local itemId = tonumber((item.link or ""):match("item:(%d+)"))
                    local reagentId = tonumber((reagent.link or ""):match("item:(%d+)"))
                    
                    if itemId and reagentId and itemId == reagentId then
                        -- Verify item has the necessary structure
                        if not item.index then
                            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[QUEUE ERROR] Item missing index: " .. reagent.name .. "|r")
                        elseif type(item) ~= "table" then
                            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[QUEUE ERROR] Item is not a table: " .. reagent.name .. "|r")
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
                            local itemProfession = find_profession_for_recipe(item)
                            
                            -- Synastria: When adding required ingredients, also pass addToTop
                            -- so they get added before the main recipe
                            add_items_to_queue(item.index, item, (needed - have), itemProfession, addToTop)
                        end
                    end
                end
            end
        end
    end

	Skillet.stitch:AddToQueue(skillIndex, count, profession, addToTop)

    -- XXX: This is a bit hacky, try to think of something smarter
    Skillet:SaveQueue(Skillet.db.server.queues, Skillet.currentTrade)
end

-- Save the current queue into the provided database
function Skillet:SaveQueue(db, tradeskill)
    if not db[UnitName("player")] then
        db[UnitName("player")] = {}
    end
    
    -- Synastria: Use unified queue across all professions
    if not db[UnitName("player")]["AllProfessions"] then
        db[UnitName("player")]["AllProfessions"] = {}
    end

    db[UnitName("player")]["AllProfessions"] = self.stitch.queue
end

-- Loads the queue for the provided tradeskill name from the database
function Skillet:LoadQueue(db, tradeskill)
    if not db[UnitName("player")] then
        db[UnitName("player")] = {}
    end
    
    -- Synastria: Use unified queue across all professions
    -- Always use the same table reference from the database
    if not db[UnitName("player")]["AllProfessions"] then
        db[UnitName("player")]["AllProfessions"] = {}
    end

    -- Always point to the database table to maintain a single unified queue
    self.stitch.queue = db[UnitName("player")]["AllProfessions"]

    AceEvent:TriggerEvent("SkilletStitch_Queue_Add")
end

-- Queue the max number of craftable items for the currently selected skill
function Skillet:QueueAllItems()
	if self.currentTrade and self.selectedSkill then
		---@type Recipe|nil
		local s = self.stitch:GetItemDataByIndex(self.currentTrade, self.selectedSkill)
        if s then
            local factor = s.nummade or 1
            local count = math.floor(s.numcraftable/factor) - self.stitch:GetNumQueuedItems(self.selectedSkill)
            if count > 0 then
                add_items_to_queue(self.selectedSkill, s, count, self.currentTrade)
            end
			-- queued all that could be created, reset the create count
			-- back down to 0
			self:UpdateNumItemsSlider(0, false);
		end
	end
end

-- Adds the currently selected number of items to the queue
function Skillet:QueueItems()
	self.numItemsToCraft = SkilletItemCountInputBox:GetNumber();

	if self.numItemsToCraft > 0 then
		if self.currentTrade and self.selectedSkill then
			local s = self.stitch:GetItemDataByIndex(self.currentTrade, self.selectedSkill);
			if s then
				add_items_to_queue(self.selectedSkill, s, self.numItemsToCraft, self.currentTrade)
			end
		end
	end
end

-- Queue and create the max number of craftable items for the currently selected skill
function Skillet:CreateAllItems()
	if self.currentTrade and self.selectedSkill then
		local s = self.stitch:GetItemDataByIndex(self.currentTrade, self.selectedSkill);
        if s then
            local factor = s.nummade or 1
            local count = math.floor(s.numcraftable/factor) - self.stitch:GetNumQueuedItems(self.selectedSkill)
            if count > 0 then
                -- Synastria: Add to TOP of queue (true parameter) so we can craft immediately
                add_items_to_queue(self.selectedSkill, s, count, nil, true)
                self:ProcessQueue()
            end
            -- created all that could be created, reset the create count
            -- back down to 0
            self:UpdateNumItemsSlider(0, false)
		end
	end
end

-- Adds the currently selected number of items to the queue and then starts the queue
function Skillet:CreateItems()
	self.numItemsToCraft = SkilletItemCountInputBox:GetNumber();

	if self.numItemsToCraft > 0 then
		if self.currentTrade and self.selectedSkill then
			local s = self.stitch:GetItemDataByIndex(self.currentTrade, self.selectedSkill);
			if s then
				-- Synastria: Add to TOP of queue (true parameter) so we can craft immediately
				add_items_to_queue(self.selectedSkill, s, self.numItemsToCraft, nil, true)
				self:ProcessQueue();
			end
		end
	end
end

-- Starts Processing any items in the queue
function Skillet:ProcessQueue()
	local queue = self.stitch:GetQueueInfo()
	if not queue then
		return
	end

	self.stitch:ProcessQueue()
end

-- Clears the current queue, this will not cancel an
-- items currently being crafted.
function Skillet:EmptyQueue()
	self.stitch:ClearQueue()
    self:SaveQueue(self.db.server.queues, self.currentTrade)
end

-- Removes an item from the queue
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
function Skillet:GetAllQueues()
    if not self.db.server.queues then
        return {}
    end

    return self.db.server.queues
end

-- Returns the list of queues for the specified player
function Skillet:GetQueues(player)
    assert(tostring(player),"Usage: GetQueues('player_name')")

    if not self.db.server.queues then
        return {}
    end

    if not self.db.server.queues[player] then
        return {}
    end

    return self.db.server.queues[player]
end

-- Returns the list of queues for the current player
function Skillet:GetPlayerQueues()
    return self:GetQueues(UnitName("player"))
end

-- Updates the list with the required number of items
-- of "link". If "name" is already in the list, the count in updated,
-- otherwise it is appended to the end of the list.
local function update_queued_list(list, player, name, link, needed)
    for i=1,#list,1 do
        if list[i]["name"] == name then
            list[i]["count"] = list[i]["count"] + needed
            if list[i].player and not string.find(list[i].player, player) then
                list[i].player = list[i].player .. ", " .. player
            end
            return
        end
    end

    table.insert(list, {
        ["name"]  = name,
        ["link"]  = link,
        ["count"] = needed,
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
function Skillet:GetReagentsForQueuedRecipes(playername)
    local list = {}

    for player,playerqueues in pairs(self:GetAllQueues()) do
        -- check the unified queue
        if not playername or playername == player then
            -- Synastria: Use unified "AllProfessions" queue
            local queue = playerqueues["AllProfessions"]
            if queue and #queue > 0 then
                for i=1,#queue,1 do
                    local queueItem = queue[i]
                    local profession = queueItem.profession
                    local index = queueItem.index
                    local count = queueItem.numcasts
                    
                    -- Synastria: Fetch the actual recipe data from the profession cache
                    -- The queue only stores {profession, index, numcasts, recipe={name,link}}
                    -- We need the full recipe with reagents
                    local recipe = self.stitch:GetItemDataByIndex(profession, index)
                    
                    if recipe then
                        local reagents = recipe.reagents or {}
                        for j=1, #reagents, 1 do
                            local reagent = reagents[j]
                            if reagent then
                                local needed = (count * reagent.needed)
                                if needed > 0 then
                                    update_queued_list(list, player, reagent.name, reagent.link, needed)
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
