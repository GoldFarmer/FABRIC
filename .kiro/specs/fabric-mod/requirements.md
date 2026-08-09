# FABRIC – Requirements

> Wardrobe Relationship Tracker for WEAVE & Equipment-EX  
> Cyberpunk 2077 quality-of-life mod

---

## Introduction

FABRIC answers one core player question: **which clothing items are connected to my saved wardrobe outfits?** It prevents accidental discard of outfit-referenced clothing by surfacing item-to-outfit associations in the wardrobe, player inventory, and virtual storefront views. FABRIC complements WEAVE and Equipment-EX; it does not replace any wardrobe or equipment-management feature.

---

## Requirements

### 1 – Usage Markers

**Requirement 1.1**  
WHEN a player opens the Wardrobe or player Inventory (including Backpack and storage)  
THEN only a clothing item whose complete `ItemID` is referenced by one or more saved outfits SHALL display FABRIC's small upper-left marker with a numeric count of associated outfits. WHEN a player opens a Virtual Atelier store  
THEN a catalog item SHALL display the marker when its `TweakDBID` record matches any complete `ItemID` referenced by one or more saved outfits.

**Requirement 1.2**  
WHEN an owned item's complete `ItemID` is referenced by zero saved outfits, or a catalog item's `TweakDBID` matches no referenced item record  
THEN no marker SHALL be shown for that item.

**Requirement 1.3**  
The marker SHALL be determined from game item metadata only. FABRIC MUST NOT hard-code vanilla clothing category names or slot names.

**Requirement 1.4**  
Item widget rendering SHALL resolve the usage count via an O(1) cache lookup. FABRIC MUST NOT scan outfit data while rendering any item widget.

**Requirement 1.5 – Marker style configuration**  
FABRIC SHALL ship a default marker style: the vanilla loop-bordered atlas `clothing` texture part, a green tint applied consistently to the marker icon and count, and the upper-left corner. The active icon, color, and corner SHALL be resolved without outfit scanning on every supported card refresh.

**Requirement 1.6 – Optional Mod Settings integration**  
WHEN Mod Settings is installed  
THEN FABRIC SHALL expose curated enum choices for the marker icon, color, and corner, persist accepted choices through Mod Settings, and apply the active values on each supported item-card refresh. WHEN Mod Settings is absent  
THEN FABRIC SHALL compile and run with its shipped default marker style and without a settings menu entry.

---

### 2 – Outfit Tooltip

**Requirement 2.1**  
WHEN a player hovers an owned Wardrobe or Inventory clothing item with a normal tooltip  
THEN that tooltip SHALL include an **Outfits:** section listing outfits that reference its complete `ItemID`. WHEN the tooltip represents a Virtual Atelier catalog item  
THEN the section SHALL list outfits that reference any complete `ItemID` with the same `TweakDBID`.

**Requirement 2.2**  
Outfit names in the tooltip SHALL be resolved at display time from FABRIC's current saved-outfit cache.

**Requirement 2.3**  
Outfit names SHALL be sorted alphabetically in the tooltip so that renamed outfits remain correct without re-writing the item cache.

---

### 3 – Backend Association Service

**Requirement 3.1**  
FABRIC SHALL provide a UI-independent backend service exposing at minimum:

- `GetUsageCount(itemID) -> Int`
- `GetAssociatedOutfitIDs(itemID) -> Set<CName>`
- `GetAssociatedOutfitNames(itemID) -> Array<String>`
- `GetRecordUsageCount(itemID) -> Int`
- `GetAssociatedOutfitNamesByRecord(itemID) -> Array<String>`

**Requirement 3.2**  
The backend SHALL maintain a primary exact index of shape `ItemID -> Set<CName>` and a secondary catalog index of shape `TweakDBID -> Set<CName>`. Wardrobe and player Inventory queries SHALL use the exact index. Virtual Atelier catalog queries SHALL resolve their supplied `ItemID` with `ItemID.GetTDBID()` and use the secondary index. Complete `ItemID` values SHALL be compared after hash-bucket lookup so a hash collision cannot become an identity match.

