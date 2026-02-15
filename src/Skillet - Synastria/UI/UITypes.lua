---@meta UITypes

--[[
Skillet UI Type Definitions
Centralized type annotations for all UI components and classes.
This is a meta file used by the language server for type checking only.
]]

---@class AceLocale : table
---Localization table from AceLibrary("AceLocale-2.2")
---Provides translated strings for the addon
---@field [string] string Localized string mappings

---@class Abacus : table
---Math formatting library from AceLibrary
---@field FormatMoneyFull fun(self: Abacus, money: number): string Format money value

---@class BackdropTable : table
---Table defining frame backdrop appearance
---Used with SetBackdrop() for borderless frames
---@field bgFile string Background texture file path
---@field edgeFile string Edge texture file path
---@field tile boolean Whether the background should tile
---@field tileSize number Size for tiling the background
---@field edgeSize number Width/height of edge textures
---@field insets table Inset values {left, right, top, bottom}

---@class ShoppingListItem : table
---Item required for crafting, not in inventory
---@field link string Item link for the reagent
---@field count number Count needed to craft all queued recipes
---@field name string Human-readable item name
---@field player string|nil Character name who needs it (optional)

---@class BankItem : table
---Item stored in bank inventory
---@field bag number Bank container/bag ID
---@field slot number Slot position within the bag
---@field id number Numeric item ID
---@field count number Stack count of items in slot

---@class ProfessionButton : table
---Profession selector button with visual state
---@field button Button The button frame itself
---@field glow Texture Glow effect texture
---@field name string Profession name
---@field spellId number Spell ID for profession casting

---@class SecureActionButton : Button
---Secure button with frame attributes for conditional actions
---@field SetAttribute fun(self: SecureActionButton, name: string, value: any): nil Set secure attribute
---@field RegisterForClicks fun(self: SecureActionButton, clicks: string): nil Register for click events

---@class ConversionGroupSource : table
---Simplified conversion group source data (before UI transformation)
---These are transformed by ExtractionFrame.lua into full ConversionGroup objects
---@field label string Display label for the conversion group
---@field resultItems number[] Item IDs of the results
---@field sourceItems number[] Item IDs of the sources (paired with resultItems by index)
---@field bidirectional boolean Whether conversion works both ways
---@field inputAmount number How many source items needed per conversion
---@field outputAmount number How many result items produced per conversion
---@field extended? boolean Whether to use extended layout for display

---@class ConversionPair : table
---Conversion recipe configuration with explicit conversion amounts
---@field resultItem number Item ID of result
---@field sourceItem number Item ID of source material
---@field bidirectional boolean Whether conversion works both ways
---@field inputAmount number How many source items needed per conversion
---@field outputAmount number How many result items produced per conversion
---@field type string Conversion type ("combine", "split", or "hardcoded")

---@class ExtractionPageData : table
---Extraction page layout configuration
---@field layout string XML layout template name
---@field groupsPerPage number How many groups per page
---@field groupIndices integer[] Indices of groups on this page

---@class ExtractionPage : table
---Extraction page with layout and conversions
---@field layout string XML layout template name
---@field conversionPairs ConversionPair[] List of conversion pairs
---@field groupsPerPage number How many groups display per page
