# flutter-falcon-example

Minimal Flutter Falcon Windows test app.

It shows:

- Installed version (from the local `.flutter_falcon.json`)
- Latest version from `GET /releases/latest`
- Whether an update is available (`installedVersion != latestVersion`)

`Falcon` runtime config lives in `.flutter_falcon.json` and is loaded through
`FlutterFalconUpdateClient.fromJsonString(...)`.
The committed config carries `serverUrl`, `appId`, and `baseVersion`.

Where to find `.flutter_falcon.json`:

- Source repo: `.flutter_falcon.json` at the project root (`D:\flutter-falcon-example`)
- Built Windows package: `...\<version>\windows-portable-<version>\data\flutter_assets\.flutter_falcon.json`

When you download a hosted build (for example `red_rect_app-windows-portable-<version>`),
this is where the app reads the update config.

Hosted FlutterFalcon builds do not need a client read token for app update
checks. If you use a private Falcon server that still protects `/updates`,
generate that file during CI/build with a `readToken` instead of committing the
secret to git.

Release flow this app expects:

1. Build and publish the new version from the same app id and channel (`stable`).
2. Ensure release metadata exists for `GET /releases/latest`.
3. Download the packaged Windows build and install it.
4. Open the app and press refresh to compare local `baseVersion` vs latest version.

If update is not shown after publishing:

- Confirm the release uses the same `appId` and platform as the installed app.
- Confirm channel is `stable`.
- Confirm the installed app `.flutter_falcon.json` is still for your app id and points to `https://flutterfalcon.com` (or your server).
- Confirm the downloaded package actually contains the new `baseVersion` and `.flutter_falcon.json` under `data\flutter_assets`.

Run:

```powershell
.\run.ps1
```
