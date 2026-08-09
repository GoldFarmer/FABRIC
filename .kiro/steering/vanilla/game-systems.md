---
inclusion: manual
---

# Vanilla Game Systems — API Reference

Key vanilla Cyberpunk 2077 game systems and classes available to REDscript integrations. All classes are native engine types accessed via `GameInstance` accessors or `@wrapMethod` patches.

**Index:** [../cyberpunk-mods-index.md](../cyberpunk-mods-index.md)

**Related:** [game-inventory.md](game-inventory.md) | [game-ui.md](game-ui.md)

---

## GameInstance Accessors

```swift
// Core systems (pass game: GameInstance obtained from GetGame() or player.GetGame())
GameInstance.GetTransactionSystem(game)       -> ref<TransactionSystem>
GameInstance.GetWardrobeSystem(game)          -> ref<WardrobeSystem>
GameInstance.GetPlayerSystem(game)            -> ref<gamePlayerSystem>
GameInstance.GetScriptableSystemsContainer(game) -> ref<ScriptableSystemsContainer>
GameInstance.GetScriptableServiceContainer(game) -> ref<ScriptableServiceContainer>  // NOTE: not in source; use Get() pattern
GameInstance.GetQuestsSystem(game)            -> ref<questQuestsSystem>
GameInstance.GetUISystem(game)                -> ref<UISystem>
GameInstance.GetBlackboardSystem(game)        -> ref<gameBlackboardSystem>
GameInstance.GetDelaySystem(game)             -> ref<DelaySystem>
GameInstance.GetPlaythroughTime(game)         -> EngineTime

// Common helpers
GetPlayer(game)                               -> ref<PlayerPuppet>
GetAllBlackboardDefs()                        -> AllBlackboardDefinitions
```

---

## WardrobeSystem

Native system managing vanilla wardrobe sets. **Confirmed from `core/systems/wardrobeSystem.script`.**

```swift
// Obtain
GameInstance.GetWardrobeSystem(game) -> ref<WardrobeSystem>

// Wardrobe store (items remembered for wardrobe use without owning)
func GetStoredItemIDs() -> array<ItemID>
func GetStoredItemID(item: TweakDBID) -> ItemID
func GetFilteredStoredItemIDs(equipmentArea: gamedataEquipmentArea) -> array<ItemID>
func StoreUniqueItemID(itemID: ItemID) -> Bool
func StoreUniqueItemIDAndMarkNew(gameInstance: GameInstance, itemID: ItemID) -> Bool
func IsItemBlacklisted(itemID: ItemID) -> Bool
func ForgetItemID(itemID: ItemID)    // NOTE: seen in EX source; may be in final.redscripts only

// Clothing sets (vanilla wardrobe presets, Slot1–Slot7)
func GetClothingSets() -> array<ClothingSet>
func GetActiveClothingSet() -> ClothingSet
func GetActiveClothingSetIndex() -> gameWardrobeClothingSetIndex
func SetActiveClothingSetIndex(slotIndex: gameWardrobeClothingSetIndex)
func PushBackClothingSet(clothingSet: ClothingSet)
func DeleteClothingSet(setIndex: gameWardrobeClothingSetIndex)

// Static helpers
static func WardrobeClothingSetIndexToNumber(slotIndex: gameWardrobeClothingSetIndex) -> Int32
static func NumberToWardrobeClothingSetIndex(number: Int32) -> gameWardrobeClothingSetIndex
static func GetActiveWardrobeSetID(player: wref<PlayerPuppet>) -> gameWardrobeClothingSetIndex  // on EquipmentSystem

enum gameWardrobeClothingSetIndex { Slot1, Slot2, Slot3, Slot4, Slot5, Slot6, Slot7, COUNT, INVALID }

struct ClothingSet {
    let setID: gameWardrobeClothingSetIndex;
    let clothingList: array<SSlotVisualInfo>;
}

struct SSlotVisualInfo {
    let visualItem: ItemID;   // ItemID of the equipped visual item
    let isHidden: Bool;
}
```

**Hook note:** Equipment-EX `@replaceMethod`s `EquipWardrobeSet` and `UnequipWardrobeSet` on `EquipmentSystemPlayerData` to no-ops, routing all wardrobe operations through `OutfitSystem` instead.

---

## TransactionSystem

Manages item ownership and slot attachment on any game entity. **Confirmed from `core/systems/transactionSystem.script`.**

