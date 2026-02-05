-- SkilletItemIDValidator.lua
-- Validates all item IDs used in Skillet data by looking them up in-game

Skillet = Skillet or {}

-- Comprehensive list of all items used in Skillet data
-- Format: ["Item Name"] = expectedID (or 0 if we need to find it)
Skillet.ITEMS_TO_VALIDATE = {
	-- PROSPECTING GEMS
	-- Vanilla Common
	["Tigerseye"] = 818,
	["Malachite"] = 774,
	["Shadowgem"] = 1210,
	["Lesser Moonstone"] = 1705,
	["Moss Agate"] = 1206,
	-- Vanilla Uncommon
	["Citrine"] = 3864,
	["Jade"] = 1529,
	["Aquamarine"] = 7909,
	["Star Ruby"] = 7910,
	-- Vanilla Rare
	["Azerothian Diamond"] = 12800,
	["Blue Sapphire"] = 12361,
	["Large Opal"] = 12799,
	["Huge Emerald"] = 12364,
	-- TBC Common
	["Blood Garnet"] = 23077,
	["Flame Spessarite"] = 21929,
	["Golden Draenite"] = 23112, -- SWAPPED
	["Deep Peridot"] = 23079, -- SWAPPED
	["Azure Moonstone"] = 23117,
	["Shadow Draenite"] = 23107,
	-- TBC Uncommon
	["Living Ruby"] = 23436,
	["Noble Topaz"] = 23439,
	["Dawnstone"] = 23440,
	["Talasite"] = 23437,
	["Star of Elune"] = 23438,
	["Nightseye"] = 23441,
	-- Wrath Common
	["Chalcedony"] = 36923,
	["Bloodstone"] = 36917,
	["Dark Jade"] = 36932,
	["Shadow Crystal"] = 36926,
	["Sun Crystal"] = 36920,
	["Huge Citrine"] = 36929, -- Was showing as Eye of Zul at 36929
	-- Wrath Uncommon
	["Scarlet Ruby"] = 36918,
	["Autumn's Glow"] = 36921,
	["Forest Emerald"] = 36933,
	["Twilight Opal"] = 36927,
	["Monarch Topaz"] = 36930,
	["Sky Sapphire"] = 36924,
	-- Wrath Rare (Epic)
	["Cardinal Ruby"] = 36919,
	["Ametrine"] = 36931,
	["King's Amber"] = 36922,
	["Majestic Zircon"] = 36925, -- Was at 36928 which is Dreadstone
	["Dreadstone"] = 36928,   -- Was at 36934 which is Eye of Zul
	["Eye of Zul"] = 36934,   -- Was at 36929 which is Huge Citrine

	-- MILLING PIGMENTS (CORRECTED based on game lookup)
	-- Vanilla Tier 1
	["Alabaster Pigment"] = 39151,
	["Dusky Pigment"] = 39334,
	-- Vanilla Tier 2
	["Golden Pigment"] = 39338,
	["Emerald Pigment"] = 39339,
	-- Vanilla Tier 3
	["Violet Pigment"] = 39340,
	["Silvery Pigment"] = 39341,
	-- Vanilla Tier 4
	["Burnt Pigment"] = 43104,
	["Indigo Pigment"] = 43105,
	["Ruby Pigment"] = 43106,
	-- Vanilla Tier 5
	["Sapphire Pigment"] = 43107,
	-- TBC
	["Nether Pigment"] = 39342,
	["Ebon Pigment"] = 43108,
	-- Wrath
	["Azure Pigment"] = 39343,
	["Icy Pigment"] = 43109,

	-- CRYSTALLIZED/ETERNAL ELEMENTS (CORRECTED)
	["Crystallized Life"] = 37704,
	["Crystallized Shadow"] = 37703,
	["Crystallized Earth"] = 37701,
	["Crystallized Fire"] = 37702,
	["Crystallized Water"] = 37705,
	["Crystallized Air"] = 37700,
	["Eternal Life"] = 35625,
	["Eternal Shadow"] = 35627,
	["Eternal Earth"] = 35624,
	["Eternal Fire"] = 36860,
	["Eternal Water"] = 35622,
	["Eternal Air"] = 35623,

	-- INKS (for reference, not used in extraction but might be confused)
	["Moonglow Ink"] = 39469,
	["Midnight Ink"] = 39774,
	["Lion's Ink"] = 43116,
	["Jadefire Ink"] = 43117,
	["Celestial Ink"] = 43118,
	["Shimmering Ink"] = 43119,
	["Ethereal Ink"] = 43120,
	["Darkflame Ink"] = 43121,
	["Ink of the Sea"] = 43126,
	["Snowfall Ink"] = 43127,
}

