#!/usr/bin/env bash
set -uo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
artifact_dir="${ACTION_SERVER_ARTIFACT_DIR:-$repo_root/.action-server/artifacts/flutter-falcon-example-v2}"
mkdir -p "$artifact_dir"

task_id="${ACTION_SERVER_TASK_ID:-flutter-falcon-example-v2}"
started_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
steps_jsonl="$artifact_dir/.steps.jsonl"
: >"$steps_jsonl"

record_step() {
  local id="$1" name="$2" status="$3" code="$4" started="$5" finished="$6" note="${7:-}"
  python3 - "$steps_jsonl" "$id" "$name" "$status" "$code" "$started" "$finished" "$note" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
payload = {
    "id": sys.argv[2],
    "name": sys.argv[3],
    "status": sys.argv[4],
    "required": True,
    "exitCode": int(sys.argv[5]),
    "startedAt": sys.argv[6],
    "finishedAt": sys.argv[7],
    "triggerCoverage": ["push", "pull_request", "workflow_dispatch", "schedule"],
}
if sys.argv[8]:
    payload["note"] = sys.argv[8]
with path.open("a", encoding="utf-8") as handle:
    handle.write(json.dumps(payload, sort_keys=True) + "\n")
PY
}

run_step() {
  local id="$1" name="$2"
  shift 2
  local started finished code status
  started="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  "$@"
  code=$?
  finished="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  status=passed
  if [[ "$code" -ne 0 ]]; then status=failed; fi
  record_step "$id" "$name" "$status" "$code" "$started" "$finished"
  return "$code"
}

run_docker_validation() {
  local -a docker_args=(--rm -v "$repo_root:/work")
  if [[ -n "${FF_LOCAL_PACKAGE_REPOSITORY:-}" ]]; then
    if [[ ! -d "$FF_LOCAL_PACKAGE_REPOSITORY/.git" ]]; then
      echo "FF_LOCAL_PACKAGE_REPOSITORY must name a FlutterFalcon Git checkout" >&2
      return 2
    fi
    docker_args+=(
      -v "$FF_LOCAL_PACKAGE_REPOSITORY:/flutterfalcon-source:ro"
      -e FF_LOCAL_PACKAGE_REPOSITORY=/flutterfalcon-source
    )
  fi
  docker run "${docker_args[@]}" \
    -w /work \
    ghcr.io/cirruslabs/flutter:stable \
    bash -lc '
      set -euo pipefail
      if [[ -n "${FF_LOCAL_PACKAGE_REPOSITORY:-}" ]]; then
        git config --global --add safe.directory "$FF_LOCAL_PACKAGE_REPOSITORY"
        git config --global --add safe.directory "$FF_LOCAL_PACKAGE_REPOSITORY/.git"
        git config --global \
          url."file://$FF_LOCAL_PACKAGE_REPOSITORY/".insteadOf \
          https://github.com/dxfoso/flutterfalcon.git
      fi
      flutter clean
      (cd apps/android_play && flutter clean)
      flutter pub get
      flutter pub get --directory apps/android_play
      flutter analyze
      flutter test
      for item in \
        "android apk" \
        "ios ipa" \
        "macos app" \
        "windows portable" \
        "linux flatpak" \
        "web web"; do
        set -- $item
        dart run flutter_falcon:flutter_falcon_v2_prebuild \
          --project . --platform "$1" \
          --artifact-type "$2"
      done
      dart run flutter_falcon:flutter_falcon_v2_prebuild \
        --project . --platform android \
        --artifact-type apk
      flutter build apk --release \
        --dart-define-from-file=.dart_tool/flutter_falcon_v2_defines.json
      cd apps/android_play
      flutter pub get
      flutter analyze
      flutter test
      dart run flutter_falcon:flutter_falcon_v2_prebuild \
        --project . --platform android \
        --artifact-type aab
      flutter build appbundle --release \
        --dart-define-from-file=.dart_tool/flutter_falcon_v2_defines.json
    ' >"$artifact_dir/docker-build.log" 2>&1
}

inspect_artifacts() {
  python3 "$repo_root/tool/verify_android_artifact_isolation.py" \
    "$repo_root/build/app/outputs/flutter-apk/app-release.apk" \
    "$repo_root/apps/android_play/build/app/outputs/bundle/release/app-release.aab" \
    "$artifact_dir/artifact-isolation.json"
}

if run_step docker-build "Dockerized v2 prebuild, tests, APK, and AAB" run_docker_validation; then
  run_step artifact-isolation "Inspect Android Direct and Play binaries" inspect_artifacts
else
  dependency_time="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  record_step artifact-isolation "Inspect Android Direct and Play binaries" \
    failed 125 "$dependency_time" "$dependency_time" \
    "Not run because the Docker build dependency failed"
fi

finished_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
python3 - "$steps_jsonl" "$artifact_dir" "$task_id" "$started_at" "$finished_at" <<'PY'
import json
import pathlib
import sys

steps_path = pathlib.Path(sys.argv[1])
artifact_dir = pathlib.Path(sys.argv[2])
steps = [json.loads(line) for line in steps_path.read_text().splitlines() if line.strip()]
failed = [step["id"] for step in steps if step["required"] and step["status"] != "passed"]
status = "failed" if failed else "passed"
trigger = {
    "events": ["push", "pull_request", "workflow_dispatch", "schedule"],
    "runtime": {
        "event": __import__("os").environ.get("ACTION_SERVER_EVENT_NAME", "workflow_dispatch"),
        "ref": __import__("os").environ.get("ACTION_SERVER_REF", "local"),
        "runId": __import__("os").environ.get("ACTION_SERVER_RUN_ID", "local"),
    },
}
status_payload = {
    "schemaVersion": "action_task_status_v1",
    "taskId": sys.argv[3],
    "status": status,
    "trigger": trigger,
    "startedAt": sys.argv[4],
    "finishedAt": sys.argv[5],
    "requiredSteps": len(steps),
    "failedRequiredSteps": failed,
}
results = {
    "schemaVersion": "flutter_falcon_example_v2_results_v1",
    "taskId": sys.argv[3],
    "status": status,
    "trigger": trigger,
    "latestPublicUrl": __import__("os").environ.get("ACTION_SERVER_ARTIFACT_URL", ""),
    "favoriteTextOutputs": ["repository-update-summary.txt"],
    "outputs": ["artifact-isolation.json", "docker-build.log"],
}
(artifact_dir / "task-status.json").write_text(json.dumps(status_payload, indent=2) + "\n")
(artifact_dir / "task-results.json").write_text(json.dumps(results, indent=2) + "\n")
(artifact_dir / "task-step-results.json").write_text(json.dumps({"steps": steps}, indent=2) + "\n")
(artifact_dir / "repository-update-summary.txt").write_text(
    f"FlutterFalcon example v2 validation: {status}\n"
    f"Required steps: {len(steps)}\n"
    f"Failed: {', '.join(failed) if failed else 'none'}\n"
)
raise SystemExit(1 if failed else 0)
PY
