---@class Texture
---@field SetPoint fun(self: Texture, point: string, ...)
---@field SetHeight fun(self: Texture, height: number)
---@field SetGradientAlpha fun(self: Texture, ...)
---@field SetTexture fun(self: Texture, ...)
---@field SetVertexColor fun(self: Texture, r: number, g: number, b: number, a?: number)
---@field ClearAllPoints fun(self: Texture)
---@field SetTexCoord fun(self: Texture, ...)
---@field SetBlendMode fun(self: Texture, mode: string)

---@class FontString
---@field SetText fun(self: FontString, text: string)
---@field SetTextColor fun(self: FontString, r: number, g: number, b: number, a?: number)
---@field SetWidth fun(self: FontString, width: number)
---@field SetPoint fun(self: FontString, point: string, ...)
---@field SetHeight fun(self: FontString, height: number)
---@field Show fun(self: FontString)
---@field Hide fun(self: FontString)
---@field GetText fun(self: FontString): string

---@class Button
---@field ClearAllPoints fun(self: Button)
---@field SetParent fun(self: Button, parent: string|Frame)
---@field SetPoint fun(self: Button, ...)
---@field SetWidth fun(self: Button, width: number)
---@field SetHeight fun(self: Button, height: number)
---@field SetNormalTexture fun(self: Button, texture: string)
---@field SetPushedTexture fun(self: Button, texture: string)
---@field SetHighlightTexture fun(self: Button, texture: string)
---@field SetDisabledTexture fun(self: Button, texture: string)
---@field GetNormalTexture fun(self: Button): Texture|nil
---@field GetPushedTexture fun(self: Button): Texture|nil
---@field GetHighlightTexture fun(self: Button): Texture|nil
---@field SetNormalFontObject fun(self: Button, font: string)
---@field SetHighlightFontObject fun(self: Button, font: string)
---@field SetDisabledFontObject fun(self: Button, font: string)
---@field SetText fun(self: Button, text: string)
---@field GetText fun(self: Button): string
---@field GetName fun(self: Button): string|nil
---@field SetID fun(self: Button, id: number)
---@field GetID fun(self: Button): number
---@field SetBackdropColor fun(self: Button, r: number, g: number, b: number)
---@field UnlockHighlight fun(self: Button)
---@field LockHighlight fun(self: Button)
---@field Show fun(self: Button)
---@field Hide fun(self: Button)
---@field IsVisible fun(self: Button): boolean
---@field SetFrameLevel fun(self: Button, level: number)
---@field GetFrameLevel fun(self: Button): number
---@field GetWidth fun(self: Button): number
---@field GetTextWidth fun(self: Button): number

---@class Tooltip
---@field SetOwner fun(self: Tooltip, owner: any, anchor?: string, ...)
---@field ClearLines fun(self: Tooltip)
---@field AddLine fun(self: Tooltip, text: string, ...)
---@field AddDoubleLine fun(self: Tooltip, left: string, right: string, ...)
---@field SetHyperlink fun(self: Tooltip, link: string)
---@field SetClampedToScreen fun(self: Tooltip, clamped: boolean)
---@field SetScale fun(self: Tooltip, scale: number)
---@field SetTradeSkillItem fun(self: Tooltip, skill: number, index?: number)
---@field AppendText fun(self: Tooltip, text: string)
---@field Show fun(self: Tooltip)
---@field SetBackdropColor fun(self: Tooltip, r: number, g: number, b: number, a: number)
--[[ Skillet: A tradeskill window replacement.
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


---@type Texture
---@type Texture|nil
---@type Texture|nil
---@type Texture|nil
local gearTexture
---@type function|nil
---@type function|nil
---@type function|nil
---@type function|nil
---@type function|nil
local old_CloseSpecialWindows
---@type table<string, string>
local L
---@type Frame
_G.SkilletFrame = _G.SkilletFrame
---@type Frame
_G.SkilletReagentParent = _G.SkilletReagentParent
---@type Frame
_G.SkilletRecipeNotesFrame = _G.SkilletRecipeNotesFrame

---@alias Texture table
---@alias FontString table
]] --

---@type table<string, string>
L                               = AceLibrary("AceLocale-2.2"):new("Skillet")

---@type integer
SKILLET_TRADE_SKILL_HEIGHT      = 16
---@type integer
SKILLET_NUM_REAGENT_BUTTONS     = 8

-- min/max width for the reagent window
---@type integer
local SKILLET_REAGENT_MIN_WIDTH = 240
---@type integer
local SKILLET_REAGENT_MAX_WIDTH = 320

---@type table<string, {r: number, g: number, b: number, level: integer, alttext: string}>
local skill_style_type          = {
    ["optimal"] = { r = 1.00, g = 0.50, b = 0.25, level = 4, alttext = "+++" },
    ["medium"]  = { r = 1.00, g = 1.00, b = 0.00, level = 3, alttext = "++" },
    ["easy"]    = { r = 0.25, g = 0.75, b = 0.25, level = 2, alttext = "+" },
    ["trivial"] = { r = 0.50, g = 0.50, b = 0.50, level = 1, alttext = "" },
    ["header"]  = { r = 1.00, g = 0.82, b = 0, level = 0, alttext = "" },
}

-- Events
---@type table
local AceEvent                  = AceLibrary("AceEvent-2.0")

-- Stack of porevisouly selected recipes for use by the
-- "click on reagent, go to recipe" code
---@type table
local previousRecipies          = {}
---@type Texture|nil
local gearTexture

-- Stolen from the Waterfall Ace2 addon.
---@type table
local ControlBackdrop           = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
}
local FrameBackdrop             = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 3, right = 3, top = 30, bottom = 3 }
}

-- List of functions that are called before a button is shown
---@type (fun(button: Button, trade: string|nil, skill: number|nil, index: number|nil): Button|nil)[]
local pre_show_callbacks        = {}

-- List of functions that are called before a button is hidden
---@type (fun(button: Button, trade: string|nil, skill: number|nil, index: number|nil): Button|nil)[]
local pre_hide_callbacks        = {}

function Skillet:internal_AddPreButtonShowCallback(method)
    assert(method and type(method) == "function",
        "Usage: Skillet:AddPreButtonShowCallback(method). method must be a non-nil function")
    table.insert(pre_show_callbacks, method)
end

function Skillet:internal_AddPreButtonHideCallback(method)
    assert(method and type(method) == "function",
        "Usage: Skillet:AddPreButtonHideCallback(method). method must be a non-nil function")
    table.insert(pre_hide_callbacks, method)
end

-- Figures out how to display the craftable counts for a recipe.
-- Returns: num, num_with_bank, num_with_resbank, num_with_alts
-- Synastria: Default to resource bank count as primary display
local function get_craftable_counts(recipe)
    local factor = 1
    if Skillet.db.profile.show_craft_counts then
        factor = recipe.nummade or 1
    end

    -- numcraftable now includes resource bank (bags+resbank)
    -- numcraftablewbank includes bags+bank+resbank
    local num = math.floor(recipe.numcraftable / factor)
    local numwbank = math.floor(recipe.numcraftablewbank / factor)

    local numwalts = nil
    if recipe.numcraftablewalts then
        numwalts = math.floor(recipe.numcraftablewalts / factor)
    end

    return num, numwbank, numwalts
end

