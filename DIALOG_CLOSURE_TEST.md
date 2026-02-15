# Dialog Closure Testing Protocol

## Sacred Incantation Enhancement - February 15, 2026

**Issue**: Start Crafting Prompt dialog persists after queue completes

**Diagnosis**: Enhanced QueueChanged with diagnostic output to trace execution

---

## Testing Procedure

### 1. Enable Dev Mode
```lua
/script Skillet:ToggleDevMode()
-- Should see: "Dev mode enabled"
```

### 2. Queue Simple Recipe
```lua
-- Queue 2-3 of a simple recipe (e.g., Linen Bandage)
-- Click "Start Crafting" to open dialog
```

### 3. Process Queue Fully
```lua
-- Click "Start Crafting" button to craft first item
-- Watch chat for debug messages:
--   [COMPLETION] Queue item present - numcasts=X
--   [COMPLETION] numcasts < 1 - removing from queue
--   [COMPLETION] Queue complete!
--   [QUEUE] QueueChanged() called! Queue count: 0
--   [DIALOG] Queue is empty - checking for dialog to close...
--   [DIALOG] promptFrame found: true, visible: true
--   "Queue complete! Dialog closed and keybindings cleared."
```

**Expected**: Dialog disappears automatically  
**Previous Behavior**: Dialog remained visible

---

## Test Case 2: Manual Clear

### 1. Queue Recipe
```lua
-- Add items to queue
-- Open Start Crafting dialog
```

### 2. Click "Clear" Button
```lua
-- Without crafting anything, click the queue Clear button
```

**Expected**: 
- Queue clears
- [QUEUE] QueueChanged() triggered
- [DIALOG] messages appear
- Dialog closes

---

## Test Case 3: Conversion Recipe

### 1. Queue Conversion
```lua
-- Queue a crystallized->eternal conversion
-- Click "Start" to process
```

### 2. Watch Completion
```lua
-- After conversion completes:
--   ProcessConversion withdraws, uses, deposits
--   RemoveFromQueue(1) called
--   SkilletStitch_Queue_Complete triggered
--   Dialog should close
```

---

## Debug Output Analysis

### Dialog Found & Visible
```
[DIALOG] Queue is empty - checking for dialog to close...
[DIALOG] promptFrame found: true, visible: true
Queue complete! Dialog closed and keybindings cleared.
```
→ **Success**: Normal closure path

### Dialog Found but Not Visible
```
[DIALOG] Queue is empty - checking for dialog to close...
[DIALOG] promptFrame found: true, visible: false
[DIALOG] Dialog existed but wasn't visible - hidden anyway
```
→ **Fallback**: Hidden defensively (possible state desync)

### Dialog Not Found
```
[DIALOG] Queue is empty - checking for dialog to close...
[DIALOG] No dialog frame found to close
```
→ **Expected**: Dialog was never opened OR already destroyed

---

## What Changed

**File**: `Skillet.lua` lines 3082-3115

**Before**:
```lua
if self.stitch.queue and #self.stitch.queue == 0 then
    local promptFrame = self.startCraftingPrompt or getglobal("SkilletStartCraftingPrompt")
    if promptFrame and promptFrame:IsVisible() then
        promptFrame:Hide()
        -- ... bindings ...
    end
end
```

**After**:
1. Added dev mode debug output showing:
   - When queue empty check triggers
   - Whether frame was found
   - Whether frame reports as visible
2. Added fallback: Hide dialog even if not reporting visible
3. Added debug confirmation messages

**Why This Fixes It**:
- Original code only hid dialog if `IsVisible()` returned true
- Possible edge case: Dialog exists but returns false for visibility
- New fallback ensures dialog is hidden in all cases where frame exists
- Debug output reveals exact execution path for further diagnosis

---

## Rollback Procedure

If this creates new issues, revert lines 3082-3115 of Skillet.lua to:
```lua
if self.stitch.queue and #self.stitch.queue == 0 then
    local promptFrame = self.startCraftingPrompt or getglobal("SkilletStartCraftingPrompt")
    if promptFrame and promptFrame:IsVisible() then
        promptFrame:Hide()
        SetBinding("CTRL-MOUSEWHEELUP")
        SetBinding("CTRL-MOUSEWHEELDOWN")
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00Queue complete! Dialog closed and keybindings cleared.|r")
    end
end
```

---

## Success Criteria

✅ Dev mode shows all [DIALOG] trace messages  
✅ Dialog disappears when queue completes naturally  
✅ Dialog disappears when queue cleared manually  
✅ No errors in language server  
✅ Keybindings cleared after closure  

