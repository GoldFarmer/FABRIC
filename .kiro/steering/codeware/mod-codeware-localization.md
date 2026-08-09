---
inclusion: manual
---

# Codeware — Localization Detail

Provides a mod-friendly localization system layered on top of the game's built-in localization. Mods register a `ModLocalizationProvider` subclass; the system resolves keys at runtime based on player gender and active language.

**Module:** `Codeware.Localization`
**Up:** [mod-codeware.md](mod-codeware.md) | [cyberpunk-mods-index.md](../cyberpunk-mods-index.md)

---

## LocalizationSystem

`LocalizationSystem extends ScriptableSystem` — central registry. You don't call this directly; it discovers registered providers automatically.

Providers are registered by the game scanning for `ModLocalizationProvider` subclasses at startup.

---

## ModLocalizationProvider

`ModLocalizationProvider extends ScriptableSystem` — base class for a dependent mod's localization provider. Subclass it to supply that mod's localized entries.

```swift
// Override to return a ModLocalizationPackage for the given language code
func GetPackage(language: CName) -> ref<ModLocalizationPackage>

// Optional: override to declare supported languages
func GetSupportedLanguages() -> array<CName>
```

### WEAVE Usage Example

```swift
// WEAVE's provider (from LocalizationProvider.reds)
public class LocalizationProvider extends ModLocalizationProvider {
  // module: EquipmentEx.Localization
}
```

---

## ModLocalizationPackage

`ModLocalizationPackage abstract` — holds all localization entries for one language. Subclass per language.

```swift
// Override to return the array of LocalizationEntry for this package
func GetEntries() -> array<ref<LocalizationEntry>>
```

---

## LocalizationEntry (and Subclasses)

`LocalizationEntry abstract` — a single key→value mapping.

| Class | Use Case |
|-------|---------|
| `GenderNeutralEntry` | Same string for all genders |
| `GenderSensitiveEntry` | Different strings for male/female player |

```swift
abstract class LocalizationEntry {
  func GetKey() -> String        // the localization key (e.g. "UI-Settings-MyLabel")
  func GetValue() -> String      // resolved value for current context
}

class GenderNeutralEntry extends LocalizationEntry {
  // constructor: key + single value string
}

class GenderSensitiveEntry extends LocalizationEntry {
  // constructor: key + maleValue + femaleValue
}
```

---

## Supporting Enums

```swift
enum PlayerGender {
  Male   = 0,
  Female = 1
}

enum EntryType {
  GenderNeutral   = 0,
  GenderSensitive = 1
}
```

---

## Usage Pattern

```swift
// 1. Define entries for a language
class MyMod_EN extends ModLocalizationPackage {
  func GetEntries() -> array<ref<LocalizationEntry>> {
    return [
      new GenderNeutralEntry("UI-MyMod-Title", "My Mod Title"),
      new GenderSensitiveEntry("UI-MyMod-Greeting", "Hey man", "Hey girl")
    ];
  }
}

// 2. Define provider
class MyMod_LocalizationProvider extends ModLocalizationProvider {
  func GetPackage(language: CName) -> ref<ModLocalizationPackage> {
    if Equals(language, n"en-us") { return new MyMod_EN(); }
    return null;  // fallback to default
  }
}
```