function Skillet:CreateTradeSkillWindow()
    -- The SkilletFrame is defined in the file main_frame.xml
    local frame = SkilletFrame
    if not frame then
        return frame
    end

    if TradeJunkieMain and TJ_OpenButtonTradeSkill then
        self:AddButtonToTradeskillWindow(TJ_OpenButtonTradeSkill)
    end
    if AC_Craft and AC_UseButton and AC_ToggleButton then
        self:AddButtonToTradeskillWindow(AC_ToggleButton)
        self:AddButtonToTradeskillWindow(AC_UseButton)
    end

    frame:SetBackdrop(FrameBackdrop);
    frame:SetBackdropColor(0.1, 0.1, 0.1)

    -- A title bar stolen from the Ace2 Waterfall window.
    local r, g, b = 0, 0.7, 0; -- dark green
    ---@type Texture
    local titlebar = frame:CreateTexture(nil, "BACKGROUND")
    ---@type Texture
    local titlebar2 = frame:CreateTexture(nil, "BACKGROUND")

    titlebar:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -4)
    titlebar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -3, -4)
    titlebar:SetHeight(13)

    titlebar2:SetPoint("TOPLEFT", titlebar, "BOTTOMLEFT", 0, 0)
    titlebar2:SetPoint("TOPRIGHT", titlebar, "BOTTOMRIGHT", 0, 0)
    titlebar2:SetHeight(13)

    titlebar:SetGradientAlpha("VERTICAL", r * 0.6, g * 0.6, b * 0.6, 1, r, g, b, 1)
    titlebar:SetTexture(r, g, b, 1)
    titlebar2:SetGradientAlpha("VERTICAL", r * 0.9, g * 0.9, b * 0.9, 1, r * 0.6, g * 0.6, b * 0.6, 1)
    titlebar2:SetTexture(r, g, b, 1)

    local title = CreateFrame("Frame", nil, frame)
    title:SetPoint("TOPLEFT", titlebar, "TOPLEFT", 0, 0)
    title:SetPoint("BOTTOMRIGHT", titlebar2, "BOTTOMRIGHT", 0, 0)

    ---@type FontString
    local titletext = title:CreateFontString("SkilletTitleText", "OVERLAY", "GameFontNormalLarge")
    titletext:SetPoint("TOPLEFT", title, "TOPLEFT", 0, 0)
    titletext:SetPoint("TOPRIGHT", title, "TOPRIGHT", 0, 0)
    titletext:SetHeight(26)
    titletext:SetShadowColor(0, 0, 0)
    titletext:SetShadowOffset(1, -1)
    titletext:SetTextColor(1, 1, 1)
    titletext:SetText(GetLocalizedString("Skillet Trade Skills"));

    local label = getglobal("SkilletFilterLabel")
    if label then label:SetText(GetLocalizedString("Filter")) end

    if _G.SkilletCreateAllButton then _G.SkilletCreateAllButton:SetText(GetLocalizedString("Create All")) end
    if _G.SkilletQueueAllButton then _G.SkilletQueueAllButton:SetText(GetLocalizedString("Queue All")) end
    if _G.SkilletCreateButton then _G.SkilletCreateButton:SetText(GetLocalizedString("Create")) end
    if _G.SkilletQueueButton then _G.SkilletQueueButton:SetText(GetLocalizedString("Queue")) end
    if _G.SkilletStartQueueButton then _G.SkilletStartQueueButton:SetText(GetLocalizedString("Start")) end
    if _G.SkilletEmptyQueueButton then _G.SkilletEmptyQueueButton:SetText(GetLocalizedString("Clear")) end
    if _G.SkilletShowOptionsButton then _G.SkilletShowOptionsButton:SetText(GetLocalizedString("Options")) end
    if _G.SkilletRescanButton then _G.SkilletRescanButton:SetText(GetLocalizedString("Rescan")) end
    if _G.SkilletRecipeNotesButton then _G.SkilletRecipeNotesButton:SetText(GetLocalizedString("Notes")) end

    -- Synastria: Create Debug button below Notes button
    if not SkilletDebugButton then
        local debugButton = CreateFrame("Button", "SkilletDebugButton", SkilletFrame, "UIPanelButtonTemplate")
        debugButton:SetWidth(60)
        debugButton:SetHeight(22)
        debugButton:SetPoint("TOP", SkilletRecipeNotesButton, "BOTTOM", 0, -5)
        debugButton:SetText("Debug")
        debugButton:SetNormalFontObject("GameFontNormalSmall")
        debugButton:SetScript("OnClick", function()
            Skillet:DebugSelectedRecipe()
        end)
    end
    if _G.SkilletRecipeNotesButton then _G.SkilletRecipeNotesButton:SetNormalFontObject("GameFontNormalSmall") end
    if _G.SkilletRecipeNotesFrameLabel then _G.SkilletRecipeNotesFrameLabel:SetText(GetLocalizedString("Notes")) end
    if _G.SkilletShoppingListButton then _G.SkilletShoppingListButton:SetText(GetLocalizedString("Shopping List")) end

    if _G.SkilletHideUncraftableRecipesText then
        _G.SkilletHideUncraftableRecipesText:SetText(GetLocalizedString(
            "Hide uncraftable"))
    end
    if _G.SkilletHideTrivialRecipesText then _G.SkilletHideTrivialRecipesText:SetText(GetLocalizedString("Hide trivial")) end
    -- SkilletEquipmentOnlyRecipesText:SetText(L["Equipment only"])  -- COMMENTED: Now controlled by forge toggles

    -- Always want these visible.
    SkilletItemCountInputBox:SetText("1");
    SkilletCreateCountSlider:SetMinMaxValues(1, 20);
    SkilletCreateCountSlider:SetValue(1);
    SkilletCreateCountSlider:Show();
    SkilletCreateCountSliderThumb:Show();

    -- Synastria: Enable mouse wheel scrolling on slider (Ctrl+Scroll for +/-10)
    SkilletCreateCountSlider:EnableMouseWheel(true)
    SkilletCreateCountSlider:SetScript("OnMouseWheel", function(self, delta)
        local step = IsControlKeyDown() and 10 or 1
        ---@type number
        local currentValue = self:GetValue()
        ---@type number, number
        local minValue, maxValue = self:GetMinMaxValues()
        ---@type number
        local newValue = currentValue + (delta * step)

        -- Clamp to min/max
        if newValue < minValue then
            newValue = minValue
        elseif newValue > maxValue then
            newValue = maxValue
        end

        self:SetValue(newValue)
        Skillet:UpdateNumItemsSlider(newValue, true)
    end)

    -- Set Clear button handler
    if SkilletEmptyQueueButton then
        SkilletEmptyQueueButton:SetScript("OnClick", function()
            Skillet:EmptyQueue()
            Skillet:UpdateQueueWindow()
            Skillet:Print("|cFFFFAA00Queue cleared!|r")
        end)
    end

    -- Progression status bar
    SkilletRankFrame:SetStatusBarColor(0.2, 0.2, 1.0, 1.0);
    SkilletRankFrameBackground:SetVertexColor(0.0, 0.0, 0.5, 0.2);

    -- The frame enclosing the scroll list needs a border and a background .....
    local backdrop = SkilletSkillListParent
    if backdrop then
        backdrop:SetBackdrop(ControlBackdrop)
        backdrop:SetBackdropBorderColor(0.6, 0.6, 0.6)
        backdrop:SetBackdropColor(0.05, 0.05, 0.05)
        backdrop:SetResizable(true)
    end

    -- Frame enclosing the reagent list
    if SkilletReagentParent then
        backdrop = SkilletReagentParent
        backdrop:SetBackdrop(ControlBackdrop)
        backdrop:SetBackdropBorderColor(0.6, 0.6, 0.6)
        backdrop:SetBackdropColor(0.05, 0.05, 0.05)
        backdrop:SetResizable(true)
    end

    -- Frame enclosing the queue
    backdrop = SkilletQueueParent
    if backdrop then
        backdrop:SetBackdrop(ControlBackdrop)
        backdrop:SetBackdropBorderColor(0.6, 0.6, 0.6)
        backdrop:SetBackdropColor(0.05, 0.05, 0.05)
        backdrop:SetResizable(true)
    end

    -- frame enclosing the pop out notes panel
    backdrop = SkilletRecipeNotesFrame
    if backdrop then
        backdrop:SetBackdrop(ControlBackdrop)
        backdrop:SetBackdropColor(0.1, 0.1, 0.1)
        backdrop:SetBackdropBorderColor(0.6, 0.6, 0.6)
        backdrop:SetResizable(true)
        backdrop:Hide() -- initially hidden
    end

    gearTexture = SkilletReagentParent:CreateTexture(nil, "OVERLAY")
    gearTexture:SetTexture("Interface\\Icons\\Trade_Engineering")
    gearTexture:SetHeight(16)
    gearTexture:SetWidth(16)

    -- Synastria: Create profession selector buttons (from ScootsCraft)
    self:CreateProfessionSelector(frame)

    -- Synastria: Create equipment slot filter (must be before attunability filters)
    if self.CreateSlotFilter then
        self:CreateSlotFilter(frame)
    else
        self:Print("Warning: CreateSlotFilter function not found. SlotFilter.lua may not be loaded.")
    end

    -- Synastria: Create attunability and forge level filters (from ScootsCraft)
    self:CreateAttunabilityFilters(frame)

    -- Ace Window manager library, allows the window position (and size)
    -- to be automatically saved
    local windowManger = AceLibrary("Window-1.0")
    local tradeSkillLocation = {
        prefix = "tradeSkillLocation_"
    }
    windowManger:RegisterConfig(frame, self.db.char, tradeSkillLocation)
    windowManger:RestorePosition(frame) -- restores scale also
    windowManger:MakeDraggable(frame)

    -- lets play the resize me game!
    local minwidth = self:GetMinSkillButtonWidth()
    if not minwidth or minwidth < 165 then
        minwidth = 165
    end
    minwidth = minwidth +           -- minwidth of scroll button
        20 +                        -- padding between sroll and detail
        SKILLET_REAGENT_MIN_WIDTH + -- reagent window (fixed width)
        10                          -- padding about window borders

    self:EnableResize(frame, minwidth, 680, Skillet.UpdateTradeSkillWindow)

    -- Set up the sorting methods here
    self:InitializeSorting()

    return frame
