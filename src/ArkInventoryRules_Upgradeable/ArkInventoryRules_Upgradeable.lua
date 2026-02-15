-- ʕ •ᴥ•ʔ✿ ArkInventory Rules - Upgradeable Items ✿ ʕ •ᴥ•ʔ
-- Praise the Omnissiah! This module provides rules for filtering upgradeable items with attunable upgrade chains.

---@diagnostic disable: undefined-global

---@class ArkInventoryRulesModule
---@field OnEnable fun(self: ArkInventoryRulesModule, ...)
---@field upgradeable fun(...: any): boolean

---@type table<string, table>
_G.ArkInventoryRules = _G.ArkInventoryRules or {}

---@type table<string, unknown>
_G.ArkInventory = _G.ArkInventory or { Localise = {} }

---@type function | nil
local CreateFrame = _G.CreateFrame

---@type function | nil
local GetHighestAttunePct = _G.GetHighestAttunePct

---@type function | nil
local Custom_GetIdFromLink = _G.Custom_GetIdFromLink

---@diagnostic enable: undefined-global
---@diagnostic disable: need-check-nil

---@type ArkInventoryRulesModule
local rule = ArkInventoryRules:NewModule('ArkInventoryRules_Upgradeable')

-- ʕ •ᴥ•ʔ✿ Upgrade Map from Scoots ID Upgradables ✿ ʕ •ᴥ•ʔ
-- Maps source itemId -> target itemId for all known upgrades from Scoots ID Upgradables database
---@type table<integer, integer>
local UPGRADE_MAP = {
    [2944] = 2943,   -- Cursed Eye of Paleth -> Eye of Paleth
    [4243] = 4244,   -- Fine Leather Tunic -> Hillman's Leather Vest
    [4246] = 4249,   -- Fine Leather Belt -> Dark Leather Belt
    [4255] = 3844,   -- Green Leather Armor -> Green Iron Hauberk
    [4368] = 4385,   -- Flying Tiger Goggles -> Green Tinted Goggles
    [4385] = 10500,  -- Green Tinted Goggles -> Fire Goggles
    [5966] = 7938,   -- Guardian Gloves -> Truesilver Gauntlets
    [7387] = 10721,  -- Dusky Belt -> Gnomish Harm Prevention Belt
    [9149] = 13503,  -- Philosopher's Stone -> Alchemist's Stone
    [10026] = 7189,  -- Black Mageweave Boots -> Goblin Rocket Boots
    [10500] = 16008, -- Fire Goggles -> Master Engineer's Goggles
    [10502] = 15999, -- Spellpower Goggles Xtreme -> Spellpower Goggles Xtreme Plus
    [10543] = 10588, -- Goblin Construction Helmet -> Goblin Rocket Helmet
    [13503] = 35749, -- Alchemist's Stone -> Sorcerer's Alchemist Stone
    [14044] = 15138, -- Cindercloth Cloak -> Onyxia Scale Cloak
    [16666] = 22102, -- Vest of Elements -> Vest of the Five Thunders
    [16667] = 22102, -- Coif of Elements -> Vest of the Five Thunders
    [16668] = 22101, -- Kilt of Elements -> Pauldrons of the Five Thunders
    [16669] = 22101, -- Pauldrons of Elements -> Pauldrons of the Five Thunders
    [16670] = 22096, -- Boots of Elements -> Boots of the Five Thunders
    [16671] = 22095, -- Bindings of Elements -> Bindings of the Five Thunders
    [16672] = 22099, -- Gauntlets of Elements -> Gauntlets of the Five Thunders
    [16673] = 22099, -- Cord of Elements -> Gauntlets of the Five Thunders
    [16674] = 22060, -- Beaststalker's Tunic -> Beastmaster's Tunic
    [16675] = 22061, -- Beaststalker's Boots -> Beastmaster's Boots
    [16676] = 22015, -- Beaststalker's Gloves -> Beastmaster's Gloves
    [16677] = 22013, -- Beaststalker's Cap -> Beastmaster's Cap
    [16678] = 22017, -- Beaststalker's Pants -> Beastmaster's Pants
    [16679] = 22017, -- Beaststalker's Mantle -> Beastmaster's Pants
    [16680] = 22010, -- Beaststalker's Belt -> Beastmaster's Belt
    [16681] = 22011, -- Beaststalker's Bindings -> Beastmaster's Bindings
    [16682] = 22064, -- Magister's Boots -> Sorcerer's Boots
    [16683] = 22063, -- Magister's Bindings -> Sorcerer's Bindings
    [16684] = 22066, -- Magister's Gloves -> Sorcerer's Gloves
    [16685] = 22062, -- Magister's Belt -> Sorcerer's Belt
    [16686] = 22065, -- Magister's Crown -> Sorcerer's Crown
    [16687] = 22067, -- Magister's Leggings -> Sorcerer's Leggings
    [16688] = 22069, -- Magister's Robes -> Sorcerer's Robes
    [16689] = 22068, -- Magister's Mantle -> Sorcerer's Mantle
    [16690] = 22083, -- Devout Robe -> Virtuous Robe
    [16691] = 22084, -- Devout Sandals -> Virtuous Sandals
    [16692] = 22081, -- Devout Gloves -> Virtuous Gloves
    [16693] = 22083, -- Devout Crown -> Virtuous Robe
    [16694] = 22085, -- Devout Skirt -> Virtuous Skirt
    [16695] = 22085, -- Devout Mantle -> Virtuous Skirt
    [16696] = 22081, -- Devout Belt -> Virtuous Gloves
    [16697] = 22079, -- Devout Bracers -> Virtuous Bracers
    [16698] = 22075, -- Dreadmist Mask -> Deathmist Robe
    [16699] = 22072, -- Dreadmist Leggings -> Deathmist Leggings
    [16700] = 22075, -- Dreadmist Robe -> Deathmist Robe
    [16701] = 22073, -- Dreadmist Mantle -> Deathmist Mantle
    [16702] = 22077, -- Dreadmist Belt -> Deathmist Wraps
    [16703] = 22071, -- Dreadmist Bracers -> Deathmist Bracers
    [16704] = 22076, -- Dreadmist Sandals -> Deathmist Sandals
    [16705] = 22077, -- Dreadmist Wraps -> Deathmist Wraps
    [16706] = 22113, -- Wildheart Vest -> Feralheart Vest
    [16707] = 22009, -- Shadowcraft Cap -> Darkmantle Tunic
    [16708] = 22008, -- Shadowcraft Spaulders -> Darkmantle Spaulders
    [16709] = 22008, -- Shadowcraft Pants -> Darkmantle Spaulders
    [16710] = 22004, -- Shadowcraft Bracers -> Darkmantle Bracers
    [16711] = 22003, -- Shadowcraft Boots -> Darkmantle Boots
    [16712] = 22006, -- Shadowcraft Gloves -> Darkmantle Gloves
    [16713] = 22006, -- Shadowcraft Belt -> Darkmantle Gloves
    [16714] = 22108, -- Wildheart Bracers -> Feralheart Bracers
    [16715] = 22107, -- Wildheart Boots -> Feralheart Boots
    [16716] = 22110, -- Wildheart Belt -> Feralheart Gloves
    [16717] = 22110, -- Wildheart Gloves -> Feralheart Gloves
    [16718] = 22112, -- Wildheart Spaulders -> Feralheart Spaulders
    [16719] = 22111, -- Wildheart Kilt -> Feralheart Kilt
    [16720] = 22109, -- Wildheart Cowl -> Feralheart Cowl
    [16721] = 22009, -- Shadowcraft Tunic -> Darkmantle Tunic
    [16722] = 22088, -- Lightforge Bracers -> Soulforge Bracers
    [16723] = 22090, -- Lightforge Belt -> Soulforge Gauntlets
    [16724] = 22086, -- Lightforge Gauntlets -> Soulforge Belt
    [16725] = 22087, -- Lightforge Boots -> Soulforge Boots
    [16726] = 22089, -- Lightforge Breastplate -> Soulforge Breastplate
    [16727] = 22091, -- Lightforge Helm -> Soulforge Helm
    [16728] = 22093, -- Lightforge Legplates -> Soulforge Spaulders
    [16729] = 22087, -- Lightforge Spaulders -> Soulforge Boots
    [16730] = 21997, -- Breastplate of Valor -> Breastplate of Heroism
    [16731] = 21999, -- Helm of Valor -> Helm of Heroism
    [16732] = 22000, -- Legplates of Valor -> Legplates of Heroism
    [16733] = 22001, -- Spaulders of Valor -> Spaulders of Heroism
    [16734] = 21995, -- Boots of Valor -> Boots of Heroism
    [16735] = 21996, -- Bracers of Valor -> Bracers of Heroism
    [16736] = 21998, -- Belt of Valor -> Gauntlets of Heroism
    [16737] = 21998, -- Gauntlets of Valor -> Gauntlets of Heroism
    [17074] = 17223, -- Shadowstrike -> Thunderstrike
    [18608] = 18609, -- Benediction -> Anathema
    [21196] = 21197, -- Signet Ring of the Bronze Dragonflight -> Signet Ring of the Bronze Dragonflight
    [21197] = 21198, -- Signet Ring of the Bronze Dragonflight -> Signet Ring of the Bronze Dragonflight
    [21198] = 21199, -- Signet Ring of the Bronze Dragonflight -> Signet Ring of the Bronze Dragonflight
    [21199] = 21200, -- Signet Ring of the Bronze Dragonflight -> Signet Ring of the Bronze Dragonflight
    [21201] = 21202, -- Signet Ring of the Bronze Dragonflight -> Signet Ring of the Bronze Dragonflight
    [21202] = 21203, -- Signet Ring of the Bronze Dragonflight -> Signet Ring of the Bronze Dragonflight
    [21203] = 21204, -- Signet Ring of the Bronze Dragonflight -> Signet Ring of the Bronze Dragonflight
    [21204] = 21205, -- Signet Ring of the Bronze Dragonflight -> Signet Ring of the Bronze Dragonflight
    [21206] = 21207, -- Signet Ring of the Bronze Dragonflight -> Signet Ring of the Bronze Dragonflight
    [21207] = 21208, -- Signet Ring of the Bronze Dragonflight -> Signet Ring of the Bronze Dragonflight
    [21208] = 21209, -- Signet Ring of the Bronze Dragonflight -> Signet Ring of the Bronze Dragonflight
    [21209] = 21210, -- Signet Ring of the Bronze Dragonflight -> Signet Ring of the Bronze Dragonflight
    [23563] = 23564, -- Nether Chain Shirt -> Twisting Nether Chain Shirt
    [23564] = 23565, -- Twisting Nether Chain Shirt -> Embrace of the Twisting Nether
    [28425] = 28426, -- Fireguard -> Blazeguard
    [28426] = 28427, -- Blazeguard -> Blazefury
    [28428] = 28429, -- Lionheart Blade -> Lionheart Champion
    [28429] = 28430, -- Lionheart Champion -> Lionheart Executioner
    [28431] = 28432, -- The Planar Edge -> Black Planar Edge
    [28432] = 28433, -- Black Planar Edge -> Wicked Edge of the Planes
    [28434] = 28435, -- Lunar Crescent -> Mooncleaver
    [28435] = 28436, -- Mooncleaver -> Bloodmoon
    [28437] = 28438, -- Drakefist Hammer -> Dragonmaw
    [28438] = 28439, -- Dragonmaw -> Dragonstrike
    [28440] = 28441, -- Thunder -> Deep Thunder
    [28441] = 28442, -- Deep Thunder -> Stormherald
    [28483] = 28484, -- Breastplate of Kings -> Bulwark of Kings
    [28484] = 28485, -- Bulwark of Kings -> Bulwark of the Ancient Kings
    [32461] = 34354, -- Furious Gizmatic Goggles -> Mayhem Projection Goggles
    [32472] = 35185, -- Justicebringer 2000 Specs -> Justicebringer 3000 Specs
    [32473] = 34357, -- Tankatronic Goggles -> Hard Khorium Goggles
    [32474] = 34356, -- Surestrike Goggles v2.0 -> Surestrike Goggles v3.0
    [32475] = 35184, -- Living Replicator Specs -> Primal-Attuned Goggles
    [32476] = 34355, -- Gadgetstorm Goggles -> Lightning Etched Specs
    [32478] = 34353, -- Deathblow X11 Goggles -> Quad Deathblow X44 Goggles
    [32479] = 35183, -- Wonderheal XT40 Shades -> Wonderheal XT68 Shades
    [32480] = 35182, -- Magnified Moon Specs -> Hyper-Magnified Moon Specs
    [32494] = 34847, -- Destruction Holo-Gogs -> Annihilator Holo-Gogs
    [32495] = 35181, -- Powerheal 4000 Lens -> Powerheal 9000 Lens
    [32649] = 32757, -- Medallion of Karabor -> Blessed Medallion of Karabor
    [34167] = 34382, -- Legplates of the Holy Juggernaut -> Judicator's Leggards
    [34169] = 34384, -- Breeches of Natural Aggression -> Breeches of Natural Splendor
    [34170] = 34386, -- Pantaloons of Calming Strife -> Pantaloons of Growing Strife
    [34180] = 34381, -- Felfury Legplates -> Felstrength Legplates
    [34186] = 34383, -- Chain Links of the Tumultuous Storm -> Kilt of Spiritual Reconstruction
    [34188] = 34385, -- Leggings of the Immortal Night -> Leggings of the Immortal Beast
    [34192] = 34388, -- Pauldrons of Perseverance -> Pauldrons of Berserking
    [34193] = 34389, -- Spaulders of the Thalassian Savior -> Spaulders of the Thalassian Defender
    [34195] = 34392, -- Shoulderpads of Vehemence -> Demontooth Shoulderpads
    [34202] = 34393, -- Shawl of Wonderment -> Shoulderpads of Knowledge's Pursuit
    [34208] = 34390, -- Equilibrium Epaulets -> Erupting Epaulets
    [34209] = 34391, -- Spaulders of Reclamation -> Spaulders of Devastation
    [34211] = 34397, -- Harness of Carnal Instinct -> Bladed Chaos Tunic
    [34212] = 34398, -- Sunglow Vest -> Utopian Tunic of Elune
    [34215] = 34394, -- Warharness of Reckless Fury -> Breastplate of Agony's Aversion
    [34216] = 34395, -- Heroic Judicator's Chestguard -> Noble Judicator's Chestguard
    [34229] = 34396, -- Garments of Serene Shores -> Garments of Crashing Shores
    [34233] = 34399, -- Robes of Faltered Light -> Robes of Ghostly Hatred
    [34234] = 34408, -- Shadowed Gauntlets of Paroxysm -> Gloves of the Forest Drifter
    [34243] = 34401, -- Helm of Burning Righteousness -> Helm of Uther's Resolve
    [34244] = 34404, -- Duplicitous Guise -> Mask of the Fury Hunter
    [34245] = 34403, -- Cover of Ursoc the Wise -> Cover of Ursoc the Mighty
    [34332] = 34402, -- Cowl of Gul'dan -> Shroud of Chieftain Ner'zhul
    [34339] = 34405, -- Cowl of Light's Purity -> Helm of Arcane Purity
    [34342] = 34406, -- Handguards of the Dawn -> Gloves of Tyri's Power
    [34345] = 34400, -- Crown of Anasterian -> Crown of Dath'Remar
    [34350] = 34409, -- Gauntlets of the Ancient Shadowmoon -> Gauntlets of the Ancient Frostwolf
    [34351] = 34407, -- Tranquil Majesty Wraps -> Tranquil Moonlight Wraps
    [40585] = 45691, -- Signet of the Kirin Tor -> Inscribed Signet of the Kirin Tor
    [40586] = 45688, -- Band of the Kirin Tor -> Inscribed Band of the Kirin Tor
    [41245] = 47590, -- Deadly Saronite Dirk -> Titanium Razorplate (H)
    [41355] = 47573, -- Vengeance Bindings -> Titanium Spikeguards (H)
    [41520] = 41544, -- Frostwoven Boots -> Duskweave Boots
    [44934] = 45689, -- Loop of the Kirin Tor -> Inscribed Loop of the Kirin Tor
    [44935] = 45690, -- Ring of the Kirin Tor -> Inscribed Ring of the Kirin Tor
    [45688] = 48954, -- Inscribed Band of the Kirin Tor -> Etched Band of the Kirin Tor
    [45689] = 48955, -- Inscribed Loop of the Kirin Tor -> Etched Loop of the Kirin Tor
    [45690] = 48956, -- Inscribed Ring of the Kirin Tor -> Etched Ring of the Kirin Tor
    [45691] = 48957, -- Inscribed Signet of the Kirin Tor -> Etched Signet of the Kirin Tor
    [48954] = 51560, -- Etched Band of the Kirin Tor -> Runed Band of the Kirin Tor
    [48955] = 51558, -- Etched Loop of the Kirin Tor -> Runed Loop of the Kirin Tor
    [48956] = 51559, -- Etched Ring of the Kirin Tor -> Runed Ring of the Kirin Tor
    [48957] = 51557, -- Etched Signet of the Kirin Tor -> Runed Signet of the Kirin Tor
    [49302] = 49301, -- Reclaimed Shadowstrike -> Reclaimed Thunderstrike
    [49496] = 49497, -- Reinforced Shadowstrike -> Reinforced Thunderstrike
    [49888] = 49623, -- Shadow's Edge -> Shadowmourne
    [50078] = 51214, -- Ymirjar Lord's Battleplate -> Sanctified Ymirjar Lord's Battleplate (N)
    [50079] = 51213, -- Ymirjar Lord's Gauntlets -> Sanctified Ymirjar Lord's Gauntlets (N)
    [50080] = 51212, -- Ymirjar Lord's Helmet -> Sanctified Ymirjar Lord's Helmet (N)
    [50081] = 51211, -- Ymirjar Lord's Legplates -> Sanctified Ymirjar Lord's Legplates (N)
    [50082] = 51210, -- Ymirjar Lord's Shoulderplates -> Sanctified Ymirjar Lord's Shoulderplates (N)
    [50087] = 51189, -- Shadowblade Breastplate -> Sanctified Shadowblade Breastplate (N)
    [50088] = 51188, -- Shadowblade Gauntlets -> Sanctified Shadowblade Gauntlets (N)
    [50089] = 51187, -- Shadowblade Helmet -> Sanctified Shadowblade Helmet (N)
    [50090] = 51186, -- Shadowblade Legplates -> Sanctified Shadowblade Legplates (N)
    [50094] = 51129, -- Scourgelord Battleplate -> Sanctified Scourgelord Battleplate (N)
    [50095] = 51128, -- Scourgelord Gauntlets -> Sanctified Scourgelord Gauntlets (N)
    [50096] = 51127, -- Scourgelord Helmet -> Sanctified Scourgelord Helmet (N)
    [50097] = 51126, -- Scourgelord Legplates -> Sanctified Scourgelord Legplates (N)
    [50098] = 51125, -- Scourgelord Shoulderplates -> Sanctified Scourgelord Shoulderplates (N)
    [50105] = 51185, -- Shadowblade Pauldrons -> Sanctified Shadowblade Pauldrons (N)
    [50106] = 51139, -- Lasherweave Robes -> Sanctified Lasherweave Robes (N)
    [50107] = 51138, -- Lasherweave Gauntlets -> Sanctified Lasherweave Gauntlets (N)
    [50108] = 51137, -- Lasherweave Helmet -> Sanctified Lasherweave Helmet (N)
    [50109] = 51136, -- Lasherweave Legplates -> Sanctified Lasherweave Legplates (N)
    [50113] = 51135, -- Lasherweave Pauldrons -> Sanctified Lasherweave Pauldrons (N)
    [50114] = 51154, -- Ahn'Kahar Blood Hunter's Handguards -> Sanctified Ahn'Kahar Blood Hunter's Handguards (N)
    [50115] = 51153, -- Ahn'Kahar Blood Hunter's Headpiece -> Sanctified Ahn'Kahar Blood Hunter's Headpiece (N)
    [50116] = 51152, -- Ahn'Kahar Blood Hunter's Legguards -> Sanctified Ahn'Kahar Blood Hunter's Legguards (N)
    [50117] = 51151, -- Ahn'Kahar Blood Hunter's Spaulders -> Sanctified Ahn'Kahar Blood Hunter's Spaulders (N)
    [50118] = 51150, -- Ahn'Kahar Blood Hunter's Tunic -> Sanctified Ahn'Kahar Blood Hunter's Tunic (N)
    [50240] = 51209, -- Dark Coven Gloves -> Sanctified Dark Coven Gloves (N)
    [50241] = 51208, -- Dark Coven Hood -> Sanctified Dark Coven Hood (N)
    [50242] = 51207, -- Dark Coven Leggings -> Sanctified Dark Coven Leggings (N)
    [50243] = 51206, -- Dark Coven Robe -> Sanctified Dark Coven Robe (N)
    [50244] = 51205, -- Dark Coven Shoulderpads -> Sanctified Dark Coven Shoulderpads (N)
    [50275] = 51159, -- Bloodmage Gloves -> Sanctified Bloodmage Gloves (N)
    [50276] = 51158, -- Bloodmage Hood -> Sanctified Bloodmage Hood (N)
    [50277] = 51157, -- Bloodmage Leggings -> Sanctified Bloodmage Leggings (N)
    [50278] = 51156, -- Bloodmage Robe -> Sanctified Bloodmage Robe (N)
    [50279] = 51155, -- Bloodmage Shoulderpads -> Sanctified Bloodmage Shoulderpads (N)
    [50324] = 51160, -- Lightsworn Shoulderplates -> Sanctified Lightsworn Shoulderplates (N)
    [50325] = 51161, -- Lightsworn Legplates -> Sanctified Lightsworn Legplates (N)
    [50326] = 51162, -- Lightsworn Helmet -> Sanctified Lightsworn Helmet (N)
    [50327] = 51163, -- Lightsworn Gauntlets -> Sanctified Lightsworn Gauntlets (N)
    [50328] = 51164, -- Lightsworn Battleplate -> Sanctified Lightsworn Battleplate (N)
    [50375] = 50388, -- Ashen Band of Courage -> Ashen Band of Greater Courage
    [50376] = 50387, -- Ashen Band of Vengeance -> Ashen Band of Greater Vengeance
    [50377] = 50384, -- Ashen Band of Destruction -> Ashen Band of Greater Destruction
    [50378] = 50386, -- Ashen Band of Wisdom -> Ashen Band of Greater Wisdom
    [50384] = 50397, -- Ashen Band of Greater Destruction -> Ashen Band of Unmatched Destruction
    [50386] = 50399, -- Ashen Band of Greater Wisdom -> Ashen Band of Unmatched Wisdom
    [50387] = 50401, -- Ashen Band of Greater Vengeance -> Ashen Band of Unmatched Vengeance
    [50388] = 50403, -- Ashen Band of Greater Courage -> Ashen Band of Unmatched Courage
    [50391] = 51183, -- Crimson Acolyte Handwraps -> Sanctified Crimson Acolyte Handwraps (N)
    [50392] = 51184, -- Crimson Acolyte Cowl -> Sanctified Crimson Acolyte Cowl (N)
    [50393] = 51181, -- Crimson Acolyte Pants -> Sanctified Crimson Acolyte Pants (N)
    [50394] = 51180, -- Crimson Acolyte Raiments -> Sanctified Crimson Acolyte Raiments (N)
    [50396] = 51182, -- Crimson Acolyte Mantle -> Sanctified Crimson Acolyte Mantle (N)
    [50397] = 50398, -- Ashen Band of Unmatched Destruction -> Ashen Band of Endless Destruction
    [50399] = 50400, -- Ashen Band of Unmatched Wisdom -> Ashen Band of Endless Wisdom
    [50401] = 50402, -- Ashen Band of Unmatched Vengeance -> Ashen Band of Endless Vengeance
    [50403] = 50404, -- Ashen Band of Unmatched Courage -> Ashen Band of Endless Courage
    [50765] = 51178, -- Crimson Acolyte Hood -> Sanctified Crimson Acolyte Hood (N)
    [50766] = 51179, -- Crimson Acolyte Gloves -> Sanctified Crimson Acolyte Gloves (N)
    [50767] = 51175, -- Crimson Acolyte Shoulderpads -> Sanctified Crimson Acolyte Shoulderpads (N)
    [50768] = 51176, -- Crimson Acolyte Robe -> Sanctified Crimson Acolyte Robe (N)
    [50769] = 51177, -- Crimson Acolyte Leggings -> Sanctified Crimson Acolyte Leggings (N)
    [50819] = 51147, -- Lasherweave Mantle -> Sanctified Lasherweave Mantle (N)
    [50820] = 51146, -- Lasherweave Trousers -> Sanctified Lasherweave Trousers (N)
    [50821] = 51149, -- Lasherweave Cover -> Sanctified Lasherweave Cover (N)
    [50822] = 51148, -- Lasherweave Gloves -> Sanctified Lasherweave Gloves (N)
    [50823] = 51145, -- Lasherweave Vestment -> Sanctified Lasherweave Vestment (N)
    [50824] = 51140, -- Lasherweave Shoulderpads -> Sanctified Lasherweave Shoulderpads (N)
    [50825] = 51142, -- Lasherweave Legguards -> Sanctified Lasherweave Legguards (N)
    [50826] = 51143, -- Lasherweave Headguard -> Sanctified Lasherweave Headguard (N)
    [50827] = 51144, -- Lasherweave Handgrips -> Sanctified Lasherweave Handgrips (N)
    [50828] = 51141, -- Lasherweave Raiment -> Sanctified Lasherweave Raiment (N)
    [50830] = 51195, -- Frost Witch's Chestguard -> Sanctified Frost Witch's Chestguard (N)
    [50831] = 51196, -- Frost Witch's Grips -> Sanctified Frost Witch's Grips (N)
    [50832] = 51197, -- Frost Witch's Faceguard -> Sanctified Frost Witch's Faceguard (N)
    [50833] = 51198, -- Frost Witch's War-Kilt -> Sanctified Frost Witch's War-Kilt (N)
    [50834] = 51199, -- Frost Witch's Shoulderguards -> Sanctified Frost Witch's Shoulderguards (N)
    [50835] = 51190, -- Frost Witch's Tunic -> Sanctified Frost Witch's Tunic (N)
    [50836] = 51191, -- Frost Witch's Handguards -> Sanctified Frost Witch's Handguards (N)
    [50837] = 51192, -- Frost Witch's Headpiece -> Sanctified Frost Witch's Headpiece (N)
    [50838] = 51193, -- Frost Witch's Legguards -> Sanctified Frost Witch's Legguards (N)
    [50839] = 51194, -- Frost Witch's Spaulders -> Sanctified Frost Witch's Spaulders (N)
    [50841] = 51200, -- Frost Witch's Hauberk -> Sanctified Frost Witch's Hauberk (N)
    [50842] = 51201, -- Frost Witch's Gloves -> Sanctified Frost Witch's Gloves (N)
    [50843] = 51202, -- Frost Witch's Helm -> Sanctified Frost Witch's Helm (N)
    [50844] = 51203, -- Frost Witch's Kilt -> Sanctified Frost Witch's Kilt (N)
    [50845] = 51204, -- Frost Witch's Shoulderpads -> Sanctified Frost Witch's Shoulderpads (N)
    [50846] = 51215, -- Ymirjar Lord's Pauldrons -> Sanctified Ymirjar Lord's Pauldrons (N)
    [50847] = 51216, -- Ymirjar Lord's Legguards -> Sanctified Ymirjar Lord's Legguards (N)
    [50848] = 51218, -- Ymirjar Lord's Greathelm -> Sanctified Ymirjar Lord's Greathelm (N)
    [50849] = 51217, -- Ymirjar Lord's Handguards -> Sanctified Ymirjar Lord's Handguards (N)
    [50850] = 51219, -- Ymirjar Lord's Breastplate -> Sanctified Ymirjar Lord's Breastplate (N)
    [50853] = 51130, -- Scourgelord Pauldrons -> Sanctified Scourgelord Pauldrons (N)
    [50854] = 51131, -- Scourgelord Legguards -> Sanctified Scourgelord Legguards (N)
    [50855] = 51133, -- Scourgelord Faceguard -> Sanctified Scourgelord Faceguard (N)
    [50856] = 51132, -- Scourgelord Handguards -> Sanctified Scourgelord Handguards (N)
    [50857] = 51134, -- Scourgelord Chestguard -> Sanctified Scourgelord Chestguard (N)
    [50860] = 51170, -- Lightsworn Shoulderguards -> Sanctified Lightsworn Shoulderguards (N)
    [50861] = 51171, -- Lightsworn Legguards -> Sanctified Lightsworn Legguards (N)
    [50862] = 51173, -- Lightsworn Faceguard -> Sanctified Lightsworn Faceguard (N)
    [50863] = 51172, -- Lightsworn Handguards -> Sanctified Lightsworn Handguards (N)
    [50864] = 51174, -- Lightsworn Chestguard -> Sanctified Lightsworn Chestguard (N)
    [50865] = 51166, -- Lightsworn Spaulders -> Sanctified Lightsworn Spaulders (N)
    [50866] = 51168, -- Lightsworn Greaves -> Sanctified Lightsworn Greaves (N)
    [50867] = 51167, -- Lightsworn Headpiece -> Sanctified Lightsworn Headpiece (N)
    [50868] = 51169, -- Lightsworn Gloves -> Sanctified Lightsworn Gloves (N)
    [50869] = 51165, -- Lightsworn Tunic -> Sanctified Lightsworn Tunic (N)
    [51125] = 51314, -- Sanctified Scourgelord Shoulderplates (N) -> Sanctified Scourgelord Shoulderplates (H)
    [51126] = 51313, -- Sanctified Scourgelord Legplates (N) -> Sanctified Scourgelord Legplates (H)
    [51127] = 51312, -- Sanctified Scourgelord Helmet (N) -> Sanctified Scourgelord Helmet (H)
    [51128] = 51311, -- Sanctified Scourgelord Gauntlets (N) -> Sanctified Scourgelord Gauntlets (H)
    [51129] = 51310, -- Sanctified Scourgelord Battleplate (N) -> Sanctified Scourgelord Battleplate (H)
    [51130] = 51309, -- Sanctified Scourgelord Pauldrons (N) -> Sanctified Scourgelord Pauldrons (H)
    [51131] = 51308, -- Sanctified Scourgelord Legguards (N) -> Sanctified Scourgelord Legguards (H)
    [51132] = 51307, -- Sanctified Scourgelord Handguards (N) -> Sanctified Scourgelord Handguards (H)
    [51133] = 51306, -- Sanctified Scourgelord Faceguard (N) -> Sanctified Scourgelord Faceguard (H)
    [51134] = 51305, -- Sanctified Scourgelord Chestguard (N) -> Sanctified Scourgelord Chestguard (H)
    [51135] = 51304, -- Sanctified Lasherweave Pauldrons (N) -> Sanctified Lasherweave Pauldrons (H)
    [51136] = 51303, -- Sanctified Lasherweave Legplates (N) -> Sanctified Lasherweave Legplates (H)
    [51137] = 51302, -- Sanctified Lasherweave Helmet (N) -> Sanctified Lasherweave Helmet (H)
    [51138] = 51301, -- Sanctified Lasherweave Gauntlets (N) -> Sanctified Lasherweave Gauntlets (H)
    [51139] = 51300, -- Sanctified Lasherweave Robes (N) -> Sanctified Lasherweave Robes (H)
    [51140] = 51299, -- Sanctified Lasherweave Shoulderpads (N) -> Sanctified Lasherweave Shoulderpads (H)
    [51141] = 51298, -- Sanctified Lasherweave Raiment (N) -> Sanctified Lasherweave Raiment (H)
    [51142] = 51297, -- Sanctified Lasherweave Legguards (N) -> Sanctified Lasherweave Legguards (H)
    [51143] = 51296, -- Sanctified Lasherweave Headguard (N) -> Sanctified Lasherweave Headguard (H)
    [51144] = 51295, -- Sanctified Lasherweave Handgrips (N) -> Sanctified Lasherweave Handgrips (H)
    [51145] = 51294, -- Sanctified Lasherweave Vestment (N) -> Sanctified Lasherweave Vestment (H)
    [51146] = 51293, -- Sanctified Lasherweave Trousers (N) -> Sanctified Lasherweave Trousers (H)
    [51147] = 51292, -- Sanctified Lasherweave Mantle (N) -> Sanctified Lasherweave Mantle (H)
    [51148] = 51291, -- Sanctified Lasherweave Gloves (N) -> Sanctified Lasherweave Gloves (H)
    [51149] = 51290, -- Sanctified Lasherweave Cover (N) -> Sanctified Lasherweave Cover (H)
    [51150] = 51289, -- Sanctified Ahn'Kahar Blood Hunter's Tunic (N) -> Sanctified Ahn'Kahar Blood Hunter's Tunic (H)
    [51151] = 51288, -- Sanctified Ahn'Kahar Blood Hunter's Spaulders (N) -> Sanctified Ahn'Kahar Blood Hunter's Spaulders (H)
    [51152] = 51287, -- Sanctified Ahn'Kahar Blood Hunter's Legguards (N) -> Sanctified Ahn'Kahar Blood Hunter's Legguards (H)
    [51153] = 51286, -- Sanctified Ahn'Kahar Blood Hunter's Headpiece (N) -> Sanctified Ahn'Kahar Blood Hunter's Headpiece (H)
    [51154] = 51285, -- Sanctified Ahn'Kahar Blood Hunter's Handguards (N) -> Sanctified Ahn'Kahar Blood Hunter's Handguards (H)
    [51155] = 51284, -- Sanctified Bloodmage Shoulderpads (N) -> Sanctified Bloodmage Shoulderpads (H)
    [51156] = 51283, -- Sanctified Bloodmage Robe (N) -> Sanctified Bloodmage Robe (H)
    [51157] = 51282, -- Sanctified Bloodmage Leggings (N) -> Sanctified Bloodmage Leggings (H)
    [51158] = 51281, -- Sanctified Bloodmage Hood (N) -> Sanctified Bloodmage Hood (H)
    [51159] = 51280, -- Sanctified Bloodmage Gloves (N) -> Sanctified Bloodmage Gloves (H)
    [51160] = 51279, -- Sanctified Lightsworn Shoulderplates (N) -> Sanctified Lightsworn Shoulderplates (H)
    [51161] = 51278, -- Sanctified Lightsworn Legplates (N) -> Sanctified Lightsworn Legplates (H)
    [51162] = 51277, -- Sanctified Lightsworn Helmet (N) -> Sanctified Lightsworn Helmet (H)
    [51163] = 51276, -- Sanctified Lightsworn Gauntlets (N) -> Sanctified Lightsworn Gauntlets (H)
    [51164] = 51275, -- Sanctified Lightsworn Battleplate (N) -> Sanctified Lightsworn Battleplate (H)
    [51165] = 51274, -- Sanctified Lightsworn Tunic (N) -> Sanctified Lightsworn Tunic (H)
    [51166] = 51273, -- Sanctified Lightsworn Spaulders (N) -> Sanctified Lightsworn Spaulders (H)
    [51167] = 51272, -- Sanctified Lightsworn Headpiece (N) -> Sanctified Lightsworn Headpiece (H)
    [51168] = 51271, -- Sanctified Lightsworn Greaves (N) -> Sanctified Lightsworn Greaves (H)
    [51169] = 51270, -- Sanctified Lightsworn Gloves (N) -> Sanctified Lightsworn Gloves (H)
    [51170] = 51269, -- Sanctified Lightsworn Shoulderguards (N) -> Sanctified Lightsworn Shoulderguards (H)
    [51171] = 51268, -- Sanctified Lightsworn Legguards (N) -> Sanctified Lightsworn Legguards (H)
    [51172] = 51267, -- Sanctified Lightsworn Handguards (N) -> Sanctified Lightsworn Handguards (H)
    [51173] = 51266, -- Sanctified Lightsworn Faceguard (N) -> Sanctified Lightsworn Faceguard (H)
    [51174] = 51265, -- Sanctified Lightsworn Chestguard (N) -> Sanctified Lightsworn Chestguard (H)
    [51175] = 51264, -- Sanctified Crimson Acolyte Shoulderpads (N) -> Sanctified Crimson Acolyte Shoulderpads (H)
    [51176] = 51263, -- Sanctified Crimson Acolyte Robe (N) -> Sanctified Crimson Acolyte Robe (H)
    [51177] = 51262, -- Sanctified Crimson Acolyte Leggings (N) -> Sanctified Crimson Acolyte Leggings (H)
    [51178] = 51261, -- Sanctified Crimson Acolyte Hood (N) -> Sanctified Crimson Acolyte Hood (H)
    [51179] = 51260, -- Sanctified Crimson Acolyte Gloves (N) -> Sanctified Crimson Acolyte Gloves (H)
    [51180] = 51259, -- Sanctified Crimson Acolyte Raiments (N) -> Sanctified Crimson Acolyte Raiments (H)
    [51181] = 51258, -- Sanctified Crimson Acolyte Pants (N) -> Sanctified Crimson Acolyte Pants (H)
    [51182] = 51257, -- Sanctified Crimson Acolyte Mantle (N) -> Sanctified Crimson Acolyte Mantle (H)
    [51183] = 51256, -- Sanctified Crimson Acolyte Handwraps (N) -> Sanctified Crimson Acolyte Handwraps (H)
    [51184] = 51255, -- Sanctified Crimson Acolyte Cowl (N) -> Sanctified Crimson Acolyte Cowl (H)
    [51185] = 51254, -- Sanctified Shadowblade Pauldrons (N) -> Sanctified Shadowblade Pauldrons (H)
    [51186] = 51253, -- Sanctified Shadowblade Legplates (N) -> Sanctified Shadowblade Legplates (H)
    [51187] = 51252, -- Sanctified Shadowblade Helmet (N) -> Sanctified Shadowblade Helmet (H)
    [51188] = 51251, -- Sanctified Shadowblade Gauntlets (N) -> Sanctified Shadowblade Gauntlets (H)
    [51189] = 51250, -- Sanctified Shadowblade Breastplate (N) -> Sanctified Shadowblade Breastplate (H)
    [51190] = 51249, -- Sanctified Frost Witch's Tunic (N) -> Sanctified Frost Witch's Tunic (H)
    [51191] = 51248, -- Sanctified Frost Witch's Handguards (N) -> Sanctified Frost Witch's Handguards (H)
    [51192] = 51247, -- Sanctified Frost Witch's Headpiece (N) -> Sanctified Frost Witch's Headpiece (H)
    [51193] = 51246, -- Sanctified Frost Witch's Legguards (N) -> Sanctified Frost Witch's Legguards (H)
    [51194] = 51245, -- Sanctified Frost Witch's Spaulders (N) -> Sanctified Frost Witch's Spaulders (H)
    [51195] = 51244, -- Sanctified Frost Witch's Chestguard (N) -> Sanctified Frost Witch's Chestguard (H)
    [51196] = 51243, -- Sanctified Frost Witch's Grips (N) -> Sanctified Frost Witch's Grips (H)
    [51197] = 51242, -- Sanctified Frost Witch's Faceguard (N) -> Sanctified Frost Witch's Faceguard (H)
    [51198] = 51241, -- Sanctified Frost Witch's War-Kilt (N) -> Sanctified Frost Witch's War-Kilt (H)
    [51199] = 51240, -- Sanctified Frost Witch's Shoulderguards (N) -> Sanctified Frost Witch's Shoulderguards (H)
    [51200] = 51239, -- Sanctified Frost Witch's Hauberk (N) -> Sanctified Frost Witch's Hauberk (H)
    [51201] = 51238, -- Sanctified Frost Witch's Gloves (N) -> Sanctified Frost Witch's Gloves (H)
    [51202] = 51237, -- Sanctified Frost Witch's Helm (N) -> Sanctified Frost Witch's Helm (H)
    [51203] = 51236, -- Sanctified Frost Witch's Kilt (N) -> Sanctified Frost Witch's Kilt (H)
    [51204] = 51235, -- Sanctified Frost Witch's Shoulderpads (N) -> Sanctified Frost Witch's Shoulderpads (H)
    [51205] = 51234, -- Sanctified Dark Coven Shoulderpads (N) -> Sanctified Dark Coven Shoulderpads (H)
    [51206] = 51233, -- Sanctified Dark Coven Robe (N) -> Sanctified Dark Coven Robe (H)
    [51207] = 51232, -- Sanctified Dark Coven Leggings (N) -> Sanctified Dark Coven Leggings (H)
    [51208] = 51231, -- Sanctified Dark Coven Hood (N) -> Sanctified Dark Coven Hood (H)
    [51209] = 51230, -- Sanctified Dark Coven Gloves (N) -> Sanctified Dark Coven Gloves (H)
    [51210] = 51229, -- Sanctified Ymirjar Lord's Shoulderplates (N) -> Sanctified Ymirjar Lord's Shoulderplates (H)
    [51211] = 51228, -- Sanctified Ymirjar Lord's Legplates (N) -> Sanctified Ymirjar Lord's Legplates (H)
    [51212] = 51227, -- Sanctified Ymirjar Lord's Helmet (N) -> Sanctified Ymirjar Lord's Helmet (H)
    [51213] = 51226, -- Sanctified Ymirjar Lord's Gauntlets (N) -> Sanctified Ymirjar Lord's Gauntlets (H)
    [51214] = 51225, -- Sanctified Ymirjar Lord's Battleplate (N) -> Sanctified Ymirjar Lord's Battleplate (H)
    [51215] = 51224, -- Sanctified Ymirjar Lord's Pauldrons (N) -> Sanctified Ymirjar Lord's Pauldrons (H)
    [51216] = 51223, -- Sanctified Ymirjar Lord's Legguards (N) -> Sanctified Ymirjar Lord's Legguards (H)
    [51217] = 51222, -- Sanctified Ymirjar Lord's Handguards (N) -> Sanctified Ymirjar Lord's Handguards (H)
    [51218] = 51221, -- Sanctified Ymirjar Lord's Greathelm (N) -> Sanctified Ymirjar Lord's Greathelm (H)
    [51219] = 51220, -- Sanctified Ymirjar Lord's Breastplate (N) -> Sanctified Ymirjar Lord's Breastplate (H)
    [52569] = 52570, -- Ashen Band of Might -> Ashen Band of Greater Might
    [52570] = 52571, -- Ashen Band of Greater Might -> Ashen Band of Unmatched Might
    [52571] = 52572, -- Ashen Band of Unmatched Might -> Ashen Band of Endless Might
}

