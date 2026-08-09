# FABRIC – Design

> Wardrobe Relationship Tracker for WEAVE & Equipment-EX

---

## Overview

FABRIC is a REDscript mod for Cyberpunk 2077. It is structured as a **backend service** that maintains an item-to-outfit association index, plus one or more **UI adapters** that query only that service. No adapter reads wardrobe data directly.

```
┌───────────────────────────────────────┐
│ Wardrobe Usage Service (backend)      │
│ ItemID + TweakDBID → Set<CName> indexes │
│ Full rebuild at supported boundaries   │
└──────────────────┬────────────────────┘
                   │ query only
┌──────────────────▼────────────────────┐
│ UI integration layer                   │
│ vanilla wardrobe/card refresh boundary │
└───────────────────────────────────────┘
```

---

## Module Breakdown

### FabricService and backend collaborators

`FabricService` is the Codeware singleton façade. It owns no index implementation details and has
no knowledge of Ink widgets or Equipment-EX API calls. `FabricOutfitReader` owns the conditional
Equipment-EX read boundary and returns short-lived `FabricRebuildEntry` values.
`FabricUsageIndex` owns the transient exact-item and record indexes; `FabricWardrobeSession` owns
the transient scope used to distinguish wardrobe card presentation from other vanilla card bindings.

**State**

```redscript
// Exact owned-item index for Wardrobe and player Inventory.
let itemIndex: HashMap<ItemID, HashSet<CName>>;

// Catalog index for Virtual Atelier, which exposes an item record rather than an owned instance.
let recordIndex: HashMap<TweakDBID, HashSet<CName>>;

```

`ItemID` is the canonical association identity for owned Wardrobe and player Inventory cards. `TweakDBID` is a secondary catalog identity used only when Virtual Atelier exposes a synthetic store item rather than an owned instance. FABRIC performs full rebuilds only and does not retain per-outfit snapshots between rebuilds.

**Public API**

```redscript
public func GetUsageCount(itemID: ItemID) -> Int32
public func GetAssociatedOutfitIDs(itemID: ItemID) -> array<CName>
public func GetAssociatedOutfitNames(itemID: ItemID) -> array<String>
public func GetRecordUsageCount(itemID: ItemID) -> Int32
public func GetAssociatedOutfitNamesByRecord(itemID: ItemID) -> array<String>
```

**Internal cache management**

```redscript
FabricService.RebuildFull()
FabricUsageIndex.Add(itemID: ItemID, outfitName: CName)
FabricUsageIndex.IsEntryIndexed(entry: ref<FabricRebuildEntry>) -> Bool
```

All public API methods are O(1) hash lookups. `RebuildFull` is O(total item references across outfits).

---

### Cache refresh boundaries

`FabricService` coordinates `FabricOutfitReader` and `FabricUsageIndex` during `RebuildFull()` and
exposes only O(1) lookup methods to UI rendering. Initial reconciliation runs after
`PlayerPuppet.OnGameAttached`.

Direct REDscript annotation interception of the script-defined `EquipmentEx.OutfitSystem` is unsupported in the current runtime. FABRIC uses ordinary service reads only; it does not directly wrap Equipment-EX methods. The compiler boundary is documented in REDscript steering.

The selected refresh mechanism is event-driven; polling is not allowed. FABRIC wraps the base-game `GenericMessageNotification.Close(result)`, calls the original once, then performs a full rebuild only when the actual result is `Confirm` and the popup's localized title/message match Equipment-EX's Save Outfit or Delete Outfit keys. This runs after Equipment-EX persistence. No incremental cache path is retained because this boundary supplies no reliable per-outfit mutation payload.

The selected item-card refresh boundaries are the base-game `InventoryItemDisplayController.NewUpdateEquipped(UIInventoryItem)`, `NewRefreshUI(UIInventoryItem)`, and `RefreshUI()` methods. Equipment-EX uses the first for its visible virtual-grid cards; the player Inventory uses the second; both query the exact `ItemID` index. Virtual Atelier's data-backed cards use `RefreshUI()`, resolve their ID from `InventoryItemData.GetGameItemData(this.m_itemData).GetID()`, and query the record index. Wardrobe markers are gated by the `WardrobeUIGameController` lifecycle. Player Inventory markers are instead scoped by the Inventory card's own `NewRefreshUI` binding because the host inventory controller may uninitialize while the Backpack view remains active. Each FABRIC marker is created once after the original item-card initialization completes, then its visibility is reset during each supported card-refresh path. Standard tooltips query the exact index; catalog tooltips query the record index. This does not annotate any Equipment-EX or Virtual Atelier scripted UI class.

