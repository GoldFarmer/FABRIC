---
inclusion: manual
---

# ArchiveXL — Namespace Index

ArchiveXL is a RED4ext plugin that extends the game's asset loading pipeline. From redscript it exposes a native abstract class for body type queries, garment offset control, and dynamic appearance name conversions.

**Source:** `red4ext\plugins\ArchiveXL\Scripts\`
**Module:** `ArchiveXL`
**Index:** [cyberpunk-mods-index.md](../cyberpunk-mods-index.md)

## Namespaces / Modules

| Module | Key Class | Purpose |
|--------|-----------|---------|
| `ArchiveXL` (core) | `ArchiveXL abstract native` | Body type, garment offsets, version check |
| `ArchiveXL.DynamicAppearance` | (free functions) | Appearance name overrides and conversions |

## ArchiveXL (Core)

`ArchiveXL abstract native` — all members are static.

```swift
// Version guard — call at mod init; returns false if installed version is older than required
static func Require(version: String) -> Bool
static func Version() -> String

// Body type of a puppet (player or NPC)
static func GetBodyType(puppet: ref<GameObject>) -> CName

// Garment offset system (affects layering of clothing meshes)
static func EnableGarmentOffsets() -> Void
static func DisableGarmentOffsets() -> Void
```

## Runtime integration model

ArchiveXL's behavior-changing integration is native, in its RED4ext plugin, rather than a redscript decorator in the installed `Scripts` folder. At game startup the plugin participates in asset loading and registers ArchiveXL's asset metadata and appearance behavior with the engine. The redscript declarations in this folder are bindings into that native work: `Require`/`Version` guard a caller against an unavailable plugin version, `GetBodyType` exposes the body classification resolved by the plugin, and the garment-offset calls enable or disable the plugin-managed clothing layering adjustment. The observable effect is that ArchiveXL-authored assets and dynamic appearances are recognized by the engine; these bindings do not independently patch a gameplay controller.

## ArchiveXL.DynamicAppearance

Free functions in module `ArchiveXL.DynamicAppearance`. Used to override or convert dynamic appearance condition attributes and switch between camera perspectives.

```swift
// Override a single dynamic appearance condition attribute for an appearance name
func OverrideDynamicAppearanceCondition(app: CName, attr: CName, value: CName) -> Void

// Convert an appearance name to/from first-person or third-person variants
func ConvertAppearanceNameToTPP(app: CName) -> CName
func ConvertAppearanceNameToFPP(app: CName) -> CName

// Convert sleeve length variants
func ConvertAppearanceNameToPartialSleeves(app: CName) -> CName
func ConvertAppearanceNameToFullSleeves(app: CName) -> CName
```

The dynamic-appearance helpers operate on the appearance identifiers consumed by ArchiveXL's native appearance pipeline. Override calls change the named condition attribute used for a dynamic appearance; conversion calls choose a corresponding first/third-person or sleeve variant. They do not equip an item or change a puppet by themselves—the next engine appearance resolution consumes the changed or converted name.
