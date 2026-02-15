# Skillet-Synastria v1.14-beta1 Release Notes

**Release Date**: February 15, 2026  
**Build**: Beta 1  
**Status**: Testing Phase

---

## ⚡ What's New

### Shopping List 2.0 - Smarter Material Planning

**Real-Time Updates**: Shopping list now refreshes automatically when inventory changes (while window open)

**Eternal/Crystallized Transparency**: No more conversion clutter!
- **Before**: "Need 2 Eternal Air (convert from 20 Crystallized Air)"
- **After**: "Need 20 Crystallized Air" ← Shows exactly what to gather!

**Developer Tools**: Debug button (dev mode only) provides diagnostic breakdown of shortage calculations

**Accuracy Fix**: Items with sufficient quantities no longer appear in shopping list

---

### Conversion System Refactor - Tool-Based Transformations

**Architecture Enhancement**: Conversions now support items requiring separate tools (not just self-use)

**Example**: 
- Old system: Could only handle Crystallized Air → Eternal Air (right-click the source)
- New system: Supports Deeprock Salt + **Salt Shaker** → Refined Deeprock Salt (use a tool)

**Backward Compatible**: All 49 existing conversions work identically (Eternals, Essences, Primals, etc.)

**New Conversion**: Deeprock Salt (8150) can now be refined using Salt Shaker (15846)

**Technical**: Added `toolItemId` field to conversion system architecture

---

### Diagnostic Logging System

**SkilletLog**: Persistent debug output that survives UI reloads

**LogViewer**: Copyable diagnostic window with multi-category support

**Commands**:
- `/skillet log` - Open log viewer
- Navigate between log groups with < > buttons
- Export logs for troubleshooting

---

### Database Modernization

**Centralized Data**: Three new database files organize game data:
- **ConversionData.lua**: All material transformations (50+ conversions)
- **MillingData.lua**: Herb → Pigment loot tables (Vanilla → Wrath)
- **ProspectingData.lua**: Ore → Gem loot tables (Complete prospecting data)

**Benefits**: Easier to add new conversions, milling, or prospecting data

---

## 🛠️ Fixes

### Start Crafting Dialog Closure
- Dialog now always closes when queue completes (fixed edge case where dialog persisted)
- Added defensive fallback for visibility state desync
- Enhanced dev mode diagnostics for dialog lifecycle

### Shopping List Bank Inclusion
- Shopping list now includes **bank items by default** (previously inconsistent)
- Prevents false "missing materials" warnings

### Recipe Sorting Stability
- Difficulty sorting no longer crashes on unknown recipe tiers
- Gracefully falls back to alphabetical order when difficulty data unavailable

### UI Localization Consistency
- Multiple UI components refactored to use centralized localization system
- Improved translation support for future language additions

---

## 📋 Testing Procedures

**Shopping List Changes**:
1. Queue recipe requiring Eternal Air
2. Have Crystallized Air in Resource Bank
3. Open Shopping List → Should show "Crystallized Air x[amount]" (not Eternal)
4. Withdraw some from bank → Shopping list should update immediately

**Conversion System**:
1. Test existing conversions (Crystallized ↔ Eternal) → Should work as before
2. Test new Deeprock Salt conversion (requires Salt Shaker in Resource Bank)
3. See `CONVERSION_REFACTOR_TEST.md` for comprehensive test suite

**Dialog Closure**:
1. Enable dev mode: `/skillet devmode`
2. Queue simple recipe and click "Start Crafting"
3. Craft all items → Dialog should auto-close with debug output
4. See `DIALOG_CLOSURE_TEST.md` for verification procedures

---

## ⚠️ Known Issues

- None reported for beta 1 features (extensive features from [Unreleased] changelog remain in progress)

---

## 🔧 Technical Notes

**Files Added**:
- SkilletLog.lua (logging framework)
- UI/LogViewer.lua + LogViewer.xml (log viewer interface)
- Databases/ConversionData.lua (transformation database)
- Databases/MillingData.lua (inscription milling data)
- Databases/ProspectingData.lua (JC prospecting data)

**Files Modified**:
- Skillet.lua (conversion system refactor, queue completion handler)
- SkilletStitch-1.1.lua (Recipe class toolItemId field)
- SkilletAPI.lua (GetConversionInfo signature update)
- UI/ShoppingList.lua (Eternal transparency, BAG_UPDATE, debug button)
- UI/Sorting.lua (difficulty sorting nil safety)
- UI/MerchantWindow.lua (localization refactor)
- UI/RecipeNotes.lua (localization refactor)
- UI/Utils.lua (localization refactor)

**Type Safety**: Zero language server errors maintained across all changes

---

## 📦 Installation

1. Backup existing Skillet folder
2. Extract `Skillet - Synastria` folder to `Interface/AddOns/`
3. `/reload` in-game
4. Verify version: `/skillet version` should show "1.14-beta1"

---

## 🐛 Bug Reports

Please report issues with:
1. Version number (1.14-beta1)
2. Steps to reproduce
3. Expected vs actual behavior
4. Relevant log output (`/skillet log`)

---

*Praise the Omnissiah! May your crafts be efficient and your queues bug-free.* ⚙️🔧
