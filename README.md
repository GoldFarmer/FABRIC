# FABRIC

FABRIC is a REDscript mod for Cyberpunk 2077 that surfaces relationships between Equipment-EX clothing items and saved outfits.

## Runtime dependencies

Required:

- Cyberpunk 2077 with compatible REDscript and RED4ext installations.
- Equipment-EX, which is FABRIC's saved-outfit authority.
- Codeware, which provides FABRIC's service lifecycle and error call-site context.
- Shared REDscript logging declarations at `r6\scripts\Logs.reds`. These are installed once per game, not bundled with FABRIC.

Optional:

- WEAVE. FABRIC works without it. Its JSON outfit sync is record-compatible, but the installed WEAVE version does not expose a post-sync completion notification; FABRIC refreshes those associations at its next supported reconciliation boundary.
- Mod Settings. When installed, it exposes marker icon, color, and corner preferences; otherwise FABRIC uses its shipped defaults.

Virtual Atelier is supported through shared vanilla item-card and tooltip paths, but is not a dependency. Cyber Engine Tweaks, Red Hot Tools, Red CLI, and WolvenKit are developer or ecosystem tools, not FABRIC runtime dependencies.

## Developer setup

Set a local PowerShell environment variable to the Cyberpunk 2077 game root; do not commit an absolute game path.

```powershell
$env:FABRIC_GAME_DIR = 'C:\Program Files (x86)\Steam\steamapps\common\Cyberpunk 2077'
```

### Required development tools

FABRIC's Windows development workflow requires the following tools in addition to the game's REDscript, RED4ext, Equipment-EX, and Codeware dependencies.

#### Red CLI

Install [rayshader/cp2077-red-cli](https://github.com/rayshader/cp2077-red-cli) and make `red-cli.exe` available on `PATH`. The local development installation is `C:\Tools\red-cli\red-cli.exe`; adding `C:\Tools\red-cli` to your user `PATH` is the recommended setup.

Red CLI provides the build-system integration for bundling REDscript modules, installing development scripts into the game directory, checking the editor's REDscript diagnostics during watch mode, triggering hot reload, and producing release-ready script packages. FABRIC uses it for the optional `tools\watch.ps1` workflow and will keep its `red.config.json` aligned with the release manifest once production scripts are added.

`red.config.json` is committed as the Red CLI project configuration. It deliberately omits the local game path; set `REDCLI_GAME` (or rely on Red CLI's game auto-detection) before invoking Red CLI directly.

#### Red Hot Tools

Install [psiberx/cp2077-red-hot-tools](https://github.com/psiberx/cp2077-red-hot-tools) into the Cyberpunk 2077 game directory. Red Hot Tools is required for FABRIC's rapid development loop: it receives REDscript reload requests from Red CLI and prevents the game from starting when script compilation fails. Its UI/widget inspection and archive/tweak hot reload features are useful for FABRIC's future interface work.

Keep Red Hot Tools, REDscript, RED4ext, ArchiveXL, Cyber Engine Tweaks, and the game version mutually compatible according to the Red Hot Tools release notes. Hot reload has known limits: structural changes such as new struct fields or scriptable-system request handlers can require a full game-session restart.

#### Shared REDscript logging declarations

Install the shared global logging declarations from the [REDscript logging reference](https://wiki.redmodding.org/redscript/references-and-examples/logging) once at `r6\scripts\Logs.reds`. FABRIC provides a guarded installer for a missing file:

```powershell
.\tools\install-logging-api.ps1 -GameDir $env:FABRIC_GAME_DIR
```

They expose `LogChannel`, `LogChannelWarning`, `LogChannelError`, `Log`, `LogWarning`, and `LogError`. FABRIC uses the engine `Log` severity functions for diagnostics: they surface one entry in CET's Game Log and persist it to `bin\x64\plugins\cyber_engine_tweaks\gamelog.log`; engine-log errors include Codeware call-site context. FABRIC deliberately does not pair these calls with `LogChannel*`, because both routes write to the same CET pipeline and would duplicate each message. The installer refuses to overwrite an existing shared declaration. This file is a game-level development prerequisite: do not place it under FABRIC or include it in a FABRIC release ZIP, because multiple bundled copies would conflict.

Commands are repository-owned PowerShell scripts:

- `tools\verify.ps1` validates project/release structure and enforces REDscript source-quality checks: 120-character line width, no planning markers in source, and removal of the unsupported incremental-cache API. `-RequireTypeCheck` remains reserved for a compiler adapter; use REDscript IDE diagnostics until it is implemented.
- `tools\dev.ps1 -BuildFlavor Debug -WhatIf` previews the default debug installation. `Debug` installs a generated `FabricBuildProfile.reds` that enables TRACE through ERROR by default; `Release` defaults to INFO/WARN/ERROR while retaining a future runtime override path for support diagnostics.
- `tools\package.ps1 -BuildFlavor Release` creates the publishable `build\release\FABRIC-<version>-release.zip` with a SHA-256 checksum. `tools\package.ps1 -BuildFlavor Debug` creates the non-publishable `build\debug\FABRIC-<version>-debug.zip`. Packaging extracts the archive and verifies the required FABRIC service and generated build profile are present. Each package contains a `buildFlavor` manifest field, so CET or a future settings UI can display the deployed flavor without parsing the ZIP name.
- `tools\smoke.ps1` opens the versioned in-game test checklist.

The project-level `.redscript` file configures source roots for Redscript IDE. Configure the editor extension with your own game directory. REDscript compilation is ultimately validated by the game/compiler on your local installation.

The build profile is intentionally separate from CET or future Mod Settings controls. A debug build defaults to TRACE, DEBUG, INFO, WARN, and ERROR. A release build defaults to INFO, WARN, and ERROR; `FabricConfig.SetVerboseLoggingEnabled()` can enable TRACE/DEBUG for the current game session when invoked by a support tool. Until a support control is available, use the debug package when verbose logs are required.

#### WolvenKit CLI

Install [WolvenKit/WolvenKit](https://github.com/WolvenKit/WolvenKit) CLI and make `cp77tools` available on `PATH`. FABRIC's release pipeline assumes package assets will be built and validated with WolvenKit: the build system will use it to process and pack supported REDengine assets into release-ready archives alongside the REDscript payload.

The current source tree does not yet contain package assets, but asset handling is a required build-system capability—not an optional future workflow. When asset sources are added, `verify` and `package` must invoke the relevant WolvenKit validation/packing commands and include the resulting archives at their game-relative release paths.

## Release layout

The release ZIP is game-root-relative and contains `r6\scripts\FABRIC\...`, `FABRIC-manifest.json`, this README, and `LICENSE`. Extract it into the Cyberpunk 2077 game directory.

## License and third-party terms

FABRIC's original source code is licensed under the [MIT License](LICENSE), copyright © 2026 Stephen R. Fonden.

This license applies only to FABRIC's original code. Cyberpunk 2077, its assets, and the required or optional third-party mods remain subject to their respective licenses and terms. Use and distribution of FABRIC as a Cyberpunk 2077 mod must comply with CD PROJEKT RED's game terms and Fan Content Guidelines. FABRIC does not include Equipment-EX, Codeware, WEAVE, Mod Settings, or shared `Logs.reds` in its release archive.

## Development disclosure

FABRIC was developed using Kiro IDE with assistance from OpenAI Codex. AI was used as a coding and documentation collaborator for research, implementation drafts, and testing support. GoldFarmer directed the work, reviewed changes, and performed in-game validation.
