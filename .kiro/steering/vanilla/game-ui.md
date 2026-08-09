---
inclusion: manual
---

# Vanilla Game UI — API Reference

Vanilla ink UI controllers and systems used by wardrobe-screen integrations. All signatures are reverse-engineered from Equipment-EX source.

**Index:** [../cyberpunk-mods-index.md](../cyberpunk-mods-index.md)

**Related:** [game-systems.md](game-systems.md) | [game-inventory.md](game-inventory.md)

---

## Controller Hierarchy (ink)

```
inkGameController                  — base for fullscreen screens
  inkPuppetPreviewGameController   — adds paperdoll puppet preview
    WardrobeScreenController       — EX wardrobe screen (Equipment-EX)
  gameuiInGameMenuGameController   — in-game menu (inventory, wardrobe hub)
  gameuiInventoryGameController    — main inventory screen
  gameuiPhotoModeMenuController    — photo mode menu
  QuestTrackerGameController       — HUD quest tracker (used for startup notifs)

inkLogicController                 — sub-controller, not a full screen
  OutfitManagerController          — EX outfit list panel (Equipment-EX)
  InventoryItemDisplayController   — single equipment slot widget
  InventoryItemModeLogicController — inventory item mode sub-controller

worlduiIGameController             — world-space UI base
inkButtonController                — base for button widgets
inkVirtualCompoundItemController   — virtual list item
inkVirtualListController           — virtual scrolling list
inkVirtualGridController           — virtual scrolling grid
inkScrollController                — scroll area controller
```

---

## gameuiInventoryGameController

Main inventory screen controller. Equipment-EX heavily patches this to inject the wardrobe button and wardrobe screen overlay.

```swift
// @addField by Equipment-EX
private let m_outfitSystem: wref<OutfitSystem>
private let m_wardrobeButton: wref<inkWidget>
private let m_wardrobePopup: ref<inkGameNotificationToken>
private let m_wardrobeReady: Bool

// @wrapMethod hooks
protected cb func OnInitialize() -> Bool          // injects outfitSystem ref
protected cb func OnUninitialize() -> Bool        // cleans up wardrobe button callback
protected cb func OnBack(userData: ref<IScriptable>) -> Bool  // intercepts back to close wardrobe
protected cb func OnEquipmentClick(evt: ref<ItemDisplayClickEvent>) -> Bool  // handles Outfit slot unequip
protected cb func OnPuppetReady(sceneName: CName, puppet: ref<gamePuppet>) -> Bool  // equips puppet outfit

// @replaceMethod hooks
private final func SetupSetButton()               // replaces wardrobe set buttons with EX link
private final func RefreshEquippedWardrobeItems() // reports managed areas when outfit active

// @addMethod hooks (callable on the controller)
protected func ShowWardrobeScreen() -> Bool
protected func HideWardrobeScreen() -> Bool

// Vanilla fields relevant to wardrobe-screen integrations (inferred)
protected let m_buttonHintsController: wref<ButtonHints>
protected let m_itemModeLogicController: wref<InventoryItemModeLogicController>
protected let m_paperDollWidget: inkWidgetRef
protected let m_btnSets: inkWidgetRef
protected let m_wardrobeOutfitAreas: array<gamedataEquipmentArea>
protected let m_mode: InventoryModes
```

---

## gameuiInGameMenuGameController

The in-game pause menu that hosts the inventory paperdoll preview.

```swift
// @wrapMethod hooks by Equipment-EX
protected cb func OnInitialize() -> Bool
protected cb func OnPuppetReady(sceneName: CName, puppet: ref<gamePuppet>) -> Bool
  // when sceneName == n"inventory": equips puppet with current outfit
protected cb func OnEquipmentChanged(value: Variant) -> Bool
  // routes to OutfitSystem.UpdatePuppetFromBlackboard instead of vanilla handling

// Vanilla method used
func GetPuppet(sceneName: CName) -> ref<gamePuppet>
```

---

## InventoryItemModeLogicController

Sub-controller for the item detail panel within the inventory screen.

```swift
// @addField by Equipment-EX
public let m_isWardrobeScreen: Bool
private let m_outfitSystem: wref<OutfitSystem>

// @wrapMethod hooks
public final func SetupData(buttonHints, tooltipsManager, inventoryManager, player)
protected cb func OnItemDisplayClick(evt: ref<ItemDisplayClickEvent>) -> Bool
  // suppressed when m_isWardrobeScreen == true
protected cb func OnItemDisplayHoverOver(evt: ref<ItemDisplayHoverOverEvent>) -> Bool
  // suppressed when m_isWardrobeScreen == true
private final func SetInventoryItemButtonHintsHoverOver(...)
  // removes preview hint for clothing when outfit is active
private final func HandleItemClick(itemData, actionName, ...)
  // blocks preview action on clothing when outfit is active

// @replaceMethod hooks
private final func UpdateOutfitWardrobe(active: Bool, activeSetOverride: Int32)
  // injects EX wardrobe button instead of vanilla wardrobe slots
protected cb func OnWardrobeOutfitSlotClicked(e)  -> calls ShowWardrobeScreen()
protected cb func OnWardrobeOutfitSlotHoverOver(e) -> no-op

// Vanilla fields
protected let m_buttonHintsController: wref<ButtonHints>
protected let m_player: wref<PlayerPuppet>
protected let m_itemDropQueue: array<ItemModParams>
protected let m_isShown: Bool
let m_outfitWardrobeSpawned: Bool
```

