---@meta

-- WoW 3.3.5 API Type Definitions for Lua Language Server
-- This file provides type information for WoW API functions used by Skillet
-- It is not executed, only used for type checking (---@meta directive)

-- Base WoW UI Object Classes
---@class FontString
---@field SetText fun(self: FontString, text: string)
---@field GetText fun(self: FontString): string
---@field SetFont fun(self: FontString, font: string, size: number, flags?: string)
---@field SetPoint fun(self: FontString, point: string, relativeTo?: Frame|FontString|string|number, relativePoint?: string|number, xOffset?: number, yOffset?: number)
---@field SetHeight fun(self: FontString, height: number)
---@field SetShadowColor fun(self: FontString, r: number, g: number, b: number, a?: number)
---@field SetShadowOffset fun(self: FontString, x: number, y: number)
---@field SetTextColor fun(self: FontString, r: number, g: number, b: number, a?: number)
---@field SetJustifyH fun(self: FontString, justify: string)
---@field Show fun(self: FontString)
---@field Hide fun(self: FontString)
---@field SetWidth fun(self: FontString, width: number)

---@class Button : Frame
---@field SetText fun(self: Button, text: string)
---@field GetText fun(self: Button): string
---@field SetScript fun(self: Button, event: string, handler: function|nil)
---@field Enable fun(self: Button)
---@field Disable fun(self: Button)
---@field Click fun(self: Button)
---@field SetParent fun(self: Button, parent: Frame|string)
---@field GetWidth fun(self: Button): number
---@field GetHeight fun(self: Button): number
---@field GetName fun(self: Button): string
---@field SetChecked fun(self: Button, checked: boolean)
---@field GetID fun(self: Button): number
---@field SetID fun(self: Button, id: number)
---@field GetTextWidth fun(self: Button): number
---@field LockHighlight fun(self: Button)
---@field UnlockHighlight fun(self: Button)
---@field SetNormalTexture fun(self: Button, texture: string)
---@field SetNormalFontObject fun(self: Button, font: string)
---@field GetFrameLevel fun(self: Button): number
---@field SetFrameLevel fun(self: Button, level: number)

---@class Slider : Frame
---@field SetMinMaxValues fun(self: Slider, min: number, max: number)
---@field SetValue fun(self: Slider, value: number)
---@field GetValue fun(self: Slider): number
---@field EnableMouseWheel fun(self: Slider, enable: boolean)
---@field SetValueStep fun(self: Slider, step: number)
---@field GetMinMaxValues fun(self: Slider): number, number

---@class CheckButton : Button
---@field SetChecked fun(self: CheckButton, checked: boolean)
---@field GetChecked fun(self: CheckButton): boolean

