---
inclusion: always
---

# FABRIC Naming Conventions

Names are part of FABRIC's compatibility boundary. They must make ownership obvious, avoid collisions with the game and other mods, and preserve the exact names required by REDscript hooks.

## Namespace and files

- Declare FABRIC implementation code in the `FABRIC` module unless a REDscript integration requires another scope.
- Name every FABRIC-owned REDscript source file `Fabric<Responsibility>.reds`. Examples: `FabricService.reds`, `FabricConfig.reds`, and `FabricEventBridge.reds`.
- Generated FABRIC source files follow the same rule, for example `FabricBuildProfile.reds`.
- Use lowercase directory names for organizational-only folders, such as `util`; directory names do not replace the `Fabric` file-name prefix.
- Do not use generic filenames such as `Service.reds`, `Config.reds`, `Events.reds`, or `EventBridge.reds` for FABRIC-owned code.

## Types and APIs

- Prefix every FABRIC-owned class, enum, struct, event, callback, and public helper with `Fabric`. Examples: `FabricService`, `FabricLogLevel`, and `FabricItemUsage`.
- Use PascalCase for type names and function names.
- Use `Fabric` in public API names when the API can be referenced outside the `FABRIC` module or could be mistaken for a game/mod API.
- Do not prefix game, Equipment-EX, WEAVE, Codeware, or other dependency types. Import and use their authoritative names.
- A REDscript wrapper/replacement/addition must retain the target method's exact name and signature. The containing FABRIC bridge type and source file remain prefixed; the hook method itself is not renamed.

## Values and members

- Use lower camel case for parameters and local variables: `itemID`, `outfitName`, `startTime`.
- Use `m_` plus lower camel case for instance fields: `m_itemIndex`, `m_verboseLoggingOverride`.
- Use descriptive booleans that read as predicates: `isVerboseLoggingEnabled`, `hasOverride`, `shouldRebuild`.
- Prefer domain terms from the authoritative API: `itemID` for `ItemID`, `outfitName` for saved-outfit `CName`, and `outfitSystem` for `EquipmentEx.OutfitSystem`.
- Do not encode implementation sequence, task identifiers, or temporary status in names. Rename code when its responsibility changes.

## Build and package names

- Keep build profiles and output names explicitly flavor-qualified: `release` and `debug`.
- Use `FABRIC` as the user-visible mod/package identifier and `Fabric` as the REDscript type/file prefix. Examples: `FABRIC-<version>-release.zip` and `FabricBuildProfile`.
- Do not derive runtime identity from a local filesystem path or ZIP filename; expose it through the generated `FabricBuildProfile` API.

## Compatibility rule

Before adding a name, check whether it is FABRIC-owned, dependency-owned, or a hook contract. Prefix only FABRIC-owned symbols. Preserve dependency and hook-contract names exactly.
