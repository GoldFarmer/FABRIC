---
inclusion: manual
---

# WEAVE — AutoTag & AutoTagDB Detail

Auto-tagging pipeline: scans wardrobe items, scores them against keyword/color/style databases, and assigns canonical tags to TweakDB automatically.

**Module:** `EquipmentEx`
**Dependencies:** `RedFileSystem`, `RedData.Json` (gracefully stubbed if absent)
**Up:** [mod-weave.md](mod-weave.md) | [../cyberpunk-mods-index.md](../cyberpunk-mods-index.md)

---

## AutoTagEngine

`AutoTagEngine extends ScriptableSystem` — orchestrates 3-phase async scanning (strip → score → apply) and exposes query API.

```swift
// Singleton access
static func GetInstance(game: GameInstance) -> ref<AutoTagEngine>

// State
func IsScanning() -> Bool
func IsRulesOutdated() -> Bool   // true if DB rules version newer than last scan
func IsPopupListening() -> Bool
func SetPopupListening(listening: Bool)  // when true: suppresses HUD messages, only fires UI events

// Tag queries (read cached results — O(n) scan of m_autoEntries)
func GetAutoTags(recordID: TweakDBID) -> ref<AutoTagEntry>   // null if not scanned
func IsAutoTag(recordID: TweakDBID, tag: CName) -> Bool

// Scan control
func StartScan(game: GameInstance, opt fullRescan: Bool)
  // fullRescan=false: incremental (only new wardrobe items)
  // fullRescan=true:  full rescan (strip old tags first)
  // auto-forces fullRescan if IsRulesOutdated() and config.autoTagAutoFullRescan==true
func ResetForWardrobeClear()   // clears all entries (called when wardrobe is cleared)
```

### Scan Events (fired via UISystem.QueueEvent)

| Event Class | Fields | Purpose |
|-------------|--------|---------|
| `AutoTagScanCompleted` | `totalItems`, `taggedItems`, `skippedItems: Int32` | Fired when scan finishes |
| `AutoTagScanProgress` | `processedItems`, `totalItems: Int32` | Fired at ~10% intervals during scoring |
| `AutoTagScanPhaseChanged` | `message: String` | Fired for every progress/status message |

### Internal Async Callbacks (not public API)

All extend `DelayCallback`. The engine schedules these via `DelaySystem` for frame-distributed work:

| Callback | Purpose |
|----------|---------|
| `AutoTagPostLoadCallback` | Post-load cleanup + Phase 3 apply |
| `AutoTagPreFilterCallback` | Phase 2a: quick native-tag pre-filter |
| `AutoTagScanCallback` | Phase 2: score a batch of items |
| `AutoTagDiscoveryCallback` | Incremental: find new (unscanned) items |
| `AutoTagPhaseCallback` | Generic phase dispatcher (strip/apply) |
| `AutoTagMessageCallback` | Drain HUD message queue |

### Scan Phases

1. **Strip (Phase 1)** — full rescan only: removes old auto tags from TweakDB in batches of 200
2. **Pre-filter (Phase 2a)** — batches of 2000: checks native tags, splits items into `toScore`/`toSkip`
3. **Score (Phase 2)** — batches of 5: calls `AutoTagScorer.ScoreSingleItem` per item
4. **Apply (Phase 3)** — batches of 20/50: writes new tags to TweakDB; skips items that already have native canonical tags

---

## AutoTagEntry

In-memory result for one scanned item. Stored in `AutoTagEngine.m_autoEntries`.

```swift
class AutoTagEntry {
    let recordID: TweakDBID
    let recordPath: String      // e.g. "Items.mod_jacket_color1"
    let displayName: String
    let styleTag: CName         // best Style match (or n"" if none)
    let factionTag: CName       // best Faction match
    let wealthTag: CName        // best Wealth match
    let reactionTag: CName      // best Reaction match
    let extraTags: array<CName> // extra rule matches (e.g. n"Mask", n"FullFace")
}
```

---

## AutoTagScorer

`AutoTagScorer abstract` — pure static scoring logic. Called by `AutoTagEngine` during Phase 2.