**Requirement 3.3**  
The backend SHALL not retain outfit snapshots or expose an incremental mutation API. The selected supported mutation boundary provides no reliable per-outfit payload, so every supported reconciliation replaces both indexes with one authoritative full rebuild.

**Requirement 3.4**  
The backend SHALL contain no UI logic. All UI adapters MUST query the backend; they MUST NOT read wardrobe data directly.

---

### 4 – Cache Lifecycle

**Requirement 4.1 – Supported outfit mutation**  
WHEN the confirmed Equipment-EX Save Outfit or Delete Outfit dialog closes  
THEN the backend SHALL replace both association indexes with one authoritative full rebuild after the host persistence callback completes.

**Requirement 4.2 – Outfit renamed**  
Equipment-EX has no native rename operation. WHEN a supported refresh boundary occurs after WEAVE renames an outfit, THEN FABRIC SHALL reconcile against authoritative saved-outfit state so association membership reflects the new `CName`.

**Requirement 4.2a – WEAVE JSON sync limitation**  
The installed WEAVE sync implementation provides no public post-sync notification. FABRIC SHALL not claim immediate reconciliation after a WEAVE JSON sync; it SHALL present correct associations after its next supported reconciliation boundary.

**Requirement 4.3 – Full rebuild**  
WHEN a game or save load occurs, or when the cache is flagged as invalid  
THEN the backend SHALL perform a full rebuild by scanning every saved outfit exactly once.

**Requirement 4.4 – View-time correctness**  
WHEN FABRIC renders item markers in the Wardrobe, player Inventory, or Virtual Atelier  
THEN the backend SHALL have reconciled the cache against the authoritative saved-outfit state before those markers are shown. Item rendering itself SHALL remain an O(1) cache lookup and SHALL NOT perform outfit scanning.

**Requirement 4.5 – Refresh strategy**  
FABRIC SHALL use an event-driven refresh strategy and SHALL NOT poll `OutfitSystem`. The selected refresh boundaries are post-player attachment and confirmed base-game Save/Delete popup closure; FABRIC SHALL not directly wrap script-defined Equipment-EX methods.

---

### 5 – Duplicate Item Handling

**Requirement 5.1 – Exact owned-item presentation identity**  
Equipment-EX outfit parts store complete `ItemID` values. IF two owned cards resolve to the same `TweakDBID` but have different complete `ItemID` values, THEN FABRIC SHALL present an outfit association only on the exact referenced owned item. Virtual Atelier catalog presentation SHALL use the shared `TweakDBID` record association.

**Requirement 5.2 – Rebuild precision**  
FABRIC SHALL preserve the complete `ItemID` values supplied by Equipment-EX while building its exact index. A WEAVE sync restore that uses `ItemID.FromTDBID(tweakID)` SHALL remain compatible with Virtual Atelier presentation because its catalog index is record-keyed.

---

### 6 – Compatibility Architecture

**Requirement 6.1**  
FABRIC SHALL separate the backend service from all UI display logic through its selected vanilla-controller integration layer. Every UI adapter SHALL query the same backend service.

**Requirement 6.2 – Equipment-EX integration**  
FABRIC SHALL support clothing managed by Equipment-EX where the underlying item data permits.

**Requirement 6.3**  
FABRIC SHALL tolerate Equipment-EX's additional slots and layered-equipment model.

**Requirement 6.4**  
FABRIC SHALL use game item metadata and identity APIs; it MUST NOT hard-code vanilla slot names or
category names. Its integration boundary MAY name only the documented vanilla controller classes
and methods required for the selected hooks; it MUST NOT directly annotate Equipment-EX, Virtual
Atelier, WEAVE, or other third-party scripted UI classes.

**Requirement 6.5**  
Equipment-EX and Codeware are hard runtime dependencies. `FabricOutfitReader` SHALL own the
conditional Equipment-EX API boundary and safely report an unavailable `OutfitSystem` to
`FabricService`, which leaves its index empty and presentation disabled with an actionable
diagnostic. After player attachment, FABRIC SHALL show one eight-second vanilla HUD notice that
identifies Equipment-EX and the required restart; detailed diagnostics remain in the game log.
Codeware owns FABRIC's registered `ScriptableService` lifecycle, which the native
post-player-attachment bridge uses for the initial rebuild. FABRIC diagnostics require the shared
game-level REDscript logging declarations, which are installed once outside the FABRIC package.
WEAVE is optional; FABRIC continues to work without it, and presents WEAVE-restored associations
after FABRIC's next supported reconciliation boundary. Mod Settings is an optional presentation
dependency; all direct references to its module, annotations, and API SHALL be enclosed by
`@if(ModuleExists("ModSettingsModule"))` so its absence retains the shipped marker style.