end

-- Resets all the sorting and filtering info for the window
-- This is called when the window has changed enough that
-- sorting or filtering may need to be updated.
function Skillet:ResetTradeSkillWindow()
    Skillet:SortDropdown_OnShow()

    -- Reset all the added buttons so that they look OK.
    local buttons = SkilletFrame.added_buttons
    if buttons then
        -- Synastria: Changed from SkilletRescanButton to SkilletScanAllButton
        -- since ScanAll is now the leftmost button in the top row
        ---@type Frame|nil
        local last_button = SkilletScanAllButton
        for i = 1, #buttons, 1 do
            ---@type Button|nil
            local button = buttons[i]
            if button then
                button:ClearAllPoints()
                button:SetParent("SkilletFrame")
                button:SetPoint("TOPRIGHT", last_button, "TOPLEFT", -5, 0)

                -- Synastria: Reskin external buttons to match our style
                button:SetWidth(100)
                button:SetHeight(22)

                -- Apply UIPanelButtonTemplate styling
                ---@type string|nil
                local buttonName = button:GetName()
                if buttonName then
                    -- Set the button textures to match UIPanelButtonTemplate
                    _G[buttonName .. "Left"]:Hide()
                    _G[buttonName .. "Middle"]:Hide()
                    _G[buttonName .. "Right"]:Hide()
                end

                -- Apply our texture style
                button:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
                button:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
                button:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
                button:SetDisabledTexture("Interface\\Buttons\\UI-Panel-Button-Disabled")

                -- Set proper texture coordinates
                ---@type Texture|nil
                local normalTexture = button:GetNormalTexture()
                if normalTexture then
                    normalTexture:SetTexCoord(0, 0.625, 0, 0.6875)
                end
                ---@type Texture|nil
                local pushedTexture = button:GetPushedTexture()
                if pushedTexture then
                    pushedTexture:SetTexCoord(0, 0.625, 0, 0.6875)
                end
                ---@type Texture|nil
                local highlightTexture = button:GetHighlightTexture()
                if highlightTexture then
                    highlightTexture:SetTexCoord(0, 0.625, 0, 0.6875)
                    highlightTexture:SetBlendMode("ADD")
                end

                -- Set font
                button:SetNormalFontObject("GameFontNormal")
                button:SetHighlightFontObject("GameFontHighlight")
                button:SetDisabledFontObject("GameFontDisable")

                -- Synastria: Change ARL button text from "Scan" to "Ackis Recipes"
                if buttonName and (buttonName:find("ARL") or buttonName:find("Ackis")) then
                    button:SetText("Ackis Recipes")
                elseif button:GetText() == "Scan" then
                    -- Fallback: check if the button text is "Scan" (typical ARL button)
                    button:SetText("Ackis Recipes")
                end

                ---@type Button|nil
                last_button = button
            end
        end
    end
end

-- Something has changed in the tradeskills, and the window needs to be updated
function Skillet:TradeSkillRank_Updated()
    ---@type string|nil, number|nil, number|nil
    local tradeName, rank, maxRank = self:GetTradeSkillLine()

    if rank and maxRank then
        SkilletRankFrame:SetMinMaxValues(0, maxRank);
        SkilletRankFrame:SetValue(rank);
        SkilletRankFrameSkillRank:SetText(rank .. "/" .. maxRank);
    end
end

-- Someone dragged the slider or set the value programatically.
function Skillet:UpdateNumItemsSlider(item_count, clicked)
    local value = floor(item_count + 0.5);

    self.numItemsToCraft = value

    if SkilletCreateCountSlider:IsVisible() then
        SkilletItemCountInputBox:SetText(tostring(value))
        if not clicked then
            SkilletCreateCountSlider:SetValue(value)
        end
    end
end

-- Called when the list of skills is scrolled
function Skillet:SkillList_OnScroll()
    Skillet:UpdateTradeSkillWindow()
end

-- Called when the list of queued items is scrolled
function Skillet:QueueList_OnScroll()
    if Skillet:IsDevMode() then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[QUEUE] QueueList_OnScroll triggered|r")
    end
    Skillet:UpdateQueueWindow()
end

-- Scans tooltip lines of a crafted item link for a given filter string.
-- Lazily creates a hidden reusable scan tooltip on first call.
-- Returns true if any tooltip line contains the filter text.
---@param link string The item link to scan
---@param filter string Lowercase filter string
---@return boolean matched Whether any tooltip line contains the filter
local function scan_tooltip_for_filter(link, filter)
    ---@type Tooltip
    local scanTooltip = (getglobal("SkilletFilterScanTooltip") or
        CreateFrame("GameTooltip", "SkilletFilterScanTooltip", nil, "GameTooltipTemplate")) --[[@as Tooltip]]
    scanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    scanTooltip:SetHyperlink(link)
    for i = 1, scanTooltip:NumLines() do
        local leftText = getglobal("SkilletFilterScanTooltipTextLeft" .. i) --[[@as FontString|nil]]
        if leftText then
            local text = leftText:GetText()
            if text and string.find(string.lower(text), filter, 1, true) ~= nil then
                scanTooltip:Hide()
                return true
            end
        end
        local rightText = getglobal("SkilletFilterScanTooltipTextRight" .. i) --[[@as FontString|nil]]
        if rightText then
            local text = rightText:GetText()
            if text and string.find(string.lower(text), filter, 1, true) ~= nil then
                scanTooltip:Hide()
                return true
            end
        end
    end
    scanTooltip:Hide()
    return false
end