-- ʕ •ᴥ•ʔ✿ Registration function ✿ ʕ •ᴥ•ʔ
---@return nil
local function RegisterRules()
    if not ArkInventoryRules then
        print("|cffff0000[ArkInventoryRules_Upgradeable]|r ERROR: ArkInventoryRules not loaded!")
        return
    end

    ArkInventoryRules.Register(rule, 'UPGRADEABLE', rule.upgradeable)
    print("|cffffd200[ArkInventoryRules_Upgradeable]|r Module loaded, upgradeable() rule registered")
    print(
    "|cffffd200[ArkInventoryRules_Upgradeable]|r Available filters: upgradeable(), upgradeable(\"char\"), upgradeable(\"acc\")")
    print("|cffffd200[ArkInventoryRules_Upgradeable]|r Test command: /aiu test <id> or /aiu test [itemlink]")
end

-- ʕ •ᴥ•ʔ✿ Register the upgradeable() rule when the addon loads ✿ ʕ •ᴥ•ʔ
---@return nil
function rule:OnEnable()
    RegisterRules()
end

-- ʕ •ᴥ•ʔ✿ Fallback registration via event ✿ ʕ •ᴥ•ʔ
---@type Frame
local frame = CreateFrame("Frame") or error("Failed to create frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "ArkInventoryRules" or addonName == "ArkInventoryRules_Upgradeable" then
        if ArkInventoryRules and ArkInventoryRules.Register then
            RegisterRules()
            frame:UnregisterEvent("ADDON_LOADED")
        end
    end
end)

