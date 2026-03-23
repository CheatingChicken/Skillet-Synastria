# LootPop — Agent Reference

## Purpose

LootPop is a standalone WoW 3.3.5 addon that replaces the default chat-based loot
notifications with compact animated popup frames anchored anywhere on screen. Each
popup shows the item icon, coloured item link, and optional quantity. Popups
stack upward or downward, auto-fade after a configurable duration, and de-duplicate
repeated drops into a running count.

---

## File Inventory

| File | Role |
|---|---|
| `LootPop.lua` | All runtime logic; the only file loaded by the WoW client |
| `LootPopAPI.lua` | `---@meta` annotation file; defines all types used by `LootPop.lua`; **never loaded by WoW** |
| `LootPop.toc` | Addon descriptor; registers `LootPopDB` as a saved variable |

Type dependency chain:
```
LootPopAPI.lua  ←  src/Shared/WoWCommonAPI.lua   (Frame, Button, Texture, FontString …)
                ←  src/Shared/SynastryCommonAPI.lua  (GetCustomGameData)
```

---

## Architecture Overview

```
WoW Event: CHAT_MSG_LOOT
        │
        ▼
  f:SetScript("OnEvent")  — message filter pipeline
        │  • strips sell / destroy / pass / roll messages
        │  • intercepts Disenchant → sets lastDisenchantItem guard
        │  • routes "You won:" / "You receive loot:" / "You create:" → CreateLootFrame()
        │  • parses money amounts → CreateLootFrame("Money", ...)
        ▼
  CreateLootFrame(itemLink, texture, quantity)
        │  • looks up lootKey in lootData (de-duplicate path)
        │  • OR creates new 32px backdrop frame on UIParent
        │  • detects ForgeType via GetForgeTypeFromItemString()
        │  • detects bounty via HasBounty() → GetCustomGameData(31, itemId)
        │  • schedules expiry via CreateTimer(duration, fadeOut callback)
        ▼
  lootFrames[]  +  lootData{}  (live state)
        │
        ▼
  CreateFadeAnimation()  ←  driven by fadeFrame:OnUpdate
        │
        ▼
  Frame cleanup: :Hide() → :SetParent(nil) → remove from lootFrames → RepositionFrames()
```

---

## State Management

### `lootFrames` — ordered display list
`LootFrameData[]`. Element `[1]` is the **newest** (most-recently-looted) entry.
Grows at the front via `table.insert(lootFrames, 1, frameData)`.
Shrinks from the tail via `RemoveOldestFrame()` when the cap is hit.

### `lootData` — dedup registry
`table<string, LootEntry>`. Keyed by **loot key** (item link with `x<n>` suffix
stripped by `GetLootKey()`). Allows `CreateLootFrame()` to find an existing popup
for the same item and increment its displayed count instead of creating a second frame.

### Relationship
Both tables hold a reference to the same `Frame` object. Removal from `lootData`
signals "this entry is expiring" while `lootFrames` is only pruned after the fade
callback fires. Keep them in sync — a frame should NEVER exist in `lootFrames`
without a matching `lootData` entry unless it is currently inside the fade-out
callback.

### `activeTimers` and timer cancellation
Each `LootEntry.timerId` is a random integer minted at creation time. The associated
`CreateTimer()` callback checks `lootData[lootKey].timerId == timerId` before acting;
a newer timer overwrites `timerId`, making stale callbacks a no-op. This replaces
per-timer cancellation without needing an ID-keyed cancel API.

---

## Core Function Reference

### Event / Init

| Function | Inputs | Outputs / Side-effects |
|---|---|---|
| `addonFrame:OnEvent` | `event`, `addonName` | `ADDON_LOADED` → `LoadAllSettings()`; `PLAYER_LOGOUT` → `SaveAllSettings()` |
| `SaveAllSettings()` | — | Writes `settings` + anchor position to `LootPopDB` |
| `LoadAllSettings()` | — | Reads `LootPopDB` into `settings`; repositions anchor |

### Popup Lifecycle

| Function | Inputs | Outputs / Side-effects |
|---|---|---|
| `CreateLootFrame(itemLink, texture, quantity)` | item hyperlink or `"Money"`, texture path/ID, optional count | Creates or updates a popup frame; schedules fade timer |
| `RemoveOldestFrame()` | — | Evicts `lootFrames[#lootFrames]` if cap reached; cancels its timer |
| `RepositionFrames(skipFadingFrames)` | unused param | Recalculates TOPLEFT/BOTTOMLEFT for all non-fading frames based on `growUp` + `spacing` |
| `CreateFadeAnimation(frame, fadeIn, callback?)` | target frame, direction, optional completion callback | Registers an `FadeEntry`; drives alpha via `fadeFrame:OnUpdate`; stops the OnUpdate when the queue is empty |

