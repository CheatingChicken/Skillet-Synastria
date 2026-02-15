--[[

Skillet: A tradeskill window replacement.
Copyright (c) 2007 Robert Clark <nogudnik@gmail.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

]] --

---@diagnostic disable:no-unknown,param-type-mismatch
-- File includes many WoW API calls with untyped globals

local MAJOR_VERSION    = "1.13"
local MINOR_VERSION    = ("$Revision: 153 $"):match("%d+") or 1
local DATE             = string.gsub("$Date: 2008-10-26 19:38:21 +0000 (Sun, 26 Oct 2008) $",
    "^.-(%d%d%d%d%-%d%d%-%d%d).-$", "%1")

---@type SkilletClass
Skillet                = AceLibrary("AceAddon-2.0"):new("AceConsole-2.0", "AceEvent-2.0", "AceDB-2.0", "AceHook-2.1")
Skillet.title          = "Skillet"
Skillet.version        = MAJOR_VERSION .. "-" .. MINOR_VERSION
Skillet.date           = DATE

-- Pull it into the local namespace, it's faster to access that way
---@type SkilletClass
local Skillet          = Skillet

-- Is a copy of LibPossessions is avaialable, use it for alt
-- character inventory checks
Skillet.inventoryCheck = LibStub and LibStub:GetLibrary('LibPossessions')

-- Register to have the AceDB class handle data and option persistence for us
Skillet:RegisterDB("SkilletDB", "SkilletDBPC")

-- Global ( across all alts ) options
Skillet:RegisterDefaults('profile', {
    -- user configurable options
    vendor_buy_button                = true,
    vendor_auto_buy                  = false,
    show_item_notes_tooltip          = false,
    show_crafters_tooltip            = true,
    show_detailed_recipe_tooltip     = true,
    link_craftable_reagents          = true,
    queue_craftable_reagents         = true,
    display_required_level           = false,
    display_shopping_list_at_bank    = false,
    display_shopping_list_at_auction = false,
    transparency                     = 1.0,
    scale                            = 1.0,
    dev_mode                         = false, -- Synastria: Debug logging disabled by default
})

-- Options specific to a single character
Skillet:RegisterDefaults('server', {
    -- we tell Stitch to keep the "recipes" table up to data for us.
    recipes = {},

    -- and any queued up recipes
    queues = {},

    -- notes added to items crafted or used in crafting.
    notes = {},
})

-- Options specific to a single character
Skillet:RegisterDefaults('char', {
    -- options specific to a current tradeskill
    tradeskill_options = {},

    -- Display alt's items in shopping list
    include_alts = true,
})

-- Localization
---@type table
local L = AceLibrary("AceLocale-2.2"):new("Skillet")

-- Events
local AceEvent = AceLibrary("AceEvent-2.0")

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

-- Helper function to safely get localized strings with fallback
---@param key string The localization key
---@return string The localized string, or the key itself as fallback
function GetLocalizedString(key)
    return L[key] or key
end

-- Type definitions for EmmyLua (QueueEntry defined in SkilletStitch-1.1.lua)
---@class Recipe
---@class Reagent
---@class DialogFrame

-- All the options that we allow the user to control.
---@type SkilletClass
local Skillet = Skillet
Skillet.options =
{
    handler = Skillet,
    type = 'group',
    args = {
        features = {
            type = 'group',
            name = L["Features"],
            desc = L["FEATURESDESC"],
            order = 11,
            args = {
                vendor_buy_button = {
                    type = "toggle",
                    name = L["VENDORBUYBUTTONNAME"],
                    desc = L["VENDORBUYBUTTONDESC"],
                    get = function()
                        return Skillet.db.profile.vendor_buy_button;
                    end,
                    set = function(value)
                        Skillet.db.profile.vendor_buy_button = value;
                    end,
                    order = 12
                },
                vendor_auto_buy = {
                    type = "toggle",
                    name = L["VENDORAUTOBUYNAME"],
                    desc = L["VENDORAUTOBUYDESC"],
                    get = function()
                        return Skillet.db.profile.vendor_auto_buy;
                    end,
                    set = function(value)
                        Skillet.db.profile.vendor_auto_buy = value;
                    end,
                    order = 12
                },
                show_item_notes_tooltip = {
                    type = "toggle",
                    name = L["SHOWITEMNOTESTOOLTIPNAME"],
                    desc = L["SHOWITEMNOTESTOOLTIPDESC"],
                    get = function()
                        return Skillet.db.profile.show_item_notes_tooltip;
                    end,
                    set = function(value)
                        Skillet.db.profile.show_item_notes_tooltip = value;
                    end,
                    order = 13
                },
                show_crafters_tooltip = {
                    type = "toggle",
                    name = L["SHOWCRAFTERSTOOLTIPNAME"],
                    desc = L["SHOWCRAFTERSTOOLTIPDESC"],
                    get = function()
                        return Skillet.db.profile.show_crafters_tooltip;
                    end,
                    set = function(value)
                        Skillet.db.profile.show_crafters_tooltip = value;
                    end,
                    order = 14
                },
                show_detailed_recipe_tooltip = {
                    type = "toggle",
                    name = L["SHOWDETAILEDRECIPETOOLTIPNAME"],
                    desc = L["SHOWDETAILEDRECIPETOOLTIPDESC"],
                    get = function()
                        return Skillet.db.profile.show_detailed_recipe_tooltip;
                    end,
                    set = function(value)
                        Skillet.db.profile.show_detailed_recipe_tooltip = value;
                    end,
                    order = 15
                },
                link_craftable_reagents = {
                    type = "toggle",
                    name = L["LINKCRAFTABLEREAGENTSNAME"],
                    desc = L["LINKCRAFTABLEREAGENTSDESC"],
                    get = function()
                        return Skillet.db.profile.link_craftable_reagents;
                    end,
                    set = function(value)
                        Skillet.db.profile.link_craftable_reagents = value;
                    end,
                    order = 16
                },
                queue_craftable_reagents = {
                    type = "toggle",
                    name = L["QUEUECRAFTABLEREAGENTSNAME"],
                    desc = L["QUEUECRAFTABLEREAGENTSDESC"],
                    get = function()
                        return Skillet.db.profile.queue_craftable_reagents;
                    end,
                    set = function(value)
                        Skillet.db.profile.queue_craftable_reagents = value;
                    end,
                    order = 17
                },
                display_shopping_list_at_bank = {
                    type = "toggle",
                    name = L["DISPLAYSHOPPINGLISTATBANKNAME"],
                    desc = L["DISPLAYSHOPPINGLISTATBANKDESC"],
                    get = function()
                        return Skillet.db.profile.display_shopping_list_at_bank;
                    end,
                    set = function(value)
                        Skillet.db.profile.display_shopping_list_at_bank = value;
                    end,
                    order = 18
                },
                display_shopping_list_at_auction = {
                    type = "toggle",
                    name = L["DISPLAYSGOPPINGLISTATAUCTIONNAME"],
                    desc = L["DISPLAYSGOPPINGLISTATAUCTIONDESC"],
                    get = function()
                        return Skillet.db.profile.display_shopping_list_at_auction;
                    end,
                    set = function(value)
                        Skillet.db.profile.display_shopping_list_at_auction = value;
                    end,
                    order = 19
                },
                show_craft_counts = {
                    type = "toggle",
                    name = L["SHOWCRAFTCOUNTSNAME"],
                    desc = L["SHOWCRAFTCOUNTSDESC"],
                    get = function()
                        return Skillet.db.profile.show_craft_counts
                    end,
                    set = function(value)
                        Skillet.db.profile.show_craft_counts = value
                        Skillet:UpdateTradeSkillWindow()
                    end,
                    order = 20,
                },
                dev_mode = {
                    type = "toggle",
                    name = "Developer Mode",
                    desc = "Enable detailed debug logging. Can also be toggled with /skillet dev",
                    get = function()
                        return Skillet.db.profile.dev_mode
                    end,
                    set = function(value)
                        Skillet.db.profile.dev_mode = value
                        if value then
                            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[Skillet] Developer mode enabled|r")
                        else
                            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[Skillet] Developer mode disabled|r")
                        end
                    end,
                    order = 21,
                },
            }
        },
        appearance = {
            type = 'group',
            name = L["Appearance"],
            desc = L["APPEARANCEDESC"],
            order = 12,
            args = {
                display_required_level = {
                    type = "toggle",
                    name = L["DISPLAYREQUIREDLEVELNAME"],
                    desc = L["DISPLAYREQUIREDLEVELDESC"],
                    get = function()
                        return Skillet.db.profile.display_required_level
                    end,
                    set = function(value)
                        Skillet.db.profile.display_required_level = value
                        Skillet:UpdateTradeSkillWindow()
                    end,
                    order = 1
                },
                transparency = {
                    type = "range",
                    name = L["Transparency"],
                    desc = L["TRANSPARAENCYDESC"],
                    min = 0.1,
                    max = 1,
                    step = 0.05,
                    isPercent = true,
                    get = function()
                        return Skillet.db.profile.transparency
                    end,
                    set = function(t)
                        Skillet.db.profile.transparency = t
                        Skillet:UpdateTradeSkillWindow()
                    end,
                    order = 2,
                },
                scale = {
                    type = "range",
                    name = L["Scale"],
                    desc = L["SCALEDESC"],
                    min = 0.1,
                    max = 1.25,
                    step = 0.05,
                    isPercent = true,
                    get = function()
                        return Skillet.db.profile.scale
                    end,
                    set = function(t)
                        Skillet.db.profile.scale = t
                        Skillet:UpdateTradeSkillWindow()
                    end,
                    order = 3,
                },
                enhanced_recipe_display = {
                    type = "toggle",
                    name = L["ENHANCHEDRECIPEDISPLAYNAME"],
                    desc = L["ENHANCHEDRECIPEDISPLAYDESC"],
                    get = function()
                        return Skillet.db.profile.enhanced_recipe_display
                    end,
                    set = function(value)
                        Skillet.db.profile.enhanced_recipe_display = value
                        Skillet:UpdateTradeSkillWindow()
                    end,
                    order = 2,
                },
            },
        },
        inventory = {
            type = "group",
            name = L["Inventory"],
            desc = L["INVENTORYDESC"],
            order = 13,
            args = {
                addons = {
                    type = 'execute',
                    name = L["Supported Addons"],
                    desc = L["SUPPORTEDADDONSDESC"],
                    func = function()
                        Skillet:ShowInventoryInfoPopup()
                    end,
                    order = 1,
                },
                show_bank_alt_counts = {
                    type = "toggle",
                    name = L["SHOWBANKALTCOUNTSNAME"],
                    desc = L["SHOWBANKALTCOUNTSDESC"],
                    get = function()
                        return Skillet.db.profile.show_bank_alt_counts
                    end,
                    set = function(value)
                        Skillet.db.profile.show_bank_alt_counts = value
                        Skillet:UpdateTradeSkillWindow()
                    end,
                    order = 2,
                },
            },
        },

        about = {
            type = 'execute',
            name = L["About"],
            desc = L["ABOUTDESC"],
            func = function()
                Skillet:PrintAddonInfo()
            end,
            order = 50
        },
        config = {
            type = 'execute',
            name = L["Config"],
            desc = L["CONFIGDESC"],
            func = function()
                if not (UnitAffectingCombat("player")) then
                    AceLibrary("Waterfall-1.0"):Open("Skillet")
                else
                    DEFAULT_CHAT_FRAME:AddMessage("|cff8888ffSkillet|r: Combat lockdown restriction." ..
                        " Leave combat and try again.")
                end
            end,
            guiHidden = true,
            order = 51
        },
        shoppinglist = {
            type = 'execute',
            name = L["Shopping List"],
            desc = L["SHOPPINGLISTDESC"],
            func = function()
                if not (UnitAffectingCombat("player")) then
                    Skillet:DisplayShoppingList(false)
                else
                    DEFAULT_CHAT_FRAME:AddMessage("|cff8888ffSkillet|r: Combat lockdown restriction." ..
                        " Leave combat and try again.")
                end
            end,
            order = 52
        },
        testattune = {
            type = 'execute',
            name = "Test Attunement",
            desc = "Test attunement status of cursor/mouseover item",
            func = function()
                Skillet:TestAttunement()
            end,
            guiHidden = true,
            order = 53
        },
        testconversions = {
            type = 'execute',
            name = "Test Conversions",
            desc = "Test Crystallized/Eternal conversion calculations",
            func = function()
                Skillet:TestConversions()
            end,
            guiHidden = true,
            order = 54
        },
        depositrbank = {
            type = 'execute',
            name = "Deposit to RBank",
            desc = "Deposit all items to Resource Bank",
            func = function()
                Skillet:DepositToResourceBank()
            end,
            guiHidden = true,
            order = 55
        },
        exportrt = {
            type = 'execute',
            name = "Export to ResourceTracker",
            desc = "Export shopping list to ResourceTracker addon",
            func = function()
                if Skillet.ExportToResourceTrackerCommand then
                    Skillet:ExportToResourceTrackerCommand()
                else
                    Skillet:Print("ResourceTracker integration not loaded")
                end
            end,
            guiHidden = true,
            order = 56
        },
    }
}

-- Called when the addon is loaded
function Skillet:OnInitialize()
    -- Synastria: Assume custom API is available on this server
    -- Will be disabled if API call fails
    self.customApiAvailable = true
    self.customApiFailureReported = false

    -- hook default tooltips
    local tooltipsToHook = { ItemRefTooltip, GameTooltip, ShoppingTooltip1, ShoppingTooltip2 };
    for _, tooltip in pairs(tooltipsToHook) do
        if tooltip and tooltip:HasScript("OnTooltipSetItem") then
            if tooltip:GetScript("OnTooltipSetItem") then
                local oldOnTooltipSetItem = tooltip:GetScript("OnTooltipSetItem")
                tooltip:SetScript("OnTooltipSetItem", function(tooltip)
                    if oldOnTooltipSetItem then
                        oldOnTooltipSetItem(tooltip)
                    end
                    Skillet:AddItemNotesToTooltip(tooltip)
                end)
            else
                tooltip:SetScript("OnTooltipSetItem", function(tooltip)
                    Skillet:AddItemNotesToTooltip(tooltip)
                end)
            end
        end
    end

    -- no need to be spammy about the fact that we are here, they'll find out soon enough
    -- self:Print("Skillet v" .. self.version .. " loaded");

    -- Track trade skill creation
    ---@type SkilletStitch
    self.stitch = AceLibrary("SkilletStitch-1.1")

    -- Log initialization
    SkilletLog:Add("Skillet:OnInitialize() called", "INFO")
    SkilletLog:Add("Checking database tables...", "INFO")

    -- Verify databases loaded
    if self.MILLING_DATA then
        SkilletLog:Add("MILLING_DATA exists - database loaded successfully", "SUCCESS")
    else
        SkilletLog:Add("MILLING_DATA is NIL - database failed to load!", "ERROR")
    end

    if self.PROSPECTING_DATA then
        SkilletLog:Add("PROSPECTING_DATA exists - database loaded successfully", "SUCCESS")
    else
        SkilletLog:Add("PROSPECTING_DATA is NIL - database failed to load!", "ERROR")
    end

    if self.CONVERSION_GROUPS then
        SkilletLog:Add("CONVERSION_GROUPS exists - database loaded successfully", "SUCCESS")
    else
        SkilletLog:Add("CONVERSION_GROUPS is NIL - database failed to load!", "ERROR")
    end

    if self.CONVERSION_DEFINITIONS then
        SkilletLog:Add("CONVERSION_DEFINITIONS exists - database loaded successfully", "SUCCESS")
    else
        SkilletLog:Add("CONVERSION_DEFINITIONS is NIL - database failed to load!", "ERROR")
    end

    -- Make sure this is done in initialize, not enable as we want the chat
    -- commands to be available even when the mod is disabled. Otherwise,
    -- how would the mod be enabled again?
    self:RegisterChatCommand({ "/skillet" }, self.options, "SKILLET")

    -- Register dev mode toggle command
    SLASH_SKILLETDEV1 = "/skillet"
    SlashCmdList["SKILLETDEV"] = function(msg)
        msg = msg:lower():trim()
        if msg == "dev" then
            Skillet.db.profile.dev_mode = not Skillet.db.profile.dev_mode
            if Skillet.db.profile.dev_mode then
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[Skillet] Developer mode ENABLED|r")
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[Skillet] Developer mode DISABLED|r")
            end
        elseif msg == "test" or msg == "phase2" then
            if Skillet.ShowPhase2TestDialog then
                Skillet:ShowPhase2TestDialog()
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Skillet] Testing UI not loaded|r")
            end
        elseif msg == "log" or msg == "logs" then
            -- Dump all logs to chat
            SkilletLog:Dump()
        elseif msg == "log show" or msg == "logui" or msg == "showlog" then
            -- Show the log viewer UI
            Skillet:ShowLogViewer()
        elseif msg == "log clear" or msg == "clearlogs" then
            -- Clear all logs
            SkilletLog:Clear()
        elseif msg == "help" then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Skillet] Available commands:|r")
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFFFF/skillet dev|r - Toggle developer mode")
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFFFF/skillet test|r - Open testing UI")
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFFFF/skillet log|r - Dump diagnostic logs to chat")
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFFFF/skillet log show|r - Show log viewer UI")
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFFFF/skillet log clear|r - Clear all logs")
        end
    end
end

-- Returns the number of items across all characters, including the
-- current one.
local function alt_item_lookup(link)
    local item = Skillet:GetItemIDFromLink(link)
    return Skillet.inventoryCheck:GetItemCount(item)
end

-- Synastria: Check if dev mode is enabled
function Skillet:IsDevMode()
    return self.db and self.db.profile and self.db.profile.dev_mode
end

-- Synastria: Debug logging function that respects dev mode
function Skillet:DebugLog(message, color)
    if self:IsDevMode() then
        -- Map color codes to log levels
        local level = "INFO"
        if color and string.find(color, "FF0000") then
            level = "ERROR"
        elseif color and string.find(color, "FFAA00") then
            level = "WARN"
        elseif color and string.find(color, "00FF00") then
            level = "SUCCESS"
        end

        -- Log to Debug group
        SkilletLog:Add(message, level, "Debug")

        -- Also print to chat for immediate visibility
        color = color or "|cFF888888"
        DEFAULT_CHAT_FRAME:AddMessage(color .. message .. "|r")
    end
