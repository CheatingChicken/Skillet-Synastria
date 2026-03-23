---@meta
-- ====================================================================
-- LootPopAPI.lua — LootPop Addon Type Definitions
-- ====================================================================
-- Canonical type declarations for all data structures used inside
-- LootPop.lua. Frame base-types (Frame, Button, FontString, Texture,
-- Slider, EditBox) and global WoW API stubs (CreateFrame, GetItemInfo,
-- UIDropDownMenu_*, GetCustomGameData, etc.) are provided by the shared
-- meta files in src/Shared/ via .luarc.json workspace.library.
-- NEVER loaded by the WoW client (---@meta file, annotation-only).
-- ====================================================================

-- ----------------------------------------------------------------
-- Forge Type
-- ----------------------------------------------------------------

--- The three Synastria forge tiers detectable via item-string bit-ranges.
---@alias ForgeType "titanforged"|"warforged"|"lightforged"

-- ----------------------------------------------------------------
-- Forge Value Constants
-- ----------------------------------------------------------------

---@class ForgeValueTable
---@field TITANFORGED number Minimum unique-ID threshold for titanforged (4096)
---@field WARFORGED   number Minimum unique-ID threshold for warforged   (8192)
---@field LIGHTFORGED number Minimum unique-ID threshold for lightforged (12288)

-- ----------------------------------------------------------------
-- Item Quality Color (r, g, b triple indexed 1–3)
-- ----------------------------------------------------------------

---@class ItemQualityColor
---@field [1] number Red component (0–1)
---@field [2] number Green component (0–1)
---@field [3] number Blue component (0–1)

-- ----------------------------------------------------------------
-- Saved Variables / Settings
-- ----------------------------------------------------------------

--- Runtime-only settings table (populated from LootPopDB on load).
---@class LootPopSettings
---@field spacing    number  Vertical pixel gap between loot frames
---@field scale      number  UI scale factor applied to all loot/anchor frames
---@field maxEntries number  Maximum simultaneous loot popup entries shown
---@field frameStrata string Frame strata for all loot popup frames (e.g., "DIALOG")
---@field growUp     boolean True = stack frames upward from anchor; false = downward
---@field duration   number  Seconds each loot entry is displayed before fading
---@field minQuality number  Minimum item quality (0=Poor … 6=Artifact) required to show popup
---@field showMoney  boolean True = show money loot popups; false = suppress them

--- Persisted saved-variable table (written to LootPopDB on logout).
---@class LootPopSavedVars : LootPopSettings
---@field anchorX      number  Left X position of the anchor frame (UIParent-relative TOPLEFT)
---@field anchorY      number  Top  Y position of the anchor frame (UIParent-relative TOPLEFT, negative = below)
---@field minimapAngle number  Degrees clockwise from the 3-o'clock position for the minimap button

-- ----------------------------------------------------------------
-- Loot Entry (lootData table values)
-- ----------------------------------------------------------------

--- A single active loot popup entry tracked in lootData[key].
---@class LootEntry
---@field frame    Frame      The visible backdrop frame for this popup
---@field textObj  FontString The FontString showing the item link + quantity
---@field quantity number     Accumulated quantity for this item since last reset
---@field timerId  number     Random ID token for the current expiry timer (used to cancel stale timers)
---@field hasBounty boolean   True when a bounty coin icon is shown next to the item icon

-- ----------------------------------------------------------------
-- Loot Frame Data (lootFrames array elements)
-- ----------------------------------------------------------------

--- An element in the ordered lootFrames array; maps a frame to its dedup key.
---@class LootFrameData
---@field frame Frame  The popup frame for this loot event
---@field key   string The dedup key (item link with quantity suffix stripped)

-- ----------------------------------------------------------------
-- Timer Entry (activeTimers array elements)
-- ----------------------------------------------------------------

--- A pending one-shot timer entry driven by timerFrame:OnUpdate.
---@class TimerEntry
---@field timeLeft number        Remaining seconds before the callback fires
---@field callback fun(): nil    The function to call when the timer expires
---@field id?      number        Optional identity token used to cancel a specific timer

-- ----------------------------------------------------------------
-- Fade Animation Entry (activeFades array elements)
-- ----------------------------------------------------------------

--- A frame currently being faded in or out by the shared fadeFrame:OnUpdate driver.
---@class FadeEntry
---@field frame      Frame              The frame whose alpha is being animated
---@field fadeTimer  number             Elapsed time since the fade started (seconds)
---@field fadeIn     boolean            True = fade in (0 → 1), false = fade out (1 → 0)
---@field callback?  fun(): nil         Called once when the fade completes

-- ----------------------------------------------------------------
-- Forge Color Pair (bg + border color for each forge tier)
-- ----------------------------------------------------------------

--- An RGBA 4-component color vector used for backdrop / border coloring.
---@class RGBAColor
---@field [1] number Red
---@field [2] number Green
---@field [3] number Blue
---@field [4] number Alpha

--- Backdrop + border color pair for a single forge tier.
---@class ForgeColorPair
---@field [1] RGBAColor Background color
---@field [2] RGBAColor Border color

-- ----------------------------------------------------------------
-- Global Saved Variable (declared global by WoW SavedVariables)
-- ----------------------------------------------------------------

---@type LootPopSavedVars
LootPopDB = {
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
