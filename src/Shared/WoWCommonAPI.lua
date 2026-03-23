---@meta
-- ====================================================================
-- WoWCommonAPI.lua — Shared WoW 3.3.5 Type Definitions
-- ====================================================================
-- Canonical source for WoW frame class hierarchy and core API stubs.
-- Referenced by ALL addons in this workspace via .luarc.json library path.
-- NEVER loaded by the WoW client (---@meta file, annotation-only).
-- ====================================================================

-- ----------------------------------------------------------------
-- Core UI Object Class Hierarchy
-- ----------------------------------------------------------------

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
---@field GetStringWidth fun(self: FontString): number
---@field IsShown fun(self: FontString): boolean

---@class Frame
---@field SetWidth fun(self: Frame, width: number)
---@field SetHeight fun(self: Frame, height: number)
---@field SetSize fun(self: Frame, width: number, height: number)
---@field SetPoint fun(self: Frame, point: string, relativeTo?: Frame|Texture|FontString|string|number, relativePoint?: string|number, xOffset?: number, yOffset?: number)
---@field ClearAllPoints fun(self: Frame)
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
---@field IsShown fun(self: Frame): boolean
---@field CreateFontString fun(self: Frame, name?: string, layer?: string, template?: string): FontString
---@field CreateTexture fun(self: Frame, name?: string, layer?: string, template?: string): Texture
---@field GetName fun(self: Frame): string
---@field SetResizable fun(self: Frame, resizable: boolean)
---@field SetAlpha fun(self: Frame, alpha: number)
---@field SetScale fun(self: Frame, scale: number)
---@field GetScale fun(self: Frame): number
---@field GetEffectiveScale fun(self: Frame): number
---@field GetParent fun(self: Frame): Frame
---@field SetParent fun(self: Frame, parent: Frame|string|nil)
---@field GetWidth fun(self: Frame): number
---@field GetHeight fun(self: Frame): number
---@field GetLeft fun(self: Frame): number|nil
---@field GetTop fun(self: Frame): number|nil
---@field GetRight fun(self: Frame): number|nil
---@field GetBottom fun(self: Frame): number|nil
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
---@field SetTextInsets fun(self: Frame, left: number, right: number, top: number, bottom: number)
---@field SetMaxLetters fun(self: Frame, maxLetters: number)
---@field SetAutoFocus fun(self: Frame, autoFocus: boolean)
---@field SetMultiLine fun(self: Frame, multiLine: boolean)
---@field SetFontObject fun(self: Frame, font: any)
---@field Click fun(self: Frame)

---@class Button : Frame
---@field SetText fun(self: Button, text: string)
---@field GetText fun(self: Button): string
---@field SetScript fun(self: Button, event: string, handler: function|nil)
---@field Enable fun(self: Button)
---@field Disable fun(self: Button)
---@field Click fun(self: Button)
---@field SetParent fun(self: Button, parent: Frame|string|nil)
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
---@field SetChecked fun(self: CheckButton, checked: boolean|number|nil)
---@field GetChecked fun(self: CheckButton): boolean

---@class EditBox : Frame
---@field SetText fun(self: EditBox, text: string)
---@field GetText fun(self: EditBox): string
---@field SetAutoFocus fun(self: EditBox, autoFocus: boolean)
---@field ClearFocus fun(self: EditBox)
---@field SetScript fun(self: EditBox, event: string, handler: function|nil)

---@class Texture : Frame
---@field SetTexture fun(self: Texture, texture: string|number)
---@field SetVertexColor fun(self: Texture, r: number, g: number, b: number, a?: number)
---@field ClearAllPoints fun(self: Texture)
---@field SetSize fun(self: Texture, width: number, height: number)
---@field SetPoint fun(self: Texture, point: string, relativeTo?: Frame|Texture|string|number, relativePoint?: string|number, xOffset?: number, yOffset?: number)

