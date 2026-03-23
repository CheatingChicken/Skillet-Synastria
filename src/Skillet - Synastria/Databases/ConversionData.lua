-- ConversionData.lua: Centralized item conversion database
-- This file contains all deterministic item conversions (Crystallized<->Eternal, Mote->Primal, Essence conversions)
-- Format: { source, target, inputAmount, outputAmount, type, name }

-- Namespace
Skillet = Skillet or {}

-- Log that we're loading
SkilletLog:Add("ConversionData.lua: Starting load...", "INFO")

--#region Eternal Elements - Wrath
local ETERNAL_AIR = 35623
local ETERNAL_EARTH = 35624
local ETERNAL_FIRE = 36860
local ETERNAL_LIFE = 35625
local ETERNAL_SHADOW = 35627
local ETERNAL_WATER = 35622
local CRYSTALLIZED_WATER = 37705
local CRYSTALLIZED_EARTH = 37701
local CRYSTALLIZED_FIRE = 37702
local CRYSTALLIZED_LIFE = 37704
local CRYSTALLIZED_SHADOW = 37703
local CRYSTALLIZED_AIR = 37700
--#endregion

--#region Elemental Primals - TBC
local PRIMAL_FIRE = 21884
local PRIMAL_EARTH = 22452
local PRIMAL_AIR = 22451
local PRIMAL_WATER = 21885
local MOTE_OF_FIRE = 22574
local MOTE_OF_EARTH = 22573
local MOTE_OF_AIR = 22572
local MOTE_OF_WATER = 22578
--#endregion

--#region Abstract Primals - TBC
local PRIMAL_LIFE = 21886
local PRIMAL_MANA = 22457
local PRIMAL_SHADOW = 22456
local MOTE_OF_LIFE = 22575
local MOTE_OF_MANA = 22576
local MOTE_OF_SHADOW = 22577
--#endregion

--#region Enchanting Essences - Magic (Vanilla)
local GREATER_MAGIC_ESSENCE = 10939
local LESSER_MAGIC_ESSENCE = 10938
--#endregion

--#region Enchanting Essences - Mystic (Vanilla)
local GREATER_MYSTIC_ESSENCE = 11082
local LESSER_MYSTIC_ESSENCE = 10998
--#endregion

--#region Enchanting Essences - Astral (Vanilla)
local GREATER_ASTRAL_ESSENCE = 10978
local LESSER_ASTRAL_ESSENCE = 10940
--#endregion

--#region Enchanting Essences - Nether (Vanilla)
local GREATER_NETHER_ESSENCE = 11135
local LESSER_NETHER_ESSENCE = 11134
--#endregion

--#region Enchanting Essences - Eternal (Vanilla)
local GREATER_ETERNAL_ESSENCE = 11175
local LESSER_ETERNAL_ESSENCE = 11174
local GREATER_ETERNAL_ESSENCE_ALT = 16203
local LESSER_ETERNAL_ESSENCE_ALT = 16202
--#endregion

--#region Enchanting Essences - Planar (TBC)
local GREATER_PLANAR_ESSENCE = 22446
local LESSER_PLANAR_ESSENCE = 22447
--#endregion

--#region Enchanting Essences - Cosmic (Wrath)
local GREATER_COSMIC_ESSENCE = 34055
local LESSER_COSMIC_ESSENCE = 34056
--#endregion

--#region Enchanting Shards - Glimmering (Vanilla)
local SMALL_GLIMMERING_SHARD = 11084
local LARGE_GLIMMERING_SHARD = 11139
--#endregion

--#region Enchanting Shards - Glowing (Vanilla)
local SMALL_GLOWING_SHARD = 11138
local LARGE_GLOWING_SHARD = 11177
--#endregion

--#region Enchanting Shards - Radiant (Vanilla)
local SMALL_RADIANT_SHARD = 11176
local LARGE_RADIANT_SHARD = 11178
--#endregion

--#region Enchanting Shards - Brilliant (Vanilla)
local SMALL_BRILLIANT_SHARD = 14343
local LARGE_BRILLIANT_SHARD = 14344
--#endregion

--#region Cooking Materials (Vanilla)
local DEEPROCK_SALT = 8150
local REFINED_DEEPROCK_SALT = 15409
local SALT_SHAKER = 15846
--#endregion

