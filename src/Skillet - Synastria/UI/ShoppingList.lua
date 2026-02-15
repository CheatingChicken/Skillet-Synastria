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

--[[
#
# Deals with building and maintaining a shopping list. This is the list
# of items that are required for queued receipes but are not currently
# in the inventory
#
]] --

SKILLET_SHOPPING_LIST_HEIGHT = 16

---@type AceLocale
local L                      = AceLibrary("AceLocale-2.2"):new("Skillet")

-- Stolen from the Waterfall Ace2 addon.
---@type BackdropTable
local ControlBackdrop        = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
}
---@type BackdropTable
local FrameBackdrop          = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 3, right = 3, top = 30, bottom = 3 }
}

-- Creates and sets up the shopping list window
---@param self table The Skillet object
---@return Frame|nil frame The created shopping list frame, or nil if not found
local function createShoppingListFrame(self)
    local frame = SkilletShoppingList
    if not frame then
        return nil
    end

    frame:SetBackdrop(FrameBackdrop);
    frame:SetBackdropColor(0.1, 0.1, 0.1)

    -- A title bar stolen from the Ace2 Waterfall window.
    local r, g, b = 0, 0.7, 0; -- dark green
    local titlebar = frame:CreateTexture(nil, "BACKGROUND")
    local titlebar2 = frame:CreateTexture(nil, "BACKGROUND")

    titlebar:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -4)
    titlebar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -3, -4)
    titlebar:SetHeight(13)

    titlebar2:SetPoint("TOPLEFT", titlebar, "BOTTOMLEFT", 0, 0)
    titlebar2:SetPoint("TOPRIGHT", titlebar, "BOTTOMRIGHT", 0, 0)
    titlebar2:SetHeight(13)

    titlebar:SetGradientAlpha("VERTICAL", r * 0.6, g * 0.6, b * 0.6, 1, r, g, b, 1)
    titlebar:SetTexture(r, g, b, 1)
    titlebar2:SetGradientAlpha("VERTICAL", r * 0.9, g * 0.9, b * 0.9, 1, r * 0.6, g * 0.6, b * 0.6, 1)
    titlebar2:SetTexture(r, g, b, 1)

    local title = CreateFrame("Frame", nil, frame)
    title:SetPoint("TOPLEFT", titlebar, "TOPLEFT", 0, 0)
    title:SetPoint("BOTTOMRIGHT", titlebar2, "BOTTOMRIGHT", 0, 0)

    local titletext = title:CreateFontString("SkilletShoppingListTitleText", "OVERLAY", "GameFontNormalLarge")
    titletext:SetPoint("TOPLEFT", title, "TOPLEFT", 0, 0)
    titletext:SetPoint("TOPRIGHT", title, "TOPRIGHT", 0, 0)
    titletext:SetHeight(26)
    titletext:SetShadowColor(0, 0, 0)
    titletext:SetShadowOffset(1, -1)
    titletext:SetTextColor(1, 1, 1)
    titletext:SetText("Skillet: " .. GetLocalizedString("Shopping List"))

    SkilletShowQueuesFromAllAltsText:SetText(GetLocalizedString("Include alts"))
    SkilletShowQueuesFromAllAlts:SetChecked(Skillet.db.char.include_alts)

    -- The frame enclosing the scroll list needs a border and a background .....
    local backdrop = SkilletShoppingListParent
    if backdrop then
        backdrop:SetBackdrop(ControlBackdrop)
        backdrop:SetBackdropBorderColor(0.6, 0.6, 0.6)
        backdrop:SetBackdropColor(0.05, 0.05, 0.05)
        backdrop:SetResizable(true)
    end

    -- Button to retrieve items needed from the bank
    SkilletShoppingListRetrieveButton:SetText(GetLocalizedString("Retrieve"))

    -- Synastria: Show/hide Export to ResourceTracker button based on availability
    if SkilletShoppingListExportRTButton then
        if self.IsResourceTrackerAvailable and self:IsResourceTrackerAvailable() then
            SkilletShoppingListExportRTButton:Show()
        else
            SkilletShoppingListExportRTButton:Hide()
        end
    end

    -- Synastria: Debug button (only visible in developer mode)
    local debugButton = CreateFrame("Button", "SkilletShoppingListDebugButton", frame, "UIPanelButtonTemplate")
    debugButton:SetWidth(80)
    debugButton:SetHeight(24)
    debugButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
    debugButton:SetText("Debug")
    debugButton:SetScript("OnClick", function()
        self:DebugShoppingListCalculation()
    end)
    debugButton:Hide() -- Hidden by default, shown when dev mode active
    frame.debugButton = debugButton

    -- Ace Window manager library, allows the window position (and size)
    -- to be automatically saved
    local windowManger = AceLibrary("Window-1.0")
    local shoppingListLocation = {
        prefix = "shoppingListLocation_"
    }
    windowManger:RegisterConfig(frame, self.db.char, shoppingListLocation)
    windowManger:RestorePosition(frame) -- restores scale also
    windowManger:MakeDraggable(frame)

    -- lets play the resize me game!
    Skillet:EnableResize(frame, 300, 165, Skillet.UpdateShoppingListWindow)

    -- so hitting [ESC] will close the window
    tinsert(UISpecialFrames, frame:GetName())
    return frame
