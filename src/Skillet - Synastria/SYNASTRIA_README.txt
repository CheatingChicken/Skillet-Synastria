================================================================================
SKILLET - SYNASTRIA EDITION
================================================================================

Version: 1.13-Synastria
Original Author: nogudnik
Synastria Modifications: Priest
Date: January 24, 2026

================================================================================
WHAT IS THIS?
================================================================================

This is a modified version of Skillet that integrates with the Synastria
server's custom Resource Bank system. The Resource Bank is a server-side
storage system for crafting materials that is separate from your regular
inventory and bank.

================================================================================
NEW FEATURES
================================================================================

1. RESOURCE BANK INTEGRATION
   - Skillet now checks the Resource Bank when determining if you have enough
     reagents to craft items
   - Craftability calculations include Resource Bank items
   - Shopping lists account for items in the Resource Bank

2. ENHANCED REAGENT DISPLAY
   - Reagent counts now show Resource Bank availability in light green
   - Format: "bags+resbank/needed" 
   - Example: "5+10/20" means you have 5 in bags, 10 in Resource Bank,
     and need 20 total (so you're still short 5)

3. IMPROVED CRAFTABLE COUNTS
   - Recipe list shows: [bags/bank/resbank/alts]
   - Resource Bank counts appear in light green when different from bank count
   - Slider maximum uses Resource Bank totals

4. TOOLTIP ENHANCEMENTS
   - Recipe tooltips show how many can be crafted with Resource Bank items
   - "X can be created including Resource Bank" line in light green

================================================================================
HOW IT WORKS
================================================================================

The addon uses the server's custom API:
- GetCustomGameData(13, itemId) - Returns count of items in Resource Bank
  where 13 is the RESOURCE_BANK data type ID

When calculating craftability:
1. Standard count: Items in bags only
2. Bank count: Items in bags + bank
3. Resource Bank count: Items in bags + bank + Resource Bank (NEW!)
4. Alts count: Items across all characters

================================================================================
TECHNICAL DETAILS
================================================================================

Modified Files:
- Skillet.toc - Updated title and version
- SkilletStitch-1.1.lua - Added Resource Bank counting functions
- UI/MainFrame.lua - Updated UI to display Resource Bank counts
- UI/ShoppingList.lua - Shopping list accounts for Resource Bank
- Locale/Locale-enUS.lua - Added new tooltip text

Key Functions Added:
- extract_item_id(link) - Extracts item ID from item link
- get_resource_bank_count(link) - Gets Resource Bank count for an item
- numwresbank - New reagent metadata property
- numcraftablewresbank - New craftability calculation

================================================================================
COMPATIBILITY
================================================================================

This addon REQUIRES:
- Synastria server (or any server with GetCustomGameData API)
- Resource Bank system enabled

On standard WoW servers, this addon will function like regular Skillet
(Resource Bank features will simply show 0 counts).

================================================================================
DIFFERENCES FROM STANDARD SKILLET
================================================================================

All standard Skillet features remain intact. The only changes are:
1. Additional counts displayed (non-intrusive)
2. Better craftability detection with Resource Bank
3. More accurate shopping lists

You can safely replace standard Skillet with this version.

================================================================================
CREDITS
================================================================================

Original Skillet addon: nogudnik
Resource Bank integration: Priest
Synastria server custom API documentation

================================================================================
LICENSE
================================================================================

This addon maintains the same GPL v3 license as the original Skillet addon.
See LICENSE.txt for full details.

================================================================================
