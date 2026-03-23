---@type Frame
local f = CreateFrame("Frame") --[[@as Frame]]
---@type LootFrameData[]
local lootFrames = {}
---@type table<string, LootEntry>
local lootData = {}
---@type string|nil
local lastDisenchantItem = nil
---@type LootPopSettings
local settings = {
    spacing     = 0,
    scale       = 1.0,
    maxEntries  = 10,
    frameStrata = "DIALOG",
    growUp      = true,
    duration    = 5,
    minQuality  = 0,
    showMoney   = true,
}

LootPopDB = LootPopDB or {
    anchorX      = 842,
    anchorY      = -300,
    scale        = 1.0,
    spacing      = 0,
    maxEntries   = 10,
    frameStrata  = "DIALOG",
    growUp       = true,
    duration     = 5,
    minimapAngle = 225,
    minQuality   = 0,
    showMoney    = true,
}

---@type Frame
local anchor
---@type Frame
local configFrame
---@type Frame[]
local previewFrames = {}
---@type Frame
local timerFrame = CreateFrame("Frame") --[[@as Frame]]
---@type TimerEntry[]
local activeTimers = {}

-- Forge values (const) - copied from AutoDeleteItems
---@type ForgeValueTable
local FORGE_VALUES = {
    TITANFORGED = 4096,
    WARFORGED = 8192,
    LIGHTFORGED = 12288
}

---@param delay number Seconds until the callback fires
---@param callback fun(): nil Function to call when the timer expires
local function CreateTimer(delay, callback)
    table.insert(activeTimers, { timeLeft = delay, callback = callback })
end

timerFrame:SetScript("OnUpdate", function(self, elapsed)
    for i = #activeTimers, 1, -1 do
        local timer = activeTimers[i]
        timer.timeLeft = timer.timeLeft - elapsed
        if timer.timeLeft <= 0 then
            timer.callback()
            table.remove(activeTimers, i)
        end
    end
end)

-- Forward declaration: UpdateMinimapButtonPosition is defined later in this file
-- after the minimap button frame is created.
---@type fun(angle: number): nil
local UpdateMinimapButtonPosition

--- Persists current runtime settings and anchor position to LootPopDB.
local function SaveAllSettings()
    local left, top = anchor:GetLeft(), anchor:GetTop()
    if left and top then
        -- GetLeft/GetTop return values in the anchor's own scaled space (i.e. divided
        -- by anchor:GetScale()).  SetPoint expects UIParent coordinate space, so we
        -- must multiply back by the scale before saving, otherwise each reload cycle
        -- drifts the anchor upward by a factor of (1/scale − 1) × UIParent:GetHeight().
        local s = anchor:GetScale()
        LootPopDB.anchorX = math.floor(left * s * 100 + 0.5) / 100
        LootPopDB.anchorY = math.floor((top * s - UIParent:GetHeight()) * 100 + 0.5) / 100
    end
    LootPopDB.scale = settings.scale
    LootPopDB.spacing = settings.spacing
    LootPopDB.maxEntries = settings.maxEntries
    LootPopDB.frameStrata = settings.frameStrata
    LootPopDB.growUp = settings.growUp
    LootPopDB.duration = settings.duration
    LootPopDB.minQuality = settings.minQuality
    LootPopDB.showMoney = settings.showMoney
end

--- Reads LootPopDB into runtime settings and repositions the anchor frame.
local function LoadAllSettings()
    anchor:ClearAllPoints()
    local x = type(LootPopDB.anchorX) == "number" and LootPopDB.anchorX or 842
    local y = type(LootPopDB.anchorY) == "number" and LootPopDB.anchorY or -300
    local scale = type(LootPopDB.scale) == "number" and LootPopDB.scale or 1.0
    anchor:SetScale(scale)
    anchor:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x / scale, y / scale)

    settings.scale = type(LootPopDB.scale) == "number" and LootPopDB.scale or 1.0
    settings.spacing = type(LootPopDB.spacing) == "number" and LootPopDB.spacing or 0
    settings.maxEntries = type(LootPopDB.maxEntries) == "number" and LootPopDB.maxEntries or 10
    settings.frameStrata = type(LootPopDB.frameStrata) == "string" and LootPopDB.frameStrata or "DIALOG"
    settings.growUp = LootPopDB.growUp ~= false
    settings.duration = type(LootPopDB.duration) == "number" and LootPopDB.duration or 5
    settings.minQuality = type(LootPopDB.minQuality) == "number" and LootPopDB.minQuality or 0
    settings.showMoney = LootPopDB.showMoney ~= false
    if UpdateMinimapButtonPosition then
        UpdateMinimapButtonPosition(type(LootPopDB.minimapAngle) == "number" and LootPopDB.minimapAngle or 225)
    end