### External mod compatibility context

Equipment-EX is the authoritative source of saved-outfit data. `FabricOutfitReader` alone reads
`GetOutfits()` and `GetOutfitParts(CName)` behind `@if(ModuleExists("EquipmentEx"))`; its
complementary implementation safely reports no available reader. `FabricService` then resets its
index, emits an actionable warning, and leaves markers and outfit tooltips hidden rather than
attempting a vanilla fallback. After player attachment, the service publishes one eight-second
`SimpleScreenMessage` through the vanilla `UI_Notifications` blackboard if the integration remains
unavailable.

WEAVE is optional. Its outfit-sync restore path can reconstruct references from a `TweakDBID`; FABRIC retains exact owned-item associations while its catalog index presents restored references consistently in Virtual Atelier after reconciliation. The installed sync implementation offers no public post-sync notification, so FABRIC does not claim immediate automatic reconciliation after a JSON sync; the limitation and requested extension are documented in `docs/weave-sync-limitations.md`.

Virtual Atelier is a separate storefront and preview system. Its catalog/cart visibility and TweakDBID-based ownership display do not indicate Equipment-EX outfit membership. FABRIC relies only on authoritative saved-outfit data and uses the shared vanilla `InventoryItemDisplayController` card and standard tooltip paths for its presentation.

---

### UI Integration

`FabricEventBridge` contains only required REDscript hook contracts and lifecycle delegation.
`FabricWardrobeMutation` classifies supported popup results and coordinates the post-persistence
full rebuild. `FabricTooltip` owns the reusable tooltip section independently of card presentation.
`FabricUsageMarkerPresenter` owns FABRIC's per-card Ink presentation, including one-time widget
creation, active marker styling, count rendering, and virtualized-card reset behavior. The UI
integration layer is responsible for the supported host interfaces. Its selected wardrobe boundary
is the vanilla item-card refresh path above. It must:

1. Locates the relevant Ink controllers or widgets.
2. Calls `FabricService` for data.
3. Applies FABRIC's visual changes (marker and tooltip).
4. Uses only item metadata APIs to identify clothing; never checks hard-coded category strings.

FABRIC must not directly annotate an Equipment-EX scripted controller or method. Source-discovered Equipment-EX UI seams remain reference material in steering. The marker implementation uses a FABRIC-owned upper-left `inkImage`, initialized from the vanilla loop-bordered atlas. The shipped style uses its `clothing` texture part and green tint for both the icon and Raj Semi-Bold count label. Owned-card paths query the complete `ItemID`; only Virtual Atelier catalog paths resolve the record before querying the service. The marker must not reuse another mod's marker widget. The marker occupies a 21 × 21 px box with 12 px left and top insets. Its count label begins at a 36 px left and 8 px top inset. FABRIC disables safely with diagnostics if its hard Equipment-EX dependency is unavailable or incompatible. Its logging helper uses the shared game-level REDscript logging declarations and does not package or declare those native functions itself.

---

### Marker style

`FabricMarkerStyle` maps marker choices to a texture part and `HDRColor`, with a shipped
`clothing`/green upper-left default. `FabricMarkerSettings` owns optional Mod Settings resolution;
the enclosed `FabricModSettings` declaration exposes curated `FabricMarkerIcon`,
`FabricMarkerColor`, and `FabricMarkerCorner` enums. Every supported item-card refresh obtains the
resolved values from `FabricMarkerSettings` and applies the resulting style and mirrored corner
layout. Mod Settings is never referenced by core, UI presenter, or diagnostics code.

### FabricConfig

Thin configuration wrapper. Exposes:

```redscript
public func IsVerboseLoggingEnabled() -> Bool
```

