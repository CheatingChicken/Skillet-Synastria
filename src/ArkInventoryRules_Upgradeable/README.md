# ArkInventoryRules_Upgradeable

An ArkInventory filter rule addon for identifying and managing upgradeable items with intelligent attunable upgrade chain detection.

## Overview

This addon registers custom ArkInventory filter rules that allow you to search for upgradeable items in your inventory. It's particularly useful for identifying items that can be upgraded into attunable versions or for managing upgrade chains.

## Features

- **Upgrade Chain Tracking**: Automatically follows upgrade chains from source to final target items
- **Attunement-Aware Filtering**: Identifies items that upgrade into attunable versions for your character or account
- **Scoots ID Database**: Uses the complete Scoots ID upgradeable items database

## Dependencies

- ArkInventory (required)
- ArkInventoryRules (required)

## Filter Rules

### `upgradeable()`
Matches any item that has an upgrade available.

**Example**: Filter a bag to show only items that can be upgraded.

### `upgradeable("char")` or `upgradeable("character")`
Matches upgradeable items where **any** final upgrade target can be attuned by the current character.

Follows the complete upgrade chain and checks if the final upgrade result (after all possible upgrades) is attunable by your character.

**Example**: Find gear that upgrades into items you can attune (character-specific).

### `upgradeable("acc")` or `upgradeable("account")`
Matches upgradeable items where **any** final upgrade target is attunable by the account.

Follows the complete upgrade chain and checks if any final target is attunable by someone in your account.

**Example**: Find gear that upgrades into items attunable by any character (account-wide).

## Usage Examples

In an ArkInventory filter rule:

```
upgradeable()                    # Show all upgradeable items
upgradeable("char")              # Show upgradeable items leading to character-attunable upgrades
upgradeable("character")         # Same as above (full form)
upgradeable("acc")               # Show upgradeable items leading to account-attunable upgrades
upgradeable("account")           # Same as above (full form)
```

## Technical Details

### Upgrade Chains

The addon maintains a map of all known upgrades. Items can have multiple levels of upgrades (e.g., basic → inscribed → etched → runed). The addon automatically follows these chains to find the final upgrade targets.

**Example Chain**:
```
Ring of the Kirin Tor (44935)
  ↓ (upgrade 1)
Inscribed Ring of the Kirin Tor (45690)
  ↓ (upgrade 2)
Etched Ring of the Kirin Tor (48956)
  ↓ (upgrade 3)
Runed Ring of the Kirin Tor (51559)
```

When checking `upgradeable("unattunedChar")`, the addon will check if item ID 51559 (Runed Ring) is attunable, regardless of which item in the chain is being evaluated.

### Attunement Detection

Uses the Synastria custom API `GetHighestAttunePct()` to determine if items are attunable:
- `upgradeable("unattunedChar")`: Uses your character's attunement status
- `upgradeable("unattunedAcc")`: Conservative check (can be extended for account-wide attunement pools)

## Data Source

Contains **380+ upgrade mappings** from the Scoots ID Upgradables database.

## Version History

- **1.0.0** (2026-02-12): Initial release with core upgradeable rules and attunement chain detection
