# FABRIC – Implementation Tasks

> Tasks follow the phased order from the specification.  
> Phases 1 and 2 must be complete before any UI work begins.

---

## Phase 0 – Steering Files (Mod Reference Documentation)

Kiro steering files providing navigable reference documentation for all 7 mods used in FABRIC development. Files use `inclusion: manual` — load them into context via `#` when working on features that touch those mods.

**Location:** `.kiro/steering/`

### Index Files

- [x] **0.1 – Top-level mod index**  
  `cyberpunk-mods-index.md` — lists all 7 mods with one-line descriptions and links to per-mod files.

- [x] **0.2 – WEAVE namespace index**  
  `mod-weave.md` — modules: Config, AutoTag/DB, TagManager, OutfitSync, ItemAdder, Localization.

- [x] **0.3 – Equipment-EX namespace index**  
  `mod-equipment-ex.md` — modules: OutfitSystem, Global API, Helpers, UI controllers.

- [x] **0.4 – ArchiveXL namespace index**  
  `mod-archivexl.md` — modules: Core native API, DynamicAppearance functions.

- [x] **0.5 – Codeware namespace index**  
  `mod-codeware.md` — modules: Core native API + @addField extensions, Localization, UI, UI.TextInput.

- [x] **0.6 – redscript tool reference**  
  `mod-redscript.md` — compiler/runtime description, language feature quick reference.

- [x] **0.7 – TweakXL tool reference**  
  `mod-tweakxl.md` — TweakDB patcher description, YAML patch format, TweakDBInterface usage.

- [x] **0.8 – RED4ext tool reference**  
  `mod-red4ext.md` — native plugin loader description, relationship to redscript native bindings.

### Namespace Detail Files

- [x] **0.9 – WEAVE AutoTag & AutoTagDB detail**  
  `mod-weave-autotag.md` — `AutoTagEngine`, `AutoTagScorer`, `AutoTagDB`, `AutoTagDBCache`, DTOs.

- [x] **0.10 – WEAVE TagManager detail**  
  `mod-weave-tagmanager.md` — `TagManagerSystem`, `TagStorageService`, `TagEditorPopup`, DTOs.

- [x] **0.11 – WEAVE OutfitSync detail**  
  `mod-weave-outfitsync.md` — `OutfitSyncSystem`, `OutfitStorageService`, DTOs, config integration.

- [x] **0.12 – Equipment-EX OutfitSystem detail**  
  `mod-equipment-ex-outfitsystem.md` — `OutfitSystem`, `EquipmentEx` global API, data classes, usage patterns.

- [x] **0.13 – Codeware Localization detail**  
  `mod-codeware-localization.md` — `LocalizationSystem`, `ModLocalizationProvider`, `ModLocalizationPackage`, entry types.

- [x] **0.14 – Codeware UI detail**  
  `mod-codeware-ui.md` — popup framework, button types, `ButtonHintsManager`, `TextInput`, internal text controllers.

---

## Phase 1 – Reverse Engineering & Investigation

- [x] **1.1 – Wardrobe API investigation**  
  Equipment-EX `OutfitSystem` is FABRIC's sole outfit authority: enumerate via `GetOutfits()`, retrieve through `GetOutfitParts(name)`, use persistent `CName` outfit names with `NameToString(name)` for display, and process `array<ref<OutfitPart>>` containing `ItemID` and `slotID`. Vanilla `WardrobeSystem` is not indexed because Equipment-EX imports its non-empty sets.  
  *Reference: `.kiro/steering/equipment-ex/mod-equipment-ex-outfitsystem.md`*

- [x] **1.2 – Item identity investigation**  
  Equipment-EX `OutfitPart` stores complete `ItemID` values. FABRIC uses exact `ItemID` associations for Wardrobe and player Inventory, and resolves `ItemID.GetTDBID()` only for Virtual Atelier catalog presentation.  
  *Reference: `.kiro/steering/vanilla/game-inventory.md` and the item-identity requirements.*

- [x] **1.3 – Events and hooks investigation**  
  Persistent-outfit mutations do not emit a general lifecycle event. FABRIC uses an event-driven refresh boundary outside direct Equipment-EX method wrapping; polling is excluded. WEAVE rename is represented as an add followed by a delete.  
  *References: `.kiro/steering/equipment-ex/mod-equipment-ex-outfitsystem.md`, `.kiro/steering/weave/mod-weave-outfitsync.md`*