Release default: verbose logging off. Debug default: verbose logging on. When enabled, `FabricService` and adapters emit diagnostic events such as rebuild trigger, rebuild duration, and cache sizes.

### FabricLog

`FabricLog` is the sole diagnostics wrapper. For each permitted severity it emits one
severity-prefixed message through the matching engine `Log` function (`Log`, `LogWarning`, or
`LogError`), which supplies CET Game Log visibility and writes to CET's `gamelog.log`.

### Source documentation hygiene

Every FABRIC class and function has an immediate contract docstring. Function contracts state
purpose, parameters, return behavior, and error or safe-default behavior; `tests/quality.ps1`
enforces the required `@param`, `@return`, and `@errors` fields alongside source width and stale
implementation-path checks.
Engine-log entries carry a `[FABRIC]` prefix; error entries additionally use Codeware `GetStackTrace(3, true)` to record
the immediate class/function call site. The shared native declarations remain a game-level
prerequisite and are never packaged with FABRIC.

---

## Data Flow

### Startup / save load

```
Game load event
  → PlayerPuppet.OnGameAttached()
    → FabricService.RebuildFull()
      for each saved outfit:
        read outfit items
        for each item:
          itemIndex[item].add(outfitName)
          recordIndex[ItemID.GetTDBID(item)].add(outfitName)
```

### Cache reconciliation

```
Supported event boundary
  → FabricService.RebuildFull()
    → enumerate saved outfits and their parts
    → replace itemIndex and recordIndex atomically
    → request or await the host view's normal item-card refresh
```

The service deliberately performs full rebuilds only because the production mutation boundary supplies no reliable per-outfit payload.

### Item widget rendered

```
Supported item-render boundary(widget, itemID)
  count = FabricService.GetUsageCount(itemID)   // O(1)
  if count > 0:
    show upper-left clothing marker
    apply active marker style and update marker count
  else:
    hide marker
```

### Standard item tooltip updated

```
Vanilla item-tooltip update boundary(itemID)
  names = FabricService.GetAssociatedOutfitNames(itemID)
  sort names alphabetically
  update FABRIC-owned "Outfits:" section, preceded by a 654 px `MainColors.Red` horizontal divider at 0.04 opacity, in the standard item tooltip
```

---

## Duplicate Item Handling

Equipment-EX `OutfitPart` stores a complete `ItemID`, which FABRIC retains in snapshots and an exact association index. Wardrobe and player Inventory indicators use this complete identity, so distinct owned instances of one record can differ. Virtual Atelier indicators use `TweakDBID` because catalog cards do not represent a specific owned instance.

WEAVE sync can restore an `ItemID` from its record. This remains compatible with FABRIC's Virtual Atelier catalog index.

---

## Error Handling

- Item-query methods return safe defaults (`false`, `0`, empty array) for invalid identities or unavailable indexes.
- Each authoritative `RebuildFull` validates its snapshots against both indexes. An inconsistency logs a warning and triggers one bounded immediate retry; a second failure logs an error and retains the most recently rebuilt safe state. No polling or render-time outfit scan is used.
- Adapters check for a null or unavailable service reference before making calls; they render items without markers if the service is unavailable, never crashing the UI.

---

## File / Module Layout

```
src/
  FABRIC/
    core/
      FabricBuildMarker.reds  # dependency-free build metadata
      FabricConfig.reds       # runtime logging configuration
      FabricOutfitReader.reds # authoritative Equipment-EX data reader
      FabricService.reds      # Codeware façade and full rebuild coordination
      FabricUsageIndex.reds   # exact and record association indexes
    integration/
      FabricEventBridge.reds  # required hooks and lifecycle delegation only
      FabricWardrobeMutation.reds # popup classification and rebuild coordination
    ui/
      FabricUsageMarkerPresenter.reds # card Ink presentation
      FabricWardrobeSession.reds      # transient wardrobe presentation scope
      FabricTooltip.reds      # reusable vanilla-tooltip presentation
    settings/
      FabricMarkerSettings.reds # optional Mod Settings bridge
      FabricMarkerStyle.reds  # shipped marker presentation mapping
    diagnostics/
      FabricLog.reds          # diagnostic logging helpers

FABRIC_Mod_Specification.md
```

---
