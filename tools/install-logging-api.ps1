[CmdletBinding()]
param(
  [string]$GameDir
)

. (Join-Path $PSScriptRoot 'common.ps1')

$root = Get-FabricRoot
$game = Get-FabricGameDir -GameDir $GameDir
$template = Join-Path $root 'tools\templates\Logs.reds'
$destination = Join-Path $game 'r6\scripts\Logs.reds'

if (Test-Path -LiteralPath $destination) {
  throw "Shared logging declaration already exists and will not be overwritten: $destination"
}

Copy-Item -LiteralPath $template -Destination $destination
Write-Host "Installed shared REDscript logging declarations at $destination"
