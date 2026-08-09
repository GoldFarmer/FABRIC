---
inclusion: manual
---

# WEAVE — TagManager Detail

Tag management system: persists user-defined and custom tags per item, merges with auto-tags, and provides a popup editor UI.

**Module:** `EquipmentEx`
**Up:** [mod-weave.md](mod-weave.md) | [../cyberpunk-mods-index.md](cyberpunk-mods-index.md)

---

## TagManagerSystem

`TagManagerSystem extends ScriptableSystem` — primary API for all tag read/write operations.

```swift
// Load tag data from storage (call before first use)
func EnsureLoaded() -> Void

// User tag management (per-item, persisted)
func AddTag(recordID: TweakDBID, tag: CName) -> Void
func RemoveTag(recordID: TweakDBID, tag: CName) -> Void
func SetTags(recordID: TweakDBID, tags: array<CName>) -> Void
func GetUserTags(recordID: TweakDBID) -> array<CName>
func IsUserTag(recordID: TweakDBID, tag: CName) -> Bool

// Aggregate tag queries (user + auto + native merged)
func GetAllTags(recordID: TweakDBID) -> array<CName>
func GetNativeTags(recordID: TweakDBID) -> array<CName>
func GetRemovedTags(recordID: TweakDBID) -> array<CName>

// Override user tags in bulk (replaces existing)
func SetTagOverrides(recordID: TweakDBID, tags: array<CName>) -> Void
func ResetTags(recordID: TweakDBID) -> Void

// Custom tag definitions (global, not per-item)
func GetCustomTags() -> array<CName>
func AddCustomTag(tag: CName) -> Void
func RemoveCustomTag(tag: CName) -> Void
func IsCustomTag(tag: CName) -> Bool

// External custom tags (registered by other mods)
func GetExtCustomTags() -> array<CName>
func RemoveExtCustomTag(tag: CName) -> Void
func GetAllCustomTags() -> array<CName>

// Auto-tag integration (delegates to AutoTagEngine)
func GetAutoTagEntry(recordID: TweakDBID) -> ref<AutoTagEntry>
func IsAutoTag(recordID: TweakDBID, tag: CName) -> Bool

// Canonical tag check
func IsCanonicalTag(tag: CName) -> Bool
```

---

## TagStorageService

`TagStorageService extends ScriptableService` — handles JSON serialization of tag data to/from the save game.

Not called directly; `TagManagerSystem` uses it internally via `EnsureLoaded()` and on write operations.

---

## TagEditorPopup

`TagEditorPopup extends InMenuPopup` — in-menu popup for editing tags on a single item. Uses `Codeware.UI.InMenuPopup` as base.

Opened by the wardrobe UI when the user selects "Edit Tags" on an item. Communicates results back to `TagManagerSystem`.

---

## DTOs

```swift
// Single item's tag payload (used for storage I/O)
class TagItemDTO {
  let recordID: TweakDBID
  let userTags: array<CName>
  let removedTags: array<CName>
}

// Full tag storage payload
class TagDataDTO {
  let items: array<ref<TagItemDTO>>
}

// Single custom tag definition
class CustomTagItemDTO {
  let tag: CName
}

// Full custom tag storage payload
class CustomTagDataDTO {
  let tags: array<ref<CustomTagItemDTO>>
}
```
