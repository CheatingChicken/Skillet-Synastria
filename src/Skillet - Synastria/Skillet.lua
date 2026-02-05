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

local MAJOR_VERSION    = "1.13"
local MINOR_VERSION    = ("$Revision: 153 $"):match("%d+") or 1
local DATE             = string.gsub("$Date: 2008-10-26 19:38:21 +0000 (Sun, 26 Oct 2008) $",
    "^.-(%d%d%d%d%-%d%d%-%d%d).-$", "%1")

Skillet                = AceLibrary("AceAddon-2.0"):new("AceConsole-2.0", "AceEvent-2.0", "AceDB-2.0", "AceHook-2.1")
Skillet.title          = "Skillet"
Skillet.version        = MAJOR_VERSION .. "-" .. MINOR_VERSION
Skillet.date           = DATE

-- Pull it into the local namespace, it's faster to access that way
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
local L = AceLibrary("AceLocale-2.2"):new("Skillet")

-- Events
local AceEvent = AceLibrary("AceEvent-2.0")

-- All the options that we allow the user to control.
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
    self.stitch = AceLibrary("SkilletStitch-1.1")

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
    if self.db.server.recipes[UnitName("player")] then
        self.stitch.data = self.db.server.recipes[UnitName("player")]
    end
    self.db.server.recipes[UnitName("player")] = self.stitch.data

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
            self:Print(L["Scan completed"] .. ": " .. name);
        end

        -- Synastria: Clear craftability cache after scan to force recalculation
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

    local player = UnitName("player")

    -- Synastria: Virtual professions that should never be checked or removed
    local virtualProfessions = {
        ["Conversion"] = true,
    }

    local changed = false
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
                        if dialog.openButton then
                            self:DebugLog("[ScanDialog] Re-enabling Open Next button after '" .. profession .. "' scan",
                                "|cFF00FF00")
                            dialog.openButton:Enable()
                        else
                            self:DebugLog("[ScanDialog] Cannot re-enable: button missing", "|cFFFFAA00")
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
local function Skillet_rescan_bags()
    cache_recipes_if_needed(Skillet, false)
    Skillet:UpdateTradeSkillWindow()
    Skillet:UpdateShoppingListWindow()
end

-- So we can track when the players inventory changes and update craftable counts
function Skillet:BAG_UPDATE()
    -- Synastria: Clear craftability cache when inventory changes
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
        local recipe = self.stitch.queue[1].recipe
        if recipe and recipe.link then
            -- Check if this is a non-item craft (enchant:, spell:, etc.)
            -- Item-producing crafts start with "item:" and will be handled by BAG_UPDATE
            if not string.match(recipe.link, "^item:") then
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

    if not frame:IsVisible() then
        ShowUIPanel(frame)
    end
end

--
-- Hides the Skillet trade skill window. Does nothing if the window is not visible
--
function Skillet:internal_HideTradeSkillWindow()
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

            DEFAULT_CHAT_FRAME:AddMessage(string.format("%s  %s%s: %d/%d -> max %d%s%s%s|r",
                indent, color, reagent.name, available, needed, maxFromReagent, vendor, craftableText, conversionText))

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
-- Define conversions in a single table for easy expansion
-- Format: [sourceItemId] = {targetItemId, conversionRatio, conversionType, name}
--   ratio: how many source items = 1 target (e.g., 10 Crystallized = 1 Eternal)
--   type: "combine" (use source item) or "split" (use target item to get source)
--
-- To add new conversions:
-- 1. Add entries to CONVERSION_DEFINITIONS
-- 2. System automatically builds lookup maps
-- 3. Shopping list and queue processor use the same data
-- ========================================