end

anchor = CreateFrame("Frame", nil, UIParent) --[[@as Frame]]
anchor:SetSize(250, 32)
anchor:SetScale(settings.scale)
anchor:SetPoint("TOPLEFT", UIParent, "TOPLEFT", (LootPopDB.anchorX or 842) / settings.scale,
    (LootPopDB.anchorY or -300) / settings.scale)
anchor:SetMovable(true)
anchor:EnableMouse(false)
anchor:RegisterForDrag("LeftButton")
anchor:SetScript("OnDragStart", function(self) self:StartMoving() end)
anchor:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    SaveAllSettings()
end)

anchor:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
anchor:SetBackdropColor(0, 0, 0, 1)
anchor:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

local anchorIcon = anchor:CreateTexture(nil, "ARTWORK")
anchorIcon:SetSize(16, 16)
anchorIcon:SetPoint("LEFT", 7.5, 0)
anchorIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

local anchorText = anchor:CreateFontString(nil, "OVERLAY", "GameFontNormal")
anchorText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
anchorText:SetJustifyH("LEFT")
anchorText:SetPoint("LEFT", anchorIcon, "RIGHT", 4, 1)
anchorText:SetText("Loot Anchor - Drag to Move")
anchorText:SetTextColor(1, 1, 1)

anchor:Hide()

---@param index number Preview frame ordinal (1-based; used for positioning)
---@return Frame previewFrame The newly created preview frame
local function CreatePreviewFrame(index)
    local previewFrame = CreateFrame("Frame", nil, anchor) --[[@as Frame]]
    previewFrame:SetSize(250, 32)
    previewFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    previewFrame:SetBackdropColor(0, 0, 0, 1)
    previewFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

    local icon = previewFrame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(16, 16)
    icon:SetPoint("LEFT", 7.5, 0)
    icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

    local text = previewFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    text:SetJustifyH("LEFT")
    text:SetPoint("LEFT", icon, "RIGHT", 4, 1)
    text:SetText("Loot Item")
    text:SetTextColor(1, 1, 1)

    return previewFrame
end

--- Rebuilds the preview frame row shown while the config window is open.
local function UpdatePreviewFrames()
    for i, frame in ipairs(previewFrames) do
        frame:Hide()
    end

    local neededFrames = settings.maxEntries - 1

    while #previewFrames < neededFrames do
        table.insert(previewFrames, CreatePreviewFrame(#previewFrames + 1))
    end

    for i = 1, neededFrames do
        local frame = previewFrames[i]
        frame:ClearAllPoints()

        if settings.growUp then
            local targetY = i * (32 + settings.spacing)
            frame:SetPoint("BOTTOMLEFT", anchor, "BOTTOMLEFT", 0, targetY)
        else
            local targetY = -i * (32 + settings.spacing)
            frame:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, targetY)
        end

        if anchor:IsShown() then
            frame:Show()
        end
    end
end

anchor:Hide()

-- ----------------------------------------------------------------
-- Minimap Button
-- ----------------------------------------------------------------

---@type number
local minimapDragAngle = 225

---@type Button|nil
local minimapBtnRef

UpdateMinimapButtonPosition = function(angle)
    if not minimapBtnRef then return end
    local rad = math.rad(angle)
    local x = 54 + 80 * math.cos(rad)
    local y = -54 + 80 * math.sin(rad)
    minimapBtnRef:ClearAllPoints()
    minimapBtnRef:SetPoint("TOPLEFT", Minimap, "TOPLEFT", x, y)
end

---@type Button
local minimapBtn = CreateFrame("Button", "LootPopMinimapButton", Minimap) --[[@as Button]]
minimapBtnRef = minimapBtn
minimapBtn:SetSize(32, 32)
minimapBtn:SetFrameStrata("MEDIUM")
minimapBtn:SetFrameLevel(8)
minimapBtn:SetClampedToScreen(true)

local minimapBtnTex = minimapBtn:CreateTexture(nil, "BACKGROUND") --[[@as Texture]]
minimapBtnTex:SetSize(24, 24)
minimapBtnTex:SetPoint("CENTER")
minimapBtnTex:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")

local minimapBtnHL = minimapBtn:CreateTexture(nil, "HIGHLIGHT") --[[@as Texture]]
minimapBtnHL:SetSize(32, 32)
minimapBtnHL:SetPoint("CENTER")
minimapBtnHL:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

local isDraggingMinimap = false

minimapBtn:RegisterForClicks("LeftButtonUp")
minimapBtn:SetScript("OnClick", function()
    if configFrame:IsShown() then
        configFrame:Hide()
    else
        configFrame:Show()
    end
end)

minimapBtn:RegisterForDrag("LeftButton")
minimapBtn:SetMovable(true)
minimapBtn:SetScript("OnDragStart", function(self)
    isDraggingMinimap = true
end)
minimapBtn:SetScript("OnDragStop", function(self)
    isDraggingMinimap = false
    LootPopDB.minimapAngle = minimapDragAngle
end)

minimapBtn:SetScript("OnUpdate", function(self)
    if isDraggingMinimap then
        local cx = Minimap:GetLeft() + Minimap:GetWidth() / 2
        local cy = Minimap:GetBottom() + Minimap:GetHeight() / 2
        local mx, my = GetCursorPosition()
        local effectiveScale = UIParent:GetEffectiveScale() --[[@as number]]
        mx = mx / effectiveScale
        my = my / effectiveScale
        minimapDragAngle = math.deg(math.atan2(my - cy, mx - cx))
        UpdateMinimapButtonPosition(minimapDragAngle)
    end
end)

minimapBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("LootPop")
    GameTooltip:AddLine("Click to open config", 1, 1, 1)
    GameTooltip:AddLine("Drag to reposition", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)

minimapBtn:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

UpdateMinimapButtonPosition(minimapDragAngle)

---@type Frame
local addonFrame = CreateFrame("Frame") --[[@as Frame]]
addonFrame:RegisterEvent("ADDON_LOADED")
addonFrame:RegisterEvent("PLAYER_LOGOUT")
addonFrame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == "LootPop" then
        LoadAllSettings()
    elseif event == "PLAYER_LOGOUT" then
        SaveAllSettings()
    end
end)

