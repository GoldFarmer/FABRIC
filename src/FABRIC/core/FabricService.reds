module FABRIC

/**
 * Coordinates FABRIC's backend collaborators for one Codeware service lifetime.
 *
 * The service exposes stable UI-facing queries while FabricUsageIndex owns cache state and
 * FabricWardrobeSession owns presentation scope. It never exposes OutfitSystem to UI adapters.
 */
public class FabricService extends ScriptableService {
  private let m_usageIndex: ref<FabricUsageIndex>;
  private let m_wardrobeSession: ref<FabricWardrobeSession>;
  private let m_isOutfitIntegrationAvailable: Bool;
  private let m_hasShownOutfitIntegrationNotice: Bool;
  private let m_hasRebuildRecoveryAttempt: Bool;

  /**
   * Obtains the registered FABRIC backend service from Codeware.
   * @param None.
   * @return The service, or null before registration.
   * @errors None; callers render safe defaults for null.
   */
  public static func Get() -> ref<FabricService> {
    return GameInstance.GetScriptableServiceContainer().GetService(n"FABRIC.FabricService")
      as FabricService;
  }

  /**
   * Gets an exact-item cached usage count in O(1)-expected time.
   *
   * @param itemID The complete owned item identity.
   * @return The association count, or zero for invalid or unavailable data.
   * @errors None.
   */
  public func GetUsageCount(itemID: ItemID) -> Int32 {
    return ItemID.IsValid(itemID) && IsDefined(this.m_usageIndex)
      ? this.m_usageIndex.GetUsageCount(itemID) : 0;
  }

  /**
   * Gets a record-level cached usage count in O(1)-expected time.
   *
   * @param itemID The catalog or owned identity whose record is queried.
   * @return The association count, or zero for invalid or unavailable data.
   * @errors None.
   */
  public func GetRecordUsageCount(itemID: ItemID) -> Int32 {
    return ItemID.IsValid(itemID) && IsDefined(this.m_usageIndex)
      ? this.m_usageIndex.GetRecordUsageCount(itemID) : 0;
  }

  /**
   * Returns cached exact-item outfit identifiers without exposing index details.
   * @param itemID The complete item identity to query.
   * @return Cached outfit identifiers, or an empty array.
   * @errors Invalid identities and missing indexes return an empty array.
   */
  public func GetAssociatedOutfitIDs(itemID: ItemID) -> array<CName> {
    return ItemID.IsValid(itemID) && IsDefined(this.m_usageIndex)
      ? this.m_usageIndex.GetOutfitNames(itemID) : [];
  }

  /**
   * Returns cached record-level outfit identifiers without exposing index details.
   * @param itemID The catalog or owned identity whose record is queried.
   * @return Cached outfit identifiers, or an empty array.
   * @errors Invalid identities and missing indexes return an empty array.
   */
  public func GetAssociatedOutfitIDsByRecord(itemID: ItemID) -> array<CName> {
    return ItemID.IsValid(itemID) && IsDefined(this.m_usageIndex)
      ? this.m_usageIndex.GetRecordOutfitNames(itemID) : [];
  }

  /**
   * Converts exact-item cached identifiers to display names without querying OutfitSystem.
   * @param itemID The complete item identity to query.
   * @return Display names, or an empty array.
   * @errors None; unavailable cache data returns an empty array.
   */
  public func GetAssociatedOutfitNames(itemID: ItemID) -> array<String> {
    return this.ToDisplayNames(this.GetAssociatedOutfitIDs(itemID));
  }

  /**
   * Converts record-level cached identifiers to display names without querying OutfitSystem.
   * @param itemID The catalog or owned identity whose record is queried.
   * @return Display names, or an empty array.
   * @errors None; unavailable cache data returns an empty array.
   */
  public func GetAssociatedOutfitNamesByRecord(itemID: ItemID) -> array<String> {
    return this.ToDisplayNames(this.GetAssociatedOutfitIDsByRecord(itemID));
  }

  /**
   * Starts the wardrobe-only UI scope used by FABRIC card adapters.
   * @param None.
   * @return None.
   * @errors None.
   */
  public func BeginWardrobeUiSession() -> Void { this.GetWardrobeSession().Begin(); }

  /**
   * Ends the wardrobe-only UI scope used by FABRIC card adapters.
   * @param None.
   * @return None.
   * @errors None; ending an inactive session is safe.
   */
  public func EndWardrobeUiSession() -> Void { this.GetWardrobeSession().End(); }

  /**
   * Reports whether FABRIC card adapters are currently scoped to the wardrobe.
   * @param None.
   * @return True while the wardrobe session is active; otherwise false.
   * @errors None.
   */
  public func IsWardrobeUiActive() -> Bool { return this.GetWardrobeSession().IsActive(); }

