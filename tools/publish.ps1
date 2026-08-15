[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
  [ValidateSet('NewFile', 'NewVersion')]
  [string]$PublishMode = 'NewVersion',
  [string]$ModId,
  [string]$ModFileId,
  [Parameter(Mandatory)]
  [ValidateLength(1, 65535)]
  [string]$Changelog,
  [ValidateSet('main', 'optional', 'miscellaneous')]
  [string]$FileCategory = 'main',
  [bool]$PrimaryModManagerDownload = $true,
  [bool]$AllowModManagerDownload = $true,
  [bool]$ShowRequirementsPopup = $true,
  [ValidateRange(1, 3600)]
  [int]$UploadTimeoutSeconds = 300,
  [ValidateRange(1, 60)]
  [int]$UploadPollSeconds = 5,
  [switch]$Publish
)

. (Join-Path $PSScriptRoot 'common.ps1')

function Get-NexusData {
  param(
    [Parameter(Mandatory)]
    [object]$Response,
    [Parameter(Mandatory)]
    [string]$Operation
  )

  if ($null -eq $Response -or $null -eq $Response.data) {
    throw "Nexus API $Operation returned no data payload."
  }
  return $Response.data
}

function Invoke-NexusApi {
  param(
    [Parameter(Mandatory)]
    [ValidateSet('Get', 'Post')]
    [string]$Method,
    [Parameter(Mandatory)]
    [string]$Path,
    [object]$Body,
    [Parameter(Mandatory)]
    [hashtable]$Headers
  )

  $request = @{
    Uri = "https://api.nexusmods.com/v3$Path"
    Method = $Method
    Headers = $Headers
    ErrorAction = 'Stop'
  }
  if ($null -ne $Body) {
    $request.ContentType = 'application/json'
    $request.Body = $Body | ConvertTo-Json -Depth 12 -Compress
  }

  try {
    return Invoke-RestMethod @request
  }
  catch {
    $details = $_.ErrorDetails.Message
    if ([string]::IsNullOrWhiteSpace($details)) { $details = $_.Exception.Message }
    throw "Nexus API $Method $Path failed: $details"
  }
}