end

-- Called when the addon is enabled
function Skillet:OnEnable()
    -- Hook into the events that we care about

    -- Trade skill window changes
    self:RegisterEvent("TRADE_SKILL_CLOSE")
    self:RegisterEvent("TRADE_SKILL_SHOW")
    self:RegisterEvent("TRADE_SKILL_UPDATE")

    -- Learning or unlearning a tradeskill
    self:RegisterEvent('SKILL_LINES_CHANGED')

    -- Tracks when the bumber of items on hand changes
    self:RegisterEvent("BAG_UPDATE")
    self:RegisterEvent("TRADE_CLOSED")

    -- Synastria: Register for UI error messages to detect craft failures
    self:RegisterEvent("UI_ERROR_MESSAGE")

    -- Synastria: Register for spell cast events to detect craft failures
    self:RegisterEvent("UNIT_SPELLCAST_FAILED")
    self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    self:RegisterEvent("UNIT_SPELLCAST_START")
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    self:RegisterEvent("UNIT_SPELLCAST_STOP")

    -- MERCHANT_SHOW, MERCHANT_HIDE, MERCHANT_UPDATE events needed for auto buying.
    self:RegisterEvent("MERCHANT_SHOW")
    self:RegisterEvent("MERCHANT_UPDATE")
    self:RegisterEvent("MERCHANT_CLOSED")

    -- May need to show a shopping list when at the bank/auction house
    self:RegisterEvent("BANKFRAME_OPENED")
    self:RegisterEvent("BANKFRAME_CLOSED")
    self:RegisterEvent("AUCTION_HOUSE_SHOW")
    self:RegisterEvent("AUCTION_HOUSE_CLOSED")

    -- Messages from the Stitch libary
    -- These need to update the tradeskill window, not just the queue
    -- as we need to redisplay the number of items that can be crafted
    -- as we consume reagents.
    self:RegisterEvent("SkilletStitch_Queue_Continue", "QueueChanged")
    self:RegisterEvent("SkilletStitch_Queue_Complete", "QueueChanged")
    self:RegisterEvent("SkilletStitch_Queue_Complete", "ResumeCalculations")
    self:RegisterEvent("SkilletStitch_Queue_Add", "QueueChanged")
    self:RegisterEvent("SkilletStitch_Craft_Failed", "OnCraftFailed")

    self:RegisterEvent("SkilletStitch_Scan_Complete", "ScanCompleted")

    self.hideUncraftableRecipes = false
    self.hideTrivialRecipes = false
    self.currentTrade = nil
    self.selectedSkill = nil

    -- run the upgrade code to convert any old settings
    self:UpgradeDataAndOptions()

    if self.stitch.SetAltCharacterItemLookupFunction and self.inventoryCheck and self.inventoryCheck:IsAvailable() then
        -- Older version of the Stitch-1.1 library may not have this
        -- routine. If they don't then we just don't included item
        -- counts from alt characters.
        self.stitch:SetAltCharacterItemLookupFunction(alt_item_lookup)
    end

    -- hook up our copy of stitch to the data for this character
    ---@type string|nil
    local playerName = UnitName("player")
    if playerName and self.db.server.recipes[playerName] then
        self.stitch.data = self.db.server.recipes[playerName]
    end
    if playerName then
        self.db.server.recipes[playerName] = self.stitch.data
    end

    -- Synastria: Populate recipe info cache from database
    if self.stitch.PopulateRecipeInfoCache then
        self.stitch:PopulateRecipeInfoCache()
    end

    self.stitch:EnableDataGathering("Skillet")
    self.stitch:EnableQueue("Skillet")

    -- Synastria: Check if any professions have old encoded data and need rescanning
    -- Set flag instead of showing dialog immediately
    self:ScheduleEvent("Skillet_CheckOldData", function()
        self:CheckForOldRecipeData()
    end, 3)

    AceLibrary("Waterfall-1.0"):Register("Skillet",
        "aceOptions", Skillet.options,
        "title", L["Skillet Trade Skills"],
        "colorR", 0,
        "colorG", 0.7,
        "colorB", 0
    )
    AceLibrary("Waterfall-1.0"):Open("Skillet")
end

-- Called when the addon is disabled
function Skillet:OnDisable()
    self.stitch:DisableDataGathering("Skillet")
    self.stitch:DisableQueue("Skillet");

    self:UnregisterAllEvents()

    AceLibrary("Waterfall-1.0"):Close("Skillet")
    AceLibrary("Waterfall-1.0"):UnRegister("Skillet")
end

local function is_known_trade_skill(name)
    -- Check to see if we actually know this skill or if the user is
    -- opening a tradeskill that was linked to them. We can't just check
    -- the cached list of skills as this might also be a tradeskill that
    -- the user has just learned.
    local numSkills = GetNumSkillLines()
    for skillIndex = 1, numSkills do
        local skillName = GetSkillLineInfo(skillIndex)
        if skillName ~= nil and skillName == name then
            return true
        end
    end

    -- must not be a trade skill we know about.
    return false
end

-- Checks to see if the current trade is one that we support.
local function is_supported_trade(parent)
    local name = parent:GetTradeSkillLine()

    -- EnchantingSell does not play well with the Skillet window, so
    -- if it is enabled, and it was the craft frame hidden, do not
    -- show Skillet for enchanting.
    --
    -- EnchantingSell does some odd things to the enchanting toggle,
    -- so expect some odd bug reports about this.
    if ESeller and ESeller:IsActive() and ESeller.db.char.DisableDefaultCraftFrame then
        return false
    end

    return is_known_trade_skill(name) and not IsTradeSkillLinked()
end

local scan_in_progress = false
local need_rescan_on_open = false
local forced_rescan = false

function Skillet:ScanCompleted()
    if scan_in_progress then
        if forced_rescan and not need_rescan_on_open then
            -- only print this if we are not not doing a bag rescan,
            -- i.e. a first time or forced rescan.
            local name = self:GetTradeSkillLine()
            self:Print(GetLocalizedString("Scan completed") .. ": " .. name);
        end

        -- Synastria: Clear craftability cache after scan to force recalculation
        ---@type SkilletStitch
        local lib = AceLibrary("SkilletStitch-1.1")
        if lib and lib.ClearCraftabilityCache then
            lib:ClearCraftabilityCache()
            -- Cache cleared after scan (debug output removed)
        end

        self:UpdateScanningText("")
        scan_in_progress = false
        need_rescan_on_open = false
        forced_rescan = false
        self:UpdateTradeSkillWindow()
    end
end

-- Checks to see if the list of recipes has been cached
-- before and if not, scans them. This only works on the
-- currently selected tradeskill
local function cache_recipes_if_needed(self, force)
    if scan_in_progress then
        return true
    end

    ---@type string|nil
    local trade = self:GetTradeSkillLine()

    if not trade or trade == "UNKNOWN" then
        return
    end

    local count = self:GetNumTradeSkills(trade)
    if count <= 0 and not force then
        -- no recipes == no scan
        return false
    end

    local recipes_known = (self.stitch:GetItemDataByIndex(trade, count) ~= nil)

    if force or not recipes_known then
        forced_rescan = true
        self:RescanTrade(true)
        return true
    end

    return false
end

local function Skillet_rescan_skills()
    local numSkills = GetNumSkillLines()
    local skills = {}
    for skillIndex = 1, numSkills do
        local skillName = GetSkillLineInfo(skillIndex)
        if skillName ~= nil then
            skills[skillName] = skillName

            -- Synastria: Add mapped profession names
            -- Mining skill opens Smelting tradeskill window, so treat them as the same
            if skillName == "Mining" then
                skills["Smelting"] = "Smelting"
            end
        end
    end

    ---@type string|nil
    local player = UnitName("player")

    -- Synastria: Virtual professions that should never be checked or removed
    local virtualProfessions = {
        ["Conversion"] = true,
    }

    local changed = false
    if player then
        for profession, _ in pairs(Skillet.db.server.recipes[player]) do
            -- Skip virtual professions - they're not real professions
            if not virtualProfessions[profession] and not skills[profession] then
                changed = true
                if profession ~= "UNKNOWN" then
                    -- where the hell does this come from?
                    Skillet:Print("No longer know: " .. profession)
                end
                Skillet.db.server.recipes[player][profession] = nil
            end
        end

        if changed == true then
            Skillet:HideAllWindows()
            if Skillet.db.server.recipes[player] then
                Skillet.stitch.data = Skillet.db.server.recipes[player]
            end
            Skillet.db.server.recipes[player] = Skillet.stitch.data
            Skillet:internal_ResetCharacterCache()
        end
    end
end

-- Called when the list of trade skills know by the player has changed
function Skillet:SKILL_LINES_CHANGED()
    if not AceEvent:IsEventScheduled("Skillet_rescan_skills") and not IsTradeSkillLinked() then
        AceEvent:ScheduleEvent("Skillet_rescan_skills", Skillet_rescan_skills, 10.0)
    end
end

-- Called when the trade skill window is opened
-- or when the window is open and the user selects another tradeskill
function Skillet:TRADE_SKILL_SHOW()
    if is_supported_trade(self) then
        -- Synastria: Check if we were waiting for a profession switch
        if self.stitch.waitingForProfessionSwitch and self.stitch.targetProfession then
            local currentTrade = GetTradeSkillLine()
            if currentTrade == self.stitch.targetProfession then
                -- Profession switch successful!
                self.stitch.waitingForProfessionSwitch = false
                self.stitch.targetProfession = nil

                -- Update the crafting prompt to show start button
                if self.startCraftingPrompt and self.startCraftingPrompt:IsVisible() then
                    self:ShowStartCraftingPrompt()
                end
            end
        end

        -- Synastria: Clear craftability cache when switching professions
        local lib = AceLibrary("SkilletStitch-1.1")
        if lib and lib.ClearCraftabilityCache then
            lib:ClearCraftabilityCache()
        end

        -- Synastria: Check if we need to prompt for recipe rescanning
        if self.needsRecipeScan and #self.needsRecipeScan > 0 then
            local temp = self.needsRecipeScan
            self.needsRecipeScan = nil -- Clear flag before showing dialog
            self:ShowRecipePrompt(temp)
        end

        self:UpdateTradeSkill()
        self:ShowTradeSkillWindow()
        self.stitch:TRADE_SKILL_SHOW()

        -- Synastria: Start background craftability calculation
        ---@type string|nil
        local profession = GetTradeSkillLine()
        if profession and profession ~= "UNKNOWN" then
            if self.CraftCalc then
                -- Stop any existing calculation first
                self.CraftCalc:StopCalculation()

                self.CraftCalc:StartBackgroundCalculation(profession, function(count)
                    -- Callback when calculation is complete
                    self:DebugLog("[ScanDialog] Calculation complete for '" .. profession .. "', updating UI",
                        "|cFF00FFFF")
                    self:UpdateTradeSkillWindow()

                    -- Re-enable the scan dialog button if it's visible
                    -- Don't update dialog text here - PostClick handles that when moving to next profession
                    if self.recipePromptDialog and self.recipePromptDialog:IsVisible() then
                        local dialog = self.recipePromptDialog
                        if dialog then
                            local openBtn = (dialog --[[@as table]]).openButton
                            if openBtn then
                                self:DebugLog(
                                    "[ScanDialog] Re-enabling Open Next button after '" .. profession .. "' scan",
                                    "|cFF00FF00")
                                openBtn:Enable()
                            else
                                self:DebugLog("[ScanDialog] Cannot re-enable: button missing", "|cFFFFAA00")
                            end
                        end
                    end
                end)
            end
        end
    else
        self:HideAllWindows()
    end
end

function Skillet:TRADE_SKILL_UPDATE()
    if IsTradeSkillLinked() then
        return
    end
    self:UpdateTradeSkill()
    if not AceEvent:IsEventScheduled("Skillet_redo_the_update") then
        self:ResetTradeSkillWindow()
        self:UpdateTradeSkillWindow()
    end
end

-- Called when the trade skill window is closed
function Skillet:TRADE_SKILL_CLOSE()
    local show_after_scan = false
    self:HideAllWindows()
end

-- Rescans the trades (and thus bags). Can only be called if the tradeskill
-- window is open and a trade selected.
-- local function Skillet_rescan_bags()
--     cache_recipes_if_needed(Skillet, false)
--     Skillet:UpdateTradeSkillWindow()
--     Skillet:UpdateShoppingListWindow()
-- end

-- So we can track when the players inventory changes and update craftable counts
function Skillet:BAG_UPDATE()
    -- Synastria: First, notify SkilletStitch for queue processing
    if self.stitch and self.stitch.OnBagUpdate then
        self.stitch:OnBagUpdate()
    end

    -- Synastria: Clear craftability cache when inventory changes
    ---@type SkilletStitch
    local lib = AceLibrary("SkilletStitch-1.1")
    if lib and lib.ClearCraftabilityCache then
        lib:ClearCraftabilityCache()
    end

    local showing = false
    if self.tradeSkillFrame and self.tradeSkillFrame:IsVisible() then
        showing = true
    end
    if self.shoppingList and self.shoppingList:IsVisible() then
        showing = true
    end

    if showing then
        -- Synastria: Start background recalculation after clearing cache
        -- This replaces the old 0.25s scheduled rescan which would read from
        -- an empty cache and populate it with incorrect values
        local profession = self.currentTrade
        if profession and profession ~= "UNKNOWN" and self.CraftCalc then
            self.CraftCalc:StartBackgroundCalculation(profession, function(count)
                -- Callback when calculation is complete - update windows
                self:UpdateTradeSkillWindow()
                self:UpdateShoppingListWindow()
            end)
        end
    else
        -- no trade window open, but something change, we will need to rescan
        -- when the window is next opened.
        need_rescan_on_open = true
    end

    if MerchantFrame and MerchantFrame:IsVisible() then
        -- may need to update the button on the merchant frame window ...
        self:UpdateMerchantFrame()
    end
end

-- Synastria: UI_ERROR_MESSAGE handler for craft failure detection
function Skillet:UI_ERROR_MESSAGE(errorType, message)
    -- Pass to stitch library which handles queue processing
    if self.stitch and self.stitch.queuecasting then
        self.stitch:OnUIError(errorType, message)
    end
end

-- Synastria: Spell cast event handlers to detect craft failures
function Skillet:UNIT_SPELLCAST_FAILED(unit, spellName, rank, lineID, spellID)
    if unit == "player" and self.stitch and self.stitch.queuecasting then
        self.stitch:OnSpellcastFailed("UNIT_SPELLCAST_FAILED", unit, spellName, rank)
    end
end

function Skillet:UNIT_SPELLCAST_INTERRUPTED(unit, spellName, rank, lineID, spellID)
    if unit == "player" and self.stitch and self.stitch.queuecasting then
        self.stitch:OnSpellcastFailed("UNIT_SPELLCAST_INTERRUPTED", unit, spellName, rank)
    end
end

function Skillet:UNIT_SPELLCAST_START(unit, spellName, rank, lineID, spellID)
    -- Event tracked for future use
end

function Skillet:UNIT_SPELLCAST_SUCCEEDED(unit, spellName, rank, lineID, spellID)
    -- Synastria: First, notify Skillet Stitch for windowless craft detection
    if self.stitch and self.stitch.OnSpellcastSucceeded then
        self.stitch:OnSpellcastSucceeded("UNIT_SPELLCAST_SUCCEEDED", unit, spellName, rank, lineID, spellID)
    end

    if unit ~= "player" or not spellID then
        return
    end

    -- Synastria: Update extraction frame after milling/prospecting
    -- Results go to resource bank and don't trigger BAG_UPDATE
    local isMillingOrProspecting = (spellID == 51005 or spellID == 80348 or
        spellID == 31252 or spellID == 80347)

    if isMillingOrProspecting and self.extractionFrame and self.extractionFrame:IsVisible() then
        -- Schedule update after a short delay to allow resource bank to update
        self:ScheduleEvent("Skillet_UpdateExtractionAfterCast", function()
            self:UpdateExtractionListDisplay()
        end, 0.5)
    end

    -- Synastria: Handle queue removal for non-item-producing crafts (enchantments, improvements)
    -- These don't produce items in bags, so BAG_UPDATE never fires to remove them from queue
    if self.stitch and self.stitch.queuecasting and self.stitch.queue and self.stitch.queue[1] then
        local spellId = self.stitch.queue[1].spellId
        if spellId and Custom_GetProfessionRecipeInfo then
            local skillId, name, itemId = Custom_GetProfessionRecipeInfo(spellId)
            -- If itemId is nil, this is a non-item craft (enchantment, improvement)
            if not itemId then
                -- This is an enchantment or improvement - process completion manually
                -- Schedule it slightly delayed to ensure spell has completed
                self:ScheduleEvent("Skillet_ProcessNonItemCraft", function()
                    if self.stitch and self.stitch.queuecasting then
                        self.stitch:ProcessCraftCompletion()
                    end
                end, 0.25)
            end
        end
    end
end

function Skillet:UNIT_SPELLCAST_STOP(unit, spellName, rank, lineID, spellID)
    -- Event tracked for future use
end

-- Trade window close, the counts may need to be updated.
-- This could be because an enchant has used up mats or the player
-- may have received more mats.
function Skillet:TRADE_CLOSED()
    self:BAG_UPDATE()
end

-- Updates the tradeskill window, if the current trade has changed.
function Skillet:UpdateTradeSkill()
    local trade_changed = false
    local new_trade = self:GetTradeSkillLine()

    if not self.currentTrade and new_trade then
        trade_changed = true
    elseif self.currentTrade ~= new_trade then
        trade_changed = true
    end

    if trade_changed then
        self:HideNotesWindow();

        -- remove any filters currently in place
        local filterbox = getglobal("SkilletFilterBox");
        local filtertext = self:GetTradeSkillOption(new_trade, "filtertext") or ""
        filterbox:SetText(filtertext);

        -- And start the update sequence through the rest of the mod
        self:SetSelectedTrade(new_trade)

        cache_recipes_if_needed(self, need_rescan_on_open)

        -- Load up any saved queued items for this profession
        self:LoadQueue(self.db.server.queues, new_trade)
    end
