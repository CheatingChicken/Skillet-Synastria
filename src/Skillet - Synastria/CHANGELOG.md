# Changelog

All notable changes to Skillet - Synastria Edition will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

## [1.14-beta1] - 2026-02-15

### Added
- **Shopping List Enhancements**
  - Real-time inventory updates via BAG_UPDATE event (refreshes while window open)
  - Debug mode button for diagnostic Shopping List calculation breakdown
  - Comprehensive shopping list calculation logging system

- **Diagnostic Logging System**
  - New SkilletLog system for persistent debug output across multiple categories
  - LogViewer UI with copyable logs and group navigation
  - `/skillet log` command to view diagnostic output
  - Multi-group organization for different diagnostic categories
  - Export functionality for sharing debug information

- **Database System**
  - Centralized conversion database (ConversionData.lua) with 50+ transformations
  - Milling database (MillingData.lua) covering herbs from Vanilla to Wrath
  - Prospecting database (ProspectingData.lua) for ore→gem loot tables
  - All databases support future expansion via simple table entries

### Changed
- **Shopping List Eternal/Crystallized Transparency**
  - Shopping list now shows only **base ingredients** (Crystallized) instead of conversions
  - **Before**: "Need 2 Eternal Air" + "Can convert from 10 Crystallized Air"
  - **After**: "Need 20 Crystallized Air" (1 Eternal = 10 Crystallized factored in)
  - Eliminates conversion clutter and shows exactly what to gather
  - Items with count ≤ 0 now properly filtered from shopping list

- **Conversion System Architecture**
  - **Tool-Based Conversions**: System now supports items requiring separate tools
  - Added `toolItemId` field to all 49 existing conversions (backward compatible)
  - **New**: Deeprock Salt → Refined Deeprock Salt (requires Salt Shaker tool)
  - GetConversionInfo() now returns 5 values (added toolItemId)
  - Virtual recipe creation and queue processing updated to use tool items
  - Self-use conversions (toolItemId = sourceId) work identically to before
  - See CONVERSION_REFACTOR_TEST.md for testing procedures

- **Localization System Updates**
  - Multiple UI components migrated to GetLocalizedString() pattern
  - Improved consistency in localization string access
  - Affects: MerchantWindow, RecipeNotes, ShoppingList, Sorting, Utils

### Fixed
- **Start Crafting Dialog Closure**
  - Dialog now properly closes when queue completes (all scenarios)
  - Added defensive fallback: hides dialog even if IsVisible() returns false
  - Enhanced diagnostic output in developer mode for dialog closure events
  - See DIALOG_CLOSURE_TEST.md for verification procedures

- **Shopping List Include Bank Default**
  - Shopping list now includes bank inventory by default (was inconsistent before)
  - Fixes items showing as needed when already available in bank

- **Sorting Difficulty Nil Safety**
  - Recipe difficulty sorting now handles unknown skillTypes gracefully
  - Prevents errors when encountering recipes with undefined difficulty tiers
  - Falls back to alphabetical sorting when difficulty data unavailable

### Major Changes
- **Queue-Aware Craftability Calculation**
  - Craftability now accounts for queue impact on total inventory (NET reservation tracking)
  - **Before**: Recipe showed 10/0/146 Cobalt Bar available regardless of queue state
  - **Now**: Recipe shows reduced availability based on what queue consumes/produces
  - **Example**: Queue has "Smelt Cobalt x40" (produces bars) + "Axe x4" (consumes bars)
    - Cobalt Bar: 0 net change (produced and consumed equally) → not reserved
    - Cobalt Ore: -40 reserved (consumed by smelting) → availability reduced by 40
  - **Implementation**: Single NET reservation map (consumption - production) replaces consumption-only tracking
  - Positive net values = reserved (consumed), Negative values = available (produced)
  - Craftability numbers now dynamically adjust as queue changes
  - **Impact**: Users see accurate craftability counts that account for queued recipes