---

## WardrobeUIGameController

Standalone wardrobe screen controller (opened from hub, not inventory). Equipment-EX fully replaces its `OnInitialize` and `OnBack` to spawn the EX wardrobe widget instead.

```swift
// @replaceMethod hooks
protected cb func OnInitialize() -> Bool   // hides vanilla panels, spawns EX wardrobe.inkwidget
protected cb func OnBack(userData: ref<IScriptable>) -> Bool  // fires OnWardrobeClose menu event
private final func CloseWardrobe()         // fires OnWardrobeClose menu event

// Vanilla fields used
protected let m_menuEventDispatcher: wref<inkMenuEventDispatcher>
protected let m_introAnimProxy: ref<inkAnimProxy>
```

---

## inkInventoryPuppetPreviewGameController

Preview puppet controller in the wardrobe/inventory screen.

```swift
// @wrapMethod by Equipment-EX
protected cb func OnInitialize() -> Bool
  // registers self with PaperdollHelper

// Fields used by Equipment-EX
let m_maxMousePointerOffset: Float
let m_mouseRotationSpeed: Float

// Methods called by WardrobeScreenController
func Rotate(offset: Float)
func QueueEvent(evt: ref<Event>)   // gameuiPuppetPreview_SetCameraSetupEvent
```

---

## gameuiPhotoModeMenuController

Photo mode menu. Equipment-EX injects an "Outfit" attribute option.

```swift
// @wrapMethod hooks
protected cb func OnInitialize() -> Bool
protected cb func OnAddMenuItem(label: String, attribute: Uint32, page: Uint32) -> Bool
  // appends Outfit option after Visibility on CharacterPage
protected cb func OnShow(reversedUI: Bool) -> Bool
  // populates Outfit selector with saved outfit names
protected cb func OnSetAttributeOptionEnabled(attribute: Uint32, enabled: Bool) -> Bool

// @addMethod
public func OnAttributeOptionSelected(attribute: Uint32, option: PhotoModeOptionSelectorData)
  // routes to OutfitSystem.EquipPuppetOutfit on the fakePuppet

// Key types
struct PhotoModeOptionSelectorData {
    let optionText: String;
    let optionData: Int32;
}

// Photo mode UI enum (Equipment-EX)
enum PhotoModeUI {
    CharacterPage       = 2,
    VisibilityAttribute = 27,
    ExpressionAttribute = 28,
    OutfitAttribute     = 3301,
    NoOutfitOption      = 3302,
    CurrentOutfitOption = 3303
}
```

---

## PhotoModePlayerEntityComponent

Component on the player entity in photo mode. Manages fake puppet setup.

```swift
// @wrapMethod hooks
private final func OnGameAttach()
private final func SetupInventory(isCurrentPlayerObjectCustomizable: Bool)
  // after vanilla: equips outfit on fakePuppet if active
protected cb func OnItemAddedToSlot(evt: ref<ItemAddedToSlot>) -> Bool
  // suppressed when outfit active (EX tracks loadingItems itself)

// Fields
let customizable: Bool
let fakePuppet: ref<gamePuppet>
let loadingItems: array<ItemID>
```

---

## WardrobeSetPreviewGameController

Preview controller used in wardrobe set notification popups.

```swift
// @wrapMethod hooks
protected cb func OnInitialize() -> Bool   // adds zoom camera setup
protected cb func OnPreviewInitialized() -> Bool
  // if notification popup + outfit active: equips outfit on puppet
public final func RestorePuppetEquipment()
  // after vanilla: re-equips outfit on puppet

// Fields
let m_isNotification: Bool
let m_data: WardrobeSetPreviewData   // contains m_data.itemID: ItemID
let cameraController: ref<gameuiPuppetPreviewCameraController>
```

---

## UI Event Types

Events fired via `UISystem.QueueEvent()` — any `inkGameController` with a matching `cb func` will receive them.

### Equipment-EX Custom Events

```swift
class OutfitUpdated extends Event {
    let isActive: Bool;
    let outfitName: CName;
}

class OutfitPartUpdated extends Event {
    let itemID: ItemID;
    let itemName: String;
    let slotID: TweakDBID;
    let slotName: String;
    let isEquipped: Bool;
}

class OutfitListUpdated extends Event {}     // outfit added/removed
class OutfitMappingUpdated extends Event {}  // slot assignment changed
class ItemSourceUpdated extends Event {}     // WardrobeItemSource changed
```

### Vanilla Events (used in hooks)

