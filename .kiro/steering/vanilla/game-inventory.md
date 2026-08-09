---
inclusion: manual
---

# Vanilla Game Inventory — API Reference

Inventory data management, item data types, and UI inventory classes.

**Index:** [../cyberpunk-mods-index.md](../cyberpunk-mods-index.md)

**Related:** [game-systems.md](game-systems.md) | [game-ui.md](game-ui.md)

---

## InventoryDataManagerV2

Primary inventory manager for the player. Wraps `TransactionSystem` with UI-aware caching.

```swift
// Instantiation (not a ScriptableSystem — must be newed and initialized)
let mgr = new InventoryDataManagerV2();
mgr.Initialize(player: wref<PlayerPuppet>, opt owner: wref<inkHUDGameController>)
mgr.UnInitialize()

// Access via EquipmentSystemPlayerData (preferred in hooks) — NOTE: this is
// NOT a direct method on EquipmentSystemPlayerData; use separate construction.
// Equipment-EX accesses it via: EquipmentSystem.GetData(player).GetInventoryManager()
// which is only available after EX patches it via @addField.

// Confirmed public API (from script dump)
func GetPlayerInventoryData() -> array<InventoryItemData>
func GetPlayerInventoryData(equipArea: gamedataEquipmentArea, opt skipEquipped: Bool, opt filteredItems: array<ItemModParams>) -> array<InventoryItemData>
func GetCachedInventoryItemData(itemData: wref<gameItemData>) -> InventoryItemData
func GetInventoryItemDataFromItemID(itemID: ItemID) -> InventoryItemData
func GetPlayerItemData(itemId: ItemID) -> wref<gameItemData>
func GetEquippedItemIdInArea(equipArea: gamedataEquipmentArea, opt slot: Int32) -> ItemID
func GetItemDataEquippedInArea(equipArea: gamedataEquipmentArea, opt slot: Int32) -> InventoryItemData
func GetGame() -> GameInstance
func GetTransactionSystem() -> wref<TransactionSystem>
func GetUIInventorySystem() -> wref<UIInventoryScriptableSystem>
func IsTransmogEnabled() -> Int32   // reads transmog_enabled quest fact
func MarkToRebuild()

// Equipment area helpers (static)
static func GetInventoryEquipmentAreas() -> array<gamedataEquipmentArea>
  // returns: Head, Face, InnerChest, OuterChest, Legs, Feet
static func IsAreaClothing(area: gamedataEquipmentArea) -> Bool
  // true for: Face, Feet, Head, InnerChest, Legs, OuterChest, Outfit

// Stash-related utilities
func GetItemFromRecord(tweakPath: String) -> InventoryItemData
func GetItemFromRecord(id: TweakDBID) -> InventoryItemData
```

---

## InventoryItemData (struct)

Flat data struct passed around by the vanilla inventory UI. Mutable fields.

```swift
struct InventoryItemData {
    let ID: ItemID;
    let Name: String;              // localized display name
    let Quantity: Int32;
    let IsEquipped: Bool;
    let SlotID: TweakDBID;         // slot it's equipped in (if any)
    let CategoryName: String;      // localized category
    let EquipmentArea: gamedataEquipmentArea;
    // ... additional fields for quality, price, tags, etc.
}
```

---

## gameItemData

Native item instance handle. Wraps an owned item in inventory.

```swift
// Obtain via TransactionSystem
func GetID() -> ItemID
func HasTag(tag: CName) -> Bool
func GetStatValueByType(statType: gamedataStatType) -> Float
```

---

## ItemID

Value type identifying an item instance. Includes TweakDB record ID + instance `rng_seed`.

```swift
// Construction
ItemID.FromTDBID(recordID: TweakDBID) -> ItemID
ItemID.None() -> ItemID

// Queries
ItemID.IsValid(itemID: ItemID) -> Bool
ItemID.GetTDBID(itemID: ItemID) -> TweakDBID
ItemID.GetCombinedHash(itemID: ItemID) -> Uint64
ItemID.HasFlag(itemID: ItemID, flag: gameEItemIDFlag) -> Bool

enum gameEItemIDFlag {
    Preview  // set on preview/paperdoll items created by CreatePreviewItemID()
}
```

