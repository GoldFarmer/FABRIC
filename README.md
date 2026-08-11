# FABRIC

FABRIC is a REDscript mod for Cyberpunk 2077 that surfaces relationships between Equipment-EX clothing items and saved outfits.

The canonical source, implementation documentation, and issue tracker are maintained at
[GoldFarmer/FABRIC](https://github.com/GoldFarmer/FABRIC). Nexus is the release-download page.

## Runtime dependencies

Required:

- Cyberpunk 2077 with compatible REDscript and RED4ext installations.
- Equipment-EX, which is FABRIC's saved-outfit authority.
- Codeware, which provides FABRIC's service lifecycle and error call-site context.

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

#### Debug logging declarations

Release packages use a no-op logging backend and do not need shared logging declarations. Debug
builds write diagnostics through the engine `FTLog` APIs, which require the shared global
declarations from the [REDscript logging reference](https://wiki.redmodding.org/redscript/references-and-examples/logging) at `r6\scripts\Logs.reds`. `tools\dev.ps1 -BuildFlavor Debug` creates that file when it is absent; `-BuildFlavor Release` removes it for a clean release test. The separate guarded installer remains available when needed:

```powershell
.\tools\install-logging-api.ps1 -GameDir $env:FABRIC_GAME_DIR
```

They expose `LogChannel*`, `Log*`, and `FTLog*` functions. FABRIC's debug backend uses the `FTLog` severity functions once per message and adds Codeware call-site context to errors. The installer refuses to overwrite an existing shared declaration. This file is a game-level development prerequisite: do not place it under FABRIC or include it in a FABRIC release ZIP, because multiple bundled copies would conflict. A Release development install removes this shared file, so do not use that mode while another source mod needs the declarations for debug logging.

Commands are repository-owned PowerShell scripts:

- `tools\verify.ps1` validates project/release structure and enforces REDscript source-quality checks: 120-character line width, no planning markers in source, and removal of the unsupported incremental-cache API. `-RequireTypeCheck` remains reserved for a compiler adapter; use REDscript IDE diagnostics until it is implemented.
- `tools\dev.ps1 -BuildFlavor Debug -WhatIf` previews the default debug installation. `Debug` installs generated `FabricBuildProfile.reds` and `FabricLogBackend.reds` files and creates missing root-level `Logs.reds`; `Release` installs a no-op logging backend and removes that root-level declarations file.
- `tools\package.ps1 -BuildFlavor Release` creates the publishable `build\release\FABRIC-<version>-release.zip` with a SHA-256 checksum. `tools\package.ps1 -BuildFlavor Debug` creates the non-publishable `build\debug\FABRIC-<version>-debug.zip`. Packaging extracts each archive, verifies that it contains only the game-root `r6` directory, validates the required FABRIC service, generated build profile, and generated logging backend, and rejects a release archive with a native logging call.
- `tools\smoke.ps1` opens the versioned in-game test checklist.

The project-level `.redscript` file configures source roots for Redscript IDE. Configure the editor extension with your own game directory. REDscript compilation is ultimately validated by the game/compiler on your local installation.

The build profile is intentionally separate from CET or future Mod Settings controls. Release builds contain no native logging calls. Debug builds default to TRACE, DEBUG, INFO, WARN, and ERROR; use a debug package with the shared declarations installed when diagnostics are required.

#### WolvenKit CLI

Install [WolvenKit/WolvenKit](https://github.com/WolvenKit/WolvenKit) CLI and make `cp77tools` available on `PATH`. FABRIC's release pipeline assumes package assets will be built and validated with WolvenKit: the build system will use it to process and pack supported REDengine assets into release-ready archives alongside the REDscript payload.

The current source tree does not yet contain package assets, but asset handling is a required build-system capability—not an optional future workflow. When asset sources are added, `verify` and `package` must invoke the relevant WolvenKit validation/packing commands and include the resulting archives at their game-relative release paths.

## Release layout

The release ZIP contains only the game-root `r6` directory. Extract the entire ZIP into the Cyberpunk 2077 game directory so that FABRIC installs at `r6\scripts\FABRIC\...`. The bundled README and MIT license are kept inside that FABRIC directory, not in the game root.

## License and third-party terms

FABRIC's original source code is licensed under the [MIT License](LICENSE), copyright © 2026 Stephen R. Fonden.

This license applies only to FABRIC's original code. Cyberpunk 2077, its assets, and the required or optional third-party mods remain subject to their respective licenses and terms. Use and distribution of FABRIC as a Cyberpunk 2077 mod must comply with CD PROJEKT RED's game terms and Fan Content Guidelines. FABRIC does not include Equipment-EX, Codeware, WEAVE, Mod Settings, or shared `Logs.reds` in its release archive.

## Development disclosure

FABRIC was developed using Kiro IDE with assistance from OpenAI Codex. AI was used as a coding and documentation collaborator for research, implementation drafts, and testing support. GoldFarmer directed the work, reviewed changes, and performed in-game validation.
