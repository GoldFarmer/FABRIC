---
inclusion: manual
---

# Native Settings UI — Reference

Native Settings UI 1.96 is a Cyber Engine Tweaks (CET) Lua mod that lets CET mods add controls to Cyberpunk 2077's native settings interface. It maintains a Lua registry of tabs, optional subcategories, and option records; when its settings page is open it spawns matching Ink widgets and forwards player changes to callbacks supplied by the consuming Lua mod.

**Package source:** `bin\x64\plugins\cyber_engine_tweaks\mods\nativeSettings\`

**Runtime:** CET Lua (`init.lua` returns the `nativeSettings` API table)

**Bundled helpers:** `Cron.lua` for timers, `EventProxy.lua` for Ink/CET event dispatch, `Ref.lua` for weak/strong reference helpers, and `UIButton.lua` for a custom Ink button.

**Index:** [cyberpunk-mods-index.md](../cyberpunk-mods-index.md)

## Registration API

Paths are slash-prefixed identifiers. A tab uses `/tab`; a subcategory uses `/tab/subcategory`; options are added at either level. `addTab(path, label, optionalClosedCallback)` creates the tab, while `addSubcategory(path, label, optionalIndex)` adds its dark-strip section. `pathExists(path)` tests that the target exists before registration.

| Control | Registration function | Callback value |
|---|---|---|
| Toggle | `addSwitch(path, label, desc, currentState, defaultState, callback, optionalIndex)` | Boolean |
| Integer slider | `addRangeInt(path, label, desc, min, max, step, currentValue, defaultValue, callback, optionalIndex)` | Number |
| Float slider | `addRangeFloat(path, label, desc, min, max, step, format, currentValue, defaultValue, callback, optionalIndex)` | Number |
| String selector | `addSelectorString(path, label, desc, elements, selectedElementIndex, defaultSelectedElementIndex, callback, optionalIndex)` | Selected 1-based index |
| Button | `addButton(path, label, desc, buttonText, textSize, callback, optionalIndex)` | Button action |
| Key binding | `addKeyBinding(path, label, desc, value, defaultValue, isHold, callback, optionalIndex)` | Input-name string |
| Custom widget | `addCustom(path, callback, optionalIndex)` | Callback owns widget setup |

Each `add*` function returns the option record it registered. The optional index chooses insertion order. When its tab is already visible, the framework spawns the new option immediately and preserves scroll position.

## Option lifecycle

`setOption(optionRecord, value)` programmatically updates a registered option, runs its callback, and updates an existing control. It validates expected Lua types: booleans for switches, numbers for numeric ranges and selector indices, and strings for key bindings. It clamps string-selector display indices to the available elements.

`removeOption(optionRecord)` removes an option; `removeSubcategory(path)` removes a whole subcategory. `registerRestoreDefaultsCallback(tabPath, overrideNativeRestoreDefaults, callback)` registers tab-level Restore Defaults behavior. Unless overridden, Native Settings invokes the callback and then restores each registered control's default value.

`refresh()` rebuilds visible settings data, although the source notes it is no longer needed after version 1.4. `getAllOptions()` exposes registered records; `getOptionTable(optionController)` maps a spawned controller back to one of them.

## UI integration flow

Native Settings stores tabs and controls under `nativeSettings.data`. Its settings controller integration populates the tab/category list, then `populateOptions` dispatches each option record to `spawnSwitch`, `spawnRangeInt`, `spawnRangeFloat`, `spawnStringList`, `spawnButton`, or `spawnKeyBinding`. Spawned controllers retain the record and invoke its callback when the player confirms a new value.

The framework paginates tabs when the category list exceeds visible space. `switchToNextPage` and `switchToPreviousPage` wrap between pages, preserve selection, and rebuild the native category list. It preserves scroll position while dynamically inserting/removing visible controls and calls a tab's optional closed callback when that tab closes.

## Supporting helpers

`Cron` provides `After`, `Every`, `NextTick`, `Halt`, `Pause`, `Resume`, and `Update` for deferred/repeating CET-side work. `EventProxy` maps Ink/CET events to callback registration and cleanup; its public functions include `RegisterCallback`, `RegisterPointerCallback`, `RegisterCustomCallback`, and `UnregisterAllCallbacks`. `UIButton` creates a styled Ink button with root/label access, callbacks, reparenting, and destruction.

This package is a Lua/CET settings UI API. It does not expose a redscript `ModSettings` class, discover runtime-property annotations, or persist a consuming mod's values by itself; the consuming CET mod owns storage and supplies the callbacks that apply changes.