end

-- Shows the trade skill frame.
function Skillet:internal_ShowTradeSkillWindow()
    local frame = self.tradeSkillFrame
    if not frame then
        frame = self:CreateTradeSkillWindow()
        self:UpdateTradeSkillWindow()
        self.tradeSkillFrame = frame
    end

    self:ResetTradeSkillWindow()

    if frame and not frame:IsVisible() then
        ShowUIPanel(frame)
    end
end

--
-- Hides the Skillet trade skill window. Does nothing if the window is not visible
--
function Skillet:internal_HideTradeSkillWindow()
    ---@type boolean|nil
    local closed -- was anything closed by us?
    local frame = self.tradeSkillFrame

    if frame and frame:IsVisible() then
        -- Synastria: StopCast removed - BAG_UPDATE handles completion
        HideUIPanel(frame)
        closed = true
    end

    return closed
end

--
-- Hides any and all Skillet windows that are open
--
function Skillet:internal_HideAllWindows()
    ---@type boolean|nil
    local closed -- was anything closed?

    -- Cancel anything currently being created
    self.stitch:CancelCast()

    if self:HideTradeSkillWindow() then
        closed = true
    end

    if self:HideNotesWindow() then
        closed = true
    end

    if self:HideShoppingList() then
        closed = true
    end

    self.currentTrade = nil
    self.selectedSkill = nil

    return closed
end

-- Show the options window
function Skillet:ShowOptions()
    AceLibrary("Waterfall-1.0"):Open("Skillet");
end

-- Synastria: Resume craftability calculations after queue processing
function Skillet:ResumeCalculations()
    if self.CraftCalc then
        self.CraftCalc:ResumeCalculation()
    end
end

-- Synastria: Debug craftability calculation for selected recipe
function Skillet:DebugSelectedRecipe()
    if not self.selectedSkill then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Skillet Debug] No recipe selected!|r")
        return
    end

    ---@type SkilletStitch
    local lib = AceLibrary("SkilletStitch-1.1")
    local recipe = lib:GetItemDataByIndex(self.currentTrade, self.selectedSkill)

    if not recipe then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Skillet Debug] Could not get recipe data!|r")
        return
    end

    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00=== Skillet Debug: " .. (recipe.name or "Unknown") .. " ===|r")

    if self.CraftCalc then
        -- Show recursive crafting tree
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00Recursive Crafting Tree:|r")
        self:DebugRecipeTree(recipe, lib, false, 0)

        DEFAULT_CHAT_FRAME:AddMessage(" ")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00Detailed Calculation Log:|r")
        -- Test bags+resbank - FORCE RECALCULATION with verbose output
        -- Note: Queue net reservation cache is built automatically in CalculateRecipeCraftabilityCustomAPI
        local numCraftable = self.CraftCalc:CalculateRecipeCraftability(recipe, lib, false, true, 0, true)

        DEFAULT_CHAT_FRAME:AddMessage(" ")
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF  Final Result: " .. tostring(numCraftable) .. "|r")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Skillet Debug] CraftCalc not available!|r")
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00==================|r")
end

-- Synastria: Debug helper to show recursive crafting tree
function Skillet:DebugRecipeTree(recipe, lib, includeBank, depth)
    if not recipe or not recipe.name then
        return
    end

    depth = depth or 0
    local indent = string.rep("  ", depth)

    -- Show recipe name
    if depth == 0 then
        DEFAULT_CHAT_FRAME:AddMessage(indent .. "|cFF00FF00" .. recipe.name .. "|r")
    else
        DEFAULT_CHAT_FRAME:AddMessage(indent .. "|cFFFFFFFF" .. recipe.name .. "|r")
    end

    -- Show reagents
    if recipe.reagents and #recipe.reagents > 0 then
        for i, reagent in ipairs(recipe.reagents) do
            local available = reagent.num or 0
            local needed = reagent.needed or 0
            local vendor = reagent.vendor and " (Vendor)" or ""

            -- Calculate max craftable from this reagent
            local maxFromReagent = math.floor(available / needed)

            -- Check if reagent is craftable
            local reagentRecipe = lib:GetItemDataByName(reagent.name)

            -- Synastria: Check if reagent has nummade > 1 to show craft equivalence
            local craftsInfo = ""
            if reagentRecipe and reagentRecipe.nummade and reagentRecipe.nummade > 1 then
                local craftsWorth = math.floor(available / reagentRecipe.nummade)
                local craftsNeeded = math.ceil(needed / reagentRecipe.nummade)
                craftsInfo = string.format(" (%d/%d crafts)", craftsWorth, craftsNeeded)
            end

            -- Check if reagent has conversions (e.g., Eternal Fire from other Eternals)
            local conversionText = ""
            if reagent.name and reagent.name:match("^Eternal ") then
                -- Check for conversion recipe (e.g., "Transmute: Eternal X to Eternal Y")
                local targetEternal = reagent.name
                -- Common eternal types to check
                local eternals = { "Eternal Fire", "Eternal Earth", "Eternal Water", "Eternal Air", "Eternal Shadow",
                    "Eternal Life" }
                for _, sourceEternal in ipairs(eternals) do
                    if sourceEternal ~= targetEternal then
                        local conversionName = "Transmute: " .. sourceEternal .. " to " .. targetEternal
                        local conversionRecipe = lib:GetItemDataByName(conversionName)
                        if conversionRecipe then
                            conversionText = conversionText .. " [Conv: " .. sourceEternal:match("Eternal (%w+)") .. "]"
                        end
                    end
                end
            end

            local craftableText = ""
            if reagentRecipe then
                craftableText = " [Craftable]"
            end

            -- Color code based on availability
            local color = "|cFF00FF00" -- Green if enough
            if available < needed then
                color = "|cFFFF0000"   -- Red if shortage
            end

            DEFAULT_CHAT_FRAME:AddMessage(string.format("%s  %s%s: %d/%d%s -> max %d%s%s%s|r",
                indent, color, reagent.name, available, needed, craftsInfo, maxFromReagent, vendor, craftableText,
                conversionText))

            -- Recurse if craftable and we have a shortage
            if reagentRecipe and available < needed and depth < 5 then
                self:DebugRecipeTree(reagentRecipe, lib, includeBank, depth + 1)
            end
        end
    end
end

-- Synastria: Check if an item is attuned (custom server API)
-- @param itemLink: Item link or bag/slot location
-- @return isAttuned: true if item is fully attuned (100% progress), false otherwise
-- Note: GetItemAttuneProgress() is more reliable than HasAttunedAnyVariant()
function Skillet:IsItemAttuned(itemLink)
    if not itemLink then
        return false
    end

    -- Use GetItemAttuneProgress as it's more reliable
    -- Returns a number 0-100 representing attunement progress
    if GetItemAttuneProgress then
        local progress = GetItemAttuneProgress(itemLink)
        return progress and progress >= 100
    end

    -- Fallback: try HasAttunedAnyVariant (may not work correctly)
    if HasAttunedAnyVariant then
        return HasAttunedAnyVariant(itemLink) == true
    end

    -- No API available
    return false
end

-- Synastria: Get attunement progress for an item
-- @param itemLink: Item link or bag/slot location
-- @return progress: Number 0-100, or nil if not attuneable
function Skillet:GetItemAttunementProgress(itemLink)
    if not itemLink or not GetItemAttuneProgress then
        return nil
    end

    return GetItemAttuneProgress(itemLink)
end

-- ========================================
-- Synastria: Centralized Conversion System
-- ========================================
-- NOTE: Conversion data has been moved to Databases/ConversionData.lua
--   - Skillet.CONVERSION_DEFINITIONS: Main conversion table
--   - Skillet.CONVERSION_GROUPS: UI grouping for extraction interface
--   - CRYSTALLIZED_TO_ETERNAL_MAP: Auto-generated lookup map
--   - ETERNAL_TO_CRYSTALLIZED_MAP: Auto-generated lookup map
-- ========================================

-- Helper function: Get conversion info for an item
-- Returns: targetId, inputAmount, outputAmount, type or nil if no conversion exists
---@param itemId number The item ID to check for conversions
---@return number|nil targetId The target item ID to convert to/from
---@return number|nil inputAmount How many source items needed for conversion
---@return number|nil outputAmount How many target items produced by conversion
---@return string|nil convType The conversion type ('combine' or 'split')
function Skillet:GetConversionInfo(itemId)
    -- Guard: Ensure CONVERSION_DEFINITIONS is loaded
    if not self.CONVERSION_DEFINITIONS then
        return nil
    end

    -- Check if this item is a TARGET (can be created FROM something else)
    -- We check TARGET first because when we need an item, we want to make it (not use it up)
    for _, conversion in ipairs(self.CONVERSION_DEFINITIONS) do
        if conversion.target == itemId then
            -- Return the source, input amount, output amount, type, and tool item ID
            return conversion.source, conversion.inputAmount, conversion.outputAmount, conversion.type,
                conversion.toolItemId
        end
    end

    -- Check if this item is a SOURCE (can be converted INTO something else)
    -- This handles the case where we have excess and want to convert it
    for _, conversion in ipairs(self.CONVERSION_DEFINITIONS) do
        if conversion.source == itemId then
            return conversion.target, conversion.inputAmount, conversion.outputAmount, conversion.type,
                conversion.toolItemId
        end
    end

    return nil, nil, nil, nil, nil
end

-- Synastry: Get prebuilt queue consumption cache (built during craftability calculation)
-- If cache doesn't exist, returns nil (caller should handle fallback)
---@return table<number, number>|nil netReservationMap Maps itemId -> net reserved amount (consumption - production)
function Skillet:GetQueueNetReservationCache()
    -- Access the cache from CraftCalc module
    if self.CraftCalc and self.CraftCalc.GetQueueNetReservationCache then
        return self.CraftCalc:GetQueueNetReservationCache()
    end
    return nil
end

-- If cache doesn't exist, returns nil (caller should handle fallback)
---@return table<number, number>|nil consumptionMap Maps itemId -> total quantity reserved
function Skillet:GetQueueConsumptionCache()
    -- Legacy function - now deprecated for craftability calculations
    -- Craftability now uses net reservations (consumption - production)
    -- This function kept for backward compatibility if needed
    return nil
end

-- Synastria: Calculate how many of an item will be consumed by queued recipes
-- OPTIMIZED: Uses prebuilt cache if available (during craftability calc)
---@param itemId number|nil The item ID to check
---@return number The total quantity needed from the queue
function Skillet:GetQueuedReagentConsumption(itemId)
    if not itemId then return 0 end

    -- Try to use prebuilt cache first (MUCH faster during bulk calculations)
    local cache = self:GetQueueConsumptionCache()
    if cache then
        local cached = cache[itemId] or 0
        if cached > 0 then
            local itemName = GetItemInfo(itemId) or ("Item#" .. itemId)
            self:DebugLog(string.format("[QueueConsump] %s: %d (from cache)", itemName, cached), "|cFF00FF00")
        end
        return cached
    end

    -- No cache available - build on-demand (slower, but necessary for non-calc contexts)
    ---@type SkilletStitch
    local lib = AceLibrary("SkilletStitch-1.1")
    if not lib or not lib.queue then return 0 end

    local itemName = GetItemInfo(itemId) or ("Item#" .. itemId)
    self:DebugLog(string.format("[QueueConsump] %s: calculating on-demand (no cache)", itemName), "|cFFFFAA00")

    -- DETAILED LOGGING: Track each contributing recipe
    if self:IsDevMode() then
        DEFAULT_CHAT_FRAME:AddMessage(string.format(
            "|cFFFF8800[CONSUMPTION CALC] Calculating consumption for %s (ID %d)|r", itemName, itemId))
    end

    local totalNeeded = 0

    -- Synastria: Use Custom API for optimized reagent lookup
    if Custom_GetProfessionRecipeReagents then
        for i = 1, #lib.queue do
            local entry = lib.queue[i]
            if entry.spellId then
                local reagents = Custom_GetProfessionRecipeReagents(entry.spellId)
                if reagents and reagents[itemId] then
                    local neededPerCraft = reagents[itemId]
                    local numCasts = entry.numcasts or 1
                    local contribution = neededPerCraft * numCasts
                    totalNeeded = totalNeeded + contribution

                    if self:IsDevMode() then
                        DEFAULT_CHAT_FRAME:AddMessage(string.format(
                            "|cFFFF8800  - %s x%d -> consumes %d (total now: %d)|r",
                            entry.name or "Unknown", numCasts, contribution, totalNeeded))
                    end
                end
            end
        end
    else
        -- Fallback: Traditional method
        for i = 1, #lib.queue do
            local entry = lib.queue[i]
            if entry.recipe and entry.recipe.reagents then
                for _, reagent in ipairs(entry.recipe.reagents) do
                    local reagentId = self:GetItemIDFromLink(reagent.link)
                    if reagentId == itemId then
                        local neededPerCraft = reagent.needed or 1
                        local numCasts = entry.numcasts or 1
                        local contribution = neededPerCraft * numCasts
                        totalNeeded = totalNeeded + contribution

                        if self:IsDevMode() then
                            DEFAULT_CHAT_FRAME:AddMessage(string.format(
                                "|cFFFF8800  - %s x%d -> consumes %d (total now: %d)|r",
                                entry.name or "Unknown", numCasts, contribution, totalNeeded))
                        end
                    end
                end
            end
        end
    end

    if self:IsDevMode() and totalNeeded > 0 then
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFF8800[CONSUMPTION CALC] TOTAL CONSUMPTION: %d|r", totalNeeded))
    end

    return totalNeeded
end

-- Synastria: Calculate how many of an item will be produced by queued recipes
---@param itemId number|nil The item ID to check
---@return number The total quantity that will be produced
function Skillet:GetQueuedItemProduction(itemId)
    if not itemId then return 0 end

    ---@type SkilletStitch
    local lib = AceLibrary("SkilletStitch-1.1")
    if not lib or not lib.queue then return 0 end

    local totalProduced = 0

    -- DETAILED LOGGING: Track each contributing recipe
    local itemName = GetItemInfo(itemId) or ("Item#" .. itemId)
    if self:IsDevMode() then
        DEFAULT_CHAT_FRAME:AddMessage(string.format(
            "|cFF00FFFF[PRODUCTION CALC] Calculating production for %s (ID %d)|r", itemName, itemId))
    end

    -- Synastria: Use Custom API to get crafted item info
    if Custom_GetProfessionRecipeInfo then
        for i = 1, #lib.queue do
            local entry = lib.queue[i]
            if entry.spellId then
                local skillId, name, craftedItemId, craftedItemCount = Custom_GetProfessionRecipeInfo(entry.spellId)
                if craftedItemId == itemId then
                    local producedPerCraft = craftedItemCount or 1
                    local numCasts = entry.numcasts or 1
                    local contribution = producedPerCraft * numCasts
                    totalProduced = totalProduced + contribution

                    if self:IsDevMode() then
                        DEFAULT_CHAT_FRAME:AddMessage(string.format(
                            "|cFF00FFFF  + %s x%d -> produces %d (total now: %d)|r",
                            name or "Unknown", numCasts, contribution, totalProduced))
                    end
                end
            end
        end
    else
        -- Fallback: Use recipe.link to extract crafted item ID
        for i = 1, #lib.queue do
            local entry = lib.queue[i]
            if entry.recipe and entry.recipe.link then
                local craftedItemId = tonumber(entry.recipe.link:match("item:(%d+)"))
                if craftedItemId == itemId then
                    local producedPerCraft = entry.recipe.nummade or 1
                    local numCasts = entry.numcasts or 1
                    local contribution = producedPerCraft * numCasts
                    totalProduced = totalProduced + contribution

                    if self:IsDevMode() then
                        DEFAULT_CHAT_FRAME:AddMessage(string.format(
                            "|cFF00FFFF  + %s x%d -> produces %d (total now: %d)|r",
                            entry.name or "Unknown", numCasts, contribution, totalProduced))
                    end
                end
            end
        end
    end

    if totalProduced > 0 then
        self:DebugLog(string.format("[QueueProduce] %s: %d will be produced", itemName, totalProduced), "|cFF00FFFF")
        if self:IsDevMode() then
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF00FFFF[PRODUCTION CALC] TOTAL PRODUCTION: %d|r",
                totalProduced))
        end
    end

    return totalProduced
end

