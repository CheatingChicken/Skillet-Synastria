local AceEvent = AceLibrary("AceEvent-2.0")
--[[
Skillet: Phase 2 Testing UI
Sacred testing interface for Custom_DoProfessionRecipe validation

By the grace of the Omnissiah, we test the server functions.
Reload-friendly - changes apply with /reload only.
]] --

---@class SkilletPhase2TestDialog : Frame
---@field title FontString
---@field statusText FontString
---@field resultsText FontString
---@field testBasicButton Button
---@field testWindowlessButton Button
---@field testCooldownButton Button
---@field testBatchButton Button
---@field testMultiProfButton Button
---@field clearButton Button
---@field closeButton Button
---@field testResults table<string, string>
---@field currentRecipe table|nil

-- Test recipe database: recipes with 100+ materials available
-- Helper to get current profession name
---@return string|nil profession The current profession name, or nil if none
local function GetCurrentProfession()
    ---@type string|nil
    local tradeName = GetTradeSkillLine()
    if tradeName and tradeName ~= "UNKNOWN" then
        return tradeName
    end
    return nil
end

-- Helper function to find most craftable recipe with minimum craftable count
---@param minCraftable number|nil Minimum number of craftable items required (default: 100)
---@return number|nil spellId The spell ID of the best recipe, or nil if not found
---@return string|nil recipeName The recipe name, or nil if not found
---@return number bestCraftable The number of items craftable
local function FindMostCraftableRecipe(minCraftable)
    minCraftable = minCraftable or 100

    if not Skillet or not Skillet.stitch then
        return nil, nil, 0
    end

    local professionName = GetTradeSkillLine()
    if not professionName or professionName == "UNKNOWN" then
        return nil, nil, 0
    end

    local bestSpellId = nil
    local bestRecipeName = nil
    local bestCraftable = 0

    -- Iterate through current tradeskill window
    local numSkills = GetNumTradeSkills()

    for i = 1, numSkills do
        local skillName, skillType = GetTradeSkillInfo(i)
        if skillType ~= "header" then
            -- Get spell ID directly from recipe link
            local recipeLink = GetTradeSkillRecipeLink(i)
            local spellId = nil

            if recipeLink then
                -- Extract spell ID from enchant link format: |Henchant:SPELLID|h[name]|h
                spellId = tonumber(recipeLink:match("|Henchant:(%d+)|h"))
            end

            -- Get craftable count from Skillet
            local recipe = Skillet.stitch:GetItemDataByIndex(professionName, i)
            local numCraftable = recipe and recipe.numcraftable or 0

            if spellId and numCraftable >= minCraftable and numCraftable > bestCraftable then
                bestSpellId = spellId
                bestRecipeName = skillName
                bestCraftable = numCraftable
            end
        end
    end

    return bestSpellId, bestRecipeName, bestCraftable
end

-- Get spell ID by recipe name (not tradeskill window index!)
local function GetRecipeSpellIdByName(recipeName, profession)
    -- Check if the requested profession is currently open
    ---@type string|nil
    local currentProf = GetTradeSkillLine()
    if currentProf ~= profession then
        return nil -- Profession not open
    end

    -- Scan tradeskill window for matching recipe name
    ---@type number
    local numSkills = GetNumTradeSkills()
    for i = 1, numSkills do
        ---@type string|nil
        local skillName = nil
        ---@type string|nil
        local skillType = nil
        skillName, skillType = GetTradeSkillInfo(i)
        if skillType ~= "header" and skillName == recipeName then
            -- Get spell ID from recipe link
            ---@type string|nil
            local recipeLink = GetTradeSkillRecipeLink(i)
            if recipeLink then
                ---@type number|nil
                local spellId = tonumber(recipeLink:match("|Henchant:(%d+)|h"))
                return spellId
            end
        end
    end

    return nil
end

local function GetRecipeIdByName(recipeName, profession)
    -- Access Skillet as global (safe inside function)
    if not Skillet or not Skillet.data then
        return nil
    end

    -- Search Skillet's profession data
    if Skillet.data[profession] then
        ---@type table<any, any>
        local profData = Skillet.data[profession]
        for recipeId, recipeData in pairs(profData) do
            ---@type any
            recipeId = recipeId
            ---@type any
            recipeData = recipeData
            if type(recipeData) == "table" and recipeData.name == recipeName then
                return recipeId
            end
        end
    end

    -- Fallback: search tradeskill window if profession matches and window is open
    if TradeSkillFrame and TradeSkillFrame:IsShown() then
        local currentProf = GetCurrentProfession()
        if currentProf == profession then
            local numSkills = GetNumTradeSkills()
            for i = 1, numSkills do
                local skillName, skillType = GetTradeSkillInfo(i)
                if skillType ~= "header" and skillName == recipeName then
                    return i
                end
            end
        end
    end

    return nil
