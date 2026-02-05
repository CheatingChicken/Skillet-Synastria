-- Synastria: Attunability and Forge Level Filtering (Toggle Button Style)
-- Modified from ScootsCraft to use 3x2 toggle grid instead of dropdowns

-- Create the attunability and forge filter toggles (2x3 grid)
function Skillet:CreateAttunabilityFilters(parent)
    -- Make sure slot filter exists first
    if not SkilletSlotFilterDropdown then
        self:Print("Warning: SkilletSlotFilterDropdown not found when creating attunability filters")
        return
    end

    local baseX = -15            -- X position relative to SlotFilter
    local baseY = 0              -- Y position relative to SlotFilter
    local buttonSize = 20
    local horizontalSpacing = 50 -- Space between columns
    local verticalSpacing = 4    -- Space between rows
    local labelOffset = -2
    local padding = 4            -- Padding inside background frame

    -- Create background frame with border
    self.toggleBackdrop = CreateFrame('Frame', 'SkilletToggleBackdrop', parent)
    self.toggleBackdrop:SetPoint('TOPLEFT', SkilletSlotFilterDropdown, 'TOPRIGHT', 10, 0)
    self.toggleBackdrop:SetSize(170, 52) -- Width and height to contain all toggles with padding

    -- Set backdrop (background and border)
    self.toggleBackdrop:SetBackdrop({
        bgFile = 'Interface\\DialogFrame\\UI-DialogBox-Background-Dark',
        edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border',
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    self.toggleBackdrop:SetBackdropColor(0, 0, 0, 0.7)
    self.toggleBackdrop:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

    -- Row 1, Column 1: Char toggle
    self.charToggle = CreateFrame('CheckButton', 'SkilletCharToggle', self.toggleBackdrop, 'UICheckButtonTemplate')
    self.charToggle:SetSize(buttonSize, buttonSize)
    self.charToggle:SetPoint('TOPLEFT', self.toggleBackdrop, 'TOPLEFT', padding, -padding)

    _G[self.charToggle:GetName() .. 'Text']:SetText('Char')
    _G[self.charToggle:GetName() .. 'Text']:SetTextColor(1, 1, 1)
    _G[self.charToggle:GetName() .. 'Text']:ClearAllPoints()
    _G[self.charToggle:GetName() .. 'Text']:SetPoint('LEFT', self.charToggle, 'RIGHT', labelOffset, 0)
    _G[self.charToggle:GetName() .. 'Text']:SetFont("Fonts\\FRIZQT__.TTF", 11)

    -- Row 1, Column 2: Un (Unattuned) toggle
    self.forgeToggleUn = CreateFrame('CheckButton', 'SkilletForgeToggleUn', parent, 'UICheckButtonTemplate')
    self.forgeToggleUn:SetSize(buttonSize, buttonSize)
    self.forgeToggleUn:SetPoint('LEFT', self.charToggle, 'LEFT', horizontalSpacing, 0)

    _G[self.forgeToggleUn:GetName() .. 'Text']:SetText('Un')
    _G[self.forgeToggleUn:GetName() .. 'Text']:SetTextColor(0.8, 0.8, 0.8)
    _G[self.forgeToggleUn:GetName() .. 'Text']:ClearAllPoints()
    _G[self.forgeToggleUn:GetName() .. 'Text']:SetPoint('LEFT', self.forgeToggleUn, 'RIGHT', labelOffset, 0)
    _G[self.forgeToggleUn:GetName() .. 'Text']:SetFont("Fonts\\FRIZQT__.TTF", 11)

    -- Row 1, Column 3: Att (Baseline) toggle
    self.forgeToggleAtt = CreateFrame('CheckButton', 'SkilletForgeToggleAtt', parent, 'UICheckButtonTemplate')
    self.forgeToggleAtt:SetSize(buttonSize, buttonSize)
    self.forgeToggleAtt:SetPoint('LEFT', self.forgeToggleUn, 'LEFT', horizontalSpacing, 0)

    _G[self.forgeToggleAtt:GetName() .. 'Text']:SetText('Att')
    _G[self.forgeToggleAtt:GetName() .. 'Text']:SetTextColor(0.65, 1, 0.5)
    _G[self.forgeToggleAtt:GetName() .. 'Text']:ClearAllPoints()
    _G[self.forgeToggleAtt:GetName() .. 'Text']:SetPoint('LEFT', self.forgeToggleAtt, 'RIGHT', labelOffset, 0)
    _G[self.forgeToggleAtt:GetName() .. 'Text']:SetFont("Fonts\\FRIZQT__.TTF", 11)

    -- Row 2, Column 1: TF (Titanforged) toggle
    self.forgeToggleTf = CreateFrame('CheckButton', 'SkilletForgeToggleTf', parent, 'UICheckButtonTemplate')
    self.forgeToggleTf:SetSize(buttonSize, buttonSize)
    self.forgeToggleTf:SetPoint('TOP', self.charToggle, 'BOTTOM', 0, -verticalSpacing)

    _G[self.forgeToggleTf:GetName() .. 'Text']:SetText('TF')
    _G[self.forgeToggleTf:GetName() .. 'Text']:SetTextColor(0.5, 0.5, 1)
    _G[self.forgeToggleTf:GetName() .. 'Text']:ClearAllPoints()
    _G[self.forgeToggleTf:GetName() .. 'Text']:SetPoint('LEFT', self.forgeToggleTf, 'RIGHT', labelOffset, 0)
    _G[self.forgeToggleTf:GetName() .. 'Text']:SetFont("Fonts\\FRIZQT__.TTF", 11)

    -- Row 2, Column 2: WF (Warforged) toggle
    self.forgeToggleWf = CreateFrame('CheckButton', 'SkilletForgeToggleWf', parent, 'UICheckButtonTemplate')
    self.forgeToggleWf:SetSize(buttonSize, buttonSize)
    self.forgeToggleWf:SetPoint('LEFT', self.forgeToggleTf, 'LEFT', horizontalSpacing, 0)

    _G[self.forgeToggleWf:GetName() .. 'Text']:SetText('WF')
    _G[self.forgeToggleWf:GetName() .. 'Text']:SetTextColor(1, 0.65, 0.5)
    _G[self.forgeToggleWf:GetName() .. 'Text']:ClearAllPoints()
    _G[self.forgeToggleWf:GetName() .. 'Text']:SetPoint('LEFT', self.forgeToggleWf, 'RIGHT', labelOffset, 0)
    _G[self.forgeToggleWf:GetName() .. 'Text']:SetFont("Fonts\\FRIZQT__.TTF", 11)

    -- Row 2, Column 3: LF (Lightforged) toggle
    self.forgeToggleLf = CreateFrame('CheckButton', 'SkilletForgeToggleLf', parent, 'UICheckButtonTemplate')
    self.forgeToggleLf:SetSize(buttonSize, buttonSize)
    self.forgeToggleLf:SetPoint('LEFT', self.forgeToggleWf, 'LEFT', horizontalSpacing, 0)

    _G[self.forgeToggleLf:GetName() .. 'Text']:SetText('LF')
    _G[self.forgeToggleLf:GetName() .. 'Text']:SetTextColor(1, 1, 0.65)
    _G[self.forgeToggleLf:GetName() .. 'Text']:ClearAllPoints()
    _G[self.forgeToggleLf:GetName() .. 'Text']:SetPoint('LEFT', self.forgeToggleLf, 'RIGHT', labelOffset, 0)
    _G[self.forgeToggleLf:GetName() .. 'Text']:SetFont("Fonts\\FRIZQT__.TTF", 11)

    -- Set up click handlers
    self:SetupForgeToggleHandlers()
end

-- Setup click handlers for forge toggles
function Skillet:SetupForgeToggleHandlers()
    if not self.currentTrade then return end

    -- Char toggle handler
    self.charToggle:SetScript('OnClick', function()
        if not Skillet.currentTrade then return end
        local isChecked = Skillet.charToggle:GetChecked()
        if type(isChecked) == "number" then
            isChecked = isChecked == 1
        end

        -- Save character attunability preference
        Skillet:SetTradeSkillOption(Skillet.currentTrade, "attunabilitychar", isChecked)
        Skillet:UpdateTradeSkillWindow()
    end)

    -- Un (Unattuned) toggle handler
    self.forgeToggleUn:SetScript('OnClick', function()
        if not Skillet.currentTrade then return end
        local isChecked = Skillet.forgeToggleUn:GetChecked()

        -- Uncheck all others
        Skillet.forgeToggleAtt:SetChecked(false)
        Skillet.forgeToggleTf:SetChecked(false)
        Skillet.forgeToggleWf:SetChecked(false)
        Skillet.forgeToggleLf:SetChecked(false)

        -- Set forge filter
        if isChecked then
            Skillet:SetTradeSkillOption(Skillet.currentTrade, "forgefilter", -1)
            -- Activate equipment only when forge filter is active
            Skillet:SetTradeSkillOption(Skillet.currentTrade, "equipmentonly", true)
        else
            Skillet:SetTradeSkillOption(Skillet.currentTrade, "forgefilter", nil)
            -- Deactivate equipment only when no forge filter
            Skillet:SetTradeSkillOption(Skillet.currentTrade, "equipmentonly", false)
        end

        Skillet:UpdateTradeSkillWindow()
    end)

    -- Att (Baseline) toggle handler
    self.forgeToggleAtt:SetScript('OnClick', function()
        if not Skillet.currentTrade then return end
        local isChecked = Skillet.forgeToggleAtt:GetChecked()

        -- Uncheck all others
        Skillet.forgeToggleUn:SetChecked(false)
        Skillet.forgeToggleTf:SetChecked(false)
        Skillet.forgeToggleWf:SetChecked(false)
        Skillet.forgeToggleLf:SetChecked(false)

        -- Set forge filter
        if isChecked then
            Skillet:SetTradeSkillOption(Skillet.currentTrade, "forgefilter", 0)
            -- Activate equipment only when forge filter is active
            Skillet:SetTradeSkillOption(Skillet.currentTrade, "equipmentonly", true)
        else
            Skillet:SetTradeSkillOption(Skillet.currentTrade, "forgefilter", nil)
            -- Deactivate equipment only when no forge filter
            Skillet:SetTradeSkillOption(Skillet.currentTrade, "equipmentonly", false)
        end

        Skillet:UpdateTradeSkillWindow()
    end)

    -- TF (Titanforged) toggle handler
    self.forgeToggleTf:SetScript('OnClick', function()
        if not Skillet.currentTrade then return end
        local isChecked = Skillet.forgeToggleTf:GetChecked()

        -- Uncheck all others
        Skillet.forgeToggleUn:SetChecked(false)
        Skillet.forgeToggleAtt:SetChecked(false)
        Skillet.forgeToggleWf:SetChecked(false)
        Skillet.forgeToggleLf:SetChecked(false)

        -- Set forge filter
        if isChecked then
            Skillet:SetTradeSkillOption(Skillet.currentTrade, "forgefilter", 1)
            -- Activate equipment only when forge filter is active
            Skillet:SetTradeSkillOption(Skillet.currentTrade, "equipmentonly", true)
        else
            Skillet:SetTradeSkillOption(Skillet.currentTrade, "forgefilter", nil)
            -- Deactivate equipment only when no forge filter
            Skillet:SetTradeSkillOption(Skillet.currentTrade, "equipmentonly", false)
        end

        Skillet:UpdateTradeSkillWindow()
    end)

    -- WF (Warforged) toggle handler
    self.forgeToggleWf:SetScript('OnClick', function()
        if not Skillet.currentTrade then return end
        local isChecked = Skillet.forgeToggleWf:GetChecked()

        -- Uncheck all others
        Skillet.forgeToggleUn:SetChecked(false)
        Skillet.forgeToggleAtt:SetChecked(false)
        Skillet.forgeToggleTf:SetChecked(false)
        Skillet.forgeToggleLf:SetChecked(false)

        -- Set forge filter
        if isChecked then
            Skillet:SetTradeSkillOption(Skillet.currentTrade, "forgefilter", 2)
            -- Activate equipment only when forge filter is active
            Skillet:SetTradeSkillOption(Skillet.currentTrade, "equipmentonly", true)
        else
            Skillet:SetTradeSkillOption(Skillet.currentTrade, "forgefilter", nil)
            -- Deactivate equipment only when no forge filter
            Skillet:SetTradeSkillOption(Skillet.currentTrade, "equipmentonly", false)
        end

        Skillet:UpdateTradeSkillWindow()
    end)

    -- LF (Lightforged) toggle handler
    self.forgeToggleLf:SetScript('OnClick', function()
        if not Skillet.currentTrade then return end
        local isChecked = Skillet.forgeToggleLf:GetChecked()

        -- Uncheck all others
        Skillet.forgeToggleUn:SetChecked(false)
        Skillet.forgeToggleAtt:SetChecked(false)
        Skillet.forgeToggleTf:SetChecked(false)
        Skillet.forgeToggleWf:SetChecked(false)

        -- Set forge filter
        if isChecked then
            Skillet:SetTradeSkillOption(Skillet.currentTrade, "forgefilter", 3)
            -- Activate equipment only when forge filter is active
            Skillet:SetTradeSkillOption(Skillet.currentTrade, "equipmentonly", true)
        else
            Skillet:SetTradeSkillOption(Skillet.currentTrade, "forgefilter", nil)
            -- Deactivate equipment only when no forge filter
            Skillet:SetTradeSkillOption(Skillet.currentTrade, "equipmentonly", false)
        end

        Skillet:UpdateTradeSkillWindow()
    end)

    -- Tooltips
    self.charToggle:SetScript('OnEnter', function()
        GameTooltip:SetOwner(Skillet.charToggle, 'ANCHOR_RIGHT')
        GameTooltip:SetText('Character Attunability')
        GameTooltip:AddLine('When no forge level is selected: shows all equipment', nil, nil, nil, true)
        GameTooltip:AddLine('When forge level is selected:', nil, nil, nil, true)
        GameTooltip:AddLine('  • Checked: shows character-attuneable items only', nil, nil, nil, true)
        GameTooltip:AddLine('  • Unchecked: shows account-attuneable items only', nil, nil, nil, true)
        GameTooltip:Show()
    end)
    self.charToggle:SetScript('OnLeave', function() GameTooltip:Hide() end)

    self.forgeToggleUn:SetScript('OnEnter', function()
        GameTooltip:SetOwner(Skillet.forgeToggleUn, 'ANCHOR_RIGHT')
        GameTooltip:SetText('Unattuned')
        GameTooltip:AddLine('Shows only unattuned items (forge level -1)', nil, nil, nil, true)
        GameTooltip:Show()
    end)
    self.forgeToggleUn:SetScript('OnLeave', function() GameTooltip:Hide() end)

    self.forgeToggleAtt:SetScript('OnEnter', function()
        GameTooltip:SetOwner(Skillet.forgeToggleAtt, 'ANCHOR_RIGHT')
        GameTooltip:SetText('Baseline')
        GameTooltip:AddLine('Shows items up to baseline (forge levels -1 and 0)', nil, nil, nil, true)
        GameTooltip:Show()
    end)
    self.forgeToggleAtt:SetScript('OnLeave', function() GameTooltip:Hide() end)

    self.forgeToggleTf:SetScript('OnEnter', function()
        GameTooltip:SetOwner(Skillet.forgeToggleTf, 'ANCHOR_RIGHT')
        GameTooltip:SetText('Titanforged')
        GameTooltip:AddLine('Shows items up to titanforged (forge levels -1, 0, and 1)', nil, nil, nil, true)
        GameTooltip:Show()
    end)
    self.forgeToggleTf:SetScript('OnLeave', function() GameTooltip:Hide() end)

    self.forgeToggleWf:SetScript('OnEnter', function()
        GameTooltip:SetOwner(Skillet.forgeToggleWf, 'ANCHOR_RIGHT')
        GameTooltip:SetText('Warforged')
        GameTooltip:AddLine('Shows items up to warforged (forge levels -1, 0, 1, and 2)', nil, nil, nil, true)
        GameTooltip:Show()
    end)
    self.forgeToggleWf:SetScript('OnLeave', function() GameTooltip:Hide() end)

    self.forgeToggleLf:SetScript('OnEnter', function()
        GameTooltip:SetOwner(Skillet.forgeToggleLf, 'ANCHOR_RIGHT')
        GameTooltip:SetText('Lightforged')
        GameTooltip:AddLine('Shows items up to lightforged (forge levels -1, 0, 1, 2, and 3)', nil, nil, nil, true)
        GameTooltip:Show()
    end)
    self.forgeToggleLf:SetScript('OnLeave', function() GameTooltip:Hide() end)
end

-- Update toggle UI to show current filter values
function Skillet:UpdateAttunabilityFilterUI()
    if not self.charToggle or not self.currentTrade then return end

    local charPref = self:GetTradeSkillOption(self.currentTrade, "attunabilitychar")
    self.charToggle:SetChecked(charPref)

    local forgeFilter = self:GetTradeSkillOption(self.currentTrade, "forgefilter")

    -- Uncheck all forge toggles first
    self.forgeToggleUn:SetChecked(false)
    self.forgeToggleAtt:SetChecked(false)
    self.forgeToggleTf:SetChecked(false)
    self.forgeToggleWf:SetChecked(false)
    self.forgeToggleLf:SetChecked(false)

    -- Check the appropriate toggle based on forge filter value
    if forgeFilter == -1 then
        self.forgeToggleUn:SetChecked(true)
    elseif forgeFilter == 0 then
        self.forgeToggleAtt:SetChecked(true)
    elseif forgeFilter == 1 then
        self.forgeToggleTf:SetChecked(true)
    elseif forgeFilter == 2 then
        self.forgeToggleWf:SetChecked(true)
    elseif forgeFilter == 3 then
        self.forgeToggleLf:SetChecked(true)
    end
end

-- Legacy functions removed (dropdowns no longer exist)
function Skillet:UpdateForgeFilterUI()
    -- Redirect to new toggle UI updater
    self:UpdateAttunabilityFilterUI()
end

-- Check if item matches attunability filter
function Skillet:MatchesAttunabilityFilter(recipeIndex)
    -- Check if we have any forge filter active
    local forgeFilter = self:GetTradeSkillOption(self.currentTrade, "forgefilter")
    local charPref = self:GetTradeSkillOption(self.currentTrade, "attunabilitychar")

    -- If no forge filter is active, Char toggle acts as "All Equipment"
    if not forgeFilter then
        return true -- Show all equipment
    end

    -- If we have a forge filter active, apply attunability based on Char toggle
    local itemLink = self:GetTradeskillItemLink(recipeIndex)
    if not itemLink then
        return false -- Hide items with no link when filter is active
    end

    local itemId = self:GetItemIDFromLink(itemLink)
    if not itemId then
        return false
    end

    -- Check if it's equippable - only equipment passes when forge filter is active
    local isEquippable = IsEquippableItem(itemId) or IsEquippableItem(itemLink)
    if not isEquippable then
        return false -- Hide non-equippable items when forge filter is active
    end

    -- Check attunability based on Char toggle
    local attuneChar = false
    local attuneAny = false

    -- First check if item has attuneable tags
    if GetItemTagsCustom then
        local tags = GetItemTagsCustom(itemId)
        if tags and bit.band(tags, 96) == 64 then
            -- Check if this character can attune it
            if CanAttuneItemHelper and CanAttuneItemHelper(itemId) > 0 then
                attuneChar = true
                attuneAny = true
            else
                -- Check if anyone on the account can attune it
                if IsAttunableBySomeone then
                    local check = IsAttunableBySomeone(itemId)
                    if check ~= nil and check ~= 0 then
                        attuneAny = true
                    end
                end
            end
        end
    end

    -- Apply filter based on Char toggle
    if charPref then
        -- Char toggle checked -> show character-attuneable only
        return attuneChar
    else
        -- Char toggle unchecked -> show account-attuneable
        return attuneAny
    end
end

-- Check if item matches forge level filter
function Skillet:MatchesForgeFilter(recipeIndex)
    local filterValue = self:GetTradeSkillOption(self.currentTrade, "forgefilter")

    if not filterValue then
        return true -- No filter active
    end

    -- Get item link (the crafted item, not the recipe)
    local itemLink = self:GetTradeskillItemLink(recipeIndex)
    if not itemLink then
        return true -- Non-items pass the filter
    end

    local itemId = self:GetItemIDFromLink(itemLink)
    if not itemId then
        return true
    end

    -- Get forge level
    local forgeLevel = nil
    if GetItemAttuneForge then
        forgeLevel = GetItemAttuneForge(itemId)
    end

    if not forgeLevel then
        return filterValue == -1 -- Only pass if filter is set to "Unattuned"
    end

    -- Compare forge level
    return forgeLevel <= filterValue
end