- [x] **1.4 – UI integration investigation**  
  FABRIC uses the vanilla `WardrobeUIGameController` lifecycle and `InventoryItemDisplayController` refresh path; it does not directly annotate Equipment-EX scripted UI classes.  
  *Reference: `.kiro/steering/equipment-ex/mod-equipment-ex.md`*

---

## Phase 1.5 – Development Toolchain & Release Pipeline

- [x] **1.5.1 – Define the reproducible developer commands**  
  Add repository-owned PowerShell entry points for `dev`, `verify`, `package`, and `smoke`. Document their inputs, outputs, required external tools, and exit-code behavior. Keep all local machine settings out of source control.  
  *Files: `tools/*.ps1`, `README.md`*

- [ ] **1.5.2 – Configure REDscript editor/type-check integration**  
  Project-level `.redscript` configuration and structural verification are in place. Wire compiler/LSP diagnostics into `verify` after the first compilable Phase 2 module exists; this requires a local REDscript IDE/compiler-capable setup.  
  *Files: `.redscript`, `tools/verify.ps1`*

- [x] **1.5.3 – Implement development install**
  Implement `dev` to install unbundled `.reds` sources into the configured game directory under FABRIC's runtime path. In Debug, create the root-level shared logging declarations only when absent; in Release, remove that exact declarations file for a clean no-logging-declarations test. Resolve the game path from a developer-local environment variable or ignored local config; never commit an absolute game path. Confirm the command refuses unsafe or missing targets.
  *Files: `tools/dev.ps1`, `.gitignore`*

- [x] **1.5.4 – Add optional watch and hot-reload support**  
  Integrate Red Hot Tools and/or `cp2077-red-cli` watch mode behind an explicit availability check. The base `dev` and `verify` commands must remain usable without either optional helper.  
  *Files: `tools/watch.ps1`, `README.md`*

- [x] **1.5.5 – Implement release staging and packaging**
  Validated with the backend source tree: `package -BuildFlavor Release` creates the publishable release ZIP, and `package -BuildFlavor Debug` creates the non-publishable debug ZIP. Each has a SHA-256 checksum, generated `FabricBuildProfile.reds`, and extraction validation that the archive contains only the expected game-root `r6` directory and scripts.
  *Files: `tools/package.ps1`, `release/manifest-template.json`*

- [x] **1.5.6 – Establish the WolvenKit asset workflow**  
  Document WolvenKit/WolvenKit CLI as a required package-asset capability. Add validation and packing hooks when FABRIC first gains archive, REDmod, or other packed assets; release packaging must include those generated assets at their game-relative paths.  
  *File: `README.md`*

- [x] **1.5.7 – Define automated and in-game verification**  
  The versioned in-game checklist and `smoke` command are in place. `verify` invokes `tests/quality.ps1` to enforce source-width, stale-planning-marker, and removed-incremental-API checks. Add behavior-level automated tests alongside the first pure helper logic that can run outside the game.  
  *Files: `tests/`, `docs/smoke-test.md`, `tools/smoke.ps1`*

- [ ] **1.5.8 – Toolchain acceptance check**  
  On a clean working copy, run `verify`, install in development mode, execute the smoke-test checklist, create a release ZIP, and validate its contents and checksum. Record the supported game, Equipment-EX, REDscript, and optional-tool versions.  

---

## Phase 2 – Backend Service

- [x] **2.1 – Project scaffold**  
  Created `src/`, `src/adapters/`, `src/util/`, `tests/`, `.redscript`, and `red.config.json`. `FabricBuildMarker.reds` is the dependency-free first REDscript module used to exercise Phase 1.5 tooling before production services are introduced.

- [x] **2.2 – FabricConfig**  
  Implement `FabricConfig` as a Codeware `ScriptableService`. Resolve TRACE/DEBUG from the generated build-profile default and allow an in-session override through `SetVerboseLoggingEnabled(enabled)`. Release defaults verbose logging off; debug defaults it on.  
  *File: `src/FABRIC/core/FabricConfig.reds`*

