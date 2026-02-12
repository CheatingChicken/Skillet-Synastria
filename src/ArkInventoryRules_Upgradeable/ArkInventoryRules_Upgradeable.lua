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
-- Maps source itemId -> target itemId for all known upgrades
-- Data extracted from all 10 sheets: Dalaran Rings, Sunmote Gear, Crafting, T10 Gear, T0.5 Gear,
-- Brood of Nozdormu, Ashen Verdict, Questing, Misc.
---@type table<integer, integer>
local UPGRADE_MAP = {
    [2944] = 2943,
    [4243] = 4244,
    [4246] = 4249,
    [4255] = 3844,
    [4368] = 4385,
    [4385] = 10500,
    [5966] = 7938,
    [7387] = 10721,
    [9149] = 13503,
    [10026] = 7189,
    [10500] = 16008,
    [10502] = 15999,
    [10543] = 10588,
    [13503] = 35749,
    [14044] = 15138,
    [16666] = 22102,
    [16667] = 22102,
    [16668] = 22101,
    [16669] = 22101,
    [16670] = 22096,
    [16671] = 22095,
    [16672] = 22099,
    [16673] = 22099,
    [16674] = 22060,
    [16675] = 22061,
    [16676] = 22015,
    [16677] = 22013,
    [16678] = 22017,
    [16679] = 22017,
    [16680] = 22010,
    [16681] = 22011,
    [16682] = 22064,
    [16683] = 22063,
    [16684] = 22066,
    [16685] = 22062,
    [16686] = 22065,
    [16687] = 22067,
    [16688] = 22069,
    [16689] = 22068,
    [16690] = 22083,
    [16691] = 22084,
    [16692] = 22081,
    [16693] = 22083,
    [16694] = 22085,
    [16695] = 22085,
    [16696] = 22081,
    [16697] = 22079,
    [16698] = 22075,
    [16699] = 22072,
    [16700] = 22075,
    [16701] = 22073,
    [16702] = 22077,
    [16703] = 22071,
    [16704] = 22076,
    [16705] = 22077,
    [16706] = 22113,
    [16707] = 22009,
    [16708] = 22008,
    [16709] = 22008,
    [16710] = 22004,
    [16711] = 22003,
    [16712] = 22006,
    [16713] = 22006,
    [16714] = 22108,
    [16715] = 22107,
    [16716] = 22110,
    [16717] = 22110,
    [16718] = 22112,
    [16719] = 22111,
    [16720] = 22109,
    [16721] = 22009,
    [16722] = 22088,
    [16723] = 22090,
    [16724] = 22086,
    [16725] = 22087,
    [16726] = 22089,
    [16727] = 22091,
    [16728] = 22093,
    [16729] = 22087,
    [16730] = 21997,
    [16731] = 21999,
    [16732] = 22000,
    [16733] = 22001,
    [16734] = 21995,
    [16735] = 21996,
    [16736] = 21998,
    [16737] = 21998,
    [17074] = 17223,
    [18608] = 18609,
    [21196] = 21197,
    [21197] = 21198,
    [21198] = 21199,
    [21199] = 21200,
    [21201] = 21202,
    [21202] = 21203,
    [21203] = 21204,
    [21204] = 21205,
    [21206] = 21207,
    [21207] = 21208,
    [21208] = 21209,
    [21209] = 21210,
    [23563] = 23564,
    [23564] = 23565,
    [28425] = 28426,
    [28426] = 28427,
    [28428] = 28429,
    [28429] = 28430,
    [28431] = 28432,
    [28432] = 28433,
    [28434] = 28435,
    [28435] = 28436,
    [28437] = 28438,
    [28438] = 28439,
    [28440] = 28441,
    [28441] = 28442,
    [28483] = 28484,
    [28484] = 28485,
    [32461] = 34354,
    [32472] = 35185,
    [32473] = 34357,
    [32474] = 34356,
    [32475] = 35184,
    [32476] = 34355,
    [32478] = 34353,
    [32479] = 35183,
    [32480] = 35182,
    [32494] = 34847,
    [32495] = 35181,
    [32649] = 32757,
    [34167] = 34382,
    [34169] = 34384,
    [34170] = 34386,
    [34180] = 34381,
    [34186] = 34383,
    [34188] = 34385,
    [34192] = 34388,
    [34193] = 34389,
    [34195] = 34392,
    [34202] = 34393,
    [34208] = 34390,
    [34209] = 34391,
    [34211] = 34397,
    [34212] = 34398,
    [34215] = 34394,
    [34216] = 34395,
    [34229] = 34396,
    [34233] = 34399,
    [34234] = 34408,
    [34243] = 34401,
    [34244] = 34404,
    [34245] = 34403,
    [34332] = 34402,
    [34339] = 34405,
    [34342] = 34406,
    [34345] = 34400,
    [34350] = 34409,
    [34351] = 34407,
    [40585] = 45691,
    [40586] = 45688,
    [41245] = 47590,
    [41355] = 47573,
    [41520] = 41544,
    [44934] = 45689,
    [44935] = 45690,
    [45688] = 48954,
    [45689] = 48955,
    [45690] = 48956,
    [45691] = 48957,
    [48954] = 51560,
    [48955] = 51558,
    [48956] = 51559,
    [48957] = 51557,
    [49302] = 49301,
    [49496] = 49497,
    [49888] = 49623,
    [50078] = 51214,
    [50079] = 51213,
    [50080] = 51212,
    [50081] = 51211,
    [50082] = 51210,
    [50087] = 51189,
    [50088] = 51188,
    [50089] = 51187,
    [50090] = 51186,
    [50094] = 51129,
    [50095] = 51128,
    [50096] = 51127,
    [50097] = 51126,
    [50098] = 51125,
    [50105] = 51185,
    [50106] = 51139,
    [50107] = 51138,
    [50108] = 51137,
    [50109] = 51136,
    [50113] = 51135,
    [50114] = 51154,
    [50115] = 51153,
    [50116] = 51152,
    [50117] = 51151,
    [50118] = 51150,
    [50240] = 51209,
    [50241] = 51208,
    [50242] = 51207,
    [50243] = 51206,
    [50244] = 51205,
    [50275] = 51159,
    [50276] = 51158,
    [50277] = 51157,
    [50278] = 51156,
    [50279] = 51155,
    [50324] = 51160,
    [50325] = 51161,
    [50326] = 51162,
    [50327] = 51163,
    [50328] = 51164,
    [50375] = 50388,
    [50376] = 50387,
    [50377] = 50384,
    [50378] = 50386,
    [50384] = 50397,
    [50386] = 50399,
    [50387] = 50401,
    [50388] = 50403,
    [50391] = 51183,
    [50392] = 51184,
    [50393] = 51181,
    [50394] = 51180,
    [50396] = 51182,
    [50397] = 50398,
    [50399] = 50400,
    [50401] = 50402,
    [50403] = 50404,
    [50765] = 51178,
    [50766] = 51179,
    [50767] = 51175,
    [50768] = 51176,
    [50769] = 51177,
    [50819] = 51147,
    [50820] = 51146,
    [50821] = 51149,
    [50822] = 51148,
    [50823] = 51145,
    [50824] = 51140,
    [50825] = 51142,
    [50826] = 51143,
    [50827] = 51144,
    [50828] = 51141,
    [50830] = 51195,
    [50831] = 51196,
    [50832] = 51197,
    [50833] = 51198,
    [50834] = 51199,
    [50835] = 51190,
    [50836] = 51191,
    [50837] = 51192,
    [50838] = 51193,
    [50839] = 51194,
    [50841] = 51200,
    [50842] = 51201,
    [50843] = 51202,
    [50844] = 51203,
    [50845] = 51204,
    [50846] = 51215,
    [50847] = 51216,
    [50848] = 51218,
    [50849] = 51217,
    [50850] = 51219,
    [50853] = 51130,
    [50854] = 51131,
    [50855] = 51133,
    [50856] = 51132,
    [50857] = 51134,
    [50860] = 51170,
    [50861] = 51171,
    [50862] = 51173,
    [50863] = 51172,
    [50864] = 51174,
    [50865] = 51166,
    [50866] = 51168,
    [50867] = 51167,
    [50868] = 51169,
    [50869] = 51165,
    [51125] = 51314,
    [51126] = 51313,
    [51127] = 51312,
    [51128] = 51311,
    [51129] = 51310,
    [51130] = 51309,
    [51131] = 51308,
    [51132] = 51307,
    [51133] = 51306,
    [51134] = 51305,
    [51135] = 51304,
    [51136] = 51303,
    [51137] = 51302,
    [51138] = 51301,
    [51139] = 51300,
    [51140] = 51299,
    [51141] = 51298,
    [51142] = 51297,
    [51143] = 51296,
    [51144] = 51295,
    [51145] = 51294,
    [51146] = 51293,
    [51147] = 51292,
    [51148] = 51291,
    [51149] = 51290,
    [51150] = 51289,
    [51151] = 51288,
    [51152] = 51287,
    [51153] = 51286,
    [51154] = 51285,
    [51155] = 51284,
    [51156] = 51283,
    [51157] = 51282,
    [51158] = 51281,
    [51159] = 51280,
    [51160] = 51279,
    [51161] = 51278,
    [51162] = 51277,
    [51163] = 51276,
    [51164] = 51275,
    [51165] = 51274,
    [51166] = 51273,
    [51167] = 51272,
    [51168] = 51271,
    [51169] = 51270,
    [51170] = 51269,
    [51171] = 51268,
    [51172] = 51267,
    [51173] = 51266,
    [51174] = 51265,
    [51175] = 51264,
    [51176] = 51263,
    [51177] = 51262,
    [51178] = 51261,
    [51179] = 51260,
    [51180] = 51259,
    [51181] = 51258,
    [51182] = 51257,
    [51183] = 51256,
    [51184] = 51255,
    [51185] = 51254,
    [51186] = 51253,
    [51187] = 51252,
    [51188] = 51251,
    [51189] = 51250,
    [51190] = 51249,
    [51191] = 51248,
    [51192] = 51247,
    [51193] = 51246,
    [51194] = 51245,
    [51195] = 51244,
    [51196] = 51243,
    [51197] = 51242,
    [51198] = 51241,
    [51199] = 51240,
    [51200] = 51239,
    [51201] = 51238,
    [51202] = 51237,
    [51203] = 51236,
    [51204] = 51235,
    [51205] = 51234,
    [51206] = 51233,
    [51207] = 51232,
    [51208] = 51231,
    [51209] = 51230,
    [51210] = 51229,
    [51211] = 51228,
    [51212] = 51227,
    [51213] = 51226,
    [51214] = 51225,
    [51215] = 51224,
    [51216] = 51223,
    [51217] = 51222,
    [51218] = 51221,
    [51219] = 51220,
    [52569] = 52570,
    [52570] = 52571,
    [52571] = 52572,
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
    print("|cffffd200[ArkInventoryRules_Upgradeable]|r Available filters: upgradeable(), upgradeable(\"char\"), upgradeable(\"acc\")")
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
        error(string.format("upgradeable() filter type '%s' is not recognized. Use 'char', 'character', 'acc', or 'account'.", arg))
    end
end
