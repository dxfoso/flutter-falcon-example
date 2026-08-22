param(
  [string]$ApiBaseUrl,
  [string]$FlutterExecutable
)

$ErrorActionPreference = 'Stop'

Set-Location $PSScriptRoot

if (-not $ApiBaseUrl) {
  $ApiBaseUrl = if ($Env:API_BASE_URL) {
    $Env:API_BASE_URL
  } else {
    'http://localhost:8080'
  }
}

if (-not $FlutterExecutable) {
  $flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
  if ($flutterCommand) {
    $FlutterExecutable = $flutterCommand.Source
  } elseif ($Env:FLUTTER_ROOT) {
    $flutterCandidates = if (
      [System.Environment]::OSVersion.Platform -eq 'Win32NT'
    ) {
      @(
        (Join-Path $Env:FLUTTER_ROOT 'bin\flutter.bat'),
        (Join-Path $Env:FLUTTER_ROOT 'bin/flutter')
      )
    } else {
      @(
        (Join-Path $Env:FLUTTER_ROOT 'bin/flutter'),
        (Join-Path $Env:FLUTTER_ROOT 'bin\flutter.bat')
      )
    }
    $FlutterExecutable = $flutterCandidates |
      Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
      Select-Object -First 1
  }
}

if (-not $FlutterExecutable -or
    -not (Test-Path -LiteralPath $FlutterExecutable -PathType Leaf)) {
  throw 'Flutter was not found. Add its bin directory to PATH, set FLUTTER_ROOT, or pass -FlutterExecutable.'
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

& $FlutterExecutable pub get
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

& $FlutterExecutable pub run flutter_falcon:flutter_falcon_v2_prebuild `
  --project . `
  --platform windows `
  --artifact-type portable
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

$flutterArgs = @(
  'run',
  '-d',
  'windows',
  '--dart-define-from-file=.dart_tool/flutter_falcon_v2_defines.json',
  "--dart-define=API_BASE_URL=$ApiBaseUrl"
)

& $FlutterExecutable @flutterArgs
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}