-- Synastria: Queue conversions when needed (bidirectional support)
-- Handles both Crystallized->Eternal (combine) and Eternal->Crystallized (split)
---@param reagent Reagent The reagent object from a recipe
---@param needed number How many of this reagent we need total
---@param skipQueuedConsumption? boolean If true, don't subtract queued consumption (used during regeneration)
---@return boolean queued True if conversion was queued, false otherwise
function Skillet:QueueConversionsIfNeeded(reagent, needed, skipQueuedConsumption)
    if not reagent or not needed or needed <= 0 then
        return false
    end

    -- Get the item ID from the reagent link
    local itemId = self:GetItemIDFromLink(reagent.link)
    if not itemId then
        return false
    end

    -- Get conversion info for this item (now includes toolItemId)
    local targetId, inputAmount, outputAmount, conversionType, toolItemId = self:GetConversionInfo(itemId)
    if not targetId or not inputAmount or not outputAmount or not toolItemId then
        return false -- No conversion available for this item
    end

    -- Calculate how many we have of the needed item
    local available = GetItemCount(itemId, true) or 0
    if GetCustomGameData then
        available = available + (GetCustomGameData(13, itemId) or 0)
    end

    -- Subtract items already allocated to queued recipes UNLESS we're regenerating
    -- During regeneration, recipes are already in queue, so subtracting would double-count
    local queuedConsumption = 0
    if not skipQueuedConsumption then
        queuedConsumption = self:GetQueuedReagentConsumption(itemId)
    end
    local availableBeforeQueue = available
    available = available - queuedConsumption

    -- Debug output
    local itemName = GetItemInfo(itemId) or ("Item#" .. itemId)
    self:DebugLog(string.format("[Conv Check] %s: have %d, queued %d, avail %d, need %d%s",
        itemName, availableBeforeQueue, queuedConsumption, available, needed,
        skipQueuedConsumption and " (skip queued)" or ""))

    if available >= needed then
        self:DebugLog(string.format("[Conv Check] %s: Already have enough (avail %d >= need %d)",
            itemName, available, needed))
        return false -- We already have enough (after accounting for queue)
    end

    -- Calculate the shortage - this is what we need to convert
    local shortage = needed - available
    ---@type number
    local conversionsNeeded = 0
    ---@type number
    local amountToConvert = 0

    if conversionType == "combine" then
        -- Crystallized -> Eternal (e.g., inputAmount=10, outputAmount=1)
        -- Need X Eternals, calculate how many Crystallized we need
        conversionsNeeded = shortage                      -- How many Eternals we need to make
        amountToConvert = conversionsNeeded * inputAmount -- How many Crystallized we need (e.g., X * 10)
    elseif conversionType == "split" then
        -- Eternal -> Crystallized (e.g., inputAmount=1, outputAmount=10)
        -- Need X Crystallized, calculate how many Eternals we need to split
        conversionsNeeded = math.ceil(shortage * inputAmount / outputAmount) -- e.g., ceil(X * 1 / 10)
        amountToConvert = conversionsNeeded                                  -- Eternals to split
    else
        return false
    end

    if conversionsNeeded <= 0 then
        return false
    end

    -- Get item names
    local neededName = GetItemInfo(itemId) or "Item"
    local convertibleName = GetItemInfo(targetId) or "Item"

    -- Determine which item we're using and which we're making
    ---@type number
    local sourceId = 0
    ---@type number
    local sourceNeeded = 0
    ---@type number
    local outputId = 0
    ---@type number
    local queueOutputAmount = 0
    if conversionType == "combine" then
        sourceId = targetId                                  -- Crystallized (what we use)
        sourceNeeded = amountToConvert
        outputId = itemId                                    -- Eternal (what we make)
        queueOutputAmount = conversionsNeeded
    else                                                     -- split
        sourceId = targetId                                  -- Eternal (what we use)
        sourceNeeded = amountToConvert
        outputId = itemId                                    -- Crystallized (what we make)
        queueOutputAmount = conversionsNeeded * outputAmount -- e.g., 5 Eternals * 10 = 50 Crystallized
    end

    -- Add the virtual conversion recipe to the queue
    ---@type SkilletStitch
    local lib = AceLibrary("SkilletStitch-1.1")
    if lib and lib.queue then
        -- Check if this exact conversion is already in the queue
        for i = 1, #lib.queue do
            local entry = lib.queue[i]
            if entry.recipe and entry.recipe.isVirtualConversion and
                entry.recipe.sourceId == sourceId and
                entry.recipe.outputId == outputId then
                -- Found existing conversion - check if we need to increase it
                local currentOutput = entry.recipe.outputAmount or 0

                self:DebugLog(string.format("[Conv] Found existing conversion for %s: currently %d, shortage is %d",
                    neededName, currentOutput, shortage))

                -- Calculate total we'll have after existing conversion completes
                local totalAfterConversion = available + currentOutput

                if totalAfterConversion >= needed then
                    self:DebugLog(string.format("[Conv] Existing conversion sufficient: %d + %d >= %d",
                        available, currentOutput, needed))
                    return false -- Existing conversion is already sufficient
                end

                -- Need more - add only the additional shortage
                local additionalNeeded = needed - totalAfterConversion

                self:DebugLog(string.format("[Conv] Need %d more, updating conversion", additionalNeeded))

                if conversionType == "combine" then
                    -- Combine: e.g., 10 Crystallized -> 1 Eternal (inputAmount=10, outputAmount=1)
                    -- additionalNeeded is in Eternals, sourceNeeded should be in Crystallized
                    entry.recipe.outputAmount = currentOutput + additionalNeeded
                    entry.recipe.sourceNeeded = entry.recipe.outputAmount *
                        inputAmount -- e.g., X Eternals * 10 = X*10 Crystallized
                else                -- split
                    -- Split: e.g., 1 Eternal -> 10 Crystallized (inputAmount=1, outputAmount=10)
                    -- additionalNeeded is in Crystallized, sourceNeeded should be in Eternals
                    entry.recipe.outputAmount = currentOutput +
                        (additionalNeeded * outputAmount)                                                         -- Total Crystallized output
                    entry.recipe.sourceNeeded = math.ceil(entry.recipe.outputAmount * inputAmount / outputAmount) -- Convert back to Eternals
                end

                local outputName = GetItemInfo(outputId) or "Item"
                local updatedName = string.format("%s (x%d)", outputName, entry.recipe.outputAmount)
                entry.recipe.name = updatedName

                -- Update all serializable fields
                entry.name = updatedName
                entry.link = reagent.link
                entry.sourceNeeded = entry.recipe.sourceNeeded
                entry.outputAmount = entry.recipe.outputAmount
                entry.crystallizedNeeded = entry.recipe.crystallizedNeeded
                entry.eternalsToMake = entry.recipe.eternalsToMake

                self:Print(string.format("|cFFFFAA00Conversion updated: %s (now %dx)|r", outputName,
                    entry.recipe.outputAmount))

                -- Synastria: CRITICAL - Save queue to database so conversion updates persist
                self:SaveQueue(self.db.server.queues, self.currentTrade)

                -- Clear craftability cache since conversion amounts changed
                lib:ClearCraftabilityCache()
                return true
            end
        end

        -- No existing conversion found - create new one
        local virtualRecipe = {
            name = string.format("%s (x%d)", neededName,
                conversionType == "combine" and conversionsNeeded or queueOutputAmount),
            link = "item:" .. outputId,       -- Simple primitive string instead of reagent.link (which might be non-serializable)
            isVirtualConversion = true,
            conversionType = conversionType,  -- "combine" or "split"
            sourceId = sourceId,              -- What we withdraw
            outputId = outputId,              -- What we make
            toolItemId = toolItemId,          -- What we use (may be source or a tool like Salt Shaker)
            sourceNeeded = sourceNeeded,      -- How many to withdraw
            outputAmount = queueOutputAmount, -- How many we'll make
            -- Backwards compatibility fields
            crystallizedId = conversionType == "combine" and sourceId or outputId,
            eternalId = conversionType == "combine" and outputId or sourceId,
            crystallizedNeeded = conversionType == "combine" and sourceNeeded or queueOutputAmount,
            eternalsToMake = conversionType == "combine" and conversionsNeeded or amountToConvert,
        }

        table.insert(lib.queue, 1, { -- Insert at the beginning so it runs first
            profession = "Conversion",
            index = 0,
            numcasts = 1,
            -- Primitive fields for serialization & hydration
            name = virtualRecipe.name,
            link = virtualRecipe.link,
            conversionType = conversionType,
            sourceId = sourceId,
            outputId = outputId,
            toolItemId = toolItemId,
            sourceNeeded = sourceNeeded,
            outputAmount = queueOutputAmount,
            -- Backward compat fields
            crystallizedId = virtualRecipe.crystallizedId,
            eternalId = virtualRecipe.eternalId,
            crystallizedNeeded = virtualRecipe.crystallizedNeeded,
            eternalsToMake = virtualRecipe.eternalsToMake,
            -- Runtime object (does not serialize)
            recipe = virtualRecipe
        })

        local action = conversionType == "combine" and "Combine" or "Split"
        self:Print(string.format("|cFFFFAA00Auto-queued: %s %s (x%d) -> %s (x%d)|r",
            action, convertibleName, sourceNeeded, neededName, queueOutputAmount))

        -- Synastria: CRITICAL - Save queue to database so conversions persist through reloads
        self:SaveQueue(self.db.server.queues, self.currentTrade)

        -- Clear craftability cache since we added a conversion
        lib:ClearCraftabilityCache()
        return true
    end

    return false
end

-- Synastria: Withdraw items from Resource Bank by item ID
-- @param itemId: Numeric item ID to withdraw (e.g., 22445 for Crystallized Shadow)
-- @param autoClose: If true, closes Resource Bank after withdrawal (default: true)
-- @return success: true if item was withdrawn, false otherwise
function Skillet:WithdrawFromResourceBank(itemId, autoClose)
    if autoClose == nil then autoClose = true end

    if not itemId or type(itemId) ~= "number" then
        self:Print("WithdrawFromResourceBank: Invalid item ID")
        return false
    end

    -- Open the Resource Bank
    if not OpenResourceSummary then
        self:Print("OpenResourceSummary function not available")
        if autoClose then self:CloseResourceBank() end
        return false
    end

    OpenResourceSummary()

    -- Check if Resource Bank opened
    local rbankFrame = _G["RBankFrame"]
    if not rbankFrame or not rbankFrame:IsShown() then
        self:Print("Failed to open Resource Bank")
        if autoClose then self:CloseResourceBank() end
        return false
    end

    -- Use the direct ItemId approach - set the ItemId on any ILine and click it
    local iline = _G["RBankFrame-ILine-1"]
    if not iline then
        self:Print("Failed to find ILine element")
        if autoClose then self:CloseResourceBank() end
        return false
    end

    -- Set the ItemId property and click the line
    iline.ItemId = itemId
    iline:Click()

    -- Click the Withdraw button
    local withdrawBtn = _G["RBankFrame-Withdraw"]
    if withdrawBtn and withdrawBtn.Click then
        withdrawBtn:Click()
        if autoClose then self:CloseResourceBank() end
        return true
    else
        self:Print("Failed to find or click Withdraw button")
        if autoClose then self:CloseResourceBank() end
        return false
    end
end

-- Synastria: Withdraw multiple items from Resource Bank in sequence
-- @param itemIds: Table of item IDs to withdraw (e.g., {22445, 37701})
-- @return withdrawn, failed: counts of successfully withdrawn and failed items
function Skillet:WithdrawMultipleFromResourceBank(itemIds)
    if not itemIds or type(itemIds) ~= "table" or #itemIds == 0 then
        self:Print("WithdrawMultipleFromResourceBank: No item IDs provided")
        return 0, 0
    end

    local withdrawn = 0
    local failed = 0

    for i, itemId in ipairs(itemIds) do
        local success = self:WithdrawFromResourceBank(itemId, false) -- Don't auto-close
        if success then
            withdrawn = withdrawn + 1
        else
            failed = failed + 1
        end
    end

    -- Close the Resource Bank after all withdrawals
    self:CloseResourceBank()

    -- Report results
    if withdrawn > 0 then
        self:Print(string.format("Withdrew %d item(s) from Resource Bank", withdrawn))
    end
    if failed > 0 then
        self:Print(string.format("Failed to withdraw %d item(s)", failed))
    end

    return withdrawn, failed
end

-- Synastria: Close the Resource Bank window
function Skillet:CloseResourceBank()
    local closeBtn = _G["RBankFrame-Close"]
    if closeBtn and closeBtn.Click then
        closeBtn:Click()
    end
end

-- Synastria: Deposit items to Resource Bank
-- @param itemIds: (optional) Single itemId or table of itemIds to deposit. If nil, deposits all items.
-- @param autoClose: If true, closes Resource Bank after deposit (default: true)
-- @return success: true if deposit was successful, false otherwise
function Skillet:DepositToResourceBank(itemIds, autoClose)
    -- Handle legacy call: DepositToResourceBank(autoClose)
    if type(itemIds) == "boolean" then
        autoClose = itemIds
        itemIds = nil
    end

    if autoClose == nil then autoClose = true end

    -- Open the Resource Bank
    if not OpenResourceSummary then
        self:Print("OpenResourceSummary function not available")
        return false
    end

    OpenResourceSummary()

    -- Check if Resource Bank opened
    local rbankFrame = _G["RBankFrame"]
    if not rbankFrame or not rbankFrame:IsShown() then
        self:Print("Failed to open Resource Bank")
        if autoClose then self:CloseResourceBank() end
        return false
    end

    -- If no specific items provided, deposit all
    if not itemIds then
        local depositBtn = _G["RBankFrame-DepositAll"]
        if depositBtn and depositBtn.Click then
            depositBtn:Click()
            self:Print("Deposited all items to Resource Bank")
            if autoClose then self:CloseResourceBank() end
            return true
        else
            self:Print("Failed to find or click DepositAll button")
            if autoClose then self:CloseResourceBank() end
            return false
        end
    end

    -- Deposit specific items
    -- Convert single itemId to table
    if type(itemIds) == "number" then
        itemIds = { itemIds }
    end

    if type(itemIds) ~= "table" or #itemIds == 0 then
        self:Print("DepositToResourceBank: Invalid item IDs")
        if autoClose then self:CloseResourceBank() end
        return false
    end

    local iline = _G["RBankFrame-ILine-1"]
    if not iline then
        self:Print("Failed to find ILine element")
        if autoClose then self:CloseResourceBank() end
        return false
    end

    local depositBtn = _G["RBankFrame-Deposit"]
    if not depositBtn or not depositBtn.Click then
        self:Print("Failed to find Deposit button")
        if autoClose then self:CloseResourceBank() end
        return false
    end

    -- Deposit each item
    local deposited = 0
    for _, itemId in ipairs(itemIds) do
        -- Check if we have any of this item in bags
        local count = GetItemCount(itemId, false)
        if count and count > 0 then
            iline.ItemId = itemId
            iline:Click()
            depositBtn:Click()
            deposited = deposited + 1
        end
    end

    if deposited > 0 then
        local itemName = GetItemInfo(itemIds[1]) or "items"
        if deposited == 1 and #itemIds == 1 then
            self:Print("Deposited " .. itemName .. " to Resource Bank")
        else
            self:Print("Deposited " .. deposited .. " item type(s) to Resource Bank")
        end
    end

    if autoClose then self:CloseResourceBank() end
    return deposited > 0
end

-- Synastria: Trigger withdrawal for conversion (called by button click)
---@param crystallizedId number The crystallized item ID to convert
---@param eternalsNeeded number How many eternals are needed
---@return boolean success True if withdrawal succeeded
function Skillet:ConversionWithdraw(crystallizedId, eternalsNeeded)
    -- Calculate how many crystallized we need (10 per eternal)
    local crystallizedNeeded = eternalsNeeded * 10

    -- Check how many we have in bags vs resource bank
    local bagsCount = GetItemCount(crystallizedId, false) or 0
    local bankCount = 0
    if GetCustomGameData then
        bankCount = GetCustomGameData(13, crystallizedId) or 0
    end

    local crystallizedName = GetItemInfo(crystallizedId) or "Crystallized item"

    -- Only withdraw if we need more
    if bagsCount >= crystallizedNeeded then
        self:Print("|cFF00FF00Already have enough " .. crystallizedName .. " in bags|r")
        return true
    end

    local neededFromBank = crystallizedNeeded - bagsCount

    if bankCount < neededFromBank then
        self:Print("|cFFFF6666Not enough " ..
            crystallizedName .. " in Resource Bank (" .. bankCount .. "/" .. neededFromBank .. " needed)|r")
        return false
    end

    -- Withdraw from resource bank
    self:Print("|cFF66AAFFWithdrawing " .. neededFromBank .. "x " .. crystallizedName .. " from Resource Bank...|r")
    if self:WithdrawFromResourceBank(crystallizedId, true) then
        self:Print("|cFF00FF00Items withdrawn! Right-click them in bags to combine.|r")
        return true
    else
        self:Print("|cFFFF0000Failed to withdraw from Resource Bank|r")
        return false
    end
end

-- Synastria: Deposit extras and continue queue (called by button click after user combines items)
---@param crystallizedId number The crystallized item ID
function Skillet:ConversionDepositAndContinue(crystallizedId)
    -- Deposit any remaining crystallized items back to resource bank
    if GetItemCount(crystallizedId, false) > 0 then
        self:Print("|cFF66AAFFDepositing remaining items to Resource Bank...|r")
        self:DepositToResourceBank(crystallizedId, true)
    end

    -- Conversion complete - remove from queue and continue
    self:Print("|cFF00FF00Conversion complete!|r")
    self.stitch:RemoveFromQueue(1)

    -- Hide the conversion dialog
    if self.conversionDialog then
        self.conversionDialog:Hide()
    end

    if #self.stitch.queue > 0 then
        self.stitch:ProcessQueue()
    else
        AceLibrary("AceEvent-2.0"):TriggerEvent("SkilletStitch_Queue_Complete")
    end
end

-- Synastria: Process conversion with automated withdraw/use/deposit
---@param virtualRecipe Recipe The conversion recipe data
function Skillet:ProcessConversion(virtualRecipe)
    if not virtualRecipe or not virtualRecipe.sourceId or not virtualRecipe.outputId then
        self:Print("|cFFFF0000Invalid conversion recipe|r")
        return
    end

    local sourceId = virtualRecipe.sourceId
    local outputId = virtualRecipe.outputId
    local sourceNeeded = virtualRecipe.sourceNeeded or 0
    local conversionType = virtualRecipe.conversionType or "combine"

    local sourceName = GetItemInfo(sourceId) or ("Item#" .. sourceId)
    local outputName = GetItemInfo(outputId) or ("Item#" .. outputId)

    -- Step 1: Withdraw source items from Resource Bank
    local bagsCount = GetItemCount(sourceId, false) or 0
    local bankCount = 0
    if GetCustomGameData then
        bankCount = GetCustomGameData(13, sourceId) or 0
    end

    if bagsCount < sourceNeeded then
        local needFromBank = sourceNeeded - bagsCount
        if bankCount >= needFromBank then
            self:Print("|cFF66AAFFWithdrawing " .. needFromBank .. "x " .. sourceName .. " from Resource Bank...|r")
            self:WithdrawFromResourceBank(sourceId, true)

            -- Wait a moment for withdrawal to complete, then use item
            self:ScheduleEvent("Skillet_ConversionUseItem", function()
                self:UseConversionItem(sourceId, outputId, conversionType, virtualRecipe)
            end, 0.5)
        else
            self:Print("|cFFFF6666Not enough " ..
                sourceName .. " in Resource Bank (" .. bankCount .. "/" .. needFromBank .. " needed)|r")
        end
    else
        -- Already have enough in bags - use directly
        self:UseConversionItem(sourceId, outputId, conversionType, virtualRecipe)
    end
end