end


-- Synastria: Use centralized conversion maps from Skillet.lua
-- These are built automatically from Skillet.CONVERSION_DEFINITIONS
---@return table<number, number> crystallizedToEternal Crystallized to Eternal conversion map
---@return table<number, number> eternalToCrystallized Eternal to Crystallized conversion map
local function getConversionMaps()
    ---@type table<number, number>
    local crystallizedToEternal = {}
    ---@type table<number, number>
    local eternalToCrystallized = {}

    if Skillet and Skillet.CONVERSION_DEFINITIONS then
        ---@type table<string, any>[]
        local definitions = Skillet.CONVERSION_DEFINITIONS
        for _, conversion in ipairs(definitions) do
            ---@type string
            local convType = conversion.type
            ---@type number
            local source = conversion.source
            ---@type number
            local target = conversion.target
            if convType == "combine" then
                crystallizedToEternal[source] = target
            elseif convType == "split" then
                eternalToCrystallized[source] = target
            end
        end
    end

    return crystallizedToEternal, eternalToCrystallized
end

---@type table<number, number>
local CRYSTALLIZED_TO_ETERNAL_MAP = {}
---@type table<number, number>
local ETERNAL_TO_CRYSTALLIZED_MAP = {}
CRYSTALLIZED_TO_ETERNAL_MAP, ETERNAL_TO_CRYSTALLIZED_MAP = getConversionMaps()