-- Warm up the item cache by querying all IDs
function Skillet:WarmItemCache()
	DEFAULT_CHAT_FRAME:AddMessage("=== WARMING ITEM CACHE ===", 1, 0.82, 0)
	DEFAULT_CHAT_FRAME:AddMessage("Querying server for all item data...", 1, 1, 1)

	local count = 0
	for itemName, itemID in pairs(self.ITEMS_TO_VALIDATE) do
		if itemID > 0 then
			-- Create item link to force server query
			local itemLink = "\124Hitem:" .. itemID .. "\124h[" .. itemName .. "]\124h"
			GetItemInfo(itemID)
			count = count + 1
		end
	end

	DEFAULT_CHAT_FRAME:AddMessage("Queried " .. count .. " items. Wait 2-3 seconds then run /svalidate", 0.5, 1, 0.5)
end

-- Slash command to look up all item IDs
function Skillet:ValidateItemIDs()
	DEFAULT_CHAT_FRAME:AddMessage("=== SKILLET ITEM ID LOOKUP ===", 1, 0.82, 0)
	DEFAULT_CHAT_FRAME:AddMessage("Querying item IDs to populate cache...", 1, 1, 1)
	DEFAULT_CHAT_FRAME:AddMessage("Format: Expected_Name [ID] -> Actual_Name", 1, 1, 1)
	DEFAULT_CHAT_FRAME:AddMessage(" ", 1, 1, 1)

	-- Sort items by expected ID for easier reading
	local sortedItems = {}
	for itemName, expectedID in pairs(self.ITEMS_TO_VALIDATE) do
		if expectedID > 0 then
			table.insert(sortedItems, { name = itemName, id = expectedID })
		end
	end
	table.sort(sortedItems, function(a, b) return a.id < b.id end)

	for _, item in ipairs(sortedItems) do
		local expectedName = item.name
		local itemID = item.id

		-- Query by ID to get the actual name
		local actualName = GetItemInfo(itemID)

		if actualName then
			local match = (actualName == expectedName) and "[OK]" or "[MISMATCH]"
			DEFAULT_CHAT_FRAME:AddMessage(string.format("%s %s [%d] -> %s", match, expectedName, itemID, actualName), 1,
				1, 1)
		else
			DEFAULT_CHAT_FRAME:AddMessage(string.format("? %s [%d] -> CACHE MISS", expectedName, itemID), 1, 0.5, 0.5)
		end
	end

	DEFAULT_CHAT_FRAME:AddMessage(" ", 1, 1, 1)
	DEFAULT_CHAT_FRAME:AddMessage("=== LOOKUP COMPLETE ===", 1, 0.82, 0)
	DEFAULT_CHAT_FRAME:AddMessage("If you see CACHE MISS, wait a moment and run /svalidate again", 0.5, 1, 0.5)
end

-- List items that need manual lookup
function Skillet:ListMissingItems()
	DEFAULT_CHAT_FRAME:AddMessage("=== ITEMS NEEDING MANUAL LOOKUP ===", 1, 0.82, 0)
	DEFAULT_CHAT_FRAME:AddMessage(" ", 1, 1, 1)

	local missing = {}

	for itemName, expectedID in pairs(self.ITEMS_TO_VALIDATE) do
		if expectedID == 0 then
			table.insert(missing, itemName .. " - UNKNOWN ID")
		else
			local actualName = GetItemInfo(expectedID)
			if not actualName then
				table.insert(missing, itemName .. " [" .. expectedID .. "] - CACHE MISS")
			end
		end
	end

	table.sort(missing)

	if #missing == 0 then
		DEFAULT_CHAT_FRAME:AddMessage("All items found!", 0.5, 1, 0.5)
	else
		DEFAULT_CHAT_FRAME:AddMessage("Please check these items in crafting menus:", 1, 1, 1)
		DEFAULT_CHAT_FRAME:AddMessage(" ", 1, 1, 1)
		for _, item in ipairs(missing) do
			DEFAULT_CHAT_FRAME:AddMessage("  " .. item, 1, 1, 0.5)
		end
	end

	DEFAULT_CHAT_FRAME:AddMessage(" ", 1, 1, 1)
	DEFAULT_CHAT_FRAME:AddMessage("=== TOTAL MISSING: " .. #missing .. " ===", 1, 0.82, 0)
end

-- Register slash command
SLASH_SKILLETVALIDATE1 = "/skilletvalidate"
SLASH_SKILLETVALIDATE2 = "/svalidate"
SlashCmdList["SKILLETVALIDATE"] = function(msg)
	Skillet:ValidateItemIDs()
end

SLASH_SKILLETMISSING1 = "/skilletmissing"
SLASH_SKILLETMISSING2 = "/smissing"
SlashCmdList["SKILLETMISSING"] = function(msg)
	Skillet:ListMissingItems()
end

SLASH_SKILLETWARM1 = "/skilletwarm"
SLASH_SKILLETWARM2 = "/swarm"
SlashCmdList["SKILLETWARM"] = function(msg)
	Skillet:WarmItemCache()
end

DEFAULT_CHAT_FRAME:AddMessage("Skillet Item Validator loaded. /svalidate | /smissing | /swarm (cache)", 0.5, 1, 0.5)