-- NEW: Hardcoded conversion groups for extraction interface with labels
Skillet.CONVERSION_GROUPS = {
    {
        label = "Eternal Elements",
        resultItems = { 35623, 35624, 36860, 35625, 35627, 35622 }, -- Water, Earth, Fire, Life, Shadow, Air (Eternals)
        sourceItems = { 37705, 37701, 37702, 37704, 37703, 37700 }, -- Crystallized versions
        bidirectional = true,                                       -- Can convert both ways
        ratio = 10                                                  -- 10 crystallized = 1 eternal
    },
    {
        label = "Elemental Primals",
        resultItems = { 21884, 22452, 22451, 21886 }, -- Life, Earth, Air, Fire (Primals)
        sourceItems = { 22575, 22573, 22572, 22574 }, -- Corresponding Motes
        bidirectional = false,                        -- One-way conversion only
        ratio = 10                                    -- 10 motes = 1 primal
    },
    {
        label = "Abstract Primals",
        resultItems = { 21884, 22457, 22456 }, -- Life, Mana, Shadow (Primals)
        sourceItems = { 22575, 22576, 22577 }, -- Corresponding Motes
        bidirectional = false,                 -- One-way conversion only
        ratio = 10                             -- 10 motes = 1 primal
    },
    {
        label = "Enchanting Essences",
        -- Row 1 (Greater): Cosmic, Planar, Eternal, Nether
        -- Row 2 (Lesser): Cosmic, Planar, Eternal, Nether
        -- Row 3 (Greater): Mystic, Astral, Magic
        -- Row 4 (Lesser): Mystic, Astral, Magic
        resultItems = { 34055, 22446, 16203, 11175, 11135, 11082, 10939 }, -- Greater Essences (high->low level)
        sourceItems = { 34056, 22447, 16202, 11174, 11134, 10998, 10938 }, -- Lesser Essences (high->low level)
        bidirectional = true,                                              -- Can convert both ways
        ratio = 3,                                                         -- 3 lesser = 1 greater
        extended = true                                                    -- Use large layout (4 rows needed)
    }
}

Skillet.CONVERSION_DEFINITIONS = {
    -- ===== WRATH: Crystallized -> Eternal (combine 10 into 1) =====
    { source = 37700, target = 35622, ratio = 10, type = "combine", name = "Crystallized Air -> Eternal Air" },
    { source = 37701, target = 35624, ratio = 10, type = "combine", name = "Crystallized Earth -> Eternal Earth" },
    { source = 37702, target = 36860, ratio = 10, type = "combine", name = "Crystallized Fire -> Eternal Fire" },
    { source = 37704, target = 35625, ratio = 10, type = "combine", name = "Crystallized Life -> Eternal Life" },
    { source = 37703, target = 35627, ratio = 10, type = "combine", name = "Crystallized Shadow -> Eternal Shadow" },
    { source = 37705, target = 35623, ratio = 10, type = "combine", name = "Crystallized Water -> Eternal Water" },

    -- ===== WRATH: Eternal -> Crystallized (split 1 into 10) =====
    { source = 35622, target = 37700, ratio = 0.1, type = "split", name = "Eternal Air -> Crystallized Air" },
    { source = 35624, target = 37701, ratio = 0.1, type = "split", name = "Eternal Earth -> Crystallized Earth" },
    { source = 36860, target = 37702, ratio = 0.1, type = "split", name = "Eternal Fire -> Crystallized Fire" },
    { source = 35625, target = 37704, ratio = 0.1, type = "split", name = "Eternal Life -> Crystallized Life" },
    { source = 35627, target = 37703, ratio = 0.1, type = "split", name = "Eternal Shadow -> Crystallized Shadow" },
    { source = 35623, target = 37705, ratio = 0.1, type = "split", name = "Eternal Water -> Crystallized Water" },

    -- ===== TBC: Mote -> Primal (combine 10 into 1) =====
    { source = 22572, target = 22451, ratio = 10, type = "combine", name = "Mote of Air -> Primal Air" },
    { source = 22573, target = 22452, ratio = 10, type = "combine", name = "Mote of Earth -> Primal Earth" },
    { source = 22574, target = 21886, ratio = 10, type = "combine", name = "Mote of Fire -> Primal Fire" },
    { source = 22575, target = 21884, ratio = 10, type = "combine", name = "Mote of Life -> Primal Life" },
    { source = 22576, target = 22457, ratio = 10, type = "combine", name = "Mote of Mana → Primal Mana" },
    { source = 22577, target = 22456, ratio = 10, type = "combine", name = "Mote of Shadow → Primal Shadow" },
    { source = 22578, target = 21885, ratio = 10, type = "combine", name = "Mote of Water → Primal Water" },

    -- Note: Primal Fire/Earth → Mote conversions are real Mining recipes, not virtual conversions

    -- ===== VANILLA: Enchanting Essence Conversions (3:1 ratio) =====
    -- Lesser → Greater (combine 3 into 1)
    { source = 10938, target = 10939, ratio = 3, type = "combine", name = "Lesser Magic Essence → Greater Magic Essence" },
    { source = 10998, target = 11082, ratio = 3, type = "combine", name = "Lesser Mystic Essence → Greater Mystic Essence" },
    { source = 11134, target = 11135, ratio = 3, type = "combine", name = "Lesser Nether Essence → Greater Nether Essence" },
    { source = 11174, target = 11175, ratio = 3, type = "combine", name = "Lesser Eternal Essence → Greater Eternal Essence" },
    { source = 10940, target = 10978, ratio = 3, type = "combine", name = "Lesser Astral Essence → Greater Astral Essence" },

    -- Greater → Lesser (split 1 into 3)
    { source = 10939, target = 10938, ratio = 0.333, type = "split", name = "Greater Magic Essence → Lesser Magic Essence" },
    { source = 11082, target = 10998, ratio = 0.333, type = "split", name = "Greater Mystic Essence → Lesser Mystic Essence" },
    { source = 11135, target = 11134, ratio = 0.333, type = "split", name = "Greater Nether Essence → Lesser Nether Essence" },
    { source = 11175, target = 11174, ratio = 0.333, type = "split", name = "Greater Eternal Essence → Lesser Eternal Essence" },
    { source = 10978, target = 10940, ratio = 0.333, type = "split", name = "Greater Astral Essence → Lesser Astral Essence" },

    -- ===== TBC: Planar Essence Conversions (3:1 ratio) =====
    { source = 22447, target = 22446, ratio = 3, type = "combine", name = "Lesser Planar Essence → Greater Planar Essence" },
    { source = 22446, target = 22447, ratio = 0.333, type = "split", name = "Greater Planar Essence → Lesser Planar Essence" },

    -- ===== WRATH: Cosmic Essence Conversions (3:1 ratio) =====
    { source = 34056, target = 34055, ratio = 3, type = "combine", name = "Lesser Cosmic Essence → Greater Cosmic Essence" },
    { source = 34055, target = 34056, ratio = 0.333, type = "split", name = "Greater Cosmic Essence → Lesser Cosmic Essence" },

    -- ===== VANILLA: Enchanting Shard Conversions (3:1 ratio, one-way only) =====
    { source = 11084, target = 11139, ratio = 3, type = "combine", name = "Small Glimmering Shard → Large Glimmering Shard" },
    { source = 11138, target = 11177, ratio = 3, type = "combine", name = "Small Glowing Shard → Large Glowing Shard" },
    { source = 11176, target = 11178, ratio = 3, type = "combine", name = "Small Radiant Shard → Large Radiant Shard" },
    { source = 14343, target = 14344, ratio = 3, type = "combine", name = "Small Brilliant Shard → Large Brilliant Shard" },
}

