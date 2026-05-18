$ErrorActionPreference = 'Stop'

Set-Location $PSScriptRoot

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw "Flutter command was not found. Add Flutter to your PATH and retry."
}

flutter run -d windows
