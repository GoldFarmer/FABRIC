[CmdletBinding()]
param(
  [ValidateSet('Release', 'Debug')]
  [string]$BuildFlavor = 'Release'
)

. (Join-Path $PSScriptRoot 'common.ps1')

$root = Get-FabricRoot
$null = @(Assert-FabricSource)
$manifestPath = Join-Path $root 'release\manifest-template.json'
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$build = Join-Path $root 'build'
$flavor = $BuildFlavor.ToLowerInvariant()
$stage = Join-Path $build "stage\$flavor"
$release = Join-Path $build $flavor
$redCliOutput = Join-Path $build 'red-cli'
$packageName = "$($manifest.name)-$($manifest.version)-$flavor.zip"
$packagePath = Join-Path $release $packageName
$redCliArchive = Join-Path $redCliOutput $packageName
$redCliRootArchive = Join-Path $root "$($manifest.name)-$($manifest.version).zip"
$fabricSource = Join-Path $root 'src\FABRIC'
$profileTemplate = Join-Path $root "tools\templates\FabricBuildProfile.$flavor.reds"
$loggingTemplate = Join-Path $root "tools\templates\FabricLogBackend.$flavor.reds"
$redCli = Get-FabricRedCli

if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
New-Item -ItemType Directory -Path $redCliOutput -Force | Out-Null
if (Test-Path -LiteralPath $redCliArchive) { Remove-Item -LiteralPath $redCliArchive -Force }
& $redCli pack
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $redCliRootArchive)) {
  throw 'Red CLI failed to create the bundled REDscript release archive.'
}
Move-Item -LiteralPath $redCliRootArchive -Destination $redCliArchive -Force
New-Item -ItemType Directory -Path $stage -Force | Out-Null
$scriptsStage = Join-Path $stage 'r6\scripts\FABRIC'
New-Item -ItemType Directory -Path $scriptsStage -Force | Out-Null
Copy-Item -Path (Join-Path $fabricSource '*') -Destination $scriptsStage -Recurse -Force
Copy-Item -LiteralPath $profileTemplate -Destination (Join-Path $scriptsStage 'FabricBuildProfile.reds') -Force
Copy-Item -LiteralPath $loggingTemplate -Destination (Join-Path $scriptsStage 'diagnostics\FabricLogBackend.reds') -Force
Copy-Item -LiteralPath (Join-Path $root 'README.md') -Destination (Join-Path $scriptsStage 'README.md') -Force
Copy-Item -LiteralPath (Join-Path $root 'LICENSE') -Destination (Join-Path $scriptsStage 'LICENSE') -Force

New-Item -ItemType Directory -Path $release -Force | Out-Null
if (Test-Path -LiteralPath $packagePath) { Remove-Item -LiteralPath $packagePath -Force }
Compress-Archive -Path (Join-Path $stage 'r6') -DestinationPath $packagePath -Force
$checksum = (Get-FileHash -LiteralPath $packagePath -Algorithm SHA256).Hash.ToLowerInvariant()
Set-Content -LiteralPath "$packagePath.sha256" -Value "$checksum  $packageName" -NoNewline

$verifyPath = Join-Path $stage '_verify'
Expand-Archive -LiteralPath $packagePath -DestinationPath $verifyPath -Force
$topLevel = @(Get-ChildItem -LiteralPath $verifyPath -Force)
if ($topLevel.Count -ne 1 -or $topLevel[0].Name -ne 'r6' -or -not $topLevel[0].PSIsContainer) {
  throw 'Package validation failed: archive must contain only the game-root r6 directory.'
}
if (-not (Test-Path -LiteralPath (Join-Path $verifyPath 'r6\scripts\FABRIC\core\FabricService.reds'))) {
  throw 'Package validation failed: expected FABRIC service source is missing.'
}
if (-not (Test-Path -LiteralPath (Join-Path $verifyPath 'r6\scripts\FABRIC\FabricBuildProfile.reds'))) {
  throw 'Package validation failed: expected generated build profile is missing.'
}
if (-not (Test-Path -LiteralPath (Join-Path $verifyPath 'r6\scripts\FABRIC\diagnostics\FabricLogBackend.reds'))) {
  throw 'Package validation failed: expected generated logging backend is missing.'
}
if (-not (Test-Path -LiteralPath (Join-Path $verifyPath 'r6\scripts\FABRIC\README.md')) -or
  -not (Test-Path -LiteralPath (Join-Path $verifyPath 'r6\scripts\FABRIC\LICENSE'))) {
  throw 'Package validation failed: expected FABRIC documentation is missing.'
}
if ($flavor -eq 'release') {
  $nativeLogCalls = Get-ChildItem -LiteralPath (Join-Path $verifyPath 'r6\scripts\FABRIC') -Filter '*.reds' -Recurse |
    Select-String -Pattern '(?<![A-Za-z])(Log|LogWarning|LogError|LogChannel|LogChannelWarning|LogChannelError|FTLog|FTLogWarning|FTLogError)\s*\('
  if ($nativeLogCalls) {
    throw 'Package validation failed: release scripts must not call native logging functions.'
  }
}
Remove-Item -LiteralPath $verifyPath -Recurse -Force
Write-Host "Created $packagePath"
Write-Host "SHA-256: $checksum"
