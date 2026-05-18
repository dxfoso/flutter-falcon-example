$ErrorActionPreference = 'Stop'

Set-Location $PSScriptRoot

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw "Flutter command was not found. Add Flutter to your PATH and retry."
}

$apiBaseUrl = if ([string]::IsNullOrWhiteSpace($env:API_BASE_URL)) { 'http://localhost:9010' } else { $env:API_BASE_URL }
$serverBaseUrl = if ([string]::IsNullOrWhiteSpace($env:SERVER_BASE_URL)) { 'http://localhost:9010' } else { $env:SERVER_BASE_URL }

$args = @(
  'run',
  '-d',
  'windows',
  "--dart-define=API_BASE_URL=$apiBaseUrl",
  "--dart-define=SERVER_BASE_URL=$serverBaseUrl"
)

if (-not [string]::IsNullOrWhiteSpace($env:BUILD_COMMIT_DATE)) {
  $args += "--dart-define=BUILD_COMMIT_DATE=$($env:BUILD_COMMIT_DATE)"
}

if (-not [string]::IsNullOrWhiteSpace($env:BUILD_RELEASE_DATE)) {
  $args += "--dart-define=BUILD_RELEASE_DATE=$($env:BUILD_RELEASE_DATE)"
}

flutter @args
