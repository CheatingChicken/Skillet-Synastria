---@meta

-- ========================================
-- Synastria Custom Server API Type Definitions
-- ========================================
-- This file provides type information for custom APIs added by the Synastria server
-- These are extensions to the standard WoW 3.3.5 API
-- It is not executed, only used for type checking (---@meta directive)

-- Attunement APIs
---@param itemId number The item ID
---@param forge? number The forge level to check, or -1 for highest across all forges (default: -1)
---@return number|nil percentage The highest attunement percentage (0-100), or nil if not attunable
function GetHighestAttunePct(itemId, forge) end

-- Item Inspection APIs (Bag/Slot Based)
---@param nativeBagId number The bag ID (0-4 for bags, -1 for bank, etc.)
---@param nativeSlotId number The slot ID within the bag
---@return number|nil isSoulbound Returns 1 if soulbound, nil if not soulbound
function Custom_IsItemSoulbound(nativeBagId, nativeSlotId) end

---@param nativeBagId number The bag ID (0-4 for bags, -1 for bank, etc.)
---@param nativeSlotId number The slot ID within the bag
---@return number|nil isInEquipMgr Returns 1 if in equipment manager sets, nil if not
function Custom_IsItemEquipMgr(nativeBagId, nativeSlotId) end

---@param nativeBagId number The bag ID (0-4 for bags, -1 for bank, etc.)
---@param nativeSlotId number The slot ID within the bag
---@return number|nil lowGuid The low 32 bits of the item GUID
---@return number|nil highGuid The high 32 bits of the item GUID
function Custom_GetItemGuid(nativeBagId, nativeSlotId) end

---@param nativeBagId number The bag ID (0-4 for bags, -1 for bank, etc.)
---@param nativeSlotId number The slot ID within the bag
---@return string|nil itemLink The item link, or nil if slot is empty
function Custom_GetItemLinkBySlot(nativeBagId, nativeSlotId) end

-- Link Parsing
---@param wowLink string Any WoW hyperlink (item, spell, quest, etc.)
---@return number|nil id The ID extracted from the link
---@return number|nil type The object type (corresponds to link type)
function Custom_GetIdFromLink(wowLink) end

-- Location/Position APIs
---@param mapId number The map ID to check
---@param x number The X coordinate
---@param y number The Y coordinate
---@param z? number The Z coordinate (optional, if nil then 2D distance only)
---@param dist? number The maximum distance in yards (default: 30)
---@return number|nil isNear Returns 1 if player is within distance, nil if not
function Custom_IsPlayerNear(mapId, x, y, z, dist) end

-- Profession Recipe APIs
---@class ProfessionRecipeFilters
---@field ATTUNABLE_CUR_CHAR number 0x01 - Recipe creates item attunable by current character
---@field UNUSED number 0x02 - Reserved/unused flag
---@field ATTUNABLE_BY_SOMEONE number 0x04 - Recipe creates item attunable by someone
---@field FILTER_REAGENTS number 0x08 - String filter also checks reagent names
---@field HAVE_CRAFTED_ITEM number 0x10 - Have created item in inventory
---@field HAVE_MATERIALS number 0x20 - Have materials to craft this recipe
---@field IS_ATTUNED number 0x40 - Recipe creates an attuned item (requires forge parameter)

---@class RecipeSortType
---@field SPELL_NAME number 1 - Sort by spell name
---@field ITEM_NAME number 2 - Sort by created item name
---@field DIFFICULTY number 3 - Sort by difficulty, then spell name

---@param professionId? number Skill ID (e.g., 164 for Blacksmithing), or negative for ALL professions (default: -1)
---@param mustFilter? number Bitmask of flags that MUST be set (default: 0)
---@param notFilter? number Bitmask of flags that MUST NOT be set (default: 0)
---@param sort? number Sort type: 1=spell name, 2=item name, 3=difficulty (negative for descending, 0 for unsorted, default: 0)
---@param filterString? string Filter by name (spell/item/reagent if flag 0x08 set), case-insensitive (default: "")
---@param forge? number Forge level for IS_ATTUNED filter (default: 0)
---@param itemClassId? number Item class filter (e.g., 2=weapon, 4=armor), negative to ignore (default: -1)
---@param itemSubClassId? number Item subclass filter, negative to ignore (default: -1)
---@param itemInvTypeId? number Inventory slot filter, negative to ignore (default: -1)
---@return number[]|nil spellIds Array of spell IDs matching the filters, or nil on error
function Custom_GetProfessionRecipes(professionId, mustFilter, notFilter, sort, filterString, forge, itemClassId,
                                     itemSubClassId, itemInvTypeId) end

---@param spellId number The crafting spell ID
---@return number|nil skillId The profession skill ID (e.g., 164 for Blacksmithing)
---@return string|nil spellName The name of the crafting spell
---@return number|nil craftedItemId The item ID created by this recipe (0 if no item, e.g., enchants)
---@return number|nil craftedItemCount How many items are created per craft
---@return number|nil canCraftTimesNow How many times you can craft this right now with current materials
---@return string|nil altVerb Alternative verb (e.g., "Enchant" instead of "Craft")
---@return string|nil headerName The category/header name (may be hex string with 0x prefix if undetermined)
---@return number|nil levelUpDifficulty The difficulty level/color
function Custom_GetProfessionRecipeInfo(spellId) end

---@param itemId number The item ID
---@return number|nil spellId The crafting spell ID that creates this item, or nil if not found
function Custom_GetProfessionRecipeFromCraftedItem(itemId) end

---@param spellId number The crafting spell ID
---@return table<number, number>|nil reagents Table mapping [itemId] = count, or nil if invalid spellId
function Custom_GetProfessionRecipeReagents(spellId) end

---@param spellId number The crafting spell ID
---@param repeatCount? number How many times to craft (default: 1)
---@return number|nil success Returns 1 on success, nil on failure
function Custom_DoProfessionRecipe(spellId, repeatCount) end
