---
inclusion: manual
---

# Vanilla Game Hooks — Reference Catalog

Complete catalog of the hook targets listed in [Redscript — Things to hook](https://wiki.redmodding.org/redscript/getting-started/how-to-create-a-hook/things-to-hook), consulted 2026-08-03 (page last documented edit: 2026-06-21). These are candidate base-game hooks; verify exact signatures against NativeDB and the installed game version before implementing.

**Related:** [game-ui.md](game-ui.md) | [game-systems.md](game-systems.md) | [game-inventory.md](game-inventory.md)

## Player lifecycle and actions

```redscript
@wrapMethod(PlayerPuppet)
protected cb func OnMakePlayerVisibleAfterSpawn(evt: ref<EndGracePeriodAfterSpawn>) -> Bool { }

@wrapMethod(PlayerPuppet)
protected cb func OnStatusEffectApplied(evt: ref<ApplyStatusEffectEvent>) -> Bool { }

@wrapMethod(PlayerPuppet)
protected cb func OnStatusEffectRemoved(evt: ref<RemoveStatusEffect>) -> Bool { }

@wrapMethod(PlayerPuppet)
protected cb func OnAction(action: ListenerAction, consumer: ListenerActionConsumer) -> Bool { }
```

## Item actions and equipment

```redscript
@wrapMethod(ItemActionsHelper)
public final static func ProcessItemAction(gi: GameInstance, executor: wref<GameObject>, itemData: wref<gameItemData>, actionID: TweakDBID, fromInventory: Bool) -> Bool { }

@wrapMethod(ItemActionsHelper)
public final static func ProcessItemAction(gi: GameInstance, executor: wref<GameObject>, itemData: wref<gameItemData>, actionID: TweakDBID, fromInventory: Bool, quantity: Int32) -> Bool { }

@wrapMethod(ItemActionsHelper)
public final static func ConsumeItem(executor: wref<GameObject>, itemID: ItemID, fromInventory: Bool) -> Void { }

@wrapMethod(ItemActionsHelper)
public final static func PerformItemAction(executor: wref<GameObject>, itemID: ItemID) -> Void { }

@wrapMethod(EquipmentSystemPlayerData)
private final func UnequipItem(itemID: ItemID) -> Void { }

@wrapMethod(EquipmentSystemPlayerData)
private final func UnequipItem(equipAreaIndex: Int32, opt slotIndex: Int32, opt forceRemove: Bool) -> Void { }

@wrapMethod(RipperDocGameController)
private final func EquipCyberware(itemData: wref<gameItemData>) -> Bool { }
```

## Menus and preview UI

```redscript
@wrapMethod(ConsumeAction)
protected func ProcessStatusEffects(const actionEffects: script_ref<array<wref<ObjectActionEffect_Record>>>, gameInstance: GameInstance) -> Void { }

@wrapMethod(inkPuppetPreviewGameController)
protected cb func OnPreviewInitialized() -> Bool { }

@wrapMethod(PhotoModePlayerEntityComponent)
private final func SetupInventory(isCurrentPlayerObjectCustomizable: Bool) { }

@wrapMethod(SingleplayerMenuGameController)
protected cb func OnInitialize() -> Bool { }

@wrapMethod(DpadWheelGameController)
protected cb func OnInitialize() -> Bool { }
```

## Generic notifications and popup manager

```redscript
@wrapMethod(GenericMessageNotification)
protected cb func OnInitialize() -> Bool { }

@wrapMethod(GenericMessageNotification)
protected cb func OnHandlePressInput(evt: ref<inkPointerEvent>) -> Bool { }

@wrapMethod(PopupsManager)
protected cb func OnPlayerAttach(playerPuppet: ref<GameObject>) -> Bool { }

@addMethod(PopupsManager)
protected cb func OnShowCustomPopup(evt: ref<ShowCustomPopupEvent>) -> Bool { }

@addMethod(PopupsManager)
protected cb func OnHideCustomPopup(evt: ref<HideCustomPopupEvent>) -> Bool { }
```

`GenericMessageNotification.OnHandlePressInput` handles button input on all generic message dialogs. `PopupsManager.OnPlayerAttach` is a manager lifecycle callback. `ShowCustomPopupEvent` and `HideCustomPopupEvent` belong to Codeware's `Codeware.UI` module rather than vanilla; Codeware adds the corresponding `PopupsManager` methods. A second add conflicts, and a different mod cannot wrap them because the added methods are not visible during wrapper resolution.

### Generic-message mutation boundary

`GenericMessageNotification` retains `GenericMessageNotificationData` as `m_data`; its `title`, `message`, and notification type are available from a wrapper on the controller. Compare title/message with the same localization keys used by the requesting feature instead of hard-coding displayed English text.

With Codeware 1.20.3 installed, its replacement of the private base method below creates close data and calls the notification token's registered listener before returning:

```redscript
@wrapMethod(GenericMessageNotification)
private final func Close(result: GenericMessageNotificationResult) -> Void {
  wrappedMethod(result);
  // The requester listener has run when this returns.
}
```

This is a suitable post-mutation boundary only after filtering on both the actual `result` and verified popup metadata. `OnHandlePressInput`, including a one-frame `DelaySystem` callback scheduled from it, can run before the requester listener; treat it as an input observation point, not a post-mutation boundary. Verify this ordering again after a game or Codeware update.

## Inventory and in-game menu UI

### Wardrobe card refresh boundary

`WardrobeUIGameController` and `InventoryItemDisplayController` are base-game classes and can be
annotated by REDscript. Equipment-EX replaces the former to spawn its wardrobe and uses the latter
for visible virtual-grid item cards. `InventoryItemDisplayController.NewUpdateEquipped(itemData)`
runs when a card is bound or refreshed and receives its complete `UIInventoryItem`.

A mod can scope an item-card wrapper to a wardrobe session tracked through
`WardrobeUIGameController.OnInitialize` / `OnBack`. To refresh already visible cards after
mod-owned state changes, queue a mod-owned `Event` through `GameInstance.GetUISystem(game)` and
handle it with an `@addMethod(InventoryItemDisplayController)` callback that invokes the card's
normal refresh method. Do not synthesize a dependency's state-change event merely to force UI
redraw; use a mod-owned event instead.

For a custom Ink marker on virtualized cards, create and parent the widget once after the original
`InventoryItemDisplayController.OnInitialize` completes. Retain a controller field referencing the
widget and, during `NewUpdateEquipped`, reset its visible state for every binding. Do not allocate
or reparent marker widgets in the per-card refresh callback: virtual grids reuse controllers and
must not retain state from their prior bound item.

### Data-backed item-card refresh boundary

`InventoryItemDisplayController.RefreshUI()` is the base-game refresh boundary for cards backed by
`InventoryItemData` rather than `UIInventoryItem`. After `wrappedMethod()`, `m_uiInventoryItem` can
be absent while `m_itemData` contains the current binding. Resolve a usable item identity through
`InventoryItemData.GetGameItemData(this.m_itemData).GetID()` after checking that the returned
`gameItemData` is defined. This supports per-card state updates without relying on an external UI
controller or a polling loop.

```redscript
@wrapMethod(BackpackMainGameController)
protected cb func OnInitialize() -> Bool { }

@wrapMethod(BackpackMainGameController)
protected cb func OnItemDisplayClick(evt: ref<ItemDisplayClickEvent>) -> Bool { }

@wrapMethod(BackpackMainGameController)
private final func NewShowItemHints(itemData: wref<UIInventoryItem>) { }

@wrapMethod(CraftingGarmentItemPreviewGameController)
protected cb func OnCrafrtingPreview(evt: ref<CraftingItemPreviewEvent>) -> Bool { }

@wrapMethod(EquipmentSystemPlayerData)
public final func OnAttach() { }

@wrapMethod(EquipmentSystemPlayerData)
public final const func IsVisualSetActive() -> Bool { }

@wrapMethod(EquipmentSystemPlayerData)
public final const func IsSlotOverriden(area: gamedataEquipmentArea) -> Bool { }

@wrapMethod(EquipmentSystemPlayerData)
private final const func ShouldUnderwearBeVisibleInSet() -> Bool { }

@wrapMethod(EquipmentSystemPlayerData)
private final const func ShouldUnderwearTopBeVisibleInSet() -> Bool { }

@wrapMethod(EquipmentSystemPlayerData)
public final func OnRestored() { }

@wrapMethod(EquipmentSystemPlayerData)
public final func OnQuestDisableWardrobeSetRequest(request: ref<QuestDisableWardrobeSetRequest>) { }

@wrapMethod(EquipmentSystemPlayerData)
public final func OnQuestRestoreWardrobeSetRequest(request: ref<QuestRestoreWardrobeSetRequest>) { }

@wrapMethod(EquipmentSystemPlayerData)
public final func OnQuestEnableWardrobeSetRequest(request: ref<QuestEnableWardrobeSetRequest>) { }

@wrapMethod(EquipmentSystemPlayerData)
public final func EquipWardrobeSet(setID: gameWardrobeClothingSetIndex) { }

@wrapMethod(EquipmentSystemPlayerData)
public final func QuestHideSlot(area: gamedataEquipmentArea) { }

@wrapMethod(EquipmentSystemPlayerData)
public final func QuestRestoreSlot(area: gamedataEquipmentArea) { }

@wrapMethod(EquipmentSystemPlayerData)
private final func ClearItemAppearanceEvent(area: gamedataEquipmentArea) { }

@wrapMethod(EquipmentSystemPlayerData)
private final func ResetItemAppearanceEvent(area: gamedataEquipmentArea) { }

@wrapMethod(EquipmentSystemPlayerData)
private final func ResetItemAppearance(area: gamedataEquipmentArea, opt force: Bool) { }

@wrapMethod(gameuiInGameMenuGameController)
protected cb func OnInitialize() -> Bool { }

@wrapMethod(gameuiInGameMenuGameController)
protected cb func OnPuppetReady(sceneName: CName, puppet: ref<gamePuppet>) -> Bool { }

@wrapMethod(gameuiInGameMenuGameController)
protected cb func OnEquipmentChanged(value: Variant) -> Bool { }

@wrapMethod(gameuiInGameMenuGameController)
protected cb func OnUninitialize() -> Bool { }

@wrapMethod(gameuiInventoryGameController)
protected cb func OnInitialize() -> Bool { }

@wrapMethod(gameuiInventoryGameController)
protected cb func OnUninitialize() -> Bool { }

@wrapMethod(gameuiInventoryGameController)
private final func SetupSetButton() -> Void { }

@wrapMethod(gameuiInventoryGameController)
protected cb func OnWardrobeBtnClick(evt: ref<inkPointerEvent>) -> Bool { }

@wrapMethod(gameuiInventoryGameController)
protected cb func OnWardrobePopupClose(data: ref<inkGameNotificationData>) { }

@wrapMethod(gameuiInventoryGameController)
protected cb func OnBack(userData: ref<IScriptable>) -> Bool { }

@wrapMethod(gameuiInventoryGameController)
protected cb func OnEquipmentClick(evt: ref<ItemDisplayClickEvent>) -> Bool { }
```

## Photo mode and item display UI

```redscript
@wrapMethod(gameuiPhotoModeMenuController)
protected cb func OnInitialize() -> Bool { }

@wrapMethod(gameuiPhotoModeMenuController)
protected cb func OnAddMenuItem(label: String, attribute: Uint32, page: Uint32) -> Bool { }

@wrapMethod(gameuiPhotoModeMenuController)
protected cb func OnShow(reversedUI: Bool) -> Bool { }

@wrapMethod(gameuiPhotoModeMenuController)
protected cb func OnSetAttributeOptionEnabled(attribute: Uint32, enabled: Bool) -> Bool { }

@wrapMethod(PhotoModeMenuListItem)
private final func StartArrowClickedEffect(widget: inkWidgetRef) { }

@wrapMethod(inkInventoryPuppetPreviewGameController)
protected cb func OnInitialize() -> Bool { }

@wrapMethod(InventoryItemDisplayController)
public func Bind(inventoryDataManager: ref<InventoryDataManagerV2>, equipmentArea: gamedataEquipmentArea, opt slotIndex: Int32, opt displayContext: ItemDisplayContext, opt setWardrobeOutfit: Bool, opt wardrobeOutfitIndex: Int32) { }

@wrapMethod(InventoryItemDisplayController)
public func Bind(inventoryScriptableSystem: ref<UIInventoryScriptableSystem>, equipmentArea: gamedataEquipmentArea, opt slotIndex: Int32, displayContext: ItemDisplayContext) { }

@wrapMethod(InventoryItemDisplayController)
protected func RefreshUI() { }

@wrapMethod(InventoryItemDisplayController)
protected func NewUpdateRequirements(itemData: ref<UIInventoryItem>) { }

@wrapMethod(InventoryItemModeLogicController)
private final func UpdateOutfitWardrobe(active: Bool, activeSetOverride: Int32) { }

@wrapMethod(InventoryItemModeLogicController)
protected cb func OnItemDisplayClick(evt: ref<ItemDisplayClickEvent>) -> Bool { }

@wrapMethod(InventoryItemModeLogicController)
protected cb func OnItemDisplayHoverOver(evt: ref<ItemDisplayHoverOverEvent>) -> Bool { }

@wrapMethod(InventoryItemModeLogicController)
private final func SetInventoryItemButtonHintsHoverOver(const displayingData: script_ref<InventoryItemData>, opt display: ref<InventoryItemDisplayController>) { }

@wrapMethod(InventoryItemModeLogicController)
private final func HandleItemClick(const itemData: script_ref<InventoryItemData>, actionName: ref<inkActionName>, opt displayContext: ItemDisplayContext, opt isPlayerLocked: Bool) { }

@wrapMethod(PhotoModePlayerEntityComponent)
private final func OnGameAttach() { }

@wrapMethod(PhotoModePlayerEntityComponent)
protected cb func OnItemAddedToSlot(evt: ref<ItemAddedToSlot>) -> Bool { }

@wrapMethod(QuestTrackerGameController)
protected cb func OnInitialize() -> Bool { }

@wrapMethod(UIInventoryItem)
public final func IsEquipped(opt force: Bool) -> Bool { }

@wrapMethod(UIInventoryItem)
public final func IsTransmogItem() -> Bool { }

@wrapMethod(UIInventoryItemsManager)
public final static func Make(player: wref<PlayerPuppet>, transactionSystem: ref<TransactionSystem>, uiScriptableSystem: wref<UIScriptableSystem>) -> ref<UIInventoryItemsManager> { }

@wrapMethod(UIInventoryItemsManager)
public final func IsItemEquippedInSlot(itemID: ItemID, slotID: TweakDBID) -> Bool { }

@wrapMethod(UIInventoryItemsManager)
public final func IsItemTransmog(itemID: ItemID) -> Bool { }

@wrapMethod(WardrobeSetPreviewGameController)
protected cb func OnInitialize() -> Bool { }

@wrapMethod(WardrobeSetPreviewGameController)
protected cb func OnPreviewInitialized() -> Bool { }

@wrapMethod(WardrobeSetPreviewGameController)
public final func RestorePuppetEquipment() { }
```

## Computer UI

```redscript
@wrapMethod(ComputerInkGameController)
private final func ShowMenuByName(elementName: String) -> Void { }

@wrapMethod(ComputerInkGameController)
private final func HideMenuByName(elementName: String) -> Void { }

@wrapMethod(ComputerControllerPS)
public final func GetMenuButtonWidgets() -> array<SComputerMenuButtonWidgetPackage> { }

@wrapMethod(ComputerMenuButtonController)
public func Initialize(gameController: ref<ComputerInkGameController>, widgetData: SComputerMenuButtonWidgetPackage) -> Void { }

@wrapMethod(BrowserController)
protected cb func OnPageSpawned(widget: ref<inkWidget>, userData: ref<IScriptable>) -> Bool { }
```

## Consumables and time skip

```redscript
@wrapMethod(ConsumableTransitions)
protected final func ChangeConsumableAnimFeature(stateContext: ref, scriptInterface: ref, newState: Bool) -> Void { }

@wrapMethod(UseHealChargeAction)
protected func ProcessStatusEffects(const actionEffects: script_ref<array<wref<ObjectActionEffect_Record>>>, gameInstance: GameInstance) -> Void { }

@wrapMethod(ConsumeAction)
protected func ProcessStatusEffects(const actionEffects: script_ref<array<wref<ObjectActionEffect_Record>>>, gameInstance: GameInstance) -> Void { }

@wrapMethod(TimeskipGameController)
private final func Apply() -> Void { }
```
