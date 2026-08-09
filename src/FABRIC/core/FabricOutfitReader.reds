module FABRIC

@if(ModuleExists("EquipmentEx"))
import EquipmentEx.{OutfitPart, OutfitSystem}

/**
 * Reads authoritative Equipment-EX saved-outfit data without owning FABRIC cache state.
 *
 * FabricService uses this boundary during full rebuilds; UI code must only query FabricService's
 * already-built index and never call this reader.
 */
@if(ModuleExists("EquipmentEx"))
public abstract class FabricOutfitReader {
  /**
   * Reports whether Equipment-EX exposes an OutfitSystem for the active game instance.
   * @param None.
   * @return True when the authoritative reader is available; otherwise false.
   * @errors None.
   */
  public static func IsAvailable() -> Bool {
    return IsDefined(OutfitSystem.GetInstance(GetGameInstance()));
  }

  /**
   * Reads all saved outfits into complete-identity entries for one authoritative rebuild.
   *
   * @param None.
   * @return One entry per saved outfit; invalid or absent parts are omitted.
   * @errors An unavailable OutfitSystem returns an empty array without mutating FABRIC state.
   */
  public static func ReadEntries() -> array<ref<FabricRebuildEntry>> {
    let entries: array<ref<FabricRebuildEntry>>;
    let outfitSystem = OutfitSystem.GetInstance(GetGameInstance());
    let parts: array<ref<OutfitPart>>;
    let entry: ref<FabricRebuildEntry>;
    if !IsDefined(outfitSystem) { return entries; }
    for outfitName in outfitSystem.GetOutfits() {
      entry = new FabricRebuildEntry();
      entry.outfitName = outfitName;
      parts = outfitSystem.GetOutfitParts(outfitName);
      for part in parts {
        if IsDefined(part) && ItemID.IsValid(part.GetItemID()) {
          ArrayPush(entry.itemIDs, part.GetItemID());
        }
      }
      ArrayPush(entries, entry);
    }
    return entries;
  }
}

/** Provides the same safe reader contract when Equipment-EX is not installed. No reader state exists. */
@if(!ModuleExists("EquipmentEx"))
public abstract class FabricOutfitReader {
  /**
   * Reports that Equipment-EX is unavailable in this compiled configuration.
   * @param None.
   * @return False.
   * @errors None.
   */
  public static func IsAvailable() -> Bool { return false; }

  /**
   * Returns no entries because the optional Equipment-EX module is unavailable.
   * @param None.
   * @return An empty array.
   * @errors None.
   */
  public static func ReadEntries() -> array<ref<FabricRebuildEntry>> { return []; }
}
