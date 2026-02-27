-- NameplateCounter
-- Tracks visible nameplate counts, optionally filtered by mob name.
-- Integrates with ElvUI NamePlates; falls back to WorldFrame scan.
-- Slash: /npc  (or /nameplatecount)

-- ============================================================================
-- Type Definitions
-- ============================================================================

---@class NCConfig
---@field enabled boolean
---@field hideWhenZero boolean
---@field filters string[]
---@field x number
---@field y number
---@field fontSize number
---@field locked boolean

--- Minimal ElvUI stub — only the fields this addon touches.
---@class ElvUIAddon
---@field GetModule fun(self: ElvUIAddon, name: string, silent?: boolean): ElvUINP|nil

---@class ElvUINP
---@field VisiblePlates table<ElvUINPFrame, boolean>
---@field Update_Name fun(self: ElvUINP, frame: ElvUINPFrame, triggered?: boolean)
---@field Initialized boolean

---@class ElvUINPFrame
---@field UnitName string|nil

--- NC addon object
---@class NCAddon
---@field frame Frame|nil
---@field label FontString|nil
---@field count integer
---@field perName table<string, integer>
---@field elvHooked boolean
---@field ticker table|nil

-- ============================================================================
-- Globals / Saved Variables
-- ============================================================================

---@type NCConfig
---@diagnostic disable-next-line: missing-fields
NameplateCounterDB = NameplateCounterDB or {} --[[@as NCConfig]]

-- ============================================================================
-- Addon Object
-- ============================================================================

---@type NCAddon
local NC = {
    frame     = nil,
    label     = nil,
    count     = 0,
    perName   = {},
    elvHooked = false,
    ticker    = nil,
}

--- Default settings
---@type NCConfig
local DEFAULTS = {
    enabled      = true,
    hideWhenZero = false,
    filters      = {},
    x            = 100,
    y            = -200,
    fontSize     = 14,
    locked       = false,
}

-- ============================================================================
-- DB Helpers
-- ============================================================================

---@overload fun(key: "enabled"): boolean
---@overload fun(key: "hideWhenZero"): boolean
---@overload fun(key: "locked"): boolean
---@overload fun(key: "filters"): string[]
---@overload fun(key: "x"): number
---@overload fun(key: "y"): number
---@overload fun(key: "fontSize"): number
local function DB(key)
    ---@diagnostic disable-next-line: no-unknown
    if NameplateCounterDB[key] == nil then
        ---@diagnostic disable-next-line: no-unknown
        NameplateCounterDB[key] = DEFAULTS[key]
    end
    ---@diagnostic disable-next-line: no-unknown
    return NameplateCounterDB[key]
end

---@param key string
---@param value any
local function DBSet(key, value)
    ---@diagnostic disable-next-line: no-unknown
    NameplateCounterDB[key] = value
end

-- ============================================================================
-- Count Logic
-- ============================================================================

-- Rebuild counts from the live nameplate source and store on NC
function NC:RebuildCounts()
    local filters   = DB("filters")
    local hasFilter = #filters > 0

    -- Build lookup set
    ---@type table<string, boolean>
    local filterSet = {}
    for _, name in ipairs(filters) do
        if name ~= "" then
            filterSet[name] = true
        end
    end

    local count   = 0
    ---@type table<string, integer>
    local perName = {}

    -- PRIMARY: ElvUI NP.VisiblePlates
    local E       = _G.ElvUI and (_G.ElvUI[1] --[[@as ElvUIAddon]])
    local NP      = E and E:GetModule("NamePlates", true)

    if NP and NP.VisiblePlates then
        for frame in pairs(NP.VisiblePlates) do
            local mobName = frame.UnitName
            if mobName then
                if not hasFilter then
                    count = count + 1
                elseif filterSet[mobName] then
                    count = count + 1
                    perName[mobName] = (perName[mobName] or 0) + 1
                end
            end
        end
    else
        -- FALLBACK: WorldFrame children scan for Blizzard nameplates
        ---@type Frame[]
        local wfChildren = { WorldFrame:GetChildren() } ---@diagnostic disable-line
        for _, f in ipairs(wfChildren) do
            local frameName = f:GetName()
            if frameName and frameName:find("NamePlate") and f:IsVisible() then
                ---@diagnostic disable-next-line: undefined-field
                local nameRegion = (f --[[@as table]]).name or (f --[[@as table]]).Name --[[@as FontString|nil]]
                local mobName    = nameRegion and nameRegion:GetText()
                if mobName then
                    if not hasFilter then
                        count = count + 1
                    elseif filterSet[mobName] then
                        count = count + 1
                        perName[mobName] = (perName[mobName] or 0) + 1
                    end
                end
            end
        end
    end

    self.count   = count
    self.perName = perName
