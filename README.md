# red_rect_app

Minimal Flutter Falcon Windows test app.

## What it does

- shows the installed app version in a red rectangle
- checks Flutter Falcon updates with one button
- uses the installed package version as `baseVersion`

## Falcon defaults

The test target keeps its Falcon defaults in `pubspec.yaml` under
`flutter_falcon.variables`:

- `FLUTTER_FALCON_SERVER_URL`
- `FLUTTER_FALCON_APP_ID`
- `FLUTTER_FALCON_PLATFORM`
- `FLUTTER_FALCON_CHANNEL`
- `FLUTTER_FALCON_READ_TOKEN`

## Local run

Run:

```powershell
.\run.ps1
```

## Update flow

1. Build and install a Windows base build.
2. Commit a change and build a newer Windows version.
3. Publish and promote the newer Falcon update for the same app id, platform, and channel.
4. Open the installed app and press `Check for update`.
