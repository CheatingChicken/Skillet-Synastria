-- ProspectingData.lua: Prospecting ore->gem loot table database
-- This file contains all prospecting data (ore extraction to gems)
-- Format: [oreItemId] = { skill, minQuantity, commonGems, uncommonGems, rareGems }

-- Namespace
Skillet = Skillet or {}

-- Log that we're loading
SkilletLog:Add("ProspectingData.lua: Starting load...", "INFO")

--#region Ores - Vanilla
local COPPER_ORE = 2770
local TIN_ORE = 2771
local IRON_ORE = 2772
local MITHRIL_ORE = 3858
local THORIUM_ORE = 10620
--#endregion

--#region Ores - TBC
local FEL_IRON_ORE = 23424
local ADAMANTITE_ORE = 23425
--#endregion

--#region Ores - Wrath
local COBALT_ORE = 36909
local SARONITE_ORE = 36912
local TITANIUM_ORE = 36910
--#endregion

--#region Gems - Vanilla Common
local TIGERSEYE = 818
local MALACHITE = 774
local SHADOWGEM = 1210
local LESSER_MOONSTONE = 1705
local MOSS_AGATE = 1206
local CITRINE = 3864
local JADE = 1529
local AQUAMARINE = 7909
local STAR_RUBY = 7910
--#endregion

--#region Gems - Vanilla Uncommon
local AZEROTHIAN_DIAMOND = 12800
local BLUE_SAPPHIRE = 12361
local LARGE_OPAL = 12799
local HUGE_EMERALD = 12364
--#endregion

--#region Gems - TBC Common
local BLOOD_GARNET = 23077
local FLAME_SPESSARITE = 21929
local GOLDEN_DRAENITE = 23079
local DEEP_PERIDOT = 23112
local AZURE_MOONSTONE = 23117
local SHADOW_DRAENITE = 23107
--#endregion

--#region Gems - TBC Uncommon
local LIVING_RUBY = 23436
local NOBLE_TOPAZ = 23439
local DAWNSTONE = 23440
local TALASITE = 23437
local STAR_OF_ELUNE = 23438
local NIGHTSEYE = 23441
--#endregion

--#region Gems - Wrath Common (Red/Orange/Yellow/Green/Blue/Purple)
local BLOODSTONE = 36917
local HUGE_CITRINE = 36929
local SUN_CRYSTAL = 36920
local DARK_JADE = 36932
local CHALCEDONY = 36923
local SHADOW_CRYSTAL = 36926
--#endregion

--#region Gems - Wrath Uncommon
local SCARLET_RUBY = 36918
local MONARCH_TOPAZ = 36930
local AUTUMNS_GLOW = 36921
local FOREST_EMERALD = 36933
local SKY_SAPPHIRE = 36924
local TWILIGHT_OPAL = 36927
--#endregion

--#region Gems - Wrath Rare/Epic
local CARDINAL_RUBY = 36919
local AMETRINE = 36931
local KINGS_AMBER = 36922
local EYE_OF_ZUL = 36934
local MAJESTIC_ZIRCON = 36925
local DREADSTONE = 36928
--#endregion

-- ========================================
-- PROSPECTING DATA
-- ========================================

