# flutter-falcon-example

Minimal Flutter Falcon Windows test app.

It shows:

- Installed version (from app package metadata)
- Effective hosted app id vs configured app id
- Exact `GET /updates` and `GET /releases/latest` URLs for the current build
- Whether an update is available from the hosted update stream

`Falcon` runtime config is now derived from package metadata at runtime:

- `appId`: package name from app metadata, kept stable across releases
- `baseVersion`: from app package `version` in `pubspec.yaml`
- `serverUrl`: defaults to `https://flutterfalcon.com` from the `flutter_falcon` package
- `channel`: fixed to `stable` in this example

Hosted FlutterFalcon builds may inject a separate runtime app id for tenant
isolation. Runtime lookup and hosted publish use that same effective app id
stream. This example now shows both values so operators can see which stream
the installed app is actually querying.

Hosted FlutterFalcon builds do not need a client read token for app update
checks. If you use a private Falcon server that still protects `/updates`,
pass a read token through `FLUTTER_FALCON_RUNTIME_READ_TOKEN` at build time.

Release flow this app expects:

1. Build and publish the new version from the same effective app id and channel (`stable`).
2. Ensure the hosted release stream exists for that effective app id and platform.
3. Download the packaged Windows build and install it.
4. Open the app and press refresh to compare local `baseVersion` vs the hosted stream.

If update is not shown after publishing:

- Confirm the release uses the same effective `appId` and platform as the installed app.
- Confirm channel is `stable`.
- Confirm the downloaded package reports the expected `packageName` and version.

Run:

```powershell
.\run.ps1
```
