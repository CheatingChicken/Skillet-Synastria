--[[

Skillet - Synastria: ResourceTracker Integration
Copyright (c) 2025 Synastria

This module provides optional integration with the ResourceTracker addon.
If ResourceTracker is not loaded, this module does nothing and Skillet works normally.

]]--

-- ========================================
-- Synastria: ResourceTracker Integration
-- ========================================
-- This module allows exporting Skillet's shopping list to ResourceTracker
-- Works only if ResourceTracker is loaded, otherwise fails gracefully

local L = AceLibrary("AceLocale-2.2"):new("Skillet")

-- Check if ResourceTracker is available
function Skillet:IsResourceTrackerAvailable()
    return _G.ResourceTracker and _G.ResourceTracker.QueueItemAdd
end

-- Export shopping list items to ResourceTracker
-- @param playername: Optional player name filter (nil = all players)
-- @param includeBank: Include bank items in availability calculation
-- @param silent: If true, suppress chat output (for automatic exports)
-- @return success, itemsAdded: true if export succeeded, and count of items added
function Skillet:ExportShoppingListToResourceTracker(playername, includeBank, silent)
    if not self:IsResourceTrackerAvailable() then
        if not silent then
            self:Print("|cFFFF0000ResourceTracker addon not found! Please install ResourceTracker to use this feature.|r")
        end
        return false, 0
    end
    
    -- Get full reagent list for queue
    local reagentsList = self:GetReagentsForQueuedRecipes(playername)
    
    if not reagentsList or #reagentsList == 0 then
        if not silent then
            self:Print("|cFFFFAA00Queue is empty - nothing to export.|r")
        end
        return true, 0
    end
    
    -- Track what we're adding
    local itemsAdded = 0
    local totalGoal = 0
    
    -- For each reagent, check if we can craft the full amount needed
    for i, entry in ipairs(reagentsList) do
        local link = entry.link
        local totalNeeded = entry.count
        
        if link and totalNeeded and totalNeeded > 0 then
            local itemId = self:GetItemIDFromLink(link)
            
            if itemId then
                local shouldAdd = false
                local shortage = 0
                
                -- Check if we already have enough (including resource bank)
                local currentAmount = GetItemCount(itemId, includeBank) or 0
                if GetCustomGameData then
                    currentAmount = currentAmount + (GetCustomGameData(13, itemId) or 0)
                end
                
                if currentAmount < totalNeeded then
                    -- Check if we can convert to get this item (e.g., Crystallized → Eternal)
                    local canConvert = false
                    local targetId, ratio, conversionType = self:GetConversionInfo(itemId)
                    if targetId then
                        local convertibleAmount = GetItemCount(targetId, includeBank) or 0
                        if GetCustomGameData then
                            convertibleAmount = convertibleAmount + (GetCustomGameData(13, targetId) or 0)
                        end
                        
                        local convertedAmount = 0
                        if conversionType == "combine" then
                            convertedAmount = math.floor(convertibleAmount / (1/ratio))
                        elseif conversionType == "split" then
                            convertedAmount = convertibleAmount * (1/ratio)
                        end
                        
                        if currentAmount + convertedAmount >= totalNeeded then
                            canConvert = true
                        end
                    end
                    
                    if not canConvert then
                        -- Find recipe for this item to check craftability
                        local recipe = self.stitch:GetItemDataByName(entry.name)
                        local canCraftAll = false
                        
                        if recipe then
                            -- Calculate how many we can craft with current materials
                            local numCraftable = self.CraftCalc:CalculateRecipeCraftability(recipe, self.stitch, includeBank, false, 0, false)
                            local amountCraftable = numCraftable * (recipe.nummade or 1)
                            
                            -- Can we craft the full amount needed (considering what we already have)?
                            shortage = totalNeeded - currentAmount
                            canCraftAll = (amountCraftable >= shortage)
                        end
                        
                        -- Only add to tracker if we CAN'T get the full amount
                        if not canCraftAll then
                            shouldAdd = true
                            shortage = totalNeeded - currentAmount
                        end
                    end
                end
                
                if shouldAdd then
                    -- Mark as externally controlled (5th parameter = true)
                    _G.ResourceTracker.QueueItemAdd(itemId, nil, shortage, true, true)
                    itemsAdded = itemsAdded + 1
                    totalGoal = totalGoal + shortage
                end
            end
        end
    end
    
    -- Report results
    if itemsAdded > 0 and not silent then
        self:Print(string.format("|cFF00FF00Exported %d item type(s) from queue to ResourceTracker!|r", itemsAdded))
        return true, itemsAdded
    else
        return true, 0
    end