-- ========================================
-- Synastria: Centralized Conversion System
-- ========================================
-- Define conversions in a single table for easy expansion
-- Format: { source, target, inputAmount, outputAmount, type, name, toolItemId }
--   inputAmount: how many source items needed
--   outputAmount: how many target items produced
--   type: "combine" (many->one) or "split" (one->many)
--   toolItemId: item ID to use for conversion (typically source, or a tool like Salt Shaker)
--
-- To add new conversions:
-- 1. Add entries to CONVERSION_DEFINITIONS
-- 2. System automatically builds lookup maps
-- 3. Shopping list and queue processor use the same data
-- ========================================

-- NEW: Hardcoded conversion groups for extraction interface with labels
-- NOTE: These are simplified source definitions. The UI (ExtractionFrame.lua) transforms
--       them into full ConversionGroup objects with additional computed fields.
---@type ConversionGroupSource[]
Skillet.CONVERSION_GROUPS = {
    {
        label = "Eternal Elements",
        resultItems = {                                                                                                                        --
            ETERNAL_WATER, ETERNAL_EARTH, ETERNAL_FIRE, ETERNAL_LIFE, ETERNAL_SHADOW, ETERNAL_AIR },                                           -- Water, Earth, Fire, Life, Shadow, Air (Eternals)
        sourceItems = { CRYSTALLIZED_WATER, CRYSTALLIZED_EARTH, CRYSTALLIZED_FIRE, CRYSTALLIZED_LIFE, CRYSTALLIZED_SHADOW, CRYSTALLIZED_AIR }, -- Crystallized versions
        bidirectional = true,                                                                                                                  -- Can convert both ways
        inputAmount = 10,                                                                                                                      -- 10 crystallized
        outputAmount = 1                                                                                                                       -- = 1 eternal
    },
    {
        label = "Elemental Primals",
        resultItems = { PRIMAL_FIRE, PRIMAL_EARTH, PRIMAL_AIR, PRIMAL_WATER },     -- Fire, Earth, Air, Water (Primals)
        sourceItems = { MOTE_OF_FIRE, MOTE_OF_EARTH, MOTE_OF_AIR, MOTE_OF_WATER }, -- Corresponding Motes
        bidirectional = false,                                                     -- One-way conversion only
        inputAmount = 10,                                                          -- 10 motes
        outputAmount = 1                                                           -- = 1 primal
    },
    {
        label = "Abstract Primals",
        resultItems = { PRIMAL_LIFE, PRIMAL_MANA, PRIMAL_SHADOW },    -- Life, Mana, Shadow (Primals)
        sourceItems = { MOTE_OF_LIFE, MOTE_OF_MANA, MOTE_OF_SHADOW }, -- Corresponding Motes
        bidirectional = false,                                        -- One-way conversion only
        inputAmount = 10,                                             -- 10 motes
        outputAmount = 1                                              -- = 1 primal
    },
    {
        label = "Enchanting Essences",
        -- Row 1 (Greater): Cosmic, Planar, Eternal, Nether
        -- Row 2 (Lesser): Cosmic, Planar, Eternal, Nether
        -- Row 3 (Greater): Mystic, Astral, Magic
        -- Row 4 (Lesser): Mystic, Astral, Magic
        resultItems = { GREATER_COSMIC_ESSENCE, GREATER_PLANAR_ESSENCE, GREATER_ETERNAL_ESSENCE_ALT, GREATER_ETERNAL_ESSENCE, GREATER_NETHER_ESSENCE, GREATER_MYSTIC_ESSENCE, GREATER_MAGIC_ESSENCE }, -- Greater Essences (high->low level)
        sourceItems = { LESSER_COSMIC_ESSENCE, LESSER_PLANAR_ESSENCE, LESSER_ETERNAL_ESSENCE_ALT, LESSER_ETERNAL_ESSENCE, LESSER_NETHER_ESSENCE, LESSER_MYSTIC_ESSENCE, LESSER_MAGIC_ESSENCE },        -- Lesser Essences (high->low level)
        bidirectional = true,                                                                                                                                                                          -- Can convert both ways
        inputAmount = 3,                                                                                                                                                                               -- 3 lesser essences
        outputAmount = 1,                                                                                                                                                                              -- = 1 greater essence
        extended = true                                                                                                                                                                                -- Use large layout (4 rows needed)
    }
}