-- Returns a table of items that:
--   1. are needed to create the queued items for the specified player
--   2. are not in the inventory
-- If the player is not provided, then all players are assumed.
-- Synastria: Updated to include resource bank, subtract items being crafted, and account for conversions
---@param playername string|nil The player name (optional)
---@param includeBank boolean|nil Whether to include bank items (optional)
---@return table list List of {link, count, name, player} items needed
function Skillet:GetShoppingList(playername, includeBank)
    ---@type table[]
    local list = self:GetReagentsForQueuedRecipes(playername) or {}

    -- Synastria: Build a table of items being crafted in the queue
    -- Also track Crystallized/Eternal reserved for conversions
    ---@type table<string, number>
    local queuedCrafts = {}
    ---@type table<number, number>
    local reservedForConversion = {}
    for player, playerqueues in pairs(self:GetAllQueues()) do
        if not playername or playername == player then
            local queue = playerqueues["AllProfessions"]
            if queue and #queue > 0 then
                for i = 1, #queue, 1 do
                    local queueItem = queue[i]
                    local count = queueItem.numcasts
                    local spellId = queueItem.spellId

                    -- Synastria: Get recipe info from Custom API
                    local link = nil
                    if spellId and Custom_GetProfessionRecipeInfo then
                        local skillId, name, itemId, craftCount = Custom_GetProfessionRecipeInfo(spellId)
                        if itemId then
                            -- Create item link from item ID
                            link = select(2, GetItemInfo(itemId))
                        end
                    end

                    -- Extract item ID from link to match properly
                    if link then
                        if queuedCrafts[link] then
                            queuedCrafts[link] = queuedCrafts[link] + count
                        else
                            queuedCrafts[link] = count
                        end
                    end

                    -- Note: Conversions are no longer supported in the new queue structure
                    if queueItem and queueItem.isVirtualConversion then
                        ---@type number|nil
                        local sourceId = queueItem.sourceId
                        ---@type number|nil
                        local sourceNeeded = queueItem.sourceNeeded
                        if sourceId and sourceNeeded then
                            if reservedForConversion[sourceId] then
                                reservedForConversion[sourceId] = reservedForConversion[sourceId] + sourceNeeded
                            else
                                reservedForConversion[sourceId] = sourceNeeded
                            end
                        end
                    end
                end
            end
        end
    end

    -- decrease counts by what we have on hand.
    -- work backwards so that removing items form the table
    -- does not screw up our indexing.
    -- ONLY show items where we have an actual shortage (count > 0)
    for i = #list, 1, -1 do
        ---@type table
        local item = list[i]
        if not item then break end

        ---@type string
        local link   = item.link
        ---@type number
        local count  = item.count

        local have   = GetItemCount(link, includeBank) or 0

        -- Synastria: Also check resource bank
        local itemId = tonumber(string.match(link, "item:(%d+)"))
        if GetCustomGameData and itemId then
            have = have + (GetCustomGameData(13, itemId) or 0)
        end

        -- Account for items being crafted in the queue that we also need as reagents
        if queuedCrafts[link] then
            have = have + queuedCrafts[link]
        end

        -- Synastria: Account for Crystallized <-> Eternal conversions
        -- But don't count materials already reserved for conversion queue items
        local canConvert = 0
        if itemId then
            -- If we need an Eternal, check if we have Crystallized to convert
            local crystallizedId = ETERNAL_TO_CRYSTALLIZED_MAP[itemId]
            if crystallizedId then
                local crystallizedCount = GetItemCount(crystallizedId, includeBank) or 0
                if GetCustomGameData then
                    crystallizedCount = crystallizedCount + (GetCustomGameData(13, crystallizedId) or 0)
                end
                -- Subtract any Crystallized already reserved for conversion
                local reserved = reservedForConversion[crystallizedId] or 0
                crystallizedCount = math.max(0, crystallizedCount - reserved)
                -- 10 Crystallized = 1 Eternal
                canConvert = math.floor(crystallizedCount / 10)
            end

            -- If we need Crystallized, check if we have Eternal to break down
            local eternalId = CRYSTALLIZED_TO_ETERNAL_MAP[itemId]
            if eternalId then
                local eternalCount = GetItemCount(eternalId, includeBank) or 0
                if GetCustomGameData then
                    eternalCount = eternalCount + (GetCustomGameData(13, eternalId) or 0)
                end
                -- Subtract any Eternal already reserved for breakdown (if we track that in the future)
                -- For now, we only track Crystallized->Eternal conversions in the queue
                -- 1 Eternal = 10 Crystallized
                canConvert = eternalCount * 10
            end
        end

        local totalAvailable = have + canConvert

        if totalAvailable >= count then
            -- We have enough between direct inventory and conversions - remove from shopping list
            table.remove(list, i)
        else
            -- Calculate actual shortfall
            ---@type number
            local stillNeed = count - totalAvailable

            -- Synastria: Replace Eternals with Crystallized equivalents (show base ingredients only)
            ---@type number|nil
            local crystallizedId = ETERNAL_TO_CRYSTALLIZED_MAP[itemId]
            if crystallizedId then
                -- This is an Eternal - replace with Crystallized equivalent
                local crystallizedLink = select(2, GetItemInfo(crystallizedId))
                local crystallizedName = select(1, GetItemInfo(crystallizedId))
                if crystallizedLink and crystallizedName then
                    item.link = crystallizedLink
                    item.name = crystallizedName
                    item.count = stillNeed * 10 -- 1 Eternal = 10 Crystallized
                else
                    -- Fallback if item info not available yet
                    item.count = stillNeed
                end
            else
                -- Not an Eternal - use as-is
                item.count = stillNeed
            end

            -- Note: We no longer add conversion alternatives - we show only the base ingredient (Crystallized)
        end
    end

    -- Final safety filter: Remove any items with count <= 0 (shouldn't be any, but let's be safe)
    for i = #list, 1, -1 do
        ---@type table
        local item = list[i]
        if item and (not item.count or item.count <= 0) then
            table.remove(list, i)
        end
    end

    return list