### Fixed
- **CRITICAL: Subreagents Not Scaled When Increasing Queue Count**
  - When requeuing a recipe that already exists, subreagents were not re-evaluated
  - **Example**: Queue "Notched Cobalt War Axe" x1 → queues "Smelt Cobalt" x10
  - Queue it again → increases Notched x2 but Smelt stays x10 instead of x20 ❌
  - Queue it again → increases Notched x3 but Smelt stays x10 instead of x30 ❌
  - **Root cause**: queueSnapshot included THIS RECIPE's consumption, masking shortage for new crafts
  - When calculating shortage for the delta (new items), the snapshot incorrectly showed enough materials
  - **Solution**: Exclude the current recipe's OWN consumption from queueSnapshot
  - When recipe already exists in queue, calculate its contribution to each reagent and subtract from snapshot
  - Now when requeuing, shortage is calculated only for the NEW items being added
  - Subreagents are properly scaled: x1→x10, x2→x20, x3→x30 ✅
  - **Impact**: Properly handles repeated queue operations; subreagent counts stay proportional

- **CRITICAL: Stale Queue Consumption Cache After Clear**
  - After clearing queue with Clear button or RemoveQueuedItem, consumption cache remained stale
  - Subsequent queue additions would use outdated cached values before next CalculateCraftability
  - **Example**: Queue cleared at 18:05:53 (consumption was 30), immediately queue again at 18:05:57
  - Next add_items_to_queue would use cached value 30 even though queue was empty
  - **Solution**: Call ClearCache() in EmptyQueue() and RemoveQueuedItem() to invalidate consumption cache
  - Cache now properly cleared whenever queue structure changes
  - Next GetQueuedReagentConsumption call will rebuild on-demand or from fresh calculation
  - **Impact**: Prevents misleading consumption calculations immediately after queue modifications

- **CRITICAL: Subreagent Cascade Accumulation Bug**
  - Repeatedly queueing the same recipe caused subreagents to accumulate (+10 → +20 → +30)
  - **Root cause**: Queue consumption math inverted - negative inventory subtraction caused doubled queueing
  - **Example**: Queue "Big Black Mace" twice (needs 10 Mithril Bar) → queued 10, then 20 instead of 10 total
  - **Math error**: `have = 0 - 10 = -10` then `needed - have = 10 - (-10) = 20` (wrong!)
  - **Solution**: Calculate total available (physical + already queued) and queue only the shortage
  - New logic: `shortage = max(0, needed - (have + queuedConsumption))`
  - Subsequent queues of same recipe now correctly use cached queueSnapshot to avoid duplication
  - Subreagent queue counts now remain stable (+10 stays at +10, not escalating)

- **CRITICAL: Clear Button Non-Functional**
  - Clear button (SkilletEmptyQueueButton) had no OnClick handler set
  - XML comment indicated handler should be set via Lua SetScript, but code was never implemented
  - **Solution**: Added SetScript("OnClick") handler that calls EmptyQueue() and updates queue display
  - Queue now properly clears when Clear button is clicked
  - Updated queue window is refreshed immediately to show empty state
  
- **CRITICAL: Queue Entry Display Visibility**
  - Queue entries now properly display text immediately after adding items
  - **Root cause**: FontStrings created from XML templates or dynamically were not explicitly shown
  - **Solution**: Explicitly call Show() on all FontStrings and their parent frames
  - Fixed both XML-template-based button1 and dynamically created buttons 2+
  - Queue window now shows recipe names and craft counts correctly
  - Eliminates "empty button" syndrome where delete buttons ("D") were visible but text was not
  
- **Conversion Queue Entry Persistence & Hydration**
  - Conversion entries (Crystallized ↔ Eternal) now properly persist across sessions
  - All conversion metadata stored as primitive fields in queue entries
  - Conversion recipe objects automatically rebuilt on queue load
  - Fixed blank "Conversion" entries after reload
  - Display logic now handles conversions separately from profession recipes
  - **Conversion entries display with [CON] tag** (e.g., "[CON] Eternal Fire (x4)")
  - Updated conversion entry creation logic to include all serializable fields
  - Updated conversion update logic to synchronize all fields when adjusting amounts
  - QueueEntry type expanded with conversionType, sourceId, outputId, etc.
  
- **CRITICAL: Queue Entry Data Persistence & Hydration**
  - Queue entries now properly persist name and link fields across sessions
  - Fixed blank queue entries appearing immediately after adding items
  - **Root cause**: Complex recipe objects don't serialize to SavedVariables
  - **Solution**: Store primitive display fields (name, link) directly in queue entries
  - Recipe objects are now marked "runtime only" - they exist during session but don't persist
  - **NEW: Recipe Hydration on Load** - Recipe objects automatically rebuilt from Custom API when loading queue
    - Uses `Custom_GetProfessionRecipeInfo()` to get recipe metadata
    - Uses `Custom_GetProfessionRecipeReagents()` to rebuild reagent arrays
    - Ensures queue consumption calculations work immediately after reload
    - Backward compatible: Updates old queue entries missing name/link fields
  - Queue display now uses stored .name field instead of calling Custom_GetProfessionRecipeInfo()
  - Eliminates dependency on server-side API cache state for display
  - Items now display correctly immediately upon queueing, not just after reload
  
