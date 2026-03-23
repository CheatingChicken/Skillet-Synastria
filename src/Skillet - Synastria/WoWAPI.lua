---@meta
-- ====================================================================
-- WoWAPI.lua — Skillet-Specific WoW 3.3.5 Type Definitions
-- ====================================================================
-- Contains API stubs and frame globals specific to the Skillet addon.
-- Common WoW types (Frame, FontString, CreateFrame, UIDropDownMenu, etc.)
--   → see src/Shared/WoWCommonAPI.lua
-- Common Synastria custom APIs (GetCustomGameData, GetHighestAttunePct, etc.)
--   → see src/Shared/SynastryCommonAPI.lua
-- NEVER loaded by the WoW client (---@meta file, annotation-only).
-- ====================================================================

-- ----------------------------------------------------------------
-- Tooltip Class (used by GameTooltip, ItemRefTooltip, etc.)
-- ----------------------------------------------------------------

---@class Tooltip : Frame
---@field SetOwner fun(self: Tooltip, owner: Frame, anchor: string, x?: number, y?: number)
---@field SetHyperlink fun(self: Tooltip, link: string)
---@field AddLine fun(self: Tooltip, text: string, r?: number, g?: number, b?: number, wrap?: boolean)
---@field Show fun(self: Tooltip)
---@field Hide fun(self: Tooltip)
---@field GetOwner fun(self: Tooltip): Frame
---@field NumLines fun(self: Tooltip): number

---@type Tooltip
---@diagnostic disable-next-line: missing-fields
GameTooltip = {}

---@type Tooltip
---@diagnostic disable-next-line: missing-fields
ItemRefTooltip = {}

---@type Tooltip
---@diagnostic disable-next-line: missing-fields
ShoppingTooltip1 = {}

---@type Tooltip
---@diagnostic disable-next-line: missing-fields
ShoppingTooltip2 = {}

-- ----------------------------------------------------------------
-- ChatFontNormal (Ace2 chat references this global)
-- ----------------------------------------------------------------

---@type table
ChatFontNormal = {}

-- ----------------------------------------------------------------
-- Merchant API
-- ----------------------------------------------------------------

---@return number count Number of merchant items
function GetMerchantNumItems() end

---@param index number The merchant item index
---@return string|nil name, string|nil texture, number|nil price, number|nil quantity, number|nil numAvailable, boolean|nil isUsable
function GetMerchantItemInfo(index) end

---@param index number The merchant item index
---@param quantity number Quantity to buy
function BuyMerchantItem(index, quantity) end

---@param index number The merchant item index
---@return string|nil itemLink The item link
function GetMerchantItemLink(index) end

-- ----------------------------------------------------------------
-- Equip / Tooltip Helpers
-- ----------------------------------------------------------------

---@param itemIdOrLink number|string Item ID or item link
---@return boolean isEquippable True if the item can be equipped
function IsEquippableItem(itemIdOrLink) end

---@param tooltip Tooltip The tooltip frame
---@param owner Frame The owner frame
function GameTooltip_SetDefaultAnchor(tooltip, owner) end

-- ----------------------------------------------------------------
-- FauxScrollFrame API
-- ----------------------------------------------------------------

---@param frame Frame The scroll frame
---@param numItems number Total number of items
---@param numToDisplay number Number of items to display
---@param itemHeight number Height of each item
function FauxScrollFrame_Update(frame, numItems, numToDisplay, itemHeight) end

---@param frame Frame|nil The scroll frame
---@return number offset The current scroll offset
function FauxScrollFrame_GetOffset(frame) end

-- ----------------------------------------------------------------
-- Container / Bag / Inventory API
-- ----------------------------------------------------------------

---@param bag number The bag index
---@return number numSlots Number of slots in the bag
function GetContainerNumSlots(bag) end

---@param bag number The bag index
---@param slot number The slot index
---@return string|nil texture, number|nil count, boolean|nil locked, number|nil quality, boolean|nil readable, boolean|nil lootable, string|nil itemLink
function GetContainerItemInfo(bag, slot) end

---@param bag number The bag index
---@param slot number The slot index
---@return string|nil itemLink The item link
function GetContainerItemLink(bag, slot) end

---@param bag number The bag index
---@param slot number The slot index
function PickupContainerItem(bag, slot) end

---@param bag number The bag index
---@param slot number The slot index
---@param count number Number of items to split
function SplitContainerItem(bag, slot, count) end

function PutItemInBackpack() end

---@param inventorySlot number The inventory slot ID
function PutItemInBag(inventorySlot) end

function ClearCursor() end

---@param bagId number The bag ID
---@return number inventoryId The inventory slot ID
function ContainerIDToInventoryID(bagId) end

