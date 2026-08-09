module FABRIC

/**
 * Registers FABRIC's optional persistent marker choices with Mod Settings.
 * Mod Settings owns persistence and instantiation; this declaration supplies stable names,
 * defaults, and display metadata only when the optional module exists.
 */
@if(ModuleExists("ModSettingsModule"))
public class FabricModSettings {
  @runtimeProperty("ModSettings.mod", "FABRIC")
  @runtimeProperty("ModSettings.category", "Marker")
  @runtimeProperty("ModSettings.displayName", "Marker icon")
  @runtimeProperty("ModSettings.description", "Icon shown for items used by saved outfits.")
  @runtimeProperty("ModSettings.displayValues.Clothing", "Clothing")
  @runtimeProperty("ModSettings.displayValues.Officer", "Officer")
  @runtimeProperty("ModSettings.displayValues.Material", "Material")
  @runtimeProperty("ModSettings.displayValues.Techie", "Techie")
  public let markerIcon: FabricMarkerIcon = FabricMarkerIcon.Clothing;
  @runtimeProperty("ModSettings.mod", "FABRIC")
  @runtimeProperty("ModSettings.category", "Marker")
  @runtimeProperty("ModSettings.displayName", "Marker color")
  @runtimeProperty("ModSettings.description", "Color shared by the outfit marker and its count.")
  @runtimeProperty("ModSettings.displayValues.Green", "Green")
  @runtimeProperty("ModSettings.displayValues.Cyan", "Cyan")
  @runtimeProperty("ModSettings.displayValues.Yellow", "Yellow")
  @runtimeProperty("ModSettings.displayValues.Orange", "Orange")
  @runtimeProperty("ModSettings.displayValues.Red", "Red")
  @runtimeProperty("ModSettings.displayValues.White", "White")
  @runtimeProperty("ModSettings.displayValues.Pink", "Pink")
  @runtimeProperty("ModSettings.displayValues.Purple", "Purple")
  public let markerColor: FabricMarkerColor = FabricMarkerColor.Green;
  @runtimeProperty("ModSettings.mod", "FABRIC")
  @runtimeProperty("ModSettings.category", "Marker")
  @runtimeProperty("ModSettings.displayName", "Marker corner")
  @runtimeProperty("ModSettings.description", "Corner used by the outfit marker and its count.")
  @runtimeProperty("ModSettings.displayValues.TopLeft", "Top left")
  @runtimeProperty("ModSettings.displayValues.TopRight", "Top right")
  @runtimeProperty("ModSettings.displayValues.BottomLeft", "Bottom left")
  @runtimeProperty("ModSettings.displayValues.BottomRight", "Bottom right")
  public let markerCorner: FabricMarkerCorner = FabricMarkerCorner.TopLeft;
}

/**
 * Resolves marker settings behind an optional-mod boundary for presentation code.
 * This stateless resolver isolates Mod Settings access so marker presentation depends only on
 * stable icon, color, and corner values.
 */
public abstract class FabricMarkerSettings {
  /**
   * Returns the active icon or shipped default when optional settings are unavailable.
   * @param None.
   * @return The committed icon or the default.
   * @errors Missing optional settings safely select the default.
   */
  @if(ModuleExists("ModSettingsModule"))
  public static func GetIcon() -> FabricMarkerIcon {
    let setting = FabricMarkerSettings.Find(n"markerIcon");
    return IsDefined(setting) ? IntEnum<FabricMarkerIcon>(setting.GetValue())
      : FabricMarkerStyle.DefaultIcon();
  }

  /**
   * Returns the shipped default icon when Mod Settings is not installed.
   * @param None.
   * @return The Clothing icon.
   * @errors None.
   */
  @if(!ModuleExists("ModSettingsModule"))
  public static func GetIcon() -> FabricMarkerIcon { return FabricMarkerStyle.DefaultIcon(); }

  /**
   * Returns the active color or shipped default when optional settings are unavailable.
   * @param None.
   * @return The committed color or the default.
   * @errors Missing optional settings safely select the default.
   */
  @if(ModuleExists("ModSettingsModule"))
  public static func GetColor() -> FabricMarkerColor {
    let setting = FabricMarkerSettings.Find(n"markerColor");
    return IsDefined(setting) ? IntEnum<FabricMarkerColor>(setting.GetValue())
      : FabricMarkerStyle.DefaultColor();
  }

  /**
   * Returns the shipped default color when Mod Settings is not installed.
   * @param None.
   * @return The green color.
   * @errors None.
   */
  @if(!ModuleExists("ModSettingsModule"))
  public static func GetColor() -> FabricMarkerColor { return FabricMarkerStyle.DefaultColor(); }

  /**
   * Returns the active corner or upper-left default when optional settings are unavailable.
   * @param None.
   * @return The committed corner or upper-left default.
   * @errors Missing optional settings safely select the default.
   */
  @if(ModuleExists("ModSettingsModule"))
  public static func GetCorner() -> FabricMarkerCorner {
    let setting = FabricMarkerSettings.Find(n"markerCorner");
    return IsDefined(setting) ? IntEnum<FabricMarkerCorner>(setting.GetValue())
      : FabricMarkerCorner.TopLeft;
  }

  /**
   * Returns the upper-left default when Mod Settings is not installed.
   * @param None.
   * @return The TopLeft corner.
   * @errors None.
   */
  @if(!ModuleExists("ModSettingsModule"))
  public static func GetCorner() -> FabricMarkerCorner { return FabricMarkerCorner.TopLeft; }

  /**
   * Locates one committed FABRIC enum setting in Mod Settings' persistent store.
   * @param varName The registered persistent variable name.
   * @return The matching enum setting, or null when absent.
   * @errors Missing optional settings safely return null.
   */
  @if(ModuleExists("ModSettingsModule"))
  private static func Find(varName: CName) -> ref<ModConfigVarEnum> {
    let settings = ModSettings.GetVars(n"FABRIC", n"Marker");
    let setting: ref<ModConfigVarEnum>;
    let index: Int32;
    while index < ArraySize(settings) {
      setting = settings[index] as ModConfigVarEnum;
      if IsDefined(setting) && Equals(setting.GetName(), varName) { return setting; }
      index += 1;
    }
    return null;
  }
}