- [x] **2.3 – FabricLog helper**
  Implement `FabricLog` as the sole FABRIC logging wrapper. Release builds use a no-op generated backend with no native logging references. Debug builds use an `FTLog` backend; gate TRACE/DEBUG through `FabricConfig`, retain INFO/WARN/ERROR, and include Codeware `GetStackTrace` call-site context for errors. All other FABRIC modules use this wrapper, never raw log calls.
  *File: `src/FABRIC/diagnostics/FabricLog.reds`*

- [x] **2.4 – FabricService skeleton**  
  Declare the Codeware service with collision-safe complete-`ItemID` and `TweakDBID` association indexes. Implement public query safe defaults and confirm compilation.  
  *Files: `src/FABRIC/core/FabricService.reds`, `src/FABRIC/core/FabricUsageIndex.reds`*

- [x] **2.5 – FabricService full rebuild**  
  Implement `RebuildFull()`: enumerate every saved outfit, read its item references, build exact `itemIndex` and catalog `recordIndex` from scratch, validate each rebuilt outfit against both indexes, and log rebuild duration via `FabricLog`.

- [x] **2.6 – Remove unsupported incremental updates**  
  Remove the unused snapshot and incremental mutation API. The selected production refresh boundary provides no reliable per-outfit payload, so the service deliberately uses `RebuildFull()` only.

- [x] **2.7 – EventBridge**  
  Initial rebuilding runs from `PlayerPuppet.OnGameAttached` after the original callback. Confirmed Equipment-EX Save Outfit and Delete Outfit dialogs are handled by a filtered `GenericMessageNotification.Close(result)` wrapper: call the original once, then run `RebuildFull()` only when the result is `Confirm` and the localized title/message pair matches the Equipment-EX Save/Delete keys. Polling and direct `OutfitSystem` annotation hooks are prohibited.
  *File: `src/FABRIC/integration/FabricEventBridge.reds`*

- [x] **2.8 – Backend validation**  
  Manual in-game test:  
  - Create two outfits each referencing different items.  
  - Confirm `GetUsageCount` returns correct values.  
  - Edit one outfit (add and remove items); confirm counts update after the selected supported refresh boundary, with a diagnostic log entry.  
  - Delete an outfit; confirm counts drop to zero after the selected supported refresh boundary.  
  - Rename through WEAVE; confirm the next supported reconciliation reflects the new `CName`.  
  - Save and reload the game; confirm `RebuildFull` restores correct counts.

---

## Phase 3 – Usage Markers

- [x] **3.1 – Vanilla item-card refresh boundary**  
  FABRIC scopes the vanilla `InventoryItemDisplayController.NewUpdateEquipped(UIInventoryItem)` wrapper to the `WardrobeUIGameController` lifecycle. After a confirmed Save/Delete rebuild, `FabricUsageIndexUpdated` is queued through `UISystem` to refresh visible cards. A saved-outfit mutation refreshes the visible-card path.  
  *Files: `src/FABRIC/integration/FabricEventBridge.reds`, `src/FABRIC/ui/FabricUsageMarkerPresenter.reds`*

- [x] **3.2 – Marker icon**  
  Create FABRIC's upper-left marker once after the original `InventoryItemDisplayController.OnInitialize` completes. The shipped default uses the vanilla loop-bordered atlas's `clothing` part and green tint in a 21 × 21 px box with 12 px left and top insets. After `wrappedMethod` in each supported item-card refresh boundary, query the exact `ItemID` index for Wardrobe and player Inventory cards or the record index for Virtual Atelier catalog cards, then reset marker visibility for every virtualized-card binding. Do not reuse another mod's marker widget or scan outfits during card rendering.

- [x] **3.3 – Marker count badge**  
  Add a FABRIC-owned Raj Semi-Bold numeric count badge adjacent to the upper-left marker, with 36 px left and 8 px top insets. The shipped default uses the marker's green tint. Populate it from `FabricService.GetUsageCount(itemID)` and hide both elements when the result is zero. Preserve the one-time marker initialization and per-refresh reset behavior.

- [x] **3.4 – Marker accuracy validation**  
  Items used by 0, 1, 2, and 3+ outfits display the correct icon/count on initial wardrobe display, after virtual-card recycling through scrolling/category/source changes, and after Save/Delete `FabricUsageIndexUpdated` refresh. Unassociated items show no marker.

---

