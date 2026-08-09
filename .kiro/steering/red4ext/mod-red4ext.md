---
inclusion: manual
---

# RED4ext — Tool Reference

RED4ext is a native plugin loader for Cyberpunk 2077. It loads `.dll` plugins from `red4ext\plugins\` and bridges them to the game's engine. It is an infrastructure component — there are no `.reds` source files and no redscript API.

**Index:** [cyberpunk-mods-index.md](../cyberpunk-mods-index.md)

## What It Is

- Injects into the game process via `bin\x64\winmm.dll` (proxy DLL)
- Scans `red4ext\plugins\` for `.dll` files and loads them at startup
- Provides C++ SDK for plugin authors to hook engine functions and expose native types to redscript
- Required by: ArchiveXL, Codeware, TweakXL (all ship as RED4ext plugins)

## Runtime integration model

The `winmm.dll` proxy is loaded as part of the game's normal process startup. RED4ext uses that foothold to initialize its runtime, load each compatible plugin DLL, and give those plugins engine/RTTI registration and function-hook facilities. RED4ext itself does not alter a particular inventory, UI, or gameplay flow after startup; a loaded plugin chooses those hooks and registers any redscript-visible native types. The observable result of RED4ext alone is that installed native plugins can initialize. The behavior attributed to a game hook belongs to the individual plugin, not to the loader.

## Relevance to redscript Modding

RED4ext itself is invisible to redscript code. Its plugins (ArchiveXL, Codeware, etc.) register `native` classes and functions that redscript can then call. The pattern is:

1. RED4ext loads the plugin `.dll`
2. The plugin registers native types/functions with the game's RTTI
3. redscript binds to those types via `native class` / `native func` declarations

## No Runtime Scripting API

RED4ext exposes no redscript API directly. Interact with its plugins through their own redscript bindings — see [mod-archivexl.md](../archivexl/mod-archivexl.md) and [mod-codeware.md](../codeware/mod-codeware.md).
