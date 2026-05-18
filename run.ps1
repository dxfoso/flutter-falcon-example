$ErrorActionPreference = 'Stop'

Set-Location $PSScriptRoot

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw "Flutter command was not found. Add Flutter to your PATH and retry."
}

$apiBaseUrl = if ([string]::IsNullOrWhiteSpace($env:API_BASE_URL)) { 'http://localhost:9010' } else { $env:API_BASE_URL }
$serverBaseUrl = if ([string]::IsNullOrWhiteSpace($env:SERVER_BASE_URL)) { 'http://localhost:9010' } else { $env:SERVER_BASE_URL }
$falconServerUrl = if ([string]::IsNullOrWhiteSpace($env:FLUTTER_FALCON_SERVER_URL)) { 'https://flutterfalcon.com' } else { $env:FLUTTER_FALCON_SERVER_URL }
$falconAppId = if ([string]::IsNullOrWhiteSpace($env:FLUTTER_FALCON_APP_ID)) { 'com.example.red_rect_app' } else { $env:FLUTTER_FALCON_APP_ID }
$falconPlatform = if ([string]::IsNullOrWhiteSpace($env:FLUTTER_FALCON_PLATFORM)) { 'windows-x64' } else { $env:FLUTTER_FALCON_PLATFORM }
$falconChannel = if ([string]::IsNullOrWhiteSpace($env:FLUTTER_FALCON_CHANNEL)) { 'stable' } else { $env:FLUTTER_FALCON_CHANNEL }

$args = @(
  'run',
  '-d',
  'windows',
  "--dart-define=API_BASE_URL=$apiBaseUrl",
  "--dart-define=SERVER_BASE_URL=$serverBaseUrl",
  "--dart-define=FLUTTER_FALCON_SERVER_URL=$falconServerUrl",
  "--dart-define=FLUTTER_FALCON_APP_ID=$falconAppId",
  "--dart-define=FLUTTER_FALCON_PLATFORM=$falconPlatform",
  "--dart-define=FLUTTER_FALCON_CHANNEL=$falconChannel"
)

if (-not [string]::IsNullOrWhiteSpace($env:BUILD_COMMIT_DATE)) {
  $args += "--dart-define=BUILD_COMMIT_DATE=$($env:BUILD_COMMIT_DATE)"
}

if (-not [string]::IsNullOrWhiteSpace($env:BUILD_RELEASE_DATE)) {
  $args += "--dart-define=BUILD_RELEASE_DATE=$($env:BUILD_RELEASE_DATE)"
}

if (-not [string]::IsNullOrWhiteSpace($env:FLUTTER_FALCON_READ_TOKEN)) {
  $args += "--dart-define=FLUTTER_FALCON_READ_TOKEN=$($env:FLUTTER_FALCON_READ_TOKEN)"
}

if (-not [string]::IsNullOrWhiteSpace($env:FLUTTER_FALCON_ROLLOUT_KEY)) {
  $args += "--dart-define=FLUTTER_FALCON_ROLLOUT_KEY=$($env:FLUTTER_FALCON_ROLLOUT_KEY)"
}

flutter @args
