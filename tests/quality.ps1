[CmdletBinding()]
param(
  [string]$Root = (Split-Path -Parent $PSScriptRoot)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$sourceRoot = Join-Path $Root 'src'
$sourceFiles = @(Get-ChildItem -LiteralPath $sourceRoot -Recurse -File -Filter '*.reds')
if ($sourceFiles.Count -eq 0) {
  throw 'Quality check requires at least one REDscript source file.'
}

foreach ($sourceFile in $sourceFiles) {
  $lines = Get-Content -LiteralPath $sourceFile.FullName
  for ($lineIndex = 0; $lineIndex -lt $lines.Count; $lineIndex += 1) {
    if ($lines[$lineIndex].Length -gt 120) {
      throw "REDscript line exceeds 120 characters: $($sourceFile.FullName):$($lineIndex + 1)"
    }
  }

  $sourceText = $lines -join "`n"
  if ($sourceText -match 'Phase\s+\d|TODO|FIXME') {
    throw "Planning or unresolved-work marker found in source: $($sourceFile.FullName)"
  }

  for ($lineIndex = 0; $lineIndex -lt $lines.Count; $lineIndex += 1) {
    if ($lines[$lineIndex] -notmatch '^\s*(public|private|protected)\s+.*\b(class|func)\b') {
      continue
    }

    $hasDocstring = $false
    for ($previousIndex = $lineIndex - 1; $previousIndex -ge 0 -and $previousIndex -ge $lineIndex - 16; $previousIndex -= 1) {
      if ($lines[$previousIndex] -match '^\s*/\*\*') {
        $hasDocstring = $true
        break
      }
    }
    if (-not $hasDocstring) {
      throw "Missing declaration docstring: $($sourceFile.FullName):$($lineIndex + 1)"
    }

    if ($lines[$lineIndex] -match '\bfunc\b') {
      $docBlock = ($lines[[Math]::Max(0, $lineIndex - 16)..($lineIndex - 1)] -join "`n")
      foreach ($tag in '@param', '@return', '@errors') {
        if ($docBlock -notmatch [regex]::Escape($tag)) {
          throw "Incomplete function contract ($tag): $($sourceFile.FullName):$($lineIndex + 1)"
        }
      }
    }
  }
}

$servicePath = Join-Path $sourceRoot 'FABRIC\core\FabricService.reds'
$serviceText = Get-Content -LiteralPath $servicePath -Raw
$removedIncrementalSymbols = @(
  'OnOutfitCreated', 'OnOutfitDeleted', 'OnOutfitModified', 'ReconcileOutfit',
  'SnapshotBeforeMutation', 'm_outfitSnapshots', 'GetPairValidationSummary'
)
foreach ($symbol in $removedIncrementalSymbols) {
  if ($serviceText -match [regex]::Escape($symbol)) {
    throw "Removed incremental-cache symbol remains in FabricService: $symbol"
  }
}

$requiredDocumentedSymbols = @(
  'FabricUsageIndexUpdated', 'FabricWardrobeMutation', 'FabricOutfitUsageTooltip',
  'FabricService', 'FabricConfig', 'FabricLog', 'FabricMarkerStyle'
)
foreach ($symbol in $requiredDocumentedSymbols) {
  $matchingFile = $sourceFiles | Where-Object { (Get-Content -LiteralPath $_.FullName -Raw) -match [regex]::Escape($symbol) } | Select-Object -First 1
  if ($null -eq $matchingFile) {
    throw "Expected documented FABRIC symbol is missing: $symbol"
  }
}

Write-Host "Source quality checks passed for $($sourceFiles.Count) REDscript file(s)."
