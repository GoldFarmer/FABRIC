---
inclusion: manual
---

# WEAVE — Namespace Index

WEAVE extends Equipment-EX with auto-tagging, tag management, outfit synchronization, item adding, user configuration, and a bundled expanded `EquipmentEx.reds` UI/performance layer. All classes live in `module EquipmentEx` (same redscript module as Equipment-EX).

**Sources:** `r6\scripts\WEAVE\` plus the package's `r6\scripts\EquipmentEx\EquipmentEx.reds` replacement.
**Index:** [cyberpunk-mods-index.md](../cyberpunk-mods-index.md)

## Namespaces / Modules

| File / Area | Key Classes | Detail File |
|-------------|-------------|-------------|
| **Config** | `WEAVEConfig` — ModSettings-backed config singleton | (see below) |
| **AutoTag** | `AutoTagEngine`, `AutoTagScorer`, DTOs | [mod-weave-autotag.md](mod-weave-autotag.md) |
| **AutoTagDB** | `AutoTagDB`, `AutoTagDBCache` — static keyword/color/tag data | [mod-weave-autotag.md](mod-weave-autotag.md) |
| **TagManager** | `TagManagerSystem`, `TagStorageService`, `TagEditorPopup` | [mod-weave-tagmanager.md](mod-weave-tagmanager.md) |
| **OutfitSync** | `OutfitSyncSystem`, `OutfitStorageService` — JSON outfit persistence | [mod-weave-outfitsync.md](mod-weave-outfitsync.md) |
| **ItemAdder** | `WEAVEItemAdderSystem` — scans and equips vanilla clothing | (see below) |
| **Localization** | `LocalizationProvider extends ModLocalizationProvider` | (inline with Codeware.Localization) |
| **Wardrobe performance overlay** | lazy grid construction, silent batch outfit switching, binary insertion sort, hash-based filter cache, scroll-wheel fixes | bundled `EquipmentEx\EquipmentEx.reds` |

## Wardrobe Performance Overlay

The installed WEAVE package includes an expanded `EquipmentEx\EquipmentEx.reds`, whose own modification
summary states: two-layer lazy construction, silent batch outfit switching, binary insertion sorting,
and a hash-based filter cache. This is distinct from the tag services under the `WEAVE\` folder.

**Installed-source verification (2026-08-03):** the game's
`r6\scripts\EquipmentEx\EquipmentEx.reds` is byte-for-byte identical to WEAVE's package copy
(375,032 bytes, SHA-256 `B837D98324EEB369D72DC3867F56A13B7607B8FE56564552370F1C12FC079EB0`),
and differs from the standalone Equipment-EX file (171,730 bytes). WEAVE therefore **replaces**
the core source in this deployment; use the installed/WEAVE replacement as the authoritative
Equipment-EX source when examining runtime behavior.

### Replacement scope versus standalone Equipment-EX

WEAVE 1.4.7 replaces exactly one standalone Equipment-EX payload path:

| Package path | WEAVE behavior |
|---|---|
| `r6\scripts\EquipmentEx\EquipmentEx.reds` | Complete replacement: 9,274 lines versus stock 4,574 lines. |
| `r6\scripts\EquipmentEx\EquipmentEx.Global.reds` | Not shipped by WEAVE; the standalone Equipment-EX global facade remains in place. |

The replacement retains the central `OutfitSystem`, `OutfitPart`, `OutfitSet`, `OutfitState`, and
wardrobe controller types, but changes their implementation and adds:

- OutfitSystem capabilities for custom mappings, visual preview/restore, `IsEquippedByTDBID`,
  `GetDefaultItemSlot`, `ResetItemMapping`, `RefreshAllBlackboards`, `RenameOutfit`, three
  `AddOutfit` overloads, timestamps, and item-give helpers.
- Wardrobe UI features for slot/tag/search filtering, virtual try-on, batch selection, batch
  mapping/removal, lazy grid population, filter caching, binary insertion sorting, and scroll repair.
- Eighteen additional UI/event/callback classes, including `PopulateGridCallback`,
  `SearchDebounceCallback`, `SSRefreshChainCallback`, filter/tag popup types, preview events, and
  batch-operation events.
- One supported vanilla hook of its own: `@wrapMethod(InventoryItemDisplayController)` for
  `NewUpdateEquipped`, plus an added method on that vanilla controller for its preview marker.

No added feature emits a public successful saved-outfit create/save/delete/copy lifecycle event.

### Runtime effect of the replacement

The replacement is loaded at the same `EquipmentEx\EquipmentEx.reds` path as the core wardrobe implementation. It therefore changes the implementation reached by the existing Equipment-EX wardrobe lifecycle instead of adding a second screen or service. When the wardrobe opens, its lazy grid path defers card construction; when filters, search, tags, or batch selection change, it rebuilds the relevant visible data; when an outfit is switched, it batches visual changes before refreshing blackboards and the UI. The replacement's `InventoryItemDisplayController.NewUpdateEquipped` wrapper runs during card refresh to maintain its preview marker. Its purpose is to keep the grid responsive while adding tag/search/try-on state; the resulting effect is a modified Equipment-EX wardrobe experience, not a separate game menu.

## WEAVEConfig

`WEAVEConfig extends ScriptableSystem` — obtain via `WEAVEConfig.Get()`.

| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| `outfitSyncEnabled` | Bool | true | Enable JSON outfit sync |
| `outfitMergeEnabled` | Bool | true | Merge outfits on load |
| `autoTagApplyOnLoad` | Bool | true | Apply auto-tags when outfit loads |
| `autoTagAutoFullRescan` | Bool | false | Full rescan on game load |
| `wardrobeCollapseOnOpen` | Bool | false | Collapse wardrobe sections by default |
| `itemAdderEnabled` | Bool | true | Enable item adder feature |
| `itemAdderRemoveAll` | Bool | false | Remove all items before adding |

```swift
static func Get() -> ref<WEAVEConfig>
```

## WEAVEItemAdderSystem

`WEAVEItemAdderSystem extends ScriptableSystem` — adds vanilla clothing items to inventory in batches.

```swift
func TriggerScan() -> Void
func ProcessScanBatch() -> Void
```

Contains static arrays `WEAVEVanillaClothing_0` through `WEAVEVanillaClothing_4` with vanilla item IDs.
