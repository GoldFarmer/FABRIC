# Duplicate item handling

Equipment-EX saves the complete `ItemID` selected for each outfit part. FABRIC preserves that identity for Wardrobe, Backpack, and storage presentation. Virtual Atelier catalog cards do not represent one owned instance, so FABRIC uses their item record (`TweakDBID`) instead.

## What the marker count means

On owned Wardrobe, Backpack, and storage cards, the number beside the FABRIC marker is the number of distinct saved outfits that reference that exact item instance. On Virtual Atelier catalog cards, it is the number of distinct saved outfits that reference any instance of the same item record.

- If one saved outfit uses one owned copy, that copy shows `1`; other copies only show a marker if they are also referenced.
- A Virtual Atelier card shows the aggregate count for its matching item record.
- An outfit contributes at most one to the count for a particular exact item or item record.

The tooltip lists those distinct outfit names alphabetically.

## What happens with duplicate instances

Two items can look identical and resolve to the same game record while still being separate runtime or inventory instances. In Wardrobe, Backpack, and storage, FABRIC only marks the specific complete `ItemID` saved in an outfit. The other copy has no marker or outfit-tooltip section unless it is separately referenced.

Virtual Atelier remains record-based by design: its catalog card shows the marker and outfit names when any owned instance of that record is referenced. WEAVE-restored references can also be record-derived, so their Virtual Atelier presentation remains compatible.

Use the owned-item marker as the direct indication that a specific visible copy is referenced by an outfit. A Virtual Atelier marker instead indicates that the catalog item type has at least one outfit association.