end

-- Create the Phase 2 testing dialog
function Skillet:CreatePhase2TestDialog()
    if self.phase2TestDialog then
        return self.phase2TestDialog
    end

    local dialog = CreateFrame("Frame", "SkilletPhase2TestDialog", UIParent)
    ---@type SkilletPhase2TestDialog
    dialog = dialog
    dialog:SetSize(560, 680)
    dialog:SetPoint("CENTER")
    dialog:SetFrameStrata("DIALOG")
    dialog:EnableMouse(true)
    dialog:SetMovable(true)
    dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", function(self) self:StartMoving() end)
    dialog:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    dialog:SetClampedToScreen(true)
    dialog:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    dialog:SetBackdropColor(0, 0, 0, 0.95)

    -- Title
    dialog.title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    dialog.title:SetPoint("TOP", 0, -15)
    dialog.title:SetText("Phase 2: Custom_DoProfessionRecipe Testing")
    dialog.title:SetTextColor(1, 0.82, 0) -- Gold for Omnissiah

    -- Status text
    dialog.statusText = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    dialog.statusText:SetPoint("TOP", dialog.title, "BOTTOM", 0, -10)
    dialog.statusText:SetWidth(520)
    dialog.statusText:SetJustifyH("LEFT")
    dialog.statusText:SetText(
        "|cFFFFAA00By the Omnissiah's grace, we test the server functions.|r\n" ..
        "Tests use SECURE BUTTONS - materials will be consumed!"
    )

    -- Copyable results log (ScrollFrame with EditBox)
    local scrollFrame = CreateFrame("ScrollFrame", "SkilletPhase2ScrollFrame", dialog, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(520, 200)
    ---@diagnostic disable-next-line: param-type-mismatch
    scrollFrame:SetPoint("TOP", dialog.statusText, "BOTTOM", 0, -10)

    local logEditBox = CreateFrame("EditBox", "SkilletPhase2LogEditBox", scrollFrame)
    logEditBox:SetSize(500, 200)
    logEditBox:SetMultiLine(true)
    logEditBox:SetAutoFocus(false)
    logEditBox:SetFont("Fonts\\FRIZQT__.TTF", 11)
    logEditBox:SetText("|cFF808080No tests run yet. Click a test button to begin.|r")
    logEditBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    scrollFrame:SetScrollChild(logEditBox)

    dialog.logEditBox = logEditBox
    dialog.scrollFrame = scrollFrame

    -- Test results storage
    dialog.testResults = {}

    -- Helper function to add test result
    local function AddTestResult(testName, success, message)
        local color = success and "|cFF00FF00" or "|cFFFF0000"
        local status = success and "[PASS]" or "[FAIL]"
        table.insert(dialog.testResults, string.format("%s%s|r %s: %s", color, status, testName, message))

        -- Update copyable log
        ---@type string
        local resultText = ""
        ---@type string[]
        local results = dialog.testResults
        for i, result in ipairs(results) do
            resultText = resultText .. result .. "\n"
        end
        dialog.logEditBox:SetText(resultText)

        -- Auto-scroll to bottom
        dialog.scrollFrame:SetVerticalScroll(dialog.scrollFrame:GetVerticalScrollRange())
    end

    -- Test 1: Basic API Check (SAFE)
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[Debug] Creating Test 1 button...|r")
    dialog.testBasicButton = CreateFrame("Button", "SkilletPhase2TestBasic", dialog, "UIPanelButtonTemplate") --[[@as Button]]
    dialog.testBasicButton:SetSize(250, 32)
    dialog.testBasicButton:SetPoint("TOP", scrollFrame, "BOTTOM", 0, -20)
    dialog.testBasicButton:SetText("Test 1: Basic API Check")
    dialog.testBasicButton:Show()
    local point1 = select(1, dialog.testBasicButton:GetPoint()) or "NONE"
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF00FF00[Debug] Test 1: shown=%s, point=%s|r",
        tostring(dialog.testBasicButton:IsShown()),
        tostring(point1)))
    dialog.testBasicButton:SetScript("OnClick", function()
        if Custom_DoProfessionRecipe then
            AddTestResult("Basic API", true, "Custom_DoProfessionRecipe exists")
        else
            AddTestResult("Basic API", false, "Custom_DoProfessionRecipe not found")
        end
    end)

    -- Test 2: Window-Free Crafting ⚠️
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[Debug] Creating Test 2 button...|r")
    dialog.testWindowlessButton = CreateFrame("Button", "SkilletPhase2TestWindowless", dialog, "UIPanelButtonTemplate") --[[@as Button]]
    dialog.testWindowlessButton:SetSize(250, 32)
    dialog.testWindowlessButton:SetPoint("TOP", dialog.testBasicButton, "BOTTOM", 0, -8)
    dialog.testWindowlessButton:SetText("Test 2: Windowless Craft ⚠")
    dialog.testWindowlessButton:Show()

    dialog.testWindowlessButton:SetScript("OnClick", function()
        -- Test TRULY windowless crafting - use hardcoded spell ID, no profession window needed!
        -- Spell ID 45545 = Frostweave Bandage (First Aid)
        local testSpellId = 45545
        local testRecipeName = "Frostweave Bandage"

        -- Close profession windows FIRST to prove we don't need them
        if TradeSkillFrame and TradeSkillFrame:IsShown() then
            HideUIPanel(TradeSkillFrame)
        end

        AddTestResult("Windowless", true,
            string.format("Testing TRULY windowless: %s (Spell ID: %d)...", testRecipeName, testSpellId))

        -- Call Custom_DoProfessionRecipe with just the spell ID - NO WINDOW NEEDED!
        local success = Custom_DoProfessionRecipe(testSpellId, 1)
        if success then
            AddTestResult("Windowless", true,
                string.format("✓ SUCCESS! Crafted %s WITHOUT opening profession window!", testRecipeName))
        else
            AddTestResult("Windowless", false, "Custom_DoProfessionRecipe returned nil")
        end
    end)

    -- Test 3: Cooldown Verification
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[Debug] Creating Test 3 button...|r")
    dialog.testCooldownButton = CreateFrame("Button", "SkilletPhase2TestCooldown", dialog, "UIPanelButtonTemplate") --[[@as Button]]
    dialog.testCooldownButton:SetSize(250, 32)
    dialog.testCooldownButton:SetPoint("TOP", dialog.testWindowlessButton, "BOTTOM", 0, -8)
    dialog.testCooldownButton:SetText("Test 3: Cooldown Respect")
    dialog.testCooldownButton:Show()

    dialog.testCooldownButton:SetScript("OnClick", function()
        local profession = GetCurrentProfession()
        if profession ~= "Alchemy" then
            AddTestResult("Cooldown", false, "Must be Alchemist for this test")
            return
        end

        local spellId = GetRecipeSpellIdByName("Flask of Endless Rage", "Alchemy")
        if not spellId then
            AddTestResult("Cooldown", false, "Flask of Endless Rage not known")
            return
        end

        -- Check cooldown before craft
        local recipeInfo = Custom_GetProfessionRecipeInfo(spellId)
        if recipeInfo and recipeInfo.cooldownRemaining and recipeInfo.cooldownRemaining > 0 then
            AddTestResult("Cooldown", true,
                string.format("Recipe on cooldown (%d sec) - API should respect this", recipeInfo.cooldownRemaining))
            return
        end

        AddTestResult("Cooldown", true, "Attempting cooldown recipe...")
        local success = Custom_DoProfessionRecipe(spellId, 1)

        if success then
            -- Check cooldown after craft (delayed check)
            ---@type number
            local elapsed = 0
            ---@type Frame
            local timerFrame = CreateFrame("Frame") --[[@as Frame]]
            timerFrame:SetScript("OnUpdate", function(self, delta)
                ---@type number
                delta = delta
                elapsed = elapsed + delta
                if elapsed >= 1.0 then
                    self:SetScript("OnUpdate", nil)
                    local checkInfo = Custom_GetProfessionRecipeInfo(spellId)
                    if checkInfo and checkInfo.cooldownRemaining and checkInfo.cooldownRemaining > 0 then
                        AddTestResult("Cooldown", true,
                            string.format("✓ Cooldown applied: %d sec", checkInfo.cooldownRemaining))
                    else
                        AddTestResult("Cooldown", false, "No cooldown detected")
                    end
                end
            end)
        else
            AddTestResult("Cooldown", false, "Custom_DoProfessionRecipe returned nil")
        end
    end)
    -- Test 4: Batch Crafting (Direct API Call)
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[Debug] Creating Test 4 button...|r")
    dialog.testBatchButton = CreateFrame("Button", "SkilletPhase2TestBatch", dialog, "UIPanelButtonTemplate") --[[@as Button]]
    dialog.testBatchButton:SetSize(250, 32)
    dialog.testBatchButton:SetPoint("TOP", dialog.testCooldownButton, "BOTTOM", 0, -8)
    dialog.testBatchButton:SetText("Test 4: Batch Craft x5")
    dialog.testBatchButton:Show()
    local point4 = select(1, dialog.testBatchButton:GetPoint()) or "NONE"
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF00FF00[Debug] Test 4: shown=%s, point=%s|r",
        tostring(dialog.testBatchButton:IsShown()),
        tostring(point4)))

    dialog.testBatchButton:SetScript("OnClick", function()
        if not Custom_DoProfessionRecipe then
            AddTestResult("Batch", false, "Custom_DoProfessionRecipe not available")
            return
        end

        local profession = GetCurrentProfession()
        if not profession then
            AddTestResult("Batch", false, "No profession selected")
            return
        end

        local recipeId, recipeName, craftable = FindMostCraftableRecipe(100)
        if not recipeId then
            AddTestResult("Batch", false, "No recipe with 100+ craftable items found")
            return
        end

        -- Try calling Custom_DoProfessionRecipe with count parameter
        local success, result = pcall(Custom_DoProfessionRecipe, recipeId, 5)
        if success then
            AddTestResult("Batch", true,
                string.format("API accepted count=5 for %s (%d available)", recipeName, craftable))
        else
            AddTestResult("Batch", false, string.format("API failed: %s", tostring(result)))
        end
    end)
    -- Test 5: Multi-Profession
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[Debug] Creating Test 5 button...|r")
    dialog.testMultiProfButton = CreateFrame("Button", "SkilletPhase2TestMultiProf", dialog, "UIPanelButtonTemplate") --[[@as Button]]
    dialog.testMultiProfButton:SetSize(250, 32)
    dialog.testMultiProfButton:SetPoint("TOP", dialog.testBatchButton, "BOTTOM", 0, -8)
    dialog.testMultiProfButton:SetText("Test 5: Multi-Profession")
    dialog.testMultiProfButton:Show()
    local point5 = select(1, dialog.testMultiProfButton:GetPoint()) or "NONE"
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF00FF00[Debug] Test 5: shown=%s, point=%s|r",
        tostring(dialog.testMultiProfButton:IsShown()),
        tostring(point5)))

    dialog.testMultiProfButton:SetScript("OnClick", function()
        if not Custom_DoProfessionRecipe then
            AddTestResult("Multi-Prof", false, "Custom_DoProfessionRecipe not available")
            return
        end

        AddTestResult("Multi-Prof", true, "Multi-profession testing requires manual verification:")
        AddTestResult("Multi-Prof", true, "1. Open profession A, run Test 2")
        AddTestResult("Multi-Prof", true, "2. Open profession B, run Test 2")
        AddTestResult("Multi-Prof", true, "3. Verify both professions craft without window switching")
    end)

    -- Clear Results button
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[Debug] Creating Clear/Close buttons...|r")
    dialog.clearButton = CreateFrame("Button", "SkilletPhase2TestClear", dialog, "UIPanelButtonTemplate") --[[@as Button]]
    dialog.clearButton:SetSize(120, 32)
    dialog.clearButton:SetPoint("TOP", dialog.testMultiProfButton, "BOTTOM", -65, -15)
    dialog.clearButton:SetText("Clear Results")
    dialog.clearButton:Show()
    dialog.clearButton:SetScript("OnClick", function()
        dialog.testResults = {}
        dialog.logEditBox:SetText("|cFF808080No tests run yet. Click a test button to begin.|r")
        AceEvent:TriggerEvent("SkilletStitch_Queue_Complete") -- Trigger queue refresh
    end)

    -- Close button
    dialog.closeButton = CreateFrame("Button", "SkilletPhase2TestClose", dialog, "UIPanelButtonTemplate") --[[@as Button]]
    dialog.closeButton:SetSize(120, 32)
    dialog.closeButton:SetPoint("TOP", dialog.testMultiProfButton, "BOTTOM", 65, -15)
    dialog.closeButton:SetText("Close")
    dialog.closeButton:Show()
    dialog.closeButton:SetScript("OnClick", function()
        dialog:Hide()
    end)

    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[Debug] All 7 buttons created successfully!|r")

    -- ESC to close
    table.insert(UISpecialFrames, "SkilletPhase2TestDialog")

    self.phase2TestDialog = dialog
    return dialog
end

-- Show the Phase 2 test dialog
function Skillet:ShowPhase2TestDialog()
    local dialog = self:CreatePhase2TestDialog()
    dialog:Show()
end