-- Synastria: Use item to trigger conversion, then deposit
---@param sourceId number Source item ID
---@param outputId number Output item ID
---@param conversionType string "combine" or "split"
---@param virtualRecipe Recipe The conversion recipe data
function Skillet:UseConversionItem(sourceId, outputId, conversionType, virtualRecipe)
    local sourceName = GetItemInfo(sourceId) or ("Item#" .. sourceId)
    local outputName = GetItemInfo(outputId) or ("Item#" .. outputId)

    -- Determine which item to use (tool or source)
    local toolItemId = virtualRecipe.toolItemId or sourceId -- Default to source for backward compatibility
    local toolName = GetItemInfo(toolItemId) or ("Item#" .. toolItemId)

    -- Step 2: Use the tool item (triggers combine/split)
    self:Print("|cFF66AAFFConverting " .. sourceName .. " to " .. outputName .. "...|r")

    if toolItemId ~= sourceId then
        -- Using a tool (e.g., Salt Shaker for Deeprock Salt)
        self:Print("|cFF66AAFFUsing " .. toolName .. " to convert...|r")
    end

    UseItemByName(toolName)

    -- Step 3: Schedule deposit and queue continuation
    self:ScheduleEvent("Skillet_ConversionDeposit", function()
        -- Deposit both source and output items to clean up
        local sourceCount = GetItemCount(sourceId, false) or 0
        local outputCount = GetItemCount(outputId, false) or 0

        if sourceCount > 0 then
            self:Print("|cFF66AAFFDepositing " .. sourceCount .. "x " .. sourceName .. " to Resource Bank...|r")
            self:DepositToResourceBank(sourceId, true)
        end

        if outputCount > 0 then
            self:Print("|cFF66AAFFDepositing " .. outputCount .. "x " .. outputName .. " to Resource Bank...|r")
            self:DepositToResourceBank(outputId, true)
        end

        -- Remove conversion from queue and continue
        self:Print("|cFF00FF00Conversion complete!|r")
        self.stitch:RemoveFromQueue(1)

        if #self.stitch.queue > 0 then
            self.stitch:ProcessQueue()
        else
            AceLibrary("AceEvent-2.0"):TriggerEvent("SkilletStitch_Queue_Complete")
        end
    end, 1.5) -- Wait for conversion animation to complete
end

-- Synastria: Test Resource Bank withdrawal
function Skillet:TestResourceBank()
    -- Test withdrawing all crystallized elements by item ID
    local crystallizedElements = {
        37700, -- Crystallized Air
        37701, -- Crystallized Earth
        37702, -- Crystallized Fire
        37704, -- Crystallized Life
        37703, -- Crystallized Shadow
        37705  -- Crystallized Water
    }

    self:WithdrawMultipleFromResourceBank(crystallizedElements)
end

-- Synastria: Test attunement checking on cursor/mouseover item
function Skillet:TestAttunement()
    -- Try to get item from cursor first
    local cursorType, itemId, itemLink = GetCursorInfo()

    if cursorType == "item" then
        self:Print("Testing cursor item: " .. (itemLink or "unknown"))
        local isAttuned = self:IsItemAttuned(itemLink)
        local progress = self:GetItemAttunementProgress(itemLink)

        self:Print("IsAttuned: " .. tostring(isAttuned))
        self:Print("Progress: " .. tostring(progress))

        -- Also test the raw APIs
        if GetItemAttuneProgress then
            local rawProgress = GetItemAttuneProgress(itemLink)
            self:Print("GetItemAttuneProgress: " .. tostring(rawProgress))
        end

        if HasAttunedAnyVariant then
            local hasAttuned = HasAttunedAnyVariant(itemLink)
            self:Print("HasAttunedAnyVariant: " .. tostring(hasAttuned))
        end
        return
    end

    -- Try mouseover tooltip
    local name, link = GameTooltip:GetItem()
    if link then
        self:Print("Testing tooltip item: " .. link)
        local isAttuned = self:IsItemAttuned(link)
        local progress = self:GetItemAttunementProgress(link)

        self:Print("IsAttuned: " .. tostring(isAttuned))
        self:Print("Progress: " .. tostring(progress))

        -- Also test the raw APIs
        if GetItemAttuneProgress then
            local rawProgress = GetItemAttuneProgress(link)
            self:Print("GetItemAttuneProgress: " .. tostring(rawProgress))
        end

        if HasAttunedAnyVariant then
            local hasAttuned = HasAttunedAnyVariant(link)
            self:Print("HasAttunedAnyVariant: " .. tostring(hasAttuned))
        end
        return
    end

    self:Print("No item found. Pick up an item or hover over one, then run /skillet testattune")
end

-- Synastria: Test Crystallized/Eternal conversion system
function Skillet:TestConversions()
    self:Print("=== Testing Crystallized <-> Eternal Conversions ===")

    -- Helper to get resource bank count
    local function GetRBankCount(itemId)
        if not GetCustomGameData then return 0 end
        return GetCustomGameData(13, itemId) or 0
    end

    -- Test item pairs
    local testPairs = {
        { cryst = 37700, eternal = 35622, name = "Air" },
        { cryst = 37701, eternal = 35624, name = "Earth" },
        { cryst = 37702, eternal = 36860, name = "Fire" },
        { cryst = 37704, eternal = 35625, name = "Life" },
        { cryst = 37703, eternal = 35627, name = "Shadow" },
        { cryst = 37705, eternal = 35623, name = "Water" },
    }

    for _, pair in ipairs(testPairs) do
        -- Get actual counts from bags/bank
        local crystCount = GetItemCount(pair.cryst, true) or 0
        local eternalCount = GetItemCount(pair.eternal, true) or 0

        -- Get counts from Resource Bank
        local crystRBank = GetRBankCount(pair.cryst)
        local eternalRBank = GetRBankCount(pair.eternal)

        self:Print(string.format("|cFF00FF00%s:|r Cryst: %d+%d(rb), Eternal: %d+%d(rb)",
            pair.name, crystCount, crystRBank, eternalCount, eternalRBank))

        -- Calculate how many Eternals we can effectively have (with conversions)
        local effectiveEternals = eternalCount + eternalRBank + math.floor((crystCount + crystRBank) / 10)

        -- Calculate how many Crystallized we can effectively have (with conversions)
        local effectiveCryst = crystCount + crystRBank + ((eternalCount + eternalRBank) * 10)

        self:Print(string.format("  Effective: %d Eternal, %d Crystallized", effectiveEternals, effectiveCryst))
    end

    self:Print("=== Conversion Test Complete ===")
end

-- Triggers a rescan of the currently selected tradeskill
function Skillet:RescanTrade(forced)
    scan_in_progress = true
    local trade = self:GetTradeSkillLine()
    if trade and trade ~= "UNKNOWN" and is_known_trade_skill(trade) and not IsTradeSkillLinked() then
        if forced then
            forced_rescan = true
        end

        if forced_rescan and not need_rescan_on_open then
            -- only print this for first time and forced rescans
            -- not when a bag is changed
            self:Print(GetLocalizedString("Scanning tradeskill") .. ": " .. trade);
        end

        self:UpdateScanningText(GetLocalizedString("Scanning tradeskill") .. " ...")

        Skillet.stitch:ScanTrade()
    else
        scan_in_progress = false
    end
end

-- Synastria: Scans all character professions
function Skillet:ScanAllProfessions()
    -- Build list of professions using same spell ID detection as ProfessionSelector
    local professionsToScan = {}
    local professionSpellIds = {
        { 53428 },                                    -- Runeforging
        { 51304, 28596, 11611, 3464,  3101,  2259 },  -- Alchemy
        { 51300, 29844, 9785,  3538,  3100,  2018 },  -- Blacksmithing
        { 51313, 28029, 13920, 7413,  7412,  7411 },  -- Enchanting
        { 51306, 30350, 12656, 4038,  4037,  4036 },  -- Engineering
        { 45363, 45361, 45360, 45359, 45358, 45357 }, -- Inscription
        { 51311, 28897, 28895, 28894, 25230, 25229 }, -- Jewelcrafting
        { 51302, 32549, 10662, 3811,  3104,  2108 },  -- Leatherworking
        { 51309, 26790, 12180, 3910,  3909,  3908 },  -- Tailoring
        { 51296, 33359, 18260, 3413,  3102,  2550 },  -- Cooking
        { 45542, 27028, 10846, 7924,  3274,  3273 }   -- First Aid
    }

    -- Check which professions the player knows
    for _, spellIdCollection in ipairs(professionSpellIds) do
        local spellId = nil
        -- Check which spell rank the player knows
        for _, checkSpellId in ipairs(spellIdCollection) do
            if IsSpellKnown(checkSpellId) then
                spellId = checkSpellId
                break
            end
        end

        if spellId then
            local name = GetSpellInfo(spellId)
            if name and name ~= "Smelting" then -- Skip smelting, it's part of Mining
                table.insert(professionsToScan, name)
            end
        end
    end

    if #professionsToScan == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000No professions found to scan|r")
        return
    end

    -- Store current profession to return to after scanning
    local currentTrade = self:GetTradeSkillLine()

    -- Show the rescan dialog with all professions
    self:ShowRecipePrompt(professionsToScan, currentTrade)
end

-- Synastria: Check for old encoded recipe data and show rescan dialog
function Skillet:CheckForOldRecipeData()
    ---@type string|nil
    local player = UnitName("player")
    local needsRescan = {}

    if player and self.db.server.recipes[player] then
        for profession, _ in pairs(self.db.server.recipes[player]) do
            if profession ~= "UNKNOWN" then
                -- Check for Mining/Smelting mapping
                local checkProf = profession
                if profession == "Mining" then
                    checkProf = "Smelting"
                end

                if self.stitch.data[checkProf] then
                    -- Check if any recipe is still in old encoded string format
                    for index, data in pairs(self.stitch.data[checkProf]) do
                        if type(data) == "string" then
                            table.insert(needsRescan, profession)
                            break
                        end
                    end
                end
            end
        end
    end

    -- Synastria: Set flag instead of showing dialog immediately
    if #needsRescan > 0 then
        self.needsRecipeScan = needsRescan
        DEFAULT_CHAT_FRAME:AddMessage("|" ..
            "|cFFFFAA00[Skillet] Recipe data needs updating. Will prompt when you open a profession.|r")
    else
        self.needsRecipeScan = nil
    end
end

-- Synastria: Custom dialog frame classes
---@class SkilletRecipePromptDialog : Frame
---@field title FontString
---@field text FontString
---@field openButton Frame  -- Button type, but CreateFrame returns Frame
---@field okButton Frame  -- Button type, but CreateFrame returns Frame
---@field professionSpellIds table<string, number>
---@field professions string[]
---@field professionIndex number|nil
---@field scannedProfessions table|nil

---@class SkilletStartCraftingPrompt : Frame
---@field title FontString
---@field text FontString
---@field itemText FontString
---@field errorText FontString
---@field startButton Frame  -- Button type, but CreateFrame returns Frame
---@field switchButton Frame  -- Button type, but CreateFrame returns Frame
---@field useItemButton Frame  -- Button type, but CreateFrame returns Frame
---@field cancelButton Frame  -- Button type, but CreateFrame returns Frame
---@field conversionStep number|nil
---@field totalCombinesNeeded number|nil
---@field combinesCompleted number|nil

---@class SkilletConversionDialog : Frame
---@field title FontString
---@field text FontString
---@field step1 FontString
---@field step2 FontString
---@field step3 FontString
---@field withdrawButton Frame  -- Button type, but CreateFrame returns Frame
---@field depositButton Frame  -- Button type, but CreateFrame returns Frame
---@field doneButton Frame  -- Button type, but CreateFrame returns Frame
---@field crystallizedId number|nil

-- Synastria: Show dialog for professions needing rescan
function Skillet:ShowRecipePrompt(professionList, originalProfession)
    if not self.recipePromptDialog then
        ---@type SkilletRecipePromptDialog
        ---@diagnostic disable-next-line: assign-type-mismatch
        local dialog = CreateFrame("Frame", "SkilletRecipePromptDialog", UIParent)
        dialog:SetSize(360, 280)
        dialog:SetPoint("CENTER")
        dialog:SetFrameStrata("DIALOG")
        dialog:EnableMouse(true)
        dialog:SetMovable(true)
        dialog:RegisterForDrag("LeftButton")
        dialog:SetClampedToScreen(true)
        dialog:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
        dialog:SetBackdropColor(0, 0, 0, 0.9)

        dialog.title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        dialog.title:SetPoint("TOP", 0, -15)
        dialog.title:SetText("Recipe Data Update Needed")

        dialog.text = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        dialog.text:SetPoint("TOP", dialog.title, "BOTTOM", 0, -15)
        dialog.text:SetWidth(320)
        dialog.text:SetJustifyH("LEFT")

        -- Open Next button (SecureActionButtonTemplate)
        dialog.openButton = CreateFrame("Button", "SkilletRecipePromptOpenButton", dialog,
            "SecureActionButtonTemplate, UIPanelButtonTemplate")
        dialog.openButton:SetSize(110, 22)
        dialog.openButton:SetPoint("BOTTOM", -50, 15)
        dialog.openButton:SetText("Open Next")
        dialog.openButton:SetAttribute("type", "spell")
        dialog.openButton:RegisterForClicks("AnyUp")
        dialog.openButton:SetScript("PostClick", function()
            -- Check if this is the return button click
            if dialog.returningToOriginal then
                Skillet:DebugLog("[ScanDialog] Return button clicked, closing dialog", "|cFF00FF00")
                C_Timer.After(0.5, function()
                    dialog:Hide()
                    dialog.professionIndex = nil
                    dialog.scannedProfessions = nil
                    dialog.originalProfession = nil
                    dialog.returningToOriginal = nil
                end)
                return
            end

            -- Disable button immediately to prevent double-clicks
            dialog.openButton:Disable()

            -- Give the profession window time to open
            C_Timer.After(0.5, function()
                if dialog.professionIndex then
                    -- Mark current profession as scanned in the display
                    dialog.scannedProfessions = dialog.scannedProfessions or {}
                    local currentProf = dialog.professions[dialog.professionIndex]
                    dialog.scannedProfessions[currentProf] = true

                    Skillet:DebugLog(
                        "[ScanDialog] PostClick: Marking '" ..
                        currentProf .. "' [" .. dialog.professionIndex .. "] as [OK]",
                        "|cFF00FF00")

                    -- Move to next profession first
                    dialog.professionIndex = dialog.professionIndex + 1
                    local nextProf = dialog.professions[dialog.professionIndex]

                    -- Update the profession list display
                    Skillet:DebugLog(
                        "[ScanDialog] PostClick: Moving to '" ..
                        (nextProf or "DONE") .. "' [" .. dialog.professionIndex .. "]", "|cFF00FFFF")
                    local promptText = "The following professions need to be rescanned:\n\n"
                    for i, prof in ipairs(dialog.professions) do
                        if i < dialog.professionIndex then
                            -- Already scanned - show in green with checkmark
                            promptText = promptText .. "|cFF00FF00  [OK] " .. prof .. "|r\n"
                        elseif i == dialog.professionIndex then
                            -- Currently being scanned - show in yellow
                            promptText = promptText .. "|cFFFFFF00  -> " .. prof .. " (scanning...)|r\n"
                        else
                            -- Not yet scanned - show in gray
                            promptText = promptText .. "|cFF808080    " .. prof .. "|r\n"
                        end
                    end
                    promptText = promptText .. "\nOpen each profession window to update the data."
                    dialog.text:SetText(promptText)

                    -- professionIndex already incremented above
                    if dialog.professionIndex <= #dialog.professions then
                        local nextProf = dialog.professions[dialog.professionIndex]
                        local spellId = dialog.professionSpellIds[nextProf]

                        if spellId then
                            dialog.openButton:SetAttribute("spell", spellId)
                            dialog.openButton:SetText("Open " .. nextProf)
                            -- Don't enable here - let calculation callback enable it when scan completes
                            Skillet:DebugLog(
                                "[ScanDialog] PostClick: Button configured for '" ..
                                nextProf .. "', waiting for calculation to complete", "|cFF888888")
                        else
                            dialog.openButton:SetText("Not Learned")
                            dialog.openButton:Disable()
                        end
                    else
                        -- All professions scanned
                        dialog.openButton:SetText("Done")
                        dialog.openButton:Disable()
                        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00All professions opened! Recipe data updated.|r")

                        -- Prompt to return to original profession if set
                        if dialog.originalProfession and dialog.originalProfession ~= "UNKNOWN" then
                            ---@type number|nil
                            local spellId = dialog.professionSpellIds[dialog.originalProfession]
                            if not spellId then
                                spellId = Skillet.stitch:FindProfessionSpellId(dialog.originalProfession) --[[@as number|nil]]
                            end

                            if spellId and IsSpellKnown(spellId) then
                                dialog.openButton:SetAttribute("spell", spellId)
                                dialog.openButton:SetText("Return to " .. dialog.originalProfession)
                                dialog.returningToOriginal = true
                                dialog.openButton:Enable()
                                dialog.professionIndex = nil -- Prevent further progression
                            end
                        end
                    end
                end
            end)
        end)

        dialog.okButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
        dialog.okButton:SetSize(80, 22)
        dialog.okButton:SetPoint("BOTTOM", 50, 15)
        dialog.okButton:SetText("Cancel")
        dialog.okButton:SetScript("OnClick", function()
            dialog:Hide()
            dialog.professionIndex = nil
            dialog.scannedProfessions = nil
            dialog.returningToOriginal = nil
            dialog.originalProfession = nil
        end)

        dialog:SetScript("OnDragStart", dialog.StartMoving)
        dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)
        dialog:Hide()

        -- Enable escape key to close the dialog
        table.insert(UISpecialFrames, "SkilletRecipePromptDialog")

        self.recipePromptDialog = dialog
    end

    local dialog = self.recipePromptDialog
    if not dialog then
        return
    end

    -- Set up profession spell IDs
    dialog.professionSpellIds = {
        ["Alchemy"] = 51304,
        ["Blacksmithing"] = 51300,
        ["Enchanting"] = 51313,
        ["Engineering"] = 51306,
        ["Inscription"] = 45363,
        ["Jewelcrafting"] = 51311,
        ["Leatherworking"] = 51302,
        ["Tailoring"] = 51309,
        ["Cooking"] = 51296,
        ["First Aid"] = 45542,
        ["Mining"] = 2656,
    }

    dialog.professions = professionList
    dialog.professionIndex = 1
    dialog.scannedProfessions = {}
    dialog.originalProfession = originalProfession

    -- Build initial text with proper formatting
    local promptText = "The following professions need to be rescanned:\n\n"
    for i, prof in ipairs(professionList) do
        if i == 1 then
            -- First profession - ready to open (no color or slight emphasis)
            promptText = promptText .. "    " .. prof .. "\n"
        else
            -- Not yet scanned - show in gray
            promptText = promptText .. "|cFF808080    " .. prof .. "|r\n"
        end
    end
    promptText = promptText .. "\nOpen each profession window to update the data."

    dialog.text:SetText(promptText)

    -- Set up the first profession to open
    if #professionList > 0 then
        local firstProf = professionList[1]
        ---@type number|nil
        local spellId = dialog.professionSpellIds[firstProf]

        -- Try to find the spell ID if not in our basic list
        if not spellId then
            spellId = self.stitch:FindProfessionSpellId(firstProf) --[[@as number|nil]]
        end

        if spellId and IsSpellKnown(spellId) then
            dialog.openButton:SetAttribute("spell", spellId)
            dialog.openButton:SetText("Open " .. firstProf)
            dialog.openButton:Enable()
        else
            dialog.openButton:SetText("Not Learned")
            dialog.openButton:Disable()
        end
    end

    dialog:Show()
