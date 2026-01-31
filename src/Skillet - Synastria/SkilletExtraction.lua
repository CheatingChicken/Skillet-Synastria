-- SkilletExtraction.lua: Extraction System for Prospecting and Milling
-- This module handles ore->gem (Prospecting) and herb->pigment (Milling) extractions
-- Unlike conversions (1:1 deterministic), extractions are probabilistic (1:many random)

-- Namespace
Skillet = Skillet or {}

-- ========================================
-- PROSPECTING DATA
-- ========================================
-- Format: [oreItemId] = { skillRequired, commonGems = {id1, id2, ...}, uncommonGems = {id1, id2, ...} }

Skillet.PROSPECTING_DATA = {
	-- VANILLA ORES
	-- Copper Ore (requires skill 20)
	[2770] = {
		skill = 20,
		minQuantity = 5,
		commonGems = {
			818,  -- Tigerseye
			774,  -- Malachite
		},
		uncommonGems = {
			1210, -- Shadowgem
		}
	},
	
	-- Tin Ore (requires skill 50)
	[2771] = {
		skill = 50,
		minQuantity = 5,
		commonGems = {
			1210, -- Shadowgem
			1705, -- Lesser Moonstone
			1206, -- Moss Agate
		},
		uncommonGems = {
			3864, -- Citrine
			1529, -- Jade
			7909, -- Aquamarine
		}
	},
	
	-- Iron Ore (requires skill 125)
	[2772] = {
		skill = 125,
		minQuantity = 5,
		commonGems = {
			3864, -- Citrine
			1705, -- Lesser Moonstone
			1529, -- Jade
		},
		uncommonGems = {
			7909, -- Aquamarine
			7910, -- Star Ruby
		}
	},
	
	-- Mithril Ore (requires skill 175)
	[3858] = {
		skill = 175,
		minQuantity = 5,
		commonGems = {
			3864, -- Citrine
			7910, -- Star Ruby
			7909, -- Aquamarine
		},
		uncommonGems = {
			12800, -- Azerothian Diamond
			12361, -- Blue Sapphire
			12799, -- Large Opal
			12364, -- Huge Emerald
		}
	},
	
	-- Thorium Ore (requires skill 250)
	[10620] = {
		skill = 250,
		minQuantity = 5,
		commonGems = {
			7910,  -- Star Ruby
			12799, -- Large Opal
			12361, -- Blue Sapphire
			12364, -- Huge Emerald
			12800, -- Azerothian Diamond
		},
		uncommonGems = {
			23077, -- Blood Garnet
			21929, -- Flame Spessarite
			23112, -- Golden Draenite
			23079, -- Deep Peridot
			23117, -- Azure Moonstone
			23107, -- Shadow Draenite
		}
	},
	
	-- TBC ORES
	-- Fel Iron Ore (requires skill 275)
	[23424] = {
		skill = 275,
		minQuantity = 5,
		commonGems = {
			23077, -- Blood Garnet
			21929, -- Flame Spessarite
			23079, -- Golden Draenite
			23112, -- Deep Peridot
			23117, -- Azure Moonstone
			23107, -- Shadow Draenite
		},
		uncommonGems = {
			23436, -- Living Ruby
			23439, -- Noble Topaz
			23440, -- Dawnstone
			23437, -- Talasite
			23438, -- Star of Elune
			23441, -- Nightseye
		}
	},
	
	-- Adamantite Ore (requires skill 325)
	[23425] = {
		skill = 325,
		minQuantity = 5,
		commonGems = {
			23077, -- Blood Garnet
			21929, -- Flame Spessarite
			23079, -- Golden Draenite
			23112, -- Deep Peridot
			23117, -- Azure Moonstone
			23107, -- Shadow Draenite
		},
		uncommonGems = {
			23436, -- Living Ruby
			23439, -- Noble Topaz
			23440, -- Dawnstone
			23437, -- Talasite
			23438, -- Star of Elune
			23441, -- Nightseye
		}
	},
	
	-- WRATH ORES
	-- Cobalt Ore (requires skill 350)
	[36909] = {
		skill = 350,
		minQuantity = 5,
		commonGems = {
			36923, -- Chalcedony (blue, common)
			36929, -- Huge Citrine (orange, common)
			36917, -- Bloodstone (red, common)
			36926, -- Shadow Crystal (purple, common)
			36932, -- Dark Jade (green, common)
			36920, -- Sun Crystal (yellow, common)
		},
		uncommonGems = {
			36933, -- Forest Emerald (green, uncommon)
			36918, -- Scarlet Ruby (red, uncommon)
			36930, -- Monarch Topaz (orange, uncommon)
			36921, -- Autumn's Glow (yellow, uncommon)
			36924, -- Sky Sapphire (blue, uncommon)
			36927, -- Twilight Opal (purple, uncommon)
		}
	},
	
	-- Saronite Ore (requires skill 400)
	[36912] = {
		skill = 400,
		minQuantity = 5,
		commonGems = {
			36917, -- Bloodstone (red, common)
			36929, -- Huge Citrine (orange, common)
			36920, -- Sun Crystal (yellow, common)
			36932, -- Dark Jade (green, common)
			36923, -- Chalcedony (blue, common)
			36926, -- Shadow Crystal (purple, common)
		},
		uncommonGems = {
			36918, -- Scarlet Ruby (red, uncommon)
			36930, -- Monarch Topaz (orange, uncommon)
			36921, -- Autumn's Glow (yellow, uncommon)
			36933, -- Forest Emerald (green, uncommon)
			36924, -- Sky Sapphire (blue, uncommon)
			36927, -- Twilight Opal (purple, uncommon)
		}
	},
	
	-- Titanium Ore (requires skill 450)
	-- Produces all Cobalt/Saronite gems PLUS Epic gems
	-- 12 common drops + 6 rare drops = 18 total possible gems!
	[36910] = {
		skill = 450,
		minQuantity = 5,
		commonGems = {
			-- Common quality gems
			36917, -- Bloodstone (red, common)
			36929, -- Huge Citrine (orange, common)
			36920, -- Sun Crystal (yellow, common)
			36932, -- Dark Jade (green, common)
			36923, -- Chalcedony (blue, common)
			36926, -- Shadow Crystal (purple, common)
			-- Uncommon quality gems (also common drops from Titanium)
			36918, -- Scarlet Ruby (red, uncommon)
			36930, -- Monarch Topaz (orange, uncommon)
			36921, -- Autumn's Glow (yellow, uncommon)
			36933, -- Forest Emerald (green, uncommon)
			36924, -- Sky Sapphire (blue, uncommon)
			36927, -- Twilight Opal (purple, uncommon)
		},
		uncommonGems = {
			-- Epic quality gems (rare drops from Titanium)
			36919, -- Cardinal Ruby (red, epic)
			36931, -- Ametrine (orange, epic)
			36922, -- King's Amber (yellow, epic)
			36934, -- Eye of Zul (green, epic)
			36925, -- Majestic Zircon (blue, epic)
			36928, -- Dreadstone (purple, epic)
		}
	},
}

