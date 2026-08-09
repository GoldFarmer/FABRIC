module FABRIC

/**
 * Identifies a non-publishable FABRIC debug build and its diagnostic policy.
 *
 * Debug builds emit every FABRIC severity to make lifecycle and reconciliation behavior observable
 * during development without depending on a future CET or Mod Settings UI.
 */
public abstract class FabricBuildProfile {
  /**
   * Returns the installed build flavor.
   *
   * Provides a stable UI-facing label without relying on archive names or local build paths.
   *
   * @param None.
   * @return The debug flavor label.
   * @errors None.
   */
  public static func GetFlavor() -> String { return "debug"; }

  /**
   * Returns this build's default verbose-log setting.
   *
   * Enables all supported severities for development diagnostics.
   *
   * @param None.
   * @return True because debug builds default to verbose logging.
   * @errors None.
   */
  public static func IsVerboseLoggingEnabledByDefault() -> Bool { return true; }
}