-- ʕ •ᴥ•ʔ✿ Helper: Get all final upgrade targets following the upgrade chain ✿ ʕ •ᴥ•ʔ
---@param itemId integer The starting item ID
---@return table<integer, boolean> Map of all final target item IDs that cannot upgrade further
local function GetUpgradeChainTargets(itemId)
    ---@type table<integer, boolean>
    local targets = {}
    ---@type table<integer, boolean>
    local visited = {}

    ---@type integer | nil
    local currentId = itemId

    -- Follow the upgrade chain
    while currentId and not visited[currentId] do
        visited[currentId] = true

        ---@type integer | nil
        local nextId = UPGRADE_MAP[currentId]
        if nextId then
            currentId = nextId
        else
            -- No further upgrade, this is a final target
            targets[currentId] = true
            break
        end
    end

    return targets
end

-- ʕ •ᴥ•ʔ✿ Helper: Check if item can be attuned by current character ✿ ʕ •ᴥ•ʔ
---@param itemId integer The item ID to check
---@return boolean Whether the item can be attuned by character
local function IsAttuneableByCharacter(itemId)
    if not GetHighestAttunePct then
        return false
    end

    ---@type number | nil
    local attunePct = GetHighestAttunePct(itemId)
    return attunePct ~= nil and attunePct >= 0