-- ========================================
-- MILLING DATA
-- ========================================
-- Format: [herbItemId] = { skillRequired, commonPigments = {id1, id2}, rarePigment = id }

Skillet.MILLING_DATA = {
	-- VANILLA HERBS (Skill 1)
	-- Peacebloom
	[2447] = {
		skill = 1,
		minQuantity = 5,
		commonPigments = {39151}, -- Alabaster Pigment
		rarePigments = {}
	},
	
	-- Silverleaf
	[765] = {
		skill = 1,
		minQuantity = 5,
		commonPigments = {39151}, -- Alabaster Pigment
		rarePigments = {}
	},
	
	-- Earthroot
	[2449] = {
		skill = 1,
		minQuantity = 5,
		commonPigments = {39151}, -- Alabaster Pigment
		rarePigments = {}
	},
	
	-- VANILLA HERBS (Skill 25)
	-- Tier 2: Dusky Pigment (Common) + Verdant Pigment (Rare)
	-- Briarthorn
	[2450] = {
		skill = 25,
		minQuantity = 5,
		commonPigments = {39334}, -- Dusky Pigment
		rarePigments = {43103}    -- Verdant Pigment
	},
	
	-- Swiftthistle
	[2452] = {
		skill = 25,
		minQuantity = 5,
		commonPigments = {39334}, -- Dusky Pigment
		rarePigments = {43103}    -- Verdant Pigment
	},
	
	-- Bruiseweed
	[2453] = {
		skill = 25,
		minQuantity = 5,
		commonPigments = {39334}, -- Dusky Pigment
		rarePigments = {43103}    -- Verdant Pigment
	},
	
	-- Stranglekelp
	[3820] = {
		skill = 25,
		minQuantity = 5,
		commonPigments = {39334}, -- Dusky Pigment
		rarePigments = {43103}    -- Verdant Pigment
	},
	
	-- Mageroyal
	[785] = {
		skill = 25,
		minQuantity = 5,
		commonPigments = {39334}, -- Dusky Pigment
		rarePigments = {43103}    -- Verdant Pigment
	},
	
	-- VANILLA HERBS (Skill 75)
	-- Tier 3: Golden Pigment (Common) + Burnt Pigment (Rare)
	-- Wild Steelbloom
	[3355] = {
		skill = 75,
		minQuantity = 5,
		commonPigments = {39338}, -- Golden Pigment
		rarePigments = {43104}    -- Burnt Pigment
	},
	
	-- Grave Moss
	[3369] = {
		skill = 75,
		minQuantity = 5,
		commonPigments = {39338}, -- Golden Pigment
		rarePigments = {43104}    -- Burnt Pigment
	},
	
	-- Kingsblood
	[3356] = {
		skill = 75,
		minQuantity = 5,
		commonPigments = {39338}, -- Golden Pigment
		rarePigments = {43104}    -- Burnt Pigment
	},
	
	-- Liferoot
	[3357] = {
		skill = 75,
		minQuantity = 5,
		commonPigments = {39338}, -- Golden Pigment
		rarePigments = {43104}    -- Burnt Pigment
	},
	
	-- VANILLA HERBS (Skill 125)
	-- Fadeleaf
	[3818] = {
		skill = 125,
		minQuantity = 5,
		commonPigments = {39339}, -- Emerald Pigment
		rarePigments = {43105}    -- Indigo Pigment
	},
	
	-- Goldthorn
	[3821] = {
		skill = 125,
		minQuantity = 5,
		commonPigments = {39339}, -- Emerald Pigment
		rarePigments = {43105}    -- Indigo Pigment
	},
	
	-- Khadgar's Whisker
	[3358] = {
		skill = 125,
		minQuantity = 5,
		commonPigments = {39339}, -- Emerald Pigment
		rarePigments = {43105}    -- Indigo Pigment
	},
	
	-- Wintersbite
	[3819] = {
		skill = 125,
		minQuantity = 5,
		commonPigments = {39339}, -- Emerald Pigment
		rarePigments = {43105}    -- Indigo Pigment
	},
	
	-- VANILLA HERBS (Skill 175)
	-- Tier 5: Violet Pigment (Common) + Ruby Pigment (Rare)
	-- Firebloom
	[4625] = {
		skill = 175,
		minQuantity = 5,
		commonPigments = {39340}, -- Violet Pigment
		rarePigments = {43106}    -- Ruby Pigment
	},
	
	-- Purple Lotus
	[8831] = {
		skill = 175,
		minQuantity = 5,
		commonPigments = {39340}, -- Violet Pigment
		rarePigments = {43106}    -- Ruby Pigment
	},
	
	-- Arthas' Tears
	[8836] = {
		skill = 175,
		minQuantity = 5,
		commonPigments = {39340}, -- Violet Pigment
		rarePigments = {43106}    -- Ruby Pigment
	},
	
	-- Sungrass
	[8838] = {
		skill = 175,
		minQuantity = 5,
		commonPigments = {39340}, -- Violet Pigment
		rarePigments = {43106}    -- Ruby Pigment
	},
	
	-- Blindweed
	[8153] = {
		skill = 175,
		minQuantity = 5,
		commonPigments = {39340}, -- Violet Pigment
		rarePigments = {43106}    -- Ruby Pigment
	},
	
	-- Ghost Mushroom
	[8845] = {
		skill = 175,
		minQuantity = 5,
		commonPigments = {39340}, -- Violet Pigment
		rarePigments = {43106}    -- Ruby Pigment
	},
	
	-- Gromsblood
	[8846] = {
		skill = 175,
		minQuantity = 5,
		commonPigments = {39340}, -- Violet Pigment
		rarePigments = {43106}    -- Ruby Pigment
	},
	
	-- VANILLA HERBS (Skill 225)
	-- Tier 6: Silvery Pigment (Common) + Sapphire Pigment (Rare)
	-- Golden Sansam
	[13464] = {
		skill = 225,
		minQuantity = 5,
		commonPigments = {39341}, -- Silvery Pigment
		rarePigments = {43107}    -- Sapphire Pigment
	},
	
	-- Dreamfoil
	[13463] = {
		skill = 225,
		minQuantity = 5,
		commonPigments = {39341}, -- Silvery Pigment
		rarePigments = {43107}    -- Sapphire Pigment
	},
	
	-- Mountain Silversage
	[13465] = {
		skill = 225,
		minQuantity = 5,
		commonPigments = {39341}, -- Silvery Pigment
		rarePigments = {43107}    -- Sapphire Pigment
	},
	
	-- Plaguebloom
	[13466] = {
		skill = 225,
		minQuantity = 5,
		commonPigments = {39341}, -- Silvery Pigment
		rarePigments = {43107}    -- Sapphire Pigment
	},
	
	-- Icecap
	[13467] = {
		skill = 225,
		minQuantity = 5,
		commonPigments = {39341}, -- Silvery Pigment
		rarePigments = {43107}    -- Sapphire Pigment
	},
	
	-- TBC HERBS (Skill 275)
	-- Tier 7: Nether Pigment (Common) + Ebon Pigment (Rare)
	-- Note: All Outland herbs produce these pigments
	
	-- Felweed
	[22785] = {
		skill = 275,
		minQuantity = 5,
		commonPigments = {39342}, -- Nether Pigment
		rarePigments = {43108}    -- Ebon Pigment
	},
	
	-- Dreaming Glory
	[22786] = {
		skill = 275,
		minQuantity = 5,
		commonPigments = {39342}, -- Nether Pigment
		rarePigments = {43108}    -- Ebon Pigment
	},
	
	-- Terocone
	[22787] = {
		skill = 275,
		minQuantity = 5,
		commonPigments = {39342}, -- Nether Pigment
		rarePigments = {43108}    -- Ebon Pigment
	},
	
	-- Ancient Lichen
	[22789] = {
		skill = 275,
		minQuantity = 5,
		commonPigments = {39342}, -- Nether Pigment
		rarePigments = {43108}    -- Ebon Pigment
	},
	
	-- Netherbloom
	[22791] = {
		skill = 275,
		minQuantity = 5,
		commonPigments = {39342}, -- Nether Pigment
		rarePigments = {43108}    -- Ebon Pigment
	},
	
	-- Nightmare Vine
	[22792] = {
		skill = 275,
		minQuantity = 5,
		commonPigments = {39342}, -- Nether Pigment
		rarePigments = {43108}    -- Ebon Pigment
	},
	
	-- Mana Thistle
	[22793] = {
		skill = 275,
		minQuantity = 5,
		commonPigments = {39342}, -- Nether Pigment
		rarePigments = {43108}    -- Ebon Pigment
	},
	
	-- Ragveil
	[22794] = {
		skill = 275,
		minQuantity = 5,
		commonPigments = {39342}, -- Nether Pigment
		rarePigments = {43108}    -- Ebon Pigment
	},
	
	-- WRATH HERBS (Skill 325)
	-- Tier 8: Azure Pigment (Common) + Icy Pigment (Rare)
	-- Note: All Northrend herbs produce these pigments
	
	-- Goldclover
	[36901] = {
		skill = 325,
		minQuantity = 5,
		commonPigments = {39343}, -- Azure Pigment
		rarePigments = {43109}    -- Icy Pigment
	},
	
	-- Tiger Lily
	[36904] = {
		skill = 325,
		minQuantity = 5,
		commonPigments = {39343}, -- Azure Pigment
		rarePigments = {43109}    -- Icy Pigment
	},
	
	-- Talandra's Rose
	[36907] = {
		skill = 325,
		minQuantity = 5,
		commonPigments = {39343}, -- Azure Pigment
		rarePigments = {43109}    -- Icy Pigment
	},
	
	-- Lichbloom
	[36905] = {
		skill = 325,
		minQuantity = 5,
		commonPigments = {39343}, -- Azure Pigment
		rarePigments = {43109}    -- Icy Pigment
	},
	
	-- Icethorn
	[36906] = {
		skill = 325,
		minQuantity = 5,
		commonPigments = {39343}, -- Azure Pigment
		rarePigments = {43109}    -- Icy Pigment
	},
	
	-- Adder's Tongue
	[36903] = {
		skill = 325,
		minQuantity = 5,
		commonPigments = {39343}, -- Azure Pigment
		rarePigments = {43109}    -- Icy Pigment
	},
}

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

