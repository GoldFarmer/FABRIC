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
$manifest | Add-Member -NotePropertyName 'buildFlavor' -NotePropertyValue $flavor -Force
$manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $stage 'FABRIC-manifest.json')
Copy-Item -LiteralPath $profileTemplate -Destination (Join-Path $scriptsStage 'FabricBuildProfile.reds') -Force
if (Test-Path -LiteralPath (Join-Path $root 'README.md')) {
  Copy-Item -LiteralPath (Join-Path $root 'README.md') -Destination (Join-Path $stage 'README.md') -Force
}
if (Test-Path -LiteralPath (Join-Path $root 'LICENSE')) {
  Copy-Item -LiteralPath (Join-Path $root 'LICENSE') -Destination (Join-Path $stage 'LICENSE') -Force
}

New-Item -ItemType Directory -Path $release -Force | Out-Null
if (Test-Path -LiteralPath $packagePath) { Remove-Item -LiteralPath $packagePath -Force }
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $packagePath -Force
$checksum = (Get-FileHash -LiteralPath $packagePath -Algorithm SHA256).Hash.ToLowerInvariant()
Set-Content -LiteralPath "$packagePath.sha256" -Value "$checksum  $packageName" -NoNewline

$verifyPath = Join-Path $stage '_verify'
Expand-Archive -LiteralPath $packagePath -DestinationPath $verifyPath -Force
if (-not (Test-Path -LiteralPath (Join-Path $verifyPath 'r6\scripts\FABRIC\core\FabricService.reds'))) {
  throw 'Package validation failed: expected FABRIC service source is missing.'
}
if (-not (Test-Path -LiteralPath (Join-Path $verifyPath 'r6\scripts\FABRIC\FabricBuildProfile.reds'))) {
  throw 'Package validation failed: expected generated build profile is missing.'
}
Remove-Item -LiteralPath $verifyPath -Recurse -Force
Write-Host "Created $packagePath"
Write-Host "SHA-256: $checksum"