```swift
// Obtain
GameInstance.GetTransactionSystem(game) -> ref<TransactionSystem>

// Item give / remove
func GiveItem(entity: wref<GameObject>, itemID: ItemID, amount: Int32, opt dynamicTags: array<CName>) -> Bool
func GiveItemByTDBID(entity: wref<GameObject>, tdbID: TweakDBID, amount: Int32) -> Bool
func GivePreviewItemByItemID(entity: wref<GameObject>, itemID: ItemID) -> Bool
func GivePreviewItemByItemData(entity: wref<GameObject>, itemData: gameItemData) -> Bool
func CreatePreviewItemID(itemID: ItemID) -> ItemID
func RemoveItem(entity: wref<GameObject>, itemID: ItemID, amount: Int32) -> Bool
func RemoveItemByTDBID(entity: wref<GameObject>, tdbID: TweakDBID, amount: Int32, opt checkMultipleInstances: Bool) -> Bool
func RemoveAllItems(entity: wref<GameObject>) -> Bool
func TransferItem(source: wref<GameObject>, target: wref<GameObject>, itemID: ItemID, amount: Int32, ...) -> Bool

// Item queries
func HasItem(entity: wref<GameObject>, itemID: ItemID) -> Bool
func HasTag(entity: wref<GameObject>, tag: CName, itemID: ItemID) -> Bool
func GetItemData(entity: wref<GameObject>, itemID: ItemID) -> wref<gameItemData>
func GetItemDataByTDBID(entity: wref<GameObject>, itemTDBID: TweakDBID) -> wref<gameItemData>
func GetItemDataByOwnerEntityId(id: EntityID, itemID: ItemID) -> wref<gameItemData>
func GetItemQuantity(entity: wref<GameObject>, itemID: ItemID) -> Int32
func GetItemList(entity: wref<GameObject>, out itemList: array<wref<gameItemData>>) -> Bool
func GetItemListByTag(entity: wref<GameObject>, tag: CName, out itemList: array<wref<gameItemData>>) -> Bool
func GetNumItems(entity: wref<GameObject>, opt tagFilters: array<CName>) -> Int32

// Slot attachment
func AddItemToSlot(entity: wref<GameObject>, slotID: TweakDBID, itemID: ItemID, opt highPriority: Bool, ...) -> Bool
func RemoveItemFromSlot(entity: wref<GameObject>, slotID: TweakDBID, ...) -> Bool
func RemoveItemFromAnySlot(entity: wref<GameObject>, itemID: ItemID, ...) -> Bool
func GetItemInSlot(entity: wref<GameObject>, slotID: TweakDBID) -> ItemObject
func HasItemInSlot(entity: wref<GameObject>, slotID: TweakDBID, itemID: ItemID) -> Bool
func IsSlotEmpty(entity: wref<GameObject>, slotID: TweakDBID) -> Bool
func RefreshAttachment(entity: wref<GameObject>, out slotID: TweakDBID, opt keepWorldTransform: Bool)

// Slot listener callbacks
func RegisterAttachmentSlotListener(entity: wref<GameObject>, callback: ref<AttachmentSlotsScriptCallback>) -> ref<AttachmentSlotsScriptListener>
func UnregisterAttachmentSlotListener(entity: wref<GameObject>, listener: ref<AttachmentSlotsScriptListener>)
func RegisterInventoryListener(entity: wref<GameObject>, callback: InventoryScriptCallback) -> InventoryScriptListener
func UnregisterInventoryListener(entity: wref<GameObject>, listener: InventoryScriptListener)
```

### AttachmentSlotsScriptCallback

```swift
abstract class AttachmentSlotsScriptCallback {
    func OnItemEquipped(slotID: TweakDBID, itemID: ItemID) -> Void
    func OnItemEquippedVisual(slotID: TweakDBID, itemID: ItemID) -> Void
    func OnItemUnequippedComplete(slotID: TweakDBID, itemID: ItemID) -> Void
}
```

---

## EquipmentSystem / EquipmentSystemPlayerData

Manages the player's equipped items per equipment area (Head, InnerChest, Legs, etc.).