Skillet.CONVERSION_DEFINITIONS = {
    -- ===== WRATH: Crystallized -> Eternal (combine 10 into 1) =====
    { source = CRYSTALLIZED_AIR,        target = ETERNAL_WATER,           inputAmount = 10, outputAmount = 1,  type = "combine", toolItemId = CRYSTALLIZED_AIR,        name = "Crystallized Air -> Eternal Air" },
    { source = CRYSTALLIZED_EARTH,      target = ETERNAL_EARTH,           inputAmount = 10, outputAmount = 1,  type = "combine", toolItemId = CRYSTALLIZED_EARTH,      name = "Crystallized Earth -> Eternal Earth" },
    { source = CRYSTALLIZED_FIRE,       target = ETERNAL_FIRE,            inputAmount = 10, outputAmount = 1,  type = "combine", toolItemId = CRYSTALLIZED_FIRE,       name = "Crystallized Fire -> Eternal Fire" },
    { source = CRYSTALLIZED_LIFE,       target = ETERNAL_LIFE,            inputAmount = 10, outputAmount = 1,  type = "combine", toolItemId = CRYSTALLIZED_LIFE,       name = "Crystallized Life -> Eternal Life" },
    { source = CRYSTALLIZED_SHADOW,     target = ETERNAL_SHADOW,          inputAmount = 10, outputAmount = 1,  type = "combine", toolItemId = CRYSTALLIZED_SHADOW,     name = "Crystallized Shadow -> Eternal Shadow" },
    { source = CRYSTALLIZED_WATER,      target = ETERNAL_AIR,             inputAmount = 10, outputAmount = 1,  type = "combine", toolItemId = CRYSTALLIZED_WATER,      name = "Crystallized Water -> Eternal Water" },

    -- ===== WRATH: Eternal -> Crystallized (split 1 into 10) =====
    { source = ETERNAL_WATER,           target = CRYSTALLIZED_AIR,        inputAmount = 1,  outputAmount = 10, type = "split",   toolItemId = ETERNAL_WATER,           name = "Eternal Air -> Crystallized Air" },
    { source = ETERNAL_EARTH,           target = CRYSTALLIZED_EARTH,      inputAmount = 1,  outputAmount = 10, type = "split",   toolItemId = ETERNAL_EARTH,           name = "Eternal Earth -> Crystallized Earth" },
    { source = ETERNAL_FIRE,            target = CRYSTALLIZED_FIRE,       inputAmount = 1,  outputAmount = 10, type = "split",   toolItemId = ETERNAL_FIRE,            name = "Eternal Fire -> Crystallized Fire" },
    { source = ETERNAL_LIFE,            target = CRYSTALLIZED_LIFE,       inputAmount = 1,  outputAmount = 10, type = "split",   toolItemId = ETERNAL_LIFE,            name = "Eternal Life -> Crystallized Life" },
    { source = ETERNAL_SHADOW,          target = CRYSTALLIZED_SHADOW,     inputAmount = 1,  outputAmount = 10, type = "split",   toolItemId = ETERNAL_SHADOW,          name = "Eternal Shadow -> Crystallized Shadow" },
    { source = ETERNAL_AIR,             target = CRYSTALLIZED_WATER,      inputAmount = 1,  outputAmount = 10, type = "split",   toolItemId = ETERNAL_AIR,             name = "Eternal Water -> Crystallized Water" },

    -- ===== TBC: Mote -> Primal (combine 10 into 1) =====
    { source = MOTE_OF_AIR,             target = PRIMAL_AIR,              inputAmount = 10, outputAmount = 1,  type = "combine", toolItemId = MOTE_OF_AIR,             name = "Mote of Air -> Primal Air" },
    { source = MOTE_OF_EARTH,           target = PRIMAL_EARTH,            inputAmount = 10, outputAmount = 1,  type = "combine", toolItemId = MOTE_OF_EARTH,           name = "Mote of Earth -> Primal Earth" },
    { source = MOTE_OF_FIRE,            target = PRIMAL_FIRE,             inputAmount = 10, outputAmount = 1,  type = "combine", toolItemId = MOTE_OF_FIRE,            name = "Mote of Fire -> Primal Fire" },
    { source = MOTE_OF_LIFE,            target = PRIMAL_LIFE,             inputAmount = 10, outputAmount = 1,  type = "combine", toolItemId = MOTE_OF_LIFE,            name = "Mote of Life -> Primal Life" },
    { source = MOTE_OF_MANA,            target = PRIMAL_MANA,             inputAmount = 10, outputAmount = 1,  type = "combine", toolItemId = MOTE_OF_MANA,            name = "Mote of Mana -> Primal Mana" },
    { source = MOTE_OF_SHADOW,          target = PRIMAL_SHADOW,           inputAmount = 10, outputAmount = 1,  type = "combine", toolItemId = MOTE_OF_SHADOW,          name = "Mote of Shadow -> Primal Shadow" },
    { source = MOTE_OF_WATER,           target = PRIMAL_WATER,            inputAmount = 10, outputAmount = 1,  type = "combine", toolItemId = MOTE_OF_WATER,           name = "Mote of Water -> Primal Water" },

    -- Note: Primal Fire/Earth -> Mote conversions are real Mining recipes, not virtual conversions

    -- ===== VANILLA: Enchanting Essence Conversions (3:1 ratio) =====
    -- Lesser -> Greater (combine 3 into 1)
    { source = LESSER_MAGIC_ESSENCE,    target = GREATER_MAGIC_ESSENCE,   inputAmount = 3,  outputAmount = 1,  type = "combine", toolItemId = LESSER_MAGIC_ESSENCE,    name = "Lesser Magic Essence -> Greater Magic Essence" },
    { source = LESSER_MYSTIC_ESSENCE,   target = GREATER_MYSTIC_ESSENCE,  inputAmount = 3,  outputAmount = 1,  type = "combine", toolItemId = LESSER_MYSTIC_ESSENCE,   name = "Lesser Mystic Essence -> Greater Mystic Essence" },
    { source = LESSER_NETHER_ESSENCE,   target = GREATER_NETHER_ESSENCE,  inputAmount = 3,  outputAmount = 1,  type = "combine", toolItemId = LESSER_NETHER_ESSENCE,   name = "Lesser Nether Essence -> Greater Nether Essence" },
    { source = LESSER_ETERNAL_ESSENCE,  target = GREATER_ETERNAL_ESSENCE, inputAmount = 3,  outputAmount = 1,  type = "combine", toolItemId = LESSER_ETERNAL_ESSENCE,  name = "Lesser Eternal Essence -> Greater Eternal Essence" },
    { source = LESSER_ASTRAL_ESSENCE,   target = GREATER_ASTRAL_ESSENCE,  inputAmount = 3,  outputAmount = 1,  type = "combine", toolItemId = LESSER_ASTRAL_ESSENCE,   name = "Lesser Astral Essence -> Greater Astral Essence" },

    -- Greater -> Lesser (split 1 into 3)
    { source = GREATER_MAGIC_ESSENCE,   target = LESSER_MAGIC_ESSENCE,    inputAmount = 1,  outputAmount = 3,  type = "split",   toolItemId = GREATER_MAGIC_ESSENCE,   name = "Greater Magic Essence -> Lesser Magic Essence" },
    { source = GREATER_MYSTIC_ESSENCE,  target = LESSER_MYSTIC_ESSENCE,   inputAmount = 1,  outputAmount = 3,  type = "split",   toolItemId = GREATER_MYSTIC_ESSENCE,  name = "Greater Mystic Essence -> Lesser Mystic Essence" },
    { source = GREATER_NETHER_ESSENCE,  target = LESSER_NETHER_ESSENCE,   inputAmount = 1,  outputAmount = 3,  type = "split",   toolItemId = GREATER_NETHER_ESSENCE,  name = "Greater Nether Essence -> Lesser Nether Essence" },
    { source = GREATER_ETERNAL_ESSENCE, target = LESSER_ETERNAL_ESSENCE,  inputAmount = 1,  outputAmount = 3,  type = "split",   toolItemId = GREATER_ETERNAL_ESSENCE, name = "Greater Eternal Essence -> Lesser Eternal Essence" },
    { source = GREATER_ASTRAL_ESSENCE,  target = LESSER_ASTRAL_ESSENCE,   inputAmount = 1,  outputAmount = 3,  type = "split",   toolItemId = GREATER_ASTRAL_ESSENCE,  name = "Greater Astral Essence -> Lesser Astral Essence" },

    -- ===== TBC: Planar Essence Conversions (3:1 ratio) =====
    { source = LESSER_PLANAR_ESSENCE,   target = GREATER_PLANAR_ESSENCE,  inputAmount = 3,  outputAmount = 1,  type = "combine", toolItemId = LESSER_PLANAR_ESSENCE,   name = "Lesser Planar Essence -> Greater Planar Essence" },
    { source = GREATER_PLANAR_ESSENCE,  target = LESSER_PLANAR_ESSENCE,   inputAmount = 1,  outputAmount = 3,  type = "split",   toolItemId = GREATER_PLANAR_ESSENCE,  name = "Greater Planar Essence -> Lesser Planar Essence" },

    -- ===== WRATH: Cosmic Essence Conversions (3:1 ratio) =====
    { source = LESSER_COSMIC_ESSENCE,   target = GREATER_COSMIC_ESSENCE,  inputAmount = 3,  outputAmount = 1,  type = "combine", toolItemId = LESSER_COSMIC_ESSENCE,   name = "Lesser Cosmic Essence -> Greater Cosmic Essence" },
    { source = GREATER_COSMIC_ESSENCE,  target = LESSER_COSMIC_ESSENCE,   inputAmount = 1,  outputAmount = 3,  type = "split",   toolItemId = GREATER_COSMIC_ESSENCE,  name = "Greater Cosmic Essence -> Lesser Cosmic Essence" },

    -- ===== VANILLA: Enchanting Shard Conversions (3:1 ratio, one-way only) =====
    { source = SMALL_GLIMMERING_SHARD,  target = LARGE_GLIMMERING_SHARD,  inputAmount = 3,  outputAmount = 1,  type = "combine", toolItemId = SMALL_GLIMMERING_SHARD,  name = "Small Glimmering Shard -> Large Glimmering Shard" },
    { source = SMALL_GLOWING_SHARD,     target = LARGE_GLOWING_SHARD,     inputAmount = 3,  outputAmount = 1,  type = "combine", toolItemId = SMALL_GLOWING_SHARD,     name = "Small Glowing Shard -> Large Glowing Shard" },
    { source = SMALL_RADIANT_SHARD,     target = LARGE_RADIANT_SHARD,     inputAmount = 3,  outputAmount = 1,  type = "combine", toolItemId = SMALL_RADIANT_SHARD,     name = "Small Radiant Shard -> Large Radiant Shard" },
    { source = SMALL_BRILLIANT_SHARD,   target = LARGE_BRILLIANT_SHARD,   inputAmount = 3,  outputAmount = 1,  type = "combine", toolItemId = SMALL_BRILLIANT_SHARD,   name = "Small Brilliant Shard -> Large Brilliant Shard" },

    -- ===== VANILLA: Cooking Material Conversions (requires tool) =====
    { source = DEEPROCK_SALT,           target = REFINED_DEEPROCK_SALT,   inputAmount = 1,  outputAmount = 1,  type = "combine", toolItemId = SALT_SHAKER,             name = "Deeprock Salt -> Refined Deeprock Salt" },
}