- **Critical Queue Entry Bug**
  - Queue entries now properly store the recipe object with full reagent data
  - Fixes blank entries appearing in queue display
  - Fixes infinite loop in reagent consumption calculations
  - AddToQueue() now fetches and stores complete recipe via GetItemDataByIndex()
  - Updated QueueEntry type annotations to document recipe field requirement
  
- **Queue Reservation Tracking in Craftability Calculations**
  - Craftability calculations now correctly account for materials reserved by queued recipes
  - Both traditional and Custom API calculation paths now subtract queued material consumption
  - Prevents overcounting available materials when planning crafts
  - Improves accuracy of "Queue All" and craftability indicators
  - Debug output from GetQueuedReagentConsumption() now respects dev_mode flag

### Changed
- **CRITICAL Performance: Queue Consumption Caching**
  - Queue consumption map now built ONCE at start of craftability calculation
  - Used as O(1) cache lookup for all recipe checks instead of recalculating every time
  - Eliminates catastrophic N×M×Q complexity (262 recipes × 5 reagents × 5 queue = 6,550 iterations!)
  - Reduces queue consumption overhead from ~1000ms to ~5ms for typical queues
  - Cache automatically cleared when queue changes or calculation starts
  - On-demand fallback calculation for non-bulk contexts
  - **Previous behavior**: GetQueuedReagentConsumption() called for EVERY reagent of EVERY recipe
  - **New behavior**: BuildQueueConsumptionMap() called ONCE, results cached as `{ [itemId] = totalNeeded }`
  - ~200x speedup for queue consumption during craftability calculations

- **Performance: Queue Consumption Calculation Optimized**
  - GetQueuedReagentConsumption() now uses Custom_GetProfessionRecipeReagents() API
  - O(1) direct lookup vs O(n) iteration through reagent arrays
  - Reduced complexity from O(queue_size × avg_reagents) to O(queue_size)
  - Server-side data eliminates need for link parsing
  - Includes fallback to traditional method if Custom API unavailable

## [1.2.0] - 2026-01-31

### Added
- **Equipment Slot Filter**
  - Dropdown selector with 23 equipment slot types (Head, Chest, Feet, etc.)
  - Filters recipes by INVTYPE constants (INVTYPE_HEAD, INVTYPE_CHEST, etc.)
  - Non-equippable items automatically pass through filter
  - Alphabetically sorted options with "All Slots" default
  - Integrated into filter chain: Sort → Slot Filter → Attunability → Forge

- **Extraction System**
  - Complete material extraction framework
  - UI for extracting materials from crafted items
  - Integration with Synastria's extraction mechanics
  - Extraction window with item selection and processing
  - Support for bulk extraction operations

- **ResourceTracker Integration**
  - Automatic shopping list synchronization with ResourceTracker addon
  - Bidirectional communication via _G.ResourceTracker API
  - Queue tracking with material requirement updates
  - Event-driven architecture (SKILLET_QUEUE_UPDATED, PLAYER_LOGIN)
  - Safety checks for addon availability

- **Custom Conversion Actions**
  - Material conversion system for Synastria-specific conversions
  - Crystallized ↔ Eternal conversion support
  - Bidirectional lookup (target-first, then source)
  - Virtual recipes inserted at queue start
  - Automatic conversion detection and insertion

- **Enhanced Queue Processing**
  - Interactive queue processing with confirmation dialogs
  - Ctrl+ScrollWheel support for step-through processing
  - Manual profession change handling
  - Queue state management with user control
  - Step-by-step execution with pause/resume capability

### Changed
- Reorganized repository structure from src/Skillet - Synastria/ to flat src/ directory
- Enhanced AreRecipesSorted() to check slot filter status (hides headers when slot filter active)
- UI layout restructured: moved Sort dropdown left, removed "Sorting" label
- Filter positioning optimized for new slot filter integration
- Queue processing now includes interactive dialog system