---@class Tooltip : Frame
---@field SetOwner fun(self: Tooltip, owner: Frame, anchor: string, x?: number, y?: number)
---@field SetHyperlink fun(self: Tooltip, link: string)
---@field AddLine fun(self: Tooltip, text: string, r?: number, g?: number, b?: number, wrap?: boolean)
---@field Show fun(self: Tooltip)
---@field Hide fun(self: Tooltip)
---@field GetOwner fun(self: Tooltip): Frame

---@class ChatFrame : Frame
---@field AddMessage fun(self: ChatFrame, message: string, r?: number, g?: number, b?: number, id?: number)

-- ----------------------------------------------------------------
-- Lua Bit Operations (WoW 3.3.5 ships Lua 5.1)
-- ----------------------------------------------------------------

---@class bit
---@field band fun(a: number, b: number): number Bitwise AND
---@field bor fun(a: number, b: number): number Bitwise OR
---@field bxor fun(a: number, b: number): number Bitwise XOR
---@field bnot fun(a: number): number Bitwise NOT
---@field lshift fun(a: number, n: number): number Left shift
---@field rshift fun(a: number, n: number): number Right shift

---@type bit
---@diagnostic disable-next-line: missing-fields
bit = {}

-- ----------------------------------------------------------------
-- Timer API
-- ----------------------------------------------------------------

---@class C_Timer
---@field After fun(duration: number, callback: function)
---@field NewTicker fun(duration: number, callback: function, iterations?: number): table

---@type C_Timer
---@diagnostic disable-next-line: missing-fields
C_Timer = {}

-- ----------------------------------------------------------------
-- Common Color/Constant Types
-- ----------------------------------------------------------------

---@class ColorTable
---@field r number Red component (0–1)
---@field g number Green component (0–1)
---@field b number Blue component (0–1)

---@class HighlightFontColor
---@field r number Red component
---@field g number Green component
---@field b number Blue component

-- ----------------------------------------------------------------
-- Core Global UI Objects
-- ----------------------------------------------------------------

--- Root UI frame; parent for all top-level addon frames.
UIParent = {}

--- List of frame names that receive ESC key close events.
---@type Frame[]
UISpecialFrames = {}

--- Slash command handler registry.
---@type table<string, function>
SlashCmdList = {}

---@type ChatFrame
---@diagnostic disable-next-line: missing-fields
DEFAULT_CHAT_FRAME = {}

--- The root 3D world frame; used as anchor for nameplates etc.
---@type Frame
WorldFrame = CreateFrame("Frame")

--- WoW 3.3.5 legacy: 'this' is the frame that fired the current OnEvent/OnUpdate.
---@type any
this = nil

-- ----------------------------------------------------------------
-- Font / Color Constants
-- ----------------------------------------------------------------

---@type string
GRAY_FONT_COLOR_CODE = ""

---@type string
FONT_COLOR_CODE_CLOSE = ""

---@type ColorTable
NORMAL_FONT_COLOR = { r = 1, g = 1, b = 1 }

---@type HighlightFontColor
HIGHLIGHT_FONT_COLOR = { r = 1, g = 1, b = 1 }

---@type string
COOLDOWN_REMAINING = ""

---@type string
SPELL_REAGENTS = ""

---@type number
BANK_CONTAINER = -1

---@type string
INVTYPE_BAG = ""

-- ----------------------------------------------------------------
-- UIDropDownMenu API
-- ----------------------------------------------------------------

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

-- ----------------------------------------------------------------
-- Frame / Object Creation
-- ----------------------------------------------------------------

---@overload fun(frameType: "GameTooltip", name?: string, parent?: Frame, template?: string): Tooltip
---@param frameType string The type of frame to create (e.g., "Frame", "Button", "Slider")
---@param name? string Optional global name for the frame
---@param parent? Frame Optional parent frame
---@param template? string Optional XML template name
---@return Frame frame The created frame
function CreateFrame(frameType, name, parent, template) end

---@param name string The global variable name
---@return any The global variable (frame, table, function, etc.)
function getglobal(name) end

-- ----------------------------------------------------------------
-- Item Information / Inventory
-- ----------------------------------------------------------------

