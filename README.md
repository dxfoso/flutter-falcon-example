# flutter-falcon-example

Minimal Flutter Falcon Windows test app.

It shows:

- Installed version (from app package metadata)
- Latest hosted release version from `/releases/latest`
- Installable Falcon target version from `/updates`
- Runtime patch state for the current install
- Effective hosted app id vs configured app id
- Exact `GET /updates` and `GET /releases/latest` URLs for the current build
- Whether an update is available from the hosted update stream
- A button that downloads and activates the installable Falcon update when one exists

`Falcon` runtime config is now derived from package metadata at runtime:

- `appId`: package name from app metadata, kept stable across releases
  (`flutter_falcon_example` on desktop/web and `com.example.flutter_falcon_example`
  on Android)
- `baseVersion`: from app package `version` in `pubspec.yaml`
- `serverUrl`: defaults to `https://flutterfalcon.com` from the `flutter_falcon` package
- `channel`: fixed to `stable` in this example

When this repo is built on hosted `https://flutterfalcon.com`, the build
service now injects the hosted Falcon defaults automatically even without a
committed `.flutter_falcon.json` or saved Falcon env block. That is what lets
the hosted build auto-publish into the same effective stream that the app
queries at runtime.

Hosted FlutterFalcon builds may inject a separate runtime app id for tenant
isolation. Runtime lookup and hosted publish use that same effective app id
stream. This example now shows both values so operators can see which stream
the installed app is actually querying.

Hosted FlutterFalcon builds do not need a client read token for app update
checks. If you use a private Falcon server that still protects `/updates`,
pass a read token through `FLUTTER_FALCON_RUNTIME_READ_TOKEN` at build time.

Release flow this app expects:

1. Build and publish an older Windows version from the same effective app id and channel (`stable`).
2. Build and publish a newer Windows version from the same effective app id and channel.
3. Download and run the older packaged Windows build.
4. Open the app and press `Check for update` or refresh to compare local `baseVersion` vs the hosted stream.
5. If `/updates` reports an installable Falcon patch, click `Download and apply update`.
6. The example app restarts itself into the updated runtime and auto-confirms the boot on the relaunched app.

For the hosted sample stream, this repo now moves from `1.1.2+6` to `1.1.2+7`,
so the intended proof path is:

- download and run `1.1.2+6`
- publish and query `1.1.2+7`
- click `Download and apply update`
- let the example app restart itself

If update is not shown after publishing:

- Confirm the release uses the same effective `appId` and platform as the installed app.
- Confirm channel is `stable`.
- Confirm the downloaded package reports the expected `packageName` and version.
- Remember that `/releases/latest` and `/updates` are different:
  `/releases/latest` is the newest hosted packaged build, while `/updates`
  is an installable Falcon runtime update for the current base version.
- Remember that Windows installable Falcon patches only publish when the diff
  stays inside patchable Dart and asset files. Native shell, engine, DLL, or
  ICU changes still require a normal packaged release.

Run:

```powershell
.\run.ps1
```