---

### 7 – Performance

**Requirement 7.1**  
Item-widget rendering SHALL be O(1) with respect to the number of saved outfits and total item count.

**Requirement 7.2**  
A full rebuild SHALL be O(total item references across all saved outfits).

**Requirement 7.3**  
Large inventories SHALL scroll without a measurable framerate impact.

---

### 8 – Reliability and Diagnostics

**Requirement 8.1**  
Cache failures and invalid item identities MUST NOT crash or block the wardrobe UI. Public item queries SHALL return `false`, `0`, or an empty array for invalid or unavailable data.

**Requirement 8.2**  
During an authoritative full rebuild, FABRIC SHALL validate that each rebuilt outfit is represented in both the exact-item and catalog-record indexes. If validation fails, FABRIC SHALL log a diagnostic and retry the rebuild once; it SHALL not poll or scan outfits during card rendering.

**Requirement 8.3**  
TRACE and DEBUG diagnostic logging SHALL be gated behind the generated build profile or an explicit session override. Release defaults them off; Debug defaults them on. INFO, WARN, and ERROR remain enabled in every build.

**Requirement 8.4**  
`FabricLog` SHALL emit each permitted diagnostic once through the engine `Log` family (`Log`, `LogWarning`, or `LogError`) with a stable `[FABRIC]` prefix. This route SHALL provide both CET Game Log visibility and the `gamelog.log` sink; error entries SHALL include Codeware `GetStackTrace` call-site context.

---

### 9 – Implementation Constraints

The following constraints are derived from the authoritative dependency and language reference material in steering.

**Requirement 9.1 – Wardrobe API**  
`EquipmentEx.OutfitSystem` is the sole outfit authority. Enumerate with `GetOutfits()`, retrieve with `GetOutfitParts(name)`, use persistent `CName` names and `NameToString(name)` for display, and process `array<ref<OutfitPart>>` values.

**Requirement 9.2 – Item identity**  
Equipment-EX `OutfitPart` stores `ItemID`. FABRIC uses complete `ItemID` identity for Wardrobe, Backpack, storage, and their standard tooltips. It resolves `ItemID.GetTDBID()` only for Virtual Atelier catalog cards and catalog tooltips, where an owned instance is unavailable.

**Requirement 9.3 – Events and hooks**  
Direct REDscript annotations cannot target the script-defined `EquipmentEx.OutfitSystem` in this runtime. FABRIC therefore requires an event-driven refresh boundary that does not directly wrap Equipment-EX methods; polling is excluded.

**Requirement 9.4 – UI integration points**  
FABRIC uses the vanilla `WardrobeUIGameController` lifecycle with `InventoryItemDisplayController.NewUpdateEquipped(UIInventoryItem)` for Equipment-EX Wardrobe cards, `NewRefreshUI(UIInventoryItem)` for player Inventory cards, and `RefreshUI()` with `InventoryItemData.GetGameItemData(this.m_itemData).GetID()` for data-backed store cards. A FABRIC-owned marker is created once after the original item-card initialization completes and is reset with its active style on each card refresh. FABRIC MUST NOT directly annotate an Equipment-EX or Virtual Atelier scripted UI class or method.

---

## Deliberate Non-Goals (Initial Release)

- Replacing WEAVE, Equipment-EX, or the base-game wardrobe manager.
- Guessing associations when the game does not provide a unique item reference.
- Hard-coding vanilla clothing slots, categories, or controllers.
- Coupling the relationship backend to any particular UI implementation.
- Used/Unused filtering and Wardrobe-usage sorting. These remain deferred product ideas and require explicit requirements, supported UI integration points, and validation before entering an implementation release.
