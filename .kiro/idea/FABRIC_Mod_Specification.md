# FABRIC

> **Planning-status note:** This is the original product exploration. The authoritative implemented scope is maintained in `.kiro/specs/fabric-mod/`. Used/Unused filtering and Wardrobe-usage sorting remain deferred; incremental snapshot reconciliation was rejected because FABRIC's supported mutation boundary has no reliable per-outfit payload.

## Wardrobe Relationship Tracker for WEAVE & Equipment-EX

> *Your wardrobe is data. FABRIC keeps the pattern.*

## 1. Purpose

FABRIC is a Cyberpunk 2077 quality-of-life mod that reveals the relationship between owned clothing items and saved wardrobe outfits. It is intended to complement **WEAVE** and **Equipment-EX**, rather than replace either mod's wardrobe or equipment-management features.

The core player question FABRIC answers is:

> Which clothing items are connected to my visual identities?

FABRIC should help players avoid accidentally selling, dismantling, or overlooking clothing that is used in one or more wardrobe outfits.

## 2. Product Identity

**Name:** FABRIC  
**Suggested subtitle:** *Wardrobe Relationship Tracker for WEAVE & Equipment-EX*  
**Optional expansion:** *Fashion Association & Wardrobe Relationship Index Cache*

FABRIC has both fashion and technical connotations: a clothing fabric, and a data fabric that maps relationships.

### Suggested terminology

| Term | Meaning |
|---|---|
| FABRIC Threads | Item-to-outfit associations |
| FABRIC Markers | Usage icon and count on an item |
| FABRIC Filters | Used / Unused wardrobe filters |
| Loose Threads | Clothing unused by any saved outfit |
| Fabric Inspector | Tooltip or diagnostic view |

## 3. Goals

1. Show whether a clothing item is referenced by one or more saved wardrobe outfits.
2. Show how many outfits reference that item.
3. On demand, show the names of the related outfits.
4. Allow players to filter clothing by whether it is used or unused.
5. Allow players to sort clothing by number of outfit associations.
6. Distinguish duplicate inventory instances when the game data supports it.
7. Work with Equipment-EX's wardrobe workflow without relying on hard-coded slots, categories, or UI controllers.
8. Keep UI rendering fast even with large inventories and many outfits.

## 4. User Experience

### 4.1 Usage marker

Clothing used by one or more saved outfits receives a small **green shirt icon** with a numeric count.

```text
Black Jacket                         👕 2
```

Items with no associations receive no marker.

The marker appears only for clothing as determined by game item metadata; FABRIC must not hard-code vanilla clothing category names.

### 4.2 Tooltip

Hovering the marker displays the outfits that reference the item.

```text
Used by:

Casual
Corpo
Johnny
```

Outfit names should be resolved at display time and sorted alphabetically so renamed outfits remain current without rewriting the item cache.

### 4.3 Filters

Add the following wardrobe-aware filters where the host interface supports them:

```text
All
Used
Unused
```

- **Used:** usage count is greater than zero.
- **Unused:** usage count is zero.

### 4.4 Sorting

Provide a FABRIC-owned **Wardrobe Usage** sort control; do not rely on a native Equipment-EX sort-menu entry because the grid disables native sorting during `UpdateView()`.

1. Sort by number of associated outfits, descending.
2. Break ties by item display name, ascending.

## 5. Data Model and Backend

FABRIC has a UI-independent backend service. UI overlays, filters, sorting, and any future integrations query this service instead of reading wardrobe data directly.

### 5.1 Required service API

```text
IsItemUsed(itemID) -> Bool
GetUsageCount(itemID) -> Int
GetAssociatedOutfitIDs(itemID) -> Set<CName>
GetAssociatedOutfitNames(itemID) -> Array<String>
```

### 5.2 Primary association index

Use a direct item-to-outfit relationship index:

```text
ItemID -> Set<CName>
```

Example:

```text
item123 -> { Outfit 1, Outfit 3, Outfit 7 }
```

Store stable outfit identifiers as the primary data. Resolve outfit names dynamically for tooltips. Names can change; identifiers should not.

### 5.3 Outfit snapshot

Maintain an optional snapshot for each outfit when callbacks do not provide both its prior and new item lists:

```text
CName -> Set<ItemID>
```

This snapshot supports efficient diffs when an outfit changes. It is not a substitute for the game's own outfit data and is only required if the available events lack sufficient context.

### 5.4 Cache lifecycle

**Outfit created**

1. Read its item references.
2. Add the outfit ID to each referenced item's association set.
3. Store its item snapshot if needed.

**Outfit deleted**

1. Read its current or cached item references.
2. Remove the outfit ID from each association set.
3. Remove its snapshot.

**Outfit modified**

1. Obtain old and new item lists, or retrieve the old list from the snapshot.
2. Remove associations for items no longer present.
3. Add associations for newly present items.
4. Replace the snapshot.

**Outfit renamed**

Equipment-EX has no native rename operation. WEAVE renames by adding a new named outfit and deleting the old one; FABRIC processes those wrapped mutations normally so associations move to the new outfit name.

**Full rebuild**

Provide a complete rebuild for game/save load, recovery after synchronization failure, debugging, and manual refresh. A full rebuild should scan every saved outfit once.

## 6. Duplicate Handling

Equipment-EX persists the complete `ItemID` in every `OutfitPart`. FABRIC therefore uses the complete `ItemID`, including its `rng_seed`, as the canonical identity for an inventory instance. It must never associate items by TweakDB record ID alone. `ItemID.GetCombinedHash()` is permitted as the runtime map-key implementation detail, but FABRIC retains the complete ID for equality checks and diagnostics.

