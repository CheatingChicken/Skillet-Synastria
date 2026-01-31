# Changelog

All notable changes to Skillet - Synastria Edition will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

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