### Identity selection

`ItemID` identifies a runtime item instance; `ItemID.GetTDBID(itemID)` identifies its TweakDB item record. Use the complete `ItemID` where an operation must distinguish runtime instances. Use the `TweakDBID` where a feature intentionally applies to every representation of the same item definition, including synthetic vendor items.

---

## UIInventoryItem

Higher-level item wrapper used by inventory UI widgets. Carries display metadata. Confirmed public API from script dump.

```swift
// Construction (vanilla)
static func Make(owner: wref<GameObject>, itemData: gameItemData, opt manager: wref<UIInventoryItemsManager>) -> UIInventoryItem
static func FromInventoryItemData(owner: wref<GameObject>, const itemData: ref<InventoryItemData>, opt manager: wref<UIInventoryItemsManager>) -> UIInventoryItem

// @addMethod by Equipment-EX (not in vanilla)
static func Make(owner: wref<GameObject>, slotID: TweakDBID, itemData: script_ref<InventoryItemData>, opt manager: wref<UIInventoryItemsManager>) -> ref<UIInventoryItem>

// Identity
func GetID() -> ItemID
func GetTweakDBID() -> TweakDBID
func GetItemData() -> wref<gameItemData>
func GetItemRecord() -> wref<Item_Record>
func GetOwner() -> wref<GameObject>

// Classification
func IsWeapon() -> Bool
func IsClothing() -> Bool
func IsCyberware() -> Bool
func IsPart() -> Bool
func IsProgram() -> Bool
func IsJunk() -> Bool
func IsHealingItem() -> Bool
func IsQuestItem() -> Bool
func IsIconic() -> Bool
func IsRecipe() -> Bool
func IsIllegal() -> Bool
func IsOfEquippableType() -> Bool

// State
func IsEquipped(opt force: Bool) -> Bool        // @wrapMethod by Equipment-EX to check outfit slot
func IsTransmogItem() -> Bool                   // @wrapMethod by Equipment-EX
func IsNew() -> Bool
func IsPlayerFavourite() -> Bool
func IsSellable() -> Bool
func IsCrafted() -> Bool
func IsBroken() -> Bool

// Display
func GetName() -> String
func GetIconPath() -> String
func GetDescription() -> String
func GetQuality() -> gamedataQuality
func GetQualityName() -> CName
func GetQualityText(opt type: RarityItemType) -> String
func GetItemType() -> gamedataItemType
func GetEquipmentArea() -> gamedataEquipmentArea
func GetQuantity(opt update: Bool) -> Int32
func GetWeight() -> Float
func GetSellPrice() -> Float
func GetBuyPrice() -> Float
func GetPrimaryStat() -> wref<UIInventoryItemStat>

// Equipment-EX @addField / @addMethod (not in vanilla)
// let m_slotID: TweakDBID
func IsForWardrobe() -> Bool   // true if m_slotID is set
```

**Key vanilla fields:**
```swift
var ID: ItemID                            // public — the item's ItemID
private var m_manager: wref<UIInventoryItemsManager>
private var m_itemRecord: wref<Item_Record>
private var m_itemTweakID: TweakDBID
private var m_slotID: TweakDBID          // @addField by Equipment-EX
```

---

## UIInventoryItemsManager

Manages `UIInventoryItem` lifecycle and equipped-state lookups for the UI layer.

