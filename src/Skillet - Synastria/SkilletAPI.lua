---@meta

---@class EditBox : Frame
---@field SetText fun(self: EditBox, text: string)
---@field Show fun(self: EditBox)
---@field Hide fun(self: EditBox)
---@field GetNumber fun(self: EditBox): number
---@field GetText fun(self: EditBox): string

---@class Texture : Frame
---@field SetWidth fun(self: Texture, width: number)
---@field SetHeight fun(self: Texture, height: number)
---@field SetTexture fun(self: Texture, ...)
---@field SetPoint fun(self: Texture, point: string, ...)
---@field SetVertexColor fun(self: Texture, r: number, g: number, b: number, a?: number)
---@field ClearAllPoints fun(self: Texture)

---@class Tooltip : Frame
---@field SetOwner fun(self: Tooltip, owner: any, anchor?: string, ...)
---@field ClearLines fun(self: Tooltip)
---@field AddLine fun(self: Tooltip, text: string, ...)
---@field AddDoubleLine fun(self: Tooltip, left: string, right: string, ...)
---@field SetHyperlink fun(self: Tooltip, link: string)
---@field SetClampedToScreen fun(self: Tooltip, clamped: boolean)
---@field SetScale fun(self: Tooltip, scale: number)
---@field SetTradeSkillItem fun(self: Tooltip, skill: number, index?: number)
---@field AppendText fun(self: Tooltip, text: string)
---@field GetItem fun(self: Tooltip): string|nil, string|nil

-- === LLS META PATCH: UI globals, missing fields, and class definitions ===

---@class Tooltip : Frame
---@field SetOwner fun(self: Tooltip, owner: any, anchor?: string, ...)
---@field ClearLines fun(self: Tooltip)
---@field AddLine fun(self: Tooltip, text: string, ...)
---@field AddDoubleLine fun(self: Tooltip, left: string, right: string, ...)
---@field SetHyperlink fun(self: Tooltip, link: string)
---@field SetClampedToScreen fun(self: Tooltip, clamped: boolean)
---@field SetScale fun(self: Tooltip, scale: number)
---@field SetTradeSkillItem fun(self: Tooltip, skill: number, index?: number)
---@field AppendText fun(self: Tooltip, text: string)
---@field GetItem fun(self: Tooltip): string|nil, string|nil

---@class FontString : Frame
---@field SetText fun(self: FontString, text: string)
---@field SetTextColor fun(self: FontString, r: number, g: number, b: number, a?: number)
---@field SetWidth fun(self: FontString, width: number)
---@field SetPoint fun(self: FontString, point: string, ...)
---@field SetHeight fun(self: FontString, height: number)
---@field Show fun(self: FontString)
---@field Hide fun(self: FontString)

---@type Frame|nil
SkilletReagentParent = nil
---@type Frame|nil
SkilletFrame = nil
---@type EditBox|nil
SkilletItemCountInputBox = nil

---@class Item
---@field name string
---@field link string?

---@class DebugInfo
---@field source string?
---@field short_src string?
---@field linedefined integer?
---@field lastlinedefined integer?
---@field nparams integer?
---@field isvararg boolean?

---@class MissingRecipeInfo
---@field index integer The recipe index in the trade window
---@field name string The recipe name
---@field skillType string The skill type (e.g., "recipe", "enchant")
---@field link string|nil The item link if available

---@class CategoryInfo
---@field index integer The recipe index
---@field name string The recipe name

---@class NotesTable : table<integer, string|nil>

---@class RecipeSearchMatch
---@field spellId number The spell ID for the recipe
---@field skillId number The skill ID (profession identifier)
---@field name string The recipe name

---@class WrongProfessionInfo
---@field name string The recipe name
---@field expectedProf integer The expected profession skill ID
---@field actualProf integer The actual profession skill ID
---@field spellId number|nil The spell ID if available

---@class SkilletQueueItem
---@field spellId number?  -- Spell ID for the recipe (may be nil for legacy queues)
---@field numcasts number

---@class SkilletQueuedItem
---@field name string
---@field link string
---@field count number
---@field player string

-- Note: SkilletStitch class is fully defined in SkilletStitch-1.1.lua

---@type SkilletStitch|nil
Skillet.stitch = nil

---@type Recipe|nil
Skillet.currentRecipe = nil

---@type string|nil
Skillet.currentTrade = nil

---@alias SkilletQueue SkilletQueueItem[]

-- Table mapping profession names to queues for a player
---@alias SkilletPlayerQueues table<string, SkilletQueue>