### Fixed
- Syntax error: GetTradeSkill Info → GetTradeSkillInfo in Sorting.lua
- Invalid equipment slot types removed (INVTYPE_ROBE, INVTYPE_RANGEDRIGHT don't exist in WoW API)
- Sort validation: only call table.sort() when valid sort method exists
- Nil function error: changed slot filter from XML OnLoad to dynamic Lua CreateFrame()
- Filter anchor chain: proper sequencing to prevent nil reference errors

### Technical
- **New Files:**
  - UI/SlotFilter.lua (112 lines) - Equipment slot filtering
  - Integrations/ResourceTracker.lua (244 lines) - ResourceTracker integration
  - SkilletExtraction.lua / SkilletExtraction.xml - Extraction system
  - UI/ExtractionFrame.lua / UI/ExtractionFrame.xml - Extraction UI
  
- **Critical Note:** New files require **full game restart**, not /reload

- **Load Order Changes:**
  - Added UI\SlotFilter.lua after AttunabilityFilter.lua
  - Added Integrations\ResourceTracker.lua at end
  - Added extraction files in core section

## [1.1.0] - 2024-01-XX

### Added
- **Scan All Professions** button for quickly updating all profession data
  - Located next to the standard Rescan button
  - Automatically cycles through all known professions
  - Returns to original profession when complete

- **Cross-Profession Queue System**
  - Queue items from multiple professions in a single queue
  - Automatic profession switching during queue processing
  - Profession name displayed in green brackets for each queue item
  - Error handling with retry logic (up to 3 attempts per profession switch)

- **Group Queue Button**
  - Reorganizes queue items by profession
  - Minimizes profession switches for more efficient crafting
  - Located next to Clear queue button

- **Synastria Bulk Crafting Detection**
  - Detects when server completes multiple items in one cast
  - Compares pre/post inventory counts
  - Automatically adjusts queue deduction based on actual items crafted
  - Chat notification when bulk crafting is detected

- **Enhanced Queue UI**
  - Profession indicator for each queued item
  - Color-coded profession names (green)
  - Better visual organization

### Changed
- ProcessQueue() now handles profession mismatches with automatic switching
- StopCast() enhanced with bulk completion detection logic
- Queue processing includes waiting state management for profession switches
- Improved error messages with color coding (green for success, red for errors)

### Fixed
- Queue desync issues caused by Synastria's bulk crafting behavior
- Profession switching timeout handling
- Invalid queue item handling

## [1.0.0] - 2024-01-XX

### Added
- **Resource Bank Integration**
  - Full integration with Synastria's custom Resource Bank system (typeID: 13)
  - Added 
umcraftablewresbank field to recipe data structure
  - Resource Bank column in crafting display
  - Resource Bank materials included in shopping lists
  - GetCustomGameData(13, itemId) API integration

- **Profession Selector UI**
  - Quick-switch buttons for all professions
  - Visual highlight for active profession
  - Adapted from ScootsCraft design
  - Support for 12 professions

- **Equipment Filtering System**
  - Attunability filter dropdown (None/Character/Account)
  - Forge level filter dropdown (-1 through 3)
  - Equipment Only checkbox
  - Integration with Synastria APIs:
    - GetItemAttuneForge() for forge levels
    - GetItemTagsCustom() for attunability
    - CanAttuneItemHelper() for attunement checking
    - IsAttunableBySomeone() for account-wide checks

- **Debug System**
  - Hidden debug button for troubleshooting
  - Detailed filter information display
  - Item statistics and API response logging

- **GitHub Integration**
  - Published to https://github.com/CheatingChicken/Skillet-Synastria
  - Comprehensive README documentation
  - Release v1.0.0 with all features

### Changed
- Modified .toc file naming and structure for Synastria compatibility
- Updated craftability calculations to include resource bank
- Enhanced filter logic to match ScootsCraft behavior
- Non-equippable items pass through attunability filter

### Fixed
- GetTradeskillItemLink() vs GetTradeSkillRecipeLink() confusion
- IsEquippableItem() nil returns for uncached items
- Attunability filter incorrectly hiding non-equippable items
- Filter positioning and anchoring issues
- Display formatting for multiple material sources

## [Unreleased]

### Planned Features
- Cross-profession craftability calculations
- Improved bulk crafting detection for edge cases
- Profession-based queue statistics
- Material availability across professions

---

## Version Format

[Major].[Minor].[Patch]
- **Major**: Significant feature additions or breaking changes
- **Minor**: New features, enhancements
- **Patch**: Bug fixes and minor improvements