end

---@param self table The Skillet object
---@return nil
local function cache_list(self)
    local name = nil
    if not Skillet.db.char.include_alts then
        name = UnitName("player")
    end
    ---@type table[]|nil
    self.cachedShoppingList = self:GetShoppingList(name, true) -- true = include bank!
end

-- Called when the bank frame is opened
---@return nil
function Skillet:BANKFRAME_OPENED()
    if not self.db.profile.display_shopping_list_at_bank then
        return
    end

    cache_list(self)
    if #self.cachedShoppingList == 0 then
        return
    end

    self:DisplayShoppingList(true) -- true -> at bank
end

-- Called when the bank frame is closed
---@return nil
function Skillet:BANKFRAME_CLOSED()
    self:HideShoppingList()
end

-- Called when the auction frame is opened
---@return nil
function Skillet:AUCTION_HOUSE_SHOW()
    if not self.db.profile.display_shopping_list_at_auction then
        return
    end

    cache_list(self)
    if #self.cachedShoppingList == 0 then
        return
    end

    self:DisplayShoppingList(false) -- false -> not at a bank
end

-- Called when the auction frame is closed
---@return nil
function Skillet:AUCTION_HOUSE_CLOSED()
    self:HideShoppingList()
end

---@type BankItem[]|nil
local bank

---@return nil
local function indexBank()
    ---@type BankItem[]
    bank = {}

    local container = BANK_CONTAINER

    -- The main bank uses a bag ID of -1, just to make my life difficult.
    for i = 1, GetContainerNumSlots(container), 1 do
        local item = GetContainerItemLink(container, i)
        if item then
            local _, count = GetContainerItemInfo(container, i)
            table.insert(bank, {
                ["bag"]   = container,
                ["slot"]  = i,
                ["id"]    = Skillet:GetItemIDFromLink(item),
                ["count"] = count,
            })
        end
    end

    -- the bag that you can purchase in the bank are numbers 5 to 11
    for container = 5, 11, 1 do
        for i = 1, GetContainerNumSlots(container), 1 do
            local item = GetContainerItemLink(container, i)
            if item then
                local _, count = GetContainerItemInfo(container, i)
                table.insert(bank, {
                    ["bag"]   = container,
                    ["slot"]  = i,
                    ["id"]    = Skillet:GetItemIDFromLink(item),
                    ["count"] = count,
                })
            end
        end
    end
end

-- checks to see if this ios a normal bag (not ammo, herb, enchanting, etc)
-- I borrowed this code from ClosetGnome.
---@param bagId number The bag container ID
---@return boolean isNormal Whether this is a normal bag
local function isNormalBag(bagId)
    -- backpack and bank are always normal
    if bagId == 0 or bagId == -1 then return true end

    local link = GetInventoryItemLink("player", ContainerIDToInventoryID(bagId))
    if not link then return false end

    local id = Skillet:GetItemIDFromLink(link)
    if not id then return false end

    local bagType = select(7, GetItemInfo(id))
    -- INVTYPE_BAG is defined by Blizzard
    if bagType and bagType == INVTYPE_BAG then return true end

    return false
end

-- Returns a bug that the item can be placed in.
---@param item string The item link
---@param count number The count of items to place
---@return number|nil bagId The bag container ID, or nil if no space found
local function findBagForItem(item, count)
    local _, _, _, _, _, _, _, itemStackCount = GetItemInfo(item)
    local id = Skillet:GetItemIDFromLink(item)

    if not id then return nil end

    for container = 0, 4, 1 do
        if isNormalBag(container) then
            local bag_size = GetContainerNumSlots(container) -- 0 if there is no bag
            for slot = 1, bag_size, 1 do
                local bagitem = GetContainerItemLink(container, slot)
                if bagitem then
                    if id == Skillet:GetItemIDFromLink(bagitem) then
                        -- found some of the same, it is a full stack or locked?
                        local _, num_in_bag, locked = GetContainerItemInfo(container, slot)
                        local space_available       = itemStackCount - num_in_bag
                        if space_available >= count and not locked then
                            return container
                        end
                    end
                else
                    -- no item there, this looks like a good place to put something.
                    return container
                end
            end
        end
    end

    return nil