-- Table mapping player names to their profession queues
---@alias SkilletAllQueues table<string, SkilletPlayerQueues>

Skillet = {}

---@class SkilletDBChar
---@field recipes table<string, any>?  -- Generalized for legacy/ambiguous data
---@field vendor_buy_button boolean?
---@field vendor_auto_buy boolean?
---@field show_item_notes_tooltip boolean?
---@field show_detailed_recipe_tooltip boolean?
---@field link_craftable_reagents boolean?
---@field notes table<string, any>?  -- Generalized for legacy/ambiguous data
---@field tradeskill_options table<string, any>?

---@class SkilletDBProfile
---@field vendor_buy_button boolean?
---@field vendor_auto_buy boolean?
---@field show_item_notes_tooltip boolean?
---@field show_detailed_recipe_tooltip boolean?
---@field link_craftable_reagents boolean?
---@field show_bank_alt_counts boolean?
---@field show_crafters_tooltip boolean?
---@field show_craft_counts boolean?
---@field transparency number?
---@field scale number?
---@field display_required_level boolean?
---@field enhanced_recipe_display boolean?
---@field queue_craftable_reagents boolean?

---@class SkilletDBServer
---@field recipes table<string, table<string, table<integer, RecipeData>>>?  -- Map of player -> profession -> recipe_index -> recipe data
---@field notes table<string, any>?  -- Generalized for legacy/ambiguous data
---@field queues SkilletAllQueues?  -- Map of player -> queues

---@class GlobalFrameRegistry
---@field RBankFrame? Frame
---@field RBankFrameClose? Button
---@field RBankFrameWithdraw? Button
---@field RBankFrameDeposit? Button
---@field RBankFrameDepositAll? Button
---@field RBankFrameILine1? Frame

---@class SkilletDB
---@field char SkilletDBChar
---@field profile SkilletDBProfile
---@field server SkilletDBServer

---@type SkilletDB
Skillet.db = nil

---@param spellId number
---@param count number
---@return boolean
Custom_DoProfessionRecipe = function(spellId, count)
    ---@type boolean result
    local result = true
    return result
end
---@param spellId number
---@return table info
Custom_GetProfessionRecipeInfo = function(spellId)
    ---@type table info
    local info = {}
    return info
end
-- WoW StatusBar type (not defined by default)
---@class StatusBar : Frame
---@field SetMinMaxValues fun(self: StatusBar, min: number, max: number)
---@field SetValue fun(self: StatusBar, value: number)
---@field SetStatusBarColor fun(self: StatusBar, r: number, g: number, b: number, a?: number)
---@field SetStatusBarTexture fun(self: StatusBar, texture: string)
---@field GetValue fun(self: StatusBar): number
---@field GetMinMaxValues fun(self: StatusBar): number, number

-- WoW debugprofilestop API (for profiling)
---@return number milliseconds
function debugprofilestop() end

---@class SkilletRecipePromptFrame : Frame
---@field title FontString
---@field text FontString
---@field openButton Button
---@field okButton Button
---@field professionSpellIds table<string, number>
---@field professions string[]
---@field professionIndex number|nil
---@field scannedProfessions table|nil

---@class SkilletStartCraftingFrame : Frame
---@field title FontString
---@field text FontString
---@field itemText FontString
---@field errorText FontString
---@field startButton Button
---@field switchButton Button
---@field useItemButton Button
---@field cancelButton Button
---@field conversionStep number|nil
---@field totalCombinesNeeded number|nil
---@field combinesCompleted number|nil

---@class SkilletProfessionSwitchPromptFrame : Frame

---@class SkilletCraftCalc
---@field ResetTimingStats fun(self: SkilletCraftCalc)
---@field GetTimingStats fun(self: SkilletCraftCalc): number, number, number
---@field ClearCache fun(self: SkilletCraftCalc)
---@field GetCachedCraftability fun(self: SkilletCraftCalc, profession: string, recipeIndex: number, includeBank: boolean, includeResBank: boolean, includeAlts: boolean): number|nil
---@field SetCachedCraftability fun(self: SkilletCraftCalc, profession: string, recipeIndex: number, includeBank: boolean, includeResBank: boolean, includeAlts: boolean, value: number)
---@field CalculateCraftability fun(self: SkilletCraftCalc, profession: string, yieldInterval?: number)
---@field CalculateRecipeCraftability fun(self: SkilletCraftCalc, recipe: Recipe, lib: SkilletStitch, includeBank: boolean, verbose?: boolean, depth?: number, forceRecalc?: boolean): number
---@field CalculateRecipeCraftabilityCustomAPI fun(self: SkilletCraftCalc, spellId: number, includeBank: boolean, verbose?: boolean, depth?: number, cache?: table): number
---@field StartBackgroundCalculation fun(self: SkilletCraftCalc, profession: string, finishCallback: function, yieldInterval?: number)
---@field IsCalculationRunning fun(self: SkilletCraftCalc): boolean, string|nil
---@field StopCalculation fun(self: SkilletCraftCalc)
---@field PauseCalculation fun(self: SkilletCraftCalc)
---@field ResumeCalculation fun(self: SkilletCraftCalc)
---@field BenchmarkCraftability fun(self: SkilletCraftCalc, recipe: Recipe, lib: SkilletStitch, includeBank: boolean)
---@field BenchmarkAllRecipes fun(self: SkilletCraftCalc, includeBank: boolean)