- [x] **3.5 – Player Inventory marker scope**  
  FABRIC uses the player Inventory's `InventoryItemDisplayController.NewRefreshUI(UIInventoryItem)` binding, while retaining the Wardrobe-gated `NewUpdateEquipped(UIInventoryItem)` path. It does not rely on `gameuiInventoryGameController` lifetime because it can uninitialize while Backpack remains active. Backpack and storage item cards display the validated marker/count behavior.

- [x] **3.6 – Virtual Atelier marker validation**  
  FABRIC uses the vanilla `InventoryItemDisplayController.RefreshUI()` data-backed card boundary and `InventoryItemData.GetGameItemData(this.m_itemData).GetID()` identity path. It does not annotate a Virtual Atelier scripted class. Catalog markers/counts and tooltips use the record-keyed association index, while owned Wardrobe and Inventory paths use the exact `ItemID` index.

- [x] **3.7 – Optional marker-style settings**  
  `FabricMarkerStyle` provides the shipped upper-left `clothing`/green default. Under `@if(ModuleExists("ModSettingsModule"))`, `FabricModSettings` exposes curated `FabricMarkerIcon`, `FabricMarkerColor`, and `FabricMarkerCorner` enum choices. Each supported item-card refresh reads the committed active style directly and applies it to the icon and count.  
  *Files: `src/FABRIC/settings/FabricMarkerStyle.reds`, `src/FABRIC/settings/FabricMarkerSettings.reds`, `src/FABRIC/ui/FabricUsageMarkerPresenter.reds`*

- [x] **3.8 – OO responsibility split**  
  Keep required REDscript hook signatures in `FabricEventBridge`, but delegate card Ink behavior to
  `FabricUsageMarkerPresenter`. `FabricWardrobeMutation` owns popup classification and rebuild
  coordination. `FabricService` is a façade over `FabricOutfitReader`, `FabricUsageIndex`, and
  `FabricWardrobeSession`; the reader owns conditional Equipment-EX reads, the index owns
  collision-safe associations, and the session owns only wardrobe presentation scope.
  `FabricMarkerSettings` owns optional Mod Settings resolution, `FabricMarkerStyle` owns mapping,
  and `FabricLog` is isolated in diagnostics. The inactive base-filter diagnostic path is removed.

---

## Phase 4 – Tooltip

- [x] **4.1 – Item-tooltip augmentation**  
  Extend the vanilla standard and store item-tooltip controllers with a FABRIC-owned "Outfits:" section. On each tooltip item update, call `FabricService.GetAssociatedOutfitNames(itemID)`, sort alphabetically, and update or hide the section without reading Equipment-EX UI controller state directly.

- [x] **4.2 – Tooltip accuracy validation**  
  Tooltip output reflects the current cache after a supported reconciliation, including a compatible WEAVE rename. Multiple outfit names are alphabetically ordered.

---

## Deferred product scope

- [ ] **D1 – Used and Unused filters**  
  The original product idea included filtering from FABRIC's association index. It is not part of the current release because no supported filter integration point or acceptance plan has been selected.

- [ ] **D2 – Wardrobe-usage sorting**  
  The original product idea included sorting by association count. It is not part of the current release because no supported sort integration point or acceptance plan has been selected.

---

## Phase 7 – Compatibility Validation

- [x] **7.1 – Equipment-EX dependency validation**  
  Validated FABRIC's `OutfitSystem.GetInstance()`, `GetOutfits()`, `GetOutfitParts(CName)`, and
  `OutfitPart.GetItemID()` contract against the installed Equipment-EX source. The conditionally
  compiled `FabricOutfitReader` owns this API boundary; without the module, it reports unavailable
  data and `FabricService` resets its cache, emits an actionable installation warning in debug builds, and leaves
  outfit-backed presentation disabled without a vanilla fallback. An unavailable `OutfitSystem`
  follows the same safe empty-cache path. After player attachment, FABRIC shows one eight-second
  vanilla HUD notice with the dependency and restart action. FABRIC neither declares nor packages
  the debug-only shared game-level REDscript logging declarations in its packages; the Debug
  development installer creates the root-level file only when absent, while the Release installer
  removes it for a clean test.

- [x] **7.2 – WEAVE sync compatibility**  
  The installed WEAVE sync implementation has no public post-sync boundary: `OutfitSyncSystem.OnPlayerAttach()` invokes private restore logic without a completion event, callback, or blackboard signal. FABRIC does not directly annotate WEAVE's scripted class and does not claim immediate reconciliation after JSON sync. Record-keyed presentation remains compatible after FABRIC's next supported reconciliation; the limitation and requested WEAVE extension are documented in `docs/weave-sync-limitations.md`.