```swift
// Obtain EquipmentSystem (it's a ScriptableSystem)
let equipSystem = GameInstance.GetScriptableSystemsContainer(game).Get(n"EquipmentSystem") as EquipmentSystem
// Or via static helpers:
EquipmentSystem.GetInstance(owner: wref<GameObject>) -> ref<EquipmentSystem>
EquipmentSystem.GetData(owner: wref<GameObject>) -> ref<EquipmentSystemPlayerData>  // shortcut
EquipmentSystem.GetActiveWardrobeSetID(player: wref<PlayerPuppet>) -> gameWardrobeClothingSetIndex

// EquipmentSystemPlayerData — confirmed public API from script dump
func GetActiveItem(area: gamedataEquipmentArea) -> ItemID
func GetItemInEquipSlot(area: gamedataEquipmentArea, slotIndex: Int32) -> ItemID
func GetEquipAreaIndex(area: gamedataEquipmentArea) -> Int32
func GetPlacementSlotByAreaType(area: gamedataEquipmentArea) -> TweakDBID
func GetVisualItemInSlot(area: gamedataEquipmentArea) -> ItemID
func GetVisualTagByAreaType(area: gamedataEquipmentArea) -> CName
func IsVisualTagActive(tag: CName) -> Bool
func IsVisualSetActive() -> Bool
func IsSlotOverriden(area: gamedataEquipmentArea) -> Bool
func IsSlotHidden(area: gamedataEquipmentArea) -> Bool
func IsSlotLocked(area: gamedataEquipmentArea, slotIndex: Int32, out visibleWhenLocked: Bool) -> Bool
func IsWardrobeEnabled() -> Bool
func GetNumberOfSlots(area: gamedataEquipmentArea, opt includeLocked: Bool) -> Int32
func GetItemSlotIndex(owner: wref<GameObject>, itemID: ItemID) -> Int32
func IsEquipped(owner: wref<GameObject>, itemID: ItemID) -> Bool
func IsEquippable(owner: wref<GameObject>, itemData: wref<gameItemData>) -> Bool
func GetInventoryManager() -> ref<InventoryDataManagerV2>   // NOTE: accessed via InventoryDataManagerV2, not this

// Visual management (called by Equipment-EX)
// ClearVisuals / UnequipVisuals are private in vanilla — Equipment-EX wraps them
func SendEquipAudioEvents(itemID: ItemID)    // private, called internally
func SendUnequipAudioEvents(itemID: ItemID)  // private, called internally

// Wardrobe set methods (Equipment-EX @replaceMethod-s these to no-ops)
func EquipWardrobeSet(setID: gameWardrobeClothingSetIndex)
func UnequipWardrobeSet()
func DeleteWardrobeSet(setID: gameWardrobeClothingSetIndex)
func QuestHideSlot(area: gamedataEquipmentArea)    // @replaceMethod -> no-op
func QuestRestoreSlot(area: gamedataEquipmentArea) // @replaceMethod -> no-op

// @addField / @addMethod by Equipment-EX (not in vanilla)
// m_visualChangesAllowed: Bool
// LockVisualChanges() / UnlockVisualChanges()
```

### gamedataEquipmentArea enum (clothing-relevant values)

```swift
enum gamedataEquipmentArea {
    Head,          // gamedataEquipmentArea.Head
    Face,          // gamedataEquipmentArea.Face
    InnerChest,    // t1 shirt layer
    OuterChest,    // t2 jacket layer  (also "ChestArmor" in some records)
    Legs,          // gamedataEquipmentArea.Legs  (also "LegArmor")
    Feet,          // gamedataEquipmentArea.Feet
    UnderwearTop,
    UnderwearBottom,
    Outfit,        // vanilla outfit slot — Equipment-EX deactivates/replaces this
    Weapon,
    Invalid
}
```

---

## DelaySystem

Deferred callback execution (next frame or after N seconds).

```swift
GameInstance.GetDelaySystem(game) -> ref<DelaySystem>

func DelayCallback(callback: ref<DelayCallback>, delay: Float, opt repeat: Bool) -> DelayID
func DelayCallbackNextFrame(callback: ref<DelayCallback>) -> DelayID
func CancelDelay(id: DelayID)

// Base class to subclass for callbacks
abstract class DelayCallback {
    func Call() -> Void
}
```

---

## TweakDBInterface / TweakDBManager

Read/write TweakDB records at runtime.

```swift
// Read
TweakDBInterface.GetItemRecord(id: TweakDBID) -> ref<Item_Record>
TweakDBInterface.GetClothingRecord(id: TweakDBID) -> ref<Clothing_Record>
TweakDBInterface.GetAttachmentSlotRecord(id: TweakDBID) -> ref<AttachmentSlot_Record>
TweakDBInterface.GetForeignKeyArray(id: TweakDBID) -> array<TweakDBID>
TweakDBInterface.GetBool(id: TweakDBID, default: Bool) -> Bool
TweakDBInterface.GetFloat(id: TweakDBID, default: Float) -> Float
TweakDBInterface.GetRecords(typeName: CName) -> array<ref<IScriptable>>
TweakDBInterface.GetLocKeyDefault(id: TweakDBID) -> CName

// Write (runtime, non-persistent)
TweakDBManager.SetFlat(id: TweakDBID, value: Variant)
TweakDBManager.UpdateRecord(id: TweakDBID)
TweakDBManager.StartBatch() -> ref<TweakDBBatch>   // batch.SetFlat / batch.UpdateRecord / batch.Commit()

// ScriptableTweak — runs at startup before scripts
abstract class ScriptableTweak {
    protected func OnApply() -> Void   // override to patch TweakDB at init
}
```