end

-- ============================================================================
-- Display
-- ============================================================================

function NC:BuildDisplayText()
    local filters   = DB("filters")
    local hasFilter = #filters > 0

    if hasFilter then
        ---@type string[]
        local lines = {}
        for _, name in ipairs(filters) do
            if name ~= "" then
                local c = (self.perName[name] or 0) --[[@as integer]]
                lines[#lines + 1] = name .. ": " .. tostring(c)
            end
        end
        return table.concat(lines, "\n")
    else
        return "Nameplates: " .. (self.count or 0)
    end
end

function NC:UpdateDisplay()
    if not self.frame then return end

    if not DB("enabled") then
        self.frame:Hide()
        return
    end

    self:RebuildCounts()

    if DB("hideWhenZero") and (self.count or 0) == 0 then
        self.frame:Hide()
        return
    end

    self.label:SetText(self:BuildDisplayText())
    self.label:SetFont(self.label:GetFont(), DB("fontSize"), "OUTLINE")
    self.frame:Show()
end

-- ============================================================================
-- Frame Construction
-- ============================================================================

function NC:CreateFrame()
    local f = CreateFrame("Frame", "NameplateCounterFrame", UIParent)
    f:SetWidth(200)
    f:SetHeight(120)
    f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", DB("x"), DB("y"))
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)

    f:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and not DB("locked") then
            self:StartMoving()
        end
    end)
    f:SetScript("OnMouseUp", function(self)
        self:StopMovingOrSizing()
        local gp = table.pack(self:GetPoint())
        DBSet("x", (gp[4] --[[@as number]]) or 0)
        DBSet("y", (gp[5] --[[@as number]]) or 0)
    end)

    -- Subtle background
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(0, 0, 0, 0.55)

    local label = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", f, "TOPLEFT", 6, -6)
    label:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -6, 6)
    label:SetJustifyH("LEFT")
    label:SetJustifyV("TOP")
    label:SetFont(label:GetFont(), DB("fontSize"), "OUTLINE")

    f:Hide()

    self.frame = f
    self.label = label
end

-- ============================================================================
-- ElvUI Hook
-- ============================================================================

function NC:HookElvUI()
    local E  = _G.ElvUI and (_G.ElvUI[1] --[[@as ElvUIAddon]])
    local NP = E and E:GetModule("NamePlates", true)

    if NP and NP.Update_Name and not self.elvHooked then
        -- Capture self as upvalue — hooksecurefunc fires outside WA/NC scope
        local addon = self
        hooksecurefunc(NP, "Update_Name", function()
            addon:UpdateDisplay()
        end)
        self.elvHooked = true
    end

    return self.elvHooked
end

-- ============================================================================
-- Fallback Ticker
-- ============================================================================

function NC:StartFallbackTicker()
    if self.ticker then return end
    local addon = self
    self.ticker = C_Timer.NewTicker(0.5, function()
        addon:UpdateDisplay()
    end)
end

function NC:StopFallbackTicker()
    if self.ticker then
        self.ticker:Cancel()
        self.ticker = nil
    end
end

--- Enable or disable the counter, starting/stopping scanning accordingly.
---@param state boolean
function NC:SetEnabled(state)
    DBSet("enabled", state)
    if state then
        if not self.elvHooked then
            self:StartFallbackTicker()
        end
        self:UpdateDisplay()
    else
        -- Stop the ticker so we don't scan while hidden
        self:StopFallbackTicker()
        if self.frame then
            self.frame:Hide()
        end
    end
end

-- ============================================================================
-- Initialisation
-- ============================================================================

function NC:Init()
    -- Migrate missing keys from defaults
    for k, v in pairs(DEFAULTS) do
        ---@diagnostic disable-next-line: no-unknown
        if NameplateCounterDB[k] == nil then
            ---@diagnostic disable-next-line: no-unknown
            NameplateCounterDB[k] = v
        end
    end

    self:CreateFrame()

    -- Try ElvUI hook; if unavailable, fall back to ticker (only when enabled)
    if not self:HookElvUI() and DB("enabled") then
        self:StartFallbackTicker()
    end

    self:UpdateDisplay()
    print("|cFF00CCFFNameplateCounter|r loaded. Type |cFFFFFF00/npc help|r for commands.")
end

-- ============================================================================
-- Event Handler
-- ============================================================================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        NC:Init()
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Re-attempt ElvUI hook after world load (modules may not be ready at LOGIN)
        if not NC.elvHooked then
            if not NC:HookElvUI() then
                NC:StartFallbackTicker()
            end
        end
        NC:UpdateDisplay()
    end
