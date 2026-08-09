Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-FabricRoot {
  return (Split-Path -Parent $PSScriptRoot)
}

function Get-FabricGameDir {
  param([string]$GameDir)

  if ([string]::IsNullOrWhiteSpace($GameDir)) {
    $GameDir = $env:FABRIC_GAME_DIR
  }
  if ([string]::IsNullOrWhiteSpace($GameDir)) {
    throw 'Set FABRIC_GAME_DIR or pass -GameDir to target your Cyberpunk 2077 installation.'
  }

  $resolved = (Resolve-Path -LiteralPath $GameDir -ErrorAction Stop).Path
  $exe = Join-Path $resolved 'bin\x64\Cyberpunk2077.exe'
  $scripts = Join-Path $resolved 'r6\scripts'
  if (-not (Test-Path -LiteralPath $exe) -or -not (Test-Path -LiteralPath $scripts)) {
    throw "GameDir is not a Cyberpunk 2077 installation: $resolved"
  }
  return $resolved
}

function Get-FabricVersion {
  $manifest = Join-Path (Get-FabricRoot) 'release\manifest-template.json'
  return (Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json).version
}

function Get-FabricRedCli {
  $candidates = @()
  if (-not [string]::IsNullOrWhiteSpace($env:FABRIC_RED_CLI)) { $candidates += $env:FABRIC_RED_CLI }
  $command = Get-Command 'red-cli' -ErrorAction SilentlyContinue
  if ($null -ne $command) { $candidates += $command.Source }
  $candidates += 'C:\Tools\red-cli\red-cli.exe'

  foreach ($candidate in $candidates) {
    if (Test-Path -LiteralPath $candidate) {
      return (Resolve-Path -LiteralPath $candidate).Path
    }
  }
  throw 'Red CLI was not found. Set FABRIC_RED_CLI or add red-cli.exe to PATH.'
}

function Assert-FabricSource {
  $source = Join-Path (Get-FabricRoot) 'src\FABRIC'
  if (-not (Test-Path -LiteralPath $source)) {
    throw "Source directory does not exist yet: $source. Complete Task 2.1 before running this command."
  }
  $files = @(Get-ChildItem -LiteralPath $source -Recurse -File -Filter '*.reds')
  if ($files.Count -eq 0) {
    throw "No .reds files found under $source. Complete the Phase 2 source scaffold before running this command."
  }
  return $files
}
