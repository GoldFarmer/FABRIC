---
inclusion: manual
---

# Codeware — UI Detail

Custom UI widget library: popup framework, button types, text input with full editing support, and resolution watching. All widgets extend inkWidget and work within the game's ink UI system.

**Modules:** `Codeware.UI`, `Codeware.UI.TextInput`
**Up:** [mod-codeware.md](mod-codeware.md) | [cyberpunk-mods-index.md](../cyberpunk-mods-index.md)

---

## inkCustomController

Base class for all Codeware custom widgets. Extends `inkLogicController` with lifecycle helpers.

```swift
class inkCustomController extends inkLogicController {
  // Override to initialize widget (called after ink binding)
  protected func OnCreate() -> Void
  protected func OnInitialize() -> Void
  protected func OnUninitialize() -> Void
}
```

---

## Popup System

### CustomPopup

`CustomPopup extends inkCustomController` — base for all popups.

```swift
func Show() -> Void
func Hide() -> Void
func IsVisible() -> Bool
func Close() -> Void

// Override to build popup content
protected func OnCreate() -> Void
```

### GenericMessageNotification extensions

`Codeware.UI.reds` extends vanilla generic notifications with `GenericMessageNotificationData.params`, `GenericMessageNotificationData.isInput`, `GenericMessageNotificationCloseData.input`, and `GenericMessageNotification.m_textInput`. Its `ShowInput` overload marks the data as input-enabled.

Codeware replaces the private `GenericMessageNotification.Close(result)` method. The replacement creates close data, copies text input when applicable, starts the outro animation, then invokes `m_data.token.TriggerCallback(m_closeData)` before returning. A post-`wrappedMethod(result)` wrapper of this base method therefore observes the requester after its close callback, subject to revalidation when Codeware changes.

### InMenuPopup

`InMenuPopup extends CustomPopup` — popup for use inside menus (wardrobe, inventory, etc.). Used by `TagEditorPopup` (WEAVE) and `OutfitMappingPopup` (Equipment-EX).

```swift
// Set popup title
func SetTitle(title: String) -> Void

// Focus management
func SetDefaultFocus() -> Void
```

### InGamePopup

`InGamePopup extends CustomPopup` — popup for use during gameplay (HUD overlay context).

### CustomPopupManager

`CustomPopupManager extends ScriptableService` — singleton that manages popup lifecycle and z-ordering.

```swift
// Obtain singleton
static func GetInstance(game: GameInstance) -> ref<CustomPopupManager>

func PushPopup(popup: ref<CustomPopup>) -> Void
func PopPopup(popup: ref<CustomPopup>) -> Void
func IsAnyPopupOpen() -> Bool
```

---

## Button Types

All extend `inkCustomController`.

| Class | Purpose |
|-------|---------|
| `PopupButton` | Standard button inside a popup |
| `SimpleButton` | Minimal styled button for general use |
| `HubLinkButton` | Button styled as a hub navigation link |

```swift
// Common button API (all button types)
func SetLabel(text: String) -> Void
func SetEnabled(enabled: Bool) -> Void
func IsEnabled() -> Bool

// Events (override in subclass or bind via callback)
protected func OnClick() -> Void
protected func OnHoverOver() -> Void
protected func OnHoverOut() -> Void
```

---

## ButtonHintsManager

`ButtonHintsManager extends ScriptableService` — manages the button hint bar shown at the bottom of menu screens.

```swift
static func GetInstance(game: GameInstance) -> ref<ButtonHintsManager>

func AddButtonHint(action: CName, label: String) -> Void
func RemoveButtonHint(action: CName) -> Void
func ClearButtonHints() -> Void
```

---

## TextInput

`TextInput extends inkCustomController` — single-line text input field with caret and selection support.

```swift
func GetText() -> String
func SetText(text: String) -> Void
func SetPlaceholder(text: String) -> Void
func SetMaxLength(max: Int32) -> Void
func Focus() -> Void
func Unfocus() -> Void
func IsFocused() -> Bool

// Events
protected func OnTextChanged(text: String) -> Void
protected func OnConfirm(text: String) -> Void
protected func OnCancel() -> Void
```

### HubTextInput

`HubTextInput extends TextInput` — `TextInput` styled for the hub/menu context.

---

## TextInput Internals (Codeware.UI.TextInput)

Internal controllers — not typically subclassed by mod authors.

| Class | Purpose |
|-------|---------|
| `Caret` | Blinking cursor position and rendering |
| `Selection` | Text selection range tracking |
| `TextFlow` | Text layout, wrapping, line management |
| `TextMeasurer` | Measures character widths for cursor math |
| `Viewport` | Scrollable view of text content |

---

## VirtualResolutionWatcher

`VirtualResolutionWatcher` — utility that fires a callback when the game's virtual resolution changes (e.g. on settings change). Useful for repositioning absolute-positioned popups.

```swift
func Register(target: ref<IScriptable>, callback: CName) -> Void
func Unregister() -> Void
```
