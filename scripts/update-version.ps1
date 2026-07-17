<#
.SYNOPSIS
Updates BitLogger's package version, installation snippets, and release-note entry.

.DESCRIPTION
For patch releases, the public release version is inferred from the latest
changes entry. For example, after 1.1.2(0.7.2), running:

  .\scripts\update-version.ps1 0.7.3

creates 1.1.3(0.7.3). A major or minor package-version change requires an
explicit -ReleaseVersion so the public release sequence is never guessed.

The generated release note uses supplied -Change, -Verification, and -Note
entries. Without them it contains TODO markers that must be completed before
the release is committed.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
  [Parameter(Mandatory, Position = 0)]
  [ValidatePattern('^\d+\.\d+\.\d+$')]
  [string]$Version,

  [ValidatePattern('^\d+\.\d+\.\d+$')]
  [string]$ReleaseVersion,

  [string[]]$Change,
  [string[]]$Verification,
  [string[]]$Note
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Read-TextFile([string]$Path) {
  [System.IO.File]::ReadAllText($Path)
}

function Write-TextFile([string]$Path, [string]$Content) {
  $encoding = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Content, $encoding)
}

function Replace-ExactlyOnce(
  [string]$Content,
  [string]$Pattern,
  [string]$Replacement,
  [string]$Path
) {
  $matches = [regex]::Matches($Content, $Pattern)
  if ($matches.Count -ne 1) {
    throw "Expected exactly one match for '$Pattern' in $Path, found $($matches.Count)."
  }
  [regex]::Replace($Content, $Pattern, $Replacement, 1)
}

function Format-BulletList([string[]]$Items, [string]$Fallback) {
  $entries = if ($null -eq $Items -or $Items.Count -eq 0) {
    @($Fallback)
  } else {
    $Items
  }
  ($entries | ForEach-Object { "- $_" }) -join [Environment]::NewLine
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$moonModPath = Join-Path $repoRoot 'moon.mod'
$changesIndexPath = Join-Path $repoRoot 'docs/changes/index.md'

foreach ($path in @($moonModPath, $changesIndexPath)) {
  if (-not (Test-Path -LiteralPath $path)) {
    throw "Required repository file is missing: $path"
  }
}

$moonMod = Read-TextFile $moonModPath
$currentVersionMatch = [regex]::Match($moonMod, '(?m)^version\s*=\s*"(?<version>\d+\.\d+\.\d+)"\s*$')
if (-not $currentVersionMatch.Success) {
  throw "Could not read the package version from $moonModPath."
}
$currentVersion = [version]$currentVersionMatch.Groups['version'].Value
$targetVersion = [version]$Version
if ($targetVersion -le $currentVersion) {
  throw "Target version $Version must be greater than the current version $currentVersion."
}

$changesIndex = Read-TextFile $changesIndexPath
$latestReleaseMatch = [regex]::Match(
  $changesIndex,
  '(?m)^- \[(?<release>\d+\.\d+\.\d+)\]\(\./(?<file>\d+\.\d+\.\d+\(\d+\.\d+\.\d+\)\.md)\)\s*$'
)
if (-not $latestReleaseMatch.Success) {
  throw "Could not read the latest release entry from $changesIndexPath."
}

$latestReleaseVersion = [version]$latestReleaseMatch.Groups['release'].Value
$latestPackageVersionMatch = [regex]::Match(
  $latestReleaseMatch.Groups['file'].Value,
  '\((?<version>\d+\.\d+\.\d+)\)\.md$'
)
if (-not $latestPackageVersionMatch.Success -or $latestPackageVersionMatch.Groups['version'].Value -ne $currentVersion.ToString()) {
  throw 'The latest changes entry must describe the current moon.mod package version before starting a new release.'
}
if ([string]::IsNullOrWhiteSpace($ReleaseVersion)) {
  if ($targetVersion.Major -ne $currentVersion.Major -or $targetVersion.Minor -ne $currentVersion.Minor) {
    throw 'A major or minor package-version change requires -ReleaseVersion, for example: -ReleaseVersion 1.2.0.'
  }
  $ReleaseVersion = "$($latestReleaseVersion.Major).$($latestReleaseVersion.Minor).$($targetVersion.Build)"
}

$releaseFileName = "$ReleaseVersion($Version).md"
$releasePath = Join-Path $repoRoot "docs/changes/$releaseFileName"
if (Test-Path -LiteralPath $releasePath) {
  throw "Release note already exists: $releasePath"
}
if ($changesIndex.Contains("./$releaseFileName")) {
  throw "Release index already contains: $releaseFileName"
}

$updatedMoonMod = Replace-ExactlyOnce `
  $moonMod `
  '(?m)^version\s*=\s*"\d+\.\d+\.\d+"\s*$' `
  "version = `"$Version`"" `
  $moonModPath

$installFiles = @(
  'README.md',
  'docs/README-en.md',
  'docs/examples/console.md',
  'docs/zh/examples/console.md'
)
$updatedFiles = @{}
foreach ($relativePath in $installFiles) {
  $path = Join-Path $repoRoot $relativePath
  if (-not (Test-Path -LiteralPath $path)) {
    throw "Required installation example is missing: $path"
  }
  $content = Read-TextFile $path
  $updatedFiles[$path] = Replace-ExactlyOnce `
    $content `
    'Nanaloveyuki/BitLogger@\d+\.\d+\.\d+' `
    "Nanaloveyuki/BitLogger@$Version" `
    $path
}

$updatedChangesIndex = $changesIndex.Replace(
  $latestReleaseMatch.Value,
  "- [$ReleaseVersion](./$releaseFileName)$([Environment]::NewLine)$($latestReleaseMatch.Value)"
)

$releaseNote = @"
## BitLogger Update Changes

version $ReleaseVersion($Version)

### Changes

$(Format-BulletList $Change 'TODO: summarize the user-visible changes in this release.')

### Verification

$(Format-BulletList $Verification 'TODO: record the commands and targets verified for this release.')

### Notes

$(Format-BulletList $Note 'TODO: record release limitations or compatibility notes when applicable.')
"@

$writeTargets = @($moonModPath, $changesIndexPath, $releasePath) + $updatedFiles.Keys
if ($PSCmdlet.ShouldProcess(($writeTargets -join ', '), "update to $Version")) {
  Write-TextFile $moonModPath $updatedMoonMod
  foreach ($path in $updatedFiles.Keys) {
    Write-TextFile $path $updatedFiles[$path]
  }
  Write-TextFile $changesIndexPath $updatedChangesIndex
  Write-TextFile $releasePath $releaseNote
}

if ($WhatIfPreference) {
  Write-Output "Previewed release $ReleaseVersion($Version)."
} else {
  Write-Output "Prepared release $ReleaseVersion($Version)."
}
Write-Output "Release notes: $releasePath"