configFrame = CreateFrame("Frame", "LootPopConfig", UIParent) --[[@as Frame]]
configFrame:SetSize(300, 435)
configFrame:SetPoint("CENTER")
configFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
})
configFrame:SetMovable(true)
configFrame:EnableMouse(true)
configFrame:RegisterForDrag("LeftButton")
configFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
configFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
configFrame:Hide()
table.insert(UISpecialFrames, "LootPopConfig")
configFrame:SetScript("OnHide", function()
    SaveAllSettings()
    anchor:Hide()
    anchor:EnableMouse(false)
    for i, frame in ipairs(previewFrames) do
        frame:Hide()
    end
end)

local title = configFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
title:SetPoint("TOP", 0, -16)
title:SetText("LootPop Configuration")

---@param parent Frame Parent frame for the slider
---@param name string Global name to assign to the slider
---@param width number Pixel width of the slider
---@param x number X offset relative to parent TOP anchor
---@param y number Y offset relative to parent TOP anchor
---@param minVal number Minimum slider value
---@param maxVal number Maximum slider value
---@param currentVal number Initial slider value
---@param step number Value step increment
---@param labelText string Label prefix shown in the slider text
---@return Slider slider The created slider frame
local function CreateSlider(parent, name, width, x, y, minVal, maxVal, currentVal, step, labelText)
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate") --[[@as Slider]]
    slider:SetSize(width, 17)
    slider:SetPoint("TOP", x, y)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValue(currentVal)
    slider:SetValueStep(step)

    getglobal(name .. "Low"):SetText(tostring(minVal))
    getglobal(name .. "High"):SetText(tostring(maxVal))
    getglobal(name .. "Text"):SetText(labelText .. ": " .. (step < 1 and string.format("%.1f", currentVal) or currentVal))

    return slider
end

local scaleSlider = CreateSlider(configFrame, "LootPopScaleSlider", 200, 0, -50, 0.5, 2.0, settings.scale, 0.1, "Scale")
scaleSlider:SetScript("OnValueChanged", function(self, value)
    settings.scale = value
    getglobal(self:GetName() .. "Text"):SetText("Scale: " .. string.format("%.1f", value))
    if anchor:IsShown() then
        anchor:SetScale(value)
    end
    SaveAllSettings()
end)

local spacingSlider = CreateSlider(configFrame, "LootPopSpacingSlider", 200, 0, -80, 0, 20, settings.spacing, 1,
    "Spacing")
spacingSlider:SetScript("OnValueChanged", function(self, value)
    settings.spacing = value
    getglobal(self:GetName() .. "Text"):SetText("Spacing: " .. value)
    if anchor:IsShown() then
        UpdatePreviewFrames()
    end
    SaveAllSettings()
end)