end

-- ʕ •ᴥ•ʔ✿ Helper: Check if item can be attuned by account (conservative) ✿ ʕ •ᴥ•ʔ
---@param itemId integer The item ID to check
---@return boolean Whether the item might be attunable by someone in the account
local function IsAttuneableByAccount(itemId)
    if not GetHighestAttunePct then
        return false
    end

    -- For account-wide check, we assume if it's attunable by character, it's attunable by account
    -- In a Synastria context, this might need to check alt skills or account-wide attunement pools
    -- For now, use the same check as character (conservative approach)
    ---@type number | nil
    local attunePct = GetHighestAttunePct(itemId)
    return attunePct ~= nil and attunePct >= 0
end

-- ʕ •ᴥ•ʔ✿ UPGRADEABLE Rule Implementation ✿ ʕ •ᴥ•ʔ
-- Returns true if the item is upgradeable
-- Usage: upgradeable() - matches any upgradeable item
-- Usage: upgradeable("char") or upgradeable("character") - matches upgradeable items where final upgrade is attunable by character
-- Usage: upgradeable("acc") or upgradeable("account") - matches upgradeable items where final upgrade is attunable by account
---@return boolean Whether the item matches the upgradeable filter
function rule.upgradeable(...)
    -- Ensure we're evaluating an item
    if not ArkInventoryRules.Object.h or ArkInventoryRules.Object.class ~= 'item' then
        return false
    end

    -- Get the item ID from the hyperlink
    ---@type number | nil
    local itemId = nil
    if Custom_GetIdFromLink then
        ---@type number | nil
        local customId = Custom_GetIdFromLink(ArkInventoryRules.Object.h)
        if customId then
            itemId = customId
        end
    end

    if not itemId or itemId == 0 then
        -- Fallback: try to extract from standard item link format
        ---@type string | nil
        local linkStr = tostring(ArkInventoryRules.Object.h)
        ---@type string | nil
        local id = linkStr:match("item:(%d+)")
        if id then
            itemId = tonumber(id)
        end
    end

    if not itemId or itemId <= 0 then
        return false
    end

    -- Check if this item is upgradeable (has an entry in the map)
    if not UPGRADE_MAP[itemId] then
        return false
    end

    ---@type integer
    local ac = select('#', ...)

    -- If no arguments, return true (item is upgradeable)
    if ac == 0 then
        return true
    end

    -- If argument provided, check type
    ---@type any
    local arg = select(1, ...)
    if type(arg) ~= "string" then
        error(string.format(ArkInventory.Localise["RULE_FAILED_ARGUMENT_IS_INVALID"], 'upgradeable', 1,
            string.format("%s", ArkInventory.Localise["STRING"]), 0))
    end

    ---@type string
    local filterType = string.lower(arg)

    -- Get all final upgrade targets
    ---@type table<integer, boolean>
    local targets = GetUpgradeChainTargets(itemId)

    -- Check each final target
    if filterType == "char" or filterType == "character" then
        -- Match if ANY final target is attunable by character
        for targetId in pairs(targets) do
            if IsAttuneableByCharacter(targetId) then
                return true
            end
        end
        return false
    elseif filterType == "acc" or filterType == "account" then
        -- Match if ANY final target is attunable by account
        for targetId in pairs(targets) do
            if IsAttuneableByAccount(targetId) then
                return true
            end
        end
        return false
    else
        -- Unknown filter type
        error(string.format(
            "upgradeable() filter type '%s' is not recognized. Use 'char', 'character', 'acc', or 'account'.", arg))
    end
