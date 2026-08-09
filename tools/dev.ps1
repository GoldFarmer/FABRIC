[CmdletBinding(SupportsShouldProcess)]
param(
  [string]$GameDir,
  [ValidateSet('Debug', 'Release')]
  [string]$BuildFlavor = 'Debug'
)

. (Join-Path $PSScriptRoot 'common.ps1')

$game = Get-FabricGameDir -GameDir $GameDir
$files = @(Assert-FabricSource)
$destination = Join-Path $game 'r6\scripts\FABRIC'
$profileTemplate = Join-Path (Get-FabricRoot) "tools\templates\FabricBuildProfile.$($BuildFlavor.ToLowerInvariant()).reds"

if ($PSCmdlet.ShouldProcess($destination, 'Install unbundled FABRIC REDscript sources')) {
  New-Item -ItemType Directory -Path $destination -Force | Out-Null
  foreach ($file in $files) {
    $relative = $file.FullName.Substring((Join-Path (Get-FabricRoot) 'src\FABRIC').Length).TrimStart('\')
    $target = Join-Path $destination $relative
    New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
    Copy-Item -LiteralPath $file.FullName -Destination $target -Force
  }
  Copy-Item -LiteralPath $profileTemplate -Destination (Join-Path $destination 'FabricBuildProfile.reds') -Force
  Write-Host "Installed $($files.Count + 1) $BuildFlavor script file(s) beneath $destination. Start the game and inspect REDscript logs for compilation results."
}