### Helpers

| Function | Inputs | Outputs |
|---|---|---|
| `GetLootKey(itemLink)` | raw item link (may end in `x<n>`) | Normalised dedup key (quantity suffix stripped) |
| `GetForgeTypeFromItemString(itemLink)` | item hyperlink or `nil` | `ForgeType` (`"titanforged"`, `"warforged"`, `"lightforged"`) or `nil` |
| `HasBounty(itemId)` | item ID or `nil` | `boolean` — calls `GetCustomGameData(31, itemId)` |
| `CreateTimer(delay, callback)` | seconds, function | Appends to `activeTimers`; fired by `timerFrame:OnUpdate` |

### Config UI

| Function | Inputs | Outputs |
|---|---|---|
| `CreateSlider(parent, name, width, x, y, minVal, maxVal, currentVal, step, labelText)` | all layout params | `Slider` frame |
| `CreatePreviewFrame(index)` | ordinal | `Frame` — preview row parented to `anchor` |
| `UpdatePreviewFrames()` | — | Hides all previews; creates/shows `maxEntries-1` rows using current settings |

---

## Settings & Persistence

### Runtime object: `settings: LootPopSettings`
```lua
{
    spacing    = 0,       -- pixels between frames
    scale      = 1.0,     -- UI scale
    maxEntries = 10,      -- max simultaneous popups
    frameStrata = "DIALOG",
    growUp     = true,    -- stack direction
    duration   = 5,       -- seconds on screen
}
```

### Saved variable: `LootPopDB: LootPopSavedVars`
Extends `LootPopSettings` with:
- `anchorX` — TOPLEFT X offset from UIParent (integer pixels)
- `anchorY` — TOPLEFT Y offset from UIParent (negative = below top edge)

`LoadAllSettings()` runs on `ADDON_LOADED`; `SaveAllSettings()` runs on `PLAYER_LOGOUT`
and on every config slider/dropdown change.

---

## Forge Type Detection

LootPop reads the **unique-ID field** (position 8 in the item string, zero-indexed)
directly from the item hyperlink without opening a tooltip.

```
item:12345:0:0:0:0:0:0:<uniqueId>:...
                              ↑
                         parts[8] (1-indexed after strsplit ":")
```

Thresholds (from `FORGE_VALUES`):

| Range | Forge tier |
|---|---|
| ≥ 12288 | `"lightforged"` |
| ≥ 8192  | `"warforged"` |
| ≥ 4096  | `"titanforged"` |

No tooltip scan required; this is significantly faster for high-volume loot.

---

## Synastria Custom API Usage

| Call | Data type | Purpose |
|---|---|---|
| `GetCustomGameData(31, itemId)` | 31 = bounty gold value | Returns a gold amount `> 0` if the item has an active server bounty; drives the gold coin icon shown next to the item icon |

If the API is unavailable (standard WoW client), `GetCustomGameData` will be `nil`;
`HasBounty()` guards this via `if not itemId then return false end` but the outer
call site should also guard `if GetCustomGameData then` when porting.

---

## Event Handler Filtering Logic

Messages are tested in priority order to avoid cross-matching:

1. **Suppress** any message containing `"You sell:"`, `"You destroy:"`, `"passed on:"`, `"passes on:"`, `"Roll -"`.
2. **Intercept** `"selected Disenchant"` → capture item link; set `lastDisenchantItem` for 0.5 s.
3. **Skip** `"selected Greed"` / `"selected Need"` (roll announcements).
4. **Handle** `"You won:"` → suppress if `lastDisenchantItem` matches → show popup.
5. **Handle** `"You receive loot:"` / `"You receive item:"` / `"You create:"` → parse quantity → show popup.
6. **Handle** money pattern (Gold/Silver/Copper) → compute total copper → show popup with coin icon.

---

## Known Limitations / Edge Cases

- `money` loot is tracked under the fixed key `"Money"` — multiple copper drops within the duration window accumulate but are treated as a single entry.
- `SetParent(nil)` is called on expired frames to release them from the frame hierarchy; this is valid WoW 3.3.5 but the type stub in `WoWCommonAPI.lua` explicitly allows `nil` for this reason.
- `GetItemInfo()` may return a numeric texture ID rather than a path string on some items; `CreateLootFrame`'s `texture` parameter and `Texture:SetTexture` both accept `string|number`.