end

-- ʕ •ᴥ•ʔ✿ Testing Command: /aiu test <id> or /aiu test [itemlink] ✿ ʕ •ᴥ•ʔ
-- Test all three ArkInventory Rules with a given item

---@diagnostic disable: undefined-global
---@type table<string, function> | nil
local SlashCmdList = _G.SlashCmdList
---@diagnostic enable: undefined-global

---@param msg string The command message after /aiu
---@return nil
local function HandleTestCommand(msg)
    local args = {}
    for word in string.gmatch(msg, "%S+") do
        table.insert(args, word)
    end

    if not args[1] or args[1] ~= "test" then
        print("|cffffd200[ArkInventory Rules]|r Usage: /aiu test <itemId> or /aiu test [itemlink]")
        print("|cffffd200                  |r Tests all rule functions (upgradeable, ahset, belowavgilvl)")
        return
    end

    if not args[2] then
        print("|cffff0000[ArkInventory Rules]|r Missing item ID or itemlink!")
        print("|cffffd200                  |r Usage: /aiu test <itemId> or /aiu test [itemlink]")
        return
    end

    ---@type string
    local itemInput = args[2]

    ---@type string | nil
    local itemLink = nil
    ---@type integer | nil
    local itemId = nil

    -- Check if input is an item link
    if string.find(itemInput, "item:") then
        itemLink = itemInput
        -- Extract ID from link: |cffffffff|Hitem:itemId:...|h[Name]|h|r
        itemId = tonumber(string.match(itemLink, "item:(%d+)"))
    else
        -- Try to parse as item ID
        itemId = tonumber(itemInput)
        if itemId then
            -- Create a simple item link from the ID
            itemLink = string.format("item:%d:0:0:0:0:0:0:0:0:0:0:0:0", itemId)
        end
    end

    if not itemId or itemId <= 0 then
        print("|cffff0000[ArkInventory Rules]|r Invalid item ID or itemlink!")
        return
    end

    print("|cffffd200========== ArkInventory Rules Test ==========|r")
    print("|cffffd200Item ID:|r " .. itemId)
    print("|cffffd200Item Link:|r " .. (itemLink or "unknown"))

    -- Mock the ArkInventoryRules.Object for testing
    ---@type table
    local originalObject = ArkInventoryRules.Object
    ArkInventoryRules.Object = {
        h = itemLink or "",
        class = "item"
    }

    -- Test upgradeable() rule
    print("|cffffd200|r")
    print("|cffffd200[1] upgradeable() rule:|r")
    do
        ---@type boolean, any
        local res, result = pcall(rule.upgradeable)
        if res then
            print("  |cff00ff00upgradeable():|r " .. (result and "TRUE" or "FALSE"))
        else
            print("  |cffff0000ERROR:|r " .. tostring(result))
        end

        -- Test with "char" parameter
        local res_char, result_char = pcall(rule.upgradeable, "char")
        if res_char then
            print("  |cff00ff00upgradeable('char'):|r " .. (result_char and "TRUE" or "FALSE"))
        else
            print("  |cffff0000ERROR:|r " .. tostring(result_char))
        end

        -- Test with "acc" parameter
        local res_acc, result_acc = pcall(rule.upgradeable, "acc")
        if res_acc then
            print("  |cff00ff00upgradeable('acc'):|r " .. (result_acc and "TRUE" or "FALSE"))
        else
            print("  |cffff0000ERROR:|r " .. tostring(result_acc))
        end
    end

    -- Test ahset() rule via ArkInventoryRules module system
    print("|cffffd200|r")
    print("|cffffd200[2] ahset() rule:|r")
    do
        -- Try to access AttuneHelper module through ArkInventoryRules
        ---@type any
        local attuneModule = ArkInventoryRules and ArkInventoryRules:GetModule("ArkInventoryRules_AttuneHelper", true)
        if attuneModule and type(attuneModule.ahset) == "function" then
            ---@type boolean
            local result = attuneModule.ahset()
            print("  |cff00ff00ahset():|r " .. (result and "TRUE" or "FALSE"))
        else
            print("  |cffa0a0a0[N/A]|r ArkInventoryRules_AttuneHelper not loaded")
        end
    end

    -- Test belowavgilvl() rule via ArkInventoryRules module system
    print("|cffffd200|r")
    print("|cffffd200[3] belowavgilvl() rule:|r")
    do
        -- Try to access ItemLevel module through ArkInventoryRules
        ---@type any
        local itemLevelModule = ArkInventoryRules and ArkInventoryRules:GetModule("ArkInventoryRules_ItemLevel", true)
        if itemLevelModule and type(itemLevelModule.belowavgilvl) == "function" then
            ---@type boolean
            local result = itemLevelModule.belowavgilvl()
            print("  |cff00ff00belowavgilvl():|r " .. (result and "TRUE" or "FALSE"))

            -- Test belowahsetavgilvl
            if itemLevelModule and type(itemLevelModule.belowahsetavgilvl) == "function" then
                ---@type boolean
                local result2 = itemLevelModule.belowahsetavgilvl()
                print("  |cff00ff00belowahsetavgilvl():|r " .. (result2 and "TRUE" or "FALSE"))
            end
        else
            print("  |cffa0a0a0[N/A]|r ArkInventoryRules_ItemLevel not loaded")
        end
    end

    -- Restore original object
    ArkInventoryRules.Object = originalObject

    print("|cffffd200==========================================|r")
end

-- Register the slash command
if SlashCmdList then
    SLASH_ARKINV_RULES_TEST1 = "/aiu"
    SlashCmdList["ARKINV_RULES_TEST"] = HandleTestCommand
end
