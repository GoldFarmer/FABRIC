---
inclusion: manual
---

# redscript — Tool & Language Reference

redscript is the statically-typed scripting language and compiler for Cyberpunk 2077 mod scripting.

**Index:** [../cyberpunk-mods-index.md](../cyberpunk-mods-index.md)

## Toolchain

- Compiler: `scc.exe` — `Cyberpunk 2077\engine\tools\scc.exe`
- Runtime library: `scc_lib.dll` (same directory)
- Scripts load from: `Cyberpunk 2077\r6\scripts\` (all subdirectories, recursively)
- Vanilla script source (human-readable dump): `Cyberpunk 2077\tools\redmod\scripts\`

## Vanilla Script Dump — Directory Map

Use this to locate classes/functions for research. All paths relative to `tools\redmod\scripts\`.

```
core/
  data/
    string.script          — all string functions (StrLen, StrReplace, etc.)
    itemID.script          — ItemID struct static methods
    tweakDBID.script       — TDBID struct static methods
    tweakDB.script         — TweakDBInterface, TweakDBManager
    tweakDBRecords.script  — record base classes (Item_Record, Clothing_Record, etc.)
    engineTime.script      — EngineTime
    itemData.script        — InventoryItemData struct static accessors
  misc.script              — IScriptable base, enum utilities, IsNameValid, IsStringValid
  systems/
    gameInstance.script    — ALL GameInstance.Get*() accessors (authoritative)
    scriptableSystem.script — ScriptableSystem, ScriptableSystemsContainer base classes
    transactionSystem.script — TransactionSystem full API
    wardrobeSystem.script  — WardrobeSystem full API + gameWardrobeClothingSetIndex enum
    equipmentSystem.script — EquipmentSystem, EquipmentSystemPlayerData
    inventorySystem.script — InventoryManager
    statsSystem.script     — StatsSystem
    questSystem.script     — QuestsSystem, questQuestsSystem
    uiSystem.script        — UISystem
    blackboardSystem.script — BlackboardSystem
    delaySystem.script     — DelaySystem, DelayCallback
    playerSystem.script    — PlayerSystem
    timeSystem.script      — TimeSystem

cyberpunk/
  global/
    functions.script       — misc game-level free functions
    enums.script           — game-level enums
    struct.script          — game-level structs (ClothingSet, SSlotVisualInfo, etc.)
  UI/
    inventory/
      inventoryDataManagerV2.script — InventoryDataManagerV2 (clothing-relevant)
      InventoryItem.script          — UIInventoryItem, UIInventoryItemsManager
      inventoryItemDisplayController.script — InventoryItemDisplayController
      inventoryGameController.script — gameuiInventoryGameController, InventoryModes
    fullscreen/
      wardrobeDevice/
        wardrobeUIController.script — WardrobeUIGameController
  systems/
    equipmentSystem.script — EquipmentSystemPlayerData public methods
  player/                  — PlayerPuppet, player-related classes
  photomode/               — gameuiPhotoModeMenuController, PhotoModePlayerEntityComponent
