-- Synastria: Profession Selector (from ScootsCraft)
-- This file adds profession switching functionality to Skillet

-- Profession spell IDs for all tradeskills
local professionSpellIds = {
    {53428},                                    -- Runeforging
    {51304, 28596, 11611, 3464,  3101,  2259},  -- Alchemy
    {51300, 29844, 9785,  3538,  3100,  2018},  -- Blacksmithing
    {51313, 28029, 13920, 7413,  7412,  7411},  -- Enchanting
    {51306, 30350, 12656, 4038,  4037,  4036},  -- Engineering
    {45363, 45361, 45360, 45359, 45358, 45357}, -- Inscription
    {51311, 28897, 28895, 28894, 25230, 25229}, -- Jewelcrafting
    {51302, 32549, 10662, 3811,  3104,  2108},  -- Leatherworking
    {2656},                                     -- Smelting
    {51309, 26790, 12180, 3910,  3909,  3908},  -- Tailoring
    {51296, 33359, 18260, 3413,  3102,  2550},  -- Cooking
    {45542, 27028, 10846, 7924,  3274,  3273}   -- First Aid
}

-- Create the profession selector bar
local function CreateProfessionSelector(self, parent)
    -- Create holder frame
    local holder = CreateFrame('Frame', 'SkilletProfessionButtonsHolder', parent)
    holder:SetSize(300, 24)
    holder:SetPoint('BOTTOMRIGHT', SkilletRankFrame, 'TOPRIGHT', 0, 5)
    
    self.professionButtons = {}
    
    for spellIndex, spellIdCollection in ipairs(professionSpellIds) do
        local spellId = nil
        -- Check which spell rank the player knows
        for _, checkSpellId in ipairs(spellIdCollection) do
            if IsSpellKnown(checkSpellId) then
                spellId = checkSpellId
                break
            end
        end
        
        if spellId then
            local name, _, icon = GetSpellInfo(spellId)
            
            -- Create button
            local button = CreateFrame('Button', 'SkilletProfessionButton' .. spellIndex, holder, 'SecureActionButtonTemplate')
            button:SetSize(24, 24)
            button:SetAttribute('type', 'spell')
            button:SetAttribute('spell', spellId)
            button:RegisterForClicks('AnyUp')
            button:SetNormalTexture(icon)
            
            -- Create glow overlay
            local glow = button:CreateTexture(nil, 'OVERLAY')
            glow:SetTexture('Interface\\Buttons\\UI-ActionButton-Border')
            glow:SetBlendMode('ADD')
            glow:SetAlpha(0)
            glow:SetSize(42, 42)
            glow:SetPoint('CENTER', 0, 0)
            
            -- Tooltip on hover
            button:SetScript('OnEnter', function(btn)
                GameTooltip_SetDefaultAnchor(GameTooltip, btn)
                GameTooltip:SetSpellByID(spellId)
                GameTooltip:Show()
                
                local currentTrade = GetTradeSkillLine()
                if currentTrade ~= name and not (currentTrade == 'Mining' and name == 'Smelting') then
                    glow:SetVertexColor(0.3, 0.3, 0.8)
                    glow:SetAlpha(1)
                end
            end)
            
            button:SetScript('OnLeave', function(btn)
                GameTooltip:Hide()
                
                local currentTrade = GetTradeSkillLine()
                if currentTrade ~= name and not (currentTrade == 'Mining' and name == 'Smelting') then
                    glow:SetAlpha(0)
                end
            end)
            
            table.insert(self.professionButtons, {
                button = button,
                glow = glow,
                name = name,
                spellId = spellId
            })
        end
    end
    
    -- Position buttons horizontally
    for i, prof in ipairs(self.professionButtons) do
        prof.button:SetPoint('TOPLEFT', holder, 'TOPLEFT', (i - 1) * 24, 0)
        prof.button:Show()
    end
    
    -- Adjust holder width to fit all buttons
    holder:SetWidth(#self.professionButtons * 24)
end

-- Update profession button highlighting
local function UpdateProfessionButtons(self)
    if not self.professionButtons then return end
    
    local currentTrade = GetTradeSkillLine()
    
    for _, prof in ipairs(self.professionButtons) do
        prof.glow:SetAlpha(0)
        prof.button:Enable()
        
        if prof.name == currentTrade or (prof.name == 'Smelting' and currentTrade == 'Mining') then
            prof.glow:SetVertexColor(0.8, 0.8, 0)
            prof.glow:SetAlpha(1)
            prof.button:Disable()
        end
    end
end

-- Assign functions to Skillet
Skillet.CreateProfessionSelector = CreateProfessionSelector
Skillet.UpdateProfessionButtons = UpdateProfessionButtons
