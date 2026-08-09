---
inclusion: manual
---

# Cyberpunk 2077 Mod Reference Index

Reference index for the 11 installed mod sources. Navigate to per-mod files for namespace lists; from there to namespace detail files for classes and APIs.

## Game Installation

| | Path |
|-|------|
| **Game root** | `C:\Program Files (x86)\Steam\steamapps\common\Cyberpunk 2077` |
| **Scripts** | `...\r6\scripts\` |
| **Tweaks** | `...\r6\tweaks\` |
| **RED4ext plugins** | `...\red4ext\plugins\` |
| **Mod manager staging** | `C:\Users\srfon\AppData\Roaming\Vortex\cyberpunk2077\mods\` |

## Vanilla Game API

Reverse-engineered from mod source. Hydrate with targeted script dump lookups when needed.

| File | Covers |
|------|--------|
| [vanilla/game-systems.md](vanilla/game-systems.md) | `GameInstance` accessors, `WardrobeSystem`, `TransactionSystem`, `EquipmentSystem`, `DelaySystem`, `TweakDBInterface`, blackboards, `UISystem`, `CallbackSystem` |
| [vanilla/game-inventory.md](vanilla/game-inventory.md) | `InventoryDataManagerV2`, `InventoryItemData`, `ItemID`, `UIInventoryItem`, `UIInventoryItemsManager`, `ScriptableDataSource/View`, TweakDB record types |
| [vanilla/game-ui.md](vanilla/game-ui.md) | Ink controller hierarchy, `gameuiInventoryGameController`, `WardrobeUIGameController`, `gameuiPhotoModeMenuController`, UI events, `ButtonHints`, `GenericMessageNotification` |
| [vanilla/game-hooks.md](vanilla/game-hooks.md) | Documented base-game popup and inventory UI hook targets, including `GenericMessageNotification` and `PopupsManager` |

## Mods

| Mod | Role | Steering File |
|-----|------|---------------|
| **WEAVE** | Equipment-EX extension — auto-tagging, tag management, outfit sync, item adder, config | [mod-weave.md](weave/mod-weave.md) |
| **Equipment-EX** | Core outfit/wardrobe system — custom outfit slots, outfit manager UI, inventory helpers | [mod-equipment-ex.md](equipment-ex/mod-equipment-ex.md) |
| **Virtual Atelier** | In-game browser storefront — registered mod shops, cart purchases, virtual try-on, store search | [mod-virtual-atelier.md](virtual-atelier/mod-virtual-atelier.md) |
| **Inventory Adjustments Hub** | Inventory and tooltip presentation — card layout, stats, effect/tag indicators, crafting and settings UI | [mod-inventory-adjustments-hub.md](inventory-adjustments-hub/mod-inventory-adjustments-hub.md) |
| **ArchiveXL** | Asset loading extension — dynamic appearances, body type queries, garment offsets | [mod-archivexl.md](archivexl/mod-archivexl.md) |
| **Codeware** | Scripting framework — native field extensions, localization system, custom UI widgets | [mod-codeware.md](codeware/mod-codeware.md) |
| **redscript** | Redscript compiler/runtime (`scc.exe`) — no scripted API surface | [mod-redscript.md](redscript/mod-redscript.md) |
| **TweakXL** | TweakDB runtime patcher — no scripted API surface | [mod-tweakxl.md](tweakxl/mod-tweakxl.md) |
| **RED4ext** | RED4 native extension loader (`winmm.dll`) — no scripted API surface | [mod-red4ext.md](red4ext/mod-red4ext.md) |

| **Mod Settings** | RED4ext/redscript configuration framework — runtime-property discovery, typed values, and a native settings UI | [mod-mod-settings.md](mod-settings/mod-mod-settings.md) |
| **Native Settings UI** | CET/Lua settings UI framework — tabs, subcategories, controls, callbacks, and settings-page integration | [mod-native-settings.md](native-settings/mod-native-settings.md) |

## Module Namespace Note

Both WEAVE and Equipment-EX declare `module EquipmentEx` in redscript. They are treated as separate mods here; WEAVE adds supplemental systems on top of Equipment-EX's core.

## Redscript Conventions Used Across Mods

- `ScriptableSystem` — game singleton, obtain via `GameInstance.GetScriptableSystemsContainer(game).Get(n"ClassName")`
- `ScriptableService` — service singleton via `GameInstance.GetScriptableServiceContainer(game).Get(n"ClassName")`
- `@wrapMethod` / `@replaceMethod` / `@addMethod` / `@addField` — patch decorators
- `native` — implemented in C++ (RED4ext plugin), exposed to redscript