---@param unit string The unit (e.g., "player")
---@param slot number The inventory slot ID
---@return string|nil itemLink The item link
function GetInventoryItemLink(unit, slot) end

---@param containerIndex number The bag index
---@param slot number The slot index
function UseContainerItem(containerIndex, slot) end

---@param itemName string The item name or item link
function UseItemByName(itemName) end

-- ----------------------------------------------------------------
-- Skill Line Functions
-- ----------------------------------------------------------------

---@return number numSkills The number of skill lines
function GetNumSkillLines() end

---@return boolean isLinked True if viewing another player's tradeskill
function IsTradeSkillLinked() end

-- ----------------------------------------------------------------
-- Merchant Frame
-- ----------------------------------------------------------------

---@class MerchantFrame : Frame
---@field IsVisible fun(self: MerchantFrame): boolean
---@type MerchantFrame
---@diagnostic disable-next-line: missing-fields
MerchantFrame = {}

-- ----------------------------------------------------------------
-- UI Panel Management
-- ----------------------------------------------------------------

---@param frame Frame The frame to show
function ShowUIPanel(frame) end

---@param frame Frame The frame to hide
function HideUIPanel(frame) end

-- ----------------------------------------------------------------
-- Key Binding
-- ----------------------------------------------------------------

---@param key string The key binding string (e.g., "CTRL-MOUSEWHEELUP")
---@param command? string The command to bind
function SetBinding(key, command) end

---@param key string The key binding string
---@param buttonName string The button frame name to click
function SetBindingClick(key, buttonName) end

-- ----------------------------------------------------------------
-- Spell Functions
-- ----------------------------------------------------------------

---@param spellId number The spell ID
---@return boolean isKnown True if the spell is known
function IsSpellKnown(spellId) end

---@param spellId number The spell ID
---@return string|nil spellName, string|nil spellRank, string|nil spellIcon, number|nil castTime, number|nil minRange, number|nil maxRange, number|nil spellId
function GetSpellInfo(spellId) end

-- ----------------------------------------------------------------
-- Cursor Functions
-- ----------------------------------------------------------------

---@return string? cursorType, number? itemId, string? itemLink
function GetCursorInfo() end

-- ----------------------------------------------------------------
-- TradeSkill Line Functions
-- ----------------------------------------------------------------

---@return string? tradeskillName, number? currentLevel, number? maxLevel
function GetTradeSkillLine() end

---@param index number The skill line index
---@return string? skillName, boolean? isHeader, boolean? isExpanded, number? skillRank, number? numTempPoints, number? skillModifier, number? skillMaxRank, boolean? isAbandonable, number? stepCost, number? rankCost, number? minLevel, number? skillCostType, string? skillDescription
function GetSkillLineInfo(index) end

-- ----------------------------------------------------------------
-- Third-party Addon Globals (optional dependencies for Skillet hooks)
-- ----------------------------------------------------------------

---@type Frame|nil
TradeJunkieMain = nil

---@type Frame|nil
TJ_OpenButtonTradeSkill = nil

---@type Frame|nil
AC_Craft = nil

---@type Frame|nil
AC_UseButton = nil

---@type Frame|nil
AC_ToggleButton = nil

---@type FontString|nil
TradeSkillReagentLabel = nil

---@type function|nil
FRC_TradeSkillFrame_SetSelection = nil

---@type function|nil
FRC_CraftFrame_SetSelection = nil

---@type Frame|nil
TradeJunkie_Attach = nil

---@type any
FRC_PriceSource = nil

-- ----------------------------------------------------------------
-- ESeller (optional third-party integration)
-- ----------------------------------------------------------------

---@class ESeller
---@field IsActive fun(self: ESeller): boolean
---@field db table
---@type ESeller|nil
ESeller = nil

-- ----------------------------------------------------------------
-- TradeSkill Functions
-- ----------------------------------------------------------------

---@return number numSkills Number of tradeskills
function GetNumTradeSkills() end

---@param index number The tradeskill index
function DoTradeSkill(index, numCasts) end

function StopTradeSkillRepeat() end

---@param index number The tradeskill index
---@return string name, string skillType, number numAvailable, boolean isExpanded, number altVerb, number numSkillUps
function GetTradeSkillInfo(index) end

---@param index number The tradeskill index
---@return string|nil itemLink The item link
function GetTradeSkillItemLink(index) end

---@param index number The tradeskill index
---@return string|nil recipeLink The recipe link
function GetTradeSkillRecipeLink(index) end

---@param index number The tradeskill index
---@return number minMade, number maxMade
function GetTradeSkillNumMade(index) end

