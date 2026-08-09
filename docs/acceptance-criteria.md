# FABRIC acceptance criteria

This record evaluates the current Kiro requirements, design, and implemented behavior. It replaces the stale reference to a non-existent external “Section 11” checklist.

## Outcome

**Pass — release package built, deployed, and tested in game.** The only compatibility constraint
is documented: WEAVE JSON synchronization has no public completion event, so FABRIC cannot
immediately reconcile cache state after that external operation.

| Area | Acceptance criterion | Result | Evidence |
| --- | --- | --- | --- |
| Association identity | Owned Wardrobe and Backpack cards use complete `ItemID` identity; catalog cards use `TweakDBID` record identity. | Pass | In-game validation confirmed that only the saved owned instance is marked while the corresponding Virtual Atelier catalog item remains discoverable. |
| Cache correctness | Full rebuilds produce exact-item and record-level associations, reject invalid identities, validate each rebuilt outfit against both indexes, and retry once on inconsistency. | Pass | `FabricService` coordinates `FabricOutfitReader` and `FabricUsageIndex` through full rebuilds only; normal game testing completed successfully. |
| Lifecycle refresh | The cache performs a full rebuild after player attachment and after confirmed Wardrobe save or delete actions. | Pass | In-game testing confirmed accurate counts following save/delete confirmation and popup closure. |
| Wardrobe indicators | Associated Wardrobe cards show a marker and unused or unbound cards do not retain a prior marker. | Pass | Card refresh clears persistent virtualized-widget state before an absent item can be displayed. |
| Backpack and stash indicators | Associated owned inventory cards show a marker using exact item identity. | Pass | In-game Backpack and stash validation completed. |
| Virtual Atelier indicators | Catalog cards show a marker when their record is associated with a saved outfit. | Pass | In-game Virtual Atelier validation completed after record-level lookup was introduced. |
| Tooltip augmentation | Existing item tooltips retain their native content and include an `Outfits:` section for associated items; unsupported payloads hide any prior FABRIC section. | Pass | Wardrobe, inventory, and Virtual Atelier tooltip behavior validated in-game; reused tooltip state is reset safely. |
| Marker presentation | Marker icon, color, and corner are configurable through Mod Settings when available and fall back to shipped defaults otherwise. | Pass | In-game Mod Settings changes validated; guarded fallback path statically audited. |
| Required dependency handling | Missing Equipment-EX leaves FABRIC in a safe empty state and displays a one-time in-game explanation. | Pass | Guarded fallback and notification path statically audited against the Equipment-EX integration. |
| Optional dependency handling | Missing Mod Settings or WEAVE does not prevent FABRIC from loading. | Pass | All optional integration references are guarded; FABRIC has no runtime dependency on WEAVE implementation files. |
| WEAVE synchronization | A WEAVE JSON synchronization is reflected immediately. | Documented limitation | WEAVE exposes no public post-sync event. FABRIC reflects the change at the next supported rebuild boundary; see [WEAVE sync limitations](weave-sync-limitations.md). |
| Performance guardrails | Card rendering uses cached constant-time lookups and does not scan outfits, poll, or rebuild during rendering. | Pass | Structural audit of the card and tooltip paths completed; manual FPS profiling was intentionally excluded from the release scope. |
| Logging and diagnostics | Runtime diagnostics are routed through `FabricLog`, preserve useful error context, and apply the generated build flavor's verbosity default. | Pass | Debug defaults to TRACE through ERROR; Release defaults to INFO/WARN/ERROR. |
| Package verification | Debug and Release archives contain the required FABRIC service and generated build profile. | Pass | `tools\package.ps1` extracts each archive and verifies the organized service path and generated build profile. The release archive was deployed with its release profile confirmed. |
| Documentation and disclosure | Shipped and publication-facing materials document dependencies, known WEAVE limitations, licensing, development assistance, and the canonical source. | Pass | The shipped README, Nexus listing, and standalone Nexus description point to the canonical GitHub repository; implementation behavior is recorded in this acceptance document and the smoke-test checklist. |

## Release boundary

This acceptance pass covers behavior, compatibility, packaging, deployment, and the completed
in-game release test. A future release requires a new package, deployment, and smoke-test record
for the changed build.
