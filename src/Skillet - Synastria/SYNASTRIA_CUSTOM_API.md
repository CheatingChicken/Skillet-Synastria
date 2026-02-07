# Synastria Custom Server API Documentation

This document describes the custom API functions added by the Synastria server that extend the standard WoW 3.3.5 API.

---

## Table of Contents

1. [Attunement APIs](#attunement-apis)
2. [Item Inspection APIs](#item-inspection-apis)
3. [Link Parsing APIs](#link-parsing-apis)
4. [Location/Position APIs](#locationposition-apis)
5. [Profession Recipe APIs](#profession-recipe-apis)

---

## Attunement APIs

### `GetHighestAttunePct(itemId, [forge])`

Gets the highest attunement percentage for an item across all variants.

**Parameters:**
- `itemId` (number) - The item ID to check
- `forge` (number, optional) - The forge level to check, or -1 for highest across all forges (default: -1)

**Returns:**
- `percentage` (number|nil) - The highest attunement percentage (0-100), or nil if not attunable

**Example:**
```lua
-- Get highest attunement across all forges
local pct = GetHighestAttunePct(12345)
if pct then
    print("Highest attunement: " .. pct .. "%")
end

-- Get attunement for specific forge level
local pct = GetHighestAttunePct(12345, 5)
```

**Use Cases:**
- Checking attunement progress for affix items (each affix has its own percentage)
- Determining if an item is worth attuning further
- Filtering recipes by attunement status

---

## Item Inspection APIs

These APIs work with bag/slot positions (native WoW indexing).

### Bag ID Reference
- `0-4` - Player bags (0 = backpack)
- `-1` - Bank
- `-2` - Bank bags

### `Custom_IsItemSoulbound(nativeBagId, nativeSlotId)`

Check if an item in a specific bag slot is soulbound.

**Parameters:**
- `nativeBagId` (number) - The bag ID
- `nativeSlotId` (number) - The slot ID within the bag

**Returns:**
- `isSoulbound` (number|nil) - Returns 1 if soulbound, nil if not

**Example:**
```lua
-- Check if item in backpack slot 5 is soulbound
if Custom_IsItemSoulbound(0, 5) then
    print("Item is soulbound")
end
```

---

### `Custom_IsItemEquipMgr(nativeBagId, nativeSlotId)`

Check if an item is part of any equipment manager sets.

**Parameters:**
- `nativeBagId` (number) - The bag ID
- `nativeSlotId` (number) - The slot ID within the bag

**Returns:**
- `isInEquipMgr` (number|nil) - Returns 1 if in equipment manager, nil if not

**Example:**
```lua
-- Check if item is in equipment manager before destroying/trading
if Custom_IsItemEquipMgr(0, 5) then
    print("Warning: This item is in an equipment set!")
end
```

---

### `Custom_GetItemGuid(nativeBagId, nativeSlotId)`

Get the unique GUID for an item in a specific bag slot.

**Parameters:**
- `nativeBagId` (number) - The bag ID
- `nativeSlotId` (number) - The slot ID within the bag

**Returns:**
- `lowGuid` (number|nil) - The low 32 bits of the GUID
- `highGuid` (number|nil) - The high 32 bits of the GUID

**Example:**
```lua
local lowGuid, highGuid = Custom_GetItemGuid(0, 5)
if lowGuid then
    print(string.format("Item GUID: %08X%08X", highGuid, lowGuid))
end
```

**Use Cases:**
- Tracking specific item instances
- Comparing if two item slots contain the same physical item
- Database/logging operations

---

### `Custom_GetItemLinkBySlot(nativeBagId, nativeSlotId)`

Get the item link for an item in a specific bag slot.

**Parameters:**
- `nativeBagId` (number) - The bag ID
- `nativeSlotId` (number) - The slot ID within the bag

**Returns:**
- `itemLink` (string|nil) - The item link, or nil if slot is empty

**Example:**
```lua
local link = Custom_GetItemLinkBySlot(0, 5)
if link then
    print("Item: " .. link)
end
```

**Note:** More efficient than `GetContainerItemLink()` for direct bag/slot access.

---

## Link Parsing APIs

### `Custom_GetIdFromLink(wowLink)`

Extract the ID and object type from any WoW hyperlink.

**Parameters:**
- `wowLink` (string) - Any link that `GameTooltip:SetHyperlink()` accepts

**Returns:**
- `id` (number|nil) - The ID extracted from the link
- `type` (number|nil) - The object type

**Supported Link Types:**
- Item links: `|cff9d9d9d|Hitem:12345...|h[Item Name]|h|r`
- Spell links: `|cffffd000|Hspell:12345|h[Spell Name]|h|r`
- Quest links: `|cffffd000|Hquest:12345|h[Quest Name]|h|r`
- Achievement links: `|cffffff00|Hachievement:12345|h[Achievement]|h|r`
- And more...

**Example:**
```lua
local itemLink = "|cff9d9d9d|Hitem:12345:0:0:0:0:0:0:0|h[Poor Item]|h|r"
local id, type = Custom_GetIdFromLink(itemLink)
if id then
    print("Item ID: " .. id)
    print("Object Type: " .. type)
end

-- Works with any link type
local spellId, spellType = Custom_GetIdFromLink("|cffffd000|Hspell:12345|h[Fireball]|h|r")
```

---

## Location/Position APIs

### `Custom_IsPlayerNear(mapId, x, y, [z], [dist])`

Check if the player is within a certain distance of a location.

**Parameters:**
- `mapId` (number) - The map ID to check
- `x` (number) - The X coordinate
- `y` (number) - The Y coordinate
- `z` (number, optional) - The Z coordinate (if nil, checks 2D distance only)
- `dist` (number, optional) - Maximum distance in yards (default: 30)

**Returns:**
- `isNear` (number|nil) - Returns 1 if within distance, nil if not

**Example:**
```lua
-- Check if player is near a specific location (2D)
if Custom_IsPlayerNear(0, 1234.5, 5678.9) then
    print("You are near the location!")
end

-- Check 3D distance with custom range
if Custom_IsPlayerNear(0, 1234.5, 5678.9, 100.0, 50) then
    print("Within 50 yards!")
end
```

**Use Cases:**
- Proximity-based quest checks
- Location-based features
- Anti-cheat validation

---

## Profession Recipe APIs

### Filter Flags

```lua
-- mustFilter / notFilter bitflags
local FILTER_ATTUNABLE_CUR_CHAR = 0x01  -- Recipe creates item attunable by current character
local FILTER_UNUSED = 0x02               -- Reserved/unused
local FILTER_ATTUNABLE_BY_SOMEONE = 0x04 -- Recipe creates item attunable by someone
local FILTER_REAGENTS = 0x08             -- String filter also checks reagent names
local FILTER_HAVE_ITEM = 0x10            -- Have created item in inventory
local FILTER_HAVE_MATS = 0x20            -- Have materials to craft
local FILTER_IS_ATTUNED = 0x40           -- Recipe creates attuned item (requires forge param)
```

### Sort Types

```lua
local SORT_SPELL_NAME = 1   -- Sort by spell name (ascending/descending)
local SORT_ITEM_NAME = 2    -- Sort by created item name
local SORT_DIFFICULTY = 3   -- Sort by difficulty, then spell name (ascending regardless)
```

---

### `Custom_GetProfessionRecipes([professionId], [mustFilter], [notFilter], [sort], [filterString], [forge], [itemClassId], [itemSubClassId], [itemInvTypeId])`

Get an array of spell IDs for profession recipes with advanced filtering.

**Parameters:**
- `professionId` (number, optional) - Skill ID (e.g., 164 for Blacksmithing), negative for ALL professions (default: -1)
- `mustFilter` (number, optional) - Bitmask of flags that MUST be set (default: 0)
- `notFilter` (number, optional) - Bitmask of flags that MUST NOT be set (default: 0)
- `sort` (number, optional) - Sort type: 1-3, negative for descending, 0 for unsorted (default: 0)
- `filterString` (string, optional) - Filter by name (case-insensitive) (default: "")
- `forge` (number, optional) - Forge level for IS_ATTUNED filter (default: 0)
- `itemClassId` (number, optional) - Item class filter (2=weapon, 4=armor), negative to ignore (default: -1)
- `itemSubClassId` (number, optional) - Item subclass filter, negative to ignore (default: -1)
- `itemInvTypeId` (number, optional) - Inventory slot filter, negative to ignore (default: -1)

**Returns:**
- `spellIds` (table|nil) - Array of spell IDs, or nil on error

**Examples:**

```lua
-- Get all Blacksmithing recipes
local recipes = Custom_GetProfessionRecipes(164)

-- Get all recipes you can craft right now (have materials)
local craftable = Custom_GetProfessionRecipes(-1, 0x20)

-- Get all attunable weapons you can craft
local FILTER_ATTUNABLE = 0x01
local FILTER_HAVE_MATS = 0x20
local CLASS_WEAPON = 2
local recipes = Custom_GetProfessionRecipes(
    -1,              -- All professions
    FILTER_ATTUNABLE + FILTER_HAVE_MATS,  -- Must be attunable AND have mats
    0,               -- No exclusions
    1,               -- Sort by spell name ascending
    "",              -- No string filter
    0,               -- No forge filter
    CLASS_WEAPON     -- Weapons only
)

-- Find recipes with "Sword" in the name or reagents
local FILTER_REAGENTS = 0x08
local swordRecipes = Custom_GetProfessionRecipes(
    164,             -- Blacksmithing
    FILTER_REAGENTS, -- Include reagent name searching
    0,
    0,
    "Sword"          -- Filter string
)

-- Get already-attuned items for forge level 5
local FILTER_IS_ATTUNED = 0x40
local attuned = Custom_GetProfessionRecipes(-1, FILTER_IS_ATTUNED, 0, 0, "", 5)
```

---

### `Custom_GetProfessionRecipeInfo(spellId)`

Get detailed information about a profession recipe.

**Parameters:**
- `spellId` (number) - The crafting spell ID

**Returns:**
- `skillId` (number|nil) - The profession skill ID
- `spellName` (string|nil) - The crafting spell name
- `craftedItemId` (number|nil) - Item ID created (0 for enchants/non-items)
- `craftedItemCount` (number|nil) - How many items created per craft
- `canCraftTimesNow` (number|nil) - How many you can craft right now
- `altVerb` (string|nil) - Alternative verb (e.g., "Enchant")
- `headerName` (string|nil) - Category name (may be hex if undetermined)
- `levelUpDifficulty` (number|nil) - Difficulty level/color

**Example:**
```lua
local skillId, name, itemId, count, canCraft, verb, header, difficulty = 
    Custom_GetProfessionRecipeInfo(12345)

if skillId then
    print("Recipe: " .. name)
    print("Creates: " .. count .. "x Item ID " .. itemId)
    print("Can craft: " .. canCraft .. " times")
    print("Category: " .. header)
end
```

---

### `Custom_GetProfessionRecipeFromCraftedItem(itemId)`

Find the crafting spell that creates a specific item.

**Parameters:**
- `itemId` (number) - The item ID

**Returns:**
- `spellId` (number|nil) - The crafting spell ID, or nil if not found

**Example:**
```lua
-- Find how to craft Titansteel Bar (item ID 37663)
local spellId = Custom_GetProfessionRecipeFromCraftedItem(37663)
if spellId then
    print("Crafted by spell ID: " .. spellId)
    -- Now get full recipe info
    local skillId, name = Custom_GetProfessionRecipeInfo(spellId)
    print("Recipe: " .. name)
end
```

**Use Cases:**
- Reverse lookup: "What recipe makes this item?"
- Shopping list generation
- Crafting path analysis

---

### `Custom_GetProfessionRecipeReagents(spellId)`

Get the reagents required for a recipe.

**Parameters:**
- `spellId` (number) - The crafting spell ID

**Returns:**
- `reagents` (table|nil) - Table mapping `[itemId] = count`, or nil if invalid

**Example:**
```lua
local reagents = Custom_GetProfessionRecipeReagents(12345)
if reagents then
    for itemId, count in pairs(reagents) do
        local itemName = GetItemInfo(itemId)
        print("Requires: " .. count .. "x " .. (itemName or "Item #" .. itemId))
    end
end
```

**Note:** Use `pairs()` to iterate, not `ipairs()`.

---

### `Custom_DoProfessionRecipe(spellId, [repeatCount])`

Craft a recipe using its spell ID.

**Parameters:**
- `spellId` (number) - The crafting spell ID
- `repeatCount` (number, optional) - How many times to craft (default: 1)

**Returns:**
- `success` (number|nil) - Returns 1 on success, nil on failure

**Example:**
```lua
-- Craft once
if Custom_DoProfessionRecipe(12345) then
    print("Crafting started!")
end

-- Craft 5 times
if Custom_DoProfessionRecipe(12345, 5) then
    print("Crafting 5 items!")
end
```

**Important Notes:**
- Works independently of the tradeskill window being open
- May bypass certain restrictions (testing required)
- Returns immediately (nil return = client-side)
- Server validates materials, cooldowns, etc.

**Potential Advantages Over `DoTradeSkill()`:**
- ✅ Can specify spell ID directly (no recipe index needed)
- ✅ May work without tradeskill window open
- ✅ Potentially different cooldown handling
- ⚠️ Behavior differences require testing

---

## Complete Example: Advanced Recipe Finder

```lua
-- Find all craftable armor pieces you can attune at forge level 10
local FILTER_ATTUNABLE = 0x01
local FILTER_HAVE_MATS = 0x20
local CLASS_ARMOR = 4

-- Get filtered recipes
local recipes = Custom_GetProfessionRecipes(
    -1,                              -- All professions
    FILTER_ATTUNABLE + FILTER_HAVE_MATS,
    0,
    3,                               -- Sort by difficulty
    "",
    10,                              -- Forge level 10
    CLASS_ARMOR                      -- Armor only
)

if recipes then
    print("Found " .. #recipes .. " craftable attunable armor pieces:")
    
    for _, spellId in ipairs(recipes) do
        local skillId, name, itemId, count, canCraft = 
            Custom_GetProfessionRecipeInfo(spellId)
        
        if name and itemId then
            local itemName = GetItemInfo(itemId)
            local reagents = Custom_GetProfessionRecipeReagents(spellId)
            
            print("---")
            print("Recipe: " .. name)
            print("Creates: " .. count .. "x " .. (itemName or itemId))
            print("Can craft: " .. canCraft .. " times")
            
            if reagents then
                print("Requires:")
                for reagentId, reagentCount in pairs(reagents) do
                    local reagentName = GetItemInfo(reagentId)
                    print("  " .. reagentCount .. "x " .. (reagentName or reagentId))
                end
            end
        end
    end
end
```

---

## Integration Notes

### Type Definitions
All these APIs have been added to `WoWAPI.lua` with full LuaLS type annotations for autocompletion and type checking.

### Testing Functions
The following test functions are available in Skillet for `Custom_DoProfessionRecipe`:
- `/script Skillet:TestCustomDoProfessionRecipe()` - Check if function exists
- `/script Skillet:TestServerSideBehavior(recipeIndex)` - Test actual behavior
- `/script Skillet:MonitorCraftCalls(true)` - Monitor all craft calls

### Performance Considerations
- Server-side functions may have different performance characteristics
- Batch operations when possible
- Cache results if appropriate

---

## Changelog

**2026-02-07** - Initial documentation of custom Synastria APIs