end

---@param item_id number The item ID
---@param bag number The bag container ID
---@param slot number The slot in the bag
---@param count number The count to move
---@return number movedCount The number of items moved
local function getItemFromBank(item_id, bag, slot, count)
    ClearCursor()
    local _, available = GetContainerItemInfo(bag, slot)
    local link = GetContainerItemLink(bag, slot)
    local num_moved = 0

    if available == 1 or count >= (available or 0) then
        PickupContainerItem(bag, slot)
        num_moved = available or 0
    else
        SplitContainerItem(bag, slot, count)
        num_moved = count
    end

    if not link then
        return 0
    end

    ---@type number|nil
    local targetBag = findBagForItem(link, num_moved)

    if not targetBag then
        Skillet:Print(GetLocalizedString("Could not find bag space for") .. ": " .. link)
        return 0
    end

    if targetBag == 0 then
        PutItemInBackpack()
    else
        PutItemInBag(ContainerIDToInventoryID(targetBag))
    end

    return num_moved
end

-- Gets all the reagents possible for queued recipies from the bank
---@return nil
function Skillet:GetReagentsFromBank()
    ---@type ShoppingListItem[]
    local list = self.cachedShoppingList or {}

    indexBank()

    if not bank then return end

    for _, v in pairs(list) do
        local id = self:GetItemIDFromLink(v.link)
        if id then
            for _, item in pairs(bank) do
                if item.id == id and item.count > 0 then
                    -- taking stuff from the bank should cause a bag update event
                    -- to be fired, which will in turn cause Skillet:UpdateShoppingListWindow()
                    -- to be called. I hope.
                    local link = GetContainerItemLink(item.bag, item.slot)
                    local moved = getItemFromBank(id, item.bag, item.slot, v.count)
                    if moved > 0 then
                        v.count = v.count - moved
                    end
                end
            end
        end
    end

    -- no need to keep the memory for bank items anymore
    bank = nil
end

---@return nil
function Skillet:ShoppingListToggleShowAlts()
    Skillet.db.char.include_alts = not Skillet.db.char.include_alts
end

local num_buttons = 0

---@param i number The button index
---@return Button button The shopping list button
local function get_button(i)
    ---@type Frame|nil
    local button = getglobal("SkilletShoppingListButton" .. i)
    if not button then
        ---@type Frame
        button = CreateFrame("Button", "SkilletShoppingListButton" .. i, SkilletShoppingListParent,
            "SkilletShoppingListItemButtonTemplate")
        if SkilletShoppingList then
            button:SetParent(SkilletShoppingList)
        end
        button:SetPoint("TOPLEFT", "SkilletShoppingListButton" .. (i - 1), "BOTTOMLEFT")
    end
    ---@cast button Button
    return button
end

