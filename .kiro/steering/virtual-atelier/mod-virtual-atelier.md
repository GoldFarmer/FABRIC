---
inclusion: manual
---

# Virtual Atelier — Namespace Index

Virtual Atelier 1.4.8 provides an in-game browser storefront for mod-defined shops. It builds a temporary vendor-style inventory from registered items, supports cart purchases and virtual try-on, and adds a store-list UI with search, categories, bookmarks, and new-store indicators.

**Package source:** `r6\scripts\virtual-atelier-full\`
**Package assets:** `archive\pc\mod\VirtualAtelier.archive` and `VirtualAtelier.archive.xl`
**Index:** [cyberpunk-mods-index.md](../cyberpunk-mods-index.md)

## Namespaces / Areas

| Area / module | Key classes | Purpose |
|---|---|---|
| `VirtualAtelier.Core` | `VirtualShopRegistration`, `VirtualShop`, `VirtualStoreSearchCriteria`, `VirtualAtelierCart` | Store registration DTOs, search data, and the in-memory cart |
| `VirtualAtelier.Systems` | `VirtualAtelierStoresManager`, `VirtualAtelierCartManager`, `VirtualAtelierPreviewManager` | Store discovery, purchase state, and temporary preview equipment |
| Store-list UI | `AtelierStoresListController`, `AtelierStoresDataView`, `SearchEngineComponent` | Browser landing page, categories, bookmarks, and cross-store search |
| Virtual-store UI | `VirtualStoreController`, `VirtualStoreDataView`, `VirtualStoreItemController` | Per-store vendor view, item grid, cart state, ownership/quantity indicators |
| Vendor preview | `FullscreenVendorGameController`, `WardrobeSetPreviewGameController` patches | Temporary try-on and preview cleanup |
| Browser setup | `BrowserController`, `BrowserGameController`, `ComputerInkGameController` patches | Adds the Atelier site/tab to game computers |
| Compatibility | `VendorPreview.Config.VirtualAtelierConfig` | ModSettings options and Equipment-EX-aware placement slots |

## Store registration API

`VirtualAtelierStoresManager.BuildStoresList()` clears the manager's runtime list, constructs a `VirtualShopRegistration`, then queues it through `UISystem`. Store-provider mods respond to that registration event and call `AddStore`.

```swift
public func AddStore(
  storeID: CName,
  storeName: String,
  items: array<String>,
  prices: array<Int32>,
  atlasResource: ResRef,
  texturePart: CName,
  opt qualities: array<String>,
  opt quantities: array<Int32>
) -> Void
```

`items`, `prices`, and optional `qualities`/`quantities` are parallel arrays. Each item string is converted with `TDBID.Create`; an invalid item ID is skipped when stock is built. `storeID` is also the persistent bookmark identity, so it must be stable across releases. `atlasResource` and `texturePart` supply the storefront tile image.

`VirtualShop` retains the registered values and additionally receives runtime `isBookmarked`, `isNew`, and derived `categories` fields. `VirtualStoreCategory` is `AllItems`, `Clothes`, `Weapons`, `Cyberware`, `Consumables`, or `Other`.

## Store manager

Get the singleton with:

```swift
let stores = VirtualAtelierStoresManager.GetInstance(gameInstance);
```

| Purpose | Methods |
|---|---|
| Store state | `GetStores`, `GetStoresCount`, `SetCurrentStore`, `GetCurrentStore` |
| Build/metadata | `BuildStoresList`, `BuildCategories`, `GetCategories`, `RefreshNewLabels` |
| Bookmarks | `AddBookmark`, `RemoveBookmark`, `IsBookmarked`, `RefreshPersistedBookmarks` |
| Search | `SearchStores`, `BeginSearchStores`, `ContinueSearchStores`, `CancelSearchStores`, `GetSearchResults`, `ClearSearchResults` |

Search matches localized item names plus primary type filters and secondary garment-slot/new-wardrobe filters. `BeginSearchStores`/`ContinueSearchStores(token, batchSize)` is the incremental version used to avoid a long UI-frame stall; `ContinueSearchStores` returns `true` when finished or when its token is stale.

## Cart and purchasing

`VirtualAtelierCartManager` is a `ScriptableSystem`; obtain it with `GetInstance(gi)`. It receives materialized `VirtualStockItem` records from the storefront, stores selected entries in `VirtualAtelierCart`, checks player money, and executes purchases through the game's `TransactionSystem`.

| Purpose | Methods |
|---|---|
| Cart mutation | `AddToCart`, `RemoveFromCart`, `ClearCart`, `GetCurrentGoods`, `GetCartSize` |
| Quantity / affordability | `GetBuyableAmountForStock`, `PlayerHasEnoughMoneyForStock`, `GetAddedStockQuantity` |
| Purchase/balances | `PurchaseGoods`, `SyncCurrentBalances`, `GetCurrentPlayerMoney`, `GetCurrentGoodsPrice`, `GetCurrentGoodsQuantity` |
| Ownership display | `SaveOwnedItems`, `SaveWardrobeItems`, `IsItemOwned`, `IsItemInWardrobe` |

Cart identity is `VirtualStockItem.stockKey` when populated; otherwise it falls back to `ItemID.GetCombinedHash(itemID) + quantity`. The same TweakDB item offered by distinct stores is only distinct if the materialization path assigns distinct stock keys.

## Preview and Equipment-EX compatibility

`VirtualAtelierPreviewManager` temporarily gives an item to the preview puppet, equips it in the item's placement slot, and later removes it. Its public lifecycle is `InitializePuppet`, `InitializeCompatibilityHelper`, `TogglePreviewItem`, `ResetGarment`, and `SetPreviewState`.

`Compat.reds` adds `gameuiMenuGameController.GetAtelierPlacementSlot(itemId)`. Without Equipment-EX it delegates to `EquipmentSystem.GetPlacementSlot`. When `EquipmentEx` is present and active, it uses `OutfitSystem.GetItemSlot` for non-weapons.

## Base-game patches and injected fields

Virtual Atelier wraps or extends: `gameuiInGameMenuGameController`, `BrowserController`, `BrowserGameController`, `ComputerInkGameController`, `ComputerControllerPS`, `ComputerMenuButtonController`, `FullscreenVendorGameController`, `WardrobeSetPreviewGameController`, `InventoryItemDisplayController`, `ItemQuantityPickerController`, `ItemTooltipBottomModule`, `MinimalItemTooltipData`, `InteractiveDevice`, and `PlayerPuppet`.

Notable injected fields include `isVirtualItem` and `virtualStockItem` on `gameItemData`; cart/owned/quantity indicator widgets and manager references on `InventoryItemDisplayController`; `virtualStore` on `VendorPanelData`; and preview state/manager fields on the fullscreen-vendor and wardrobe-preview controllers.

## Item identity and tooltips

Virtual-store cards are data-backed `InventoryItemDisplayController` instances. During
`RefreshUI()`, the current `InventoryItemData` can be converted to `gameItemData` with
`InventoryItemData.GetGameItemData(this.m_itemData)`; its `GetID()` returns the synthetic store
`ItemID`. `ItemID.GetTDBID()` resolves that ID to the registered item record, matching the record
identity used by ownership and wardrobe checks.

`VirtualStoreController.ShowTooltipsForItemController` creates `InventoryTooltipData`, sets
`displayContext` to `Vendor`, sets `isVirtualItem`, retains the inspected `InventoryItemData`, and
shows the standard `itemTooltip`. Consumers of the standard tooltip receive `InventoryTooltipData`
and can use its `itemID` for item-identity queries.

## Game integration flows

| Trigger / host flow | Why it is intercepted | What Virtual Atelier does | Result |
|---|---|---|---|
| The in-game menu initializes (`gameuiInGameMenuGameController.OnInitialize`) | Registered stores must be collected after the player/menu runtime exists | Calls `VirtualAtelierStoresManager.BuildStoresList()`, which clears transient store state and queues `VirtualShopRegistration` through `UISystem` | Store-provider mods receive the registration event and rebuild the available storefront list for the session |
| A player opens a computer's menu or browser (`ComputerControllerPS`, `ComputerInkGameController`, `ComputerMenuButtonController`, `BrowserController`, `BrowserGameController`, `WebPage`) | The game's computer browser has no Atelier destination | Adds an Atelier menu button and site listener, spawns the external store-list widget when its page appears, and disposes the listener when the browser closes | Computers expose the Virtual Atelier storefront as a browser destination; guards defer to Browser Extension when that module exists |
| A registered store is opened as the special `VirtualVendor` (`FullscreenVendorGameController`, `InteractiveDevice`, `VendorPanelData`) | Store inventory is assembled from mod registration data rather than a world vendor | Initializes cart/preview managers, detects the virtual vendor, intercepts device exit while the view is active, and handles the close event | Registered shops reuse the familiar fullscreen vendor UI without requiring a physical vendor NPC |
| The player enters preview mode, clicks/hover items, leaves the vendor, or the controller uninitializes (`FullscreenVendorGameController`) | Try-on needs temporary equipment that must never leak into normal inventory state | Opens a preview picker, routes item clicks to preview equipment, refreshes equipped labels, then resets preview state and removes temporary items on exit | Items can be tried on safely and the player/preview puppet is restored on close |
| Wardrobe preview receives mouse, camera, or picker events (`WardrobeSetPreviewGameController`) | Vendor try-on needs a controllable preview puppet and camera | Marks the vendor-player display context as virtual, routes press/release/axis input to the preview interaction, and removes temporary preview garments during uninitialization | The garment preview is interactive while active and cleans itself up reliably |
| A virtual store item card initializes, refreshes, or receives a state-refresh event (`InventoryItemDisplayController`) | Vanilla cards do not know virtual stock, cart quantity, affordability, ownership, or temporary preview equipment | Creates indicator widgets once; on every refresh reads `virtualStockItem`, cart manager, and preview manager to update their visibility/text | The vendor grid shows cart, quantity, owned, affordability, and preview-equipped state, including after virtual-grid reuse |
| Quantity picker or tooltip data is built (`ItemQuantityPickerController`, `ItemTooltipBottomModule`, `MinimalItemTooltipData`, `InventoryTooltipData`) | A virtual item has a supplied storefront price and needs virtual-item presentation | Supplies the virtual price and carries an `isVirtualItem` flag into tooltip presentation | Purchase UI and tooltips describe the store item rather than treating it as ordinary owned inventory |

Supporting injections carry data between these flows: `BackpackMainGameController` retains the preview-popup token, `VendorInventoryItemData.NotInWardrobe` marks stock that has no wardrobe entry, and `ItemDisplayUtils.AsyncSpawnCommonSlotControllerVA` loads Virtual Atelier's external slot widget. `gameuiMenuGameController.GetAtelierPlacementSlot` selects the placement slot used by the preview manager; its Equipment-EX guard is described above.

## Configuration

`VirtualAtelierConfig.Get()` returns a fresh config object backed by ModSettings runtime properties.

| Property | Default | Notes |
|---|---:|---|
| `instantBuy` | `false` | Available only when `AtelierDelivery` is absent |
| `enableDangerZoneChecker` | `false` | Purchase restriction in dangerous contexts |
| `enableDuplicatesChecker` | `false` | Owned-item duplicate checks |
| `enableStorePagination` | `true` | Enables paged store inventory |
| `paginationPageSize` | `200` | 50–500, step 25; dependent on pagination |

When `AtelierDelivery` exists, the configuration class omits `instantBuy` but retains the other settings.
