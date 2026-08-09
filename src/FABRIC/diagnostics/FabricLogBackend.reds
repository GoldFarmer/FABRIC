module FABRIC

/**
 * Provides the default release diagnostics backend.
 *
 * The release backend deliberately performs no native logging so its package compiles without
 * the optional shared REDscript logging declarations.
 */
public abstract class FabricLogBackend {
  /**
   * Ignores a FABRIC diagnostic in the release build.
   *
   * @param level The diagnostic severity selected by the caller.
   * @param message The diagnostic message selected by the caller.
   * @return None.
   * @errors None; the release backend intentionally has no logging side effect.
   */
  public static func Write(level: FabricLogLevel, message: String) -> Void {}
}