---@param index number The tradeskill index
---@return number numReagents
function GetTradeSkillNumReagents(index) end

---@param index number The tradeskill index
---@param reagentIndex number The reagent index
---@return string name, string texture, number count, number playerCount
function GetTradeSkillReagentInfo(index, reagentIndex) end

---@param index number The tradeskill index
---@param reagentIndex number The reagent index
---@return string|nil reagentLink
function GetTradeSkillReagentItemLink(index, reagentIndex) end

---@param index number The tradeskill index
---@return string|nil tool1, string|nil tool2, string|nil tool3, string|nil tool4
function GetTradeSkillTools(index) end

---@return boolean isLinked True if viewing a linked tradeskill
function GetTradeSkillListLink() end

---@param index number The tradeskill index
---@return number|nil cooldown Cooldown in seconds, or nil
function GetTradeSkillCooldown(index) end

---@param index number The tradeskill index
function SelectTradeSkill(index) end

-- ----------------------------------------------------------------
-- Casting Information
-- ----------------------------------------------------------------

---@param unit string The unit (e.g., "player")
---@return string|nil spell, string|nil displayName, string|nil texture, number|nil startTime, number|nil endTime, boolean|nil isTradeSkill, string|nil castID, boolean|nil notInterruptible
function UnitCastingInfo(unit) end

---@param unit string The unit (e.g., "player")
---@return string|nil spell, string|nil displayName, string|nil texture, number|nil startTime, number|nil endTime, boolean|nil isTradeSkill, boolean|nil notInterruptible
function UnitChannelInfo(unit) end

-- ----------------------------------------------------------------
-- Misc UI Helpers
-- ----------------------------------------------------------------

---@param key string The CVar key
---@return string|nil value The CVar value
function GetCVar(key) end

---@param seconds number Time in seconds
---@return string formatted Formatted time string
function SecondsToTime(seconds) end

---@param tools string|nil Comma-separated list of tools
---@return string coloredList Colored list string
function BuildColoredListString(tools) end

-- ----------------------------------------------------------------
-- Skillet-Specific Frame Classes
-- ----------------------------------------------------------------

---@class SkilletExtractionFrameExtended : Frame
---@field bagUpdateRegistered boolean? Tracks if BAG_UPDATE event is registered

-- ----------------------------------------------------------------
-- Skillet-Specific Frame Globals
-- ----------------------------------------------------------------

---@type SkilletExtractionFrameExtended|nil
SkilletExtractionFrame = nil

---@type Frame|nil
SkilletExtractionListParent = nil

---@type Frame|nil
SkilletExtractionListScrollFrame = nil

---@type CheckButton|nil
SkilletExtractionBulkModeCheckbox = nil

---@type Button|nil
SkilletExtractionMillingButton = nil

---@type Button|nil
SkilletExtractionProspectingButton = nil

---@type Frame|nil
TradeSkillFrame = nil

---@type Frame|nil
SkilletDebugButton = nil

---@type Frame|nil
SkilletRBankTestButton = nil

---@type Frame|nil
SkilletScanAllButton = nil

---@type Frame|nil
SkilletShoppingListList = nil

---@type Button
SkilletShowQueuesFromAllAlts = nil

---@type FontString
SkilletShowQueuesFromAllAltsText = nil

---@type Button
SkilletShoppingListRetrieveButton = nil

---@type Slider
SkilletCreateCountSlider = nil

---@type FontString
SkilletSkillIconCount = nil

---@type Frame
SkilletHighlightFrame = nil

---@type Texture
SkilletHighlight = nil

---@type Frame
SkilletSkillListParent = nil

---@type Frame
SkilletQueueParent = nil

---@type Frame|nil
SkilletTradeSkillLinkButton = nil

---@type Frame|nil
ChatFrameEditBox = nil

---@type Frame|nil
WIM_EditBoxInFocus = nil

---@type Frame|nil
SkilletTradeskillTooltip = nil

---@type Frame|nil
SkilletMerchantBuyFrame = nil

---@type Frame|nil
SkilletMerchantBuyFrameTopText = nil

---@type Frame|nil
SkilletMerchantBuyFrameButton = nil

---@type Frame|nil
SkilletNotesList = nil

---@type Frame|nil
SkilletShoppingListExportRTButton = nil

---@type Frame|nil
SkilletShoppingListParent = nil

---@type Frame|nil
SkilletExtractionContainer = nil

---@type Frame|nil
SkilletExtractionScrollFrame = nil

---@type Frame|nil
SkilletLogViewerFrame = nil

---@type EditBox|nil
SkilletLogViewerEditBox = nil

---@type FontString|nil
SkilletLogViewerGroupLabel = nil