- [x] **7.3 – Extended-slot compatibility**  
  Validated the Equipment-EX Balaclava extended-slot path during Wardrobe marker work, and validated marker and tooltip presentation across Wardrobe, player inventory, and Virtual Atelier. FABRIC's association path uses `OutfitPart.ItemID` without reading or branching on `slotID`; Virtual Atelier catalog presentation additionally resolves the item record.

- [x] **7.4 – Compatibility regression validation**  
  The supported Equipment-EX workflow is validated across Wardrobe, player Inventory, and Virtual Atelier: initial rebuild, Save/Delete reconciliation, marker/count reset, and tooltip associations. The missing/unavailable Equipment-EX fallback leaves presentation disabled with an actionable game-log and one-time HUD diagnostic. WEAVE rename remains compatible after a supported reconciliation; automatic JSON sync is explicitly limited by WEAVE's absent post-sync notification.

- [x] **7.5 – Optional Mod Settings validation**  
  Static optional-dependency audit confirms that every Mod Settings symbol is contained in the `@if(ModuleExists("ModSettingsModule"))` branch and the complementary branch returns the shipped `clothing`/green/upper-left defaults using only core REDscript types. With Mod Settings installed, marker icon, color, and corner selections were validated in game.

---

## Phase 8 – Polish, Hardening & Release Prep

- [x] **8.1 – Duplicate instance behavior documentation**  
  `docs/duplicate-handling.md` explains exact owned-item marker/count and tooltip behavior, record-level Virtual Atelier catalog behavior, the distinct-outfit count rule, and duplicate-instance presentation.

- [x] **8.1a – Exact owned-item presentation**  
  FABRIC maintains both a complete-`ItemID` association index and a `TweakDBID` catalog index. Wardrobe, Backpack, storage, and their standard tooltips use the exact index; Virtual Atelier cards and catalog tooltips use the record index. Duplicate-instance validation confirmed that only the saved owned instance is marked while the matching Virtual Atelier catalog item remains marked.

- [x] **8.2 – Error and edge-case hardening**  
  Public `FabricService` item queries guard invalid identities and unavailable caches with safe defaults. Each authoritative rebuild validates exact-item and catalog-record indexes for every rebuilt outfit, logs and retries once on an inconsistency, and never polls or scans outfits during card rendering. Normal full-restart validation passed.

- [x] **8.3 – Performance guardrails**  
  FABRIC keeps per-card marker and tooltip reads O(1), performs no outfit scans during rendering, and rebuilds only at supported event boundaries. A separate manual FPS benchmark is not required for the initial release.

- [x] **8.4 – Acceptance criteria pass**  
  The current Kiro requirements have a recorded acceptance pass in `docs/acceptance-criteria.md`. The only constraint is the documented WEAVE JSON-sync limitation; no release-blocking failure remains.

- [x] **8.5 – Release packaging**  
  `package -BuildFlavor Release` creates a game-root-relative FABRIC runtime archive containing only `r6` and its checksum. Packaging extracts the archive and verifies the top-level layout, service, generated build profile, and selected logging backend; it rejects a release archive containing a native logging call. The generated release profile sets verbose logging to `false` by default. The current publishable artifact is `build/release/FABRIC-0.1.2-release.zip` (SHA-256 `9e485665d90c1089198f515830b6a3051d9f5dc5ccba6f9be6e4d410b6d72582`).

---

- [x] **8.6 â€“ Source-contract hygiene**  
  Every FABRIC class and function has an immediate docstring. Every function contract documents
  purpose, parameters, return behavior, and errors or safe defaults; `tests/quality.ps1` enforces
  `@param`, `@return`, and `@errors` fields, 120-character source lines, and removed-path checks.

## Dependency Order (Summary)

```
Phase 1 (investigation)
  → Phase 1.5 (toolchain)
    → Phase 2 (backend)
    → Phase 3 (markers)
      → Phase 4 (tooltip)
    → Phase 7 (compatibility validation)  [after marker and tooltip work]
      → Phase 8 (polish)
```

Phase 2 starts only after Phase 1.5 establishes the repeatable development, verification, packaging, and smoke-test workflow. Phase 7 validates the completed marker and tooltip work.
