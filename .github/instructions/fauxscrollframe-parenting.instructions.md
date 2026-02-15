---
applyTo: '**'
---

# FauxScrollFrame Button Parenting Pattern (CRITICAL)

## The Problem: Buttons Not Rendering in Scroll Frames

When creating buttons dynamically for a FauxScrollFrame, buttons will NOT display unless they're parented to the **container frame**, not the scroll frame itself.

**This has been a recurring issue and must be remembered.**

## The Solution Pattern

### WRONG ❌
```lua
-- Button is child of SkilletQueueList (the scroll frame)
local button = CreateFrame("Frame", "SkilletQueueButton" .. i, SkilletQueueList)
```

**Result**: `IsVisible() = N` even after `Show()`. Templates with `hidden="true"` also suffer from this.

### RIGHT ✅
```lua
-- Button is child of SkilletQueueParent (the container)
local button = CreateFrame("Frame", "SkilletQueueButton" .. i, SkilletQueueParent)
button:SetParent(SkilletQueueParent)  -- Explicit parenting
```

**Result**: `IsVisible() = Y` after `Show()`. Button renders properly.

## Reference Implementation

From MainFrame.lua's `get_recipe_button()` function (lines 648-656):

```lua
local function get_recipe_button(i)
    local button = getglobal("SkilletScrollButton" .. i)
    if not button then
        button = CreateFrame("Button", "SkilletScrollButton" .. i, SkilletSkillListParent, "SkilletSkillButtonTemplate")
        button:SetParent(SkilletSkillListParent)  -- CRITICAL: NOT SkilletSkillList!
        button:SetPoint("TOPLEFT", "SkilletScrollButton" .. (i - 1), "BOTTOMLEFT")
        button:SetFrameLevel(SkilletSkillListParent:GetFrameLevel() + 1)
    end
    return button
end
```

## Frame Hierarchy

Correct structure:
```
SkilletQueueParent (container)
├── SkilletQueueList (FauxScrollFrame)
├── SkilletQueueButton1 (child of parent, not scroll frame)
├── SkilletQueueButton2 (child of parent, not scroll frame)
├── SkilletQueueButton3 (child of parent, not scroll frame)
└── ... more queue buttons
```

## Why This Matters

- FauxScrollFrame manages visibility/positioning of child buttons via offset calculations
- If buttons are children of the scroll frame, they may be clipped or hidden by frame visibility rules
- The scroll frame internally manages which buttons (created as children of the **parent**) are visible based on scroll position
- XML templates with `hidden="true"` create frames with immutable visibility state that `Show()` can't override

## When Creating Dynamic Scroll List Buttons

1. **Create frames with parent = container** (not the scroll frame)
2. **Set parent explicitly** even if specified in CreateFrame
3. **Don't rely on templates** for dynamic buttons (they may have immutable hidden state)
4. **Let FauxScrollFrame manage visibility** by calling `FauxScrollFrame_Update()`
5. **Position relative to previous button**, not the scroll frame

## Testing Pattern

```lua
-- Check before Show()
print("BEFORE Show(): visible=" .. (button:IsVisible() and "Y" or "N"))

button:Show()

-- Check after Show()
print("AFTER Show(): visible=" .. (button:IsVisible() and "Y" or "N"))

-- If still N, check parent and parenting
print("Parent: " .. button:GetParent():GetName())
print("ExpectedParent: SkilletQueueParent")
```

If `visible=N` even after `Show()`, the parent is wrong. Fix immediately.

## Dates & Locations

- **Fixed**: February 11, 2026 in ThirdPartyHooks.lua (UpdateQueueWindow function)
- **Previous occurrences**: Multiple attempts trying different approaches before realizing parent was wrong
- **Root cause**: Misunderstanding FauxScrollFrame visibility management - scroll frames don't manage children's visibility, only positioning and offset
