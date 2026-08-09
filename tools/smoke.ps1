[CmdletBinding()]
param()

. (Join-Path $PSScriptRoot 'common.ps1')

$root = Get-FabricRoot
$manifest = Get-Content -LiteralPath (Join-Path $root 'release\manifest-template.json') -Raw | ConvertFrom-Json
Write-Host "FABRIC $($manifest.version) smoke test"
Write-Host "Open and complete: $(Join-Path $root 'docs\smoke-test.md')"
Write-Host 'Record the game, REDscript, RED4ext, Equipment-EX, and optional WEAVE versions with the results.'