-- Build lookup maps from definitions (backwards compatibility)
---@type table<number, number>
local CRYSTALLIZED_TO_ETERNAL_MAP = {}
---@type table<number, number>
local ETERNAL_TO_CRYSTALLIZED_MAP = {}

for _, conversion in ipairs(Skillet.CONVERSION_DEFINITIONS) do
    if conversion.type == "combine" then
        -- Crystallized -> Eternal
        CRYSTALLIZED_TO_ETERNAL_MAP[conversion.source] = conversion.target
    elseif conversion.type == "split" then
        -- Eternal -> Crystallized
        ETERNAL_TO_CRYSTALLIZED_MAP[conversion.source] = conversion.target
    end
end

-- Log successful load
SkilletLog:Add("ConversionData.lua: Table assignments attempting...", "INFO")

if Skillet.CONVERSION_GROUPS then
    SkilletLog:Add("ConversionData.lua: SUCCESS - Loaded " .. #Skillet.CONVERSION_GROUPS .. " conversion groups",
        "SUCCESS")
else
    SkilletLog:Add("ConversionData.lua: ERROR - CONVERSION_GROUPS is nil!", "ERROR")
end

if Skillet.CONVERSION_DEFINITIONS then
    SkilletLog:Add(
        "ConversionData.lua: SUCCESS - Loaded " .. #Skillet.CONVERSION_DEFINITIONS .. " conversion definitions",
        "SUCCESS")
else
    SkilletLog:Add("ConversionData.lua: ERROR - CONVERSION_DEFINITIONS is nil!", "ERROR")
end