local durationSlider = CreateSlider(configFrame, "LootPopDurationSlider", 200, 0, -110, 1, 10, settings.duration, 1,
    "Duration")
durationSlider:SetScript("OnValueChanged", function(self, value)
    settings.duration = value
    getglobal(self:GetName() .. "Text"):SetText("Duration: " .. value .. "s")
    SaveAllSettings()
end)

local maxEntriesLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
maxEntriesLabel:SetPoint("TOP", 0, -140)
maxEntriesLabel:SetText("Max Entries:")

local maxEntriesEditBox = CreateFrame("EditBox", nil, configFrame, "InputBoxTemplate")
maxEntriesEditBox:SetSize(60, 20)
maxEntriesEditBox:SetPoint("TOP", 0, -160)
maxEntriesEditBox:SetText(tostring(settings.maxEntries))
maxEntriesEditBox:SetAutoFocus(false)
maxEntriesEditBox:SetScript("OnEnterPressed", function(self)
    local value = tonumber(self:GetText())
    if value and value > 0 and value <= 50 then
        settings.maxEntries = math.floor(value)
        self:SetText(tostring(settings.maxEntries))
        if anchor:IsShown() then
            UpdatePreviewFrames()
        end
        SaveAllSettings()
    else
        self:SetText(tostring(settings.maxEntries))
    end
    self:ClearFocus()
end)

local frameStrataLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
frameStrataLabel:SetPoint("TOP", 0, -185)
frameStrataLabel:SetText("Frame Strata:")

local frameStrataDropdown = CreateFrame("Frame", "LootPopFrameStrataDropdown", configFrame, "UIDropDownMenuTemplate")
frameStrataDropdown:SetPoint("TOP", 0, -200)
local strataOptions = { "BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "FULLSCREEN", "FULLSCREEN_DIALOG", "TOOLTIP" }

UIDropDownMenu_Initialize(frameStrataDropdown, function()
    local info = {}
    for _, strata in ipairs(strataOptions) do
        info.text = strata
        info.value = strata
        info.func = function()
            settings.frameStrata = strata
            UIDropDownMenu_SetText(frameStrataDropdown, strata)
            if anchor:IsShown() then
                anchor:SetFrameStrata(strata)
            end
            SaveAllSettings()
        end
        info.checked = (settings.frameStrata == strata)
        UIDropDownMenu_AddButton(info)
    end
end)
UIDropDownMenu_SetWidth(frameStrataDropdown, 120)
UIDropDownMenu_SetText(frameStrataDropdown, settings.frameStrata)

local growthLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
growthLabel:SetPoint("TOP", 0, -230)
growthLabel:SetText("Growth Direction:")

local growthDropdown = CreateFrame("Frame", "LootPopGrowthDropdown", configFrame, "UIDropDownMenuTemplate")
growthDropdown:SetPoint("TOP", 0, -245)

UIDropDownMenu_Initialize(growthDropdown, function()
    local info = {}

    info.text = "Grow Up"
    info.value = true
    ---@diagnostic disable-next-line: duplicate-set-field
    info.func = function()
        settings.growUp = true
        UIDropDownMenu_SetText(growthDropdown, "Grow Up")
        if anchor:IsShown() then
            UpdatePreviewFrames()
        end
        SaveAllSettings()
    end
    info.checked = settings.growUp
    UIDropDownMenu_AddButton(info)

    info.text = "Grow Down"
    info.value = false
    ---@diagnostic disable-next-line: duplicate-set-field
    info.func = function()
        settings.growUp = false
        UIDropDownMenu_SetText(growthDropdown, "Grow Down")
        if anchor:IsShown() then
            UpdatePreviewFrames()
        end
        SaveAllSettings()
    end
    info.checked = not settings.growUp
    UIDropDownMenu_AddButton(info)
end)
UIDropDownMenu_SetWidth(growthDropdown, 120)
UIDropDownMenu_SetText(growthDropdown, settings.growUp and "Grow Up" or "Grow Down")

-- ----------------------------------------------------------------
-- Rarity Filter Slider
-- ----------------------------------------------------------------

---@type string[]
local QUALITY_NAMES = { "Poor", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Artifact" }

---@type table<number, ItemQualityColor>
local QUALITY_COLORS = {
    [0] = { 0.62, 0.62, 0.62 },
    [1] = { 1, 1, 1 },
    [2] = { 0.12, 1, 0 },
    [3] = { 0, 0.44, 0.87 },
    [4] = { 0.64, 0.21, 0.93 },
    [5] = { 1, 0.5, 0 },
    [6] = { 0.9, 0.8, 0.5 },
}

local raritySlider = CreateSlider(configFrame, "LootPopRaritySlider", 200, 0, -300, 0, 6, settings.minQuality, 1,
    "Min Rarity")
raritySlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value + 0.5)
    settings.minQuality = value
    local qualityName = QUALITY_NAMES[value + 1] or "Unknown"
    local labelFS = getglobal(self:GetName() .. "Text") --[[@as FontString]]
    labelFS:SetText("Min Rarity: " .. qualityName .. " (" .. value .. ")")
    local c = QUALITY_COLORS[value] or { 1, 1, 1 }
    labelFS:SetTextColor(c[1], c[2], c[3])
    SaveAllSettings()
end)

