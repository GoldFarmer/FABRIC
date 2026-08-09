module FABRIC

import Codeware.*

/**
 * Provides the debug diagnostics backend.
 *
 * The debug backend writes one severity-prefixed entry through the engine file-log API after the
 * shared REDscript logging declarations expose the native logging functions.
 */
public abstract class FabricLogBackend {
  /**
   * Filters and writes one FABRIC diagnostic through the debug logging API.
   *
   * @param level The severity that controls filtering and the emitted prefix.
   * @param message The already-composed diagnostic text.
   * @return None.
   * @errors Missing shared logging declarations prevent debug REDscript compilation.
   */
  public static func Write(level: FabricLogLevel, message: String) -> Void {
    let formatted = s"[FABRIC] [\(FabricLogBackend.LevelName(level))] \(message)";
    if !FabricConfig.ShouldLog(level) { return; }
    switch level {
      case FabricLogLevel.Warn:
        FTLogWarning(formatted);
        break;
      case FabricLogLevel.Error:
        FTLogError(FabricLogBackend.FormatErrorMessage(formatted));
        break;
      default:
        FTLog(formatted);
    }
  }

  /**
   * Adds the direct FABRIC call site to a debug error message.
   *
   * @param formatted The severity-prefixed message produced by Write.
   * @return A message carrying the current FABRIC class and function when available.
   * @errors None; Codeware supplies the current call stack for the supported debug runtime.
   */
  private static func FormatErrorMessage(formatted: String) -> String {
    let entries = GetStackTrace(3, true);
    let entry = entries[0];
    let trace = IsDefined(entry.object)
      ? s"[\(entry.class)][\(entry.function)]"
      : s"[\(entry.function)]";
    return s"\(trace) \(formatted)";
  }

  /**
   * Converts a severity enum value into its stable log prefix.
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
