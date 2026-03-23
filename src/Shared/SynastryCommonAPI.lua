---@meta
-- ====================================================================
-- SynastryCommonAPI.lua — Shared Synastria Custom Server API Definitions
-- ====================================================================
-- Type stubs for Synastria 3.3.5 private server custom API extensions
-- that are useful across multiple addons in this workspace.
-- Skillet-specific profession recipe APIs live in SynastryAPI.lua.
-- NEVER loaded by the WoW client (---@meta file, annotation-only).
-- ====================================================================

-- ----------------------------------------------------------------
-- Generic Custom Data Query
-- ----------------------------------------------------------------

--- Query arbitrary custom server-side game data by type and item ID.
--- Known type codes:
---   13 = resource bank item count
---   31 = bounty gold value for item
---@param dataType number The Synastria data-type code
---@param itemId number The item ID to query
---@return number|nil value The queried value, or nil if unavailable
function GetCustomGameData(dataType, itemId) end

-- ----------------------------------------------------------------
-- Attunement APIs
-- ----------------------------------------------------------------

--- Get the highest attunement percentage for an item across all (or a specific) forge tier.
---@param itemId number The item ID
---@param forge? number The forge level to check, or -1 for the highest across all forges (default: -1)
---@return number|nil percentage Attunement percentage (0–100), or nil if not attunable
function GetHighestAttunePct(itemId, forge) end

--- Check attunement progress value.
---@param itemIdOrLink number|string|nil The item ID or item link
---@return number|nil value The attunement progress value
function GetItemAttuneProgress(itemIdOrLink) end

--- Returns true if any variant of an item has been attuned.
---@param itemIdOrLink number|string|nil The item ID or item link
---@return boolean hasAttuned True if any variant has been attuned
function HasAttunedAnyVariant(itemIdOrLink) end

--- Returns the forge level used for attuning the given item.
---@param itemId number The item ID
---@return number|nil forgeLevel The attune forge level
function GetItemAttuneForge(itemId) end

--- Returns non-zero if the current character can attune the item.
---@param itemId number The item ID
---@return number canAttune 0 if cannot attune, >0 if can attune
function CanAttuneItemHelper(itemId) end

--- Returns whether anyone can attune the item.
---@param itemId number The item ID
---@return boolean|number isAttunable True/non-zero if attunable by someone
function IsAttunableBySomeone(itemId) end

-- ----------------------------------------------------------------
-- Item Tag / Classification APIs
-- ----------------------------------------------------------------

--- Returns a bitmask of custom item tags.
---@param itemId number The item ID
---@return number|nil tags Item tags bitmask, or nil if unavailable
function GetItemTagsCustom(itemId) end

-- ----------------------------------------------------------------
-- Bag / Slot Item Inspection APIs
-- ----------------------------------------------------------------

--- Returns 1 if the item in the given bag slot is soulbound.
---@param nativeBagId number The bag ID (0–4 for bags, -1 for bank, etc.)
---@param nativeSlotId number The slot ID within the bag
---@return number|nil isSoulbound 1 if soulbound, nil if not
function Custom_IsItemSoulbound(nativeBagId, nativeSlotId) end

--- Returns 1 if the item is tracked by the equipment manager.
---@param nativeBagId number The bag ID
---@param nativeSlotId number The slot ID
---@return number|nil isInEquipMgr 1 if in equipment manager sets, nil if not
function Custom_IsItemEquipMgr(nativeBagId, nativeSlotId) end

--- Returns the low and high 32-bit parts of an item's GUID.
---@param nativeBagId number The bag ID
---@param nativeSlotId number The slot ID
---@return number|nil lowGuid The low 32 bits of the item GUID
---@return number|nil highGuid The high 32 bits of the item GUID
function Custom_GetItemGuid(nativeBagId, nativeSlotId) end

--- Returns the full item link for the item in the given bag slot.
---@param nativeBagId number The bag ID
---@param nativeSlotId number The slot ID
---@return string|nil itemLink The item link, or nil if the slot is empty
function Custom_GetItemLinkBySlot(nativeBagId, nativeSlotId) end

-- ----------------------------------------------------------------
-- WoW Hyperlink Parsing
-- ----------------------------------------------------------------

--- Extracts the numeric ID and type from any WoW hyperlink.
---@param wowLink string Any WoW hyperlink (item, spell, quest, etc.)
---@return number|nil id The ID extracted from the link
---@return number|nil linkType The object type code
function Custom_GetIdFromLink(wowLink) end

-- ----------------------------------------------------------------
-- Proximity / Location APIs
-- ----------------------------------------------------------------

--- Returns 1 if the player is within `dist` yards of the given map coordinates.
---@param mapId number The map ID to test against
---@param x number X coordinate
---@param y number Y coordinate
---@param z? number Z coordinate (optional; if nil, 2-D distance is used)
---@param dist? number Maximum distance in yards (default: 30)
---@return number|nil isNear 1 if within range, nil otherwise
function Custom_IsPlayerNear(mapId, x, y, z, dist) end

-- ----------------------------------------------------------------
-- Resource Summary UI
-- ----------------------------------------------------------------

--- Opens the server-side resource summary window.
function OpenResourceSummary() end