end

-- Synastria: Show profession switch prompt button
-- DEPRECATED: Now handled by ShowStartCraftingPrompt with switchButton
function Skillet:ShowProfessionSwitchPrompt(professionName, spellId, actionType)
    -- Redirect to unified dialog instead of showing separate prompt
    if actionType == "queue" then
        self:ShowStartCraftingPrompt()
    end
    -- Note: "scan" action type is not handled here anymore
end

-- Synastria: Called after user clicks the profession switch button
function Skillet:OnProfessionSwitchComplete()
    if not self.professionSwitchPrompt or not self.professionSwitchPrompt:IsVisible() then
        return
    end

    -- Synastria: Clear the keybindings
    SetBinding("CTRL-MOUSEWHEELUP")
    SetBinding("CTRL-MOUSEWHEELDOWN")

    ---@type string|nil
    local actionType = (self.professionSwitchPrompt --[[@as table]]).actionType --[[@as string|nil]]
    self.professionSwitchPrompt:Hide()

    if actionType == "queue" then
        -- Show start crafting prompt instead of auto-starting
        self:ScheduleEvent("Skillet_ShowCraftPrompt", function()
            self:ShowStartCraftingPrompt()
        end, 0.5)
    end
end

-- Synastria: Show prompt to start crafting with cancel option
function Skillet:ShowStartCraftingPrompt()
    if not self.stitch.queue or not self.stitch.queue[1] then
        return
    end

    -- Create the prompt frame if it doesn't exist
    if not self.startCraftingPrompt then
        ---@type SkilletStartCraftingPrompt
        ---@diagnostic disable-next-line: assign-type-mismatch
        local frame = CreateFrame("Frame", "SkilletStartCraftingPrompt", UIParent)
        frame:SetWidth(350)
        frame:SetHeight(140)
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
        frame:SetBackdropColor(0, 0, 0, 1)
        frame:SetFrameStrata("DIALOG")
        frame:EnableMouse(true)
        frame:SetMovable(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

        -- Title text
        local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", frame, "TOP", 0, -18)
        title:SetText("Ready to Craft")
        frame.title = title

        -- Instruction text
        local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        text:SetPoint("TOP", title, "BOTTOM", 0, -10)
        text:SetWidth(300)
        text:SetJustifyH("CENTER")
        frame.text = text

        -- Item info text
        local itemText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        itemText:SetPoint("TOP", text, "BOTTOM", 0, -8)
        itemText:SetWidth(300)
        itemText:SetJustifyH("CENTER")
        frame.itemText = itemText

        -- Synastria: Error message text
        local errorText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        errorText:SetPoint("TOP", itemText, "BOTTOM", 0, -10)
        errorText:SetWidth(310)
        errorText:SetJustifyH("CENTER")
        errorText:SetTextColor(1, 0.3, 0.3) -- Red color
        errorText:SetText("")
        frame.errorText = errorText

        -- Start button
        local startButton = CreateFrame("Button", "SkilletStartCraftingButton", frame, "UIPanelButtonTemplate")
        startButton:SetWidth(100)
        startButton:SetHeight(24)
        startButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOM", -3, 15) -- Right edge at center with 3px gap
        startButton:SetText("Start")
        startButton:SetScript("OnClick", function()
            frame.errorText:SetText("") -- Clear error message
            startButton:Disable()
            Skillet.stitch:ProcessQueue()
        end)
        frame.startButton = startButton

        -- Synastria: Profession switch button (SecureActionButtonTemplate)
        local switchButton = CreateFrame("Button", "SkilletSwitchProfessionButton", frame,
            "SecureActionButtonTemplate, UIPanelButtonTemplate")
        switchButton:SetWidth(140)
        switchButton:SetHeight(24)
        switchButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOM", -3, 15) -- Right edge at center with 3px gap
        switchButton:SetAttribute("type", "spell")
        switchButton:RegisterForClicks("AnyUp")
        switchButton:SetText("Switch Profession")
        switchButton:Hide()
        frame.switchButton = switchButton

        -- Synastria: Secure button for item usage (Combine step in conversions)
        local useItemButton = CreateFrame("Button", "SkilletUseItemButton", frame,
            "SecureActionButtonTemplate, UIPanelButtonTemplate")
        useItemButton:SetWidth(100)
        useItemButton:SetHeight(24)
        useItemButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOM", -3, 15) -- Same position as start button
        useItemButton:SetAttribute("type", "item")
        useItemButton:RegisterForClicks("AnyUp")
        useItemButton:SetText("Combine")
        useItemButton:Hide()

        -- PostClick handler for use item button to advance conversion step
        useItemButton:SetScript("PostClick", function()
            if frame.conversionStep == 2 then
                frame.combinesCompleted = (frame.combinesCompleted or 0) + 1

                -- Check if we need more combines
                if frame.combinesCompleted >= frame.totalCombinesNeeded then
                    -- All combines done, move to deposit
                    Skillet:Print(string.format("|cFF00FF00Combined %d times - completed!|r", frame.combinesCompleted))
                    frame.conversionStep = 3
                    Skillet:ShowStartCraftingPrompt() -- Refresh dialog to update button
                else
                    -- More combines needed, stay on step 2 and refresh to update counter
                    Skillet:Print(string.format("|cFF00FF00Combined %d/%d times...|r", frame.combinesCompleted,
                        frame.totalCombinesNeeded))
                    Skillet:ShowStartCraftingPrompt() -- Refresh to update counter
                end
            end
        end)
        frame.useItemButton = useItemButton

        -- Cancel button
        local cancelButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        cancelButton:SetWidth(100)
        cancelButton:SetHeight(24)
        cancelButton:SetPoint("BOTTOMLEFT", frame, "BOTTOM", 3, 15) -- Left edge at center with 3px gap
        cancelButton:SetText("Cancel")
        cancelButton:SetScript("OnClick", function()
            -- Synastria: Clear keybindings
            SetBinding("CTRL-MOUSEWHEELUP")
            SetBinding("CTRL-MOUSEWHEELDOWN")
            frame:Hide()
            startButton:Enable() -- Re-enable if user re-opens
            Skillet.stitch.waitingForProfessionSwitch = false
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00Crafting cancelled - queue preserved|r")
        end)
        frame.cancelButton = cancelButton

        frame:Hide()
        self.startCraftingPrompt = frame
    end

    -- Update the prompt with current queue info
    local frame = self.startCraftingPrompt
    if not frame then
        return
    end
    local queueItem = self.stitch.queue[1]

    if queueItem and queueItem.spellId then
        -- Synastria: Get recipe info from spell ID
        local spellId = queueItem.spellId
        ---@type number
        local count = (queueItem.numcasts or 1) --[[@as number]]
        local currentTrade = GetTradeSkillLine()

        -- Get recipe details from Custom API
        local recipeName = "Unknown Item"
        local profession = "Unknown"
        if Custom_GetProfessionRecipeInfo then
            local skillId, name, itemId, craftCount, canCraft, verb, header, difficulty = Custom_GetProfessionRecipeInfo(
                spellId)
            if name then
                recipeName = name
            end
            -- Synastria: Try to determine profession from skill ID or header
            -- For now, we'll use currentTrade or "Unknown"
            if currentTrade and currentTrade ~= "" then
                profession = currentTrade
            end
        end

        -- Synastria: Virtual conversions no longer supported with new queue structure
        -- Regular crafting workflow only
        frame.conversionStep = 1
        frame.useItemButton:Hide()

        -- Restore normal start button click handler
        frame.startButton:SetScript("OnClick", function()
            frame.errorText:SetText("") -- Clear error message
            frame.startButton:Disable()
            Skillet.stitch:ProcessQueue()
        end)
        frame.startButton:SetText("Start")

        -- Synastria: Check if we can use windowless crafting
        local canUseWindowlessCrafting = false
        if self.customApiAvailable and spellId then
            canUseWindowlessCrafting = true
            if self:IsDevMode() then
                DEFAULT_CHAT_FRAME:AddMessage(
                    "|cFF00FF00[ShowStartCraftingPrompt] Windowless crafting available - spell ID: " ..
                    tostring(spellId) .. "|r")
            end
        else
            if self:IsDevMode() then
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[ShowStartCraftingPrompt] Windowless check: API=" ..
                    tostring(self.customApiAvailable) .. ", spellId=" .. tostring(spellId) .. "|r")
            end
        end

        if self:IsDevMode() then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF00FF[ShowStartCraftingPrompt] canUseWindowlessCrafting=" ..
                tostring(canUseWindowlessCrafting) ..
                ", currentTrade=" .. tostring(currentTrade) .. ", profession=" .. tostring(profession) .. "|r")
        end

        -- Check if we need to switch professions (only if NOT using windowless crafting)
        if not canUseWindowlessCrafting and currentTrade ~= profession then
            -- Need to switch profession
            frame.text:SetText("Switch to " .. profession .. " to craft:")
            frame.itemText:SetText("|cFF00FF00" .. count .. "x " .. recipeName .. "|r")

            -- Show switch button, hide start button
            frame.startButton:Hide()
            frame.switchButton:Show()

            -- Set spell for profession switch
            local professionSpellId = self.stitch:FindProfessionSpellId(profession)
            if professionSpellId then
                frame.switchButton:SetAttribute("spell", professionSpellId)

                -- Synastria: Bind to the switch button
                SetBindingClick("CTRL-MOUSEWHEELUP", "SkilletSwitchProfessionButton")
                SetBindingClick("CTRL-MOUSEWHEELDOWN", "SkilletSwitchProfessionButton")

                -- Flag that we're waiting for profession switch
                self.stitch.waitingForProfessionSwitch = true
                self.stitch.targetProfession = profession
            else
                frame.errorText:SetText("Cannot find spell for " .. profession)
            end
        else
            -- Either same profession OR using windowless crafting - ready to craft!
            if canUseWindowlessCrafting then
                frame.text:SetText("Ready to craft (windowless):")
            else
                frame.text:SetText("Ready to craft in " .. profession .. ":")
            end
            frame.itemText:SetText("|cFF00FF00" .. count .. "x " .. recipeName .. "|r")

            -- Show start button, hide switch button
            frame.switchButton:Hide()
            frame.startButton:Show()

            -- Synastria: Bind to the start button
            SetBindingClick("CTRL-MOUSEWHEELUP", "SkilletStartCraftingButton")
            SetBindingClick("CTRL-MOUSEWHEELDOWN", "SkilletStartCraftingButton")
        end
    else
        frame.text:SetText("Ready to start crafting")
        frame.itemText:SetText("")
        frame.switchButton:Hide()
        frame.startButton:Show()
    end

    -- Synastria: Clear any previous error message
    frame.errorText:SetText("")

    -- Enable start button when showing prompt
    frame.startButton:Enable()

    -- Show the prompt
    frame:Show()
end

-- Synastria: Show dialog for manual item conversion (Crystallized -> Eternal)
---@param virtualRecipe Recipe The conversion recipe with crystallizedId, eternalId, etc.
function Skillet:ShowConversionDialog(virtualRecipe)
    -- Create the dialog if it doesn't exist
    if not self.conversionDialog then
        ---@type SkilletConversionDialog
        ---@diagnostic disable-next-line: assign-type-mismatch
        local frame = CreateFrame("Frame", "SkilletConversionDialog", UIParent)
        frame:SetWidth(400)
        frame:SetHeight(200)
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
        frame:SetBackdropColor(0, 0, 0, 1)
        frame:SetFrameStrata("DIALOG")
        frame:EnableMouse(true)
        frame:SetMovable(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

        -- Title
        local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", frame, "TOP", 0, -18)
        title:SetText("Item Conversion Required")
        frame.title = title

        -- Instructions
        local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        text:SetPoint("TOP", title, "BOTTOM", 0, -15)
        text:SetWidth(360)
        text:SetJustifyH("CENTER")
        frame.text = text

        -- Step 1: Withdraw
        local step1 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        step1:SetPoint("TOP", text, "BOTTOM", 0, -15)
        step1:SetWidth(360)
        step1:SetJustifyH("LEFT")
        step1:SetText("|cFFFFAA001. Click 'Withdraw' to get items from Resource Bank|r")
        frame.step1 = step1

        -- Step 2: Use
        local step2 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        step2:SetPoint("TOP", step1, "BOTTOM", 0, -8)
        step2:SetWidth(360)
        step2:SetJustifyH("LEFT")
        step2:SetText("|cFFFFAA002. Right-click Crystallized items in bags to combine|r")
        frame.step2 = step2

        -- Step 3: Deposit
        local step3 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        step3:SetPoint("TOP", step2, "BOTTOM", 0, -8)
        step3:SetWidth(360)
        step3:SetJustifyH("LEFT")
        step3:SetText("|cFFFFAA003. Click 'Deposit' to return extras to Resource Bank|r")
        frame.step3 = step3

        -- Withdraw button
        local withdrawButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        withdrawButton:SetWidth(120)
        withdrawButton:SetHeight(24)
        withdrawButton:SetPoint("BOTTOM", frame, "BOTTOM", -65, 15)
        withdrawButton:SetText("Withdraw")
        withdrawButton:SetScript("OnClick", function()
            if frame.crystallizedId and frame.eternalsNeeded then
                Skillet:ConversionWithdraw(frame.crystallizedId, frame.eternalsNeeded)
            end
        end)
        frame.withdrawButton = withdrawButton

        -- Deposit & Continue button
        local depositButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        depositButton:SetWidth(120)
        depositButton:SetHeight(24)
        depositButton:SetPoint("BOTTOM", frame, "BOTTOM", 65, 15)
        depositButton:SetText("Deposit & Done")
        depositButton:SetScript("OnClick", function()
            if frame.crystallizedId then
                Skillet:ConversionDepositAndContinue(frame.crystallizedId)
            end
        end)
        frame.depositButton = depositButton

        frame:Hide()
        self.conversionDialog = frame
    end

    -- Update the dialog with conversion details
    local frame = self.conversionDialog

    local crystallizedName = GetItemInfo(virtualRecipe.crystallizedId) or "Crystallized"
    local eternalName = GetItemInfo(virtualRecipe.eternalId) or "Eternal"

    frame.text:SetText(string.format("Convert |cFF00FF00%dx %s|r to |cFF00FF00%dx %s|r",
        virtualRecipe.crystallizedNeeded, crystallizedName,
        virtualRecipe.eternalsToMake, eternalName))

    frame.crystallizedId = virtualRecipe.crystallizedId
    frame.eternalsNeeded = virtualRecipe.eternalsToMake

    -- Show the dialog
    frame:Show()
end

-- Notes when a new trade has been selected
function Skillet:SetSelectedTrade(new_trade)
    self.currentTrade = new_trade;
    self:SetSelectedSkill(nil, false);
    self.headerCollapsedState = {};

    self:UpdateTradeSkillWindow()

    -- Synastria: Don't clear the queue when switching professions
    -- This allows cross-profession queuing
    -- Stop any current casting but keep the queue intact
    self.stitch:CancelCast();
    -- StopCast removed - BAG_UPDATE handles craft completion
end

-- Sets the specific trade skill that the user wants to see details on.
function Skillet:SetSelectedSkill(skill_index, was_clicked)
    if not skill_index then
        -- no skill selected
        self:HideNotesWindow()
    elseif self.selectedSkill and self.selectedSkill ~= skill_index then
        -- new skill selected
        self:HideNotesWindow() -- XXX: should this be an update?
    end

    self.selectedSkill = skill_index
    self:UpdateDetailsWindow(skill_index)
end

-- Updates the text we filter the list of recipes against.
function Skillet:UpdateFilter(text)
    self:SetTradeSkillOption(self.currentTrade, "filtertext", text)
    self:UpdateTradeSkillWindow()
end

-- Synastria: Called when a craft fails
function Skillet:OnCraftFailed(errorMessage)
    -- Display error in the start crafting prompt if it's visible
    if self.startCraftingPrompt and self.startCraftingPrompt:IsVisible() then
        self.startCraftingPrompt.errorText:SetText(errorMessage or "Craft failed!")

        -- Re-enable the start button after 1 second
        self:ScheduleEvent("Skillet_ReenableStartButton", function()
            if self.startCraftingPrompt and self.startCraftingPrompt:IsVisible() then
                self.startCraftingPrompt.startButton:Enable()
            end
        end, 1.0)
    end
end

-- Called when the queue has changed in some way
function Skillet:QueueChanged()
    -- OPTIMIZATION: Skip expensive operations during bulk queue operations
    if self.suppressQueueUpdates then
        return
    end

    -- Debug queue state (only in dev mode)
    if self:IsDevMode() then
        local queueCount = self.stitch.queue and #self.stitch.queue or 0
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[QUEUE] QueueChanged() called! Queue count: " .. queueCount .. "|r")

        -- Debug: Show first queue entry details
        if self.stitch.queue and #self.stitch.queue > 0 then
            local firstEntry = self.stitch.queue[1]
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[QUEUE] First entry: spellId=" ..
                tostring(firstEntry.spellId) ..
                ", name='" .. tostring(firstEntry.name) .. "', profession='" .. tostring(firstEntry.profession) .. "'|r")

            local lastEntry = self.stitch.queue[#self.stitch.queue]
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[QUEUE] Last entry: spellId=" ..
                tostring(lastEntry.spellId) ..
                ", name='" .. tostring(lastEntry.name) .. "', profession='" .. tostring(lastEntry.profession) .. "'|r")
        end
    end

    -- Synastria: Update the queue display immediately
    self:UpdateQueueWindow()

    -- Synastria: Auto-export queue to ResourceTracker (if available)
    if self.AutoExportQueueToResourceTracker then
        self:AutoExportQueueToResourceTracker()
    end

    -- Synastria: If queue is empty and start crafting prompt is visible, hide it and clear keybindings
    if self.stitch.queue and #self.stitch.queue == 0 then
        if self:IsDevMode() then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[DIALOG] Queue is empty - checking for dialog to close...|r")
        end

        -- Try using self reference first, then fall back to global
        local promptFrame = self.startCraftingPrompt or getglobal("SkilletStartCraftingPrompt")

        if self:IsDevMode() then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[DIALOG] promptFrame found: " ..
                tostring(promptFrame ~= nil) .. ", visible: " ..
                tostring(promptFrame and promptFrame:IsVisible() or false) .. "|r")
        end

        if promptFrame and promptFrame:IsVisible() then
            promptFrame:Hide()
            -- Clear keybindings
            SetBinding("CTRL-MOUSEWHEELUP")
            SetBinding("CTRL-MOUSEWHEELDOWN")
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00Queue complete! Dialog closed and keybindings cleared.|r")
        elseif promptFrame then
            -- Dialog exists but isn't visible - still hide it to be safe
            promptFrame:Hide()
            SetBinding("CTRL-MOUSEWHEELUP")
            SetBinding("CTRL-MOUSEWHEELDOWN")
            if self:IsDevMode() then
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[DIALOG] Dialog existed but wasn't visible - hidden anyway|r")
            end
        else
            if self:IsDevMode() then
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[DIALOG] No dialog frame found to close|r")
            end
        end
    else
        -- Synastria: Queue still has items - refresh the prompt to show next item and re-enable button
        if self.startCraftingPrompt and self.startCraftingPrompt:IsVisible() then
            self:ShowStartCraftingPrompt()
        end
    end

    -- Synastria: Clear craftability cache when queue changes
    -- Simpler and more efficient than selective invalidation for multi-step crafts
    ---@type SkilletStitch
    local lib = AceLibrary("SkilletStitch-1.1")
    if lib and lib.ClearCraftabilityCache then
        lib:ClearCraftabilityCache()
        -- Debug output disabled
    end

    -- Trigger full background craftability recalculation if trade skill window is visible
    if self.tradeSkillFrame and self.tradeSkillFrame:IsVisible() and self.currentTrade then
        -- Cancel any scheduled updates
        if AceEvent:IsEventScheduled("Skillet_UpdateWindows") then
            AceEvent:CancelScheduledEvent("Skillet_UpdateWindows")
        end

        -- Start background calculation for current profession
        if self.CraftCalc then
            local isRunning, runningProf = self.CraftCalc:IsCalculationRunning()
            if isRunning then
                self.CraftCalc:StopCalculation()
            end

            local success = self.CraftCalc:StartBackgroundCalculation(self.currentTrade, function()
                -- After calculation completes, update the UI
                if self.tradeSkillFrame and self.tradeSkillFrame:IsVisible() then
                    self:UpdateTradeSkillWindow()
                end
            end)
        else
            -- Fallback to immediate update if calc module not available
            self:UpdateTradeSkillWindow()
        end
    end

    -- Hey! What's all this then? Well, we may get the request to update the
    -- windows while the queue is being processed and the reagent and item
    -- counts may not have been updated yet. So, the "0.5" puts in a 1/2
    -- second delay before the real update window method is called. That
    -- give the rest of the UI (and the API methods called by Stitch) time
    -- to record any used reagents.
    if Skillet.tradeSkillFrame and Skillet.tradeSkillFrame:IsVisible() then
        if not AceEvent:IsEventScheduled("Skillet_UpdateWindows") then
            AceEvent:ScheduleEvent("Skillet_UpdateWindows", Skillet.UpdateTradeSkillWindow, 0.5, self)
        end
    end

    if SkilletShoppingList and SkilletShoppingList:IsVisible() then
        if not AceEvent:IsEventScheduled("Skillet_UpdateShoppingList") then
            AceEvent:ScheduleEvent("Skillet_UpdateShoppingList", Skillet.UpdateShoppingListWindow, 0.25, self)
        end
    end

    if MerchantFrame and MerchantFrame:IsVisible() then
        if not AceEvent:IsEventScheduled("Skillet_UpdateMerchantFrame") then
            AceEvent:ScheduleEvent("Skillet_UpdateMerchantFrame", Skillet.UpdateMerchantFrame, 0.25, self)
        end
    end