-- Called to update the shopping list window
---@param use_cached_recipes boolean|nil Whether to use cached recipes (optional)
---@return nil
function Skillet:UpdateShoppingListWindow(use_cached_recipes)
    if not self.shoppingList or not self.shoppingList:IsVisible() then
        return
    end

    if not use_cached_recipes then
        cache_list(self)
    end
    local numItems = #self.cachedShoppingList

    if numItems == 0 then
        SkilletShoppingListRetrieveButton:Disable()
    else
        SkilletShoppingListRetrieveButton:Enable()
    end

    local button_count = SkilletShoppingListList:GetHeight() / SKILLET_SHOPPING_LIST_HEIGHT
    button_count = math.floor(button_count)

    -- Update the scroll frame
    ---@diagnostic disable-next-line: param-type-mismatch
    FauxScrollFrame_Update(SkilletShoppingListList, -- frame
        numItems,                                   -- num items
        button_count,                               -- num to display
        SKILLET_SHOPPING_LIST_HEIGHT)               -- value step (item height)

    -- Where in the list of items to start counting.
    local itemOffset = FauxScrollFrame_GetOffset(SkilletShoppingListList) or 0

    local width = SkilletShoppingListList:GetWidth()

    for i = 1, button_count, 1 do
        num_buttons     = math.max(num_buttons, i)

        local itemIndex = i + itemOffset

        local button    = get_button(i)
        ---@type FontString|nil
        local count     = getglobal(button:GetName() .. "CountText")
        ---@type FontString|nil
        local name      = getglobal(button:GetName() .. "NameText")
        ---@type FontString|nil
        local player    = getglobal(button:GetName() .. "PlayerText")

        button:SetWidth(width)

        local button_width = width - 5
        local count_width  = math.max(button_width * 0.1, 30)
        local player_width = math.max(button_width * 0.3, 100)
        local name_width   = math.max(button_width - count_width - player_width, 125)

        if count and name and player then
            count:SetWidth(count_width)
            name:SetWidth(name_width)
            name:SetPoint("LEFT", count:GetName(), "RIGHT", 4)
            player:SetWidth(player_width)
            player:SetPoint("LEFT", name:GetName(), "RIGHT", 4)
        end

        if itemIndex <= numItems and count and name and player then
            ---@type table
            local item = self.cachedShoppingList[itemIndex] or {}

            count:SetText(tostring(item.count or 0))
            name:SetText(item.link or "")
            player:SetText(item.player or "")

            ---@type string
            local link      = item.link or ""
            ---@type number
            local itemCount = item.count or 0

            ---@diagnostic disable-next-line: inject-field
            button.link     = link
            ---@diagnostic disable-next-line: inject-field
            button.count    = itemCount

            button:Show()
            name:Show()
            count:Show()
            player:Show()
        else
            ---@diagnostic disable-next-line: inject-field
            button.link = nil
            button:Hide()
            if name then name:Hide() end
            if count then count:Hide() end
            if player then player:Hide() end
        end
    end


    -- Hide any of the buttons that we created, but don't need right now
    for i = button_count + 1, num_buttons, 1 do
        local button = get_button(i)
        button:Hide()
    end
end

-- Called when the list of reagents is scrolled
---@return nil
function Skillet:ShoppingList_OnScroll()
    Skillet:UpdateShoppingListWindow(true) -- true == use the cached list of recipes
end

-- Fills out and displays the shopping list frame
---@param atBank boolean Whether the list should be displayed at the bank
---@return nil
function Skillet:internal_DisplayShoppingList(atBank)
    if not self.shoppingList then
        self.shoppingList = createShoppingListFrame(self)
    end
    local frame = self.shoppingList

    if not atBank then
        SkilletShoppingListRetrieveButton:Hide()
    else
        SkilletShoppingListRetrieveButton:Show()
    end

    -- Synastria: Update ResourceTracker button visibility
    if SkilletShoppingListExportRTButton then
        if self.IsResourceTrackerAvailable and self:IsResourceTrackerAvailable() then
            SkilletShoppingListExportRTButton:Show()
        else
            SkilletShoppingListExportRTButton:Hide()
        end
    end

    -- Synastria: Show/hide debug button based on developer mode
    if frame and frame.debugButton then
        if self:IsDevMode() then
            frame.debugButton:Show()
        else
            frame.debugButton:Hide()
        end
    end

    cache_list(self)

    if frame and not frame:IsVisible() then
        ShowUIPanel(frame)

        -- Register BAG_UPDATE to refresh shopping list while window is open
        if not self.shoppingListBagUpdateRegistered then
            self:RegisterEvent("BAG_UPDATE", "ShoppingList_OnBagUpdate")
            self.shoppingListBagUpdateRegistered = true
        end
    end

    -- true == use cached recipes, we just loaded them after all
    self:UpdateShoppingListWindow(true)
end

-- Refresh shopping list cache when bags update (while window is visible)
---@return nil
function Skillet:ShoppingList_OnBagUpdate()
    -- Only refresh if shopping list window is visible
    if not self.shoppingList or not self.shoppingList:IsVisible() then
        return
    end

    -- Recalculate the shopping list with current inventory
    cache_list(self)

    -- Refresh the display
    if self.shoppingList and self.shoppingList:IsVisible() then
        self:UpdateShoppingListWindow(true) -- true = use cached list
    end
