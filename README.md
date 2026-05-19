# red_rect_app

Minimal Flutter Falcon Windows test app.

It only shows the installed version and checks Flutter Falcon for updates.
Falcon runtime config lives in `.flutter_falcon.json` at the app root and is
loaded through `package:flutter_falcon/flutter_falcon_api.dart`.
The committed config stays minimal. If your hosted `/updates` path requires
read auth, inject `FLUTTER_FALCON_READ_TOKEN` at build or run time instead of
committing it to git.

Run:

```powershell
.\run.ps1
```