---@class LibPossessions
---@field GetItemCount fun(self: LibPossessions, item: number|string): number
---@field IsAvailable fun(self: LibPossessions): boolean

---@class SkilletClass
---@field version string
---@field title string
---@field date string
---@field stitch SkilletStitch
---@field db SkilletDB
---@field tradeSkillFrame Frame|nil
---@field shoppingList Frame|nil
---@field notesFrame Frame|nil
---@field currentTrade string|nil
---@field selectedSkill number|nil
---@field currentRecipe Recipe|nil
---@field hideUncraftableRecipes boolean
---@field hideTrivialRecipes boolean
---@field customApiAvailable boolean
---@field customApiFailureReported boolean
---@field inventoryCheck LibPossessions|nil
---@field CraftCalc SkilletCraftCalc|nil
---@field extractionFrame Frame|nil
---@field toggleBackdrop Frame|nil
---@field charToggle CheckButton|nil
---@field forgeToggleUn CheckButton|nil
---@field forgeToggleAtt CheckButton|nil
---@field forgeToggleTf CheckButton|nil
---@field forgeToggleWf CheckButton|nil
---@field forgeToggleLf CheckButton|nil
---@field startCraftingPrompt SkilletStartCraftingPrompt|nil
---@field recipePromptDialog SkilletRecipePromptDialog|nil
---@field professionSwitchPrompt SkilletProfessionSwitchPromptFrame|nil
---@field needsRecipeScan string[]|nil
---@field headerCollapsedState table<string, boolean>|nil
---@field options table<string, any>
---@field Print fun(self: SkilletClass, message: string)
---@field DebugLog fun(self: SkilletClass, message: string, color?: string)
---@field IsDevMode fun(self: SkilletClass): boolean
---@field GetItemIDFromLink fun(self: SkilletClass, link: string|nil): number|nil
---@field GetConversionInfo fun(self: SkilletClass, itemId: number): number|nil, number|nil, string|nil
---@field GetQueuedReagentConsumption fun(self: SkilletClass, itemId: number|nil): number
---@field QueueConversionsIfNeeded fun(self: SkilletClass, reagent: Reagent, needed: number): boolean
---@field GetTradeSkillLine fun(self: SkilletClass): string|nil, number|nil, number|nil
---@field GetNumTradeSkills fun(self: SkilletClass, trade: string|nil): integer
---@field GetTradeSkillOption fun(self: SkilletClass, trade: string|nil, option: string): any
---@field SetTradeSkillOption fun(self: SkilletClass, trade: string|nil, option: string, value: any)
---@field GetReagentsForQueuedRecipes fun(self: SkilletClass, player: string|nil): SkilletQueuedItem[]|nil
---@field GetAllQueues fun(self: SkilletClass): SkilletAllQueues
---@field GetQueues fun(self: SkilletClass, player: string): SkilletPlayerQueues
---@field GetPlayerQueues fun(self: SkilletClass): SkilletPlayerQueues
---@field IsResourceTrackerAvailable fun(self: SkilletClass): boolean
---@field ExportShoppingListToResourceTracker fun(self: SkilletClass, playername: string|nil, includeBank: boolean, silent: boolean): boolean, number
---@field ExportItemToResourceTracker fun(self: SkilletClass, itemLink: string|number, goalAmount: number): boolean
---@field ExportToResourceTrackerCommand fun(self: SkilletClass)
---@field AutoExportQueueToResourceTracker fun(self: SkilletClass)
---@field UpdateResourceTrackerAfterCraft fun(self: SkilletClass, recipe: Recipe, numCrafted: number)
---@field UpdateTradeSkill fun(self: SkilletClass)
---@field UpdateTradeSkillWindow fun(self: SkilletClass)
---@field UpdateQueueWindow fun(self: SkilletClass)
---@field UpdateShoppingListWindow fun(self: SkilletClass)
---@field UpdateMerchantFrame fun(self: SkilletClass)
---@field ResetTradeSkillWindow fun(self: SkilletClass)
---@field CreateTradeSkillWindow fun(self: SkilletClass): Frame|nil
---@field ShowTradeSkillWindow fun(self: SkilletClass)
---@field HideTradeSkillWindow fun(self: SkilletClass): boolean|nil
---@field HideNotesWindow fun(self: SkilletClass): boolean|nil
---@field HideShoppingList fun(self: SkilletClass): boolean|nil
---@field ShowOptions fun(self: SkilletClass)
---@field HideAllWindows fun(self: SkilletClass): boolean|nil
---@field SetSelectedTrade fun(self: SkilletClass, trade: string|nil)
---@field SetSelectedSkill fun(self: SkilletClass, skill: number|nil, noQueue?: boolean)
---@field RescanTrade fun(self: SkilletClass, quick: boolean|nil)
---@field LoadQueue fun(self: SkilletClass, queues: SkilletAllQueues, profession: string)
---@field SaveQueue fun(self: SkilletClass, db: SkilletAllQueues, tradeskill: string)
---@field WithdrawFromResourceBank fun(self: SkilletClass, itemId: number, autoClose?: boolean): boolean
---@field WithdrawMultipleFromResourceBank fun(self: SkilletClass, itemIds: number[]): number, number
---@field CloseResourceBank fun(self: SkilletClass)
---@field DepositToResourceBank fun(self: SkilletClass, itemIds: number|number[]|nil, autoClose?: boolean): boolean
---@field AddItemNotesToTooltip fun(self: SkilletClass, tooltip: Tooltip): boolean|nil
---@field IsItemAttuned fun(self: SkilletClass, itemLink: string|nil): boolean|nil
---@field GetItemAttunementProgress fun(self: SkilletClass, itemLink: string|nil): number|nil
---@field UpdateExtractionListDisplay fun(self: SkilletClass)
---@field OnCraftFailed fun(self: SkilletClass, errorMessage?: string)
---@field ResumeCalculations fun(self: SkilletClass)
---@field CheckForOldRecipeData fun(self: SkilletClass)
---@field ShowPhase2TestDialog fun(self: SkilletClass)
---@field ShowRecipePrompt fun(self: SkilletClass, professions: string[], originalProfession?: string)
---@field ShowStartCraftingPrompt fun(self: SkilletClass)
---@field DebugSelectedRecipe fun(self: SkilletClass)
---@field DebugRecipeTree fun(self: SkilletClass, recipe: Recipe, lib: SkilletStitch, includeBank: boolean, depth: number)
---@field TestAttunement fun(self: SkilletClass)
---@field TestConversions fun(self: SkilletClass)
---@field TestResourceBank fun(self: SkilletClass)
---@field UpgradeDataAndOptions fun(self: SkilletClass)
---@field RegisterDB fun(self: SkilletClass, dbName: string, charDbName: string)
---@field RegisterDefaults fun(self: SkilletClass, scope: string, defaults: table)
---@field RegisterEvent fun(self: SkilletClass, event: string, method?: string|function)
---@field ScheduleEvent fun(self: SkilletClass, name: string, func: function|string, delay: number, ...)
---@field OnInitialize fun(self: SkilletClass)
---@field OnEnable fun(self: SkilletClass)
---@field OnDisable fun(self: SkilletClass)
---@field RegisterChatCommand fun(self: SkilletClass, commands: string[], options: table, name: string)
---@field UnregisterAllEvents fun(self: SkilletClass)
---@field UpdateDetailsWindow fun(self: SkilletClass, skillIndex: number)
---@field ExportToResourceTrackerCommand? fun(self: SkilletClass)
---@field TRADE_SKILL_CLOSE fun(self: SkilletClass)
---@field TRADE_SKILL_UPDATE fun(self: SkilletClass)
---@field SKILL_LINES_CHANGED fun(self: SkilletClass)
---@field BAG_UPDATE fun(self: SkilletClass)
---@field TRADE_CLOSED fun(self: SkilletClass)
---@field MERCHANT_SHOW fun(self: SkilletClass)
---@field MERCHANT_UPDATE fun(self: SkilletClass)
---@field MERCHANT_CLOSED fun(self: SkilletClass)
---@field BANKFRAME_OPENED fun(self: SkilletClass)
---@field BANKFRAME_CLOSED fun(self: SkilletClass)
---@field AUCTION_HOUSE_SHOW fun(self: SkilletClass)
---@field AUCTION_HOUSE_CLOSED fun(self: SkilletClass)
---@field UI_ERROR_MESSAGE fun(self: SkilletClass, errorType: string, message: string)
---@field UNIT_SPELLCAST_FAILED fun(self: SkilletClass, ...)
---@field UNIT_SPELLCAST_INTERRUPTED fun(self: SkilletClass, ...)
---@field UNIT_SPELLCAST_START fun(self: SkilletClass, ...)
---@field UNIT_SPELLCAST_SUCCEEDED fun(self: SkilletClass, ...)
---@field UNIT_SPELLCAST_STOP fun(self: SkilletClass, ...)
---@field UpdateScanningText fun(self: SkilletClass, text: string)
---@field internal_ResetCharacterCache fun(self: SkilletClass)
---@field internal_ShowTradeSkillWindow fun(self: SkilletClass)
---@field internal_HideTradeSkillWindow fun(self: SkilletClass): boolean|nil
---@field internal_HideAllWindows fun(self: SkilletClass): boolean|nil
---@field GetCraftersForItem fun(self: SkilletClass, itemId: number): string[]|nil
---@field PrintAddonInfo fun(self: SkilletClass)
---@field ShowInventoryInfoPopup fun(self: SkilletClass)
---@field DisplayShoppingList fun(self: SkilletClass, showAtBank: boolean)