end

-- Hides the shopping list window
---@return nil
function Skillet:internal_HideShoppingList()
    if self.shoppingList then
        HideUIPanel(self.shoppingList)
    end

    -- Unregister BAG_UPDATE handler when window is hidden
    if self.shoppingListBagUpdateRegistered then
        self:UnregisterEvent("BAG_UPDATE", "ShoppingList_OnBagUpdate")
        self.shoppingListBagUpdateRegistered = false
    end

    ---@type table[]|nil
    self.cachedShoppingList = nil
end

-- Synastria: Debug function to log detailed shopping list calculation breakdown
---@return nil
function Skillet:DebugShoppingListCalculation()
    local group = "Shopping List"

    SkilletLog:Add("========== SHOPPING LIST DEBUG ==========", "INFO", group)

    local name = nil
    if not self.db.char.include_alts then
        name = UnitName("player")
    end

    -- Get raw reagent list
    local rawList = self:GetReagentsForQueuedRecipes(name) or {}
    SkilletLog:Add("Raw reagent list has " .. #rawList .. " items", "SUCCESS", group)

    -- Build queued crafts table
    ---@type table<string, number>
    local queuedCrafts = {}
    for player, playerqueues in pairs(self:GetAllQueues()) do
        if not name or name == player then
            local queue = playerqueues["AllProfessions"]
            if queue and #queue > 0 then
                for i = 1, #queue, 1 do
                    local queueItem = queue[i]
                    local count = queueItem.numcasts
                    local spellId = queueItem.spellId

                    if spellId and Custom_GetProfessionRecipeInfo then
                        local skillId, recipeName, itemId, craftCount = Custom_GetProfessionRecipeInfo(spellId)
                        if itemId then
                            local link = select(2, GetItemInfo(itemId))
                            if link then
                                ---@type number
                                local currentCount = queuedCrafts[link] or 0
                                queuedCrafts[link] = currentCount + count
                            end
                        end
                    end
                end
            end
        end
    end

    -- Process each item
    for i, item in ipairs(rawList) do
        local link = item.link
        local needed = item.count
        local itemId = tonumber(string.match(link, "item:(%d+)"))
        local itemName = item.name or "Unknown"

        SkilletLog:Add("--- " .. itemName .. " (ID:" .. tostring(itemId) .. ") ---", "WARN", group)
        SkilletLog:Add("  Total Needed: " .. needed, "INFO", group)

        -- Inventory check
        local bags = GetItemCount(link, false) or 0
        local bagsAndBank = GetItemCount(link, true) or 0
        local resBank = 0
        if GetCustomGameData and itemId then
            resBank = GetCustomGameData(13, itemId) or 0
        end

        SkilletLog:Add("  Bags Only: " .. bags, "INFO", group)
        SkilletLog:Add("  Bags+Bank: " .. bagsAndBank, "INFO", group)
        SkilletLog:Add("  Resource Bank: " .. resBank, "INFO", group)
        SkilletLog:Add("  Total Have: " .. (bagsAndBank + resBank), "INFO", group)

        -- Queued crafts
        local queuedCount = queuedCrafts[link] or 0
        if queuedCount > 0 then
            SkilletLog:Add("  Items Being Crafted: " .. queuedCount, "INFO", group)
            SkilletLog:Add("  Adjusted Have: " .. (bagsAndBank + resBank + queuedCount), "INFO", group)
        end

        -- Final shortage
        local totalAvailable = bagsAndBank + resBank + queuedCount
        local shortage = needed - totalAvailable
        if shortage > 0 then
            SkilletLog:Add("  SHORTAGE: " .. shortage, "ERROR", group)
        else
            SkilletLog:Add("  COVERED (excess: " .. (-shortage) .. ")", "SUCCESS", group)
        end
    end

    SkilletLog:Add("=========================================", "INFO", group)

    -- Open log viewer automatically and switch to Shopping List group
    self:ShowLogViewer("Shopping List")
end
