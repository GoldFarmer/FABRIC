module FABRIC

/**
 * Classifies supported wardrobe mutations and coordinates their post-persistence rebuild.
 *
 * GenericMessageNotification hooks delegate here after the host popup closes. The popup boundary
 * contains no reliable per-outfit payload, so confirmed mutations always trigger a full rebuild.
 */
public abstract class FabricWardrobeMutation {
  /**
   * Returns whether a popup result confirms a supported Equipment-EX save or delete action.
   *
   * @param result The host popup close result.
   * @param popupTitle The localized title captured before the host close callback.
   * @param popupMessage The localized message captured before the host close callback.
   * @return True for a confirmed supported mutation; otherwise false.
   * @errors None; unmatched or cancelled popups safely return false.
   */
  public static func IsConfirmed(result: GenericMessageNotificationResult, popupTitle: String,
    popupMessage: String) -> Bool {
    let isSave = Equals(popupTitle, GetLocalizedTextByKey(n"UI-Wardrobe-SaveSet"))
      && Equals(popupMessage, GetLocalizedTextByKey(n"UI-Wardrobe-NotificationSaveSet"));
    let isDelete = Equals(popupTitle, GetLocalizedTextByKey(n"UI-Wardrobe-Deleteset"))
      && Equals(popupMessage, GetLocalizedTextByKey(n"UI-Wardrobe-NotificationDeleteSet"));
    return Equals(result, GenericMessageNotificationResult.Confirm) && (isSave || isDelete);
  }

  /**
   * Rebuilds authoritative usage state after the host has persisted a confirmed mutation.
   *
   * @param None.
   * @return None.
   * @errors A missing service logs WARN and leaves host popup behavior unchanged.
   */
  public static func RebuildVisibleCards() -> Void {
    let service = FabricService.Get();
    if !IsDefined(service) {
      FabricLog.Warn("Confirmed wardrobe mutation could not obtain FabricService.");
      return;
    }
    service.RebuildFull();
    if service.IsWardrobeUiActive() {
      GameInstance.GetUISystem(GetGameInstance()).QueueEvent(new FabricUsageIndexUpdated());
    }
  }
}
