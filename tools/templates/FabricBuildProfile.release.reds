module FABRIC

/**
 * Identifies a publishable FABRIC build and its compile-time logging ceiling.
 *
 * Release builds default to operational INFO, WARN, and ERROR diagnostics. The profile retains
 * verbose-log capability so a future support UI can enable it for a customer bug report.
 */
public abstract class FabricBuildProfile {
  /**
   * Returns the installed build flavor.
   *
   * Provides a stable UI-facing label without relying on archive names or local build paths.
   *
   * @param None.
   * @return The release flavor label.
   * @errors None.
   */
  public static func GetFlavor() -> String { return "release"; }

  /**
   * Returns this build's default verbose-log setting.
   *
   * Keeps release logging quiet until a support control explicitly enables verbose diagnostics.
   *
   * @param None.
   * @return False because release builds default to non-verbose logging.
   * @errors None.
   */
  public static func IsVerboseLoggingEnabledByDefault() -> Bool { return false; }
}