-- Figures out whether or not the section a recipe
-- is in has been hidden (collapsed or filtered).
-- Headers are, by definition never hidden
local function is_hidden_skill(parent, skill_index)
    -- look up the info in stitch to avoid spamming the server with
    -- GetTradeSkillInfo() calls. It does not seem to like that
    ---@type table|nil
    local s = Skillet.stitch:GetItemDataByIndex(parent.currentTrade, skill_index)

    if not s then
        -- it's a header, headers are not skills and can never be hidden
        return false
    end

    -- it's a recipe, is it filtered out?
    -- plain text search only
    ---@type string|nil
    local filtertext = parent:GetTradeSkillOption(parent.currentTrade, "filtertext")
    if filtertext and filtertext ~= "" then
        local matched = false
        local filter = string.lower(filtertext)

        if type(s.name) == "string" then
            local name = string.lower(s.name)
            if string.find(name, filter, 1, true) == nil then
                -- no match against the filter for the item name, check the reagents
                local reagents = s.reagents or {}
                for i = 1, #reagents, 1 do
                    ---@type table|nil
                    local reagent = reagents[i]
                    if reagent and type(reagent.name) == "string" then
                        name = string.lower(reagent.name)
                        if string.find(name, filter, 1, true) ~= nil then
                            matched = true
                            break
                        end
                    end
                end
                if not matched then
                    -- Last resort: scan the crafted item's tooltip text
                    if not (s.link and scan_tooltip_for_filter(s.link, filter)) then
                        return true
                    end
                end
            end
        else
            -- If s.name is not a string, skip filtering by name and only check reagents
            local reagents = s.reagents or {}
            for i = 1, #reagents, 1 do
                ---@type table|nil
                local reagent = reagents[i]
                if reagent and type(reagent.name) == "string" then
                    local name = string.lower(reagent.name)
                    if string.find(name, filter, 1, true) ~= nil then
                        matched = true
                        break
                    end
                end
            end
            if not matched then
                -- Last resort: scan the crafted item's tooltip text
                if not (s.link and scan_tooltip_for_filter(s.link, filter)) then
                    return true
                end
            end
        end
    end

    -- it's a recipe, work backwards to find the section it's
    -- in and see if that has been collapsed.
    for i = skill_index - 1, 0, -1 do
        if Skillet.stitch:GetItemDataByIndex(parent.currentTrade, i) == nil then
            -- found the header
            local skillName, _ = Skillet:GetTradeSkillInfo(i);
            if (parent.headerCollapsedState and parent.headerCollapsedState[skillName]) then
                return true
            end
            break
        end
    end

    -- are we hiding anything that can't be created with the mats on this character?
    -- Synastria: Check resource bank craftability instead of just bank
    local craftable = s.numcraftablewresbank or s.numcraftablewbank or 0
    if craftable == 0 and parent:GetTradeSkillOption(parent.currentTrade, "hideuncraftable") then
        return true
    end

    -- are we hiding anything that is trivial (has no chance of giving a skill point)
    if s.difficulty == "trivial" and parent:GetTradeSkillOption(parent.currentTrade, "hidetrivial") then
        return true
    end

    -- Synastria: Equipment only filter
    if parent:GetTradeSkillOption(parent.currentTrade, "equipmentonly") then
        ---@type string|nil
        local itemLink = parent:GetTradeskillItemLink(skill_index)
        if itemLink then
            ---@type number|nil
            local itemId = parent:GetItemIDFromLink(itemLink)
            if itemId then
                local isEquippable = IsEquippableItem(itemId) or IsEquippableItem(itemLink)
                if not isEquippable then
                    return true
                end
            end
        end
    end

    -- Synastria: Check attunability filter
    if not parent:MatchesAttunabilityFilter(skill_index) then
        return true
    end

    -- Synastria: Check forge level filter
    if not parent:MatchesForgeFilter(skill_index) then
        return true
    end

    -- Synastria: Check equipment slot filter
    if parent.MatchesSlotFilter and not parent:MatchesSlotFilter(skill_index) then
        return true
    end

    return false
end

local function Skillet_redo_the_update(self)
    AceEvent:CancelScheduledEvent("Skillet_redo_the_update")
    self:UpdateTradeSkillWindow()
end

local num_recipe_buttons = 0
local function get_recipe_button(i)
    local button = getglobal("SkilletScrollButton" .. i)
    if not button then
        button = CreateFrame("Button", "SkilletScrollButton" .. i, SkilletSkillListParent, "SkilletSkillButtonTemplate")
        button:SetParent(SkilletSkillListParent)
        button:SetPoint("TOPLEFT", "SkilletScrollButton" .. (i - 1), "BOTTOMLEFT")
        button:SetFrameLevel(SkilletSkillListParent:GetFrameLevel() + 1)
    end
    return button
end

-- Get attunement status indicator for a recipe's crafted item
-- Returns colored indicator like [U], [A], [T], [W], or [L] for equippable items
-- Returns spacing for non-equippable items to preserve recipe name alignment
-- @param itemLink The item link of the crafted item
-- @return string Color-coded attunement indicator, or spacing for alignment
local function get_attunement_indicator(itemLink)
    if not itemLink then
        return "    " -- 4 spaces to match indicator width: [X]
    end

    -- Only show attunement for equippable items
    local itemId = Skillet:GetItemIDFromLink(itemLink)
    if not itemId then
        return "    " -- 4 spaces to match indicator width: [X]
    end

    local isEquippable = IsEquippableItem(itemId) or IsEquippableItem(itemLink)
    if not isEquippable then
        return "    " -- 4 spaces to match indicator width: [X]
    end

    -- Exclude bags/containers - they can't be attuned despite being "equippable"
    local _, _, _, _, _, _, _, _, _, _, _, itemClassID = GetItemInfo(itemId)
    if itemClassID == 1 then -- Container/Bag
        return "    "        -- 4 spaces to match indicator width: [X]
    end

    -- Get forge level
    ---@type number|nil
    local forgeLevel = nil
    if GetItemAttuneForge then
        forgeLevel = GetItemAttuneForge(itemId)
    end

    -- Determine indicator and color based on forge level
    ---@type string
    local indicator = ""
    ---@type number, number, number
    local r, g, b = 1, 1, 1

    if not forgeLevel or forgeLevel == -1 then
        -- Unattuned (nil or -1)
        indicator = "[U]"
        r, g, b = 0.8, 0.8, 0.8
    elseif forgeLevel == 0 then
        -- Attuned (Baseline)
        indicator = "[A]"
        r, g, b = 0.65, 1, 0.5
    elseif forgeLevel == 1 then
        -- Titanforged
        indicator = "[T]"
        r, g, b = 0.5, 0.5, 1
    elseif forgeLevel == 2 then
        -- Warforged
        indicator = "[W]"
        r, g, b = 1, 0.65, 0.5
    elseif forgeLevel >= 3 then
        -- Lightforged
        indicator = "[L]"
        r, g, b = 1, 1, 0.65
    else
        -- Default to unattuned for any unexpected value
        indicator = "[U]"
        r, g, b = 0.8, 0.8, 0.8
    end

    -- Return colored indicator with trailing space (appears before recipe name)
    return string.format("|cff%02x%02x%02x%s|r ",
        math.floor(r * 255),
        math.floor(g * 255),
        math.floor(b * 255),
        indicator)
end

-- shows a recipe button (in the scrolling list) after doing the
-- required callbacks.
local function show_button(button, trade, skill, index)
    -- legacy method
    ---@type Button|nil
    local before = Skillet:BeforeRecipeButtonShow(button, trade, skill, index)
    if before and before ~= button then
        button:Hide()
        button = before
    end

    for i = 1, #pre_show_callbacks, 1 do
        local new_button = pre_show_callbacks[i](button, trade, skill, index)
        if new_button and new_button ~= button then
            button:Hide() -- hide the old one just in case ....
            button = new_button
        end
    end

    button:Show()
end

-- hides a recipe button (in the scrolling list) after doing the
-- required callbacks.
local function hide_button(button, trade, skill, index)
    -- legacy method
    ---@type Button|nil
    local before = Skillet:BeforeRecipeButtonHide(button, trade, skill, index)
    if before and before ~= button then
        button:Hide()
        button = before
    end

    for i = 1, #pre_hide_callbacks, 1 do
        local new_button = pre_hide_callbacks[i](button, trade, skill, index)
        if new_button and new_button ~= button then
            button:Hide() -- hide the old one just in case ....
            button = new_button
        end
    end

    button:Hide()
end

