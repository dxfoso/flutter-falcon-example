# flutter-falcon-example

Minimal Flutter Falcon Windows test app.

It only shows the installed version and checks Flutter Falcon for updates.
Falcon runtime config lives in `.flutter_falcon.json` at the app root and is
loaded through `package:flutter_falcon/flutter_falcon_api.dart`.
The committed config stays minimal. Hosted FlutterFalcon builds do not need a
client read token for app update checks. The supported app-facing runtime
contract is `.flutter_falcon.json`. If you use a private Falcon server that
still protects `/updates`, generate that file during CI/build with a
`readToken` instead of committing the secret to git.

Run:

```powershell
.\run.ps1
```