```swift
// Construction (vanilla)
static func Make(player: wref<PlayerPuppet>, transactionSystem: ref<TransactionSystem>, uiScriptableSystem: wref<UIScriptableSystem>) -> ref<UIInventoryItemsManager>
// @wrapMethod by Equipment-EX to inject m_outfitSystem reference

// Queries
func IsItemEquipped(itemID: ItemID) -> Bool
func IsItemTransmog(itemID: ItemID) -> Bool     // @wrapMethod by Equipment-EX
func IsItemEquippedInSlot(itemID: ItemID, slotID: TweakDBID) -> Bool  // @addMethod by Equipment-EX

// Icon resolution
static func ResolveItemIconName(recordID: TweakDBID, record: wref<Item_Record>, opt manager: wref<UIInventoryItemsManager>) -> String
```

---

## UIInventoryScriptableSystem

Scriptable system providing cached inventory data to UI screens.

```swift
UIInventoryScriptableSystem.GetInstance(game: GameInstance) -> ref<UIInventoryScriptableSystem>

func GetInventoryItemsManager() -> ref<UIInventoryItemsManager>
func FlushFullscreenCache()
```

---

## UIScriptableSystem

General UI scriptable system, bound to data views.

```swift
UIScriptableSystem.GetInstance(game: GameInstance) -> ref<UIScriptableSystem>
```

---

## InventoryItemDisplayController

Widget controller for a single item slot in the equipment paperdoll panel. Confirmed from script dump.

**Base class:** `BaseButtonView`

```swift
// Vanilla Bind overloads (Equipment-EX @wrapMethod-s both)
public virtual func Bind(inventoryDataManager: InventoryDataManagerV2, equipmentArea: gamedataEquipmentArea, opt slotIndex: Int32, opt displayContext: ItemDisplayContext, opt setWardrobeOutfit: Bool, opt wardrobeOutfitIndex: Int32)
public virtual func Bind(inventoryScriptableSystem: UIInventoryScriptableSystem, equipmentArea: gamedataEquipmentArea, opt slotIndex: Int32, displayContext: ItemDisplayContext)

// Public state API
func SetLocked(value: Bool, visibleWhenLocked: Bool)
func SetTransmoged(value: Bool)
func SetWardrobeDisabled(value: Bool)
func SetItemCounterDisabled(value: Bool)
func IsLocked() -> Bool
func GetEquipmentArea() -> gamedataEquipmentArea
func GetItemID() -> ItemID
func GetItemData() -> InventoryItemData
func GetItemType() -> gamedataItemType
func GetUIInventoryItem() -> wref<UIInventoryItem>
func GetDisplayContext() -> ItemDisplayContext
func InvalidateQuantity()
func PlayEquipFeedback()
func PlayUpgradeFeedback()

// Virtual update methods (Equipment-EX @wrapMethod-s these)
protected virtual func NewUpdateEquipped(itemData: UIInventoryItem)
protected virtual func NewUpdateLocked(itemData: UIInventoryItem)
protected virtual func NewUpdateRequirements(itemData: UIInventoryItem)  // @wrapMethod: skips wardrobe items
protected virtual func RefreshUI()                                        // @wrapMethod: tweaks Outfit slot display
```

**Key protected fields (confirmed from dump):**
```swift
protected var m_equipmentArea: gamedataEquipmentArea  // default: Invalid
protected var m_isLocked: Bool
protected var m_visibleWhenLocked: Bool               // default: true
protected var m_wardrobeOutfitIndex: Int32            // default: -1; ≥0 = wardrobe outfit active
protected var m_slotID: TweakDBID
protected var m_slotIndex: Int32
protected var m_isTransmoged: Bool
protected var m_isWardrobeDisabled: Bool
protected var m_inventoryDataManager: InventoryDataManagerV2
protected var m_inventoryScriptableSystem: UIInventoryScriptableSystem
protected var m_uiInventoryItem: wref<UIInventoryItem>
protected var m_itemData: InventoryItemData
```

### Card identity by binding path

`NewUpdateEquipped(UIInventoryItem)` and `NewRefreshUI(UIInventoryItem)` provide a `UIInventoryItem`; obtain its identity with `itemData.GetID()`. Data-backed cards can instead run `RefreshUI()` with no `UIInventoryItem`. For those cards, obtain the bound identity with:

```redscript
let data = InventoryItemData.GetGameItemData(this.m_itemData);
if IsDefined(data) {
  let itemID = data.GetID();
}
```

Always reset custom card state on each applicable refresh because virtual grids reuse controller instances.

```swift
// @wrapMethod targets by Equipment-EX
public func Bind(inventoryDataManager: ref<InventoryDataManagerV2>, equipmentArea: gamedataEquipmentArea, ...)
public func Bind(inventoryScriptableSystem: ref<UIInventoryScriptableSystem>, ...)
protected func RefreshUI()                    // @wrapMethod: suppresses Outfit slot info when EX active
protected func NewUpdateRequirements(itemData: ref<UIInventoryItem>)  // @wrapMethod: skips wardrobe items

// Key fields (from @addField / vanilla)
let m_equipmentArea: gamedataEquipmentArea
let m_wardrobeOutfitIndex: Int32
let m_isLocked: Bool
let m_visibleWhenLocked: Bool
```

---

## ScriptableDataSource / ScriptableDataView

Data binding infrastructure used by virtual list/grid controllers.

```swift
// ScriptableDataSource — the backing store
class ScriptableDataSource {
    func AppendItem(item: ref<IScriptable>)
    func RemoveItem(item: ref<IScriptable>)
    func Clear()
    func Reset(items: array<ref<IScriptable>>)
    func GetArray() -> array<ref<IScriptable>>
}

// ScriptableDataView — filtered/sorted view over a source
class ScriptableDataView {
    func SetSource(source: ref<ScriptableDataSource>)
    func EnableSorting()
    func DisableSorting()
    func Sort()
    func Filter()
    // Override in subclass:
    func FilterItem(data: ref<IScriptable>) -> Bool
    func SortItem(left: ref<IScriptable>, right: ref<IScriptable>) -> Bool
}

// BackpackDataView — adds filter type and sort mode support
class BackpackDataView extends ScriptableDataView {
    func SetFilterType(filter: ItemFilterCategory)
    func SetSortMode(mode: ItemSortMode)
    func BindUIScriptableSystem(system: wref<UIScriptableSystem>)
}
```

---

## ItemFilterCategory / ItemSortMode

```swift
enum ItemFilterCategory {
    AllItems,
    Clothes,    // used as "Equipped" filter in EX wardrobe
    // ... others (Weapons, Cyberware, etc.)
}

enum ItemSortMode {
    Default,
    // ... others
}
```

---

## TweakDB Record Types (Clothing)

```swift
// Clothing_Record — a clothing item's TweakDB record
class Clothing_Record extends Item_Record {
    func GetID() -> TweakDBID
    func AppearanceName() -> CName
    func EntityName() -> CName
    func EquipArea() -> ref<EquipmentArea_Record>
    func GarmentOffset() -> Int32
    // placementSlots: array<TweakDBID> — accessed via TweakDBInterface.GetForeignKeyArray(id + t".placementSlots")
    // buyPrice: array<TweakDBID> — price modifier refs
    // tags: array<CName>
}

class Item_Record {
    func GetID() -> TweakDBID
    func DisplayName() -> CName       // localization key
    func ItemCategory() -> ref<ItemCategory_Record>
    func Tags() -> array<CName>
}

class ItemCategory_Record {
    func Type() -> gamedataItemCategory
}

enum gamedataItemCategory {
    Clothing,
    Weapon,
    Cyberware,
    // ...
}
```

---

## Stash

The player's stash container (storage chest). Implements `GameObject`.

```swift
// @addMethod by Equipment-EX to register with InventoryHelper on attach
protected cb func OnGameAttached() -> Bool

// Used via TransactionSystem — pass as entity parameter
TransactionSystem.GetItemList(stash: wref<Stash>, out items: array<wref<gameItemData>>) -> Bool
TransactionSystem.RemoveItem(stash: wref<Stash>, itemID: ItemID, quantity: Int32)
```