  /**
   * Rebuilds the complete usage index after a supported authoritative boundary.
   *
   * The popup boundary lacks a reliable per-outfit payload, so every supported mutation replaces
   * the index from OutfitSystem rather than attempting an incremental update.
   *
   * @param None.
   * @return None.
   * @errors Missing Equipment-EX leaves an empty index and an actionable diagnostic.
   */
  public func RebuildFull() -> Void {
    let startTime = EngineTime.ToFloat(GameInstance.GetSimTime(GetGameInstance()));
    let entries: array<ref<FabricRebuildEntry>>;
    let elapsedMilliseconds: Float;

    this.GetUsageIndex().Reset();
    this.m_isOutfitIntegrationAvailable = false;
    if !FabricOutfitReader.IsAvailable() {
      FabricLog.Warn("RebuildFull: Equipment-EX OutfitSystem is unavailable; FABRIC is disabled.");
      return;
    }

    this.m_isOutfitIntegrationAvailable = true;
    entries = FabricOutfitReader.ReadEntries();
    for entry in entries {
      for itemID in entry.itemIDs {
        this.GetUsageIndex().Add(itemID, entry.outfitName);
      }
      this.GetUsageIndex().CountOutfit();
      if !this.GetUsageIndex().IsEntryIndexed(entry) {
        this.RecoverFromInvalidRebuild();
        return;
      }
    }

    this.m_hasRebuildRecoveryAttempt = false;
    elapsedMilliseconds = (EngineTime.ToFloat(GameInstance.GetSimTime(GetGameInstance())) - startTime)
      * 1000.0;
    FabricLog.Info(s"Full rebuild complete: \(this.GetUsageIndex().GetSummary()), \(elapsedMilliseconds) ms.");
  }

  /**
   * Displays one dependency notice after the integration has proven unavailable.
   * @param None.
   * @return None.
   * @errors Missing UI notifications logs WARN and leaves the HUD unchanged.
   */
  public func ShowOutfitIntegrationUnavailableNotice() -> Void {
    let blackboard = GameInstance.GetBlackboardSystem(GetGameInstance()).Get(
      GetAllBlackboardDefs().UI_Notifications);
    let message: SimpleScreenMessage;
    if this.m_isOutfitIntegrationAvailable || this.m_hasShownOutfitIntegrationNotice { return; }
    this.m_hasShownOutfitIntegrationNotice = true;
    if !IsDefined(blackboard) {
      FabricLog.Warn("Unable to access UI notifications for FABRIC's dependency notice.");
      return;
    }
    message.isShown = true;
    message.duration = 8.0;
    message.message = "FABRIC disabled: Equipment-EX is unavailable. Install it and restart the game.";
    blackboard.SetVariant(GetAllBlackboardDefs().UI_Notifications.OnscreenMessage, ToVariant(message), true);
  }

  /**
   * Lazily creates and returns this service's association-index collaborator.
   * @param None.
   * @return A usable transient usage index.
   * @errors None.
   */
  private func GetUsageIndex() -> ref<FabricUsageIndex> {
    if !IsDefined(this.m_usageIndex) { this.m_usageIndex = new FabricUsageIndex(); }
    return this.m_usageIndex;
  }

  /**
   * Lazily creates and returns this service's wardrobe-session collaborator.
   * @param None.
   * @return A usable transient wardrobe session.
   * @errors None.
   */
  private func GetWardrobeSession() -> ref<FabricWardrobeSession> {
    if !IsDefined(this.m_wardrobeSession) { this.m_wardrobeSession = new FabricWardrobeSession(); }
    return this.m_wardrobeSession;
  }

  /**
   * Converts cached CNames into tooltip-facing strings without reading game systems.
   * @param outfitNames The cached identifiers to convert.
   * @return One display string for each supplied identifier.
   * @errors None.
   */
  private func ToDisplayNames(outfitNames: array<CName>) -> array<String> {
    let names: array<String>;
    for outfitName in outfitNames { ArrayPush(names, NameToString(outfitName)); }
    return names;
  }

  /**
   * Retries one invalid authoritative rebuild, then retains the latest reconstructed state.
   * @param None.
   * @return None.
   * @errors A second validation failure logs ERROR and stops retrying.
   */
  private func RecoverFromInvalidRebuild() -> Void {
    if !this.m_hasRebuildRecoveryAttempt {
      this.m_hasRebuildRecoveryAttempt = true;
      FabricLog.Warn("RebuildFull: index validation failed; retrying one full rebuild.");
      this.RebuildFull();
      return;
    }
    FabricLog.Error("RebuildFull: index validation failed after retry; retaining reconstructed state.");
  }
}
