module FABRIC

/**
 * Holds distinct saved outfits that reference one catalog record during an index lifetime.
 * FabricUsageIndex owns instances only inside its transient record index; callers do not mutate
 * outfitNames directly, preserving one entry per outfit name.
 */
public class FabricRecordUsage extends IScriptable {
  public let recordID: TweakDBID;
  public let outfitNames: array<CName>;
}

/**
 * Holds distinct saved outfits that reference one complete item instance during an index lifetime.
 * FabricUsageIndex owns instances inside collision-safe buckets and retains the complete ItemID so
 * record-equal items with different rng_seed values cannot become identical associations.
 */
public class FabricItemUsage extends IScriptable {
  public let itemID: ItemID;
  public let outfitNames: array<CName>;
}

/**
 * Groups complete identities sharing one combined-hash key.
 * FabricUsageIndex owns each bucket; full ItemID equality remains authoritative after the hash
 * lookup so collisions cannot become identity matches.
 */
public class FabricItemUsageBucket extends IScriptable {
  public let entries: array<ref<FabricItemUsage>>;
}

/**
 * Records one outfit's complete item identities while a rebuild validates newly created indexes.
 * FabricUsageIndex creates this short-lived rebuild value and discards it after validation; it is
 * not retained as an incremental-mutation snapshot.
 */
public class FabricRebuildEntry extends IScriptable {
  public let outfitName: CName;
  public let itemIDs: array<ItemID>;
}

/**
 * Owns FABRIC's transient item and record association indexes.
 *
 * FabricService owns this collaborator for its session. The complete ItemID remains in each hash
 * bucket so a combined-hash collision cannot become an identity match.
 */
public class FabricUsageIndex extends IScriptable {
  private let m_itemIndex: ref<inkHashMap>;
  private let m_recordIndex: ref<inkHashMap>;
  private let m_outfitCount: Int32;
  private let m_associationCount: Int32;

  /**
   * Replaces this index with a new empty state before a full authoritative rebuild.
   *
   * @param None.
   * @return None.
   * @errors None.
   */
  public final func Reset() -> Void {
    this.m_itemIndex = new inkHashMap();
    this.m_recordIndex = new inkHashMap();
    this.m_outfitCount = 0;
    this.m_associationCount = 0;
  }

  /**
   * Adds one complete item identity and its record-level presentation association.
   *
   * @param itemID The complete persisted identity, including its rng_seed when present.
   * @param outfitName The saved outfit that owns the association.
   * @return None.
   * @errors None; duplicate outfit references are represented once.
   */
  public final func Add(itemID: ItemID, outfitName: CName) -> Void {
    let key = ItemID.GetCombinedHash(itemID);
    let bucket: ref<FabricItemUsageBucket>;
    let usage = this.FindItemUsage(itemID);

    if !IsDefined(usage) {
      if this.m_itemIndex.KeyExist(key) {
        bucket = this.m_itemIndex.Get(key) as FabricItemUsageBucket;
      } else {
        bucket = new FabricItemUsageBucket();
        this.m_itemIndex.Insert(key, bucket);
      }
      usage = new FabricItemUsage();
      usage.itemID = itemID;
      ArrayPush(bucket.entries, usage);
    }

    if !ArrayContains(usage.outfitNames, outfitName) {
      ArrayPush(usage.outfitNames, outfitName);
    }
    this.AddRecord(itemID, outfitName);
  }

  /**
   * Marks one fully indexed saved outfit after all of its parts have been added.
   *
   * @param None.
   * @return None.
   * @errors None.
   */
  public final func CountOutfit() -> Void {
    this.m_outfitCount += 1;
  }

  /**
   * Gets the exact-item usage count without scanning outfits.
   *
   * @param itemID The complete item identity to query.
   * @return The cached count, or zero when unavailable.
   * @errors None.
   */
  public final func GetUsageCount(itemID: ItemID) -> Int32 {
    let usage = this.FindItemUsage(itemID);
    return IsDefined(usage) ? ArraySize(usage.outfitNames) : 0;
  }

  /**
   * Gets the catalog-record usage count without scanning outfits.
   *
   * @param itemID The card identity from which the record is derived.
   * @return The cached count, or zero when unavailable.
   * @errors None.
   */
  public final func GetRecordUsageCount(itemID: ItemID) -> Int32 {
    let usage = this.FindRecordUsage(ItemID.GetTDBID(itemID));
    return IsDefined(usage) ? ArraySize(usage.outfitNames) : 0;
  }

  /**
   * Returns exact-item saved outfit identifiers from the in-memory index.
   *
   * @param itemID The complete item identity to query.
   * @return Cached outfit identifiers, or an empty array.
   * @errors None.
   */
  public final func GetOutfitNames(itemID: ItemID) -> array<CName> {
    let usage = this.FindItemUsage(itemID);
    return IsDefined(usage) ? usage.outfitNames : [];
  }

