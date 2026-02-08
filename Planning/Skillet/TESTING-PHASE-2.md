# Testing Phase 2: Spell-Based Crafting

## Status: IN PROGRESS 🔄

## Confirmed Facts
- ✅ `Custom_DoProfessionRecipe` EXISTS
- ✅ Does NOT bypass cooldowns (by design - this is correct)
- ✅ Respects normal game rules

## Objective
Test `Custom_DoProfessionRecipe` to determine:
1. Can we craft via spell IDs without opening tradeskill windows?
2. Does it work across professions without switching windows?
3. What events does it trigger?
4. Can we build a spell-based queue system?

---

## Pre-Test Checklist

1. ✅ Open a profession window (any profession you have)
2. ✅ Have materials for at least one recipe
3. ✅ Identify a recipe with a cooldown (if testing cooldown bypass)
4. ✅ Note the index of recipes you want to test

---

## Test Sequence

### Test 1: Basic API Existence Check
**Purpose:** Verify the function exists and get basic info

```lua
/script Skillet:TestCustomDoProfessionRecipe()
```

**Expected Results:**
- ✅ Function exists
- ✅ Shows function type and debug info
- ✅ Lists current profession and available recipes
- ✅ Provides test commands

**What to Look For:**
- Does the function exist?
- What type is it? (function, userdata, etc.)
- Any error messages?

---

### Test 2: Enable Monitoring
**Purpose:** Track all craft function calls in real-time

```lua
/script Skillet:MonitorCraftCalls(true)
```

**Expected Results:**
- ✅ "DoTradeSkill monitoring ENABLED"
- ✅ "Custom_DoProfessionRecipe monitoring ENABLED"

**Keep this enabled for all subsequent tests!**

---

### Test 3: Systematic Test Suite
**Purpose:** Automatically identify test cases and suggest tests

```lua
/script Skillet:SystematicCustomTest()
```

**Expected Results:**
- ✅ Lists available test recipes:
  - Normal recipe (no special properties)
  - Recipe with cooldown
  - Transmute recipe (if Alchemy)
  - Transmute with cooldown
- ✅ Provides specific test commands for each

**Note the index numbers provided!**

---

### Test 4A: Test Normal Recipe (Standard Method)
**Purpose:** Establish baseline behavior with DoTradeSkill

```lua
-- Replace INDEX with the number from Test 3
/script DoTradeSkill(INDEX, 1)
```

**Monitor Output - Look For:**
- `[MONITOR] DoTradeSkill(INDEX, 1) CALLED`
- `[MONITOR] DoTradeSkill RETURNED: ...`
- Crafting bar appears
- Item created
- Events fired (TRADE_SKILL_UPDATE, etc.)

---

### Test 4B: Test Normal Recipe (Custom API)
**Purpose:** Test if Custom_DoProfessionRecipe works for basic crafting

**First, get the spell ID:**
```lua
-- Open profession window, find the recipe, note its item link
-- Extract item ID from link, then:
/script local itemId = XXXXX  -- Replace with actual item ID
/script local spellId = Custom_GetProfessionRecipeFromCraftedItem(itemId)
/script print("SpellId: " .. tostring(spellId))
```

**Then craft:**
```lua
/script Custom_DoProfessionRecipe(SPELLID, 1)
```

**Monitor Output - Look For:**
- `[MONITOR] Custom_DoProfessionRecipe(SPELLID, 1) CALLED`
- `[MONITOR] Custom_DoProfessionRecipe RETURNED: ...`
- Does crafting bar appear?
- Is item created?
- Are events fired?
- **Does it work WITHOUT opening profession window?**

---

### Test 5: Cooldown Handling (VERIFICATION TEST)
**Purpose:** Verify cooldowns are properly respected

**Setup:**
1. Find a recipe with a cooldown
2. Craft it once (establishes cooldown)
3. Try to craft again

```lua
/script Custom_DoProfessionRecipe(COOLDOWN_SPELLID, 1)
```

**Expected Behavior:**
- ✅ Should fail/error (cooldown active)
- ✅ Should NOT bypass cooldown
- ✅ Should respect game rules

**This confirms the API is working correctly and fairly!**

---

### Test 6: Crafting Without Window (CRITICAL TEST)
**Purpose:** Test if we can craft without profession window open

**Steps:**
1. Open profession window
2. Get spell ID for a recipe
3. **Close profession window**
4. Try to craft:

```lua
/script Custom_DoProfessionRecipe(SPELLID, 1)
```

**CRITICAL QUESTIONS:**
- ❓ Does it work without window?
- ❓ Does it auto-open window?
- ❓ Does it fail silently?
- ❓ Do we get an error message?

---

### Test 8: Batch Crafting
**Purpose:** Test crafting multiple items at once

```lua
/script Custom_DoProfessionRecipe(SPELLID, 5)
```

**Questions:**
- ❓ Does it craft all 5?
- ❓ Or just 1?
- ❓ How does it handle the count parameter?