-- Get prospecting information for an ore
function Skillet:GetProspectingInfo(oreId)
	return self.PROSPECTING_DATA[oreId]
end

-- Get milling information for a herb
function Skillet:GetMillingInfo(herbId)
	return self.MILLING_DATA[herbId]
end

-- Check if item can be prospected
function Skillet:CanProspect(itemId)
	return self.PROSPECTING_DATA[itemId] ~= nil
end

-- Check if item can be milled
function Skillet:CanMill(itemId)
	return self.MILLING_DATA[itemId] ~= nil
end

-- Get all possible results from prospecting an ore
function Skillet:GetProspectingResults(oreId)
	local data = self.PROSPECTING_DATA[oreId]
	if not data then return nil end
	
	local results = {}
	
	-- Add common gems
	if data.commonGems then
		for _, gemId in ipairs(data.commonGems) do
			table.insert(results, {itemId = gemId, rarity = "common"})
		end
	end
	
	-- Add uncommon gems
	if data.uncommonGems then
		for _, gemId in ipairs(data.uncommonGems) do
			table.insert(results, {itemId = gemId, rarity = "uncommon"})
		end
	end
	
	return results
end

-- Get all possible results from milling a herb
function Skillet:GetMillingResults(herbId)
	local data = self.MILLING_DATA[herbId]
	if not data then return nil end
	
	local results = {}
	
	-- Add common pigments
	if data.commonPigments then
		for _, pigmentId in ipairs(data.commonPigments) do
			table.insert(results, {itemId = pigmentId, rarity = "common"})
		end
	end
	
	-- Add rare pigments
	if data.rarePigments then
		for _, pigmentId in ipairs(data.rarePigments) do
			table.insert(results, {itemId = pigmentId, rarity = "rare"})
		end
	end
	
	return results
end

Skillet:Print("SkilletExtraction module loaded")