-- ...existing code...
---@type Frame|nil
SkilletShoppingList = nil
---@type Button|nil
SkilletSortAscButton = nil
---@type Button|nil
SkilletSortDescButton = nil
---@type Frame|nil
SkilletSortDropdown = nil
---@type Frame|nil
SkilletSlotFilterDropdown = nil
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
SkilletSkillIconCount = nil
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
---@type Frame
SkilletRecipeNotesFrame = nil
---@type Button
SkilletCreateAllButton = nil
---@type Button
SkilletQueueAllButton = nil
---@type Button
SkilletCreateButton = nil
---@type Button
SkilletQueueButton = nil
---@type Button
SkilletStartQueueButton = nil
---@type Button
SkilletEmptyQueueButton = nil
---@type Button
SkilletShowOptionsButton = nil
---@type Button
SkilletRescanButton = nil
---@type Button
SkilletRecipeNotesButton = nil
---@type FontString
SkilletRecipeNotesFrameLabel = nil
---@type Button
SkilletShoppingListButton = nil
---@type FontString
SkilletHideUncraftableRecipesText = nil
---@type FontString
SkilletHideTrivialRecipesText = nil
---@type Slider
SkilletCreateCountSliderThumb = nil
---@type StatusBar
SkilletRankFrame = nil
---@type Texture
SkilletRankFrameBackground = nil
---@type Frame
SkilletSkillList = nil
---@type Button
SkilletSkillName = nil
---@type Button
SkilletSkillIcon = nil
---@type FontString
SkilletReagentLabel = nil
---@type FontString
SkilletRankFrameSkillRank = nil
---@type Frame
SkilletQueueList = nil
---@type CheckButton|nil
SkilletHideTrivialRecipes = nil
---@type CheckButton|nil
SkilletHideUncraftableRecipes = nil
---@type Frame
SkilletSkillListParent = nil
---@type Frame
SkilletQueueParent = nil

-- Skillet custom frame/button classes with injected fields
---@class SkilletFrameClass : Frame
---@field selectedSkill number|nil
SkilletFrame = nil

---@class SkilletCreateCountSliderClass : Slider
---@field tooltipText string|nil
SkilletCreateCountSlider = nil

---@class SkilletEmptyQueueButtonClass : Button
---@field _handlerSet boolean|nil
SkilletEmptyQueueButton = nil

---@class SkilletRequirementLabelClass : FontString
SkilletRequirementLabel = nil

---@class SkilletRequirementTextClass : FontString
SkilletRequirementText = nil

---@class SkilletSkillCooldownClass : FontString
SkilletSkillCooldown = nil

---@class SkilletPreviousItemButtonClass : Button
SkilletPreviousItemButton = nil

---@class SkilletExtraDetailTextClass : FontString
SkilletExtraDetailText = nil

---@type table|nil
color = nil

-- Helper function to safely get player name, always returns a string
---@return string playerName The player's name, or "Unknown" if not available
function GetSafePlayerName()
    local nameFromAPI = UnitName("player")
    if nameFromAPI then
        return nameFromAPI
    else
        return "Unknown"
    end
end
