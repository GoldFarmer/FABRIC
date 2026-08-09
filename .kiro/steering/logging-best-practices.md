---
inclusion: always
---

# FABRIC Logging Best Practices

Use `FabricLog` for all FABRIC runtime diagnostics. Do not call `Log`, `LogWarning`, `LogError`, `LogChannel`, `FTLog`, or another logging API directly from FABRIC feature code.

## Severity levels

- `TRACE` — entry into significant logic. State what will happen and include relevant parameter values.
- `DEBUG` — exit from significant logic. State what happened, the relevant input parameters, return value, and important result values.
- `INFO` — significant expected lifecycle or state-change events that remain useful with verbose logging disabled.
- `WARN` — unexpected but recoverable conditions. Include the condition, affected values, and recovery or fallback taken.
- `ERROR` — unrecoverable operation failures. Include the failed operation, relevant non-sensitive values, and player-visible consequence or required recovery.

`FabricLog` uses the shared engine `Log`, `LogWarning`, and `LogError` APIs and writes all entries with the `FABRIC` tag plus a standardized `[TRACE]`, `[DEBUG]`, `[INFO]`, `[WARN]`, or `[ERROR]` prefix. `LogError` includes Codeware call-site context. The native declarations belong once in a shared root-level `r6\\scripts\\Logs.reds` file and must never be declared or packaged by FABRIC.

## Where to inspect FABRIC logs

- During a running game, treat CET's **Game Log** panel as the authoritative live view. Filter or search for `[FABRIC]`.
- FABRIC's engine-log sink is `Cyberpunk 2077\\bin\\x64\\plugins\\cyber_engine_tweaks\\gamelog.log`.
- `gamelog.log` is buffered during a running game: a game-script call may coincide with a flush but does not guarantee one, and the active file can temporarily end mid-record. Do not treat a missing or incomplete live-session line as proof that FABRIC did not run.
- `scripting.log` is for CET/Lua scripting output and is not the authoritative sink for FABRIC REDscript diagnostics.
- `Cyberpunk 2077\\r6\\logs\\redscript_rCURRENT.log` is the REDscript compiler log. Use it to diagnose compilation and source-loading failures, not FABRIC runtime behavior.

## Entry and exit logging

For each independently meaningful operation—cache rebuilds, mutation reconciliation, dependency checks, I/O, game hooks, or UI state changes—use a `TRACE` entry at the start and a `DEBUG` entry at completion only when each line contributes distinct diagnostic information.

Do not mechanically pair severity levels. A `WARN` already states the abnormal condition and recovery; do not follow it with a DEBUG restatement. Likewise, an `INFO` state-change record should not be followed by a DEBUG line that merely repeats its counts or outcome. When one operation calls another logged operation, let the child own its detailed completion log; the parent should log only its own distinct context or fallback decision.

Do not add entry/exit logs to trivial getters, setters, small predicates, or simple value conversions. Log only when the call materially changes state, crosses a system boundary, performs meaningful computation, or resolves a failure path.

Keep parameters safe to log: do not emit credentials, tokens, player-private content, or unnecessarily large payloads. Treat user-entered outfit names as player-private; when correlation is needed, log a stable `NameToHash` value rather than the displayed name. Summarize collections by size unless individual values are needed to diagnose a bug.

## Failure handling

Use `WARN` when FABRIC can continue safely, such as a missing optional integration, a stale cache that will be rebuilt, or a recoverable malformed reference. Use `ERROR` only when the requested operation cannot continue safely; return the documented safe default or disable the affected FABRIC feature without crashing the host UI.

Do not use task numbers, specification phases, or temporary implementation narration in log messages. Messages must describe the runtime condition and consequence for a future developer or player support log.
