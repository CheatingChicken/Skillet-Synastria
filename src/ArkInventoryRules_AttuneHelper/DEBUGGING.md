# Debugging the ahset() Rule

## Quick Diagnostic Steps

### Step 1: Check if the addon loaded
When you log in or reload UI (`/reload`), you should see this message:
```
[ArkInventoryRules_AttuneHelper] Module loaded, ahset() rule registered
[ArkInventoryRules_AttuneHelper] To enable debug: /run ArkInventoryRules_AttuneHelper_EnableDebug()
```

**If you DON'T see this message:**
- The addon file is loading but the registration isn't happening
- First check: `/run print(IsAddOnLoaded("ArkInventoryRules_AttuneHelper"))` - should return `1`
- Then manually trigger registration: `/run ArkInventoryRules_AttuneHelper_ForceRegister()`
- If that shows the load message, then the ADDON_LOADED event timing is off

### Step 2: Verify AHSetList has items
```lua
/run for name,slot in pairs(AHSetList) do print(name, "=>", slot) end
```

**Expected output:** List of items you've added with `/ahset`

**If empty:** Add items first with `/ahset <itemlink> [slot]`

### Step 3: Enable debug mode
```lua
/run ArkInventoryRules_AttuneHelper_EnableDebug()
```

You should see: `[AHSet Debug] Debug mode enabled!`

### Step 4: Trigger the rule
Open your ArkInventory and the rule should automatically evaluate. Watch your chat for debug messages.

**Example debug output when it works:**
```
[AHSet Debug] === ahset() called ===
[AHSet Debug] Item hyperlink: |cff0070dd|Hitem:12345:0:0:0:0:0:0:0:80|h[Example Item]|h|r
[AHSet Debug] AHSetList exists, item count: 5
[AHSet Debug] Arguments count: 0
[AHSet Debug] Item name: Example Item
[AHSet Debug] Item found in AHSetList, designated slot: MainHandSlot
[AHSet Debug] No arguments, returning true
```

**If it fails, you'll see WHERE it fails:**
```
[AHSet Debug] === ahset() called ===
[AHSet Debug] AHSetList is nil!
```
↑ This means AttuneHelper isn't loaded or AHSetList doesn't exist

```
[AHSet Debug] GetItemInfo returned nil for hyperlink
```
↑ This means the item hyperlink couldn't be resolved (rare)

```
[AHSet Debug] Item not in AHSetList
[AHSet Debug]   AHSetList example: Sword of Awesome => MainHandSlot
```
↑ This means the item name doesn't match what's in AHSetList

### Step 5: Disable debug when done
```lua
/run ArkInventoryRules_AttuneHelper_DisableDebug()
```

## Common Issues

### Issue: "Rule not found" or rule doesn't execute
**Cause:** The addon didn't register properly
**Fix:** 
1. `/reload` 
2. Check load order - ArkInventoryRules must load before this addon
3. Verify in TOC: `## RequiredDeps: ArkInventoryRules, AttuneHelper`

### Issue: Debug shows "Item not in AHSetList" but you added it
**Cause:** Item name mismatch
**Solution:** Item names must EXACTLY match. Check with:
```lua
/run local name = GetItemInfo("itemlink"); print(name); print(AHSetList[name])
```

### Issue: No debug output at all
**Cause:** Rule isn't being called or debug not enabled
**Fix:**
1. Make sure you enabled debug: `/run ArkInventoryRules_AttuneHelper_EnableDebug()`
2. Force ArkInventory to re-evaluate rules (close/open bags)
3. Check if rule syntax is correct in ArkInventory configuration

### Issue: AHSetList is nil
**Cause:** AttuneHelper not loaded or saved variables not initialized
**Fix:**
1. Check: `/run print(AHSetList)`
2. If nil, AttuneHelper isn't creating it
3. Verify AttuneHelper is loaded: `/run print(IsAddOnLoaded("AttuneHelper"))`

## Manual Testing

### Verify the rule is registered:
```lua
/run print("ahset() registered:", ArkInventoryRules.Environment and ArkInventoryRules.Environment.ahset ~= nil)
```
Should print `ahset() registered: true`

### Test if the rule function exists:
```lua
/run print("ahset() rule:", ArkInventoryRules.Environment and ArkInventoryRules.Environment.ahset ~= nil)
```
Should print `ahset() rule: true`, not false.

If you see a warning "ahset is already registered" when running ForceRegister, that's GOOD - it means it registered successfully the first time!

### Quick functional test:
```lua
/run print("Test ahset function:", type(ArkInventoryRules.Environment.ahset))
```
Should print `Test ahset function: function`

### Test AHSetList directly:
```lua
/run print("AHSetList exists:", AHSetList ~= nil)
/run local c=0; for _ in pairs(AHSetList) do c=c+1 end; print("Items in AHSetList:", c)
```

### Test item name extraction:
```lua
/run local name = GetItemInfo(GetInventoryItemLink("player", 16)); print("Main hand item:", name)
```

## Understanding ArkInventory Rule Syntax

When creating a rule in ArkInventory, use:
```
ahset()                    # Matches any item in AHSetList
ahset("MainHandSlot")      # Matches items designated for main hand
```

**NOT:**
```
AHSET()                    # Wrong - case matters in the rule text
ahset("mainhandslot")      # This will work - slot comparison is case-insensitive
```

## Still Not Working?

If debug shows the rule IS finding items but they're not being filtered:

1. Check your ArkInventory rule syntax
2. Make sure you're using the rule in the right place (category rules, not search)
3. Try combining with other rules: `ahset() and true`
4. Check ArkInventory's own debug options

## Contact

If you've followed all these steps and it still doesn't work, capture:
1. The debug output (with debug enabled)
2. Output of `/run for n,s in pairs(AHSetList) do print(n,s) end`
3. The exact rule syntax you're using in ArkInventory
4. Any error messages from the game
