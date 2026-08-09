# WEAVE outfit-sync limitation

WEAVE is optional. FABRIC's Virtual Atelier catalog index remains compatible with the item references restored by WEAVE's JSON outfit sync once FABRIC performs a supported reconciliation.

The installed WEAVE implementation runs JSON restore from `OutfitSyncSystem.OnPlayerAttach()` and does not publish a public completion event, callback, or blackboard signal. FABRIC cannot directly wrap WEAVE's scripted class in this REDscript runtime. Therefore, FABRIC does not guarantee that its initial post-player-attachment rebuild runs after WEAVE's restore operation.

Normal Equipment-EX Save and Delete dialogs remain supported FABRIC reconciliation boundaries. They do not cover WEAVE's automatic JSON restore because that path bypasses those dialogs.

## Request for WEAVE

**Title:** Publish a post-outfit-sync completion notification

Could WEAVE expose a documented notification after `OutfitSyncSystem` finishes applying JSON outfit sync or merge changes?

The notification should be emitted after all Equipment-EX outfit additions, replacements, and deletions are complete, and should identify whether sync changed outfit data. A public, base-game-compatible event or blackboard signal would let dependent UI mods reconcile their own cached outfit-derived data without polling or wrapping WEAVE's scripted classes.

Suggested payload:

- completion status (`succeeded` / `failed`);
- mode (`sync`, `merge`, or no-op);
- whether any outfit data changed.

This would allow integrations to refresh exactly once after authoritative outfit state is settled, without coupling to WEAVE internals.