```

**Search tip (PowerShell):**
```powershell
Get-ChildItem -Recurse "C:\Program Files (x86)\Steam\steamapps\common\Cyberpunk 2077\tools\redmod\scripts" -Filter "*.script" | Select-String "class MyClassName"
```

---

## Key Language Features

| Feature | Syntax / Example |
|---------|---------|
| Module declaration | `module MyMod` |
| Class definition | `class Foo extends Bar { }` |
| Abstract class | `abstract class Foo { }` |
| Persistent field | `private persistent let m_state: ref<MyState>` |
| Native binding | `native func Foo() -> RetType` / `native let field: Type` |
| Method patches | `@wrapMethod(TargetClass)` / `@replaceMethod` / `@addMethod` / `@addField` |
| Conditional compile | `@if(ModuleExists("Foo.Bar"))` |
| CName literal | `n"SomeName"` |
| TweakDB ref literal | `t"Path.To.Record"` |
| Resource ref literal | `r"base\path\to\file.inkwidget"` |
| String interpolation | `` s"Hello \(name)" `` |
| Null check | `IsDefined(ref)` |
| Casting | `ref as TargetType` |
| Weak reference | `wref<Foo>` — does not prevent GC |
| Script ref (out param) | `script_ref<array<ItemID>>` — pass array by ref |
| Optional param | `opt paramName: Type` |
| Default field value | `default m_field = true;` |

---

## Runtime integration model

redscript is the compiler and language layer through which script mods alter game behavior. At startup, the compiler discovers source under `r6\scripts`, resolves imports and modules, then applies annotations to the game's script metadata. `@wrapMethod` preserves the host method and lets the wrapper run before and/or after `wrappedMethod`; `@replaceMethod` substitutes the body; `@addMethod` and `@addField` extend an existing script-visible type. The observable behavior comes from the mod's annotated body, not from redscript itself. This distinction matters when reading a hook: the annotation selects the host flow, while the implementation explains the feature effect.

## Hook Annotation Boundary

`@wrapMethod` targets use a single, unqualified class identifier and the wrapper must be a
root-level function with the target method's exact signature. Call `wrappedMethod(...)` to retain
the original behavior.

- `@wrapMethod(EquipmentEx.OutfitSystem)` is invalid: the compiler reports
  `[INVALID_ANN_USE] invalid arguments for annotation`.
- Importing an external scripted class permits ordinary code to reference it, but does **not**
  necessarily make its unqualified name resolve for an annotation. In the installed runtime, an
  `@wrapMethod` probe against an imported external scripted class reports
  `[UNRESOLVED_REF] unresolved reference` at the annotation.
- The same unresolved-target result occurs when the wrapper source itself declares
  `module EquipmentEx`.
- `@if(ModuleExists("EquipmentEx"))` guards an absent module only; it does not defer annotation
  resolution or make an external scripted class a valid annotation target.

Treat direct wrapping of an external scripted class as unsupported in this runtime unless a
compiler-supported integration mechanism is documented. Prefer the target's public API, events,
or a supported indirect integration strategy.

*Evidence: REDscript annotation documentation and a 2026-08-03 minimal compiler probe.*

---

## ScriptableSystem Lifecycle

```swift
// Base class for game singletons registered in ScriptableSystemsContainer
import class ScriptableSystem extends IScriptableSystem {
    // Lifecycle — override these, do NOT call super unless explicitly needed
    private virtual func OnAttach()                                   // first init
    private virtual func OnDetach()                                   // cleanup
    private virtual func OnRestored(saveVersion: Int32, gameVersion: Int32)  // after load
    private virtual func OnPlayerAttach(request: ref<PlayerAttachRequest>)   // player ready
    private virtual func OnPlayerDetach(request: ref<PlayerDetachRequest>)   // player gone

    // Access game from within any ScriptableSystem method
    protected func GetGameInstance() -> GameInstance

    // Queue a request to self (thread-safe)
    public func QueueRequest(request: ref<ScriptableSystemRequest>)

    // Check if this system was restored from save (not first-time attached)
    public func WasRestored() -> Bool
}

// Obtain any ScriptableSystem by name
GameInstance.GetScriptableSystemsContainer(game).Get(n"FullClassName") as MyClass
```

---

## GameInstance Accessors (Complete List)

Confirmed from `core/systems/gameInstance.script`. All are `static` on `GameInstance`.

```swift
// Commonly used in wardrobe/inventory mods
GameInstance.GetTransactionSystem(game)          -> ref<TransactionSystem>
GameInstance.GetWardrobeSystem(game)             -> ref<WardrobeSystem>
GameInstance.GetPlayerSystem(game)               -> ref<PlayerSystem>
GameInstance.GetScriptableSystemsContainer(game) -> ref<ScriptableSystemsContainer>
GameInstance.GetBlackboardSystem(game)           -> ref<BlackboardSystem>
GameInstance.GetDelaySystem(game)                -> ref<DelaySystem>
GameInstance.GetQuestsSystem(game)               -> ref<QuestsSystem>
GameInstance.GetUISystem(game)                   -> ref<UISystem>
GameInstance.GetStatsSystem(game)                -> ref<StatsSystem>
GameInstance.GetStatPoolsSystem(game)            -> ref<StatPoolsSystem>
GameInstance.GetTimeSystem(game)                 -> ref<TimeSystem>
GameInstance.GetInventoryManager(game)           -> ref<InventoryManager>
GameInstance.GetTelemetrySystem(game)            -> ref<TelemetrySystem>

