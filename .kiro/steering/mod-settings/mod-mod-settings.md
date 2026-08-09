---
inclusion: manual
---

# Mod Settings — Reference

Mod Settings 0.2.21 is a RED4ext plugin with redscript bindings and an Ink settings screen. It discovers redscript fields annotated as runtime properties, groups them into mod categories, exposes typed configuration variables, and lets the player edit, apply, reject, or restore values from a **Mod Settings** entry in the game's settings menus.

**Package source:** `red4ext\plugins\mod_settings\`

**Runtime pieces:** `mod_settings.dll`, `packed.reds`, `ModSettings.archive`, and `ModSettings.archive.xl`

**Module:** `ModSettingsModule` (`GetVersionString()` returns `v0.2.21`)

**Requirements declared by the package:** RED4ext and redscript; cybercmd is additionally required when deployed through REDmod.

**Index:** [cyberpunk-mods-index.md](../cyberpunk-mods-index.md)

## Configuration model

A mod declares a field in a redscript class and annotates it with `@runtimeProperty`. `ModSettings.mod` supplies the displayed mod name; further metadata controls display labels and enum labels. The native runtime discovers these declarations and presents them by mod/category in the settings UI.

```swift
class ExampleSettings {
  @runtimeProperty("ModSettings.mod", "Example Mod")
  @runtimeProperty("ModSettings.displayName", "UI-Example-Enabled")
  public let enabled: Bool = true;
}
```

For an enum, `ModSettings.displayValues.<EnumMember>` supplies either a localization key or literal display text. Members without a display-value annotation fall back to their enum-member name. The bundled readme says variable and class names are limited to 1024 characters.

Key bindings use an Input Loader mapping whose button has `overridableUI="<field name>"`; the matching annotated `EInputKey` field becomes editable. The consuming mod still registers and handles the corresponding game input action itself.

## Native redscript API

`ModSettings` is a native `IScriptable` class supplied by the DLL.

| Purpose | API |
|---|---|
| Discover entries | `GetInstance()`, `GetMods()`, `GetCategories(mod)`, `GetVars(mod, category)` |
| Commit lifecycle | `AcceptChanges()`, `RejectChanges()`, `RestoreDefaults(mod)` |
| Keep class fields in sync | `RegisterListenerToClass(self)`, `UnregisterListenerToClass(self)` |
| Receive lifecycle callbacks | `RegisterListenerToModifications(self)`, `UnregisterListenerToModifications(self)` |
| Runtime state | `changesRequested`, `isActive` |

The modification-listener callbacks must use these names and signatures:

```swift
public cb func OnModVariableChangeRequested(groupPath: CName, varName: CName) -> Void { }
public cb func OnModVariableChangeAccepted(groupPath: CName, varName: CName) -> Void { }
public cb func OnModSettingsChange() -> Void { }
```

`groupPath` is `/mods/[ModName]/[ModClass]`; `varName` is the annotated field name. `RegisterListenerToClass` is available when an integration needs the native runtime to synchronize fields on a live script object.

For a rendering path that requires the current committed value, query `ModSettings.GetVars(mod, category)`, identify the corresponding `ConfigVar` by name, cast it to the appropriate typed subclass, and read its value directly. This avoids coupling rendering to listener synchronization timing.

## Optional integration

REDscript can exclude a Mod Settings integration at compile time with `@if(ModuleExists("ModSettingsModule"))`. Put every direct Mod Settings import, `@runtimeProperty` declaration, native API call, and listener callback inside that conditional region. The unguarded feature code must provide its own defaults and must not reference Mod Settings types, so it remains compilable and functional when the plugin is absent.

## Typed variables

`GetVars` returns `array<ref<ConfigVar>>`; entries can be cast to these subclasses.

| Type | Value operations | Extra metadata/behavior |
|---|---|---|
| `ModConfigVarBool` | `GetValue`, `SetValue`, `GetDefaultValue` | `Toggle()` |
| `ModConfigVarName` | `GetValue`, `SetValue`, `GetDefaultValue` | `CName` value |
| `ModConfigVarKeyBinding` | `GetValue`, `SetValue`, `GetDefaultValue` | `EInputKey`; name conversion helpers |
| `ModConfigVarFloat` | `GetValue`, `SetValue`, `GetDefaultValue` | min, max, and step getters |
| `ModConfigVarInt32` | `GetValue`, `SetValue`, `GetDefaultValue` | min, max, and step getters |
| `ModConfigVarEnum` | current/default value and index access | values, indices, and `GetDisplayValue(index)` |

## UI and game hooks

The bundled redscript replaces the pause, death, and single-player menu item lists to insert a localized **Mod Settings** action. Its added scenario handlers enter `MenuScenario_ModSettings`, which opens the `mod_settings_main` Ink menu and returns to the previous scenario when closed.

`ModStngsMainGameController` is the main Ink controller. On initialization it marks `ModSettings.GetInstance().isActive`, builds the mod/category list, creates settings selectors, binds Apply/Reset/Defaults input, and registers itself for modification callbacks. Its selector controllers render booleans, integer and float sliders, enums/lists, and key bindings using the typed config-variable API. Apply commits requested changes, Reset rejects them, and Defaults restores a selected mod's defaults.

The package also wraps `SettingsCategoryController`, `SettingsSelectorController`, and key-binding selector events. These adapt vanilla settings widgets to the mod's own labels, descriptions, and editable runtime values; they do not make every normal settings screen a Mod Settings screen.