```swift
// Main entry point — returns a populated AutoTagEntry or null if no tags scored
static func ScoreSingleItem(recordPath: String, displayName: String, cache: ref<AutoTagDBCache>) -> ref<AutoTagEntry>

// Text utilities
static func NormalizeText(text: String) -> String
static func SplitWords(text: String) -> array<String>

// Scoring helpers
static func ScoreText(words: array<String>, cache: ref<AutoTagDBCache>) -> ...
static func ScoreColors(name: String, cache: ref<AutoTagDBCache>) -> ...
static func DetectColorSuffix(name: String) -> CName
static func GetPrimaryFactionForColor(color: CName) -> CName
static func DetectExtraTags(recordID: TweakDBID, cache: ref<AutoTagDBCache>) -> array<CName>
static func IsCanonicalTag(tag: CName) -> Bool
```

---

## AutoTagDB

`AutoTagDB abstract` — static keyword/color/rule database. All methods are static; no instance needed.

```swift
// Version — increment when rules change to trigger auto-rescan
static func GetRulesVersion() -> Int32

// Tag group accessors (used to build canonical tag cache in engine)
static func GetAllStyleTags() -> array<CName>
static func GetAllFactionTags() -> array<CName>
static func GetAllWealthTags() -> array<CName>
static func GetAllReactionTags() -> array<CName>
```

### Canonical Tag Lists (actual values from source)

- **Wealth:** `Rich`, `Simple`, `Poor`
- **Style:** `Biker`, `Casual`, `Corpo`, `Cowboy`, `Formal`, `Industrial`, `Military`, `Punk`, `Rocker`, `Samurai`, `Sports`, `Streetwear`, `Stylish`, `Tomboy`
- **Faction:** `Animals`, `Aldecaldos`, `Arasaka`, `Barghest`, `KangTao`, `Maelstrom`, `Militech`, `Moxies`, `NCPD`, `SixthStreet`, `Scavengers`, `TraumaTeam`, `TygerClaws`, `Valentinos`, `VoodooBoys`, `Wraiths`, `Biotechnica`, `Zetatech`
- **Reaction:** `Revealing`, `Intimidating`, `FearReaction`, `PositiveReaction`, `AnnoyedReaction`

### Entry Types

| Class | Key Fields | Purpose |
|-------|-----------|---------|
| `TagKeywordEntry` | `keyword: String`, `tag: CName`, `weight: Float` | Maps keyword → tag with scoring weight |
| `ColorFactionEntry` | `color: CName`, `faction: CName` | Color → primary faction |
| `ColorWeightEntry` | `color: CName`, `weight: Float` | Color scoring weight |
| `NegModEntry` | `keyword: String`, `negTag: CName` | Keyword that negates a tag |
| `ComboBonusEntry` | `tagA: CName`, `tagB: CName`, `bonus: Float` | Combo score bonus |
| `StyleContextEntry` | `style: CName`, `contexts: array<CName>` | Style-to-context mappings |
| `ExtraTagRuleEntry` | `condition: CName`, `tag: CName` | Conditional extra tag rule |

---

## AutoTagDBCache

`AutoTagDBCache` — one-shot snapshot of all `AutoTagDB` arrays, built once per scan to avoid repeated static array lookups.

```swift
static func Build() -> ref<AutoTagDBCache>
```

---

## Storage DTOs (auto_tags.json)

```swift
class AutoTagItemDTO {
    let id: String           // TweakDBID path
    let name: String         // display name cache
    let style: String
    let faction: String
    let wealth: String
    let reaction: String
    let extraTags: array<String>
}

class AutoTagDataDTO {
    let version: Int32
    let rulesVersion: Int32       // compared against AutoTagDB.GetRulesVersion()
    let items: array<ref<AutoTagItemDTO>>
    let scannedIds: array<String> // all processed IDs (including skipped), for incremental scan
}
```

`extraTags` results are also written to `custom_tags_auto.json` in `CustomTagDataDTO` format for `TagManagerSystem` to consume as ext custom tags.
