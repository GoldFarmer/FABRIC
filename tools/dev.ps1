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
$loggingDeclarations = Join-Path $game 'r6\scripts\Logs.reds'
$profileTemplate = Join-Path (Get-FabricRoot) "tools\templates\FabricBuildProfile.$($BuildFlavor.ToLowerInvariant()).reds"
$loggingTemplate = Join-Path (Get-FabricRoot) "tools\templates\FabricLogBackend.$($BuildFlavor.ToLowerInvariant()).reds"
$loggingDeclarationsTemplate = Join-Path (Get-FabricRoot) 'tools\templates\Logs.reds'

if ($PSCmdlet.ShouldProcess($destination, 'Install unbundled FABRIC REDscript sources')) {
  New-Item -ItemType Directory -Path $destination -Force | Out-Null
  foreach ($file in $files) {
    $relative = $file.FullName.Substring((Join-Path (Get-FabricRoot) 'src\FABRIC').Length).TrimStart('\')
    $target = Join-Path $destination $relative
    New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
    Copy-Item -LiteralPath $file.FullName -Destination $target -Force
  }
  Copy-Item -LiteralPath $profileTemplate -Destination (Join-Path $destination 'FabricBuildProfile.reds') -Force
  Copy-Item -LiteralPath $loggingTemplate -Destination (Join-Path $destination 'diagnostics\FabricLogBackend.reds') -Force
  Write-Host "Installed $($files.Count + 2) $BuildFlavor script file(s) beneath $destination. Start the game and inspect REDscript logs for compilation results."
}

if ($BuildFlavor -eq 'Debug' -and -not (Test-Path -LiteralPath $loggingDeclarations -PathType Leaf)) {
  if ($PSCmdlet.ShouldProcess($loggingDeclarations, 'Create shared debug logging declarations')) {
    Copy-Item -LiteralPath $loggingDeclarationsTemplate -Destination $loggingDeclarations
    Write-Host "Created shared debug logging declarations at $loggingDeclarations."
  }
}

if ($BuildFlavor -eq 'Release' -and (Test-Path -LiteralPath $loggingDeclarations -PathType Leaf)) {
  if ($PSCmdlet.ShouldProcess($loggingDeclarations, 'Remove shared logging declarations for a release installation')) {
    Remove-Item -LiteralPath $loggingDeclarations -Force
    Write-Host "Removed shared logging declarations at $loggingDeclarations for the release installation."
  }
}