---@class Frame
---@field SetWidth fun(self: Frame, width: number)
---@field SetHeight fun(self: Frame, height: number)
---@field SetSize fun(self: Frame, width: number, height: number)
---@field SetPoint fun(self: Frame, point: string, relativeTo?: Frame|Texture|string|number, relativePoint?: string|number, xOffset?: number, yOffset?: number)
---@field SetBackdrop fun(self: Frame, backdrop: table)
---@field SetBackdropColor fun(self: Frame, r: number, g: number, b: number, a?: number)
---@field SetBackdropBorderColor fun(self: Frame, r: number, g: number, b: number, a?: number)
---@field SetFrameStrata fun(self: Frame, strata: string)
---@field SetMovable fun(self: Frame, movable: boolean)
---@field RegisterForDrag fun(self: Frame, button: string)
---@field SetClampedToScreen fun(self: Frame, clamped: boolean)
---@field EnableMouse fun(self: Frame, enable: boolean)
---@field SetScript fun(self: Frame, event: string, handler: function|nil)
---@field HasScript fun(self: Frame, event: string): boolean
---@field GetScript fun(self: Frame, event: string): function|nil
---@field Show fun(self: Frame)
---@field Hide fun(self: Frame)
---@field IsVisible fun(self: Frame): boolean
---@field CreateFontString fun(self: Frame, name?: string, layer?: string, template?: string): FontString
---@field CreateTexture fun(self: Frame, name?: string, layer?: string, template?: string): Texture
---@field GetName fun(self: Frame): string
---@field SetResizable fun(self: Frame, resizable: boolean)
---@field SetAlpha fun(self: Frame, alpha: number)
---@field SetScale fun(self: Frame, scale: number)
---@field GetParent fun(self: Frame): Frame
---@field SetParent fun(self: Frame, parent: Frame|string)
---@field GetWidth fun(self: Frame): number
---@field GetHeight fun(self: Frame): number
---@field GetFrameLevel fun(self: Frame): number
---@field SetFrameLevel fun(self: Frame, level: number)
---@field GetText fun(self: Frame): string
---@field SetText fun(self: Frame, text: string)
---@field SetID fun(self: Frame, id: number)
---@field GetID fun(self: Frame): number
---@field GetTextWidth fun(self: Frame): number
---@field SetNormalTexture fun(self: Frame, texture: string)
---@field SetNormalFontObject fun(self: Frame, font: string)
---@field LockHighlight fun(self: Frame)
---@field UnlockHighlight fun(self: Frame)
---@field Enable fun(self: Frame)
---@field Disable fun(self: Frame)
---@field SetChecked fun(self: Frame, checked: boolean)
---@field StartMoving fun(self: Frame)
---@field StopMovingOrSizing fun(self: Frame)
---@field RegisterEvent fun(self: Frame, event: string)
---@field UnregisterEvent fun(self: Frame, event: string)
---@field SetAttribute fun(self: Frame, name: string, value: any)
---@field RegisterForClicks fun(self: Frame, clicks: string)
---@field SetMinMaxValues fun(self: Frame, min: number, max: number)
---@field SetValue fun(self: Frame, value: number)
---@field GetValue fun(self: Frame): number
---@field EnableMouseWheel fun(self: Frame, enable: boolean)
---@field GetAttribute fun(self: Frame, name: string): any
---@field IsShown fun(self: Frame): boolean
---@field SetTextInsets fun(self: Frame, left: number, right: number, top: number, bottom: number)
---@field SetMaxLetters fun(self: Frame, maxLetters: number)
---@field SetAutoFocus fun(self: Frame, autoFocus: boolean)
---@field SetMultiLine fun(self: Frame, multiLine: boolean)
---@field SetFontObject fun(self: Frame, font: any)

---@class Texture
---@field SetTexture fun(self: Texture, texture: string|number, g?: number, b?: number, a?: number)
---@field SetPoint fun(self: Texture, point: string, relativeTo?: Frame|Texture|string|number, relativePoint?: string|number, xOffset?: number, yOffset?: number)
---@field SetHeight fun(self: Texture, height: number)
---@field SetGradientAlpha fun(self: Texture, orientation: string, startR: number, startG: number, startB: number, startA: number, endR: number, endG: number, endB: number, endA: number)

---@class LibStub
---@field GetLibrary fun(self: LibStub, name: string): any
LibStub = {}

---@param name string Library name (e.g., "AceAddon-2.0")
---@return any library The requested library object
function AceLibrary(name) end

---@class AceLibraryClass
---@field Register fun(self: AceLibraryClass, lib: table, major: string|number, minor: number|string, activate?: function, deactivate?: function, external?: table)
---@field IsNewVersion fun(self: AceLibraryClass, major: string|number, minor: number|string): boolean
---@field HasInstance fun(self: AceLibraryClass, name: string): boolean
AceLibrary = {}

---@type table<string, function>
SlashCmdList = {}

-- Frame Creation
---@overload fun(frameType: "GameTooltip", name?: string, parent?: Frame, template?: string): Tooltip
---@param frameType string The type of frame to create (e.g., "Frame", "Button")
---@param name? string Optional name for the frame
---@param parent? Frame Optional parent frame
---@param template? string Optional template name
---@return Frame frame The created frame
function CreateFrame(frameType, name, parent, template) end

-- Global Frame/Variable Lookup
---@param name string The global variable name
---@return any The global variable (frame, table, function, etc.)
function getglobal(name) end

-- Tooltip Frames (Global UI Elements)
---@class Tooltip : Frame
---@field AddLine fun(self: Tooltip, text: string, r?: number, g?: number, b?: number, wrap?: boolean)
---@field SetOwner fun(self: Tooltip, owner: Frame, anchor?: string)
---@field Show fun(self: Tooltip)
---@field Hide fun(self: Tooltip)
---@field GetItem fun(self: Tooltip): string?, string?
---@field SetText fun(self: Tooltip, text: string, r?: number, g?: number, b?: number)
---@field ClearLines fun(self: Tooltip)
---@field SetTradeSkillItem fun(self: Tooltip, skill: number, index?: number)
---@field AppendText fun(self: Tooltip, text: string)
---@field SetHyperlink fun(self: Tooltip, link: string)
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

