$ErrorActionPreference = 'Stop'

Set-Location $PSScriptRoot

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw "Flutter command was not found. Add Flutter to your PATH and retry."
}

$windowsBuildDirectory = Join-Path $PSScriptRoot 'build\windows'
$cmakeCache = Join-Path $windowsBuildDirectory 'x64\CMakeCache.txt'
if (Test-Path -LiteralPath $cmakeCache) {
  $expectedSourceDirectory = (Join-Path $PSScriptRoot 'windows').Replace('\', '/')
  $cacheSourceDirectory = (
    Get-Content -LiteralPath $cmakeCache |
      Where-Object { $_ -like 'CMAKE_HOME_DIRECTORY:INTERNAL=*' } |
      Select-Object -First 1
  ) -replace '^CMAKE_HOME_DIRECTORY:INTERNAL=', ''

  if ($cacheSourceDirectory -and
      -not ($cacheSourceDirectory.Replace('\', '/') -ieq $expectedSourceDirectory)) {
    Write-Host 'Removing stale Windows build cache after project relocation.'
    Remove-Item -LiteralPath $windowsBuildDirectory -Recurse -Force
  }
}

$args = @('run', '-d', 'windows')
if ($Env:FLUTTER_FALCON_READ_TOKEN) {
  $args += "--dart-define=FLUTTER_FALCON_READ_TOKEN=$Env:FLUTTER_FALCON_READ_TOKEN"
}

flutter @args
