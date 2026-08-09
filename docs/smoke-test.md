# FABRIC in-game smoke test

Record the game, REDscript, RED4ext, Equipment-EX, WEAVE (if installed), and FABRIC versions before running this checklist.

1. Start from a clean FABRIC install and confirm REDscript reports no compilation error.
2. Open the Equipment-EX wardrobe and confirm FABRIC loads without UI errors.
3. Create an outfit, add and remove clothing, then delete it; verify affected marker counts after each operation.
4. If WEAVE is installed, rename an outfit and verify the add-then-delete sequence preserves correct associations.
5. If WEAVE sync is enabled, save/load once and record whether the current startup reconciliation reflects the restored data. Immediate post-sync reconciliation is not a supported guarantee until WEAVE provides a completion notification.
6. Open an existing saved outfit containing an Equipment-EX extended-slot item, such as Balaclava, Glasses, Neckwear, Torso Inner/Middle/Outer, or Legs Inner/Middle/Outer. Verify its Wardrobe card shows the expected FABRIC marker/count and its tooltip lists the expected outfit name. If the same item is available in Backpack, storage, or Virtual Atelier, verify the same record-level result there.
7. Test two apparent copies of one garment, including after save/load. Do not claim per-instance precision unless their complete ItemIDs differ.
8. Test used and unused marker states together with the outfit-tooltip section. Change selections or scroll a virtualized card list to confirm an unbound/unsupported item never retains a prior marker or FABRIC tooltip section.
9. Remove FABRIC's installed script directory, start the game, and confirm the game and Equipment-EX still load normally.

Record pass/fail and the relevant log paths in the release notes or issue tracker.
