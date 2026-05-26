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

- Source repo: `D:\flutter-falcon-example\.flutter_falcon.json` (or just `.flutter_falcon.json` at repo root)
- Built Windows package: `...\<version>\windows-portable-<version>\data\flutter_assets\.flutter_falcon.json`

When you download a hosted build (for example `red_rect_app-windows-portable-<version>`),
this is where the app reads the update config.

Hosted FlutterFalcon builds do not need a client read token for app update
checks. If you use a private Falcon server that still protects `/updates`,
generate that file during CI/build with a `readToken` instead of committing the
secret to git.

Run:

```powershell
.\run.ps1
```
