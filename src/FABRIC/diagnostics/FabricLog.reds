module FABRIC

import Codeware.*

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
 * Writes consistently formatted FABRIC diagnostics through the engine log pipeline.
 *
 * The engine Log API surfaces entries in CET's Game Log and persists them to its game-log file.
 * Trace and debug output are gated by FabricConfig; higher severities remain visible for
 * significant normal events and actionable failures.
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
    FabricLog.Write(FabricLogLevel.Trace, message);
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
    FabricLog.Write(FabricLogLevel.Debug, message);
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
    FabricLog.Write(FabricLogLevel.Info, message);
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
    FabricLog.Write(FabricLogLevel.Warn, message);
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
    FabricLog.Write(FabricLogLevel.Error, message);
  }

  /**
   * Filters and emits one formatted diagnostic through the engine log pipeline.
   *
   * Applies FabricConfig's severity gate before using the shared engine logging API with a stable
   * prefix. Error entries also include the immediate Codeware stack location.
   *
   * @param level The severity that controls filtering and the emitted prefix.
   * @param message The already-composed diagnostic text.
   * @return None.
   * @errors None; logging failures are handled by the game logging runtime.
   */
  private static func Write(level: FabricLogLevel, message: String) {
    let formatted = s"[\(FabricLog.LevelName(level))] \(message)";

    if FabricConfig.ShouldLog(level) {
      switch level {
        case FabricLogLevel.Warn:
          LogWarning(s"[FABRIC] \(formatted)");
          break;
        case FabricLogLevel.Error:
          LogError(FabricLog.FormatErrorFileMessage(formatted));
          break;
        default:
          Log(s"[FABRIC] \(formatted)");
      }
    }
  }

  /**
   * Formats an error's file-log entry with the direct FABRIC call site when Codeware exposes it.
   *
   * @param formatted The severity-prefixed message produced by Write.
   * @return A file-log message carrying FABRIC's tag and, when available, class/function context.
   * @errors None; Codeware supplies the current call stack for FABRIC's supported runtime.
   */
  private static func FormatErrorFileMessage(formatted: String) -> String {
    // Skip this formatter, Write, and Error so the first entry is FABRIC's actual call site.
    let entries = GetStackTrace(3, true);
    let entry = entries[0];
    let trace = "";

    trace = IsDefined(entry.object)
      ? s"[\(entry.class)][\(entry.function)]"
      : s"[\(entry.function)]";
    return s"[FABRIC] \(trace) \(formatted)";
  }

  /**
   * Converts a severity enum value into its stable log prefix.
   *
   * Selects the documented uppercase label used by Write.
   *
   * @param level The severity to name.
   * @return The uppercase severity label, or ERROR for an unrecognized value.
   * @errors None.
   */
  private static func LevelName(level: FabricLogLevel) -> String {
    switch level {
      case FabricLogLevel.Trace: return "TRACE";
      case FabricLogLevel.Debug: return "DEBUG";
      case FabricLogLevel.Info: return "INFO";
      case FabricLogLevel.Warn: return "WARN";
      default: return "ERROR";
    }
  }
}
