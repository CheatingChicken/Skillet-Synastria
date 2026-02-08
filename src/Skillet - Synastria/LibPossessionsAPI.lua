---@meta LibPossessionsAPI
-- Type definitions for LibPossessions and its supported inventory addons
-- This is a meta file (annotation-only) for type checking

-- ========================================================================
--                        WoW Global Constants
-- ========================================================================

---@type string
FACTION_HORDE = "Horde"

---@type string
FACTION_ALLIANCE = "Alliance"

---@type number
NUM_BAG_SLOTS = 16

---@type table
ChatFrame1 = {}

-- ========================================================================
--                        Core WoW API Functions
-- ========================================================================

---@return string realmName The name of the current realm
function GetRealmName() end

---@return string playerName The name of the player character
function UnitName(unit) end

---@param unit string The unit token (e.g., "player")
---@return string race The race of the unit
---@return string raceLocalized The localized race name
function UnitRace(unit) end

---@param unit string The unit token (e.g., "player")
---@return string faction The faction code ("Horde" or "Alliance")
function UnitFactionGroup(unit) end

---@param str string String to trim
---@return string trimmed The trimmed string
function strtrim(str) end

---@param input string The input string to split
---@param delimiter string The delimiter to split on
---@return string ... The split string parts
function strsplit(input, delimiter) end

---@param item number|string The item ID or item link
---@return string? name Item name
---@return string? link Item link
---@return number? rarity Item rarity
---@return number? level Item level
---@return string? minLevel Minimum level
---@return string? type Item type
---@return string? subType Item subtype
---@return number? stackCount Stack count
---@return string? texture Item texture
---@return number? vendorPrice Vendor price
function GetItemInfo(item) end

---@param index number The addon index (1-based)
---@return string name The addon name
---@return nil title (unused)
---@return nil notes (unused)
---@return boolean enabled Whether addon is enabled
function GetAddOnInfo(index) end

---@return number count The number of loaded addons
function GetNumAddOns() end

---@param addonName string The name of the addon to check
---@return boolean loaded Whether the addon is loaded
function IsAddOnLoaded(addonName) end

---@param itemId number Item ID
---@param includeBank? boolean Include bank in count
---@return number count Item count
function GetItemCount(itemId, includeBank) end

---@param itemId number Item ID
---@return number? count Item count or nil
function GetInventoryCount(itemId) end

-- ========================================================================
--                        Sanity2 Addon (Inventory Tracker)
-- ========================================================================

---@class Sanity
---@field GetOwnersFor? fun(self: Sanity, itemName: string): table<string, table> | nil Owner data for item

---@type Sanity | nil
Sanity = nil

-- ========================================================================
--                        BagnonDB Addon (Bagnon Forever)
-- ========================================================================

---@class BagnonDBPlayer
---@field GetPlayers? fun(self: BagnonDBPlayer): fun(): string Iterator of player names
---@field GetItemCount? fun(self: BagnonDBPlayer, link: string, bag: number, playerName: string): number Item count

---@type BagnonDBPlayer | nil
BagnonDB = nil

-- ========================================================================
--                        CharacterInfoStorage Addon
-- ========================================================================

---@class CharacterInfoStorageAPI
---@field GetCharacters? fun(self: CharacterInfoStorageAPI): string[] List of character names
---@field GetNumItems? fun(self: CharacterInfoStorageAPI, charName: string, itemId: number): number Item count for character

---@type CharacterInfoStorageAPI | nil
CharacterInfoStorage = nil

-- ========================================================================
--                        BankItems Addon Data Structures
-- ========================================================================

---@class BankItemSlot
---@field link string Item link
---@field count number Item count

---@class BankItemBag
---@field size number Bag size
---@field [integer] BankItemSlot | nil Slots in bag

---@class BankItemPlayer
---@field [integer] BankItemSlot | nil Main bank slots (1-28)
---@field [string] BankItemBag | nil Bag contents (Bag0, Bag1, etc.)

---@type table<string, BankItemPlayer>
BankItems_Save = {}

