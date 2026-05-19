$ErrorActionPreference = 'Stop'

Set-Location $PSScriptRoot

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw "Flutter command was not found. Add Flutter to your PATH and retry."
}

$args = @('run', '-d', 'windows')
if ($Env:FLUTTER_FALCON_READ_TOKEN) {
  $args += "--dart-define=FLUTTER_FALCON_READ_TOKEN=$Env:FLUTTER_FALCON_READ_TOKEN"
}

flutter @args
