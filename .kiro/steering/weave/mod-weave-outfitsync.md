---
inclusion: manual
---

# WEAVE — OutfitSync Detail

Outfit synchronization system: serializes Equipment-EX outfits to JSON files and restores them across saves/characters.

**Module:** `EquipmentEx`
**Up:** [mod-weave.md](mod-weave.md) | [../cyberpunk-mods-index.md](cyberpunk-mods-index.md)

---

## OutfitSyncSystem

`OutfitSyncSystem extends ScriptableSystem` — orchestrates save/load of outfit data.
Requires `RedFileSystem` + `RedData.Json`; a no-op stub is compiled when either is absent.

```swift
static func GetInstance(game: GameInstance) -> ref<OutfitSyncSystem>

// Persist all current outfits to JSON (suppressed during load, and when both sync modes off)
func Save()

// Rename a saved outfit in OutfitSystem + JSON
func RenameOutfit(oldName: CName, newName: CName) -> Bool
```

Loading is triggered automatically on `OnPlayerAttach` when `WEAVEConfig.outfitSyncEnabled` or `outfitMergeEnabled` is true.

### Sync vs Merge modes

| Config field | Behavior |
|---|---|
| `outfitSyncEnabled` | JSON wins — overwrites any same-named outfit in save |
| `outfitMergeEnabled` | Save wins — JSON only adds outfits not already in save |
| Both false | Feature disabled, no file I/O |

---

## OutfitStorageService

`OutfitStorageService extends ScriptableService` — handles file I/O for outfit JSON files.

Not called directly; used internally by `OutfitSyncSystem`. Reads/writes from the mod's designated storage path.

---

## DTOs

These DTOs mirror the Equipment-EX `OutfitPart` and `OutfitSet` structures for JSON serialization.

```swift
// Single item within a saved outfit
class JsonOutfitItemDTO {
  let itemID: ItemID       // the equipped item
  let slotID: TweakDBID   // the slot it's assigned to
}

// A named outfit with all its parts
class JsonOutfitDTO {
  let name: String
  let parts: array<ref<JsonOutfitItemDTO>>
}

// Full outfit storage payload (all outfits for a character)
class JsonOutfitDataDTO {
  let outfits: array<ref<JsonOutfitDTO>>
}
```

---

## Runtime behavior notes

### Rename behavior

WEAVE's `RenameOutfit(oldName, newName)` is implemented as:

1. Read old parts through `OutfitSystem.GetOutfitParts(oldName)`.
2. `AddOutfit(newName, parts, false)`.
3. `DeleteOutfit(oldName)`.

Outfit names are mutable display labels and persistence keys, not immutable identifiers.

### Item-identity caveat for WEAVE sync

The installed WEAVE 1.0.0 source serializes each outfit item as `tweakID` plus `slotID`, then restores it with `ItemID.FromTDBID(tweakID)`. It does **not** serialize the full Equipment-EX `ItemID` instance value. Consequently, a WEAVE sync/load operation can reduce an outfit reference to record-level identity even though Equipment-EX itself persists a full `ItemID`.

`OutfitSyncSystem.OnPlayerAttach()` calls its private `LoadAndApply()` and does not publish a post-sync completion event. Consumers that need to observe completed JSON synchronization cannot subscribe to a dedicated completion event.

### WEAVE UI/performance boundary

WEAVE's smoother inventory/tag behavior comes from its own tag services and caches (`AutoTagDBCache`, `TagManagerSystem`, and `TagStorageService`), plus tag-specific events such as `UserTagsChanged` and `TagEditorCompleted`. These concern clothing metadata and filtering, not saved-outfit membership.

WEAVE does not add a base-game wrapper that reports successful OutfitSystem save/delete/copy mutations, and its `OutfitSyncSystem` does not publish an `Event` on completion. Tag-cache and tag-editor events describe metadata/filter changes, not saved-outfit membership changes.

The installed package is WEAVE 1.0.0, while the current Nexus description advertises later releases. Before shipping a version that claims support for newer WEAVE builds, re-check that build's JSON DTO and restore path; this limitation may have changed.

---

## Config Integration

Sync behavior is controlled by `WEAVEConfig` fields:

| Field | Effect |
|-------|--------|
| `outfitSyncEnabled` | Master switch — disabling stops all sync I/O |
| `outfitMergeEnabled` | When true, loaded outfits merge with existing; when false, replaces |

See [mod-weave.md § WEAVEConfig](mod-weave.md) for full config reference.