-- ----------------------------------------------------------------
-- Show Money Toggle
-- ----------------------------------------------------------------

local showMoneyCheck = CreateFrame("CheckButton", "LootPopShowMoneyCheck", configFrame,
    "UICheckButtonTemplate") --[[@as Button]]
showMoneyCheck:SetSize(24, 24)
showMoneyCheck:SetPoint("TOP", -50, -320)
showMoneyCheck:SetChecked(settings.showMoney)
showMoneyCheck:SetScript("OnClick", function(self)
    ---@cast self Button
    settings.showMoney = self:GetChecked() ~= nil and self:GetChecked() ~= false
    SaveAllSettings()
end)

local showMoneyLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
showMoneyLabel:SetPoint("LEFT", showMoneyCheck, "RIGHT", 4, 0)
showMoneyLabel:SetText("Show Money Loot")

local centerBtn = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
centerBtn:SetSize(160, 22)
centerBtn:SetPoint("BOTTOM", 0, 68)
centerBtn:SetText("Return to Center")
centerBtn:SetScript("OnClick", function()
    anchor:ClearAllPoints()
    anchor:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    SaveAllSettings()
end)

local posBtn = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
posBtn:SetSize(160, 22)
posBtn:SetPoint("BOTTOM", 0, 43)
posBtn:SetText("Show/Move Anchor")
posBtn:SetScript("OnClick", function()
    if anchor:IsShown() then
        anchor:Hide()
        anchor:EnableMouse(false)
        for i, frame in ipairs(previewFrames) do
            frame:Hide()
        end
    else
        anchor:SetScale(settings.scale)
        anchor:Show()
        anchor:EnableMouse(true)
        UpdatePreviewFrames()
    end
end)

local closeBtn = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
closeBtn:SetSize(80, 22)
closeBtn:SetPoint("BOTTOM", 0, 18)
closeBtn:SetText("Close")
closeBtn:SetScript("OnClick", function()
    configFrame:Hide()
end)

configFrame:SetScript("OnShow", function()
    scaleSlider:SetValue(settings.scale)
    spacingSlider:SetValue(settings.spacing)
    durationSlider:SetValue(settings.duration)
    maxEntriesEditBox:SetText(tostring(settings.maxEntries))
    UIDropDownMenu_SetText(frameStrataDropdown, settings.frameStrata)
    UIDropDownMenu_SetText(growthDropdown, settings.growUp and "Grow Up" or "Grow Down")
    raritySlider:SetValue(settings.minQuality)
    local qualityName = QUALITY_NAMES[settings.minQuality + 1] or "Unknown"
    local labelFS = getglobal(raritySlider:GetName() .. "Text") --[[@as FontString]]
    labelFS:SetText("Min Rarity: " .. qualityName .. " (" .. settings.minQuality .. ")")
    local c = QUALITY_COLORS[settings.minQuality] or { 1, 1, 1 }
    labelFS:SetTextColor(c[1], c[2], c[3])
    showMoneyCheck:SetChecked(settings.showMoney)
end)

SLASH_LOOTPOP1 = "/lootpop"
SlashCmdList["LOOTPOP"] = function(msg)
    configFrame:Show()
end

---@type table<number, ItemQualityColor>
local itemColors = {
    [0] = { 0.62, 0.62, 0.62 },
    [1] = { 1, 1, 1 },
    [2] = { 0.12, 1, 0 },
    [3] = { 0, 0.44, 0.87 },
    [4] = { 0.64, 0.21, 0.93 },
    [5] = { 1, 0.5, 0 },
    [6] = { 0.9, 0.8, 0.5 }
}