```swift
class ItemDisplayClickEvent extends Event {
    let uiInventoryItem: wref<UIInventoryItem>;
    let actionName: ref<inkActionName>;
    let display: wref<InventoryItemDisplayController>;  // on paperdoll click
}

class ItemDisplayHoverOverEvent extends Event {
    let uiInventoryItem: wref<UIInventoryItem>;
    let widget: wref<inkWidget>;
}

class ItemDisplayHoverOutEvent extends Event {}

class ItemDisplayHoldEvent extends Event {
    let uiInventoryItem: wref<UIInventoryItem>;
    let actionName: ref<inkActionName>;
}

class UIMenuNotificationEvent extends Event {
    let m_notificationType: UIMenuNotificationType;
}

enum UIMenuNotificationType {
    InventoryActionBlocked,
    // ...
}

class DropQueueUpdatedEvent extends Event {
    let m_dropQueue: array<ItemModParams>;
}

struct ItemModParams {
    let itemID: ItemID;
    let quantity: Int32;
}

class gameuiPuppetPreview_SetCameraSetupEvent extends Event {
    let setupIndex: Uint32;
}

enum InventoryPaperdollZoomArea {
    Default = 0,
    Head    = 1
}
```

---

## ButtonHints

Widget controller for the input hint bar at the bottom of menu screens.

```swift
// Obtain via SpawnFromExternal into button_hints widget, or passed from parent
// Used directly — not a singleton

func AddButtonHint(action: CName, label: String)
func RemoveButtonHint(action: CName)
func Hide()
func Show()
```

---

## gameuiTooltipsManager

Manages tooltip display in menu screens.

```swift
// Obtain via GetRootWidget().GetControllerByType(n"gameuiTooltipsManager")
func Setup(style: ETooltipsStyle)
func ShowTooltipAtWidget(tooltipID: CName, widget: wref<inkWidget>, data: ref<ATooltipData>, placement: gameuiETooltipPlacement)
func HideTooltips()

enum ETooltipsStyle { Menus, HUD }
enum gameuiETooltipPlacement { RightTop, LeftTop, /* ... */ }
```

---

## GenericMessageNotification

Static helper to show OK/Confirm/Cancel popups and text input dialogs.

```swift
static func Show(controller: ref<worlduiIGameController>, title: String, message: String, type: GenericMessageNotificationType) -> ref<inkGameNotificationToken>
static func Show(controller: ref<worlduiIGameController>, title: String, message: String, params: ref<inkTextParams>, type: GenericMessageNotificationType) -> ref<inkGameNotificationToken>
static func ShowInput(controller: ref<inkGameController>, title: String, message: String, type: GenericMessageNotificationType) -> ref<inkGameNotificationToken>

// Register on returned token to get result
token.RegisterListener(target: ref<IScriptable>, func: CName)

// Result data passed to listener
class GenericMessageNotificationCloseData extends inkGameNotificationData {
    let result: GenericMessageNotificationResult;
    let input: String;   // populated for ShowInput
}

enum GenericMessageNotificationResult { Confirm, Cancel }
enum GenericMessageNotificationType { OK, ConfirmCancel }
```

---

## PopupsManager

Global popup manager. Equipment-EX patches it to suppress specific wardrobe tutorial popups.

```swift
// @wrapMethod by Equipment-EX
private final func ShowTutorial()
  // blocks LocKey#86091 and LocKey#86092 tutorials

// Fields
let m_tutorialData: TutorialData   // m_tutorialData.message: String
```

---

## FilterRadioGroup / ItemCategoryFliterManager

Filter button group used in the wardrobe and inventory grids.

```swift
// FilterRadioGroup — inkRadioGroupController subclass
func SetData(filters: array<Int32>)
func Toggle(value: Int32)
func RegisterToCallback(n"OnValueChanged", target, func)
// Callback signature: func OnFilterChange(controller: wref<inkRadioGroupController>, selectedIndex: Int32)

// ItemCategoryFliterManager — manages available filter options
static func Make() -> ref<ItemCategoryFliterManager>
func Clear()
func AddFilter(category: ItemFilterCategory)
func GetAt(index: Int32) -> ItemFilterCategory
func GetIntFiltersList() -> array<Int32>
```

### Inheritance-boundary caveat

Wrapping a method on a vanilla data-view base class only observes subclass calls that delegate to
that implementation. A mod-owned subclass can implement its filtering method directly and bypass
the vanilla base method entirely. Verify the runtime call path before choosing a base-class filter
hook as a data boundary; a successful wrapper compilation alone is not evidence that it is used.

---

## inkScrollController

Scroll area controller. Equipment-EX `@addMethod`s a `SetScrollEnabled` helper.

```swift
// @addMethod by Equipment-EX
func SetScrollEnabled(enabled: Bool)

// Vanilla fields
let position: Float
let scrollDelta: Float
let contentSize: Vector2
let viewportSize: Vector2
let direction: inkEScrollDirection

// Vanilla methods
func SetScrollPosition(position: Float)
func UpdateScrollPositionFromScrollArea()
```
