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

--[[

This file contains functions intended to be used by authors of other mods.
I will make every effort never to change the names or behaviour of any of the
methods listed in this file. All bets are off for methods in other files though.

If you would like to see a method added here that would benefit your mod, by all
means contact me and let me know.

Hooking a Method Using AceHook
------------------------------

To hook this routine with an Ace2 mod, use (for example):

    self:Hook(Skillet, "GetExtraItemDetailText")

and write your method:

    function MyMod:GetExtraItemDetailText(obj, tradeskill, skill_index)
        -- get the previous value from the hook chain
        local before = self.hooks["GetExtraItemDetailText"](obj, tradeskill, skill_index)
        local myvalue = "samplething"
        if before then
            return before .. "\n" .. myvalue
        else
            return myvalue
        end
    end

Hooking a Method Without Using AceHook
--------------------------------------

local orig_get_extra = Skillet.GetExtraItemDetailText
Skillet.GetExtraItemDetailText = function(obj, tradeskill, skill_index)
    local before = orig_get_extra(obj, tradeskill, skill_index)
    local myvalue = "samplething"
    if before then
        return before .. "\n" .. myvalue
    else
        return myvalue
    end
end

In both methods, the 'obj' passed in will be a copy of the 'Skillet' main object.

Of course, the action you take with the previous value is entirely dependent
of what the method does. For methods that return text, you should probably
concatenetate the values. For something like Skillet:GetMinSkillButtonWidth()
you should return the maximum of the previous value and you value.

Please remember that there may be multple mods hooking these methods so please
be courteous and make sure not to discard their data, but rather combine it with
your own in as sane a fashion as possible.

]]

local function tradejunkie_custom_add()
    if TradeJunkieMain and TJ_OpenButtonTradeSkill then
        -- Override the default action of the button to attach it
        -- to our window, rather than the Blizzard trade skill window
        TJ_OpenButtonTradeSkill:SetScript("OnClick", function()
            TradeJunkie_Attach("SkilletFrame")
            TradeJunkieMain:SetPoint("TOPLEFT", "SkilletFrame", "TOPRIGHT", 0, 0)
        end)
    end
end

local function armorcraft_custom_add()
    if AC_Craft and AC_UseButton and AC_ToggleButton then
        AC_Craft:SetParent("SkilletFrame")
        AC_Craft:SetPoint("TOPLEFT", "SkilletFrame", "TOPRIGHT", 0, 0)
        AC_Craft:SetAlpha(1.0)
    end
end

local function Skillet_NOP()
    -- do nothing!
end

--=================================================================================
--                ******* Start of the public API ********
--=================================================================================

-- Adds a button to the tradeskill window. The button will be
-- reparented and placed appropriately in the window.
--
-- You should not hook this method, you should call it directly.
--
-- The frame representing the main tradeskill window will be
-- returned in case you need to pop up a frame attached to it.
function Skillet:AddButtonToTradeskillWindow(button)
    if not SkilletFrame.added_buttons then
        SkilletFrame.added_buttons = {}
    end

    if TJ_OpenButtonTradeSkill and button == TJ_OpenButtonTradeSkill then
        tradejunkie_custom_add()
    elseif AC_UseButton and button == AC_UseButton then
        armorcraft_custom_add()
    end

    -- See if this button has already been added ....
    for i = 1, #SkilletFrame.added_buttons, 1 do
        if SkilletFrame.added_buttons[i] == button then
            -- ... yup
            return SkilletFrame
        end
    end

    -- ... nope
    table.insert(SkilletFrame.added_buttons, button)
    return SkilletFrame
end