---

### Test 9: Event Monitoring
**Purpose:** Check what events are triggered

**Setup event monitor:**
```lua
/script local f = CreateFrame("Frame")
/script f:RegisterEvent("TRADE_SKILL_UPDATE")
/script f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
/script f:RegisterEvent("UNIT_SPELLCAST_START")
/script f:SetScript("OnEvent", function(self, event, ...) print("EVENT: " .. event) end)
```

**Then craft:**
```lua
/script Custom_DoProfessionRecipe(SPELLID, 1)
```

**Monitor which events fire**
7: Multi-Profession Queue
**Purpose:** Test if we can craft from different professions without window switching

**Steps:**
1. Get spell IDs for recipes from 2+ professions
2. Close all profession windows
3. Try crafting from different professions in sequence:

```lua
-- Alchemy recipe
/script Custom_DoProfessionRecipe(ALCHEMY_SPELLID, 1)
-- Immediately followed by Blacksmithing recipe
/script Custom_DoProfessionRecipe(BLACKSMITH_SPELLID, 1)
```

**CRITICAL QUESTIONS:**
- ❓ Does it switch professions automatically?
- ❓ Or does it fail without correct window?
- ❓ Can we avoid manual profession switching?

---

### Test 
---
Respect
- Recipe tested: __________
- SpellId: __________
- Cooldown active: YES / NO
- Custom API respected cooldown: YES / NO
- Proper error handling: YES / NO
- Notes: ___________________________________

TEST 4pe name: __________
- Return value: __________
- Item created: YES / NO
- Crafting bar shown: YES / NO
- Events fired: __________
- Notes: ___________________________________

TEST 3: Cooldown Bypass
- Recipe tested: __________
- SpellId: __________
- Cooldown active: YES / NO
- Custom API crafted anyway: YES / NO
- Item created: YES / NO
- Coo5: Multi-Profession Support
- Profession 1: __________
- Profession 2: __________
- Switched automatically: YES / NO
- Required window open: YES / NO
- Notes: ___________________________________

TEST ldown reset: YES / NO
- Notes: ___________________________________

TEST 4: Transmute Cooldown (If Alchemy)
- Transmute recipe: __________
- Daily cooldown active: YES / NO
- Custom API bypassed cooldown: YES / NO
- Notes: ___________________________________

TEST 5: Window-Free Crafting
- Profession window open: YES / NO
- Custom API worked: YES / NO
- Window auto-opened: YES / NO
- Notes: ___________________________________

TEST 6: Batch Crafting
- Requested count: __________
- Actual crafted: __________
- Notes: ___________________________________

TEST 7: Event Handling
- TRADE_SKILL_UPDATE fired: YES / NO
- UNIT_SPELLCAST_* events: YES / NO
- Other events: __________
- Notes: ___________________________________

CRITICAL FINDINGS:
1. ___________________________________
2. ___________________________________
3. ___________________________________

BLOCKERS:
- ___________________________________

READY FOR IMPLEMENTATION: YES / NO
```

---

## Success Criteria

### ✅ PASS Criteria
- [ ] Custom_DoProfessionRecipe exists ✓ CONFIRMED
- [ ] Successfully crafts items
- [ ] Works without profession window
- [ ] Triggers appropriate events
- [ ] Properly respects cooldowns ✓ CONFIRMED

### ⚠️ PARTIAL PASS
- Function works but requires window open
- Function works but respects cooldowns
- Function works but with limitations

### ❌ FAIL Criteria
- Function doesn't exist
- Returns nil/error
- Doesn't craft items
- Crashes client

---

## Troubleshooting

### "Custom_DoProfessionRecipe does not exist"
- **Cause:** Server doesn't have this API implemented
- **Solution:** Contact server admin or abandon spell-based crafting

### "Returned nil"
- **Cause:** Could be normal (server-side execution)
- **Action:** Check if item was actually created

### No item created
- **Cause:** Function might not work, or materials missing
- **Action:** Verify materials, check inventory

### Window opens automatically
- **Cause:** API might trigger window opening
- **Result:** Still better than manual switching

---

## Disable Monitoring When Done

```lua
/script Skillet:MonitorCraftCalls(false)
```

---

## Next Steps Based on Results

### If ALL TESTS PASS ✅
→ Implement spell-based queue processing:
1. Convert queue items to spell IDs
2. Use Custom_DoProfessionRecipe for crafting
3. Implement window-free queue processing

### If WINDOW-FREE CRAFTING WORKS ✅
→ Implement:
1. Window-free crafting
2. Faster queue processing
3. Multi-profession queue support

### If NOTHING WORKS ❌
→ Stick with traditional methods:
1. Keep window-based crafting
2. Use other working APIs (reagents, attunement)
3. Wait for server updates

---

**By the Omnissiah, may the Machine Spirits reveal their secrets!** ⚙️🔧
