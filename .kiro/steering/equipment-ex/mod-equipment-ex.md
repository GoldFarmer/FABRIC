---
inclusion: manual
---

# Equipment-EX — Namespace Index

Equipment-EX is the custom outfit and wardrobe system for Cyberpunk 2077. It adds equipment slots, an outfit manager UI, and scripted outfit APIs.

**Source:** `r6\scripts\EquipmentEx\`
**Module:** `EquipmentEx`
**Index:** [cyberpunk-mods-index.md](../cyberpunk-mods-index.md)

## Namespaces / Modules

| Area | Key classes | Detail file |
|---|---|---|
| Core — OutfitSystem | `OutfitSystem`, `OutfitPart`, `OutfitSet`, `OutfitState` | [mod-equipment-ex-outfitsystem.md](mod-equipment-ex-outfitsystem.md) |
| Global API | `EquipmentEx abstract` static facade | [mod-equipment-ex-outfitsystem.md](mod-equipment-ex-outfitsystem.md) |
| Helpers | `InventoryHelper`, `PaperdollHelper`, `ViewManager`, `CompatibilityManager` | This file |
| UI | `WardrobeScreenController`, `OutfitMappingPopup`, `OutfitManagerController`, `OutfitListEntryController`, `InventoryGridSlotController` | This file |

## Helper classes

`InventoryHelper` queries the player's inventory items and slots. `PaperdollHelper` manages wardrobe preview state. `ViewManager` tracks wardrobe UI view state. `CompatibilityManager` contains compatibility checks for known systems.

## UI controllers

| Class | Base | Purpose |
|---|---|---|
| `WardrobeScreenController` | `inkPuppetPreviewGameController` | Wardrobe/outfit manager screen |
| `OutfitMappingPopup` | `InMenuPopup` | Custom outfit-slot assignment popup |
| `OutfitManagerController` | `inkLogicController` | Outfit-list panel |
| `OutfitListEntryController` | `inkLogicController` | Single outfit-list row |
| `InventoryGridSlotController` | `inkLogicController` | Inventory grid slot widget |

## Game integration flows

Equipment-EX does not merely add an outfit data service: it substitutes its own active-outfit state for the game's wardrobe-set state along the player-equipment and UI paths. The decorators in `EquipmentEx.Global.reds` group into these flows.

| Trigger / host flow | Why it is intercepted | What Equipment-EX does | Result |
|---|---|---|---|
| Player equipment attaches, restores, changes appearance, or receives wardrobe quest requests (`EquipmentSystemPlayerData`) | Vanilla wardrobe-set state cannot represent Equipment-EX's custom slot mapping | Stores an `OutfitSystem` reference, reports its active/managed slots as visual overrides, suppresses conflicting vanilla appearance reset events, and replaces vanilla wardrobe-set/quest handlers | The active custom outfit remains visually equipped through load, quest, and equipment transitions |
| Inventory menu initializes or the wardrobe button/back/equipment actions are used (`gameuiInventoryGameController`, `InventoryItemModeLogicController`, `WardrobeUIGameController`) | The standard inventory menu has no Equipment-EX outfit-manager surface | Creates/removes the custom wardrobe screen, changes menu navigation and button hints, and redirects wardrobe-slot actions into that screen | Players enter and exit the Equipment-EX wardrobe manager from the normal inventory flow |
| Inventory cards bind or refresh, and UI inventory items/managers calculate equipped/transmog state (`InventoryItemDisplayController`, `UIInventoryItem`, `UIInventoryItemsManager`) | Vanilla card state knows only standard equipment/wardrobe slots | Attaches the outfit service to each data path and answers equipped/wardrobe/transmog checks from custom outfit state | Custom-slot items render with the correct equipped and requirement state in virtualized inventory views |
| Inventory or wardrobe puppet preview initializes/restores (`gameuiInGameMenuGameController`, `inkInventoryPuppetPreviewGameController`, `WardrobeSetPreviewGameController`) | Preview puppets must mirror the custom outfit, not just ordinary equipment | Initializes the service for the relevant game/puppet and updates or restores the preview from OutfitSystem state | Inventory and wardrobe previews show the selected custom outfit consistently |
| Photo Mode opens, its outfit selector changes, or its player entity updates (`gameuiPhotoModeMenuController`, `PhotoModeMenuListItem`, `PhotoModePlayerEntityComponent`) | Photo Mode's vanilla outfit control does not enumerate custom saved outfits | Adds and manages a custom outfit attribute, routes selection to the outfit service, and refreshes the Photo Mode puppet | Custom outfits can be selected and displayed in Photo Mode |
| Backpack preview/crafting preview actions, tutorial popups, quest tracker, and stash attach | These are adjacent entry points that can expose or conflict with wardrobe state | Routes preview actions through OutfitSystem when active, bypasses obsolete vanilla wardrobe tutorials, exposes a wardrobe entry from the quest tracker, and registers the stash with inventory helpers | Custom outfit behavior remains available and coherent outside the primary inventory screen |

## Source files

Equipment-EX supplies `EquipmentEx.reds` (core) and `EquipmentEx.Global.reds` (global facade and base-game annotations).

## Base-game annotations (`EquipmentEx.Global.reds`)

These annotations target base-game classes; none target `OutfitSystem`.

- `@wrapMethod`: `BackpackMainGameController`, `CraftingGarmentItemPreviewGameController`, `EquipmentSystemPlayerData`, `gameuiInGameMenuGameController`, `gameuiInventoryGameController`, `gameuiPhotoModeMenuController`, `PhotoModeMenuListItem`, `inkInventoryPuppetPreviewGameController`, `InventoryItemDisplayController`, `InventoryItemModeLogicController`, `PhotoModePlayerEntityComponent`, `PopupsManager`, `QuestTrackerGameController`, `UIInventoryItem`, `UIInventoryItemsManager`, and `WardrobeSetPreviewGameController`.
- `@replaceMethod`: methods on `EquipmentSystemPlayerData`, `gameuiInventoryGameController`, `InventoryItemModeLogicController`, and `WardrobeUIGameController`.
- `@addMethod`: methods on `EquipmentSystemPlayerData`, `gameuiInventoryGameController`, `gameuiPhotoModeMenuController`, `inkScrollController`, `QuestTrackerGameController`, `Stash`, `UIInventoryItem`, `UIInventoryItemsManager`, and `WardrobeUIGameController`.