---@class ChatFrame : Frame
---@field AddMessage fun(self: ChatFrame, message: string, r?: number, g?: number, b?: number, id?: number)

---@type ChatFrame
---@diagnostic disable-next-line: missing-fields
DEFAULT_CHAT_FRAME = {}

-- Skill Line Functions
---@return number numSkills The number of skill lines
function GetNumSkillLines() end

-- TradeSkill Functions
---@return boolean isLinked True if viewing another player's tradeskill
function IsTradeSkillLinked() end

-- Merchant Functions
---@class MerchantFrame : Frame
---@field IsVisible fun(self: MerchantFrame): boolean
---@type MerchantFrame
---@diagnostic disable-next-line: missing-fields
MerchantFrame = {}

-- UI Panel Management
---@param frame Frame The frame to show
function ShowUIPanel(frame) end

---@param frame Frame The frame to hide
function HideUIPanel(frame) end

-- Key Binding
---@param key string The key binding string (e.g., "CTRL-MOUSEWHEELUP")
---@param command? string The command to bind
function SetBinding(key, command) end

-- Custom Synastria Server Functions
---@param itemIdOrLink number|string|nil The item ID or item link
---@return number|nil value The custom data value or nil
function GetItemAttuneProgress(itemIdOrLink) end

---@param itemIdOrLink number|string|nil The item ID or item link
---@return boolean hasAttuned True if any variant has been attuned
function HasAttunedAnyVariant(itemIdOrLink) end

---@param dataType number The type of custom game data
---@param itemId number The item ID
---@return number|nil value The custom game data value
function GetCustomGameData(dataType, itemId) end

---@param itemId number The item ID
---@return number|nil tags Item tags bitmask
function GetItemTagsCustom(itemId) end

---@param itemId number The item ID
---@return number|nil forgeLevel The attune forge level
function GetItemAttuneForge(itemId) end

---@param itemId number The item ID
---@return number canAttune 0 if cannot attune, >0 if can attune
function CanAttuneItemHelper(itemId) end

---@param itemId number The item ID
---@return boolean|number isAttunable Check result
function IsAttunableBySomeone(itemId) end

-- Lua Bit Operations Library (Lua 5.1)
---@class bit
---@field band fun(a: number, b: number): number Bitwise AND
---@field bor fun(a: number, b: number): number Bitwise OR
---@field bxor fun(a: number, b: number): number Bitwise XOR
bit = {}

-- Resource Tracker Integration
function OpenResourceSummary() end

-- Item Information
---@param itemId number|string|nil The item ID or item link
---@return string? itemName, string? itemLink, number? itemRarity, number? itemLevel, number? itemMinLevel, string? itemType, string? itemSubType, number? itemStackCount, string? itemEquipLoc, string? itemTexture, number? itemSellPrice
function GetItemInfo(itemId) end

-- Cursor Functions
---@return string? cursorType, number? itemId, string? itemLink
function GetCursorInfo() end

-- TradeSkill Line Functions
---@return string? tradeskillName, number? currentLevel, number? maxLevel
function GetTradeSkillLine() end

-- Skill Line Functions
---@param index number The skill line index
---@return string? skillName, boolean? isHeader, boolean? isExpanded, number? skillRank, number? numTempPoints, number? skillModifier, number? skillMaxRank, boolean? isAbandonable, number? stepCost, number? rankCost, number? minLevel, number? skillCostType, string? skillDescription
function GetSkillLineInfo(index) end

-- Global UI Elements and Tables
---@type Frame
---@diagnostic disable-next-line: missing-fields
UIParent = {}

---@type Frame[]
UISpecialFrames = {}

---@type Frame|nil
SkilletShoppingList = nil

-- Third-party addon globals (optional dependencies)
---@class ESeller
---@field IsActive fun(self: ESeller): boolean
---@field db table
---@type ESeller|nil
ESeller = nil

-- Global Functions
---@param name string The global variable name
---@return any value The global variable value
function getglobal(name) end

-- Key Modifiers
---@return boolean isDown True if the control key is down
function IsControlKeyDown() end

-- Spell Functions
---@param spellId number The spell ID
---@return boolean isKnown True if the spell is known
function IsSpellKnown(spellId) end

---@param spellId number The spell ID
---@return string? spellName, string? spellRank, string? spellIcon, number? castTime, number? minRange, number? maxRange, number? spellId
function GetSpellInfo(spellId) end

-- Timer Functions
---@class C_Timer
---@field After fun(duration: number, callback: function)
C_Timer = {}

