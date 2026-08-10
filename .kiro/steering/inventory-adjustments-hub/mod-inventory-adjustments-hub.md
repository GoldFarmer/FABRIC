---
inclusion: manual
---

# Inventory Adjustments Hub — Runtime and Hook Reference

Inventory Adjustments Hub (IAH) 1.3 is an inventory, crafting, and tooltip presentation mod. It reorganizes item-card layout, exposes additional item/stat information, adds effect and tag indicators, and supplies ModSettings-controlled visual variants. It does not change item ownership, combat values, or equipment rules; its TweakXL payload supplies metadata/tags that its UI readers use to describe items more clearly.

**Sources:** `r6\scripts\InventoryAdjustmentsHub\` and `r6\tweaks\InventoryAdjustmentsHub.yaml`
**Modules:** `IAHCore`, `IAHConfig`, `IAHLayout`, `IAHStats`, `IAHEffects`, `IAHMagazine`, `IAHPlusQuality`, `IAHCrafting`, `IAHDFSupport`, `IAHub.Localization`
**Index:** [cyberpunk-mods-index.md](../cyberpunk-mods-index.md)

## Runtime model

`IAHCore.IAHub extends ScriptableSystem`. On attach it reads the game's Big Font, UI-language, and HDR settings, then creates `IAHModSettings` and caches whether IAH is enabled. When `PauseMenuBackgroundGameController.OnUninitialize` runs, it refreshes both system and ModSettings values so subsequent inventory UI refreshes use the latest settings.

The mod is largely refresh-driven: it attaches its own Ink containers during a host controller's `OnInitialize`, then updates their text, icons, color, visibility, and layout after the host's normal card or tooltip update has completed. The added container fields retain those widgets across subsequent refreshes; this avoids re-creating them for every item binding.

On the base `InventoryItemDisplayController`, IAH uses `@wrapMethod` (not `@replaceMethod`) for both `OnInitialize()` and `NewRefreshUI(UIInventoryItem)`, and calls `wrappedMethod()` in each. Its initializer then runs `AdjustCommonLayout` and `AdjustClothingLayout`; its refresh wrapper only applies the configured clothing-mod visibility rule to `m_commonModsRoot`. The clothing-layout path can create a separate `tagsLabel` under `container/rightContainer/wrapper`, using the vanilla loop-bordered mappin atlas and `icon_officer` texture part. It does not remove or replace the card's root `container`.

## Game integration flows

| Trigger / host flow | Why it is intercepted | IAH behavior | Result |
|---|---|---|---|
| An inventory item card initializes, changes comparison state, refreshes, or updates its counter (`InventoryItemDisplayController`) | Vanilla card layout does not reserve IAH's labels/indicators and can show clothing attachment icons that the mod elects to hide | Adjusts common/clothing layout, creates weapon-only `+`, effects, and ammo containers, shifts counters, suppresses the clothing comparison arrow, fixes cyberware-preview opacity, and hides clothing mod icons when configured | Inventory cards use the adjusted layout and do not retain stale IAH visuals across normal refreshes |
| A weapon card refreshes (`InventoryWeaponDisplayController`) | Weapon cards need information not represented by the default type line and parts display | Uses injected container references to update ammo/DPS/magazine or attack-type replacement text, weapon type label/icon placement, mod and part colors, iconic `+` quality, stat-effect icons, and TweakDB tag labels | Weapon, cyberware-arm, consumable, clothing, and part cards can display selected extra indicators and configured styling |
| A visual/equipment display refreshes (`VisualDisplayController`) | Equipment displays otherwise omit the item's tag labels | Reads the item's TweakDB record tags and updates the same tag-label presentation path | Tag labels remain consistent outside the standard weapon-card controller |
| A detailed/minimal item tooltip initializes or updates header, bottom, data, stats, or attachments (`AGenericTooltipControllerWithDebug`, `ItemTooltipCommonController`, `NewItemTooltipCommonController`, `ItemTooltipStatController`, `ItemTooltipModController`, `NewItemTooltipAttachmentGroupController`, `MinimalItemTooltipData`) | Vanilla tooltips omit IAH's effective-DPS, magazine, clothing-tag, stat-effect, and attachment naming presentation | Creates persistent DPS/magazine/tag containers; derives comparison DPS and magazine capacity; formats stat titles/values; colors stats and adds effect icons; chooses mod description/name/slot presentation; and copies attachment item names into `slotName` | Old and new item-tooltip variants show the selected additional data with consistent names, icons, spacing, and wrapping |
| Tooltip stats and weapon bars are constructed (`UIInventoryItemStatsManager`, `UIInventoryItemWeaponBars`) | Tooltip formatting needs a cached effective-DPS value and a configurable stat set | Captures `EffectiveDPS` on the weapon-bars object and either uses vanilla stat collection or builds IAH's configured complexity list before the tooltip consumes it | Header comparison and expanded-stat display have the values required by IAH's later tooltip hooks |
| Armor-panel stats are built (`InventoryDataManagerV2.GetPlayerStatsFromMap`) | The vanilla armor map does not include the selected headgear resistance mappings | Maps explosion and melee resistance to the corresponding head-item values and adds them only while building `UIMaps.Player_Stat_Panel_Armor` | The player armor panel includes those headgear-derived values |
| Tooltip windows show or hide (`gameuiTooltipsManager`) | Item tooltips need an independently configurable scale without leaving later tooltips scaled | After normal show, identifies item/program/cyberdeck tooltip classes and scales the shared tooltip container; on hide, restores scale to `1.0` | Supported tooltips resize while open and the global tooltip container is reset afterward |
| The crafting panel opens or a craftable item changes (`CraftingMainLogicController`, `CraftableItemLogicController`) | Crafting's slider can be non-interactive and iconic cards need the same visual cue as inventory cards | Restores slider interactivity and updates iconic tint after the normal controller update | Crafting navigation remains usable and iconic craftables receive the configured tint |
| Mod Settings selector controls update (`SettingsSelectorControllerList`, `SettingsSelectorControllerRange`) | IAH exposes color-driven settings that vanilla controls do not preview | Updates selector color when a dot is selected and adds a range-control color update helper | The settings UI previews the chosen color values |
| Dark Future updates its backpack needs bars (`BackpackMainGameController.UpdateAllBarsAppearance`) | Optional Dark Future bars need a matching color treatment | Guarded by `ModuleExists("DarkFuture.Main")` and the IAH setting; tints hydration, nutrition, energy, and nerve labels/icons | Dark Future needs bars receive IAH's configured semantic colors only when both mods are active |

## Injected state and lifecycle

| Host type | Added state | Purpose |
|---|---|---|
| `InventoryWeaponDisplayController` | `plusContainer`, `effectsContainer`, `ammoReplacerContainer`, initial type-container index | Preserves IAH-owned card widgets and original layout position across item refreshes |
| `AGenericTooltipControllerWithDebug` | `magazineContainer`, `dpsContainer`, `tagsContainer` | Owns tooltip widgets created once during initialization and updated in header/bottom hooks |
| `ItemTooltipStatController`, `ItemTooltipModController`, `NewItemTooltipAttachmentGroupController` | Cached `IAHub` reference | Avoids repeatedly resolving the scriptable system while applying settings-gated formatting |
| `UIInventoryItemWeaponBars` | `effectiveDps` | Carries the source item's effective DPS into tooltip comparison UI |

## Modules and presentation data

- `IAHLayout` moves/recolors existing Ink controls, changes weapon type-label presentation, adjusts count/mod visibility, and repairs selected controller layout defects.
- `IAHPlusQuality` creates the configured visual representation of post-quality `+` values. Its V1/V2 container variants accommodate different item-card layouts.
- `IAHEffects` converts item tags and selected stat values into effect-icon lists for weapons, clothing, cyberware arms, scopes, muzzles, mods, consumables, and junk; it then creates, reuses, and lays out Ink icon labels.
- `IAHMagazine` and `IAHStats` provide the magazine, effective-DPS, tag, and expanded-stat tooltip widgets consumed by the tooltip hooks.
- `IAHCrafting` updates iconic tint in crafting; `IAHDFSupport` is compiled only when Dark Future is present.
- `IAHub.Localization` is a Codeware `ModLocalizationProvider` with packages for the shipped language files.

## TweakXL data integration

`InventoryAdjustmentsHub.yaml` runs through TweakXL at startup. It supplies display metadata for additional stat records (for example percent/seconds/plus formatting and localized names) and appends identifying tags to weapon-mod base records. IAH's stat and effect code later reads those record properties and tags during UI refresh; the YAML itself does not execute UI code or alter combat calculations.

## Configuration

`IAHConfig.IAHModSettings` uses ModSettings runtime properties. The settings are grouped around global enablement, adjusted item layout, crafting iconic tint, plus-quality style, the optional Equipment-EX clothing-mod display fix, weapon type/ammo/color presentation, effect-icon categories and scale, clothing tags, tooltip scale/stat complexity/mod-information scheme, and Dark Future color support.

Most hooks call through to `wrappedMethod` and gate their extra work on `IAHub.isEnabled` or the relevant setting. The Equipment-EX-specific tooltip-details wrapper is additionally compiled only when `ModuleExists("EquipmentEx")`; it temporarily tags a clothing display context as `CyberwareUpgrade` while vanilla mod rendering runs, then hides the empty wrapper if no actual mod entries remain.

## Hook inventory

The behavior groups above cover the source decorators. Exact source files are: `core.reds`, `config.reds`, `modules/darkFutureSupport.reds`, and the controller files `inventoryItemDisplayController.reds`, `inventoryWeaponDisplayController.reds`, `visualDisplayController.reds`, `itemTooltipController.reds`, `itemTooltipDetailsModule.reds`, `itemTooltipStatController.reds`, `itemTooltipModController.reds`, `NewItemTooltipAttachmentGroupController.reds`, `MinimalItemTooltipData.reds`, `UIInventoryItemStatsManager.reds`, `UIInventoryItemWeaponBars.reds`, `InventoryDataManagerV2.reds`, `gameuiTooltipsManager.reds`, `craftingMainLogicController.reds`, and `craftableItemLogicController.reds`.