end)

-- ============================================================================
-- Slash Commands
-- ============================================================================

local function PrintHelp()
    print("|cFF00CCFFNameplateCounter commands:|r")
    print("  |cFFFFFF00/npc add <name>|r    - Add a mob name to track")
    print("  |cFFFFFF00/npc remove <name>|r - Remove a tracked mob name")
    print("  |cFFFFFF00/npc list|r          - List all tracked names")
    print("  |cFFFFFF00/npc clear|r         - Remove all filters (show all nameplates)")
    print("  |cFFFFFF00/npc toggle|r        - Show / hide the counter")
    print("  |cFFFFFF00/npc zero|r          - Toggle 'hide when zero'")
    print("  |cFFFFFF00/npc lock|r          - Toggle frame lock (prevent dragging)")
    print("  |cFFFFFF00/npc size <n>|r      - Set font size (e.g. /npc size 16)")
    print("  |cFFFFFF00/npc reset|r         - Reset frame position")
end

SLASH_NAMEPLATECOUNTER1 = "/npc"
SLASH_NAMEPLATECOUNTER2 = "/nameplatecount"

SlashCmdList["NAMEPLATECOUNTER"] = function(msg)
    msg = msg and msg:match("^%s*(.-)%s*$") or ""
    local cmd, arg = msg:match("^(%S+)%s*(.*)")
    cmd = cmd and cmd:lower() or ""

    if cmd == "add" and arg and arg ~= "" then
        local filters = DB("filters")
        -- Deduplicate
        for _, v in ipairs(filters) do
            if v == arg then
                print("|cFF00CCFFNameplateCounter:|r |cFFFFFF00" .. arg .. "|r is already tracked.")
                return
            end
        end
        filters[#filters + 1] = arg
        print("|cFF00CCFFNameplateCounter:|r Now tracking |cFFFFFF00" .. arg .. "|r")
        NC:UpdateDisplay()
    elseif cmd == "remove" and arg and arg ~= "" then
        local filters = DB("filters")
        local found = false
        for i, v in ipairs(filters) do
            if v == arg then
                table.remove(filters, i)
                found = true
                break
            end
        end
        if found then
            print("|cFF00CCFFNameplateCounter:|r Removed |cFFFFFF00" .. arg .. "|r")
        else
            print("|cFF00CCFFNameplateCounter:|r |cFFFFFF00" .. arg .. "|r was not in the filter list.")
        end
        NC:UpdateDisplay()
    elseif cmd == "list" then
        local filters = DB("filters")
        if #filters == 0 then
            print("|cFF00CCFFNameplateCounter:|r No filters set — counting all nameplates.")
        else
            print("|cFF00CCFFNameplateCounter:|r Tracking:")
            for i, v in ipairs(filters) do
                print("  " .. i .. ". " .. v)
            end
        end
    elseif cmd == "clear" then
        DBSet("filters", {})
        print("|cFF00CCFFNameplateCounter:|r All filters cleared.")
        NC:UpdateDisplay()
    elseif cmd == "toggle" then
        local newState = not DB("enabled")
        NC:SetEnabled(newState)
        print("|cFF00CCFFNameplateCounter:|r Display " ..
            (newState and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r (scanning paused)"))
    elseif cmd == "zero" then
        DBSet("hideWhenZero", not DB("hideWhenZero"))
        print("|cFF00CCFFNameplateCounter:|r Hide-when-zero: " ..
            (DB("hideWhenZero") and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"))
        NC:UpdateDisplay()
    elseif cmd == "lock" then
        DBSet("locked", not DB("locked"))
        print("|cFF00CCFFNameplateCounter:|r Frame " .. (DB("locked") and "|cFF00FF00locked|r" or "|cFFFF0000unlocked|r"))
    elseif cmd == "size" then
        local n = tonumber(arg)
        if n and n >= 6 and n <= 48 then
            DBSet("fontSize", n)
            NC.label:SetFont(NC.label:GetFont(), n, "OUTLINE")
            NC:UpdateDisplay()
            print("|cFF00CCFFNameplateCounter:|r Font size set to " .. n)
        else
            print("|cFF00CCFFNameplateCounter:|r Usage: /npc size <6-48>")
        end
    elseif cmd == "reset" then
        DBSet("x", DEFAULTS.x)
        DBSet("y", DEFAULTS.y)
        NC.frame:ClearAllPoints()
        NC.frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", DEFAULTS.x, DEFAULTS.y)
        print("|cFF00CCFFNameplateCounter:|r Position reset.")
    else
        PrintHelp()
    end
end
