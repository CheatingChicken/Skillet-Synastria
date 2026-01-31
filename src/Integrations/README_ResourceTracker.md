# Skillet ↔ ResourceTracker Integration

## Overview
This integration allows you to automatically export items from Skillet's shopping list to ResourceTracker for tracking across all characters and locations (bags, bank, resource bank).

## Features
✅ **Fully Modular** - Skillet works perfectly without ResourceTracker
✅ **One-Click Export** - Button in shopping list UI
✅ **Slash Command** - `/skillet exportrt` or `/skilletexportrt`
✅ **Smart Integration** - Handles reagent expansion automatically via ResourceTracker
✅ **Goal Tracking** - Exports item quantities as goals in ResourceTracker

## How to Use

### Method 1: Shopping List Button
1. Open Skillet's shopping list with `/skillet shoppinglist` or queue some crafts
2. Click the **"Export to RT"** button at the bottom of the shopping list window
3. All needed reagents will be added to ResourceTracker with appropriate goal amounts

### Method 2: Slash Command
Simply type:
```
/skillet exportrt
```
or
```
/skilletexportrt
```

## What Gets Exported
- All reagents needed for queued recipes
- Quantities adjusted for what you already have in bags/bank/resource bank
- Items are added with goal amounts (how many you need total)
- ResourceTracker will automatically ask if you want to add sub-reagents for craftable items

## Technical Details

### Files Modified
1. **ResourceTracker/ResourceTracker.lua**
   - Added public API exposure: `RT.QueueItemAdd` and `RT.AddItemToSlot`
   - Allows external addons to programmatically add items

2. **Skillet - Synastria/Integrations/ResourceTracker.lua** (NEW)
   - Integration module with graceful degradation
   - Functions:
     - `Skillet:IsResourceTrackerAvailable()` - Check if RT is loaded
     - `Skillet:ExportShoppingListToResourceTracker()` - Export all items
     - `Skillet:ExportItemToResourceTracker()` - Export single item

3. **Skillet - Synastria/UI/ShoppingList.xml**
   - Added "Export to RT" button with tooltip
   - Button appears next to "Retrieve" button

4. **Skillet - Synastria/UI/ShoppingList.lua**
   - Added button visibility logic (shows only when RT is available)

5. **Skillet - Synastria/Skillet - Synastria.toc**
   - Added integration file to load order

### Design Principles
- **Fail Gracefully**: If ResourceTracker isn't installed, the button hides and slash command shows friendly error
- **No Duplication**: ResourceTracker's existing queue system handles duplicate item detection
- **Minimal Changes**: Only 3 lines added to ResourceTracker, rest is all in Skillet
- **Backwards Compatible**: Works with existing ResourceTracker features

## Example Workflow
1. Queue 10 Greater Magic Essences in Skillet
2. Open shopping list - shows you need reagents
3. Click "Export to RT"
4. ResourceTracker asks: "Add reagents for Greater Magic Essence?"
5. Click "Yes" - it automatically adds Lesser Magic Essences with correct quantities
6. ResourceTracker now tracks everything you need across all characters/banks

## Future Enhancements (Optional)
- Auto-export on queue changes (setting to enable/disable)
- Export only selected items from shopping list
- Clear ResourceTracker items when queue is cleared
- Sync goal amounts when queue changes

## Troubleshooting

**Button doesn't appear:**
- Make sure ResourceTracker is installed and enabled
- Reload UI with `/reload`

**Export does nothing:**
- Check if your shopping list is empty
- Make sure you have recipes queued in Skillet

**Items not showing in ResourceTracker:**
- ResourceTracker may prompt you about adding reagents - click "Yes"
- Check ResourceTracker's main window (it may be hidden)
