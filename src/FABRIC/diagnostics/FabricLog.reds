module FABRIC

/**
 * Defines FABRIC's ordered diagnostic severities.
 *
 * The values distinguish detailed development traces from recoverable and unrecoverable runtime
 * conditions while retaining one stable game-log channel.
 */
public enum FabricLogLevel {
  Trace = 0,
  Debug = 1,
  Info = 2,
  Warn = 3,
  Error = 4
}

/**
 * Provides a stable diagnostics façade for FABRIC's selected build-time logging backend.
 *
 * Release builds select a no-op backend so customers do not need shared native logging
 * declarations. Debug builds select the engine logging backend for development diagnostics.
 */
public abstract class FabricLog {
  /**
   * Records detailed significant-logic entry information.
   *
   * Formats the supplied message with the TRACE prefix when verbose logging is enabled.
   *
   * @param message The operation and parameter values about to be processed.
   * @return None.
   * @errors None; logging failures are handled by the game logging runtime.
   */
  public static func Trace(message: String) {
    FabricLogBackend.Write(FabricLogLevel.Trace, message);
  }

  /**
   * Records detailed significant-logic exit information.
   *
   * Formats the supplied message with the DEBUG prefix when verbose logging is enabled.
   *
   * @param message The completed operation, relevant parameters, and return or outcome values.
   * @return None.
   * @errors None; logging failures are handled by the game logging runtime.
   */
  public static func Debug(message: String) {
    FabricLogBackend.Write(FabricLogLevel.Debug, message);
  }

  /**
   * Records a significant normal lifecycle event.
   *
   * Formats the supplied message with the INFO prefix regardless of verbose-log configuration.
   *
   * @param message The completed normal event and its useful summary values.
   * @return None.
   * @errors None; logging failures are handled by the game logging runtime.
   */
  public static func Info(message: String) {
    FabricLogBackend.Write(FabricLogLevel.Info, message);
  }

  /**
   * Records an unexpected condition from which FABRIC safely recovers.
   *
   * Formats the supplied message with the WARN prefix regardless of verbose-log configuration.
   *
   * @param message The condition, affected values, and fallback or recovery taken.
   * @return None.
   * @errors None; logging failures are handled by the game logging runtime.
   */
  public static func Warn(message: String) {
    FabricLogBackend.Write(FabricLogLevel.Warn, message);
  }

  /**
   * Records an unrecoverable operation failure.
   *
   * Formats the supplied message with the ERROR prefix regardless of verbose-log configuration.
   *
   * @param message The failed operation, relevant values, and player-visible consequence.
   * @return None.
   * @errors None; logging failures are handled by the game logging runtime.
   */
  public static func Error(message: String) {
    FabricLogBackend.Write(FabricLogLevel.Error, message);
  }
}