--
-- Adds a sort method to those used for recipe names.
--
-- You should not hook this method, you should call it directly.
--
-- With this method you can add your own custom sorting to the
-- list of recipes in the scrolling list.
--
-- @param text The name of you sorting method, will be shown to the
--        user in a drop-down menu
-- @param method Your sorting method (described below)
--
-- Your sorting method must have the following signature
--
--    function sort(tradeskill, index_a, index_b)
--
-- where:
--    tradeskill is the name of the currently selected tradeskill
--    index_a in the skill index of the first recipe
--    index_b is the skill index of the second recipe
--
-- Your method must return 'true' if a should be before b and 'false'
-- if a should be after b.
--
function Skillet:AddRecipeSorter(text, sorter)
    self:internal_AddRecipeSorter(text, sorter)
end

--
-- A hook to get the reagent label
--
-- Refer to the notes at the top of this file for how to hook this method.
--
-- @param tradeskill name of the currently selected tradeskill
-- @param skill_index the index of the currently selected recipe
--
function Skillet:GetReagentLabel(tradeskill, skill_index)
    if (FRC_PriceSource ~= nil and FRC_CraftFrame_SetSelection and FRC_TradeSkillFrame_SetSelection) then
        -- Support for Fizzwidget's Reagent Cost
        local Orig_TradeSkillFrame_SetSelection = FRC_Orig_TradeSkillFrame_SetSelection
        FRC_Orig_TradeSkillFrame_SetSelection = Skillet_NOP
        FRC_TradeSkillFrame_SetSelection(skill_index)
        FRC_Orig_TradeSkillFrame_SetSelection = Orig_TradeSkillFrame_SetSelection
        return TradeSkillReagentLabel:GetText()
    else
        -- boring
        return SPELL_REAGENTS;
    end
end

--
-- A hook to get text to prefix the name of the recipe in the scrolling list of recipes.
-- If you hook this method, make sure to include any text you get from calling the hooked method.
-- This will allow more than one mod to use the hook.
--
-- Refer to the notes at the top of this file for how to hook this method.
--
-- @param tradeskill name of the currently selected tradeskill
-- @param skill_index the index of the currently selected recipe
--
function Skillet:GetRecipeNamePrefix(tradeskill, skill_index)
end

--
-- A hook to get text to append to the name of the recipe in the scrolling list of recipes
-- If you hook this method, make sure to include any text you get from calling the hooked method.
-- This will allow more than one mod to use the hook.
--
-- Refer to the notes at the top of this file for how to hook this method.
--
-- @param tradeskill name of the currently selected tradeskill
-- @param skill_index the index of the currently selected recipe
--
function Skillet:GetRecipeNameSuffix(tradeskill, skill_index)
end

--
-- A hook to display extra information about a recipe. Any text returned from this function
-- will be displayed in the recipe details frame when the user clicks on the recipe name.
-- The text will be added to the bottom the frame, after the list of reagents.
--
-- Refer to the notes at the top of this file for how to hook this method.
--
-- @param tradeskill name of the currently selected tradeskill
-- @param skill_index the index of the currently selected recipe
--
function Skillet:GetExtraItemDetailText(tradeskill, skill_index)
end

--
-- Returns the minimum width of the skill button. This is the
-- button that displays the name of the recipe in the scrolling
-- list. If you was to add text to the button and need more room,
-- then hook this method and return a minimum width for the button
-- that works for your mod.
--
-- The hard limit is 165, any size below this will be ignored
--
-- Refer to the notes at the top of this file for how to hook this method.
--
-- @return the minimum width allow for a recipe button
--
function Skillet:GetMinSkillButtonWidth()
end