-- Updates the trade skill window whenever anything has changed,
-- number of skills, skill type, skill level, etc
function Skillet:internal_UpdateTradeSkillWindow()
    if not self.currentTrade or self.currentTrade == "UNKNOWN" then
        -- nothing to see, nothing to update
        self:SetSelectedSkill(nil)
        return
    end

    -- Synastria: Update profession button highlighting
    self:UpdateProfessionButtons()

    -- If it's link-able, show the link button.
    if GetTradeSkillListLink() then
        SkilletTradeSkillLinkButton:Show()
    else
        SkilletTradeSkillLinkButton:Hide()
    end

    SkilletFrame:SetAlpha(self.db.profile.transparency)
    SkilletFrame:SetScale(self.db.profile.scale)

    SkilletQueueAllButton:Show()
    SkilletQueueButton:Show()
    SkilletCreateAllButton:Show()
    SkilletCreateButton:Show()
    SkilletCreateCountSlider:Show()
    SkilletCreateCountSliderThumb:Show()
    SkilletItemCountInputBox:Show()
    SkilletQueueParent:Show()
    SkilletStartQueueButton:Show()
    SkilletEmptyQueueButton:Show()

    -- shopping list button always shown
    SkilletShoppingListButton:Show()

    local width = SkilletFrame:GetWidth() - 20 -- for padding.
    local reagent_width = width / 2
    if reagent_width < SKILLET_REAGENT_MIN_WIDTH then
        reagent_width = SKILLET_REAGENT_MIN_WIDTH
    elseif reagent_width > SKILLET_REAGENT_MAX_WIDTH then
        reagent_width = SKILLET_REAGENT_MAX_WIDTH
    end

    SkilletReagentParent:SetWidth(reagent_width)
    SkilletQueueParent:SetWidth(reagent_width)

    local width = SkilletFrame:GetWidth() - reagent_width - 20 -- padding
    SkilletSkillListParent:SetWidth(width)

    -- Set the state of any craft specific options
    SkilletHideTrivialRecipes:SetChecked(self:GetTradeSkillOption(self.currentTrade, "hidetrivial"))
    SkilletHideUncraftableRecipes:SetChecked(self:GetTradeSkillOption(self.currentTrade, "hideuncraftable"))
    -- SkilletEquipmentOnlyRecipes:SetChecked(self:GetTradeSkillOption(self.currentTrade, "equipmentonly"))  -- COMMENTED: Now controlled by forge toggles

    -- Synastria: Update filter dropdown displays to match saved values for this profession
    if self.UpdateSlotFilterUI then
        self:UpdateSlotFilterUI()
    end
    if self.UpdateAttunabilityFilterUI then
        self:UpdateAttunabilityFilterUI()
    end

    self:UpdateQueueWindow()

    ---@type string|nil, number|nil, number|nil
    local _, rank, maxRank = self:GetTradeSkillLine()

    -- Window Title
    local title = getglobal("SkilletTitleText");
    if title then
        title:SetText(GetLocalizedString("Skillet Trade Skills") .. ": " .. self.currentTrade)
    end

    local numTradeSkills = self:GetNumTradeSkills()
    -- Will only sort recipes if something has changed
    -- and there is a sorting method selected.
    self:ResortRecipes()

    -- List of all the reagents we need for all queued recipies
    -- for this player. This is used to ajust the craftable item
    -- count
    ---@type table<any, any>
    local queued_reagents = self:GetReagentsForQueuedRecipes(GetSafePlayerName()) --[[@as table<any, any>]]

    -- Tell the Stitch library about the queued items so it knows how
    -- to adjust its item counts.
    self.stitch:SetReservedReagentsList(queued_reagents);

    -- Progression status bar
    if rank and maxRank then
        SkilletRankFrame:SetMinMaxValues(0, maxRank)
        SkilletRankFrame:SetValue(rank)
        SkilletRankFrameSkillRank:SetText(rank .. "/" .. maxRank)
    end

    local button_count = SkilletSkillList:GetHeight() / SKILLET_TRADE_SKILL_HEIGHT
    button_count = math.floor(button_count)

    -- Update the scroll frame
    FauxScrollFrame_Update(SkilletSkillList, -- frame
        numTradeSkills,                      -- num items
        button_count,                        -- num to display
        SKILLET_TRADE_SKILL_HEIGHT)          -- value step (item height)

    -- Where in the list of skill to start counting.
    local skillOffset = FauxScrollFrame_GetOffset(SkilletSkillList);

    -- Remove any selected highlight, it will be added back as needed
    SkilletHighlightFrame:Hide();

    local nilFound = false
    width = SkilletSkillListParent:GetWidth() - 10
    if SkilletSkillList:IsVisible() then
        -- adjust for the width of the scroll bar, if it is visible.
        width = width - 20
    end
    local max_text_width = width

    -- Iterate through all the buttons that make up the scroll window
    -- and fill them in with data or hide them, as necessary
    for i = 1, button_count, 1 do
        num_recipe_buttons = math.max(num_recipe_buttons, i)

        local skillIndex = i + skillOffset
        local button = get_recipe_button(i)

        button:SetWidth(width)

        -- skip over any hidden skills
        while (skillIndex <= numTradeSkills) do
            -- want to check the mapped name to see it it is hidden
            ---@type number|nil
            local mapped_index = self:GetSortedRecipeIndex(skillIndex)

            -- mapped index may be nil as the sorted_table is smaller than
            -- the standard table (all headers removed)

            if mapped_index and not is_hidden_skill(self, mapped_index) then
                -- nope, not skipping this one
                break
            end

            skillOffset = skillOffset + 1
            skillIndex = i + skillOffset
        end

        if (skillIndex <= numTradeSkills) then
            ---@type number
            skillIndex = self:GetSortedRecipeIndex(skillIndex)

            local skillName, skillType = self:GetTradeSkillInfo(skillIndex)
            if not skillName then
                local s = self.stitch:GetItemDataByIndex(self.currentTrade, skillIndex)
                if s == nil then
                    skillType = "header"
                    skillName = ""
                    nilFound = true
                else
                    skillName = s.name
                end
            end

            local buttonText = getglobal(button:GetName() .. "Name")
            local levelText = getglobal(button:GetName() .. "Level")
            local countText = getglobal(button:GetName() .. "Counts")

            buttonText:SetText("")
            levelText:SetText("")
            countText:SetText("")

            levelText:Hide()
            countText:Hide()

            local skill_color = skill_style_type[skillType]
            if skill_color then
                buttonText:SetTextColor(skill_color.r, skill_color.g, skill_color.b)
                countText:SetTextColor(skill_color.r, skill_color.g, skill_color.b)
            else
                buttonText:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
                countText:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
            end

            if skillType == "header" then
                ---@type boolean
                local collapsed = false;
                if self.headerCollapsedState and self.headerCollapsedState[skillName] then
                    ---@type boolean|nil
                    collapsed = self.headerCollapsedState[skillName]
                end

                if collapsed then
                    -- Collapsed
                    button:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up")
                else
                    -- expanded
                    button:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
                end

                buttonText:SetText(skillName)
                levelText:SetWidth(20)
                buttonText:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)

                button:SetID(-1)
                button:UnlockHighlight() -- headers never get highlighted

                local button_width = button:GetTextWidth()
                ---@type string
                local text = skillName --[[@as string]]
                while button_width > max_text_width do
                    text = string.sub(text, 0, -2)
                    buttonText:SetText(text .. "..")
                    button_width = button:GetTextWidth()
                end

                show_button(button, self.currentTrade, skillIndex, i)
            else
                button:SetNormalTexture("")
                getglobal(button:GetName() .. "Highlight"):SetTexture("")

                local s = self.stitch:GetItemDataByIndex(self.currentTrade, skillIndex)

                ---@type string
                local text = ""
                if s then
                    ---@type string
                    text = text .. (self:GetRecipeNamePrefix(self.currentTrade, skillIndex) or "")

                    -- if the item has a minimum level requirement, then print that here
                    if self.db.profile.display_required_level then
                        local level = self:GetLevelRequiredToUse(s.link)

                        if level and level > 1 then
                            local _, r, g, b = self:GetQualityFromLink(s.link)
                            if r and g and b then
                                levelText:SetTextColor(r, g, b)
                            end
                            levelText:SetText("[" .. level .. "]")
                        end

                        levelText:Show()
                        levelText:SetWidth(25)
                    else
                        levelText:SetWidth(10)
                    end

                    -- Synastria: Add attunement indicator before recipe name (includes trailing space)
                    text = text .. get_attunement_indicator(s.link)

                    ---@type string
                    text = text .. s.name

                    -- Synastria: num already includes resource bank
                    local num, numwbank, numwalts = get_craftable_counts(s)
                    -- Only show counts if the primary count (bags+resbank) is > 0
                    if num > 0 then
                        ---@type string
                        local count = "[" .. num
                        -- only show bank and alt counts if it has been enabled
                        -- through the options.
                        if self.db.profile.show_bank_alt_counts then
                            count = count .. "/" .. numwbank
                            if numwalts then
                                -- only show this if there is a mod installed that
                                -- allows Stitch to collect the information.
                                ---@type string
                                count = count .. "/" .. numwalts
                            end
                        end
                        count = count .. "]"
                        countText:SetText(count)
                        countText:Show()
                    end
                    button:SetID(skillIndex)

                    -- If enhanced recipe display is eanbled, show the difficulty as text,
                    -- rather than as a colour. This should help used that have problems
                    -- distinguishing between the difficulty colours we use.
                    if self.db.profile.enhanced_recipe_display then
                        ---@type string
                        text = text .. skill_color.alttext;
                    end

                    ---@type string
                    text = text .. (self:GetRecipeNameSuffix(self.currentTrade, skillIndex) or "")
                else
                    nilFound = true
                    -- not cached yet
                end

                buttonText:SetText(text)

                -- update the width we use for checking for text truncation
                local button_width = button:GetTextWidth()
                while button_width > max_text_width do
                    text = string.sub(text, 0, -2)
                    button:SetText(text .. "..")
                    button_width = button:GetTextWidth()
                end

                if (self.selectedSkill and self.selectedSkill == skillIndex) then
                    -- user has this skill selected

                    -- This is so mods that call GetTradeSkillSelectionIndex() will work
                    -- tested with ArmorCraft.
                    SelectTradeSkill(self.selectedSkill)

                    SkilletHighlightFrame:SetPoint("TOPLEFT", "SkilletScrollButton" .. i, "TOPLEFT", 0, 0)
                    SkilletHighlightFrame:SetWidth(button:GetWidth())
                    SkilletHighlightFrame:SetFrameLevel(button:GetFrameLevel())

                    if color then
                        SkilletHighlight:SetTexture(color.r, color.g, color.b, 0.4)
                    else
                        SkilletHighlight:SetTexture(0.7, 0.7, 0.7, 0.4)
                    end

                    -- And update the details for this skill, just in case something
                    -- has changed (mats consumed, etc)
                    self:UpdateDetailsWindow(self.selectedSkill)

                    SkilletHighlightFrame:Show()
                    button:LockHighlight()
                else
                    -- not selected
                    button:SetBackdropColor(0.8, 0.2, 0.2);
                    button:UnlockHighlight();
                end

                show_button(button, self.currentTrade, skillIndex, i)
            end
        else
            -- We have no data for you Mister Button .....
            hide_button(button, self.currentTrade, skillIndex, i)
            button:UnlockHighlight()
        end
    end

    -- Hide any of the buttons that we created but don't need right now
    for i = button_count + 1, num_recipe_buttons, 1 do
        local button = get_recipe_button(i)
        hide_button(button, self.currentTrade, 0, i)
    end

    if nilFound then
        if not AceEvent:IsEventScheduled("Skillet_redo_the_update") then
            AceEvent:ScheduleEvent("Skillet_redo_the_update", 0.25, self)
        end
    end
