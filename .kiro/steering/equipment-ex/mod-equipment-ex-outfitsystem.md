---
inclusion: manual
---

# Equipment-EX — OutfitSystem Detail

`OutfitSystem extends ScriptableSystem` is Equipment-EX's central outfit-management system.

**Module:** `EquipmentEx`
**Up:** [mod-equipment-ex.md](mod-equipment-ex.md) | [cyberpunk-mods-index.md](../cyberpunk-mods-index.md)

## OutfitSystem

```swift
static func GetInstance(game: GameInstance) -> ref<OutfitSystem>

func IsActive() -> Bool
func Activate()
func Deactivate()
func Reactivate()

func EquipItem(itemID: ItemID, opt slotID: TweakDBID) -> Bool
func UnequipItem(itemID: ItemID) -> Bool
func UnequipSlot(slotID: TweakDBID) -> Bool
func UnequipAll()

func IsEquipped(itemID: ItemID) -> Bool
func IsEquippable(itemID: ItemID) -> Bool
func GetItemSlot(itemID: ItemID) -> TweakDBID

func HasOutfit(name: CName) -> Bool
func LoadOutfit(name: CName) -> Bool
func SaveOutfit(name: CName, opt overwrite: Bool) -> Bool
func AddOutfit(name: CName, parts: array<ref<OutfitPart>>, opt overwrite: Bool) -> Bool
func CopyOutfit(name: CName, from: CName) -> Bool
func DeleteOutfit(name: CName) -> Bool
func DeleteAllOutfits() -> Bool
func GetOutfits() -> array<CName>
func GetOutfitParts(name: CName) -> array<ref<OutfitPart>>

func AssignItem(itemID: ItemID, slotID: TweakDBID) -> Bool
```

## EquipmentEx global facade (`EquipmentEx.Global.reds`)

```swift
static func Version() -> String
static func Activate(game: GameInstance)
static func Reactivate(game: GameInstance)
static func Deactivate(game: GameInstance)

static func EquipItem(game: GameInstance, itemID: TweakDBID)
static func EquipItem(game: GameInstance, itemID: TweakDBID, slotID: TweakDBID)
static func UnequipItem(game: GameInstance, itemID: TweakDBID)
static func UnequipSlot(game: GameInstance, slotID: TweakDBID)
static func UnequipAll(game: GameInstance)

static func LoadOutfit(game: GameInstance, name: CName)
static func SaveOutfit(game: GameInstance, name: String)
static func CopyOutfit(game: GameInstance, name: String, from: CName)
static func DeleteOutfit(game: GameInstance, name: CName)
static func DeleteAllOutfits(game: GameInstance)
```

## Runtime behavior (Equipment-EX)

Equipment-EX converts non-empty vanilla `WardrobeSystem` sets during first use into named `WARDROBE SET N` outfits, then uses `OutfitSystem` for its custom named-outfit workflow.

- An outfit key is its persistent `CName` name (`OutfitSet.m_name`); `GetOutfits()` returns names alphabetically.
- `OutfitPart` stores an `ItemID` and `TweakDBID` slot. `GetItemHash()` uses `ItemID.GetCombinedHash()`. `ItemID.GetTDBID()` provides the item-record identity when an integration intentionally aggregates all runtime representations of one item definition.
- `SaveOutfit` creates a new `OutfitSet` for a new name, or replaces an existing set only when `overwrite` is true. `AddOutfit` follows the same create/overwrite model; `DeleteOutfit` removes the named set.
- Normal save/delete mutations do not dispatch `OutfitListUpdated`. `OutfitUpdated` and `OutfitPartUpdated` describe current visual state. `DeleteAllOutfits` calls `TriggerOutfitListEvent()`.
