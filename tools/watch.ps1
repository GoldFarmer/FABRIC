[CmdletBinding()]
param([string]$GameDir)

. (Join-Path $PSScriptRoot 'common.ps1')

if (-not [string]::IsNullOrWhiteSpace($GameDir)) { $env:REDCLI_GAME = Get-FabricGameDir -GameDir $GameDir }
& (Get-FabricRedCli) watch