---

## Blackboard System

Event/data bus used by UI to react to equipment changes.

```swift
GameInstance.GetBlackboardSystem(game) -> ref<gameBlackboardSystem>

// Get a blackboard instance
let bb = GameInstance.GetBlackboardSystem(game).Get(GetAllBlackboardDefs().UI_Equipment)

// Register/unregister listeners
bb.RegisterListenerVariant(key: BlackboardID_Variant, target: ref<IScriptable>, func: CName) -> ref<CallbackHandle>
bb.RegisterListenerBool(key: BlackboardID_Bool, target: ref<IScriptable>, func: CName) -> ref<CallbackHandle>
bb.UnregisterListenerVariant(key: BlackboardID_Variant, handle: ref<CallbackHandle>)
bb.UnregisterListenerBool(key: BlackboardID_Bool, handle: ref<CallbackHandle>)

// Get/set values
bb.GetVariant(key: BlackboardID_Variant) -> Variant
bb.SetVariant(key: BlackboardID_Variant, value: Variant, opt fireCallbacks: Bool)
bb.SetInt(key: BlackboardID_Int, value: Int32, opt fireCallbacks: Bool)
bb.FireCallbacks()
```

### Key Blackboard Definitions

```swift
// UI_Equipment blackboard (GetAllBlackboardDefs().UI_Equipment)
// Used by Equipment-EX to notify UI of outfit slot changes
let def = GetAllBlackboardDefs().UI_Equipment
def.areaChanged: BlackboardID_Int
def.areaChangedSlotIndex: BlackboardID_Int
def.itemEquipped: BlackboardID_Variant   // Variant<ItemID>
def.lastModifiedArea: BlackboardID_Variant // Variant<SPaperdollEquipData>
def.EquipmentInProgress: BlackboardID_Bool

struct SPaperdollEquipData {
    let equipped: Bool;
    let placementSlot: TweakDBID;
}

// UI_Inventory blackboard (GetAllBlackboardDefs().UI_Inventory)
def.itemAdded: BlackboardID_Variant    // Variant<ItemRemovedData> (reused struct)
def.itemRemoved: BlackboardID_Variant  // Variant<ItemRemovedData>

struct ItemRemovedData {
    let itemID: ItemID;
}
```

---

## UISystem

Queues global UI events (received by any registered `inkGameController`).

```swift
GameInstance.GetUISystem(game) -> ref<UISystem>

func QueueEvent(event: ref<Event>)
```

**Usage:** Equipment-EX fires `OutfitUpdated`, `OutfitPartUpdated`, `OutfitListUpdated`, `OutfitMappingUpdated` via UISystem so all open screens react.

---

## CallbackSystem

Allows subscribing to named engine lifecycle events (e.g. `Session/Ready`).

```swift
GameInstance.GetCallbackSystem() -> ref<CallbackSystem>

// Register a callback for a named event
func RegisterCallback(eventName: CName, target: ref<IScriptable>, funcName: CName) -> ref<CallbackHandle>
  // Returns a handle; call .SetLifetime() on it to control duration

// Callback handle options
handle.SetLifetime(lifetime: CallbackLifetime)

enum CallbackLifetime {
    Forever,     // persists until manually unregistered
    // ...
}

// Common event names
n"Session/Ready"   // fires after TweakDB + game systems are initialized, before player attach
```

---

## SystemRequestsHandler

Provides game state queries (e.g. whether we're in the pre-game main menu).

```swift
GameInstance.GetSystemRequestsHandler() -> ref<SystemRequestsHandler>

func IsPreGame() -> Bool   // true when in main menu (no active game session)
```

---

## UI_Notifications Blackboard

Used to display on-screen HUD messages (`SimpleScreenMessage`).

```swift
let def = GetAllBlackboardDefs().UI_Notifications
let bb = GameInstance.GetBlackboardSystem(game).Get(def)

// Show an on-screen message
let msg: SimpleScreenMessage;
msg.isShown = true;
msg.duration = 5.0;   // seconds
msg.message = "Your text here";
bb.SetVariant(def.OnscreenMessage, ToVariant(msg), true);
```

---

## InventoryHelper (Equipment-EX) — Additional Method

`GetWardrobeItemIDs()` is an additional method on `InventoryHelper` (Equipment-EX) not previously documented:

```swift
// Returns all ItemIDs currently in the wardrobe store
func GetWardrobeItemIDs() -> array<ItemID>
```

See [../equipment-ex/mod-equipment-ex.md](../equipment-ex/mod-equipment-ex.md) for full `InventoryHelper` reference.