-- Quality level encoded in the link's |c colour code (always available, no cache needed).
---@type table<string, number>
local LINK_COLOR_TO_QUALITY = {
    ["ff9d9d9d"] = 0, -- Poor
    ["ffffffff"] = 1, -- Common
    ["ff1eff00"] = 2, -- Uncommon
    ["ff0070dd"] = 3, -- Rare
    ["ffa335ee"] = 4, -- Epic
    ["ffff8000"] = 5, -- Legendary
    ["ffe6cc80"] = 6, -- Artifact
}

--- Extracts item quality from the |c colour code embedded in an item link.
--- This works even before GetItemInfo has cached the item, making it reliable
--- immediately after a /reload or for newly encountered items.
---@param itemLink string The full WoW item hyperlink
---@return number quality Quality level 0–6, or -1 if unrecognised
local function GetQualityFromItemLink(itemLink)
    local colorHex = itemLink:match("|c(%x%x%x%x%x%x%x%x)|H")
    if colorHex then
        local q = LINK_COLOR_TO_QUALITY[colorHex:lower()]
        if q then return q end
    end
    return -1
end

-- NEW: Parse item string directly for forge type (faster than tooltip scan)
---@param itemLink string|nil The full item hyperlink to inspect
---@return ForgeType|nil forgeType The detected forge tier, or nil if none
local function GetForgeTypeFromItemString(itemLink)
    if not itemLink then return nil end

    local itemString = itemLink:match("item:([%-?%d:]+)")
    if not itemString then return nil end

    local parts = { strsplit(":", itemString) }
    local uniqueId = tonumber(parts[8]) or 0

    if uniqueId >= FORGE_VALUES.LIGHTFORGED then
        return "lightforged"
    elseif uniqueId >= FORGE_VALUES.WARFORGED then
        return "warforged"
    elseif uniqueId >= FORGE_VALUES.TITANFORGED then
        return "titanforged"
    end

    return nil
end

-- NEW: Check if item has a bounty
---@param itemId number|nil The item ID to check
---@return boolean hasBounty True when the item has a server bounty value > 0
local function HasBounty(itemId)
    if not itemId then return false end
    local gold = GetCustomGameData(31, itemId)
    return gold ~= nil and gold > 0
end

---@param itemLink string The raw item link (may include trailing "x<count>")
---@return string key The normalised dedup key (quantity suffix stripped)
local function GetLootKey(itemLink)
    return itemLink:match("^(.-)x%d+$") or itemLink
end

---@param skipFadingFrames any Unused parameter kept for API compatibility
local function RepositionFrames(skipFadingFrames)
    for i, frameData in ipairs(lootFrames) do
        local frame = frameData.frame
        if not frame.isFading and not frame.isDestroying then
            if settings.growUp then
                local targetY = (i - 1) * (frame:GetHeight() + settings.spacing)
                frame:ClearAllPoints()
                frame:SetPoint("BOTTOMLEFT", anchor, "BOTTOMLEFT", 0, targetY)
            else
                local targetY = -(i - 1) * (frame:GetHeight() + settings.spacing)
                frame:ClearAllPoints()
                frame:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, targetY)
            end
        end
    end
end

-- Reusable fade frame to prevent creating new frames constantly (MEMORY LEAK FIX)
---@type Frame
local fadeFrame = CreateFrame("Frame") --[[@as Frame]]
---@type FadeEntry[]
local activeFades = {}

---@param frame Frame The frame to fade
---@param fadeIn boolean True = fade in (alpha 0→1); false = fade out (alpha 1→0)
---@param callback? fun(): nil Called once the fade completes
local function CreateFadeAnimation(frame, fadeIn, callback)
    -- Cancel any existing fade on this frame
    for i = #activeFades, 1, -1 do
        if activeFades[i].frame == frame then
            table.remove(activeFades, i)
        end
    end

    table.insert(activeFades, {
        frame = frame,
        fadeTimer = 0,
        fadeIn = fadeIn,
        callback = callback
    })

    -- Start the fade processor if not already running
    if not fadeFrame:GetScript("OnUpdate") then
        fadeFrame:SetScript("OnUpdate", function(self, elapsed)
            for i = #activeFades, 1, -1 do
                local fade = activeFades[i]
                fade.fadeTimer = fade.fadeTimer + elapsed
                local alpha = fade.fadeIn and (fade.fadeTimer / 0.3) or (1 - fade.fadeTimer / 0.3)

                if (fade.fadeIn and alpha >= 1) or (not fade.fadeIn and alpha <= 0) then
                    fade.frame:SetAlpha(fade.fadeIn and 1 or 0)
                    if fade.callback then fade.callback() end
                    table.remove(activeFades, i)
                else
                    fade.frame:SetAlpha(alpha)
                end
            end

            -- Stop processor if no active fades
            if #activeFades == 0 then
                self:SetScript("OnUpdate", nil)
            end
        end)
    end