end

-- Gets the note associated with the item, if there is such a note.
-- If there is no user supplied note, then return nil
-- The item can be either a recipe or reagent name
function Skillet:GetItemNote(link)
    ---@type string|nil
    local result

    ---@type string|nil
    local playerName = UnitName("player")

    if not playerName or not self.db.server.notes[playerName] then
        return
    end

    local id = self:GetItemIDFromLink(link)
    if id and self.db.server.notes[playerName] then
        result = self.db.server.notes[playerName][id]
    else
        self:Print("Error: Skillet:GetItemNote() could not determine item ID for " .. link);
    end

    if result and result == "" then
        result = nil
        if playerName and self.db.server.notes[playerName] and id then
            self.db.server.notes[playerName][id] = nil
        end
    end

    return result
end

-- Sets the note for the specified object, if there is already a note
-- then it is overwritten
function Skillet:SetItemNote(link, note)
    local id = self:GetItemIDFromLink(link);

    ---@type string|nil
    local playerName = UnitName("player")
    if playerName and not self.db.server.notes[playerName] then
        self.db.server.notes[playerName] = {}
    end

    if playerName and id then
        self.db.server.notes[playerName][id] = note
    else
        self:Print("Error: Skillet:SetItemNote() could not determine item ID for " .. link);
    end
end

-- Adds the skillet notes text to the tooltip for a specified
-- item.
-- Returns true if tooltip modified.
function Skillet:AddItemNotesToTooltip(tooltip)
    if IsControlKeyDown() then
        return
    end

    local notes_enabled = self.db.profile.show_item_notes_tooltip or false
    local crafters_enabled = self.db.profile.show_crafters_tooltip or false

    -- nothing to be added to the tooltip
    if not notes_enabled and not crafters_enabled then
        return
    end

    -- get item name
    local name, link = tooltip:GetItem();
    if not link then return; end

    local id = self:GetItemIDFromLink(link);
    if not id then return end;

    if notes_enabled then
        ---@type string|nil
        local currentPlayer = UnitName("player")
        local header_added = false
        for player, notes_table in pairs(self.db.server.notes) do --as string, NotesTable
            local note = notes_table[id]                          --as string|nil
            if note then
                if not header_added then
                    tooltip:AddLine("Skillet " .. GetLocalizedString("Notes") .. ":")
                    header_added = true
                end
                if currentPlayer and player ~= currentPlayer then
                    note = GRAY_FONT_COLOR_CODE .. player .. ": " .. FONT_COLOR_CODE_CLOSE .. note
                end
                tooltip:AddLine(" " .. note, 1, 1, 1, 1) -- r,g,b, wrap
            end
        end
    end

    local header_added = false
    if crafters_enabled then
        local crafters = self:GetCraftersForItem(id);
        if crafters then
            header_added = true
            local title_added = false

            for i, name in ipairs(crafters) do
                if not title_added then
                    title_added = true
                    tooltip:AddDoubleLine(GetLocalizedString("Crafted By"), name)
                else
                    tooltip:AddDoubleLine(" ", name)
                end
            end
        end
    end

    return header_added
end

-- Returns the state of a craft specific option
function Skillet:GetTradeSkillOption(trade, option)
    local options = self.db.char.tradeskill_options;

    if not options or not options[trade] then
        return false
    end

    return options[trade][option]
end

-- sets the state of a craft specific option
function Skillet:SetTradeSkillOption(trade, option, value)
    if not trade then
        return
    end

    ---@type table<string, table>
    local options = self.db.char.tradeskill_options;

    if not options then
        options = {}
        self.db.char.tradeskill_options = options
    end

    if not options[trade] then
        options[trade] = {}
    end

    options[trade][option] = value
end

-- Synastria: Register PT vendor extensions after addon loads
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

local addonLoaded = false
local playerEntered = false

local function TryRegisterPT()
    -- Only run once, after both events have fired
    if not (addonLoaded and playerEntered) then return end

    -- Unregister events
    frame:UnregisterEvent("ADDON_LOADED")
    frame:UnregisterEvent("PLAYER_ENTERING_WORLD")

    if AceLibrary and AceLibrary:HasInstance("LibPeriodicTable-3.1") then
        local PT = AceLibrary("LibPeriodicTable-3.1")

        -- Register our extension using our own parent category
        -- Define vendor items that are missing from PT's base vendor set
        local vendorItemOverrides = {
            2593,  -- Flask of Port (Cooking)
            2880,  -- Weak Flux (Engineering/Blacksmithing)
            3466,  -- Strong Flux (Engineering/Blacksmithing)
            4399,  -- Wooden Stock (Engineering - Gun component)
            4539,  -- Goldenbark Apple (Cooking)
            30817, -- Simple Flour (Cooking)
            34412, -- Sparkling Apple Cider (Cooking)
            38426, -- Eternium Thread (Tailoring)
            39354, -- Light Parchment (Inscription)
            39684, -- Hair Trigger (Engineering - WotLK Gun component)
            40533, -- Walnut Stock (Engineering - WotLK Gun component)
        }

        -- Convert table to comma-separated string
        local vendorItemString = table.concat(vendorItemOverrides, ",")

        local success, err = pcall(function()
            PT:AddData("Skillet", "$Rev: 1 $", {
                ["Skillet.Vendor.Extended"] = vendorItemString
            })
        end)

        -- PeriodicTable registration complete (silent)
    end
end

frame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == "Skillet - Synastria" then
        addonLoaded = true
        TryRegisterPT()
    elseif event == "PLAYER_ENTERING_WORLD" then
        playerEntered = true
        TryRegisterPT()
    end
end)

--- Helper: Get profession name from skill ID
function Skillet:GetProfessionNameFromSkillId(skillId)
    local map = {
        [171] = "Alchemy",
        [164] = "Blacksmithing",
        [333] = "Enchanting",
        [202] = "Engineering",
        [755] = "Jewelcrafting",
        [165] = "Leatherworking",
        [197] = "Tailoring",
        [185] = "Cooking",
        [129] = "First Aid",
    }
    return map[skillId]
end

