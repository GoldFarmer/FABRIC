[CmdletBinding()]
param(
  [string]$GameDir,
  [switch]$RequireTypeCheck
)

. (Join-Path $PSScriptRoot 'common.ps1')

$root = Get-FabricRoot
$required = @(
  '.redscript', 'release\manifest-template.json', 'release\nexus-metadata.md', 'release\nexus-listing.bbcode',
  'release\nexus-publish.json',
  'tools\dev.ps1', 'tools\package.ps1', 'tools\publish.ps1',
  'docs\smoke-test.md', 'tests\quality.ps1'
)
foreach ($relative in $required) {
  if (-not (Test-Path -LiteralPath (Join-Path $root $relative))) {
    throw "Required project file is missing: $relative"
  }
}

$manifest = Get-Content -LiteralPath (Join-Path $root 'release\manifest-template.json') -Raw | ConvertFrom-Json
if ([string]::IsNullOrWhiteSpace($manifest.name) -or [string]::IsNullOrWhiteSpace($manifest.version)) {
  throw 'Release manifest must contain non-empty name and version fields.'
}
if ($manifest.version -notmatch '^\d+\.\d+\.\d+([-.][0-9A-Za-z.-]+)?$') {
  throw "Release manifest version is not SemVer-like: $($manifest.version)"
}

$source = Join-Path $root 'src'
if (Test-Path -LiteralPath $source) {
  $scripts = @(Get-ChildItem -LiteralPath $source -Recurse -File -Filter '*.reds')
  if ($scripts.Count -eq 0) { throw 'src exists but contains no .reds files.' }
  foreach ($script in $scripts) {
    $text = Get-Content -LiteralPath $script.FullName -Raw
    if ($text -match '<<<<<<<|=======|>>>>>>>') { throw "Merge marker found: $($script.FullName)" }
  }
}

& (Join-Path $root 'tests\quality.ps1') -Root $root

if ($RequireTypeCheck) {
  $game = Get-FabricGameDir -GameDir $GameDir
  $compiler = Join-Path $game 'engine\tools\scc.exe'
  if (-not (Test-Path -LiteralPath $compiler)) {
    throw "REDscript compiler not found: $compiler"
  }
  throw 'Automated compiler invocation is intentionally deferred until FABRIC has a compilable Phase 2 source tree. Use Redscript IDE diagnostics now; this command will gain a compiler adapter with the first source module.'
}

Write-Host "Structural verification passed for FABRIC $($manifest.version)."