end

--- Evicts the oldest loot popup frame when the maximum entry count is reached.
local function RemoveOldestFrame()
    if #lootFrames >= settings.maxEntries then
        local oldestFrame = lootFrames[#lootFrames]

        for key, data in pairs(lootData) do
            if data.frame == oldestFrame.frame then
                if data.timerId then
                    for i = #activeTimers, 1, -1 do
                        local timer = activeTimers[i]
                        if timer.id == data.timerId then
                            table.remove(activeTimers, i)
                            break
                        end
                    end
                end
                lootData[key] = nil
                break
            end
        end

        oldestFrame.frame:Hide()
        oldestFrame.frame:SetParent(nil)
        table.remove(lootFrames, #lootFrames)

        RepositionFrames()
    end
end

---@param itemLink string The WoW item hyperlink for the looted item (or "Money")
---@param texture string|number Icon texture path or ID used for the left-side icon
---@param quantity number|nil Quantity looted (defaults to 1)
local function CreateLootFrame(itemLink, texture, quantity)
    quantity = quantity or 1
    local lootKey = GetLootKey(itemLink)

    if lootData[lootKey] then
        local existingData = lootData[lootKey]
        existingData.quantity = existingData.quantity + quantity

        if existingData.timerId then
            for i, timer in ipairs(activeTimers) do
                if timer.id == existingData.timerId then
                    table.remove(activeTimers, i)
                    break
                end
            end
        end

        local baseLink = itemLink:match("^(.-)x%d*$") or itemLink
        local displayText = existingData.quantity > 1 and (baseLink .. "|cFFFFFFFF x" .. existingData.quantity .. "|r") or
            baseLink
        existingData.textObj:SetText(displayText)

        existingData.textObj:SetWidth(0)
        local baseWidth = existingData.hasBounty and 55 or 33
        existingData.frame:SetWidth(math.max(50, existingData.textObj:GetStringWidth() + baseWidth))

        local timerId = math.random(1000000)
        existingData.timerId = timerId
        CreateTimer(settings.duration, function()
            if existingData.timerId == timerId then
                lootData[lootKey] = nil
                CreateFadeAnimation(existingData.frame, false, function()
                    existingData.frame:Hide()
                    existingData.frame:SetParent(nil)
                    for i, data in ipairs(lootFrames) do
                        if data.frame == existingData.frame then
                            table.remove(lootFrames, i)
                            break
                        end
                    end
                    RepositionFrames()
                end)
            end
        end)
        return
    end

    RemoveOldestFrame()

    ---@type Frame
    local lootFrame = CreateFrame("Frame", nil, UIParent) --[[@as Frame]]
    lootFrame:SetScale(settings.scale)
    lootFrame:SetFrameStrata(settings.frameStrata)

    local baseLink = itemLink:match("^(.-)x%d*$") or itemLink
    local displayText = quantity > 1 and (baseLink .. "|cFFFFFFFF x" .. quantity .. "|r") or baseLink

    local textColor = { 1, 1, 1 }
    local itemID = itemLink:match("item:(%d+)")
    if itemID then
        local _, _, quality = GetItemInfo(itemID)
        if quality and itemColors[quality] then
            textColor = itemColors[quality]
        end
    end

    local forgeType = GetForgeTypeFromItemString(itemLink)

    local hasBounty = false
    if itemID then
        hasBounty = HasBounty(tonumber(itemID))
    end

    local text = lootFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    text:SetJustifyH("LEFT")
    text:SetText(displayText)
    text:SetTextColor(textColor[1], textColor[2], textColor[3])

    local icon = lootFrame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(16, 16)
    icon:SetPoint("LEFT", 7.5, 0)
    icon:SetTexture(texture)

    ---@type Texture|nil
    local bountyIcon
    if hasBounty then
        bountyIcon = lootFrame:CreateTexture(nil, "ARTWORK")
        bountyIcon:SetSize(16, 16)
        bountyIcon:SetPoint("LEFT", icon, "RIGHT", 2, 0)
        bountyIcon:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
        text:SetPoint("LEFT", bountyIcon, "RIGHT", 4, 1)
    else
        text:SetPoint("LEFT", icon, "RIGHT", 4, 1)
    end

    text:SetWidth(0)

    local baseWidth = hasBounty and 55 or 33
    local frameWidth = math.max(50, text:GetStringWidth() + baseWidth)

    lootFrame:SetSize(frameWidth, 32)
    lootFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })

    ---@type table<ForgeType, ForgeColorPair>
    local forgeColors = {
        titanforged = { { 0.35, 0.35, 0.7, 1 }, { 0.42, 0.49, 0.63, 1 } },
        warforged = { { 0.7, 0.36, 0.31, 1 }, { 0.7, 0.36, 0.31, 1 } },
        lightforged = { { 0.67, 0.67, 0.49, 1 }, { 0.67, 0.67, 0.49, 1 } }
    }

    if forgeType and forgeColors[forgeType] then
        lootFrame:SetBackdropColor(unpack(forgeColors[forgeType][1]))
        lootFrame:SetBackdropBorderColor(unpack(forgeColors[forgeType][2]))
    else
        lootFrame:SetBackdropColor(0, 0, 0, 1)
        lootFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    end

    local frameData = { frame = lootFrame, key = lootKey }
    local timerId = math.random(1000000)

    lootData[lootKey] = {
        frame = lootFrame,
        textObj = text,
        quantity = quantity,
        timerId = timerId,
        hasBounty = hasBounty,
    }

    table.insert(lootFrames, 1, frameData)
    RepositionFrames()
    CreateFadeAnimation(lootFrame, true)
    lootFrame:Show()

    CreateTimer(settings.duration, function()
        if lootData[lootKey] and lootData[lootKey].timerId == timerId then
            lootData[lootKey] = nil
            CreateFadeAnimation(lootFrame, false, function()
                lootFrame:Hide()
                lootFrame:SetParent(nil)
                for i, data in ipairs(lootFrames) do
                    if data.frame == lootFrame then
                        table.remove(lootFrames, i)
                        break
                    end
                end
                RepositionFrames()
            end)
        end
    end)