--- Deep investigation: Compare window vs API data in detail
--- Usage: /script Skillet:InvestigateDataConsistency()
--- NOTE: Requires a tradeskill window to be open
function Skillet:InvestigateDataConsistency()
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF========================================|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF   Data Consistency Investigation|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF========================================|r")

    -- Check if window is open
    local tradeskillName = GetTradeSkillLine()
    if not tradeskillName or tradeskillName == "" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[ERROR] No tradeskill window open|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00Open a profession window first|r")
        return
    end

    if not Custom_GetProfessionRecipes or not Custom_GetProfessionRecipeInfo then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[ERROR] Custom APIs not available|r")
        return
    end

    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFFFF[PROFESSION] " .. tradeskillName .. "|r")
    DEFAULT_CHAT_FRAME:AddMessage("")

    -- Get profession ID
    local professionMap = {
        ["Alchemy"] = 171,
        ["Blacksmithing"] = 164,
        ["Enchanting"] = 333,
        ["Engineering"] = 202,
        ["Jewelcrafting"] = 755,
        ["Leatherworking"] = 165,
        ["Tailoring"] = 197,
        ["Cooking"] = 185,
        ["First Aid"] = 129,
    }

    local professionId = professionMap[tradeskillName]
    if not professionId then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[ERROR] Unknown profession|r")
        return
    end

    -- Build API recipe lookup
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFFFF[STEP 1] Building API recipe database...|r")
    local apiRecipes = Custom_GetProfessionRecipes(professionId)
    if not apiRecipes then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[ERROR] Could not get API recipes|r")
        return
    end

    local apiLookup = {} -- [recipeName] = {spellId, itemId, ...}
    local apiByItem = {} -- [itemId] = {spellId, name, ...}

    for _, spellId in ipairs(apiRecipes) do
        local skillId, name, itemId = Custom_GetProfessionRecipeInfo(spellId)
        if name then
            apiLookup[name] = {
                spellId = spellId,
                itemId = itemId,
                skillId = skillId
            }
            if itemId then
                apiByItem[itemId] = {
                    spellId = spellId,
                    name = name,
                    skillId = skillId
                }
            end
        end
    end

    DEFAULT_CHAT_FRAME:AddMessage(string.format(
        "  |cFF00FF00✓ Indexed %d API recipes|r",
        #apiRecipes
    ))

    -- Scan window data
    DEFAULT_CHAT_FRAME:AddMessage("")
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFFFF[STEP 2] Scanning window data...|r")

    local windowTotal = GetNumTradeSkills()
    local categories = {
        headers = 0,
        matched = 0,
        notInAPI = 0,
        duplicates = 0
    }

    ---@type MissingRecipeInfo[]
    local notFoundList = {}
    ---@type string[]
    local headerList = {}
    local seenRecipes = {} -- Track duplicates

    for i = 1, windowTotal do
        local name, skillType = GetTradeSkillInfo(i)
        local link = GetTradeSkillItemLink(i)

        if skillType == "header" then
            categories.headers = categories.headers + 1
            table.insert(headerList, name)
        else
            -- Check if we've seen this exact recipe before
            if seenRecipes[name] then
                categories.duplicates = categories.duplicates + 1
            else
                seenRecipes[name] = true

                -- Try to find in API
                local found = false

                -- Method 1: Direct name match
                if apiLookup[name] then
                    categories.matched = categories.matched + 1
                    found = true
                else
                    -- Method 2: Try to match by item ID from link
                    if link then
                        local itemId = tonumber(link:match("item:(%d+)"))
                        if itemId and apiByItem[itemId] then
                            categories.matched = categories.matched + 1
                            found = true

                            -- Note if name differs
                            if apiByItem[itemId].name ~= name then
                                -- Name mismatch but same item
                            end
                        end
                    end
                end

                if not found then
                    categories.notInAPI = categories.notInAPI + 1
                    table.insert(notFoundList, --as MissingRecipeInfo
                        {
                            index = i,
                            name = name,
                            skillType = skillType,
                            link = link
                        })
                end
            end
        end
    end

    -- Report findings
    DEFAULT_CHAT_FRAME:AddMessage("")
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[ANALYSIS RESULTS]|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFFFF━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━|r")
    DEFAULT_CHAT_FRAME:AddMessage(string.format(
        "|cFFFFFFFF  Total window entries:|r %d",
        windowTotal
    ))
    DEFAULT_CHAT_FRAME:AddMessage(string.format(
        "|cFFFFFFFF  Total API recipes:|r %d",
        #apiRecipes
    ))
    DEFAULT_CHAT_FRAME:AddMessage("")
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFFFF[BREAKDOWN]|r")
    DEFAULT_CHAT_FRAME:AddMessage(string.format(
        "  |cFF888888Headers/Categories:|r %d",
        categories.headers
    ))
    DEFAULT_CHAT_FRAME:AddMessage(string.format(
        "  |cFF00FF00Matched in API:|r %d",
        categories.matched
    ))
    DEFAULT_CHAT_FRAME:AddMessage(string.format(
        "  |cFFFF8800Duplicates:|r %d",
        categories.duplicates
    ))
    DEFAULT_CHAT_FRAME:AddMessage(string.format(
        "  |cFFFF0000Not in API:|r %d",
        categories.notInAPI
    ))

    -- Calculate expected total
    local expectedTotal = categories.headers + categories.matched + categories.duplicates + categories.notInAPI
    DEFAULT_CHAT_FRAME:AddMessage("")
    DEFAULT_CHAT_FRAME:AddMessage(string.format(
        "|cFFFFFFFF  Calculation: %d + %d + %d + %d = %d|r",
        categories.headers, categories.matched, categories.duplicates,
        categories.notInAPI, expectedTotal
    ))

    if expectedTotal == windowTotal then
        DEFAULT_CHAT_FRAME:AddMessage("  |cFF00FF00✓ Totals match!|r")
    else
        DEFAULT_CHAT_FRAME:AddMessage("  |cFFFF0000✗ Totals don't match!|r")
    end

    -- Show headers
    if #headerList > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFFFF[HEADERS] (Cannot be crafted)|r")
        for i, header in ipairs(headerList) do --as string
            if i <= 10 then
                DEFAULT_CHAT_FRAME:AddMessage(string.format("  %d. %s", i, header))
            elseif i == 11 then
                DEFAULT_CHAT_FRAME:AddMessage(string.format("  ... and %d more", #headerList - 10))
                break
            end
        end
    end

    -- Show recipes not in API
    if #notFoundList > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8800[NOT IN API] Recipes in window but not in API:|r")
        for i, recipe in ipairs(notFoundList) do
            if i <= 20 then
                local itemId = recipe.link and tonumber(recipe.link:match("item:(%d+)")) or "nil"
                DEFAULT_CHAT_FRAME:AddMessage(string.format(
                    "  %d. [%d] %s (type:%s, item:%s)",
                    i, recipe.index, recipe.name, recipe.skillType, tostring(itemId)
                ))
            elseif i == 21 then
                DEFAULT_CHAT_FRAME:AddMessage(string.format("  ... and %d more", #notFoundList - 20))
                break
            end
        end

        DEFAULT_CHAT_FRAME:AddMessage("")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[INVESTIGATION NEEDED]|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFFFFThese recipes appear in the window but not in API.|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFFFFPossible reasons:|r")
        DEFAULT_CHAT_FRAME:AddMessage("  • Specialty/variant recipes (e.g., Mooncloth)")
        DEFAULT_CHAT_FRAME:AddMessage("  • Quest-learned recipes")
        DEFAULT_CHAT_FRAME:AddMessage("  • Faction-specific recipes")
        DEFAULT_CHAT_FRAME:AddMessage("  • Name mismatches (different localization)")
    end

    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF========================================|r")

    -- Summary
    local uniqueRecipes = categories.matched + categories.notInAPI
    DEFAULT_CHAT_FRAME:AddMessage("")
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[SUMMARY]|r")
    DEFAULT_CHAT_FRAME:AddMessage(string.format(
        "  Unique craftable recipes: %d",
        uniqueRecipes
    ))
    DEFAULT_CHAT_FRAME:AddMessage(string.format(
        "  API coverage: %.1f%% (%d/%d)",
        (categories.matched / uniqueRecipes * 100), categories.matched, uniqueRecipes
    ))

    if categories.notInAPI == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("  |cFF00FF00✓ PERFECT API COVERAGE|r")
    elseif categories.notInAPI <= 5 then
        DEFAULT_CHAT_FRAME:AddMessage("  |cFFFFAA00! Minor gaps in API coverage|r")
    else
        DEFAULT_CHAT_FRAME:AddMessage("  |cFFFF8800! Significant gaps in API coverage|r")
    end
end

--- Investigate WHY recipes are missing from API
--- Usage: /script Skillet:InvestigateMissingRecipes()
--- NOTE: Requires a tradeskill window to be open
function Skillet:InvestigateMissingRecipes()
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF========================================|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF   Missing Recipe Investigation|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF========================================|r")

    -- Check if window is open
    local tradeskillName = GetTradeSkillLine()
    if not tradeskillName or tradeskillName == "" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[ERROR] No tradeskill window open|r")
        return
    end

    if not Custom_GetProfessionRecipes or not Custom_GetProfessionRecipeInfo then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[ERROR] Custom APIs not available|r")
        return
    end

    local professionMap = {
        ["Alchemy"] = 171,
        ["Blacksmithing"] = 164,
        ["Enchanting"] = 333,
        ["Engineering"] = 202,
        ["Jewelcrafting"] = 755,
        ["Leatherworking"] = 165,
        ["Tailoring"] = 197,
        ["Cooking"] = 185,
        ["First Aid"] = 129,
    }

    local professionId = professionMap[tradeskillName]
    if not professionId then return end

    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFFFF[PROFESSION] " .. tradeskillName .. "|r")
    DEFAULT_CHAT_FRAME:AddMessage("")

    -- Build API lookup
    ---@type number[]|nil
    local apiRecipes = Custom_GetProfessionRecipes(professionId)
    local apiLookup = {}
    local apiByItem = {}

    if apiRecipes then
        ---@type number[]
        local spellIds = apiRecipes
        for _, spellId in ipairs(spellIds) do
            local skillId, name, itemId = Custom_GetProfessionRecipeInfo(spellId)
            if name then
                apiLookup[name] = spellId
                if itemId then
                    apiByItem[itemId] = spellId
                end
            end
        end
    end

    -- Find missing recipes
    ---@type MissingRecipeInfo[]
    local missing = {}
    local windowTotal = GetNumTradeSkills()

    for i = 1, windowTotal do
        local name, skillType = GetTradeSkillInfo(i)
        local link = GetTradeSkillItemLink(i)

        if skillType ~= "header" then
            local found = apiLookup[name]

            if not found and link then
                local itemId = tonumber(link:match("item:(%d+)"))
                if itemId then
                    found = apiByItem[itemId]
                end
            end

            if not found then
                table.insert(missing, {
                    index = i,
                    name = name,
                    skillType = skillType,
                    link = link
                })
            end
        end
    end

    DEFAULT_CHAT_FRAME:AddMessage(string.format(
        "|cFFFFFFFF[FOUND] %d missing recipes|r",
        #missing
    ))
    DEFAULT_CHAT_FRAME:AddMessage("")

    if #missing == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[RESULT] No missing recipes!|r")
        return
    end

    -- Investigate each missing recipe
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFFFF[INVESTIGATING] First 10 missing recipes...|r")
    DEFAULT_CHAT_FRAME:AddMessage("")

    for i = 1, math.min(10, #missing) do
        local recipe = missing[i] --as MissingRecipeInfo
        DEFAULT_CHAT_FRAME:AddMessage(string.format(
            "|cFFFFAA00[%d] %s|r",
            i, recipe.name
        ))

        -- Get window data
        local numReagents = GetTradeSkillNumReagents(recipe.index)
        local cooldown = GetTradeSkillCooldown(recipe.index)
        local numMade = GetTradeSkillNumMade(recipe.index)
        local minMade, maxMade = numMade, numMade

        DEFAULT_CHAT_FRAME:AddMessage(string.format(
            "  Window Data: type=%s, reagents=%s, cooldown=%s, makes=%s",
            recipe.skillType,
            tostring(numReagents),
            tostring(cooldown and (cooldown > 0) or false),
            tostring(numMade)
        ))

        -- Try to find via item ID
        if recipe.link then
            local itemId = tonumber(recipe.link:match("item:(%d+)"))
            if itemId then
                DEFAULT_CHAT_FRAME:AddMessage(string.format("  ItemId: %d", itemId))

                -- Try reverse lookup
                if Custom_GetProfessionRecipeFromCraftedItem then
                    local spellId = Custom_GetProfessionRecipeFromCraftedItem(itemId)
                    if spellId then
                        DEFAULT_CHAT_FRAME:AddMessage(string.format(
                            "  |cFF00FF00✓ Found via reverse lookup: SpellId %d|r",
                            spellId
                        ))

                        -- Check if this spell is in our API list
                        local found = false
                        if apiRecipes then
                            ---@type number[]
                            local apiSpellIds = apiRecipes
                            for _, apiSpellId in ipairs(apiSpellIds) do
                                if apiSpellId == spellId then
                                    found = true
                                    break
                                end
                            end
                        end

                        if found then
                            DEFAULT_CHAT_FRAME:AddMessage(
                                "  |cFFFF8800⚠ SpellId IS in API list but name didn't match!|r")
                        else
                            DEFAULT_CHAT_FRAME:AddMessage("  |cFFFF0000✗ SpellId NOT in API list|r")
                        end

                        -- Get API info for this spell
                        local skillId, apiName, apiItemId = Custom_GetProfessionRecipeInfo(spellId)
                        if apiName then
                            DEFAULT_CHAT_FRAME:AddMessage(string.format(
                                "  API Name: '%s' vs Window Name: '%s'",
                                apiName, recipe.name
                            ))
                            if apiName ~= recipe.name then
                                DEFAULT_CHAT_FRAME:AddMessage("  |cFFFF8800⚠ NAME MISMATCH!|r")
                            end
                        end
                    else
                        DEFAULT_CHAT_FRAME:AddMessage("  |cFFFF0000✗ Reverse lookup returned nil|r")
                    end
                end
            else
                DEFAULT_CHAT_FRAME:AddMessage("  |cFFFF8800⚠ No item ID in link|r")
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("  |cFFFF8800⚠ No item link|r")
        end

        DEFAULT_CHAT_FRAME:AddMessage("")
    end

    -- Pattern analysis
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFFFF[PATTERN ANALYSIS]|r")

    local patterns = {
        sharpening = 0,
        weightstone = 0,
        skeleton = 0,
        chain = 0,
        plating = 0,
        socket = 0,
        other = 0
    }

    ---@type MissingRecipeInfo[]
    for _, recipe in ipairs(missing) do --as MissingRecipeInfo
        local nameLower = string.lower(recipe.name)
        if string.find(nameLower, "sharpening") then
            patterns.sharpening = patterns.sharpening + 1
        elseif string.find(nameLower, "weightstone") then
            patterns.weightstone = patterns.weightstone + 1
        elseif string.find(nameLower, "skeleton") then
            patterns.skeleton = patterns.skeleton + 1
        elseif string.find(nameLower, "chain") then
            patterns.chain = patterns.chain + 1
        elseif string.find(nameLower, "plating") then
            patterns.plating = patterns.plating + 1
        elseif string.find(nameLower, "socket") then
            patterns.socket = patterns.socket + 1
        else
            patterns.other = patterns.other + 1
        end
    end

    DEFAULT_CHAT_FRAME:AddMessage("  Sharpening Stones: " .. patterns.sharpening)
    DEFAULT_CHAT_FRAME:AddMessage("  Weightstones: " .. patterns.weightstone)
    DEFAULT_CHAT_FRAME:AddMessage("  Skeleton Keys: " .. patterns.skeleton)
    DEFAULT_CHAT_FRAME:AddMessage("  Chains: " .. patterns.chain)
    DEFAULT_CHAT_FRAME:AddMessage("  Plating: " .. patterns.plating)
    DEFAULT_CHAT_FRAME:AddMessage("  Socket items: " .. patterns.socket)
    DEFAULT_CHAT_FRAME:AddMessage("  Other weapons/items: " .. patterns.other)

    DEFAULT_CHAT_FRAME:AddMessage("")
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF========================================|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[HYPOTHESIS]|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFFFFThe API may be filtering out:|r")
    DEFAULT_CHAT_FRAME:AddMessage("  • Temporary item enhancements")
    DEFAULT_CHAT_FRAME:AddMessage("  • Non-equippable items")
    DEFAULT_CHAT_FRAME:AddMessage("  • Utility items (keys, etc.)")
    DEFAULT_CHAT_FRAME:AddMessage("  • Or using different spell ID mapping|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF========================================|r")
end

--- Check if missing recipes exist in the global (-1) dataset
--- Usage: /script Skillet:CheckMissingInGlobalDataset()
--- NOTE: Requires a tradeskill window to be open
function Skillet:CheckMissingInGlobalDataset()
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF========================================|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF   Global Dataset Check|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF========================================|r")

    -- Check if window is open
    local tradeskillName = GetTradeSkillLine()
    if not tradeskillName or tradeskillName == "" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[ERROR] No tradeskill window open|r")
        return
    end

    if not Custom_GetProfessionRecipes or not Custom_GetProfessionRecipeInfo then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[ERROR] Custom APIs not available|r")
        return
    end

    local professionMap = {
        ["Alchemy"] = 171,
        ["Blacksmithing"] = 164,
        ["Enchanting"] = 333,
        ["Engineering"] = 202,
        ["Jewelcrafting"] = 755,
        ["Leatherworking"] = 165,
        ["Tailoring"] = 197,
        ["Cooking"] = 185,
        ["First Aid"] = 129,
    }

    local professionId = professionMap[tradeskillName]
    if not professionId then return end

    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFFFF[PROFESSION] " .. tradeskillName .. " (ID: " .. professionId .. ")|r")
    DEFAULT_CHAT_FRAME:AddMessage("")

    -- Get profession-specific recipes
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFFFF[STEP 1] Getting profession-specific recipes...|r")
    local profRecipes = Custom_GetProfessionRecipes(professionId) or {}
    local profLookup = {}
    local profByItem = {}

    ---@type number[]
    local profSpellIds = profRecipes
    for _, spellId in ipairs(profSpellIds) do
        local skillId, name, itemId = Custom_GetProfessionRecipeInfo(spellId)
        if name then
            profLookup[name] = spellId
            if itemId then
                profByItem[itemId] = spellId
            end
        end
    end

    DEFAULT_CHAT_FRAME:AddMessage(string.format("  ✓ Indexed %d recipes", #profRecipes))

    -- Get ALL recipes globally
    DEFAULT_CHAT_FRAME:AddMessage("")
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFFFF[STEP 2] Getting ALL recipes (professionId = -1)...|r")
    local allRecipes = Custom_GetProfessionRecipes(-1) or {}
    local globalLookup = {}
    local globalByItem = {}
    local globalBySpell = {}

    ---@type number[]
    local allSpellIds = allRecipes
    for _, spellId in ipairs(allSpellIds) do
        local skillId, name, itemId = Custom_GetProfessionRecipeInfo(spellId)
        if name then
            globalLookup[name] = { spellId = spellId, skillId = skillId, itemId = itemId }
            if itemId then
                globalByItem[itemId] = { spellId = spellId, skillId = skillId, name = name }
            end
            globalBySpell[spellId] = { name = name, skillId = skillId, itemId = itemId }
        end
    end

    DEFAULT_CHAT_FRAME:AddMessage(string.format("  ✓ Indexed %d global recipes", #allRecipes))

    -- Find missing recipes in window
    DEFAULT_CHAT_FRAME:AddMessage("")
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFFFF[STEP 3] Finding missing recipes from window...|r")
    ---@type MissingRecipeInfo[]
    local missing = {}
    local windowTotal = GetNumTradeSkills()

    for i = 1, windowTotal do
        local name, skillType = GetTradeSkillInfo(i)
        local link = GetTradeSkillItemLink(i)

        if skillType ~= "header" then
            local found = profLookup[name]

            if not found and link then
                local itemId = tonumber(link:match("item:(%d+)"))
                if itemId then
                    found = profByItem[itemId]
                end
            end

            if not found then
                table.insert(missing, {
                    index = i,
                    name = name,
                    skillType = skillType,
                    link = link
                })
            end
        end
    end

    DEFAULT_CHAT_FRAME:AddMessage(string.format("  ✓ Found %d missing recipes", #missing))

    -- Check if missing recipes exist in global dataset
    DEFAULT_CHAT_FRAME:AddMessage("")
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFFFF[STEP 4] Checking missing recipes in global dataset...|r")
    DEFAULT_CHAT_FRAME:AddMessage("")

    local foundInGlobal = 0
    local wrongProfession = 0
    local notFoundAnywhere = 0
    ---@type WrongProfessionInfo[]
    local wrongProfessionList = {}
    ---@type string[]
    local notFoundList = {}

    for i, recipe in ipairs(missing) do
        local foundGlobally = false
        ---@type table|nil
        local globalData = nil

        -- Check by name
        if globalLookup[recipe.name] then
            foundGlobally = true
            globalData = globalLookup[recipe.name]
        end

        -- Check by item ID
        if not foundGlobally and recipe.link then
            local itemId = tonumber(recipe.link:match("item:(%d+)"))
            if itemId and globalByItem[itemId] then
                foundGlobally = true
                globalData = globalByItem[itemId]
            end
        end

        if foundGlobally and globalData then
            foundInGlobal = foundInGlobal + 1

            -- Check if it's under the correct profession
            local skillId = globalData.skillId or 0
            if skillId ~= professionId then
                wrongProfession = wrongProfession + 1
                table.insert(wrongProfessionList, {
                    name = recipe.name,
                    expectedProf = professionId,
                    actualProf = skillId,
                    spellId = globalData.spellId
                })
            end
        else
            notFoundAnywhere = notFoundAnywhere + 1
            if i <= 20 then
                table.insert(notFoundList, recipe.name)
            end
        end
    end

    -- Report results
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[RESULTS]|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFFFF━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━|r")
    DEFAULT_CHAT_FRAME:AddMessage(string.format(
        "|cFFFFFFFF  Missing from profession list:|r %d",
        #missing
    ))
    DEFAULT_CHAT_FRAME:AddMessage(string.format(
        "|cFF00FF00  Found in global dataset:|r %d",
        foundInGlobal
    ))
    DEFAULT_CHAT_FRAME:AddMessage(string.format(
        "|cFFFF8800  Under wrong profession:|r %d",
        wrongProfession
    ))
    DEFAULT_CHAT_FRAME:AddMessage(string.format(
        "|cFFFF0000  Not found anywhere:|r %d",
        notFoundAnywhere
    ))

    -- Show wrong profession details
    if #wrongProfessionList > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8800[WRONG PROFESSION] Recipes under wrong profession ID:|r")
        for i, item in ipairs(wrongProfessionList) do
            if i <= 10 then
                local profName = self:GetProfessionNameFromSkillId(item.actualProf)
                DEFAULT_CHAT_FRAME:AddMessage(string.format(
                    "  %d. %s -> Listed under: %s (%d)",
                    i, item.name, profName or "Unknown", item.actualProf
                ))
            elseif i == 11 then
                DEFAULT_CHAT_FRAME:AddMessage(string.format("  ... and %d more", #wrongProfessionList - 10))
                break
            end
        end
    end

    -- Show not found anywhere
    if #notFoundList > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[NOT FOUND ANYWHERE] Missing from all API data:|r")
        for i, name in ipairs(notFoundList) do
            DEFAULT_CHAT_FRAME:AddMessage(string.format("  %d. %s", i, name))
        end
        if notFoundAnywhere > #notFoundList then
            DEFAULT_CHAT_FRAME:AddMessage(string.format("  ... and %d more", notFoundAnywhere - #notFoundList))
        end
    end

    -- Summary
    DEFAULT_CHAT_FRAME:AddMessage("")
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[ANALYSIS]|r")

    local coverage = (foundInGlobal / #missing) * 100
    DEFAULT_CHAT_FRAME:AddMessage(string.format(
        "  Global dataset coverage: %.1f%% (%d/%d)",
        coverage, foundInGlobal, #missing
    ))

    if wrongProfession > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8800[ISSUE] Some recipes are categorized under wrong profession!|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFFFFThis is a server-side API bug.|r")
    end

    if notFoundAnywhere > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[ISSUE] Some recipes missing from API entirely!|r")
        DEFAULT_CHAT_FRAME:AddMessage(string.format(
            "|cFFFFFFFF%d recipes cannot be accessed via Custom_GetProfessionRecipes|r",
            notFoundAnywhere
        ))
    end

    if foundInGlobal == #missing then
        DEFAULT_CHAT_FRAME:AddMessage("")
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[GOOD NEWS] All missing recipes exist in global dataset!|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFFFFWe can use professionId=-1 and filter client-side.|r")
    end

    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF========================================|r")
end

-- Synastria: Test event registration and firing
function Skillet:TestEventSystem()
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF========== EVENT SYSTEM TEST ==========|r")

    -- Test if we can receive events
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[TEST] Skillet addon has AceEvent-2.0: " ..
        tostring(self.RegisterEvent ~= nil) .. "|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[TEST] BAG_UPDATE and UNIT_SPELLCAST_SUCCEEDED are already registered|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFFFF[TEST] Try:  Moving bag item → should trigger [DEBUG BAG_UPDATE]|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFFFF[TEST] Try:  Cast any spell → should trigger [DEBUG SPELLCAST]|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF========================================|r")
end
