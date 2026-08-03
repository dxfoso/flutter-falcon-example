# flutter-falcon-example

FlutterFalcon v2 example applications connected to
`https://flutterfalcon.com` on the `stable` channel.

## Distribution targets

The root Flutter application is the cross-platform target. It contains one
adapter for each operating system and one profile-named build manifest for
each artifact:

- Android Direct APK
- iOS App Store
- macOS App Store
- Windows Direct App Installer
- Linux Flatpak
- Web PWA

Android Play is a separate application target at `apps/android_play`. Android
Play and Android Direct cannot share one pubspec because that would compile
store and package-installer code into the same Android dependency graph.

No target contains the old patch runtime, sidecar, v1 endpoints, route
fallbacks, publish credentials, or signing secrets.

## Runtime behavior

Each app uses `FlutterFalconUpdateController` with the v2 HTTP release source,
native method-channel adapter, and per-client event reporter. The UI enables an
action only when the exact-profile update plan declares its capability:

- Direct targets start the signed operating-system installer route.
- Store targets open only their official store route.
- Web asks only the active service worker to update.

The update page displays the installed and target versions, platform, profile,
route, architecture, progress, full redacted failure reason, and client
diagnostics. Optional application-log reporting is off by default and requires
explicit consent inside the app.

## Validate the root target

Run prebuild for the artifact being built:

```sh
flutter pub get
dart run flutter_falcon:flutter_falcon_v2_prebuild \
  --project . \
  --platform android \
  --build-manifest flutter_falcon_v2.android-direct.json
flutter build apk --release \
  --dart-define-from-file=.dart_tool/flutter_falcon_v2_defines.json
```

Replace the platform and manifest for iOS, macOS, Windows, Linux, or Web. The
prebuild fails before compilation if the selected profile, OS adapter, version,
route identity, architecture, minimum OS, or signing declaration drifts.

## Validate Android Play

```sh
cd apps/android_play
flutter pub get
dart run flutter_falcon:flutter_falcon_v2_prebuild \
  --project . \
  --platform android \
  --build-manifest flutter_falcon_v2.android-play.json
flutter build appbundle --release \
  --dart-define-from-file=.dart_tool/flutter_falcon_v2_defines.json
```

The Play AAB must not contain `REQUEST_INSTALL_PACKAGES`, FileProvider, APK
MIME handling, or the Android Direct adapter. The Direct APK must contain the
installer permission and adapter and must not contain Google Play update code.

## Verification boundary

Widget, contract, and artifact-isolation tests are not end-to-end update tests.
End-to-end completion requires installing the shipped base artifact on its real
target platform and completing its declared store or signed-installer route.
Store-track acceptance additionally requires the real store application,
publishing account, signing identity, and test device.