### Per-instance behavior

When two visible items have different complete `ItemID` values (including different `rng_seed` values), mark only the referenced copy.

```text
Blue Jacket A                         👕 2
Blue Jacket B
```

### Shared-stack and synchronization fallback

Equal complete `ItemID` values represent a shared stack, not two distinguishable copies. FABRIC must show stack-level usage and must not invent per-row distinctions.

WEAVE 1.0.0 synchronization restores item references with `ItemID.FromTDBID(tweakID)`, so outfits restored through that path can lose per-instance precision. Rebuild after WEAVE's player-attach sync; for those restored references, show the association represented by the restored `ItemID` and do not guess a particular duplicate.

```text
Blue Jacket A                         👕 2
Blue Jacket B                         👕 2
```

## 7. Compatibility Architecture

FABRIC must separate relationship tracking from display integration.

```text
Wardrobe Usage Service
        |
        +-- Equipment-EX wardrobe UI adapter
        +-- Future compatible UI adapters
```

The backend must contain no UI logic. Each adapter is responsible for locating its item widgets and applying markers, tooltips, filters, or sort behavior appropriate to that interface.

### Equipment-EX requirements

FABRIC must:

- require Equipment-EX as the sole runtime outfit authority;
- support clothing introduced or managed by Equipment-EX where the underlying data permits;
- tolerate additional slots and layered equipment;
- use game item metadata and identity APIs rather than hard-coded vanilla slot names or categories;
- avoid assuming vanilla inventory widgets or controllers;
- use the confirmed Equipment-EX grid hooks rather than maintaining a vanilla runtime adapter;
- treat WEAVE as optional and rebuild after its compatible sync path completes.

## 8. Required Investigation Before Production Code

Do not assume REDscript class names, callbacks, or data shapes. First inspect the current game scripts, relevant framework definitions, WEAVE, and Equipment-EX.

### 8.1 Wardrobe API

Complete: use `EquipmentEx.OutfitSystem` as the sole authority; enumerate via `GetOutfits()`, retrieve with `GetOutfitParts(name)`, use persistent `CName` names with `NameToString(name)` for display, and process `array<ref<OutfitPart>>` entries.

### 8.2 Item identity

Completed: Equipment-EX `OutfitPart` stores a complete `ItemID`; FABRIC keys associations by its complete value (including `rng_seed`) and uses `GetCombinedHash()` only as a map-key implementation detail. Equal IDs are shared stacks. The remaining runtime test verifies that apparent UI duplicates receive distinct IDs; WEAVE 1.0.0 sync is the documented record-level fallback.

### 8.3 Events and hooks

Complete: wrap `AddOutfit`, `SaveOutfit`, `DeleteOutfit`, `DeleteAllOutfits`, and `CopyOutfit`; use pre-call snapshots and post-success reads for incremental diffs, then rebuild after player attach or reconciliation failure. WEAVE rename is add then delete.

### 8.4 UI integration

Complete: marker rendering targets `InventoryItemDisplayController.NewUpdateEquipped(UIInventoryItem)` via the `WardrobeScreenController` grid. `InventoryGridDataView.FilterItem()` is the filter seam; native sorting is disabled by `UpdateView()`, so FABRIC owns its sort state and data-source ordering.

## 9. Performance and Reliability

- Item-widget rendering must be an O(1) cache lookup. Never scan every outfit while rendering an item.
- Incremental changes should be O(number of items changed).
- A full rebuild should be O(total item references across saved outfits).
- Cache failures must not crash or block wardrobe UI.
- On invalid synchronization, log diagnostics and rebuild the cache.
- Put detailed logging behind a configuration flag.

Useful diagnostic events include cache rebuilds, rebuild duration, cache size, outfit lifecycle events, and association additions/removals.

## 10. Implementation Phases

1. **Reverse engineering:** document the actual wardrobe, identity, event, and UI APIs.
2. **Toolchain:** establish reproducible development install, REDscript type checks, optional hot reload, release packaging, and in-game smoke testing before production code.
3. **Backend index:** implement the item-to-outfit association cache and full rebuild; validate it through outfit create/edit/delete/rename operations.
4. **Usage markers:** add the green shirt icon and count badge through the appropriate UI adapter.
5. **Tooltip:** list dynamically resolved, alphabetically sorted outfit names.
6. **Filters:** implement Used and Unused using backend queries only.
7. **Sorting:** add Wardrobe Usage sort behavior using backend queries only.
8. **Compatibility and polish:** complete Equipment-EX integration, configuration, error handling, logging, and optional display in other inventory contexts.

## 11. Acceptance Criteria

FABRIC is ready for release when:

- every eligible clothing item shows an accurate usage marker;
- the marker count equals the number of associated outfits;
- tooltips list the correct, current outfit names;
- Used and Unused filters return correct results;
- Wardrobe Usage sorting is correct and stable;
- duplicate instances are distinguished whenever the game data makes that possible;
- outfit edits update associations without unnecessary full rebuilds whenever supported by available APIs;
- a full rebuild recovers a valid cache;
- large inventories scroll without a measurable slowdown;
- the Equipment-EX wardrobe adapter remains isolated from the backend service;
- unsupported or changing APIs fail safely and produce actionable diagnostics.

## 12. Deliberate Non-Goals for the Initial Release

- Replacing WEAVE, Equipment-EX, or the base-game wardrobe manager.
- Guessing associations when the game does not provide a unique item reference.
- Hard-coding vanilla clothing slots, categories, or controllers.
- Coupling the relationship backend to a particular UI implementation.