end

-- Display an action packed tooltip when we are over
-- a recipe in the list of skills
---@param id number The recipe index in the currently selected trade
function Skillet:DisplayTradeskillTooltip(id)
    if id < 0 then
        -- it's header or not cached yet.
        return
    end

    if not self.db.profile.show_detailed_recipe_tooltip then
        -- user does not want the tooltip displayed, it can get a bit big after all
        return
    end

    ---@type Tooltip
    local tooltip = SkilletTradeskillTooltip --[[@as Tooltip]]
    tooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT", -300);
    tooltip:SetBackdropColor(0, 0, 0, 1);
    tooltip:ClearLines();
    tooltip:SetClampedToScreen(true)

    -- Set the tooltip's scale to match that of the default UI
    local uiScale = 1.0;
    if (GetCVar("useUiScale") == "1") then
        local scale = tonumber(GetCVar("uiscale"))
        if scale then
            uiScale = scale
        end
    end
    SkilletTradeskillTooltip:SetScale(uiScale)

    ---@type table|nil
    local s = self.stitch:GetItemDataByIndex(self.currentTrade, id)
    if not s then
        -- this can happen when the recipe is not yet cached
        return
    end

    -- Synastria: Show appropriate tooltip based on link type
    ---@type string|nil
    local itemLink = s.link
    if itemLink then
        -- Only convert to simple item link if it's actually an item (not enchant/spell)
        if string.match(itemLink, "^item:") then
            -- It's an item link - extract the item ID to remove craft data
            local itemID = self:GetItemIDFromLink(itemLink)
            if itemID then
                -- Construct a clean item link without craft data
                local cleanLink = "item:" .. itemID
                tooltip:SetHyperlink(cleanLink)
            else
                -- Fallback to original link if extraction fails
                tooltip:SetHyperlink(itemLink)
            end
        else
            -- It's an enchant/spell/other link - use it directly
            tooltip:SetHyperlink(itemLink)
        end
    end

    -- Synastria: num already includes resource bank (bags+resbank)
    local num, numwbank, numwalts = get_craftable_counts(s)

    -- how many can be created with the reagents in your inventory (includes resource bank)
    if num > 0 then
        ---@type string
        local text = "\n" .. num .. " " .. GetLocalizedString("can be created from reagents in your inventory");
        tooltip:AddLine(text, 1, 1, 1, 0); -- (text, r, g, b, wrap)
    end
    -- how many can be created with the reagent in your inv + bank + resource bank
    if self.db.profile.show_bank_alt_counts and numwbank > 0 and numwbank ~= num then
        ---@type string
        local text = numwbank .. " " .. GetLocalizedString("can be created from reagents in your inventory and bank");
        if num == 0 then
            text = "\n" .. text;
        end
        tooltip:AddLine(text, 1, 1, 1, 0); -- (text, r, g, b, wrap)
    end
    -- how many can be crafted with reagents on *all* alts, including this one.
    if self.db.profile.show_bank_alt_counts and numwalts and numwalts > 0 and numwalts ~= num then
        ---@type string
        local text = numwalts .. " " .. GetLocalizedString("can be created from reagents on all characters");
        if num and numwbank == 0 then
            text = "\n" .. text;
        end
        tooltip:AddLine(text, 1, 1, 1, 0); -- (text, r, g, b, wrap)
    end

    tooltip:AddLine("\n" .. self:GetReagentLabel(self.currentTrade, id));

    -- now the list of reagents for this recipe and some info about them
    -- Synastria: Use modern reagents table format
    local reagents = s.reagents or {}
    for i = 1, #reagents, 1 do
        ---@type table|nil
        local reagent = reagents[i];
        if not reagent then
            break
        end

        local text = "  " .. (reagent and reagent.needed or "?") .. " x " .. (reagent and reagent.name or "?");
        -- Synastria: Updated for new architecture where num always includes resource bank
        -- Display format: (bags+resbank / bank)
        local reagent_counts = GRAY_FONT_COLOR_CODE ..
            " (" ..
            (reagent and reagent.num or 0) ..
            " / " .. ((reagent and reagent.numwbank or 0) - (reagent and reagent.num or 0))
        if reagent and reagent.numwalts and reagent.numwbank then
            reagent_counts = reagent_counts .. " / " .. math.max(0, reagent.numwalts - reagent.numwbank)
        end
        reagent_counts = reagent_counts .. ")" .. FONT_COLOR_CODE_CLOSE
        if reagent and reagent.vendor == true then
            text = text .. GRAY_FONT_COLOR_CODE .. "  (" .. GetLocalizedString("buyable") .. ")" .. FONT_COLOR_CODE_CLOSE;
        end

        tooltip:AddDoubleLine(text, reagent_counts, 1, 1, 1);
    end

    -- The legend at the bottom
    ---@type string
    local text = "(" .. GetLocalizedString("reagents in inventory") .. " / " .. GetLocalizedString("bank")
    -- Synastria: Add resource bank to legend
    if s.numcraftablewresbank ~= nil then
        text = text .. " / " .. GetLocalizedString("resbank")
    end
    if s.numcraftablewalts ~= nil then
        text = text .. " / " .. GetLocalizedString("alts")
    end
    text = text .. ")"
    tooltip:AddDoubleLine("\n", text)

    -- Do any mods want to add extra info about this recipe?
    local extra_text = self:GetExtraItemDetailText(self.currentTrade, id)
    if extra_text then
        tooltip:AddLine("\n" .. extra_text)
    end

    tooltip:Show();
end

