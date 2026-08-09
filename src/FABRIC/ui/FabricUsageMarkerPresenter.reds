module FABRIC

@addField(InventoryItemDisplayController)
private let m_fabricUsageMarker: wref<inkImage>;

@addField(InventoryItemDisplayController)
private let m_fabricUsageCount: wref<inkText>;

/**
 * Owns FABRIC's reusable card marker presentation while host controllers own the widgets.
 *
 * Event hooks delegate here after the native card has bound its item. This presenter only queries
 * FabricService O(1) indexes and resets visibility on every binding for virtualized-card safety.
 */
public abstract class FabricUsageMarkerPresenter {
  /**
   * Initializes one wardrobe card's marker after the host layout has been created.
   * @param controller The host item-card controller.
   * @return None.
   * @errors An unavailable service or inactive session leaves the card unchanged.
   */
  public static func OnCardInitialized(controller: ref<InventoryItemDisplayController>) -> Void {
    let service = FabricService.Get();
    if IsDefined(service) && service.IsWardrobeUiActive() { FabricUsageMarkerPresenter.Initialize(controller); }
  }

  /**
   * Refreshes an owned card in the active wardrobe session or clears stale state.
   * @param controller The host item-card controller.
   * @param itemData The bound item, or null for a recycled card.
   * @return None.
   * @errors An inactive session hides existing FABRIC presentation.
   */
  public static func RefreshWardrobeOwnedCard(controller: ref<InventoryItemDisplayController>,
    itemData: ref<UIInventoryItem>) -> Void {
    let service = FabricService.Get();
    if !IsDefined(service) || !service.IsWardrobeUiActive() {
      FabricUsageMarkerPresenter.SetCount(controller, 0);
      return;
    }
    FabricUsageMarkerPresenter.RefreshOwnedCard(controller, itemData);
  }

  /**
   * Refreshes an owned backpack or storage card using its host binding as presentation scope.
   * @param controller The host item-card controller.
   * @param itemData The bound item, or null for a recycled card.
   * @return None.
   * @errors A null binding hides existing FABRIC presentation.
   */
  public static func RefreshOwnedCard(controller: ref<InventoryItemDisplayController>,
    itemData: ref<UIInventoryItem>) -> Void {
    if IsDefined(itemData) {
      FabricUsageMarkerPresenter.Refresh(controller, itemData.GetID(), false);
    } else {
      FabricUsageMarkerPresenter.SetCount(controller, 0);
    }
  }

  /**
   * Refreshes a catalog-backed card when its host binding exposes an item identity.
   * @param controller The host item-card controller.
   * @return None.
   * @errors Missing data hides existing FABRIC presentation.
   */
  public static func RefreshCatalogCard(controller: ref<InventoryItemDisplayController>) -> Void {
    let data: ref<gameItemData>;
    let service = FabricService.Get();
    if !IsDefined(service) { return; }
    if !IsDefined(controller.m_uiInventoryItem) {
      data = InventoryItemData.GetGameItemData(controller.m_itemData);
      if IsDefined(data) { FabricUsageMarkerPresenter.Refresh(controller, data.GetID(), true); }
      else { FabricUsageMarkerPresenter.SetCount(controller, 0); }
    }
  }

  /**
   * Requests the host-compatible refresh for an active wardrobe card after a rebuild.
   * @param controller The host item-card controller.
   * @return None.
   * @errors Missing bound items or inactive sessions leave the card unchanged.
   */
  public static func RefreshAfterIndexUpdate(controller: ref<InventoryItemDisplayController>) -> Void {
    let service = FabricService.Get();
    if IsDefined(service) && service.IsWardrobeUiActive() && IsDefined(controller.m_uiInventoryItem) {
      controller.NewUpdateEquipped(controller.m_uiInventoryItem);
    }
  }

  /**
   * Creates the marker and count once in the host card's stable item container.
   * @param controller The host item-card controller.
   * @return None.
   * @errors Missing host containers leave widgets unattached.
   */
  private static func Initialize(controller: ref<InventoryItemDisplayController>) -> Void {
    let root = inkWidgetRef.Get(controller.m_widgetWrapper) as inkCompoundWidget;
    let container: ref<inkCompoundWidget>;
    let marker: ref<inkImage>;
    let count: ref<inkText>;
    if IsDefined(controller.m_fabricUsageMarker) || !IsDefined(root) { return; }
    container = root.GetWidgetByPathName(n"container") as inkCompoundWidget;
    if !IsDefined(container) { return; }
    marker = new inkImage();
    marker.SetName(n"fabricUsageMarker");
    marker.SetAtlasResource(r"base\\gameplay\\gui\\widgets\\mappins\\atlas_gameplay_loop_bordered.inkatlas");
    marker.SetSize(new Vector2(21.0, 21.0));
    marker.SetVisible(false);
    marker.Reparent(container);
    controller.m_fabricUsageMarker = marker;
    count = new inkText();
    count.SetName(n"fabricUsageCount");
    count.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
    count.SetFontStyle(n"Semi-Bold");
    count.SetFontSize(24);
    count.SetFitToContent(true);
    count.SetVisible(false);
    count.Reparent(container);
    controller.m_fabricUsageCount = count;
    FabricUsageMarkerPresenter.ApplyStyle(controller);
  }