--
-- Called immediately before the button containng the name of a
-- tradeskill recipe is displayed in the scrolling list
--
-- The value you return from this method (if not nil) will have it's
-- :Show() method called. You can return the button based in to have
-- Skillet's button shown, or you can return your own button.
--
-- If you return your own button, you are responsible for attaching
-- properly in the list. The list_offset parameter might be useful
-- here as you could use this to determine the name of the button
-- immediately before this one in the list and attach to it.
--
-- Refer to the notes at the top of this file for how to hook this method.
--
-- @param button the button that is about to be displayed
-- @param tradeskill the name of the currently selected tradeskill
-- @param skill_index the index of recipe thius button is used for
-- @param list_offset how far down in the scrolling this button is located.
--        No matter where the list is scrolled to, the first visible recipe
--        is at list_offset 0
--
-- @return a button who's :Show() method is to be called. Use nil to have
--         the default button used.
--
function Skillet:BeforeRecipeButtonShow(button, tradeskill, skill_index, list_offset)
    -- these tests are in here to make sure that I don't
    -- accidentally break the hooking code.
    assert(button, "Button cannot be nil")
    assert(tradeskill and tostring(tradeskill), "Tradeskill cannot be nil")
    assert(skill_index and tonumber(skill_index) and skill_index > 0, "Recipe index cannot be nil")
    assert(list_offset and tonumber(list_offset) and list_offset > 0, "List offset cannot be nil")

    return button
end

--
-- Called immediately before the button containing the name of a
-- tradeskill recipe is hidden in the scrolling list
--
-- The value you return from this method (if not nil) will have it's
-- :Hide() method called. You can return the button based in to have
-- Skillet's button hidden, or you can return your own button.
--
-- If you return your own button, you are responsible for attaching
-- properly in the list. The list_offset parameter might be useful
-- here as you could use this to determine the name of the button
-- immediately before this one in the list and attach to it.
--
-- Refer to the notes at the top of this file for how to hook this method.
--
-- @param button the button that is about to be hidden
-- @param tradeskill the name of the currently selected tradeskill
-- @param skill_index the index of the recipe this button is used for
-- @param list_offset how far down in the scrolling this button is located.
--        No matter where the list is scrolled to, the first visible recipe
--        is at list_offset 0
--
-- @return a button who's :Hide() method is to be called. Use nil to have
--         the default button used.
--
function Skillet:BeforeRecipeButtonHide(button, tradeskill, skill_index, list_offset)
    -- these tests are in here to make sure that I don't
    -- accidentally break the hooking code.
    assert(button, "Button cannot be nil")
    assert(tradeskill and tostring(tradeskill), "Tradeskill cannot be nil")
    assert(skill_index and tonumber(skill_index) and skill_index >= 0, "Recipe index cannot be nil")
    assert(list_offset and tonumber(list_offset) and list_offset >= 0, "List offset cannot be nil")

    return button
end

--
-- Adds a method that will be called before a button in the recipe list
-- is shown. If multiple methods are added, they will be called in the
-- order they are registered.
--
-- The method you provide *must* have the following signature and behaviour:
--
--   function yourfunc(button, tradeskill, skill_index, list_offset)
--
--     where:
--        o button the button that is about to be displayed
--        o tradeskill the name of the currently selected tradeskill
--        o skill_index the index of recipe thius button is used for
--        o list_offset how far down in the scrolling this button is located.
--          No matter where the list is scrolled to, the first visible recipe
--          is at list_offset 0
--
--     returns:
--        the button who's :Show() method is to be called
--
-- If you return your own button (instead of returning the button passed in),
-- you are responsible for attaching it properly in the list. The list_offset
-- parameter might be useful here as you could use this to determine the name
-- of the button immediately before this one in the list and attach to it.
--
function Skillet:AddPreButtonShowCallback(method)
    assert(method and type(method) == "function",
        "Usage: Skillet:AddPreButtonShowCallback(method). method must be a non-nil function")
    self:internal_AddPreButtonShowCallback(method)
end

