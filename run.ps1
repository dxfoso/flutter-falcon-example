$ErrorActionPreference = 'Stop'

Set-Location $PSScriptRoot

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw "Flutter command was not found. Add Flutter to your PATH and retry."
}

$falconServerUrl = if ([string]::IsNullOrWhiteSpace($env:FLUTTER_FALCON_SERVER_URL)) { 'https://flutterfalcon.com' } else { $env:FLUTTER_FALCON_SERVER_URL }
$falconAppId = if ([string]::IsNullOrWhiteSpace($env:FLUTTER_FALCON_APP_ID)) { 'com.example.red_rect_app' } else { $env:FLUTTER_FALCON_APP_ID }
$falconPlatform = if ([string]::IsNullOrWhiteSpace($env:FLUTTER_FALCON_PLATFORM)) { 'windows-x64' } else { $env:FLUTTER_FALCON_PLATFORM }
$falconChannel = if ([string]::IsNullOrWhiteSpace($env:FLUTTER_FALCON_CHANNEL)) { 'stable' } else { $env:FLUTTER_FALCON_CHANNEL }
$falconReadToken = if ([string]::IsNullOrWhiteSpace($env:FLUTTER_FALCON_READ_TOKEN)) { '8df9b70751964cc6abb977adb8efd44c' } else { $env:FLUTTER_FALCON_READ_TOKEN }

$args = @(
  'run',
  '-d',
  'windows',
  "--dart-define=FLUTTER_FALCON_SERVER_URL=$falconServerUrl",
  "--dart-define=FLUTTER_FALCON_APP_ID=$falconAppId",
  "--dart-define=FLUTTER_FALCON_PLATFORM=$falconPlatform",
  "--dart-define=FLUTTER_FALCON_CHANNEL=$falconChannel",
  "--dart-define=FLUTTER_FALCON_READ_TOKEN=$falconReadToken"
)

if (-not [string]::IsNullOrWhiteSpace($env:FLUTTER_FALCON_ROLLOUT_KEY)) {
  $args += "--dart-define=FLUTTER_FALCON_ROLLOUT_KEY=$($env:FLUTTER_FALCON_ROLLOUT_KEY)"
}

flutter @args