  /**
   * Resolves an O(1) exact or record count and renders it on one initialized card.
   * @param controller The host item-card controller.
   * @param itemID The host-provided card identity.
   * @param useRecordLookup True for catalog cards; false for owned cards.
   * @return None.
   * @errors Missing services or widgets safely hide FABRIC presentation.
   */
  private static func Refresh(controller: ref<InventoryItemDisplayController>, itemID: ItemID,
    useRecordLookup: Bool) -> Void {
    let service = FabricService.Get();
    let count: Int32;
    if IsDefined(service) && !IsDefined(controller.m_fabricUsageMarker) {
      FabricUsageMarkerPresenter.Initialize(controller);
    }
    if !IsDefined(controller.m_fabricUsageMarker) || !IsDefined(controller.m_fabricUsageCount) { return; }
    FabricUsageMarkerPresenter.ApplyStyle(controller);
    if IsDefined(service) {
      count = useRecordLookup ? service.GetRecordUsageCount(itemID) : service.GetUsageCount(itemID);
    }
    FabricUsageMarkerPresenter.SetCount(controller, count);
  }

  /**
   * Applies active style and mirrored corner layout without changing marker visibility.
   * @param controller The host item-card controller with FABRIC widgets.
   * @return None.
   * @errors Missing widgets leave the card unchanged.
   */
  private static func ApplyStyle(controller: ref<InventoryItemDisplayController>) -> Void {
    let corner = FabricMarkerSettings.GetCorner();
    let texturePart = FabricMarkerStyle.TexturePartFor(FabricMarkerSettings.GetIcon());
    let tint = FabricMarkerStyle.ColorFor(FabricMarkerSettings.GetColor());
    if !IsDefined(controller.m_fabricUsageMarker) || !IsDefined(controller.m_fabricUsageCount) { return; }
    controller.m_fabricUsageMarker.SetTexturePart(texturePart);
    controller.m_fabricUsageMarker.SetTintColor(tint);
    controller.m_fabricUsageCount.SetTintColor(tint);
    switch corner {
      case FabricMarkerCorner.TopRight:
        controller.m_fabricUsageMarker.SetHAlign(inkEHorizontalAlign.Right);
        controller.m_fabricUsageCount.SetHAlign(inkEHorizontalAlign.Right);
        controller.m_fabricUsageMarker.SetVAlign(inkEVerticalAlign.Top);
        controller.m_fabricUsageCount.SetVAlign(inkEVerticalAlign.Top);
        controller.m_fabricUsageMarker.SetMargin(0.0, 12.0, 12.0, 0.0);
        controller.m_fabricUsageCount.SetMargin(0.0, 8.0, 36.0, 0.0);
        break;
      case FabricMarkerCorner.BottomLeft:
        controller.m_fabricUsageMarker.SetHAlign(inkEHorizontalAlign.Left);
        controller.m_fabricUsageCount.SetHAlign(inkEHorizontalAlign.Left);
        controller.m_fabricUsageMarker.SetVAlign(inkEVerticalAlign.Bottom);
        controller.m_fabricUsageCount.SetVAlign(inkEVerticalAlign.Bottom);
        controller.m_fabricUsageMarker.SetMargin(12.0, 0.0, 0.0, 12.0);
        controller.m_fabricUsageCount.SetMargin(36.0, 0.0, 0.0, 8.0);
        break;
      case FabricMarkerCorner.BottomRight:
        controller.m_fabricUsageMarker.SetHAlign(inkEHorizontalAlign.Right);
        controller.m_fabricUsageCount.SetHAlign(inkEHorizontalAlign.Right);
        controller.m_fabricUsageMarker.SetVAlign(inkEVerticalAlign.Bottom);
        controller.m_fabricUsageCount.SetVAlign(inkEVerticalAlign.Bottom);
        controller.m_fabricUsageMarker.SetMargin(0.0, 0.0, 12.0, 12.0);
        controller.m_fabricUsageCount.SetMargin(0.0, 0.0, 36.0, 8.0);
        break;
      default:
        controller.m_fabricUsageMarker.SetHAlign(inkEHorizontalAlign.Left);
        controller.m_fabricUsageCount.SetHAlign(inkEHorizontalAlign.Left);
        controller.m_fabricUsageMarker.SetVAlign(inkEVerticalAlign.Top);
        controller.m_fabricUsageCount.SetVAlign(inkEVerticalAlign.Top);
        controller.m_fabricUsageMarker.SetMargin(12.0, 12.0, 0.0, 0.0);
        controller.m_fabricUsageCount.SetMargin(36.0, 8.0, 0.0, 0.0);
    }
  }

  /**
   * Sets both marker widgets visible only when the card has one or more associations.
   * @param controller The host item-card controller with FABRIC widgets.
   * @param count The cached association count for the current card.
   * @return None.
   * @errors Missing widgets leave the card unchanged.
   */
  private static func SetCount(controller: ref<InventoryItemDisplayController>, count: Int32) -> Void {
    if !IsDefined(controller.m_fabricUsageMarker) || !IsDefined(controller.m_fabricUsageCount) { return; }
    controller.m_fabricUsageMarker.SetVisible(count > 0);
    controller.m_fabricUsageCount.SetVisible(count > 0);
    if count > 0 { controller.m_fabricUsageCount.SetText(IntToString(count)); }
  }
}