-- ========================================================================
--                        Possessions Addon Data Structures
-- ========================================================================

---@class PossessionsBagItem
---@field [1] string Item ID string
---@field [2] number Stack size
---@field [3] number Count
---@field [4] string? Location data

---@class PossessionsCharData
---@field items table<number, PossessionsBagItem[]> Item storage by bag

---@type table<string, table<string, PossessionsCharData>>
PossessionsData = {}

-- ========================================================================
--                        BankList Addon Data Structures
-- ========================================================================

---@class BankListItemData
---@field id string Item ID string
---@field count number Item count

---@class BankListCharData
---@field bags table<number, BankListItemData[]> Item lists by bag

---@class BankListRealmData
---@field chars table<string, BankListCharData> Character data

---@class BankListDB
---@field realm BankListRealmData Realm data storage

---@class BankListAddon
---@field db? BankListDB Database

---@type BankListAddon | nil
BankList = nil

-- ========================================================================
--                        OneView Addon Data Structures
-- ========================================================================

---@class OneViewStorageAPI
---@field GetCharListByServerId fun(self: OneViewStorageAPI): table<number, table> Character list by server
---@field BagInfo fun(self: OneViewStorageAPI, faction: string, charId: number, bag: number): number, number, boolean, boolean, boolean Item ID, size, ammo, soul, prof
---@field SlotInfo fun(self: OneViewStorageAPI, faction: string, charId: number, bag: number, slot: number): string | nil, number | nil Item ID, quantity

---@class OneViewAddon
---@field storage? OneViewStorageAPI Storage API

---@type OneViewAddon | nil
OneView = nil

-- ========================================================================
--                        ArkInventory Addon Data Structures
-- ========================================================================

---@class ArkInventorySlotData
---@field h string Item hash/ID string
---@field count number Item count

---@class ArkInventoryBag
---@field size number Bag size
---@field slot table<number, ArkInventorySlotData | nil> Bag slots
---@field [integer] ArkInventorySlotData | nil Legacy slot access

---@class ArkInventoryLocationData
---@field bag table<string, ArkInventoryBag> Bags by ID
---@field [string] ArkInventoryBag Bag access by string

---@class ArkInventoryInfo
---@field name string Character name
---@field realm string Realm name
---@field faction string Faction code

---@class ArkInventoryPlayer
---@field info ArkInventoryInfo Player info
---@field location table<string, ArkInventoryLocationData> Locations with bags
---@field [string] ArkInventoryLocationData Location access

---@class ArkInventoryDB
---@field global table Global database
---@field player table Player-specific data
---@field realm table Realm data by name
---@field faction table Faction data

---@class ArkInventoryAddon
---@field Const? any Constants table
---@field db? ArkInventoryDB Database
---@field spairs? fun(tbl: table): fun(): number, ArkInventoryPlayer Iterator over sorted pairs
---@field ObjectStringDecodeItem? fun(self: ArkInventoryAddon, hash: string): string | nil Decode item hash

---@type ArkInventoryAddon | nil
ArkInventory = nil

-- ========================================================================
--                        Baggins_AnywhereBags Addon
-- ========================================================================

---@class BagginsAnywherebags
---@field GetItemCount? fun(self: BagginsAnywherebags, itemId: number): number Get item count across characters

---@type BagginsAnywherebags | nil
BagginsAnywhereBags = nil

-- ========================================================================
--                        LibStub (Library Loader)
-- ========================================================================

---@class LibStubResult
---@field [1] table The library instance
---@field [2] number The old version (if updating)

---@class LibStub
---@field NewLibrary? fun(self: LibStub, majorName: string, minorVersion: number): table | nil, number | nil Create or get library instance
---@field GetLibrary? fun(self: LibStub, majorName: string): table Get library instance

---@type LibStub | nil
LibStub = nil

-- ========================================================================
--                        Chat Frame (Default chat)
-- ========================================================================

---@class ChatFrame
---@field AddMessage? fun(self: ChatFrame, message: string, r?: number, g?: number, b?: number): nil Add message to chat

---@type ChatFrame | nil
ChatFrame1 = nil