function Send-NexusArchive {
  param(
    [Parameter(Mandatory)]
    [string]$PresignedUrl,
    [Parameter(Mandatory)]
    [string]$ArchivePath,
    [Parameter(Mandatory)]
    [string]$ArchiveName,
    [string]$ContentType = 'application/octet-stream'
  )

  # Use HttpWebRequest directly to avoid Invoke-WebRequest adding Transfer-Encoding: chunked or
  # other headers outside the presigned URL's signed set (content-disposition, content-type, host).
  $bytes = [System.IO.File]::ReadAllBytes($ArchivePath)

  # Try candidates in order: 'application/octet-stream' (AWS SDK JS v3 presigned default),
  # 'application/zip', and empty string (if Content-Type header was omitted in presigned signature).
  $contentTypesToTry = @($ContentType, 'application/octet-stream', 'application/zip', '') | Select-Object -Unique

  $lastException = $null
  foreach ($ct in $contentTypesToTry) {
    $request = [System.Net.HttpWebRequest]::Create($PresignedUrl)
    $request.Method = 'PUT'
    if ([string]::IsNullOrWhiteSpace($ct)) {
      $request.ContentType = $null
    }
    else {
      $request.ContentType = $ct
    }
    $request.Headers.Add('Content-Disposition', "attachment; filename=`"$ArchiveName`"")
    $request.ContentLength = $bytes.Length
    $request.AllowWriteStreamBuffering = $false
    try {
      $stream = $request.GetRequestStream()
      $stream.Write($bytes, 0, $bytes.Length)
      $stream.Close()
      $response = $request.GetResponse()
      $response.Close()
      return
    }
    catch [System.Net.WebException] {
      $body = ''
      if ($null -ne $_.Exception.Response) {
        $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
        $body = $reader.ReadToEnd()
        $reader.Close()
      }
      $lastException = "Nexus archive upload failed (Content-Type: '$ct'): $body"
      if ($body -match 'SignatureDoesNotMatch' -and $ct -ne $contentTypesToTry[-1]) {
        Write-Verbose "Upload with Content-Type '$ct' returned SignatureDoesNotMatch; retrying with next Content-Type candidate..."
        continue
      }
      throw $lastException
    }
  }
  throw $lastException
}

$root = Get-FabricRoot
$manifest = Get-Content -LiteralPath (Join-Path $root 'release\manifest-template.json') -Raw | ConvertFrom-Json
$version = $manifest.version
$packageName = "$($manifest.name)-$version-release.zip"
$packagePath = Join-Path $root "build\release\$packageName"
$checksumPath = "$packagePath.sha256"
$metadataPath = Join-Path $root 'release\nexus-metadata.md'
$listingPath = Join-Path $root 'release\nexus-listing.bbcode'
$publishConfigPath = Join-Path $root 'release\nexus-publish.json'

if (-not (Test-Path -LiteralPath $packagePath -PathType Leaf)) {
  throw "Release archive is missing: $packagePath. Run tools\\package.ps1 -BuildFlavor Release first."
}
if (-not (Test-Path -LiteralPath $checksumPath -PathType Leaf)) {
  throw "Release checksum is missing: $checksumPath. Run tools\\package.ps1 -BuildFlavor Release first."
}
if (-not (Test-Path -LiteralPath $metadataPath -PathType Leaf) -or -not (Test-Path -LiteralPath $listingPath -PathType Leaf)) {
  throw 'Nexus metadata or BBCode listing source is missing under release.'
}
if (-not (Test-Path -LiteralPath $publishConfigPath -PathType Leaf)) {
  throw "Nexus publish configuration is missing: $publishConfigPath"
}

$publishConfig = Get-Content -LiteralPath $publishConfigPath -Raw | ConvertFrom-Json
foreach ($property in 'gameDomain', 'modPageId', 'modId', 'mainFileId', 'fileCategory', 'fileNameTemplate') {
  if ($null -eq $publishConfig.$property -or [string]::IsNullOrWhiteSpace([string]$publishConfig.$property)) {
    throw "Nexus publish configuration has no usable '$property' value."
  }
}
if (-not $PSBoundParameters.ContainsKey('ModFileId')) { $ModFileId = $publishConfig.mainFileId }
if (-not $PSBoundParameters.ContainsKey('FileCategory')) { $FileCategory = $publishConfig.fileCategory }
if ($FileCategory -notin 'main', 'optional', 'miscellaneous') {
  throw "Nexus publish configuration has an unsupported fileCategory: $FileCategory"
}
$nexusFileName = $publishConfig.fileNameTemplate.Replace('{version}', $version)
if ($nexusFileName.Length -gt 50 -or $nexusFileName -notmatch "^[a-zA-Z0-9 _'().-]+$") {
  throw "Nexus file name is invalid after applying fileNameTemplate: $nexusFileName"
}
if ([string]::IsNullOrWhiteSpace($ModFileId) -and $PublishMode -eq 'NewVersion') {
  throw 'NewVersion publishing requires a ModFileId.'
}

$checksumLine = (Get-Content -LiteralPath $checksumPath -Raw).Trim()
if ($checksumLine -notmatch '^(?<hash>[0-9A-Fa-f]{64})\s{2}(?<name>.+)$') {
  throw "Release checksum has an unexpected format: $checksumPath"
}
if ($Matches.name -ne $packageName) {
  throw "Release checksum names '$($Matches.name)' instead of '$packageName'."
}
$actualHash = (Get-FileHash -LiteralPath $packagePath -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actualHash -ne $Matches.hash.ToLowerInvariant()) {
  throw "Release checksum does not match archive: $packagePath"
}
$archiveBytes = (Get-Item -LiteralPath $packagePath).Length
if ($archiveBytes -gt 100MB) {
  throw 'Release archive exceeds the 100 MiB single-part Nexus upload limit. Add multipart upload support before publishing this archive.'
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::OpenRead($packagePath)
try {
  $entries = @($archive.Entries | ForEach-Object {
    [PSCustomObject]@{ Path = $_.FullName.Replace('\', '/') }
  } | Where-Object { -not [string]::IsNullOrWhiteSpace($_.Path) })
  if ($entries.Count -eq 0 -or @($entries | Where-Object { $_.Path -notmatch '^r6/' }).Count -gt 0) {
    throw 'Release archive must contain only game-root r6 content.'
  }
  if (@($entries | Where-Object { $_.Path -eq 'r6/scripts/FABRIC/README.md' }).Count -ne 1 -or
      @($entries | Where-Object { $_.Path -eq 'r6/scripts/FABRIC/LICENSE' }).Count -ne 1) {
    throw 'Release archive is missing the bundled FABRIC README or LICENSE.'
  }
}
finally {
  $archive.Dispose()
}

$target = if ($PublishMode -eq 'NewFile') { 'POST /mod-files' } else { "POST /mod-files/$ModFileId/versions" }
$plan = [ordered]@{
  Mode = $PublishMode
  NexusTarget = $target
  GameDomain = $publishConfig.gameDomain
  ModPageId = $publishConfig.modPageId
  ModIdOverride = if ([string]::IsNullOrWhiteSpace($ModId)) { '<from tracked configuration>' } else { $ModId }
  ModFileId = if ($PublishMode -eq 'NewVersion') { $ModFileId } else { '<created by Nexus>' }
  Archive = $packagePath
  ArchiveBytes = $archiveBytes
  SHA256 = $actualHash
  Version = $version
  FileName = $packageName
  NexusFileName = $nexusFileName
  FileCategory = $FileCategory
  PrimaryModManagerDownload = $PrimaryModManagerDownload
  AllowModManagerDownload = $AllowModManagerDownload
  ShowRequirementsPopup = $ShowRequirementsPopup
  Changelog = $Changelog
  MetadataSource = $metadataPath
  ListingSource = $listingPath
  PublishConfiguration = $publishConfigPath
}

$plan.GetEnumerator() | ForEach-Object { Write-Host ('{0}: {1}' -f $_.Key, $_.Value) }
if (-not $Publish) {
  Write-Host 'Nexus publish preview only. No API credential was read and no network request was made.'
  Write-Host 'Use -Publish only after reviewing this plan and setting NEXUS_API_KEY in the current shell.'
  return
}

if (-not $PSCmdlet.ShouldProcess("Nexus Mods $PublishMode for $packageName", 'Upload archive and create publication')) {
  return
}

$apiKey = $env:NEXUS_API_KEY
if ([string]::IsNullOrWhiteSpace($apiKey)) {
  throw 'Set NEXUS_API_KEY in the current shell before using -Publish. Never store it in the repository or release files.'
}
$headers = @{ apikey = $apiKey; Accept = 'application/json'; 'User-Agent' = 'FABRIC publish script' }
$resolvedModId = if ([string]::IsNullOrWhiteSpace($ModId)) { [string]$publishConfig.modId } else { $ModId }

# Nexus API v3 endpoints expect the v3 UUID mod ID ($v3ModId).
# If $resolvedModId is a game-scoped numeric ID (e.g. "32441"), resolve its v3 UUID via GET /games/{game}/mods/{id}.
if ($resolvedModId -notmatch '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$') {
  $modData = Get-NexusData -Operation 'get mod details' -Response (Invoke-NexusApi -Method Get -Path "/games/$($publishConfig.gameDomain)/mods/$resolvedModId" -Headers $headers)
  $v3ModId = [string]$modData.id
  if ([string]::IsNullOrWhiteSpace($v3ModId)) {
    throw "Could not resolve Nexus v3 Mod ID for game '$($publishConfig.gameDomain)' and mod '$resolvedModId'."
  }
}
else {
  $v3ModId = $resolvedModId
}

if ($PublishMode -eq 'NewVersion') {
  $targetCheckId = if (-not [string]::IsNullOrWhiteSpace([string]$publishConfig.gameScopedId)) {
    [string]$publishConfig.gameScopedId
  } else {
    $ModFileId
  }

  $v1Files = Invoke-RestMethod -Uri "https://api.nexusmods.com/v1/games/$($publishConfig.gameDomain)/mods/$resolvedModId/files.json" `
    -Headers $headers -ErrorAction Stop
  $activeFile = @($v1Files.files | Where-Object { ([string]$_.file_id -eq $targetCheckId -or [string]$_.file_id -eq $ModFileId) -and $_.category_name -ne 'ARCHIVED' })
  if ($activeFile.Count -eq 0) {
    throw "Nexus mod file $targetCheckId is not active or does not exist. Update release\nexus-publish.json before publishing."
  }
}

$upload = Get-NexusData -Operation 'create upload' -Response (Invoke-NexusApi -Method Post -Path '/uploads' -Body @{
  size_bytes = (Get-Item -LiteralPath $packagePath).Length
  filename = $packageName
} -Headers $headers)
if ([string]::IsNullOrWhiteSpace([string]$upload.id) -or [string]::IsNullOrWhiteSpace([string]$upload.presigned_url)) {
  throw 'Nexus upload creation did not provide an upload ID and presigned URL.'
}

Send-NexusArchive -PresignedUrl $upload.presigned_url -ArchivePath $packagePath -ArchiveName $packageName
$null = Get-NexusData -Operation 'finalise upload' -Response (Invoke-NexusApi -Method Post -Path "/uploads/$($upload.id)/finalise" -Headers $headers)

$deadline = [DateTime]::UtcNow.AddSeconds($UploadTimeoutSeconds)
$uploadState = $null
do {
  Start-Sleep -Seconds $UploadPollSeconds
  $uploadState = Get-NexusData -Operation 'upload status' -Response (Invoke-NexusApi -Method Get -Path "/uploads/$($upload.id)" -Headers $headers)
  if ($uploadState.state -in 'failed', 'cancelled') {
    throw "Nexus upload $($upload.id) entered terminal state '$($uploadState.state)'."
  }
} while ($uploadState.state -ne 'available' -and [DateTime]::UtcNow -lt $deadline)
if ($uploadState.state -ne 'available') {
  throw "Nexus upload $($upload.id) did not become available within $UploadTimeoutSeconds seconds."
}

$filePayload = [ordered]@{
  upload_id = $upload.id
  name = $nexusFileName
  version = $version
  description = $Changelog
  file_category = $FileCategory
  primary_mod_manager_download = $PrimaryModManagerDownload
  allow_mod_manager_download = $AllowModManagerDownload
  show_requirements_pop_up = $ShowRequirementsPopup
  update_mod_version = $true
}
if ($PublishMode -eq 'NewVersion') {
  $targetGroupId = if (-not [string]::IsNullOrWhiteSpace([string]$publishConfig.gameScopedId)) {
    [string]$publishConfig.gameScopedId
  } else {
    $ModFileId
  }

  $created = Get-NexusData -Operation 'create update group version' -Response (Invoke-NexusApi -Method Post -Path "/mod-file-update-groups/$targetGroupId/versions" -Body $filePayload -Headers $headers)
}
else {
  $filePayload.mod_id = $v3ModId
  $created = Get-NexusData -Operation 'create mod file' -Response (Invoke-NexusApi -Method Post -Path '/mod-files' -Body $filePayload -Headers $headers)
}

$null = Get-NexusData -Operation 'add changelog entries' -Response (Invoke-NexusApi -Method Post -Path "/mods/$v3ModId/changelogs" -Body @{
  version = $version
  changelog = $Changelog
} -Headers $headers)

# Update the tracked main-file ID so the next NewVersion publish resolves the correct target without a manual override.
$hasFileProp = $null -ne $created.PSObject.Properties['file'] -and $null -ne $created.file
$newFileId = if ($hasFileProp -and $null -ne $created.file.id) { [string]$created.file.id } elseif ($null -ne $created.PSObject.Properties['id']) { [string]$created.id } else { $null }
$newGameScopedId = if ($hasFileProp -and $null -ne $created.file.game_scoped_id) { [string]$created.file.game_scoped_id } elseif ($null -ne $created.PSObject.Properties['game_scoped_id']) { [string]$created.game_scoped_id } else { $null }

if (-not [string]::IsNullOrWhiteSpace($newFileId)) {
  $publishConfig.mainFileId = $newFileId
}
if (-not [string]::IsNullOrWhiteSpace($newGameScopedId)) {
  $publishConfig.gameScopedId = $newGameScopedId
}
if (-not [string]::IsNullOrWhiteSpace($newFileId)) {
  $publishConfig | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $publishConfigPath -Encoding UTF8
  Write-Host "Updated release\nexus-publish.json mainFileId to $newFileId (gameScopedId: $newGameScopedId)."
}
else {
  Write-Host "WARNING: Publication response did not include a file ID. Update release\nexus-publish.json mainFileId manually before the next release."
}

Write-Host "Nexus publication completed for $packageName."
Write-Host "Upload ID: $($upload.id)"
Write-Host "Publication response: $($created | ConvertTo-Json -Depth 6 -Compress)"

# Create or update corresponding GitHub release if gh CLI is available
$ghCli = Get-Command -Name gh -ErrorAction SilentlyContinue
if ($null -ne $ghCli) {
  $tagName = "v$version"
  $title = "$($manifest.name) $version"
  Write-Host "Creating/updating GitHub release '$tagName'..."
  try {
    gh release create $tagName $packagePath $checksumPath --title $title --notes $Changelog --clobber
    Write-Host "GitHub release $tagName published successfully."
  }
  catch {
    Write-Host "WARNING: GitHub release creation via gh CLI failed: $_"
  }
}
else {
  Write-Host "INFO: 'gh' CLI tool is not installed; skipping GitHub release creation."
}