// Time
GameInstance.GetPlaythroughTime(game)            -> EngineTime
GameInstance.GetEngineTime(game)                 -> EngineTime
GameInstance.GetGameTime(game)                   -> GameTime

// Entity lookup
GameInstance.FindEntityByID(game, entityId)      -> ref<Entity>

// State
GameInstance.IsValid(game)                       -> Bool
GameInstance.IsRestoringState(game)              -> Bool
GameInstance.IsSavingLocked(game, out locks)     -> Bool

// Free function — get GameInstance from anywhere in script
GetGameInstance() -> GameInstance
```

---

## WardrobeSystem (Complete API)

Confirmed from `core/systems/wardrobeSystem.script`. Native class — not in script dump as `.script` only partially; full API confirmed from source.

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

// Clothing sets (vanilla wardrobe presets, Slot1–Slot7)
func GetClothingSets() -> array<ClothingSet>
func GetActiveClothingSet() -> ClothingSet
func GetActiveClothingSetIndex() -> gameWardrobeClothingSetIndex
func SetActiveClothingSetIndex(slotIndex: gameWardrobeClothingSetIndex)
func PushBackClothingSet(clothingSet: ClothingSet)
func DeleteClothingSet(setIndex: gameWardrobeClothingSetIndex)

// Helpers (static)
static func WardrobeClothingSetIndexToNumber(slotIndex: gameWardrobeClothingSetIndex) -> Int32
static func NumberToWardrobeClothingSetIndex(number: Int32) -> gameWardrobeClothingSetIndex

enum gameWardrobeClothingSetIndex { Slot1, Slot2, Slot3, Slot4, Slot5, Slot6, Slot7, COUNT, INVALID }

struct ClothingSet {
    let setID: gameWardrobeClothingSetIndex;
    let clothingList: array<SSlotVisualInfo>;
}

struct SSlotVisualInfo {
    let visualItem: ItemID;
    let isHidden: Bool;
}
```

---

## String Functions (Complete)

Confirmed from `core/data/string.script`.

```swift
// Length and search
StrLen(str: String) -> Int32
StrCmp(str: String, with: String, opt length: Int32, opt noCase: Bool) -> Int32  // <0, 0, >0
StrFindFirst(str: String, match: String) -> Int32   // -1 if not found
StrFindLast(str: String, match: String) -> Int32
StrContains(str: String, subStr: String) -> Bool
StrBeginsWith(str: String, match: String) -> Bool
StrEndsWith(str: String, match: String) -> Bool

// Extraction
StrMid(str: String, first: Int32, opt length: Int32) -> String
StrLeft(str: String, length: Int32) -> String
StrRight(str: String, length: Int32) -> String
StrBeforeFirst(str: String, match: String) -> String
StrBeforeLast(str: String, match: String) -> String
StrAfterFirst(str: String, match: String) -> String
StrAfterLast(str: String, match: String) -> String

// Splitting
StrSplitFirst(str: String, divider: String, out left: String, out right: String) -> Bool
StrSplitLast(str: String, divider: String, out left: String, out right: String) -> Bool
StrSplit(str: String, divider: String, opt includeEmpty: Bool) -> array<String>

// Transformation
StrReplace(str: String, match: String, with: String) -> String    // first occurrence
StrReplaceAll(str: String, match: String, with: String) -> String
StrUpper(str: String) -> String
StrLower(str: String) -> String
StrFrontToUpper(str: String) -> String
StrFrontToLower(str: String) -> String
StrChar(i: Int32) -> String   // character from ASCII code

// Conversion
NameToString(n: CName) -> String
StringToName(str: String) -> CName
FloatToString(value: Float) -> String
FloatToStringPrec(value: Float, precision: Int32) -> String
IntToString(value: Int32) -> String
StringToInt(value: String, opt defValue: Int32) -> Int32
StringToFloat(value: String, opt defValue: Float) -> Float
StringToUint64(value: String, opt defValue: Uint64) -> Uint64
BoolToString(value: Bool) -> String
StringToBool(s: String) -> Bool
IsStringNumber(value: String) -> Bool
NoTrailZeros(str: String) -> String
```

