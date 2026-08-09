module FABRIC

/**
 * Stores the session-level override for FABRIC diagnostic verbosity.
 *
 * The generated FabricBuildProfile supplies the release/debug default. Presentation settings are
 * owned separately by FabricMarkerStyle so logging remains available without Mod Settings.
 */
public class FabricConfig extends ScriptableService {
  private let m_hasVerboseLoggingOverride: Bool;
  private let m_verboseLoggingOverride: Bool;

  /**
   * Obtains Codeware's registered FABRIC configuration service.
   *
   * Resolves the service by its fully qualified generated class name from Codeware's container.
   *
   * @param None.
   * @return The configuration system, or null before game-system registration.
   * @errors None; callers use the build-profile default when this returns null.
   */
  public static func Get() -> ref<FabricConfig> {
    return GameInstance.GetScriptableServiceContainer().GetService(n"FABRIC.FabricConfig") as FabricConfig;
  }

  /**
   * Enables or disables verbose logging for the current game session.
   *
   * Records an explicit override that takes precedence over the generated build-profile default.
   * A caller that owns persistence can apply its loaded value through this method.
   *
   * @param enabled True to emit TRACE and DEBUG entries; false to retain operational levels only.
   * @return None.
   * @errors None; this method changes only FABRIC's in-memory configuration.
   */
  public func SetVerboseLoggingEnabled(enabled: Bool) {
    this.m_hasVerboseLoggingOverride = true;
    this.m_verboseLoggingOverride = enabled;
  }

  /**
   * Resolves the active verbose-log setting.
   *
   * Uses a session override when present and otherwise returns the generated profile default.
   *
   * @param None.
   * @return True when TRACE and DEBUG entries should be emitted; otherwise false.
   * @errors None.
   */
  public func IsVerboseLoggingEnabled() -> Bool {
    if this.m_hasVerboseLoggingOverride {
      return this.m_verboseLoggingOverride;
    }

    return FabricBuildProfile.IsVerboseLoggingEnabledByDefault();
  }

  /**
   * Determines whether a severity should reach the game log.
   *
   * Preserves INFO, WARN, and ERROR in every build while applying the resolved verbose setting to
   * TRACE and DEBUG. Falls back to the build default during early initialization.
   *
   * @param level The requested diagnostic severity.
   * @return True when the deployed profile or session override permits the message.
   * @errors None.
   */
  public static func ShouldLog(level: FabricLogLevel) -> Bool {
    let config = FabricConfig.Get();

    switch level {
      case FabricLogLevel.Trace:
      case FabricLogLevel.Debug:
        if IsDefined(config) {
          return config.IsVerboseLoggingEnabled();
        }

        return FabricBuildProfile.IsVerboseLoggingEnabledByDefault();
      default:
        return true;
    }
  }
}
