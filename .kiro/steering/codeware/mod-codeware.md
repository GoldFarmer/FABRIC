---
inclusion: manual
---

# Codeware — Namespace Index

Codeware is a RED4ext plugin and redscript framework that provides native field extensions to game classes, a localization system, and a library of custom UI widgets (popups, buttons, text inputs).

**Source:** `red4ext\plugins\Codeware\Scripts\`
**Module:** `Codeware`
**Index:** [cyberpunk-mods-index.md](../cyberpunk-mods-index.md)

## Namespaces / Modules

| Module | Key Classes | Detail File |
|--------|-------------|-------------|
| `Codeware` (core) | `Codeware abstract native` — version check; `@addField` extensions | (see below) |
| `Codeware.Localization` | `LocalizationSystem`, `ModLocalizationProvider`, `ModLocalizationPackage` | [mod-codeware-localization.md](mod-codeware-localization.md) |
| `Codeware.UI` | `inkCustomController`, `CustomPopup`, `InMenuPopup`, `InGamePopup`, `ButtonHintsManager`, `TextInput`, custom buttons | [mod-codeware-ui.md](mod-codeware-ui.md) |
| `Codeware.UI.TextInput` | `Caret`, `Selection`, `TextFlow`, `TextMeasurer`, `Viewport` | [mod-codeware-ui.md](mod-codeware-ui.md) |

## Codeware Core

`Codeware abstract native` — all members are static.

```swift
static func Require(version: String) -> Bool   // version guard
static func Version() -> String
```

### Native Field Extensions (@addField)

`Codeware.Global.reds` injects native fields into many game classes. Key additions:

| Game Class | Added Fields (examples) |
|------------|------------------------|
| `PlayerPuppet` | Extended state fields for outfit/equipment tracking |
| `inkWidget` | Additional layout/state fields |
| `gameObject` | Extra scripting hooks |

> These are `native` fields — implemented in the C++ plugin. Access them as regular fields on the patched classes; no special API call needed.

## Runtime integration model

Codeware's large extension surface is infrastructure, not a collection of feature-specific gameplay overrides. Its installed script bindings declare native fields and methods across engine, UI, Ink, journal, AI, and data types; the RED4ext plugin supplies their storage and implementation. These declarations let Codeware widgets, localization, and dependent mods retain state or call helpers on game objects without each dependent shipping its own native bridge.

Consequently, a target type in `Codeware.Global.reds` identifies an available native binding, not necessarily a Codeware behavior that runs whenever that game type is used. The behavior-changing flows are the framework services themselves: provider discovery registers localization packages at startup, custom Ink controllers manage their own widget lifecycle, and popup/input helpers create and dispose their own UI state. See the localization and UI detail files for those trigger-to-effect flows.
