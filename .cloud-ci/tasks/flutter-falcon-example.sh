#!/usr/bin/env bash
set -uo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
artifact_dir="${CLOUD_CI_ARTIFACT_DIR:-$repo_root/build/cloud-ci-artifacts/flutter-falcon-example}"
mkdir -p "$artifact_dir"
started_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
status=passed

run_build() {
  docker run --rm --cpus=4 --memory=12g \
    -v "$repo_root:/work" -w /work "$1" bash -lc "$2"
}

if ! run_build ghcr.io/cirruslabs/flutter:3.41.6 '
  set -euo pipefail
  flutter pub get
  flutter analyze
  flutter test
  dart run flutter_falcon:flutter_falcon_prebuild \
    --platform android --artifact-type apk --build-mode standard \
    --dart-define API_BASE_URL=https://api.example.com
  flutter build apk --release \
    --dart-define-from-file=.dart_tool/flutter_falcon_defines.json
'; then status=failed; fi

if [[ "$status" == passed ]] && ! run_build registry.cloud.divclouds.com/flutterfalcon/android-builder:2c5e6477714a '
  set -euo pipefail
  flutter pub get
  dart run flutter_falcon:flutter_falcon_prebuild \
    --platform android --artifact-type aab --build-mode code-push \
    --engine-revision 2c5e6477714ac64bbeb6f332228a8f2d74fc7cad0539f176b251c667c1a1cdc9 \
    --dart-define API_BASE_URL=https://api.example.com
  flutter build appbundle --release --target-platform android-arm64 \
    --local-engine-src-path=/opt/flutter_falcon_engine \
    --local-engine=android_release_arm64 --local-engine-host=host_release \
    --dart-define-from-file=.dart_tool/flutter_falcon_defines.json
'; then status=failed; fi

finished_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
python3 - "$artifact_dir" "$status" "$started_at" "$finished_at" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
status = sys.argv[2]
step = {
    "id": "package-and-build",
    "name": "Test package and build standard APK plus FlutterFalcon AAB",
    "status": status,
    "required": True,
    "exitCode": 0 if status == "passed" else 1,
    "startedAt": sys.argv[3],
    "finishedAt": sys.argv[4],
    "triggerCoverage": ["push", "pull_request", "workflow_dispatch", "schedule"],
}
trigger = {"events": step["triggerCoverage"]}
outputs = [
    "build/app/outputs/flutter-apk/app-release.apk",
    "build/app/outputs/bundle/release/app-release.aab",
]
payload = {
    "schemaVersion": "flutter_falcon_example_results_v1",
    "taskId": "flutter-falcon-example",
    "status": status,
    "trigger": trigger,
    "latestPublicUrl": __import__("os").environ.get("CLOUD_CI_ARTIFACT_URL", ""),
    "favoriteTextOutputs": ["repository-update-summary.txt"],
    "outputs": outputs,
}
(root / "task-status.json").write_text(json.dumps(payload, indent=2) + "\n")
(root / "task-results.json").write_text(json.dumps(payload, indent=2) + "\n")
(root / "task-step-results.json").write_text(json.dumps({"steps": [step]}, indent=2) + "\n")
(root / "repository-update-summary.txt").write_text(f"FlutterFalcon example: {status}\n")
raise SystemExit(0 if status == "passed" else 1)
PY
