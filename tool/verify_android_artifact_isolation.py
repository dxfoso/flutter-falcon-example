#!/usr/bin/env python3
import hashlib
import json
import pathlib
import sys
import zipfile


def digest(path: pathlib.Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    if len(sys.argv) != 4:
        raise SystemExit("usage: verify_android_artifact_isolation.py APK AAB OUTPUT")
    apk = pathlib.Path(sys.argv[1])
    aab = pathlib.Path(sys.argv[2])
    output = pathlib.Path(sys.argv[3])

    with zipfile.ZipFile(apk) as archive:
        apk_dex = archive.read("classes.dex")
        apk_manifest = archive.read("AndroidManifest.xml").decode(
            "utf-16le", errors="ignore"
        )
    with zipfile.ZipFile(aab) as archive:
        aab_dex = archive.read("base/dex/classes.dex")
        aab_manifest = archive.read("base/manifest/AndroidManifest.xml").decode(
            "utf-16le", errors="ignore"
        )

    checks = {
        "apkHasDirectAdapter": b"flutter_falcon_android_direct" in apk_dex,
        "apkHasInstallerMime": b"application/vnd.android.package-archive" in apk_dex,
        "apkHasInstallPermission": "REQUEST_INSTALL_PACKAGES" in apk_manifest,
        "apkHasNoPlayAdapter": b"flutter_falcon_android_play" not in apk_dex,
        "apkHasNoPlaySdk": b"IAppUpdateService" not in apk_dex,
        "aabHasPlayAdapter": b"flutter_falcon_android_play" in aab_dex,
        "aabHasPlaySdk": b"IAppUpdateService" in aab_dex,
        "aabHasNoDirectAdapter": b"flutter_falcon_android_direct" not in aab_dex,
        "aabHasNoInstallerMime": (
            b"application/vnd.android.package-archive" not in aab_dex
        ),
        "aabHasNoInstallPermission": "REQUEST_INSTALL_PACKAGES" not in aab_manifest,
    }
    payload = {
        "schemaVersion": "flutter_falcon_example_artifact_isolation_v2",
        "status": "passed" if all(checks.values()) else "failed",
        "checks": checks,
        "artifacts": {
            "androidDirectApk": {"bytes": apk.stat().st_size, "sha256": digest(apk)},
            "androidPlayAab": {"bytes": aab.stat().st_size, "sha256": digest(aab)},
        },
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    return 0 if payload["status"] == "passed" else 1


if __name__ == "__main__":
    raise SystemExit(main())