-- Sets the game tooltip item to the selected skill
-- (and reagent at index if not nil)
function Skillet:SetTradeSkillToolTip(skill, index)
    ---@type Tooltip
    GameTooltip:ClearLines();

    -- Call SetTradeSkillItem to populate the tooltip
    if index then
        GameTooltip:SetTradeSkillItem(skill, index)
    else
        GameTooltip:SetTradeSkillItem(skill)
    end

    ---@type table|nil
    local s = self.stitch:GetItemDataByIndex(self.currentTrade, skill);
    if not s then return end

    ---@type table[]
    local reagents = s.reagents or {}

    -- Can the item be obtained from a vendor? Let the user know!
    if index and reagents[index] and reagents[index].vendor == true then
        GameTooltip:AppendText(GRAY_FONT_COLOR_CODE ..
            " (" .. GetLocalizedString("buyable") .. ")" .. FONT_COLOR_CODE_CLOSE);
    end
end

-- Updates the details window with information about the currently selected skill
function Skillet:UpdateDetailsWindow(skill_index)
    -- If no skill is selected, just hide content but keep panel background visible
    if not skill_index then
        -- Hide the content but keep the frame itself visible (for background)
        if SkilletSkillName then SkilletSkillName:Hide() end
        if SkilletRequirementLabel then SkilletRequirementLabel:Hide() end
        if SkilletRequirementText then SkilletRequirementText:Hide() end
        if SkilletSkillCooldown then SkilletSkillCooldown:Hide() end
        if SkilletReagentLabel then SkilletReagentLabel:Hide() end
        if SkilletSkillIcon then SkilletSkillIcon:Hide() end
        if _G.SkilletRecipeNotesButton then _G.SkilletRecipeNotesButton:Hide() end
        if _G.SkilletDebugButton then _G.SkilletDebugButton:Hide() end

        -- Hide all reagent buttons
        for i = 1, 8 do
            ---@type Button|nil
            local button = _G["SkilletReagent" .. i]
            if button then
                button:Hide()
            end
        end
        return
    end

    -- Show the content since a recipe is selected
    if SkilletSkillName then SkilletSkillName:Show() end
    if SkilletReagentLabel then SkilletReagentLabel:Show() end
    if SkilletSkillIcon then SkilletSkillIcon:Show() end
    if _G.SkilletRecipeNotesButton then _G.SkilletRecipeNotesButton:Show() end
    if _G.SkilletDebugButton then _G.SkilletDebugButton:Show() end

    -- Get the recipe data
    ---@type table|nil
    local recipe = self.stitch:GetItemDataByIndex(self.currentTrade, skill_index)
    if not recipe then
        -- Hide content if recipe data not available
        if SkilletSkillName then SkilletSkillName:Hide() end
        if SkilletRequirementLabel then SkilletRequirementLabel:Hide() end
        if SkilletRequirementText then SkilletRequirementText:Hide() end
        if SkilletSkillCooldown then SkilletSkillCooldown:Hide() end
        if SkilletReagentLabel then SkilletReagentLabel:Hide() end
        if SkilletSkillIcon then SkilletSkillIcon:Hide() end
        if _G.SkilletRecipeNotesButton then _G.SkilletRecipeNotesButton:Hide() end
        if _G.SkilletDebugButton then _G.SkilletDebugButton:Hide() end
        return
    end

    -- Update skill name
    if SkilletSkillName then
        SkilletSkillName:SetText(recipe.name or "")
    end

    -- Update requirement text (for tools, etc)
    if SkilletRequirementLabel then
        SkilletRequirementLabel:SetText("")
    end
    if SkilletRequirementText then
        SkilletRequirementText:SetText("")
    end

    -- Update reagent list display
    if SkilletReagentLabel then
        SkilletReagentLabel:SetText(GetLocalizedString("Reagents:"))
        SkilletReagentLabel:Show()
    end

    -- Update skill icon
    if SkilletSkillIcon then
        if recipe.link then
            local icon = GetItemIcon(recipe.link)
            if icon then
                SkilletSkillIcon:SetNormalTexture(icon)
            end
        end
        SkilletSkillIcon:Show()
    end

    -- Populate reagent buttons with reagent data
    ---@type table[]
    local reagents = recipe.reagents or {}
    for i = 1, 8 do
        ---@type Button|nil
        local button = _G["SkilletReagent" .. i]
        if button then
            ---@type table|nil
            local reagent = reagents[i]
            if reagent then
                -- Update reagent name text (left side) with "Nx " prefix
                ---@type FontString|nil
                local text_frame = getglobal(button:GetName() .. "Text")
                if text_frame then
                    local needed = reagent.needed or 0
                    local display_text = needed .. " x " .. (reagent.name or "?")
                    text_frame:SetText(display_text)
                    text_frame:Show()
                end

                -- Update count display (right side): "needed / available / craftable"
                ---@type FontString|nil
                local count_frame = getglobal(button:GetName() .. "Count")
                if count_frame then
                    -- Display format: needed / available / craftable
                    -- num = bags+resbank, numwbank = bags+bank+resbank
                    local needed = reagent.needed or 0
                    local available = (reagent.num or 0)

                    -- Check if reagent is craftable and calculate how many we can craft
                    local craftable_count = 0
                    local reagent_item = self.stitch:GetItemDataByName(reagent.name or "")
                    if reagent_item and reagent_item.numcraftable then
                        craftable_count = reagent_item.numcraftable
                    end

                    -- Determine color based on availability
                    local total_with_craftable = available + craftable_count
                    if available >= needed then
                        -- Have enough in inventory - show in green
                        count_frame:SetTextColor(0.25, 0.75, 0.25)
                    elseif total_with_craftable >= needed then
                        -- Have enough including craftable - show in soft light blue
                        count_frame:SetTextColor(0.5, 0.75, 1.0)
                    elseif available > 0 then
                        -- Have some but not enough - show in yellow/orange
                        count_frame:SetTextColor(1.0, 1.0, 0.0)
                    else
                        -- Have none - show in red
                        count_frame:SetTextColor(1.0, 0.25, 0.25)
                    end

                    -- Build display text
                    ---@type string
                    local display_text
                    if craftable_count > 0 then
                        display_text = needed .. " / " .. available .. " / " .. craftable_count
                    else
                        display_text = needed .. " / " .. available
                    end

                    count_frame:SetText(display_text)
                    count_frame:Show()
                end

                -- Update icon texture
                ---@type Button|nil
                local icon_button = getglobal(button:GetName() .. "Icon")
                if icon_button then
                    if reagent.link then
                        local icon = GetItemIcon(reagent.link)
                        if icon then
                            icon_button:SetNormalTexture(icon)
                        end
                    end
                    icon_button:Show()
                end

                button:Show()
            else
                -- Hide unused reagent buttons
                if button then
                    button:Hide()
                end
            end
        end
    end
end

-- When one of the skill buttons in the left scroll pane is clicked
function Skillet:SkillButton_OnClick(button)
    if (button == "LeftButton") then
        ---@type number
        local id = this:GetID();
        if id == -1 then
            -- header clicked / toggle collapsed state
            local buttonText = getglobal(this:GetName() .. "Name")
            ---@type string
            local header = buttonText:GetText()
            ---@type boolean|nil
            local state = self.headerCollapsedState[header]

            if not state or state == false then
                ---@type boolean
                self.headerCollapsedState[header] = true
            else
                ---@type boolean
                self.headerCollapsedState[header] = false
            end
        else
            -- skill clicked
            self:SetSelectedSkill(id, true);

            -- Synastria: Ctrl+Click to queue item directly
            if IsControlKeyDown() then
                local recipe = self.stitch:GetItemDataByIndex(self.currentTrade, id)
                if recipe then
                    -- Queue 1 of this item
                    self:QueueItems()
                    if self:IsDevMode() then
                        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00Added to queue: " .. (recipe.name or "Unknown") .. "|r")
                    end
                end
                -- if it was shift-left clicked *and* there is a chat edit
                -- window open, insert the recipe link.
            elseif IsShiftKeyDown() and (ChatFrameEditBox:IsVisible() or WIM_EditBoxInFocus ~= nil) then
                ChatEdit_InsertLink(self:GetTradeSkillRecipeLink(id));
            end
        end

        self:UpdateTradeSkillWindow()
    end
