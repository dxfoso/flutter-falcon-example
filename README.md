# red_rect_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Flutter Falcon update setup

This project includes a Falcon update checker on the diagnostics screen:

- `package:flutter_falcon/cloud_flutter_falcon_update.dart`
- `CloudFlutterFalconUpdateButton()`

### Required build variables

Set these under the `flutter_falcon` block in `pubspec.yaml`:

- `FLUTTER_FALCON_SERVER_URL=https://flutterfalcon.com`
- `FLUTTER_FALCON_APP_ID=<your-app-id>`
- `FLUTTER_FALCON_PLATFORM=windows-x64`
- `FLUTTER_FALCON_CHANNEL=stable`
- `API_BASE_URL=http://localhost:9010` (for local/dev)
- `SERVER_BASE_URL=http://localhost:9010` (for local/dev)

Optional auth variables:

- `FLUTTER_FALCON_READ_TOKEN` (if read auth is enabled)
- `FLUTTER_FALCON_ROLLOUT_KEY` (for stable device/user rollout key)

### Local run

Use `run.ps1` to launch Windows builds with all required `--dart-define` values.

### Release workflow (outline)

1. Build and install the first Falcon-ready base (Windows portable).
2. Commit your next change and build a newer commit artifact.
3. Publish and promote a Falcon update target for:
   - `platform=windows-x64`
   - `channel=stable`
   - matching `appId` and `baseVersion`.