-- Build lookup maps from definitions (backwards compatibility)
local CRYSTALLIZED_TO_ETERNAL_MAP = {}
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

-- Helper function: Get conversion info for an item
-- Returns: targetId, ratio, type or nil if no conversion exists
function Skillet:GetConversionInfo(itemId)
    -- Check if this item is a TARGET (can be created FROM something else)
    -- We check TARGET first because when we need an item, we want to make it (not use it up)
    for _, conversion in ipairs(self.CONVERSION_DEFINITIONS) do
        if conversion.target == itemId then
            -- Return the source, ratio, and type
            return conversion.source, conversion.ratio, conversion.type
        end
    end

    -- Check if this item is a SOURCE (can be converted INTO something else)
    -- This handles the case where we have excess and want to convert it
    for _, conversion in ipairs(self.CONVERSION_DEFINITIONS) do
        if conversion.source == itemId then
            return conversion.target, conversion.ratio, conversion.type
        end
    end

    return nil, nil, nil
end

-- Synastria: Calculate how many of an item will be consumed by queued recipes
---@param itemId number The item ID to check
---@return number consumed Number of items that will be consumed by the queue
function Skillet:GetQueuedReagentConsumption(itemId)
    if not itemId then return 0 end

    local lib = AceLibrary("SkilletStitch-1.1")
    if not lib or not lib.queue then return 0 end

    -- Debug: Show queue size and item being checked
    local itemName = GetItemInfo(itemId) or ("Item#" .. itemId)
    self:Print(string.format("|cFF888888[QueueConsump] Checking %s (id=%s), queue size=%d|r",
        itemName, tostring(itemId), #lib.queue))

    local totalNeeded = 0

    -- Iterate through queue and count reagents needed
    for i = 1, #lib.queue do
        local entry = lib.queue[i]
        local recipeName = entry.recipe and entry.recipe.name or "Unknown"
        self:Print(string.format("|cFF888888  [%d] Recipe: %s|r", i, recipeName))

        if entry.recipe and entry.recipe.reagents then
            self:Print(string.format("|cFF888888    Has .reagents table with %d items|r", #entry.recipe.reagents))
            for j, reagent in ipairs(entry.recipe.reagents) do
                local reagentId = self:GetItemIDFromLink(reagent.link)
                local reagentName = GetItemInfo(reagentId) or "Unknown"
                self:Print(string.format("|cFF888888      [%d] %s (id=%s vs %s) match=%s|r",
                    j, reagentName, tostring(reagentId), tostring(itemId), tostring(reagentId == itemId)))

                if reagentId == itemId then
                    local neededPerCraft = reagent.needed or 1
                    local numCasts = entry.numcasts or 1
                    local amount = neededPerCraft * numCasts
                    totalNeeded = totalNeeded + amount
                    self:Print(string.format("|cFFFFAA00      MATCH! Adding %d (need %d x %d casts)|r",
                        amount, neededPerCraft, numCasts))
                end
            end
        else
            self:Print("|cFF888888    WARNING: Recipe missing reagents data!|r")
        end
    end

    self:Print(string.format("|cFFFFAA00[QueueConsump] Total for %s: %d|r", itemName, totalNeeded))
    return totalNeeded
end

-- Synastria: Queue conversions when needed (bidirectional support)
-- Handles both Crystallized→Eternal (combine) and Eternal→Crystallized (split)
-- @param reagent: The reagent object from a recipe
-- @param needed: How many of this reagent we need total
-- @return: true if conversion was queued, false otherwise
function Skillet:QueueConversionsIfNeeded(reagent, needed)
    if not reagent or not needed or needed <= 0 then
        return false
    end

    -- Get the item ID from the reagent link
    local itemId = self:GetItemIDFromLink(reagent.link)
    if not itemId then
        return false
    end

    -- Get conversion info for this item
    local targetId, ratio, conversionType = self:GetConversionInfo(itemId)
    if not targetId then
        return false -- No conversion available for this item
    end

    -- Calculate how many we have of the needed item
    local available = GetItemCount(itemId, true) or 0
    if GetCustomGameData then
        available = available + (GetCustomGameData(13, itemId) or 0)
    end

    -- Subtract items already allocated to queued recipes
    -- IMPORTANT: Calculate this BEFORE calling this function recursively to avoid double-counting
    local queuedConsumption = self:GetQueuedReagentConsumption(itemId)
    local availableBeforeQueue = available
    available = available - queuedConsumption

    -- Debug output
    local itemName = GetItemInfo(itemId) or ("Item#" .. itemId)
    self:DebugLog(string.format("[Conv Check] %s: have %d, queued %d, avail %d, need %d",
        itemName, availableBeforeQueue, queuedConsumption, available, needed))

    if available >= needed then
        self:DebugLog(string.format("[Conv Check] %s: Already have enough (avail %d >= need %d)", 
            itemName, available, needed))
        return false -- We already have enough (after accounting for queue)
    end

    -- Calculate the shortage - this is what we need to convert
    local shortage = needed - available
    local conversionsNeeded, amountToConvert

    if conversionType == "combine" then
        -- Crystallized → Eternal (10:1 ratio)
        -- Need X Eternals, queue conversion for ALL of them
        conversionsNeeded = shortage
        amountToConvert = conversionsNeeded * math.floor(1 / ratio) -- e.g., 10 Crystallized per Eternal
    elseif conversionType == "split" then
        -- Eternal → Crystallized (1:10 ratio)
        -- Need X Crystallized, calculate how many Eternals we need to split
        local eternalsNeeded = math.ceil(shortage * ratio) -- e.g., divide by 10 and round up
        conversionsNeeded = eternalsNeeded
        amountToConvert = conversionsNeeded                -- Eternals to split
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
    local sourceId, sourceNeeded, outputId, outputAmount
    if conversionType == "combine" then
        sourceId = targetId -- Crystallized (what we use)
        sourceNeeded = amountToConvert
        outputId = itemId   -- Eternal (what we make)
        outputAmount = conversionsNeeded
    else                    -- split
        sourceId = targetId -- Eternal (what we use)
        sourceNeeded = amountToConvert
        outputId = itemId   -- Crystallized (what we make)
        outputAmount = conversionsNeeded * 10
    end

    -- Add the virtual conversion recipe to the queue
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
                    entry.recipe.outputAmount = currentOutput + additionalNeeded
                    entry.recipe.sourceNeeded = entry.recipe.outputAmount * 10
                else -- split
                    entry.recipe.outputAmount = currentOutput + (additionalNeeded * 10)
                    entry.recipe.sourceNeeded = math.ceil(entry.recipe.outputAmount / 10)
                end

                local outputName = GetItemInfo(outputId) or "Item"
                entry.recipe.name = string.format("%s (x%d)", outputName, entry.recipe.outputAmount)

                self:Print(string.format("|cFFFFAA00Conversion updated: %s (now %dx)|r", outputName,
                    entry.recipe.outputAmount))

                -- Clear craftability cache since conversion amounts changed
                lib:ClearCraftabilityCache()
                return true
            end
        end

        -- No existing conversion found - create new one
        local virtualRecipe = {
            name = string.format("%s (x%d)", neededName,
                conversionType == "combine" and conversionsNeeded or outputAmount),
            link = reagent.link,
            isVirtualConversion = true,
            conversionType = conversionType, -- "combine" or "split"
            sourceId = sourceId,             -- What we withdraw and use
            outputId = outputId,             -- What we make
            sourceNeeded = sourceNeeded,     -- How many to withdraw
            outputAmount = outputAmount,     -- How many we'll make
            -- Backwards compatibility fields
            crystallizedId = conversionType == "combine" and sourceId or outputId,
            eternalId = conversionType == "combine" and outputId or sourceId,
            crystallizedNeeded = conversionType == "combine" and sourceNeeded or outputAmount,
            eternalsToMake = conversionType == "combine" and conversionsNeeded or amountToConvert,
        }

        table.insert(lib.queue, 1, { -- Insert at the beginning so it runs first
            profession = "Conversion",
            index = 0,
            numcasts = 1,
            recipe = virtualRecipe
        })

        local action = conversionType == "combine" and "Combine" or "Split"
        self:Print(string.format("|cFFFFAA00Auto-queued: %s %s (x%d) → %s (x%d)|r",
            action, convertibleName, sourceNeeded, neededName, outputAmount))

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
            self:Print(L["Scanning tradeskill"] .. ": " .. trade);
        end

        self:UpdateScanningText(L["Scanning tradeskill"] .. " ...")

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
    local player = UnitName("player")
    local needsRescan = {}

    if self.db.server.recipes[player] then
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
                    "[ScanDialog] PostClick: Marking '" .. currentProf .. "' [" .. dialog.professionIndex .. "] as [OK]",
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
                            Skillet:DebugLog("[ScanDialog] PostClick: Button configured for '" .. nextProf .. "', waiting for calculation to complete", "|cFF888888")
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
                            local spellId = dialog.professionSpellIds[dialog.originalProfession]
                            if not spellId then
                                spellId = Skillet.stitch:FindProfessionSpellId(dialog.originalProfession)
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
        local spellId = dialog.professionSpellIds[firstProf]

        -- Try to find the spell ID if not in our basic list
        if not spellId then
            spellId = self.stitch:FindProfessionSpellId(firstProf)
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

    local actionType = self.professionSwitchPrompt.actionType
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
    local queueItem = self.stitch.queue[1]

    if queueItem and queueItem.recipe then
        local profession = queueItem.profession or "Unknown"
        local itemName = queueItem.recipe.name or "Unknown Item"
        local count = queueItem.numcasts or 1
        local currentTrade = GetTradeSkillLine()

        -- Synastria: Check if this is a virtual conversion recipe
        local isVirtualConversion = queueItem.recipe.isVirtualConversion

        if isVirtualConversion then
            -- Handle conversion workflow with step-by-step buttons
            local conversionType = queueItem.recipe.conversionType or "combine"
            local sourceName = GetItemInfo(queueItem.recipe.sourceId) or "Item"
            local outputName = GetItemInfo(queueItem.recipe.outputId) or "Item"

            local actionWord = conversionType == "combine" and "Combine" or "Split"
            frame.text:SetText(string.format("%s |cFF00FF00%dx %s|r → |cFF00FF00%dx %s|r",
                actionWord,
                queueItem.recipe.sourceNeeded, sourceName,
                queueItem.recipe.outputAmount, outputName))
            frame.itemText:SetText("") -- No instruction text needed

            -- Hide switch button, show start button with conversion action
            frame.switchButton:Hide()
            frame.startButton:Show()

            -- Initialize conversion step if not set
            if not frame.conversionStep then
                frame.conversionStep = 1
            end

            -- Calculate how many times we need to use the item
            local totalUses
            if conversionType == "combine" then
                -- Crystallized→Eternal: need X uses to make X Eternals
                totalUses = queueItem.recipe.outputAmount
            else
                -- Eternal→Crystallized: need X uses to split X Eternals
                totalUses = queueItem.recipe.sourceNeeded
            end

            -- Set button based on current step
            if frame.conversionStep == 1 then
                -- Initialize conversion tracking
                frame.totalCombinesNeeded = totalUses
                frame.combinesCompleted = 0

                frame.startButton:SetText("Withdraw")
                frame.startButton:SetScript("OnClick", function()
                    if queueItem.recipe.sourceId then
                        Skillet:WithdrawFromResourceBank(queueItem.recipe.sourceId, true)
                        Skillet:Print("|cFF00FF00Items withdrawn.|r")
                        frame.conversionStep = 2
                        Skillet:ShowStartCraftingPrompt() -- Refresh dialog to update button
                    end
                end)
                frame.startButton:Show()
                frame.useItemButton:Hide()

                -- Bind to start button for Withdraw step
                SetBindingClick("CTRL-MOUSEWHEELUP", "SkilletStartCraftingButton")
                SetBindingClick("CTRL-MOUSEWHEELDOWN", "SkilletStartCraftingButton")
            elseif frame.conversionStep == 2 then
                -- Use secure button for item usage
                local itemName = GetItemInfo(queueItem.recipe.sourceId)
                if itemName then
                    frame.useItemButton:SetAttribute("item", itemName)
                    -- Update button text to show progress
                    local buttonText = conversionType == "combine" and "Combine" or "Split"
                    frame.useItemButton:SetText(string.format("%s (%d/%d)", buttonText, frame.combinesCompleted,
                        frame.totalCombinesNeeded))
                    frame.useItemButton:Show()
                    frame.startButton:Hide()
                end

                -- Bind to use item button for Combine/Split step
                SetBindingClick("CTRL-MOUSEWHEELUP", "SkilletUseItemButton")
                SetBindingClick("CTRL-MOUSEWHEELDOWN", "SkilletUseItemButton")
            elseif frame.conversionStep == 3 then
                frame.startButton:SetText("Deposit")
                frame.startButton:SetScript("OnClick", function()
                    Skillet:DepositToResourceBank(true)
                    Skillet:Print("|cFF00FF00Remaining items deposited. Conversion complete!|r")

                    -- Reset for next conversion and remove from queue
                    frame.conversionStep = 1
                    Skillet.stitch:RemoveFromQueue(1)

                    -- Continue to next queue item
                    if #Skillet.stitch.queue > 0 then
                        Skillet.stitch:ProcessQueue()
                    else
                        -- Queue empty, hide dialog and clear keybindings
                        frame:Hide()
                        SetBinding("CTRL-MOUSEWHEELUP")
                        SetBinding("CTRL-MOUSEWHEELDOWN")
                        AceLibrary("AceEvent-2.0"):TriggerEvent("SkilletStitch_Queue_Complete")
                    end
                end)
                frame.startButton:Show()
                frame.useItemButton:Hide()

                -- Bind to start button for Deposit step
                SetBindingClick("CTRL-MOUSEWHEELUP", "SkilletStartCraftingButton")
                SetBindingClick("CTRL-MOUSEWHEELDOWN", "SkilletStartCraftingButton")
            end
        else
            -- Regular crafting workflow
            -- Reset conversion step when not a conversion
            frame.conversionStep = 1

            -- Hide the use item button (only for conversions)
            frame.useItemButton:Hide()

            -- Restore normal start button click handler
            frame.startButton:SetScript("OnClick", function()
                frame.errorText:SetText("") -- Clear error message
                frame.startButton:Disable()
                Skillet.stitch:ProcessQueue()
            end)
            frame.startButton:SetText("Start")

            -- Check if we need to switch professions
            if currentTrade ~= profession then
                -- Need to switch profession
                frame.text:SetText("Switch to " .. profession .. " to craft:")
                frame.itemText:SetText("|cFF00FF00" .. count .. "x " .. itemName .. "|r")

                -- Show switch button, hide start button
                frame.startButton:Hide()
                frame.switchButton:Show()

                -- Set spell for profession switch
                local spellId = self.stitch:FindProfessionSpellId(profession)
                if spellId then
                    frame.switchButton:SetAttribute("spell", spellId)

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
                -- Same profession, ready to craft
                frame.text:SetText("Ready to craft in " .. profession .. ":")
                frame.itemText:SetText("|cFF00FF00" .. count .. "x " .. itemName .. "|r")

                -- Show start button, hide switch button
                frame.switchButton:Hide()
                frame.startButton:Show()

                -- Synastria: Bind to the start button
                SetBindingClick("CTRL-MOUSEWHEELUP", "SkilletStartCraftingButton")
                SetBindingClick("CTRL-MOUSEWHEELDOWN", "SkilletStartCraftingButton")
            end
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
        withdrawButton:SetWidth(100)
        withdrawButton:SetHeight(24)
        withdrawButton:SetPoint("BOTTOM", frame, "BOTTOM", -110, 15)
        withdrawButton:SetText("Withdraw")
        withdrawButton:SetScript("OnClick", function()
            if frame.crystallizedId then
                Skillet:WithdrawFromResourceBank(frame.crystallizedId, true)
                Skillet:Print("|cFF00FF00Items withdrawn. Right-click them to combine.|r")
            end
        end)
        frame.withdrawButton = withdrawButton

        -- Deposit button
        local depositButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        depositButton:SetWidth(100)
        depositButton:SetHeight(24)
        depositButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 15)
        depositButton:SetText("Deposit")
        depositButton:SetScript("OnClick", function()
            Skillet:DepositToResourceBank(true)
            Skillet:Print("|cFF00FF00Remaining items deposited.|r")
        end)
        frame.depositButton = depositButton

        -- Done button
        local doneButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        doneButton:SetWidth(100)
        doneButton:SetHeight(24)
        doneButton:SetPoint("BOTTOM", frame, "BOTTOM", 110, 15)
        doneButton:SetText("Done")
        doneButton:SetScript("OnClick", function()
            frame:Hide()
            -- Remove the conversion from queue and continue
            Skillet.stitch:RemoveFromQueue(1)
            if #Skillet.stitch.queue > 0 then
                Skillet.stitch:ProcessQueue()
            else
                AceLibrary("AceEvent-2.0"):TriggerEvent("SkilletStitch_Queue_Complete")
            end
        end)
        frame.doneButton = doneButton

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
    -- Synastria: Auto-export queue to ResourceTracker (if available)
    if self.AutoExportQueueToResourceTracker then
        self:AutoExportQueueToResourceTracker()
    end

    -- Synastria: If queue is empty and start crafting prompt is visible, hide it and clear keybindings
    if self.stitch.queue and #self.stitch.queue == 0 then
        if self.startCraftingPrompt and self.startCraftingPrompt:IsVisible() then
            self.startCraftingPrompt:Hide()
            -- Clear keybindings
            SetBinding("CTRL-MOUSEWHEELUP")
            SetBinding("CTRL-MOUSEWHEELDOWN")
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00Queue complete! Keybindings cleared.|r")
        end
    end

    -- Synastria: Clear craftability cache when queue changes
    -- Simpler and more efficient than selective invalidation for multi-step crafts
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
    local result

    if not self.db.server.notes[UnitName("player")] then
        return
    end

    local id = self:GetItemIDFromLink(link)
    if id and self.db.server.notes[UnitName("player")] then
        result = self.db.server.notes[UnitName("player")][id]
    else
        self:Print("Error: Skillet:GetItemNote() could not determine item ID for " .. link);
    end

    if result and result == "" then
        result = nil
        local playerName = UnitName("player")
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

    if not self.db.server.notes[UnitName("player")] then
        self.db.server.notes[UnitName("player")] = {}
    end

    if id then
        self.db.server.notes[UnitName("player")][id] = note
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
        local header_added = false
        for player, notes_table in pairs(self.db.server.notes) do
            local note = notes_table[id]
            if note then
                if not header_added then
                    tooltip:AddLine("Skillet " .. L["Notes"] .. ":")
                    header_added = true
                end
                if player ~= UnitName("player") then
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
                    tooltip:AddDoubleLine(L["Crafted By"], name)
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
    local options = self.db.char.tradeskill_options;

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
