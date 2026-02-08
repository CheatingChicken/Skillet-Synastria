# Skillet-Synastria Coding Instructions

This workspace develops **Skillet**, a World of Warcraft addon for the Synastria 3.3.5 private server. The addon enhances the default tradeskill UI with advanced queuing, cross-profession crafting, and custom server integrations.

## Architecture Overview

### Core Framework: Ace2
- Built on **Ace2** library system (legacy WoW addon framework)
- Main modules: `AceAddon-2.0`, `AceEvent-2.0`, `AceDB-2.0`, `AceHook-2.1`
- Global object: `Skillet` (accessible via `_G.Skillet`)
- Initialization: Auto-loaded on `ADDON_LOADED` event

### Data Flow
```
WoW TradeSkill Window → SkilletStitch → Skillet Core → UI Components
                            ↓
                     Recipe Database (per-profession)
                            ↓
                      Queue System → Crafting Engine
```

### Key Components
- **SkilletStitch-1.1.lua**: Recipe scanning/caching engine. Tracks all known recipes across professions.
- **SkilletQueue.lua**: Cross-profession queue with dependency resolution and auto-switching.
- **SkilletCraftCalc.lua**: Calculates craftability based on bags+bank+resource bank+alts.
- **SynastryAPI.lua**: Type definitions for custom server APIs (annotation-only file, not executed).
- **UI/**: Modular UI components with paired `.lua` (logic) and `.xml` (layout) files.

## Critical API Knowledge

### Synastria Custom APIs
The Synastria server provides custom APIs beyond standard WoW 3.3.5. Always consult SYNASTRIA_CUSTOM_API.md (in src/Skillet - Synastria/) before implementing server features.

**Working APIs** (verified):
- `Custom_GetProfessionRecipeInfo(spellId)` - Get recipe details by spell ID
- `Custom_GetProfessionRecipeReagents(spellId)` - Get reagent requirements
- `Custom_GetProfessionRecipeFromCraftedItem(itemId)` - Reverse lookup: item → spell
- `GetHighestAttunePct(itemId, forge)` - Check attunement status
- `GetCustomGameData(type, param)` - Type 13 = resource bank count

**Incomplete APIs** (see API-LIMITATIONS.md in Planning/Skillet/):
- `Custom_GetProfessionRecipes()` - Returns ~60% of recipes (missing consumables/enhancements)
- Use traditional window scanning (`GetNumTradeSkills()`) for complete data

### Standard WoW APIs
- `GetTradeSkillLine()` - Current profession name
- `GetNumTradeSkills()` - Count of recipes in open window
- `DoTradeSkill(index, repeat)` - Craft by window index
- `GetItemCount(itemLink, includeBank)` - Inventory count

## Code Conventions

### Lua Style
```lua
-- Naming: snake_case for locals, PascalCase for tables
local function calculate_needs(recipe, count)
    return recipe.required * count
end

-- Tables: Use dot notation for methods, colon for self methods
Skillet.someFunction() -- Global function
function Skillet:UpdateUI() -- Method with implicit self
end

-- Globals: Always check existence before use
if GetCustomGameData then
    local rbCount = GetCustomGameData(13, itemId) or 0
end
```

### Type Annotations (REQUIRED)

**CRITICAL**: All code must be fully annotated with LuaLS type annotations. Zero language server warnings are tolerated.

```lua
-- Annotate function parameters and returns
---@param spellId number The crafting spell ID
---@param count? number Optional craft count (default: 1)
---@return boolean success Whether crafting succeeded
---@return string? error Error message if failed
function Skillet:CraftRecipe(spellId, count)
    count = count or 1
    -- implementation
end

-- Annotate table structures
---@class Recipe
---@field link string Item link
---@field name string Recipe name
---@field index number Recipe index in tradeskill window
---@field nummade number Items created per craft
---@field reagents Reagent[] Required materials

---@class Reagent
---@field link string Item link
---@field needed number Count needed per craft
---@field name string Reagent name

-- Annotate complex types
---@type table<number, Recipe>
local recipeCache = {}
```

**Reference Pattern**: See SynastryAPI.lua (in src/Skillet - Synastria/) for server API annotations using `---@meta` directive.

**Before Committing**:
1. Run language server check in VS Code (no warnings should appear)
2. Annotate all function parameters, returns, and complex data structures
3. Use `---@type` for local variables with non-obvious types
4. Define `---@class` for all table structures used across files

**CRITICAL - Avoid Generic `table` Type**:
- NEVER use `---@type table` or `table[]` - these cause widespread type inference failures
- Always define specific table structures using `---@class` and then reference by name
- Even if you're not sure of the complete structure, define what you know:

```lua
-- BAD - causes type inference to fail completely downstream
---@type table | nil
local characters

-- GOOD - defines structure even if nested
---@class Character
---@field name string
---@field [integer] Profession

---@class Profession
---@field name string
---@field [integer] Skill

---@type Character[] | nil
local characters
```

- Generic `table` types propagate error through entire call chains. Downstream code cannot infer what fields exist, leading to "Cannot infer type" errors
- If a table has both named fields AND array elements, use `[integer]` for the array part: `---@field [integer] ItemType`
- Always prefer specific table types over generic `table`, even if structure is complex

**CRITICAL - Avoid `any` Type**:
- NEVER use `---@param self any` or `---@type any` - this disables all type checking and causes cascading errors
- Always define specific types for parameters, even if only to hold known methods/fields:

```lua
-- BAD - disables type checking, prevents inference in function body
---@param self any
local function process(self, name)
    self.db.recipes[name] -- Type of db and recipes unknown
end

-- GOOD - defines what self must provide
---@class BuildContext
---@field db table Database
---@field stitch SkilletStitch

---@param self BuildContext
local function process(self, name)
    self.db.recipes[name] -- Type information preserved
end
```

- `any` is the opposite of type safety. Use it only for truly dynamic external APIs without type information
- Prefer creating minimal `---@class` definitions over using `any`

### Data Structures
- **Recipe Table**: `{ link, name, index, nummade, reagents[], numcraftable, difficulty }`
- **Queue Item**: `{ link, index, count, profession, [spellId] }`
- **Saved Variables**: `SkilletDB` (account-wide), `SkilletDBPC` (per-character)

### Error Handling
```lua
-- Use assertions for developer errors
assert(skillIndex and recipe, "Usage: add_to_queue(skillIndex, recipe, count)")

-- Use print for user-facing errors
Skillet:Print("|cFFFF0000Error:|r Recipe not found")

-- Silent fallbacks for optional features
local count = GetCustomGameData(13, itemId) or 0
```

## Development Workflow

### Testing Process
1. **Edit in VS Code** - Make changes to `.lua`/`.xml` files
2. **Annotate** - Add type annotations for all new functions/tables
3. **Verify** - Check VS Code Problems panel (Ctrl+Shift+M) - MUST show 0 warnings
4. **Syntax Check** - Run `luac -p file.lua` to verify Lua syntax
5. **Reload in WoW** - Type `/reload` in-game to reload UI
6. **Test via commands** - Use `/script` commands from TESTING-PHASE-*.md files (in Planning/Skillet/)
7. **Check errors** - Monitor chat for Lua errors (red text)

### Manual Testing Commands
```lua
-- Test basic functionality
/script Skillet:Print("Test message")
/script Skillet:RunCrossProfessionTestSuite()

-- Debug queue state
/script Skillet:DumpQueue()
/script Skillet:PrintQueueDebug()

-- Test API availability
/script print(Custom_GetProfessionRecipeInfo and "API OK" or "API missing")
```

### No Automated Tests
- **No unit tests** - All testing is manual in-game
- **No build system** - Files are loaded directly by WoW client
- **No linter** - Use `luac -p file.lua` for syntax validation only

## ✨ Annotation Purity (CRITICAL)

**As of 2026-02-08**: All UI files have achieved **ZERO type errors**. This is a purified state that MUST be maintained.

**IMPORTANT**: See annotation-purity.instructions.md (in .github/instructions/) for comprehensive maintenance guidelines.

### Current Purified Files (0 Errors Each)
- ✅ All 12 UI files: ExtractionFrame, MerchantWindow, ProfessionSelector, RecipeNotes, ShoppingList, UITypes, Sorting, SlotFilter, AttunabilityFilter, Utils, SkilletTestingUI, MainFrame
- ✅ Upgrades.lua (with justified diagnostic suppressions)

### Before Every Commit
**ZERO TOLERANCE RULE**: Any committed code must have zero language server errors.

```bash
# Verify your changes:
1. Run: get_errors [filePath]
2. Check VS Code Problems panel (Ctrl+Shift+M) - must show 0 errors
3. If errors exist, fix them BEFORE committing
4. Never commit with warnings
```

### When Adding New Code
```lua
-- ✅ Every function annotated
---@param tradeskill string The profession name
---@return boolean isValid True if valid
function Skillet:ValidateProfession(tradeskill)
    -- implementation
end

-- ✅ Every complex local variable typed
---@type table<string, number>
local itemCounts = {}

-- ❌ Never commit unannotated code
function SomeFunction() -- Missing annotations!
    return true
end
```

### Key Rules to Maintain Purity
1. **No generic `table` type** - Always define specific `---@class` structures
2. **No bare `any` type** - Use specific class definitions instead
3. **Nil safety guards required** - Check before accessing table fields
4. **Explicit frame type casts** - Use `--[[@as FrameType]]` after `CreateFrame()`
5. **Loop variable typing** - Type variables in `ipairs()` and `pairs()` iterations when needed

See annotation-purity.instructions.md (in .github/instructions/) for detailed patterns and examples.

## File Organization

### Load Order (from Skillet - Synastria.toc in src/Skillet - Synastria/)
```
embeds.xml           # Ace2 + library dependencies
Locale/*.lua         # Localization strings
LibPossessions.lua   # Alt inventory tracking
SkilletStitch-1.1.lua# Recipe database
Skillet.lua          # Core addon logic
SkilletQueue.lua     # Queue system
UI/*.lua             # UI components (order matters!)
Integrations/*.lua   # Third-party integrations
```

**CRITICAL**: Files load in TOC order. Dependencies must load before dependents.

### UI Pairing Convention
- `UI/MainFrame.xml` defines frames/buttons
- `UI/MainFrame.lua` implements logic
- XML creates globals (e.g., `SkilletFrame`), Lua references them

## Key Patterns

### Queue Dependency Resolution
The queue auto-adds subrecipes for missing materials:
```lua
-- Pattern: Check inventory → Check resource bank → Queue dependencies → Add recipe
if have < needed then
    local item = Skillet.stitch:GetItemDataByName(reagent.name)
    if item and item.craftable then
        add_items_to_queue(item.index, item, needed - have, nil, true) -- Add to top
    end
end
add_items_to_queue(skillIndex, recipe, count) -- Then add main recipe
```

### Cross-Profession Switching
```lua
-- Pattern: Save current → Switch → Wait for event → Restore
local originalProfession = GetTradeSkillLine()
CastSpellByName("Blacksmithing") -- Triggers TRADE_SKILL_SHOW event
-- ... event handler re-opens appropriate window ...
```

### Resource Bank Integration
```lua
-- Pattern: Always add resource bank to inventory counts
local have = GetItemCount(itemLink, true) -- Bags + bank
if GetCustomGameData then
    have = have + (GetCustomGameData(13, itemId) or 0) -- + resource bank
end
```

## Common Pitfalls

1. **API Assumptions**: Don't assume custom APIs are complete. Check API-LIMITATIONS.md (in Planning/Skillet/) first.
2. **Event Timing**: Profession switches aren't instant. Use `TRADE_SKILL_SHOW` event, not immediate checks.
3. **Queue Recursion**: Prevent infinite loops when queueing dependencies (see `queueSnapshot` pattern in SkilletQueue.lua in src/Skillet - Synastria/, lines 60-80).
4. **Global Pollution**: All WoW addons share global namespace. Prefix globals with `Skillet` or use locals.
5. **TOC Version**: Must match WoW client (`## Interface: 30300` = 3.3.0).
6. **Missing Type Annotations**: NEVER commit code with language server warnings. All functions, parameters, and complex types MUST be annotated.

## Active Development Focus

Current work revolves around spell-based crafting (see Planning/Skillet/ directory):
- Phase 1: Recipe scanning (COMPLETE)
- Phase 2: Spell-based crafting via `Custom_DoProfessionRecipe()` (IN PROGRESS)
- Phase 3: Multi-profession queue optimization (PLANNED)

When modifying queue/crafting logic, reference the planning docs for architectural decisions and known edge cases.

## Debugging Techniques

```lua
-- Print to chat
DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00Debug:|r " .. tostring(value))

-- Table dumps
for k, v in pairs(Skillet.stitch.queue) do
    print(k, v.link, v.count)
end

-- Event monitoring
Skillet:RegisterEvent("TRADE_SKILL_UPDATE")
function Skillet:TRADE_SKILL_UPDATE()
    self:Print("Trade skill window updated")
end
```

## File Naming Exceptions

- **Original addon files**: Keep original names (e.g., `Skillet.lua`, `TradeskillInfo.lua`)
- **Synastria additions**: Use descriptive names (e.g., `SynastryAPI.lua`, `ResourceTracker.lua`)
- **UI components**: Match frame name (e.g., `MainFrame.lua` for `SkilletFrame`)

---

**When in doubt**: Check existing code patterns in Skillet.lua (in src/Skillet - Synastria/), consult SYNASTRIA_CUSTOM_API.md (in src/Skillet - Synastria/), and test in-game early and often.