--
-- Adds a method that will be called before a button in the recipe list
-- is hidden. If multiple methods are added, they will be called in the
-- order they are registered.
--
-- The method you provide *must* have the following signature and behaviour:
--
--   function yourfunc(button, tradeskill, skill_index, list_offset)
--
--     where:
--        o button the button that is about to be displayed
--        o tradeskill the name of the currently selected tradeskill
--        o skill_index the index of recipe thius button is used for
--        o list_offset how far down in the scrolling this button is located.
--          No matter where the list is scrolled to, the first visible recipe
--          is at list_offset 0
--
--     returns:
--        the button who's :Hide() method is to be called
--
-- If you return your own button (instead of returning the button passed in),
-- you are responsible for attaching it properly in the list. The list_offset
-- parameter might be useful here as you could use this to determine the name
-- of the button immediately before this one in the list and attach to it.
--
function Skillet:AddPreButtonHideCallback(method)
    assert(method and type(method) == "function",
        "Usage: Skillet:AddPreButtonShowCallback(method). method must be a non-nil function")
    self:internal_AddPreButtonHideCallback(method)
end

--
-- Shows the trade skill frame for the currently selected tradeskill or craft.
--
-- Refer to the notes at the top of this file for how to hook this method.
-- If you do not (eventually) call the hooked method from your method, the
-- window will not be shown.
--
function Skillet:ShowTradeSkillWindow()
    return self:internal_ShowTradeSkillWindow()
end

--
-- Hides the Skillet trade skill window. Does nothing if the window is not visible
--
-- Refer to the notes at the top of this file for how to hook this method.
-- If you do not (eventually) call the hooked method from your method, the
-- window will not be hidden.
--
--
function Skillet:HideTradeSkillWindow()
    return self:internal_HideTradeSkillWindow()
end

--
-- Called to update the trade skill window. This will redraw the main
-- tradeskill window with the current settings.
--
-- Refer to the notes at the top of this file for how to hook this method.
-- If you do not (eventually) call the hooked method from your method, the
-- window will not be updated.
--
function Skillet:UpdateTradeSkillWindow()
    return self:internal_UpdateTradeSkillWindow()
end