-- Key Bindings (extended)
---@param key string The key binding string (e.g., "CTRL-MOUSEWHEELUP")
---@param buttonName string The button frame name to click
function SetBindingClick(key, buttonName) end

-- Font Color Constants
---@type string
GRAY_FONT_COLOR_CODE = ""

---@type string
FONT_COLOR_CODE_CLOSE = ""

-- Combat Status
---@param unit string The unit to check (e.g., "player")
---@return boolean inCombat True if the unit is in combat
function UnitAffectingCombat(unit) end

-- Additional Combat/Lockdown Functions
---@return boolean inCombat True if the player is in combat lockdown
function InCombatLockdown() end

-- TradeSkill Functions (Extended)
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

-- Time Functions
---@return number time Current game time in seconds
function GetTime() end

-- Table Functions (Lua standard library)
---@param list table The table to insert into
---@param value any The value to insert
function tinsert(list, value) end

---@param list table The table to remove from
---@param pos? number The position to remove (default: last element)
---@return any removed The removed value
function tremove(list, pos) end

-- Casting Information
---@param unit string The unit (e.g., "player")
---@return string|nil spell, string|nil displayName, string|nil texture, number|nil startTime, number|nil endTime, boolean|nil isTradeSkill, string|nil castID, boolean|nil notInterruptible
function UnitCastingInfo(unit) end

---@param unit string The unit (e.g., "player")
---@return string|nil spell, string|nil displayName, string|nil texture, number|nil startTime, number|nil endTime, boolean|nil isTradeSkill, boolean|nil notInterruptible
function UnitChannelInfo(unit) end

-- Third-party Addon Globals
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

-- WoW 3.3.5 Legacy Global: 'this' references the current event handler's frame
---@type any
this = nil

-- XML-defined Skillet Sort Buttons and Dropdowns
---@type Button|nil
SkilletSortAscButton = nil

---@type Button|nil
SkilletSortDescButton = nil

---@type Frame|nil
SkilletSortDropdown = nil

-- Global Constants
---@type string
SPELL_REAGENTS = ""

-- Item Quality/Color Functions
---@param quality number Item quality (0-7)
---@return number r, number g, number b Color components
function GetItemQualityColor(quality) end

---@param containerIndex number The bag index
---@param slot number The slot index
function UseContainerItem(containerIndex, slot) end

-- Math Functions (Lua standard library)
---@param x number The number to floor
---@return number floored The floored value
function floor(x) end

---@param ... number Numbers to compare
---@return number maximum The maximum value
function max(...) end

-- UI/Chat Functions
---@param link string|nil The item link to insert
function ChatEdit_InsertLink(link) end

---@return boolean isLinked True if viewing a linked tradeskill
function GetTradeSkillListLink() end

---@param index number The tradeskill index
---@return number|nil cooldown Cooldown in seconds, or nil
function GetTradeSkillCooldown(index) end

---@param key string The CVar key
---@return string|nil value The CVar value
function GetCVar(key) end

---@param seconds number Time in seconds
---@return string formatted Formatted time string
function SecondsToTime(seconds) end

---@param index number The tradeskill index
function SelectTradeSkill(index) end

---@return boolean isShiftDown True if shift key is down
function IsShiftKeyDown() end

---@param tools string|nil Comma-separated list of tools
---@return string coloredList Colored list string
function BuildColoredListString(tools) end

-- Global Color Constants
---@class ColorTable
---@field r number Red component (0-1)
---@field g number Green component (0-1)
---@field b number Blue component (0-1)

---@type ColorTable
NORMAL_FONT_COLOR = { r = 1, g = 1, b = 1 }

---@type string
COOLDOWN_REMAINING = ""

-- Merchant Functions (Extended)
---@param index number The merchant item index
---@return string|nil itemLink The item link
function GetMerchantItemLink(index) end

---@return number count Number of merchant items
function GetMerchantNumItems() end

---@param index number The merchant item index
---@return string|nil name, string|nil texture, number|nil price, number|nil quantity, number|nil numAvailable, boolean|nil isUsable
function GetMerchantItemInfo(index) end

---@param index number The merchant item index
---@param quantity number Quantity to buy
function BuyMerchantItem(index, quantity) end

-- Tooltip Functions
---@param tooltip Tooltip The tooltip frame
---@param owner Frame The owner frame
function GameTooltip_SetDefaultAnchor(tooltip, owner) end

-- Special WoW Lua global `this` (pre-Wrath)
---@type Frame|nil
this = nil

