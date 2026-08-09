---
inclusion: manual
---

# TweakXL — Tool Reference

TweakXL is a runtime TweakDB patcher. It reads `.yaml` and `.xl` files from `r6\tweaks\` and applies additions/overrides to the game's TweakDB at startup. There are no `.reds` source files — it is a data-driven tool, not a scripting API.

**Index:** [cyberpunk-mods-index.md](../cyberpunk-mods-index.md)

## What It Is

- Patches TweakDB (the game's flat record database) without recompiling game files
- Runs as a RED4ext plugin at game startup before scripts execute
- Tweak files location: `r6\tweaks\` (the folder is empty for this mod install — no custom tweaks defined yet)

## Runtime integration model

TweakXL does not wrap a game method, inject a UI field, or run a redscript callback for each edited record. Its RED4ext plugin runs during startup, discovers `.yaml` and `.xl` definitions, resolves record inheritance and values, then writes the resulting records/flats into the game's TweakDB before gameplay systems consume them. A mod uses this path to make an item, vendor, stat, UI record, or other TweakDB-backed object exist with altered data; the normal game system that later reads that record produces the effect. The installed package exposes no per-feature tweak files, so there is no additional mod-authored runtime flow to document here.

## TweakDB Patch File Format

```yaml
# r6/tweaks/MyMod/my_tweaks.yaml

# Create a new record
Items.MyCustomItem:
  $type: gamedataItem_Record
  displayName: LocKey#MyItem
  icon:
    $type: UIIcon_Record
    atlasResourcePath: base\gameplay\gui\...

# Override a field on an existing record
Items.SomeVanillaItem:
  price: 500

# Append to an array field
Items.SomeVanillaItem:
  tags:
    - !append MyTag
```

## Interaction with redscript

TweakDB changes made by TweakXL are visible to redscript via `TweakDBInterface`:

```swift
// Read a record field
let price = TweakDBInterface.GetFloat(t"Items.SomeItem.price", 0.0)

// Get a record ref
let record = TweakDBInterface.GetItemRecord(t"Items.SomeItem")
```

## No Runtime Scripting API

TweakXL itself exposes no redscript API. All scripted TweakDB access goes through the vanilla `TweakDBInterface` class.
