module FABRIC

/**
 * Exposes FABRIC's installed source version without relying on archive or local-path metadata.
 * The generated build profile supplies flavor-specific runtime metadata; this dependency-free
 * marker remains available for support diagnostics before optional services are registered.
 */
public abstract class FabricBuildMarker {
  /**
   * Returns the version shipped by this source tree.
   *
   * @param None.
   * @return The FABRIC version string.
   * @errors None.
   */
  public static func GetVersion() -> String {
    return "0.1.3";
  }
}