end

-- Export a single item from the shopping list to ResourceTracker
-- @param itemLink: The item link or item ID
-- @param goalAmount: How many we need (goal)
-- @return success: true if the item was added
function Skillet:ExportItemToResourceTracker(itemLink, goalAmount)
    if not self:IsResourceTrackerAvailable() then
        return false
    end
    
    local itemId = self:GetItemIDFromLink(itemLink)
    if not itemId then
        return false
    end
    
    _G.ResourceTracker.QueueItemAdd(itemId, nil, goalAmount)
    return true
end

-- Slash command handler for /skillet exportrt
function Skillet:ExportToResourceTrackerCommand()
    local playername = nil -- Export for all players
    local includeBank = true -- Include bank when calculating what we need
    local silent = false -- Show messages for manual export
    
    self:ExportShoppingListToResourceTracker(playername, includeBank, silent)
end

-- Automatically export queue to ResourceTracker when queue changes
-- Called by Skillet:QueueChanged event
function Skillet:AutoExportQueueToResourceTracker()
    if not self:IsResourceTrackerAvailable() then
        return -- Silently fail if ResourceTracker not available
    end
    
    -- Generate a hash of the current queue state to detect actual changes
    local queueHash = ""
    for player, playerqueues in pairs(self:GetAllQueues()) do
        local queue = playerqueues["AllProfessions"]
        if queue and #queue > 0 then
            for i = 1, #queue do
                local item = queue[i]
                queueHash = queueHash .. (item.profession or "") .. ":" .. (item.index or "") .. ":" .. (item.numcasts or "") .. "|"
            end
        end
    end
    
    -- Only export if queue actually changed
    if self.lastExportedQueueHash ~= queueHash then
        self.lastExportedQueueHash = queueHash
        
        -- Clear all externally controlled items before re-syncing
        if _G.ResourceTracker.ClearExternalItems then
            _G.ResourceTracker.ClearExternalItems()
        end
        
        local playername = nil -- Export for all players
        local includeBank = true -- Include bank
        local silent = true -- Suppress messages for automatic export
        
        self:ExportShoppingListToResourceTracker(playername, includeBank, silent)
    end
end

-- Update ResourceTracker when items are crafted
-- Called after successful craft to reduce tracked goals
function Skillet:UpdateResourceTrackerAfterCraft(recipe, numCrafted)
    if not self:IsResourceTrackerAvailable() then
        return
    end
    
    if not recipe or not numCrafted or numCrafted <= 0 then
        return
    end
    
    -- For each reagent used in the craft, check if it's tracked
    for i = 1, 8 do
        local reagent = recipe[i]
        if not reagent then
            break
        end
        
        local itemId = self:GetItemIDFromLink(reagent.link)
        if itemId then
            local amountUsed = reagent.needed * numCrafted
            
            -- Remove this amount from the tracker goal
            if _G.ResourceTracker.RemoveFromItemGoal then
                _G.ResourceTracker.RemoveFromItemGoal(itemId, amountUsed)
            end
        end
    end
end

-- Register slash command
SLASH_SKILLETEXPORTRT1 = "/skilletexportrt"
SLASH_SKILLETEXPORTRT2 = "/skillet exportrt"
SlashCmdList["SKILLETEXPORTRT"] = function(msg)
    Skillet:ExportToResourceTrackerCommand()
end

-- Print information about the integration on load
local integrationFrame = CreateFrame("Frame")
integrationFrame:RegisterEvent("ADDON_LOADED")
integrationFrame:SetScript("OnEvent", function(self, event, addon)
    if addon == "Skillet - Synastria" then
        if Skillet:IsResourceTrackerAvailable() then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00Skillet <-> ResourceTracker integration enabled!|r")
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00Use '/skillet exportrt' or the shopping list button to export items.|r")
        end
        self:UnregisterAllEvents()
    end
end)
