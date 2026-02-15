-- MillingData.lua: Milling herb->pigment loot table database
-- This file contains all milling data (herb extraction to pigments)
-- Format: [herbItemId] = { skill, minQuantity, commonPigments, rarePigments }

-- Namespace
Skillet = Skillet or {}

-- Log that we're loading
SkilletLog:Add("MillingData.lua: Starting load...", "INFO")

--#region Pigments
local ALABASTER_PIGMENT = 39151
local DUSKY_PIGMENT = 39334
local VERDANT_PIGMENT = 43103
local GOLDEN_PIGMENT = 39338
local BURNT_PIGMENT = 43104
local EMERALD_PIGMENT = 39339
local INDIGO_PIGMENT = 43105
local VIOLET_PIGMENT = 39340
local RUBY_PIGMENT = 43106
local SILVERY_PIGMENT = 39341
local SAPPHIRE_PIGMENT = 43107
local NETHER_PIGMENT = 39342
local EBON_PIGMENT = 43108
local AZURE_PIGMENT = 39343
local ICY_PIGMENT = 43109
--#endregion

--#region Herbs - Vanilla Tier 1 (Skill 1)
local PEACEBLOOM = 2447
local SILVERLEAF = 765
local EARTHROOT = 2449
--#endregion

--#region Herbs - Vanilla Tier 2 (Skill 25)
local BRIARTHORN = 2450
local SWIFTTHISTLE = 2452
local BRUISEWEED = 2453
local STRANGLEKELP = 3820
local MAGEROYAL = 785
--#endregion

--#region Herbs - Vanilla Tier 3 (Skill 75)
local WILD_STEELBLOOM = 3355
local GRAVE_MOSS = 3369
local KINGSBLOOD = 3356
local LIFEROOT = 3357
--#endregion

--#region Herbs - Vanilla Tier 4 (Skill 125)
local FADELEAF = 3818
local GOLDTHORN = 3821
local KHADGARS_WHISKER = 3358
local WINTERSBITE = 3819
--#endregion

--#region Herbs - Vanilla Tier 5 (Skill 175)
local FIREBLOOM = 4625
local PURPLE_LOTUS = 8831
local ARTHAS_TEARS = 8836
local SUNGRASS = 8838
local BLINDWEED = 8153
local GHOST_MUSHROOM = 8845
local GROMSBLOOD = 8846
--#endregion

--#region Herbs - Vanilla Tier 6 (Skill 225)
local GOLDEN_SANSAM = 13464
local DREAMFOIL = 13463
local MOUNTAIN_SILVERSAGE = 13465
local PLAGUEBLOOM = 13466
local ICECAP = 13467
--#endregion

--#region Herbs - TBC (Skill 275)
local FELWEED = 22785
local DREAMING_GLORY = 22786
local TEROCONE = 22787
local ANCIENT_LICHEN = 22789
local NETHERBLOOM = 22791
local NIGHTMARE_VINE = 22792
local MANA_THISTLE = 22793
local RAGVEIL = 22794
--#endregion

--#region Herbs - Wrath (Skill 325)
local GOLDCLOVER = 36901
local TIGER_LILY = 36904
local TALANDRA_ROSE = 36907
local LICHBLOOM = 36905
local ICETHORN = 36906
local ADDERS_TONGUE = 36903
--#endregion
-- ========================================
-- MILLING DATA
-- ========================================