Skillet.PROSPECTING_DATA = {
    -- VANILLA ORES
    -- Copper Ore (requires skill 20)
    [COPPER_ORE] = {
        skill = 20,
        minQuantity = 5,
        commonGems = {
            TIGERSEYE,
            MALACHITE,
        },
        uncommonGems = {
            SHADOWGEM,
        }
    },

    -- Tin Ore (requires skill 50)
    [TIN_ORE] = {
        skill = 50,
        minQuantity = 5,
        commonGems = {
            SHADOWGEM,
            LESSER_MOONSTONE,
            MOSS_AGATE,
        },
        uncommonGems = {
            CITRINE,
            JADE,
            AQUAMARINE,
        }
    },

    -- Iron Ore (requires skill 125)
    [IRON_ORE] = {
        skill = 125,
        minQuantity = 5,
        commonGems = {
            CITRINE,
            LESSER_MOONSTONE,
            JADE,
        },
        uncommonGems = {
            AQUAMARINE,
            STAR_RUBY,
        }
    },

    -- Mithril Ore (requires skill 175)
    [MITHRIL_ORE] = {
        skill = 175,
        minQuantity = 5,
        commonGems = {
            CITRINE,
            STAR_RUBY,
            AQUAMARINE,
        },
        uncommonGems = {
            AZEROTHIAN_DIAMOND,
            BLUE_SAPPHIRE,
            LARGE_OPAL,
            HUGE_EMERALD,
        }
    },

    -- Thorium Ore (requires skill 250)
    [THORIUM_ORE] = {
        skill = 250,
        minQuantity = 5,
        commonGems = {
            STAR_RUBY,
            LARGE_OPAL,
            BLUE_SAPPHIRE,
            HUGE_EMERALD,
            AZEROTHIAN_DIAMOND,
        },
        uncommonGems = {
            BLOOD_GARNET,
            FLAME_SPESSARITE,
            GOLDEN_DRAENITE,
            DEEP_PERIDOT,
            AZURE_MOONSTONE,
            SHADOW_DRAENITE,
        }
    },

    -- TBC ORES
    -- Fel Iron Ore (requires skill 275)
    [FEL_IRON_ORE] = {
        skill = 275,
        minQuantity = 5,
        commonGems = {
            BLOOD_GARNET,
            FLAME_SPESSARITE,
            GOLDEN_DRAENITE,
            DEEP_PERIDOT,
            AZURE_MOONSTONE,
            SHADOW_DRAENITE,
        },
        uncommonGems = {
            LIVING_RUBY,
            NOBLE_TOPAZ,
            DAWNSTONE,
            TALASITE,
            STAR_OF_ELUNE,
            NIGHTSEYE,
        }
    },

    -- Adamantite Ore (requires skill 325)
    [ADAMANTITE_ORE] = {
        skill = 325,
        minQuantity = 5,
        commonGems = {
            BLOOD_GARNET,
            FLAME_SPESSARITE,
            GOLDEN_DRAENITE,
            DEEP_PERIDOT,
            AZURE_MOONSTONE,
            SHADOW_DRAENITE,
        },
        uncommonGems = {
            LIVING_RUBY,
            NOBLE_TOPAZ,
            DAWNSTONE,
            TALASITE,
            STAR_OF_ELUNE,
            NIGHTSEYE,
        }
    },

    -- WRATH ORES
    -- Cobalt Ore (requires skill 350)
    [COBALT_ORE] = {
        skill = 350,
        minQuantity = 5,
        commonGems = {
            CHALCEDONY,
            HUGE_CITRINE,
            BLOODSTONE,
            SHADOW_CRYSTAL,
            DARK_JADE,
            SUN_CRYSTAL,
        },
        uncommonGems = {
            FOREST_EMERALD,
            SCARLET_RUBY,
            MONARCH_TOPAZ,
            AUTUMNS_GLOW,
            SKY_SAPPHIRE,
            TWILIGHT_OPAL,
        }
    },

    -- Saronite Ore (requires skill 400)
    [SARONITE_ORE] = {
        skill = 400,
        minQuantity = 5,
        commonGems = {
            BLOODSTONE,
            HUGE_CITRINE,
            SUN_CRYSTAL,
            DARK_JADE,
            CHALCEDONY,
            SHADOW_CRYSTAL,
        },
        uncommonGems = {
            SCARLET_RUBY,
            MONARCH_TOPAZ,
            AUTUMNS_GLOW,
            FOREST_EMERALD,
            SKY_SAPPHIRE,
            TWILIGHT_OPAL,
        }
    },

    -- Titanium Ore (requires skill 450)
    -- Produces 6 uncommon + 6 rare + 6 epic gems = 18 total possible gems!
    [TITANIUM_ORE] = {
        skill = 450,
        minQuantity = 5,
        commonGems = {
            -- Uncommon quality gems (common drops from Titanium)
            SCARLET_RUBY,
            MONARCH_TOPAZ,
            AUTUMNS_GLOW,
            FOREST_EMERALD,
            SKY_SAPPHIRE,
            TWILIGHT_OPAL,
        },
        uncommonGems = {
            -- Rare quality gems (uncommon drops from Titanium)
            BLOODSTONE,
            HUGE_CITRINE,
            SUN_CRYSTAL,
            DARK_JADE,
            CHALCEDONY,
            SHADOW_CRYSTAL,
        },
        rareGems = {
            -- Epic quality gems (rare drops from Titanium)
            CARDINAL_RUBY,
            AMETRINE,
            KINGS_AMBER,
            EYE_OF_ZUL,
            MAJESTIC_ZIRCON,
            DREADSTONE,
        }
    },
}

-- Log successful load
SkilletLog:Add("ProspectingData.lua: Table assignment attempting...", "INFO")
if Skillet.PROSPECTING_DATA then
    local count = 0
    for _ in pairs(Skillet.PROSPECTING_DATA) do count = count + 1 end
    SkilletLog:Add("ProspectingData.lua: SUCCESS - Loaded " .. count .. " ores", "SUCCESS")
else
    SkilletLog:Add("ProspectingData.lua: ERROR - Table is nil after assignment!", "ERROR")
end
