# Thin Windows wrapper around the cross-platform Dart generator.
# Prefer the same command on all desktops:
#   dart run tool/generate_app_icons.dart

param(
  [switch]$SkipSvg
)

$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location $root

$argsList = @('run', 'tool/generate_app_icons.dart')
if ($SkipSvg) {
  $argsList += '--skip-svg'
}

& dart @argsList
if ($LASTEXITCODE -ne 0) {
  throw "generate_app_icons failed with exit code $LASTEXITCODE"
}