end

f:RegisterEvent("CHAT_MSG_LOOT")
f:SetScript("OnEvent", function(self, event, arg1)
    ---@cast arg1 string
    if arg1:find("You sell:") or arg1:find("You destroy:") or arg1:find("passed on:") or arg1:find("passes on:") or arg1:find("Roll -") then
        return
    end

    if arg1:find("selected Disenchant") then
        local itemLink = arg1:match("|c%x+|Hitem.-|h%[.-%]|h|r")
        if itemLink then
            lastDisenchantItem = itemLink
            CreateTimer(0.5, function()
                lastDisenchantItem = nil
            end)
        end
        return
    end

    if arg1:find("selected Greed") or arg1:find("selected Need") then
        return
    end

    if arg1:find("You won:") then
        local itemLink = arg1:match("|c%x+|Hitem.-|h%[.-%]|h|r")
        if itemLink then
            ---@cast itemLink string
            if lastDisenchantItem and itemLink == lastDisenchantItem then
                return
            end
            local quality = GetQualityFromItemLink(itemLink)
            if quality >= 0 and quality < settings.minQuality then return end
            local itemID = itemLink:match("item:(%d+)")
            local texture = itemID and select(10, GetItemInfo(itemID)) or nil
            texture = texture or "Interface\\Icons\\INV_Misc_QuestionMark"
            CreateLootFrame(itemLink, texture, 1)
        end
        return
    end

    if arg1:find("You receive loot:") or arg1:find("You receive item:") or arg1:find("You create:") then
        local itemLink = arg1:match("|c%x+|Hitem.-|h%[.-%]|h|r")
        if itemLink then
            ---@cast itemLink string
            local quantity = tonumber(arg1:match("x(%d+)")) or 1
            local quality = GetQualityFromItemLink(itemLink)
            if quality >= 0 and quality < settings.minQuality then return end
            local itemID = itemLink:match("item:(%d+)")
            local texture = itemID and select(10, GetItemInfo(itemID)) or nil
            texture = texture or "Interface\\Icons\\INV_Misc_QuestionMark"
            CreateLootFrame(itemLink, texture, quantity)
        end
        return
    end

    local copper = arg1:match("(%d+) Copper")
    local silver = arg1:match("(%d+) Silver")
    local gold = arg1:match("(%d+) Gold")
    if copper or silver or gold then
        if not settings.showMoney then return end
        local totalCopper = (tonumber(gold) or 0) * 10000 + (tonumber(silver) or 0) * 100 + (tonumber(copper) or 0)
        if totalCopper > 0 then
            CreateLootFrame("Money", "Interface\\Icons\\INV_Misc_Coin_01", totalCopper)
        end
    end
end)