end

-- Go to the previous recipe in the history list.
function Skillet:GoToPreviousRecipe()
    local itemID = table.remove(previousRecipies)
    if itemID then
        self:SetSelectedSkill(itemID);
    end
end

-- Called when then mouse enters a reagent button
---@param button table The reagent button frame
---@param skill number The recipe index
---@param index number The reagent button index (1-8)
function Skillet:ReagentButtonOnEnter(button, skill, index)
    if not self.db.profile.link_craftable_reagents then
        return
    end

    -- Validate parameters
    if not skill or not index or type(skill) ~= "number" or type(index) ~= "number" then
        return
    end

    -- Validate currentTrade is set
    if not self.currentTrade or type(self.currentTrade) ~= "string" then
        return
    end

    ---@type table|nil
    local s = self.stitch:GetItemDataByIndex(self.currentTrade, skill)
    if not s then return end

    ---@type table[]
    local reagents = s.reagents or {}
    ---@type table|nil
    local reagent = reagents[index]

    if not reagent or not reagent.name then return end

    local can_craft = self.stitch:GetItemDataByName(reagent.name)
    if can_craft and gearTexture then
        ---@type Texture|nil
        local icon = getglobal(button:GetName() .. "Icon")
        if icon then
            -- Show gear texture overlay to indicate craftable
            gearTexture:SetParent(icon)
            gearTexture:ClearAllPoints()
            gearTexture:SetPoint("TOPLEFT", icon)
            gearTexture:Show()
        end
    end
end

-- called then the mouse leaves a reagent button
function Skillet:ReagentButtonOnLeave(button, skill, index)
    if gearTexture then
        gearTexture:Hide()
    end
end

-- Called when the reagent button is clicked
---@param button table The reagent button frame
---@param skill number The recipe index
---@param index number The reagent button index (1-8)
function Skillet:ReagentButtonOnClick(button, skill, index)
    if not self.db.profile.link_craftable_reagents then
        return
    end

    -- current recipe -> selected reagent --> reagent item link
    ---@type table|nil
    local s = self.stitch:GetItemDataByIndex(self.currentTrade, skill)
    if not s then return end

    ---@type table[]
    local reagents = s.reagents or {}
    if not reagents[index] then return end

    ---@type table|nil
    local reagent = self.stitch:GetItemDataByName(reagents[index].name)

    if reagent then
        -- we know how to make this, we just need to figure out
        -- what the *index* of the item is. That is not stored in
        -- the stitch library.

        for i = 1, self:GetNumTradeSkills(), 1 do
            ---@type table|nil
            local item = self.stitch:GetItemDataByIndex(self.currentTrade, i)
            if item and item.link == reagent.link then
                table.insert(previousRecipies, skill)
                if gearTexture then
                    gearTexture:Hide()
                end
                self:SetSelectedSkill(i)
                return
            end
        end
    end
end

-- The start/pause queue button.
function Skillet:StartQueue_OnClick(button)
    if self.stitch.queuecasting then
        self.stitch.queuecasting = false
        self.stitch:CancelCast() -- next update will reset the text
        button:Disable()
    else
        -- Synastria: Check if first queue item is a conversion
        if self.stitch.queue and self.stitch.queue[1] then
            local queueItem = self.stitch.queue[1]

            -- Handle conversion recipes with automated withdraw/use/deposit
            if queueItem.profession == "Conversion" or (queueItem.recipe and queueItem.recipe.isVirtualConversion) then
                if queueItem.recipe and queueItem.recipe.sourceId and queueItem.recipe.outputId then
                    self:ProcessConversion(queueItem.recipe)
                else
                    self:Print("|cFFFF0000Invalid conversion data|r")
                end
                return
            end

            -- Normal crafting: show the unified crafting prompt dialog
            self:ShowStartCraftingPrompt()
        end
    end
end

-- Updates the "Scanning tradeskill" text area with provided text
-- Set nil/empty text to hide the area
function Skillet:UpdateScanningText(text)
    local area = getglobal("SkilletFrameScanningText")
    if area then
        if text and string.len(text) > 0 then
            area:SetText(text)
            area:Show()
        else
            area:Hide()
        end
    end
end

---@type table
local orig_tradeskill_settings = {}
---@type table
local orig_craft_settings = {}

-- Hides a Blizzard tradeskill or craft skill frame by making
-- it transparent, setting it to the background, and attaching
-- it to the Skillet frame
local function hide_blizz(frame, settings)
    ---@type string
    settings["strata"] = frame:GetFrameStrata()
    ---@type number
    settings["alpha"]  = frame:GetAlpha()
    ---@type number
    settings["width"]  = frame:GetWidth()
    ---@type number
    settings["height"] = frame:GetHeight()

    frame:SetAlpha(0)
    frame:SetFrameStrata("BACKGROUND")
    frame:SetPoint("TOPLEFT", SkilletFrame, "TOPLEFT", 5, -5)
    frame:SetWidth(5)
    frame:SetHeight(5)
end

-- restores a Blizzard trade or craft skill frame from the
-- provided settings.
local function restore_blizz(frame, settings)
    if settings["alpha"] then
        frame:SetAlpha(settings["alpha"])
    end
    if settings["strata"] then
        frame:SetFrameStrata(settings["strata"])
    end
    if settings["width"] then
        frame:SetWidth(settings["width"])
    end
    if settings["height"] then
        frame:SetHeight(settings["height"])
    end
    frame:ClearAllPoints()
end

-- Updates all UI button labels and text with localized strings
---@return nil
function Skillet:UpdateUILabels()
    -- Button labels
    if _G.SkilletRescanButton then _G.SkilletRescanButton:SetText(GetLocalizedString("Rescan")) end
    if _G.SkilletScanAllButton then _G.SkilletScanAllButton:SetText(GetLocalizedString("Scan All")) end
    if _G.SkilletRecipeNotesButton then _G.SkilletRecipeNotesButton:SetText(GetLocalizedString("Notes")) end
    if _G.SkilletGroupQueueButton then _G.SkilletGroupQueueButton:SetText(GetLocalizedString("Optimize")) end
    if _G.SkilletShoppingListButton then _G.SkilletShoppingListButton:SetText(GetLocalizedString("Shopping List")) end
    if _G.SkilletShowExtractionButton then _G.SkilletShowExtractionButton:SetText(GetLocalizedString("Extraction")) end
    if _G.SkilletShowOptionsButton then _G.SkilletShowOptionsButton:SetText(GetLocalizedString("Options")) end

    -- FontString labels
    if _G.SkilletRequirementLabel then _G.SkilletRequirementLabel:SetText(GetLocalizedString("Requires:")) end
    if _G.SkilletReagentLabel then _G.SkilletReagentLabel:SetText(GetLocalizedString("Reagents:")) end
end

-- Called when the trade skill window is shown
function Skillet:Tradeskill_OnShow()
    -- Get rid of Blizzards windows. This can happen when the user
    -- changes from a skill that we do not support to one that we do.
    if TradeSkillFrame and TradeSkillFrame:IsVisible() then
        -- Can't really hide the frame as that has some nasty side effects
        -- like setting the current craft to UNKNOWN and causing bad results
        -- from GetTradeSkillLine() et al.
        hide_blizz(TradeSkillFrame, orig_tradeskill_settings)
    end

    -- Need to hook this so that hitting [ESC] will close the Skillet window(s).
    if not old_CloseSpecialWindows then
        old_CloseSpecialWindows = CloseSpecialWindows
        CloseSpecialWindows = function()
            ---@type boolean|nil
            local found = old_CloseSpecialWindows and old_CloseSpecialWindows()
            return self:HideAllWindows() or found
        end
    end
end

-- Called when the trade skill window is hidden
function Skillet:Tradeskill_OnHide()
    -- Clear reagent buttons when closing window
    for i = 1, 8 do
        ---@type Button|nil
        local button = _G["SkilletReagent" .. i]
        if button then
            button:Hide()
        end
    end

    if TradeSkillFrame then
        restore_blizz(TradeSkillFrame, orig_tradeskill_settings)
    end
end