  /**
   * Returns record-level saved outfit identifiers from the in-memory index.
   *
   * @param itemID The card identity from which the record is derived.
   * @return Cached outfit identifiers, or an empty array.
   * @errors None.
   */
  public final func GetRecordOutfitNames(itemID: ItemID) -> array<CName> {
    let usage = this.FindRecordUsage(ItemID.GetTDBID(itemID));
    return IsDefined(usage) ? usage.outfitNames : [];
  }

  /**
   * Validates a rebuilt outfit against both indexes before the rebuild is accepted.
   *
   * @param entry The temporary complete-identity entry captured while rebuilding.
   * @return True when each exact and record association maps to its outfit.
   * @errors A missing association returns false without changing index state.
   */
  public final func IsEntryIndexed(entry: ref<FabricRebuildEntry>) -> Bool {
    let checkedItemIDs: array<ItemID>;
    let checkedRecordIDs: array<TweakDBID>;
    let itemUsage: ref<FabricItemUsage>;
    let recordID: TweakDBID;
    let recordUsage: ref<FabricRecordUsage>;

    if !IsDefined(entry) { return false; }
    for itemID in entry.itemIDs {
      if !ArrayContains(checkedItemIDs, itemID) {
        ArrayPush(checkedItemIDs, itemID);
        itemUsage = this.FindItemUsage(itemID);
        if !IsDefined(itemUsage) || !ArrayContains(itemUsage.outfitNames, entry.outfitName) {
          return false;
        }
      }
      recordID = ItemID.GetTDBID(itemID);
      if !ArrayContains(checkedRecordIDs, recordID) {
        ArrayPush(checkedRecordIDs, recordID);
        recordUsage = this.FindRecordUsage(recordID);
        if !IsDefined(recordUsage) || !ArrayContains(recordUsage.outfitNames, entry.outfitName) {
          return false;
        }
      }
    }
    return true;
  }

  /**
   * Describes the rebuilt index for an operational diagnostic.
   *
   * @param None.
   * @return A count summary after the current rebuild.
   * @errors None.
   */
  public final func GetSummary() -> String {
    return s"\(this.m_outfitCount) outfits, \(this.m_associationCount) associations";
  }

  /**
   * Finds an exact ItemID in its collision-safe combined-hash bucket.
   * @param itemID The complete item identity, including rng_seed when present.
   * @return The matching usage entry, or null when absent.
   * @errors None; a hash collision cannot become a match because full ItemID equality is checked.
   */
  private final func FindItemUsage(itemID: ItemID) -> ref<FabricItemUsage> {
    let key = ItemID.GetCombinedHash(itemID);
    let bucket: ref<FabricItemUsageBucket>;
    if !IsDefined(this.m_itemIndex) || !this.m_itemIndex.KeyExist(key) { return null; }
    bucket = this.m_itemIndex.Get(key) as FabricItemUsageBucket;
    if !IsDefined(bucket) { return null; }
    for entry in bucket.entries { if Equals(entry.itemID, itemID) { return entry; } }
    return null;
  }

  /**
   * Finds one record-level usage entry by its stable record key.
   * @param recordID The TweakDB record identity to query.
   * @return The matching usage entry, or null when absent.
   * @errors None.
   */
  private final func FindRecordUsage(recordID: TweakDBID) -> ref<FabricRecordUsage> {
    let key = TDBID.ToNumber(recordID);
    let usage: ref<FabricRecordUsage>;
    if !IsDefined(this.m_recordIndex) || !this.m_recordIndex.KeyExist(key) { return null; }
    usage = this.m_recordIndex.Get(key) as FabricRecordUsage;
    return IsDefined(usage) && Equals(usage.recordID, recordID) ? usage : null;
  }

  /**
   * Adds a record association and advances the distinct association counter once.
   * @param itemID The complete item identity from which the record is derived.
   * @param outfitName The saved outfit that references the item.
   * @return None.
   * @errors None; duplicate outfit references remain represented once.
   */
  private final func AddRecord(itemID: ItemID, outfitName: CName) -> Void {
    let recordID = ItemID.GetTDBID(itemID);
    let key = TDBID.ToNumber(recordID);
    let usage = this.FindRecordUsage(recordID);
    if !IsDefined(usage) {
      usage = new FabricRecordUsage();
      usage.recordID = recordID;
      this.m_recordIndex.Insert(key, usage);
    }
    if !ArrayContains(usage.outfitNames, outfitName) {
      ArrayPush(usage.outfitNames, outfitName);
      this.m_associationCount += 1;
    }
  }
}