---@param itemId number|string|nil The item ID or item link
---@return string? itemName, string? itemLink, number? itemRarity, number? itemLevel, number? itemMinLevel, string? itemType, string? itemSubType, number? itemStackCount, string? itemEquipLoc, string? itemTexture, number? itemSellPrice
function GetItemInfo(itemId) end

---@param itemId number The item ID
---@return string|nil iconTexture The icon texture path
function GetItemIcon(itemId) end

---@param itemId number|string Item ID or item link
---@param includeBank? boolean Whether to include bank items (default false)
---@return number count The number of items found
function GetItemCount(itemId, includeBank) end

---@param quality number Item quality (0–7)
---@return number r, number g, number b Color components
function GetItemQualityColor(quality) end

-- ----------------------------------------------------------------
-- Unit / Player Functions
-- ----------------------------------------------------------------

---@param unit string The unit (e.g., "player", "target")
---@return string|nil name The unit's name
function UnitName(unit) end

---@param unit string The unit to check (e.g., "player")
---@return boolean inCombat True if the unit is in combat
function UnitAffectingCombat(unit) end

---@return boolean inCombat True if the player is in combat lockdown
function InCombatLockdown() end

---@return boolean isDown True if the control key is down
function IsControlKeyDown() end

---@return boolean isShiftDown True if shift key is down
function IsShiftKeyDown() end

-- ----------------------------------------------------------------
-- Time and Math (WoW Lua globals)
-- ----------------------------------------------------------------

---@return number time Current game time in seconds
function GetTime() end

---@param x number The number to floor
---@return number floored The floored value
function floor(x) end

---@param ... number Numbers to compare
---@return number maximum The maximum value
function max(...) end

-- ----------------------------------------------------------------
-- Table Utility (WoW Lua aliases)
-- ----------------------------------------------------------------

---@param list table The table to insert into
---@param value any The value to insert
function tinsert(list, value) end

---@param list table The table to remove from
---@param pos? number The position to remove (default: last element)
---@return any removed The removed value
function tremove(list, pos) end

-- ----------------------------------------------------------------
-- String Utilities
-- ----------------------------------------------------------------

---@param str string The string to split
---@param sep string The separator character(s)
---@return string ... The split parts
function strsplit(str, sep) end

-- ----------------------------------------------------------------
-- Secure Hook
-- ----------------------------------------------------------------

--- Hooks a named method on a table so the original still fires.
---@param tbl table The table containing the method
---@param funcName string The method name to hook
---@param hook function Callback invoked after the original function
function hooksecurefunc(tbl, funcName, hook) end

-- ----------------------------------------------------------------
-- Chat / UI Helpers
-- ----------------------------------------------------------------

---@param link string|nil The item link to insert
function ChatEdit_InsertLink(link) end

-- ----------------------------------------------------------------
-- Lib Stub (Ace2)
-- ----------------------------------------------------------------

---@class LibStub
---@field GetLibrary fun(self: LibStub, name: string): any

---@type LibStub
---@diagnostic disable-next-line: missing-fields
LibStub = {}

---@class AceLibraryClass
---@field Register fun(self: AceLibraryClass, lib: table, major: string|number, minor: number|string, activate?: function, deactivate?: function, external?: table)
---@field IsNewVersion fun(self: AceLibraryClass, major: string|number, minor: number|string): boolean
---@field HasInstance fun(self: AceLibraryClass, name: string): boolean

---@param name string Library name (e.g., "AceAddon-2.0")
---@return any library The requested library object
function AceLibrary(name) end

-- ----------------------------------------------------------------
-- Minimap
-- ----------------------------------------------------------------

--- The minimap frame (a globally named Frame in the default WoW UI).
---@type Frame
---@diagnostic disable-next-line: missing-fields
Minimap = {}

-- ----------------------------------------------------------------
-- Cursor
-- ----------------------------------------------------------------

--- Returns the current cursor position in screen pixels (unscaled).
---@return number x Screen X coordinate in pixels from the left
---@return number y Screen Y coordinate in pixels from the bottom
function GetCursorPosition() end
