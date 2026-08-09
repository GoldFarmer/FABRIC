module FABRIC

/**
 * Requests active FABRIC card presenters to re-read a rebuilt usage index.
 * FabricWardrobeMutation queues it only after a successful authoritative rebuild; the UI system
 * owns delivery and the event carries no mutable payload.
 */
public class FabricUsageIndexUpdated extends Event {}

/**
 * Rebuilds FABRIC's backend after native player attachment without altering host lifecycle behavior.
 * @param None.
 * @return The original host callback result.
 * @errors A missing service logs an error and leaves FABRIC presentation disabled.
 */
@wrapMethod(PlayerPuppet)
protected cb func OnGameAttached() -> Bool {
  let result = wrappedMethod();
  let service = FabricService.Get();
  if !IsDefined(service) {
    FabricLog.Error("Player attachment could not obtain FabricService; FABRIC is disabled.");
    return result;
  }
  service.RebuildFull();
  service.ShowOutfitIntegrationUnavailableNotice();
  return result;
}

/**
 * Starts FABRIC's wardrobe scope before the host builds its initial virtualized cards.
 * @param None.
 * @return The original host callback result.
 * @errors A missing service preserves host initialization without FABRIC session state.
 */
@wrapMethod(WardrobeUIGameController)
protected cb func OnInitialize() -> Bool {
  let service = FabricService.Get();
  if IsDefined(service) { service.BeginWardrobeUiSession(); }
  return wrappedMethod();
}

/**
 * Ends FABRIC's wardrobe scope after the host controller has completed its normal close flow.
 * @param userData The host callback payload.
 * @return The original host callback result.
 * @errors A missing service preserves the normal host close flow.
 */
@wrapMethod(WardrobeUIGameController)
protected cb func OnBack(userData: ref<IScriptable>) -> Bool {
  let result = wrappedMethod(userData);
  let service = FabricService.Get();
  if IsDefined(service) { service.EndWardrobeUiSession(); }
  return result;
}

/**
 * Delegates vanilla card initialization to FABRIC's focused marker presenter.
 * @param None.
 * @return The original host callback result.
 * @errors Presenter safe defaults leave cards unchanged when FABRIC cannot initialize widgets.
 */
@wrapMethod(InventoryItemDisplayController)
protected cb func OnInitialize() -> Bool {
  let result = wrappedMethod();
  FabricUsageMarkerPresenter.OnCardInitialized(this);
  return result;
}

/**
 * Delegates the wardrobe owned-item refresh boundary to FABRIC's focused marker presenter.
 * @param itemData The host's bound owned item, or null for a recycled card.
 * @return None.
 * @errors Presenter safe defaults clear stale FABRIC state without affecting host refresh.
 */
@wrapMethod(InventoryItemDisplayController)
protected func NewUpdateEquipped(itemData: ref<UIInventoryItem>) -> Void {
  wrappedMethod(itemData);
  FabricUsageMarkerPresenter.RefreshWardrobeOwnedCard(this, itemData);
}

/**
 * Delegates the backpack or storage refresh boundary to FABRIC's focused marker presenter.
 * @param itemData The host's bound owned item, or null for a recycled card.
 * @return None.
 * @errors Presenter safe defaults clear stale FABRIC state without affecting host refresh.
 */
@wrapMethod(InventoryItemDisplayController)
protected func NewRefreshUI(itemData: ref<UIInventoryItem>) -> Void {
  wrappedMethod(itemData);
  FabricUsageMarkerPresenter.RefreshOwnedCard(this, itemData);
}

/**
 * Delegates the catalog-card refresh boundary to FABRIC's focused marker presenter.
 * @param None.
 * @return None.
 * @errors Missing catalog identity leaves the host card unchanged and hides FABRIC state.
 */
@wrapMethod(InventoryItemDisplayController)
protected func RefreshUI() -> Void {
  wrappedMethod();
  FabricUsageMarkerPresenter.RefreshCatalogCard(this);
}

/**
 * Re-runs the host-compatible card refresh when FABRIC's usage index has changed.
 * @param evt The completed-index notification; it has no additional payload.
 * @return None.
 * @errors An inactive wardrobe session leaves the host card unchanged.
 */
@addMethod(InventoryItemDisplayController)
protected cb func OnFabricUsageIndexUpdated(evt: ref<FabricUsageIndexUpdated>) {
  FabricUsageMarkerPresenter.RefreshAfterIndexUpdate(this);
}

/**
 * Rebuilds after the confirmed mutation popup has persisted its host operation.
 * @param result The actual host popup result.
 * @return None.
 * @errors An unmatched popup leaves FABRIC state unchanged.
 */
@wrapMethod(GenericMessageNotification)
private final func Close(result: GenericMessageNotificationResult) -> Void {
  let isMutation = FabricWardrobeMutation.IsConfirmed(result, this.m_data.title, this.m_data.message);
  wrappedMethod(result);
  if isMutation { FabricWardrobeMutation.RebuildVisibleCards(); }
}