---

## TDBID / TweakDBID Functions

Confirmed from `core/data/tweakDBID.script`.

```swift
TDBID.Create(str: String) -> TweakDBID         // "Items.MyItem" -> TweakDBID
TDBID.IsValid(tdbID: TweakDBID) -> Bool
TDBID.None() -> TweakDBID
TDBID.ToNumber(tdbID: TweakDBID) -> Uint64     // for hash map keys
TDBID.ToStringDEBUG(tdbID: TweakDBID) -> String  // "Items.MyItem" — debug only, slow
TDBID.Prepend(out tdbID: TweakDBID, toPrepend: TweakDBID)
TDBID.Append(out tdbID: TweakDBID, toAppend: TweakDBID)

// Operators
a + b       // concatenates two TweakDBIDs (e.g. recordID + t".tags")
a == b / a != b
```

---

## ItemID Functions

Confirmed from `core/data/itemID.script`.

```swift
ItemID.IsValid(itemID: ItemID) -> Bool
ItemID.None() -> ItemID
ItemID.FromTDBID(tdbID: TweakDBID) -> ItemID          // new instance from record
ItemID.CreateQuery(tdbID: TweakDBID) -> ItemID         // query (non-unique) instance
ItemID.GetTDBID(itemID: ItemID) -> TweakDBID
ItemID.IsOfTDBID(itemID: ItemID, tdbID: TweakDBID) -> Bool
ItemID.IsQuery(itemID: ItemID) -> Bool
ItemID.HasFlag(itemID: ItemID, flag: gameEItemIDFlag) -> Bool
  // gameEItemIDFlag.Preview — set on preview/paperdoll items
ItemID.GetCombinedHash(itemID: ItemID) -> Uint64       // for inkHashMap / caching
ItemID.GetStructure(itemID: ItemID) -> gamedataItemStructure
ItemID.GetRngSeed(itemID: ItemID) -> Uint32

// Operators
a == b / a != b
```

---

## Enum Utilities

Confirmed from `core/misc.script`.

```swift
EnumGetMax(type: CName) -> Int64                         // n"gamedataEquipmentArea"
EnumGetMin(type: CName) -> Int64
EnumValueFromString(enumStr: String, enumValue: String) -> Int64
EnumValueFromName(enumName: CName, enumValue: CName) -> Int64
EnumValueToString(enumStr: String, enumValue: Int64) -> String
EnumValueToName(enumName: CName, enumValue: Int64) -> CName

// Validity
IsNameValid(n: CName) -> Bool    // false for n"" (empty CName)
IsStringValid(n: String) -> Bool // false for "" (empty string)
```

---

## IScriptable Base

```swift
// All script objects inherit from IScriptable
class IScriptable {
    func GetClassName() -> CName
    func IsA(className: CName) -> Bool
    func IsExactlyA(className: CName) -> Bool
}
```

---

## Compilation Notes

- All `.reds` files under `r6\scripts\` compile together; load order within a module is unspecified
- `@if(ModuleExists("Mod.Namespace"))` — conditional compilation; use for optional dependencies
- `@if(!ModuleExists("Mod.Namespace"))` — compile fallback/stub when mod is absent
- `persistent` fields survive save/load; non-persistent fields reset on game restart
- `wref<T>` — weak reference, does not prevent GC; check `IsDefined()` before use
- `s"interpolated \(expr)"` — string interpolation, compiles to concatenation
- `T"TweakDB.Path"` — TweakDBID literal (shorthand for `TDBID.Create("TweakDB.Path")`)
- `n"CName"` — CName literal
- `r"path\to\resource"` — ResRef literal

## No Runtime API

redscript itself exposes no runtime scripting API. All game-facing APIs come from the engine (accessed via `GameInstance`) or from mods like Codeware, ArchiveXL, Equipment-EX, etc.
