module FABRIC

/** Curated texture parts from the vanilla loop-bordered marker atlas. */
public enum FabricMarkerIcon {
  Clothing = 0,
  Officer = 1,
  Material = 2,
  Techie = 3,
}

/** Readable marker palettes shared by the icon and its usage-count label. */
public enum FabricMarkerColor {
  Green = 0,
  Cyan = 1,
  Yellow = 2,
  Orange = 3,
  Red = 4,
  White = 5,
  Pink = 6,
  Purple = 7,
}

/** Card corners available to the shared marker icon and count badge. */
public enum FabricMarkerCorner {
  TopLeft = 0,
  TopRight = 1,
  BottomLeft = 2,
  BottomRight = 3,
}

/**
 * Maps FABRIC marker choices to the vanilla Ink representation used by persistent card widgets.
 *
 * This stateless type owns only presentation mappings and has no game-service lifecycle.
 */
public abstract class FabricMarkerStyle {

  /**
   * Returns the shipped marker icon without requiring a running service.
   *
   * @param None.
   * @return The default Clothing icon.
   * @errors None.
   */
  public static func DefaultIcon() -> FabricMarkerIcon {
    return FabricMarkerIcon.Clothing;
  }

  /**
   * Returns the shipped marker color without requiring a running service.
   *
   * @param None.
   * @return The default green tint choice.
   * @errors None.
   */
  public static func DefaultColor() -> FabricMarkerColor {
    return FabricMarkerColor.Green;
  }

  /**
   * Maps a supported icon choice to its verified vanilla atlas texture part.
   *
   * @param icon The configured FABRIC marker icon.
   * @return The vanilla atlas texture part, falling back to Clothing for an unrecognized value.
   * @errors None.
   */
  public static func TexturePartFor(icon: FabricMarkerIcon) -> CName {
    switch icon {
      case FabricMarkerIcon.Officer:
        return n"icon_officer";
      case FabricMarkerIcon.Material:
        return n"material";
      case FabricMarkerIcon.Techie:
        return n"techie1";
      default:
        return n"clothing";
    }
  }

  /**
   * Maps a supported palette choice to an HDR tint shared by the icon and count label.
   *
   * @param color The configured FABRIC marker color.
   * @return The corresponding HDR tint, falling back to green for an unrecognized value.
   * @errors None.
   */
  public static func ColorFor(color: FabricMarkerColor) -> HDRColor {
    switch color {
      case FabricMarkerColor.Cyan:
        return new HDRColor(0.30, 0.90, 1.00, 1.00);
      case FabricMarkerColor.Yellow:
        return new HDRColor(1.00, 0.90, 0.20, 1.00);
      case FabricMarkerColor.Orange:
        return new HDRColor(1.00, 0.55, 0.20, 1.00);
      case FabricMarkerColor.Red:
        return new HDRColor(1.00, 0.30, 0.30, 1.00);
      case FabricMarkerColor.White:
        return new HDRColor(1.00, 1.00, 1.00, 1.00);
      case FabricMarkerColor.Pink:
        return new HDRColor(1.00, 0.40, 0.70, 1.00);
      case FabricMarkerColor.Purple:
        return new HDRColor(0.80, 0.50, 1.00, 1.00);
      default:
        return new HDRColor(0.50, 1.00, 0.50, 1.00);
    }
  }
}