-- Additional WoW API Functions
---@param unit string The unit (e.g., "player")
---@param slot number The inventory slot ID
---@return string|nil itemLink The item link
function GetInventoryItemLink(unit, slot) end

---@param containerIndex number The bag index
---@param slot number The slot index
---@return string|nil itemLink The item link
function GetContainerItemLink(containerIndex, slot) end

---@param containerIndex number The bag index
---@param slot number The slot index
function PickupContainerItem(containerIndex, slot) end

---@param containerIndex number The bag index
---@param slot number The slot index
---@param count number Number of items to split
function SplitContainerItem(containerIndex, slot, count) end

function PutItemInBackpack() end

---@param inventorySlot number The inventory slot ID
function PutItemInBag(inventorySlot) end

function ClearCursor() end

---@param bagId number The bag ID
---@return number inventoryId The inventory slot ID
function ContainerIDToInventoryID(bagId) end

-- UIDropDownMenu Functions
---@param frame Frame The dropdown frame
---@param initFunction function The initialization function
function UIDropDownMenu_Initialize(frame, initFunction) end

---@param frame Frame The dropdown frame
---@param width number The width to set
function UIDropDownMenu_SetWidth(frame, width) end

---@param frame Frame The dropdown frame
---@param text string The text to display
function UIDropDownMenu_SetText(frame, text) end

---@param info table The button info table
---@param level? number The menu level
function UIDropDownMenu_AddButton(info, level) end

---@return table info The dropdown info table
function UIDropDownMenu_CreateInfo() end

---@param frame Frame The dropdown frame
---@param id number The ID to select
function UIDropDownMenu_SetSelectedID(frame, id) end

-- Global Constants
---@type number
BANK_CONTAINER = -1

---@type string
INVTYPE_BAG = ""

---@type table
ChatFontNormal = {}

-- Container (Bag) Functions
---@param containerIndex number The bag index (0-4)
---@return number numSlots Number of slots in the bag
function GetContainerNumSlots(containerIndex) end

---@param containerIndex number The bag index
---@param slot number The slot index
---@return string|nil texture, number|nil count, boolean|nil locked, number|nil quality, boolean|nil readable, boolean|nil lootable, string|nil itemLink
function GetContainerItemInfo(containerIndex, slot) end

-- Scroll Frame Functions
---@param frame Frame The scroll frame
---@param numItems number Total number of items
---@param numToDisplay number Number of items to display
---@param itemHeight number Height of each item
function FauxScrollFrame_Update(frame, numItems, numToDisplay, itemHeight) end

---@param frame Frame|nil The scroll frame
---@return number offset The current scroll offset
function FauxScrollFrame_GetOffset(frame) end

-- Item Checks
---@param itemIdOrLink number|string Item ID or item link
---@return boolean isEquippable True if the item can be equipped
function IsEquippableItem(itemIdOrLink) end

---@param itemId number The item ID
---@return string|nil iconTexture The icon texture path
function GetItemIcon(itemId) end

-- Global UI Frames
---@type Frame
---@diagnostic disable-next-line: missing-fields
WorldFrame = {}

---@type Frame|nil
SkilletSlotFilterDropdown = nil

---@class SkilletExtractionFrameExtended : Frame
---@field bagUpdateRegistered boolean? Tracks if BAG_UPDATE event is registered

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

---@type Frame|nil
SkilletSkillListParent = nil

---@type Frame|nil
SkilletQueueParent = nil

---@type Frame|nil
SkilletTradeSkillLinkButton = nil

---@type Frame|nil
SkilletSkillIconCount = nil

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
SkilletShowQueuesFromAllAltsText = nil

---@type Frame|nil
SkilletShowQueuesFromAllAlts = nil

---@type Frame|nil
SkilletShoppingListRetrieveButton = nil

---@type Frame|nil
SkilletShoppingListExportRTButton = nil

---@type Frame|nil
SkilletShoppingListList = nil

---@type Frame|nil
SkilletShoppingListParent = nil

---@type Frame|nil
SkilletExtractionContainer = nil

---@type Frame|nil
SkilletExtractionScrollFrame = nil

---@class HighlightFontColor
---@field r number Red component
---@field g number Green component
---@field b number Blue component

---@type HighlightFontColor
HIGHLIGHT_FONT_COLOR = { r = 1, g = 1, b = 1 }

--- Get the count of an item across bags and bank
---@param itemId number|string Item ID or item link
---@param includeBank boolean? Whether to include bank items (default false)
---@return number count The number of items found
function GetItemCount(itemId, includeBank) end
