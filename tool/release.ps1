# Create release tag vX.Y.Z, bump apps/zephyr pubspec version, push to origin.
# Pushing the tag triggers .github/workflows/release.yml (GitHub Release + artifacts).
#
# Usage:
#   .\tool\release.ps1 1.0.4
#   .\tool\release.ps1 v1.0.4
#   .\tool\release.ps1 1.0.4 -DryRun

param(
  [Parameter(Mandatory = $true, Position = 0)]
  [string]$Version,

  [switch]$DryRun,

  # Tag current HEAD without bumping pubspec or making a commit.
  [switch]$TagOnly
)

$ErrorActionPreference = 'Stop'

function Write-Step([string]$Message) {
  Write-Host "==> $Message" -ForegroundColor Cyan
}

$semver = $Version.Trim()
if ($semver.StartsWith('v')) {
  $semver = $semver.Substring(1)
}

if ($semver -notmatch '^\d+\.\d+\.\d+([\-+][\w.\-]+)?$') {
  throw "Version must look like 1.2.3 (optional -prerelease). Got: $Version"
}

$tag = "v$semver"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location $repoRoot

Write-Step "Repository: $repoRoot"

$branch = (git rev-parse --abbrev-ref HEAD).Trim()
if ($branch -ne 'main') {
  throw "Release from main (current branch: $branch)."
}

$upstream = (git rev-parse --abbrev-ref '@{u}' 2>$null)
if (-not $upstream) {
  throw "main has no upstream. Run: git push -u origin main"
}

$behind = [int](git rev-list --count "HEAD..@{u}" 2>$null)
$ahead = [int](git rev-list --count "@{u}..HEAD" 2>$null)
if ($behind -gt 0) {
  throw "main is $behind commit(s) behind $upstream. Pull first."
}

$pubspecPath = Join-Path $repoRoot 'apps/zephyr/pubspec.yaml'
if (-not (Test-Path $pubspecPath)) {
  throw "Missing $pubspecPath"
}

if (git rev-parse -q --verify "refs/tags/$tag" 2>$null) {
  throw "Tag $tag already exists locally."
}

git fetch --tags origin 2>$null | Out-Null
$remoteTag = git ls-remote --tags origin "refs/tags/$tag"
if ($remoteTag -and $remoteTag.Trim()) {
  throw "Tag $tag already exists on origin."
}

$status = git status --porcelain
if ($status -and -not $TagOnly) {
  throw "Working tree is not clean. Commit or stash changes first, or use -TagOnly."
}
if ($status -and $TagOnly) {
  Write-Host "Warning: working tree has uncommitted changes (-TagOnly)." -ForegroundColor Yellow
}

$commitMessage = "chore(release): $tag"

if (-not $TagOnly) {
  Write-Step "Updating apps/zephyr/pubspec.yaml to $semver"
  $pubspec = Get-Content -Raw -Path $pubspecPath
  if ($pubspec -notmatch '(?m)^version:\s*(\d+\.\d+\.\d+)(\+(\d+))?\s*$') {
    throw "Could not parse version: line in $pubspecPath"
  }

  $currentName = $Matches[1]
  $currentBuild = if ($Matches[3]) { [int]$Matches[3] } else { 0 }
  $newBuild = if ($currentName -eq $semver) { $currentBuild + 1 } else { 1 }
  $newVersionLine = "version: $semver+$newBuild"

  $pubspec = [regex]::Replace(
    $pubspec,
    '(?m)^version:\s*.+$',
    $newVersionLine,
    1
  )
  Set-Content -Path $pubspecPath -Value $pubspec -NoNewline -Encoding utf8

  $diff = git diff --name-only -- $pubspecPath
  if ($diff) {
    if ($DryRun) {
      Write-Host "[dry-run] would commit: $pubspecPath ($newVersionLine)"
    } else {
      git add -- $pubspecPath
      git commit -m $commitMessage
    }
  }
}

if ($DryRun) {
  Write-Host "[dry-run] would tag: $tag"
  Write-Host "[dry-run] would push: origin $branch and origin $tag"
  exit 0
}

Write-Step "Creating annotated tag $tag"
git tag -a $tag -m "Zephyr $tag"

Write-Step "Pushing $branch and $tag to origin"
git push origin $branch
git push origin $tag

Write-Host ""
Write-Host "Done. Watch the Release workflow:" -ForegroundColor Green
Write-Host "  https://github.com/$(git remote get-url origin | ForEach-Object { if ($_ -match 'github\.com[:/](.+?)(?:\.git)?$') { $Matches[1] } })/actions/workflows/release.yml"