Skillet.MILLING_DATA = {
    -- VANILLA HERBS (Skill 1)
    -- Peacebloom
    [PEACEBLOOM] = {
        skill = 1,
        minQuantity = 5,
        commonPigments = { ALABASTER_PIGMENT }, -- Alabaster Pigment
        rarePigments = {}
    },

    -- Silverleaf
    [SILVERLEAF] = {
        skill = 1,
        minQuantity = 5,
        commonPigments = { ALABASTER_PIGMENT }, -- Alabaster Pigment
        rarePigments = {}
    },

    -- Earthroot
    [EARTHROOT] = {
        skill = 1,
        minQuantity = 5,
        commonPigments = { ALABASTER_PIGMENT }, -- Alabaster Pigment
        rarePigments = {}
    },

    -- VANILLA HERBS (Skill 25)
    -- Tier 2: Dusky Pigment (Common) + Verdant Pigment (Rare)
    -- Briarthorn
    [BRIARTHORN] = {
        skill = 25,
        minQuantity = 5,
        commonPigments = { DUSKY_PIGMENT }, -- Dusky Pigment
        rarePigments = { VERDANT_PIGMENT }  -- Verdant Pigment
    },

    -- Swiftthistle
    [SWIFTTHISTLE] = {
        skill = 25,
        minQuantity = 5,
        commonPigments = { DUSKY_PIGMENT }, -- Dusky Pigment
        rarePigments = { VERDANT_PIGMENT }  -- Verdant Pigment
    },

    -- Bruiseweed
    [BRUISEWEED] = {
        skill = 25,
        minQuantity = 5,
        commonPigments = { DUSKY_PIGMENT }, -- Dusky Pigment
        rarePigments = { VERDANT_PIGMENT }  -- Verdant Pigment
    },

    -- Stranglekelp
    [STRANGLEKELP] = {
        skill = 25,
        minQuantity = 5,
        commonPigments = { DUSKY_PIGMENT }, -- Dusky Pigment
        rarePigments = { VERDANT_PIGMENT }  -- Verdant Pigment
    },

    -- Mageroyal
    [MAGEROYAL] = {
        skill = 25,
        minQuantity = 5,
        commonPigments = { DUSKY_PIGMENT }, -- Dusky Pigment
        rarePigments = { VERDANT_PIGMENT }  -- Verdant Pigment
    },

    -- VANILLA HERBS (Skill 75)
    -- Tier 3: Golden Pigment (Common) + Burnt Pigment (Rare)
    -- Wild Steelbloom
    [WILD_STEELBLOOM] = {
        skill = 75,
        minQuantity = 5,
        commonPigments = { GOLDEN_PIGMENT }, -- Golden Pigment
        rarePigments = { BURNT_PIGMENT }     -- Burnt Pigment
    },

    -- Grave Moss
    [GRAVE_MOSS] = {
        skill = 75,
        minQuantity = 5,
        commonPigments = { GOLDEN_PIGMENT }, -- Golden Pigment
        rarePigments = { BURNT_PIGMENT }     -- Burnt Pigment
    },

    -- Kingsblood
    [KINGSBLOOD] = {
        skill = 75,
        minQuantity = 5,
        commonPigments = { GOLDEN_PIGMENT }, -- Golden Pigment
        rarePigments = { BURNT_PIGMENT }     -- Burnt Pigment
    },

    -- Liferoot
    [LIFEROOT] = {
        skill = 75,
        minQuantity = 5,
        commonPigments = { GOLDEN_PIGMENT }, -- Golden Pigment
        rarePigments = { BURNT_PIGMENT }     -- Burnt Pigment
    },

    -- VANILLA HERBS (Skill 125)
    -- Fadeleaf
    [FADELEAF] = {
        skill = 125,
        minQuantity = 5,
        commonPigments = { EMERALD_PIGMENT }, -- Emerald Pigment
        rarePigments = { INDIGO_PIGMENT }     -- Indigo Pigment
    },

    -- Goldthorn
    [GOLDTHORN] = {
        skill = 125,
        minQuantity = 5,
        commonPigments = { EMERALD_PIGMENT }, -- Emerald Pigment
        rarePigments = { INDIGO_PIGMENT }     -- Indigo Pigment
    },

    -- Khadgar's Whisker
    [KHADGARS_WHISKER] = {
        skill = 125,
        minQuantity = 5,
        commonPigments = { EMERALD_PIGMENT }, -- Emerald Pigment
        rarePigments = { INDIGO_PIGMENT }     -- Indigo Pigment
    },

    -- Wintersbite
    [WINTERSBITE] = {
        skill = 125,
        minQuantity = 5,
        commonPigments = { EMERALD_PIGMENT }, -- Emerald Pigment
        rarePigments = { INDIGO_PIGMENT }     -- Indigo Pigment
    },

    -- VANILLA HERBS (Skill 175)
    -- Tier 5: Violet Pigment (Common) + Ruby Pigment (Rare)
    -- Firebloom
    [FIREBLOOM] = {
        skill = 175,
        minQuantity = 5,
        commonPigments = { VIOLET_PIGMENT }, -- Violet Pigment
        rarePigments = { RUBY_PIGMENT }      -- Ruby Pigment
    },

    -- Purple Lotus
    [PURPLE_LOTUS] = {
        skill = 175,
        minQuantity = 5,
        commonPigments = { VIOLET_PIGMENT }, -- Violet Pigment
        rarePigments = { RUBY_PIGMENT }      -- Ruby Pigment
    },

    -- Arthas' Tears
    [ARTHAS_TEARS] = {
        skill = 175,
        minQuantity = 5,
        commonPigments = { VIOLET_PIGMENT }, -- Violet Pigment
        rarePigments = { RUBY_PIGMENT }      -- Ruby Pigment
    },

    -- Sungrass
    [SUNGRASS] = {
        skill = 175,
        minQuantity = 5,
        commonPigments = { VIOLET_PIGMENT }, -- Violet Pigment
        rarePigments = { RUBY_PIGMENT }      -- Ruby Pigment
    },

    -- Blindweed
    [BLINDWEED] = {
        skill = 175,
        minQuantity = 5,
        commonPigments = { VIOLET_PIGMENT }, -- Violet Pigment
        rarePigments = { RUBY_PIGMENT }      -- Ruby Pigment
    },

    -- Ghost Mushroom
    [GHOST_MUSHROOM] = {
        skill = 175,
        minQuantity = 5,
        commonPigments = { VIOLET_PIGMENT }, -- Violet Pigment
        rarePigments = { RUBY_PIGMENT }      -- Ruby Pigment
    },

    -- Gromsblood
    [GROMSBLOOD] = {
        skill = 175,
        minQuantity = 5,
        commonPigments = { VIOLET_PIGMENT }, -- Violet Pigment
        rarePigments = { RUBY_PIGMENT }      -- Ruby Pigment
    },

    -- VANILLA HERBS (Skill 225)
    -- Tier 6: Silvery Pigment (Common) + Sapphire Pigment (Rare)
    -- Golden Sansam
    [GOLDEN_SANSAM] = {
        skill = 225,
        minQuantity = 5,
        commonPigments = { SILVERY_PIGMENT }, -- Silvery Pigment
        rarePigments = { SAPPHIRE_PIGMENT }   -- Sapphire Pigment
    },

    -- Dreamfoil
    [DREAMFOIL] = {
        skill = 225,
        minQuantity = 5,
        commonPigments = { SILVERY_PIGMENT }, -- Silvery Pigment
        rarePigments = { SAPPHIRE_PIGMENT }   -- Sapphire Pigment
    },

    -- Mountain Silversage
    [MOUNTAIN_SILVERSAGE] = {
        skill = 225,
        minQuantity = 5,
        commonPigments = { SILVERY_PIGMENT }, -- Silvery Pigment
        rarePigments = { SAPPHIRE_PIGMENT }   -- Sapphire Pigment
    },

    -- Plaguebloom
    [PLAGUEBLOOM] = {
        skill = 225,
        minQuantity = 5,
        commonPigments = { SILVERY_PIGMENT }, -- Silvery Pigment
        rarePigments = { SAPPHIRE_PIGMENT }   -- Sapphire Pigment
    },

    -- Icecap
    [ICECAP] = {
        skill = 225,
        minQuantity = 5,
        commonPigments = { SILVERY_PIGMENT }, -- Silvery Pigment
        rarePigments = { SAPPHIRE_PIGMENT }   -- Sapphire Pigment
    },

    -- TBC HERBS (Skill 275)
    -- Tier 7: Nether Pigment (Common) + Ebon Pigment (Rare)
    -- Note: All Outland herbs produce these pigments

    -- Felweed
    [FELWEED] = {
        skill = 275,
        minQuantity = 5,
        commonPigments = { NETHER_PIGMENT }, -- Nether Pigment
        rarePigments = { EBON_PIGMENT }      -- Ebon Pigment
    },

    -- Dreaming Glory
    [DREAMING_GLORY] = {
        skill = 275,
        minQuantity = 5,
        commonPigments = { NETHER_PIGMENT }, -- Nether Pigment
        rarePigments = { EBON_PIGMENT }      -- Ebon Pigment
    },

    -- Terocone
    [TEROCONE] = {
        skill = 275,
        minQuantity = 5,
        commonPigments = { NETHER_PIGMENT }, -- Nether Pigment
        rarePigments = { EBON_PIGMENT }      -- Ebon Pigment
    },

    -- Ancient Lichen
    [ANCIENT_LICHEN] = {
        skill = 275,
        minQuantity = 5,
        commonPigments = { NETHER_PIGMENT }, -- Nether Pigment
        rarePigments = { EBON_PIGMENT }      -- Ebon Pigment
    },

    -- Netherbloom
    [NETHERBLOOM] = {
        skill = 275,
        minQuantity = 5,
        commonPigments = { NETHER_PIGMENT }, -- Nether Pigment
        rarePigments = { EBON_PIGMENT }      -- Ebon Pigment
    },

    -- Nightmare Vine
    [NIGHTMARE_VINE] = {
        skill = 275,
        minQuantity = 5,
        commonPigments = { NETHER_PIGMENT }, -- Nether Pigment
        rarePigments = { EBON_PIGMENT }      -- Ebon Pigment
    },

    -- Mana Thistle
    [MANA_THISTLE] = {
        skill = 275,
        minQuantity = 5,
        commonPigments = { NETHER_PIGMENT }, -- Nether Pigment
        rarePigments = { EBON_PIGMENT }      -- Ebon Pigment
    },

    -- Ragveil
    [RAGVEIL] = {
        skill = 275,
        minQuantity = 5,
        commonPigments = { NETHER_PIGMENT }, -- Nether Pigment
        rarePigments = { EBON_PIGMENT }      -- Ebon Pigment
    },

    -- WRATH HERBS (Skill 325)
    -- Tier 8: Azure Pigment (Common) + Icy Pigment (Rare)
    -- Note: All Northrend herbs produce these pigments

    -- Goldclover
    [GOLDCLOVER] = {
        skill = 325,
        minQuantity = 5,
        commonPigments = { AZURE_PIGMENT }, -- Azure Pigment
        rarePigments = { ICY_PIGMENT }      -- Icy Pigment
    },

    -- Tiger Lily
    [TIGER_LILY] = {
        skill = 325,
        minQuantity = 5,
        commonPigments = { AZURE_PIGMENT }, -- Azure Pigment
        rarePigments = { ICY_PIGMENT }      -- Icy Pigment
    },

    -- Talandra's Rose
    [TALANDRA_ROSE] = {
        skill = 325,
        minQuantity = 5,
        commonPigments = { AZURE_PIGMENT }, -- Azure Pigment
        rarePigments = { ICY_PIGMENT }      -- Icy Pigment
    },

    -- Lichbloom
    [LICHBLOOM] = {
        skill = 325,
        minQuantity = 5,
        commonPigments = { AZURE_PIGMENT }, -- Azure Pigment
        rarePigments = { ICY_PIGMENT }      -- Icy Pigment
    },

    -- Icethorn
    [ICETHORN] = {
        skill = 325,
        minQuantity = 5,
        commonPigments = { AZURE_PIGMENT }, -- Azure Pigment
        rarePigments = { ICY_PIGMENT }      -- Icy Pigment
    },

    -- Adder's Tongue
    [ADDERS_TONGUE] = {
        skill = 325,
        minQuantity = 5,
        commonPigments = { AZURE_PIGMENT }, -- Azure Pigment
        rarePigments = { ICY_PIGMENT }      -- Icy Pigment
    },
}

-- Log successful load
SkilletLog:Add("MillingData.lua: Table assignment attempting...", "INFO")
if Skillet.MILLING_DATA then
    local count = 0
    for _ in pairs(Skillet.MILLING_DATA) do count = count + 1 end
    SkilletLog:Add("MillingData.lua: SUCCESS - Loaded " .. count .. " herbs", "SUCCESS")
else
    SkilletLog:Add("MillingData.lua: ERROR - Table is nil after assignment!", "ERROR")
end