--
-- Updates the queue window display (scrolling list of queued recipes)
--
---@return nil
function Skillet:UpdateQueueWindow()
    -- OPTIMIZATION: Skip UI updates during bulk queue operations
    if self.suppressQueueUpdates then
        return
    end

    -- Refresh queue display: show/hide buttons and populate with data
    -- This is called when the queue list scrolls or changes
    if not SkilletQueueList then
        return
    end

    -- Get queue data from SkilletStitch - simple array of queue entries
    if not self.stitch or not self.stitch.queue then
        return
    end

    ---@type table
    local queues = self.stitch.queue
    local queueCount = #queues

    local buttonHeight = SKILLET_TRADE_SKILL_HEIGHT or 16
    local listHeight = SkilletQueueList:GetHeight()

    -- Calculate how many items can fit, with minimum of 1
    local numVisible = math.max(1, math.floor(listHeight / buttonHeight))
    local offset = FauxScrollFrame_GetOffset(SkilletQueueList)

    -- Update the scroll frame with total queue count
    FauxScrollFrame_Update(SkilletQueueList, queueCount, numVisible, buttonHeight)

    -- Ensure button 1 exists and has correct parent
    local button1 = getglobal("SkilletQueueButton1") --[[@as Frame|nil]]
    if button1 then
        button1:SetParent(SkilletQueueParent)

        -- IMPORTANT: Fix the template-created FontStrings to match dynamic button properties
        -- The XML template has wrong defaults (height=0, anchor=LEFT, justifyH=LEFT)
        local count1Text = getglobal("SkilletQueueButton1CountText") --[[@as FontString|nil]]
        if count1Text then
            count1Text:SetHeight(16)
            count1Text:SetPoint("RIGHT", getglobal("SkilletQueueButton1Count"), "RIGHT", 0, 0)
            count1Text:SetJustifyH("RIGHT")
            count1Text:Show() -- Ensure FontString is visible
        end

        local name1Text = getglobal("SkilletQueueButton1NameText") --[[@as FontString|nil]]
        if name1Text then
            name1Text:SetHeight(16)
            name1Text:SetPoint("CENTER", getglobal("SkilletQueueButton1Name"), "CENTER", 0, 0)
            name1Text:SetJustifyH("LEFT")
            name1Text:Show() -- Ensure FontString is visible
        end

        -- Show parent frames explicitly
        local count1Frame = getglobal("SkilletQueueButton1Count") --[[@as Frame|nil]]
        if count1Frame then count1Frame:Show() end

        local name1Frame = getglobal("SkilletQueueButton1Name") --[[@as Frame|nil]]
        if name1Frame then name1Frame:Show() end
    end

    -- Create buttons 2+ on first load (only when needed)
    for i = 2, numVisible do
        local button = getglobal("SkilletQueueButton" .. i)
        if not button then
            -- CRITICAL: parent is SkilletQueueParent (container), not SkilletQueueList (scroll frame)!
            button = CreateFrame("Frame", "SkilletQueueButton" .. i, SkilletQueueParent) --[[@as Frame]]
            button:SetParent(SkilletQueueParent)
            button:SetWidth(270)
            button:SetHeight(16)
            button:SetPoint("TOPLEFT", "SkilletQueueButton" .. (i - 1), "BOTTOMLEFT", 0, 0)
            button:SetFrameLevel((SkilletQueueParent:GetFrameLevel() or 0) + 1)

            -- Add backdrop
            button:SetBackdrop({
                bgFile = "Interface/Tooltips/UI-Tooltip-Background",
                edgeFile = nil,
                tile = true,
                tileSize = 16,
                edgeSize = 0,
                insets = { left = 0, right = 0, top = 0, bottom = 0 }
            })
            button:SetBackdropColor(0, 0, 0, 0.5)

            -- Create Count frame with text right-aligned and vertically centered
            local countFrame = CreateFrame("Frame", "SkilletQueueButton" .. i .. "Count", button)
            countFrame:SetWidth(30)
            countFrame:SetHeight(16)
            countFrame:SetPoint("LEFT", 0, 0)
            countFrame:Show() -- Ensure visibility
            local countText = countFrame:CreateFontString("SkilletQueueButton" .. i .. "CountText", "OVERLAY",
                "GameFontNormal")
            countText:SetWidth(30)
            countText:SetHeight(16)
            countText:SetPoint("RIGHT", countFrame, "RIGHT", 0, 0)
            countText:SetJustifyH("RIGHT")
            countText:SetTextColor(1, 1, 1, 1)
            countText:Show() -- Ensure visibility

            -- Create Name frame with text centered vertically
            local nameFrame = CreateFrame("Frame", "SkilletQueueButton" .. i .. "Name", button)
            nameFrame:SetWidth(220)
            nameFrame:SetHeight(16)
            nameFrame:SetPoint("LEFT", 34, 0)
            nameFrame:Show() -- Ensure visibility
            local nameText = nameFrame:CreateFontString("SkilletQueueButton" .. i .. "NameText", "OVERLAY",
                "GameFontNormal")
            nameText:SetWidth(220)
            nameText:SetHeight(16)
            nameText:SetPoint("CENTER", nameFrame, "CENTER", 0, 0)
            nameText:SetJustifyH("LEFT")
            nameText:SetTextColor(1, 1, 1, 1)
            nameText:Show() -- Ensure visibility

            -- Create Delete button
            local deleteButton = CreateFrame("Button", "SkilletQueueButton" .. i .. "DeleteButton", button,
                "UIPanelButtonTemplate")
            deleteButton:SetWidth(16)
            deleteButton:SetHeight(16)
            deleteButton:SetPoint("RIGHT", -2, 0)
            deleteButton:SetText("D")
            deleteButton:SetScript("OnClick", function()
                Skillet:RemoveQueuedItem(deleteButton:GetID())
            end)

            -- Create Primary toggle button (dev mode only)
            local primaryButton = CreateFrame("Button", "SkilletQueueButton" .. i .. "PrimaryButton", button,
                "UIPanelButtonTemplate")
            primaryButton:SetWidth(16)
            primaryButton:SetHeight(16)
            primaryButton:SetPoint("RIGHT", deleteButton, "LEFT", -2, 0)
            primaryButton:SetText("P")
            primaryButton:SetScript("OnClick", function()
                local queueIdx = primaryButton:GetID()
                if Skillet.stitch.queue and Skillet.stitch.queue[queueIdx] then
                    local entry = Skillet.stitch.queue[queueIdx]
                    -- Toggle isPrimary status
                    entry.isPrimary = not entry.isPrimary
                    -- Save and refresh
                    Skillet:SaveQueue(Skillet.db.server.queues, Skillet.currentTrade)
                    Skillet:UpdateQueueWindow()
                end
            end)
        end
    end

    -- Show/Hide and populate buttons based on queue data
    for i = 1, numVisible do
        local buttonIndex = i + offset
        local button = getglobal("SkilletQueueButton" .. i) --[[@as Frame|nil]]

        if button then
            if buttonIndex <= queueCount then
                -- Show and populate this button
                ---@type table
                local queueItem = queues[buttonIndex]

                -- Populate count FontString (number of crafts)
                local countText = getglobal(button:GetName() .. "CountText") --[[@as FontString|nil]]
                if countText then
                    countText:SetText(tostring(queueItem.numcasts or 0))
                    countText:Show()
                end

                -- Show count parent frame
                local countFrame = getglobal(button:GetName() .. "Count") --[[@as Frame|nil]]
                if countFrame then countFrame:Show() end

                -- Populate name FontString (profession + recipe name)
                local nameText = getglobal(button:GetName() .. "NameText") --[[@as FontString|nil]]
                if nameText then
                    local professionTag = queueItem.profession or "???"
                    local displayName = "Unknown Recipe"

                    -- Handle conversion entries (special case - no spellId)
                    if professionTag == "Conversion" then
                        displayName = queueItem.name or "Conversion"

                        -- Handle normal profession recipes
                    else
                        -- Use stored .name field (persists across sessions)
                        displayName = queueItem.name or "Unknown Recipe"

                        -- Fallback: Try API if name field missing (backward compat with old saves)
                        if displayName == "Unknown Recipe" and queueItem.spellId and Custom_GetProfessionRecipeInfo then
                            local skillId, name = Custom_GetProfessionRecipeInfo(queueItem.spellId)
                            if name then
                                displayName = name
                            end
                        end
                    end

                    local finalText = ""
                    if professionTag == "Conversion" then
                        finalText = "[CON] " .. displayName
                    elseif professionTag == "UNKNOWN" then
                        finalText = displayName
                    else
                        finalText = "[" .. professionTag .. "] " .. displayName
                    end

                    -- Synastria: Calculate craftability and apply color coding
                    -- Green = fully craftable, Yellow = partially craftable, Red = not craftable
                    ---@type number
                    local craftable = 0
                    ---@type number, number, number
                    local r, g, b = 1, 1, 1 -- Default white

                    -- Skip coloring for conversions (they use different logic)
                    if professionTag ~= "Conversion" and professionTag ~= "UNKNOWN" then
                        -- Try to get recipe object for craftability calculation
                        ---@type Recipe|nil
                        local recipeObj = nil

                        -- Method 1: Use spellId if available (fast Custom API lookup)
                        if queueItem.spellId and self.stitch.GetItemDataBySpellId then
                            recipeObj = self.stitch:GetItemDataBySpellId(queueItem.spellId)
                        end

                        -- Method 2: Fallback to name lookup (slower but works for all recipes)
                        if not recipeObj and queueItem.name then
                            recipeObj = self.stitch:GetItemDataByName(queueItem.name, queueItem.profession)
                        end

                        -- Calculate craftability if recipe found
                        if recipeObj and self.CraftCalc and self.CraftCalc.CalculateRecipeCraftability then
                            -- Use synchronous calculation (it's fast with our optimizations!)
                            -- includeBank=true to match UI display (bags+bank+resbank)
                            craftable = self.CraftCalc:CalculateRecipeCraftability(
                                recipeObj, self.stitch, true, false, 0, true
                            ) or 0

                            -- Divide by nummade to get number of CRAFTS (not items)
                            if recipeObj.nummade and recipeObj.nummade > 1 then
                                craftable = math.floor(craftable / recipeObj.nummade)
                            end
                        end

                        -- Apply color based on craftability vs queued amount
                        ---@type number
                        local numQueued = queueItem.numcasts or 0

                        if craftable >= numQueued then
                            -- Fully craftable - GREEN
                            r, g, b = 0, 1, 0
                        elseif craftable > 0 then
                            -- Partially craftable - YELLOW
                            r, g, b = 1, 1, 0
                        else
                            -- Not craftable - RED
                            r, g, b = 1, 0, 0
                        end
                    end

                    -- Apply color to both name and count for visual consistency
                    nameText:SetTextColor(r, g, b, 1)
                    nameText:SetText(finalText)
                    nameText:Show() -- Ensure visibility

                    -- Also color the count text to match
                    if countText then
                        countText:SetTextColor(r, g, b, 1)
                    end
                end

                -- Show name parent frame
                local nameFrame = getglobal(button:GetName() .. "Name") --[[@as Frame|nil]]
                if nameFrame then nameFrame:Show() end

                -- Set button ID for delete button and show it
                local deleteBtn = getglobal(button:GetName() .. "DeleteButton") --[[@as Button|nil]]
                if deleteBtn then
                    deleteBtn:SetID(buttonIndex)
                    deleteBtn:Show()
                end

                -- Set button ID for primary button and show/color based on dev mode and status
                local primaryBtn = getglobal(button:GetName() .. "PrimaryButton") --[[@as Button|nil]]
                if primaryBtn then
                    primaryBtn:SetID(buttonIndex)

                    -- Only show in dev mode
                    if self:IsDevMode() then
                        -- Color based on isPrimary status
                        ---@type FontString|nil
                        local fontString = primaryBtn:GetFontString()
                        if fontString then
                            if queueItem.isPrimary then
                                -- Green for primary items
                                fontString:SetTextColor(0, 1, 0, 1)
                            else
                                -- Red for auto-generated subcrafts
                                fontString:SetTextColor(1, 0, 0, 1)
                            end
                        end
                        primaryBtn:Show()
                    else
                        primaryBtn:Hide()
                    end
                end

                -- Show the button
                button:Show()
            else
                -- Hide this button and all its children
                button:Hide()

                local countText = getglobal(button:GetName() .. "CountText") --[[@as FontString|nil]]
                if countText then
                    countText:Hide()
                end

                local nameText = getglobal(button:GetName() .. "NameText") --[[@as FontString|nil]]
                if nameText then
                    nameText:Hide()
                end

                local deleteBtn = getglobal(button:GetName() .. "DeleteButton") --[[@as Button|nil]]
                if deleteBtn then
                    deleteBtn:Hide()
                end

                local primaryBtn = getglobal(button:GetName() .. "PrimaryButton") --[[@as Button|nil]]
                if primaryBtn then
                    primaryBtn:Hide()
                end
            end
        end
    end
end

--
-- Hides any and all Skillet windows that are open
--
-- Refer to the notes at the top of this file for how to hook this method.
-- If you do not (eventually) call the hooked method from your method, the
-- windows will not be hidden.
--
--
function Skillet:HideAllWindows()
    return self:internal_HideAllWindows()
end

--
-- Fills out and displays the shopping list frame
--
-- Refer to the notes at the top of this file for how to hook this method.
-- If you do not (eventually) call the hooked method from your method, the
-- window will not be shown.
--
-- @param atBank whether or not we are displaying the shopping list at a bank
--
function Skillet:DisplayShoppingList(atBank)
    return self:internal_DisplayShoppingList(atBank)
end

--
-- Hides the shopping list window
--
-- Refer to the notes at the top of this file for how to hook this method.
-- If you do not (eventually) call the hooked method from your method, the
-- window will not be hidden.
--
function Skillet:HideShoppingList()
    return self:internal_HideShoppingList()
end

--
-- Causes the list of recipes to be resorted. This should only be called
-- when the trade skill window is open.
--
-- You should not hook this method, you should call it directly.
--
-- @param force if true, the list of recipes will be resorted, if false
--        then recipes will only be resorted if they have changed
--
function Skillet:ResortRecipes(force)
    self:internal_ResortRecipes(force)
end

-- =================================================================
--                Skillet Recipe API
-- =================================================================

--[[

All data returned from theses methods is to be considered READ-ONLY

Data Formats
============

Reagent = {
    ["name"] = name,
    ["link"] = link,
    ["needed"] = number,
    ["texture"] = texture
}

Recipe = {
    ["name"] = name,
    ["link"] = link,
    ["texture"] = texture
    ["difficulty"] = "optimal", "medium", "easy", trivial" (non-localized)
    ["nummade"] = number made, (how many this recipe make)
    ["tools"] = "tools", (tools required, nil for no requirements)
    ["reagents"] = array of Reagent objects
}

-- Synastria: Modern format uses recipe.reagents table
So, recipe.name is the name of the recipe, recipe.reagents[1].name is the name of
the first required reagent.

Profession = {
    ["name"] = trade skill name
    ["count"] = number of recipes for this profession
    [recipe 1] = Recipe,
    [recipe 2] = Recipe,
    ....
}

So, profession.name is the name of the profession, profession[1].name is the
name of the first recipe in the profession.

Character = {
    ["name"] = name of the character
    ["count"] = number of professions for this character
    [profession 1] = Profession,
    [profession 2] = Profession,
    ...
}

So, character.name is the name of the character, character[1].name is the
name of the first profession known by that character.

Characters = {
    ["count"] = number of characters
    [character 1] = Character,
    [character 2] = Character,
}

So, characters.count is the number of characters, characters[1].name is the
name of the first character.

]]

--
-- Returns a list of characters for which Skillet recipe data
-- is available. This list will apply only to current realm and
-- faction. Characters on other servers or in the opposite
-- faction will no be included.
--
-- You should not hook this method, you should call it directly.
--
-- @return A list of characters for which Skillet has data
--
function Skillet:GetCharacters()
    return self:internal_GetCharacters()
end

--
-- Returns the list of professions that a particular character
-- knows. The character name must be one of those returned by
-- Skillet:GetCharacters().
--
-- You should not hook this method, you should call it directly.
--
-- @param character_name the character for which a profession list
--           should be returned
--
-- @return A list of professions for the specified character or nil
--            if the character has no professions known to Skillet.
--
function Skillet:GetCharacterProfessions(character_name)
    return self:internal_GetCharacterProfessions(character_name)
end

--
-- Returns the list of tradeskills for the specified character
-- and profession, or nil if either the character or profession
-- is unknown to Skillet.
--
-- You should not hook this method, you should call it directly.
--
-- @param character_name the character for which a tradeksill list
--           should be returned
-- @param professions the profession for which a tradeksill list
--           should be returned
--
-- @return A table of tradeskills known for the specified character name
--           and profession. Refer to the comment above for details on
--           the table's format.
--
function Skillet:GetCharacterTradeskills(character_name, profession)
    return self:internal_GetCharacterTradeskills(character_name, profession)
end

function Skillet:GetCraftersForItem(itemId)
    return self:internal_GetCraftersForItem(itemId)
end
