# flutter-falcon-example

Minimal Flutter Falcon Windows test app.

It shows:

- Installed version (from app package metadata)
- Latest version from `GET /releases/latest`
- Whether an update is available (`installedVersion != latestVersion`)

`Falcon` runtime config is now derived from package metadata at runtime:

- `appId`: `<user>-<version>`, where `user` is derived from package name and `version` is `version` from `pubspec.yaml`
- `baseVersion`: from app package `version` in `pubspec.yaml`
- `serverUrl`: defaults to `https://flutterfalcon.com`
- `channel`: fixed to `stable` in this example

Hosted FlutterFalcon builds do not need a client read token for app update
checks. If you use a private Falcon server that still protects `/updates`,
pass a read token through `FLUTTER_FALCON_RUNTIME_READ_TOKEN` at build time.

Release flow this app expects:

1. Build and publish the new version from the same app id and channel (`stable`).
2. Ensure release metadata exists for `GET /releases/latest`.
3. Download the packaged Windows build and install it.
4. Open the app and press refresh to compare local `baseVersion` vs latest version.

If update is not shown after publishing:

- Confirm the release uses the same `appId` and platform as the installed app.
- Confirm channel is `stable`.
- Confirm the downloaded package reports the expected `packageName` and version.

Run:

```powershell
.\run.ps1
```
