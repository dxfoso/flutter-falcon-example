# flutter-falcon-example

FlutterFalcon v2 example applications connected to
`https://flutterfalcon.com` on the `stable` channel.

## Distribution targets

The root Flutter application is the cross-platform target. Its pubspec contains
one adapter for each operating system; FlutterFalcon derives each profile and
generates disposable build metadata under `.dart_tool`:

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

The app reads its API server from a public compile-time build variable:

```dart
const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
```

`flutter run` defaults to `http://localhost:8080`. A release build fails when
`API_BASE_URL` is missing. In FlutterFalcon, open the selected `pubspec.yaml`,
choose **Build variables**, and save:

```text
API_BASE_URL=https://flutterfalcon.com
```

FlutterFalcon forwards it as `--dart-define=API_BASE_URL=...`. The update page
shows **Local server** or **Live server** with the effective app API URL. The
FlutterFalcon update service remains `https://flutterfalcon.com`. For an Android
emulator, use `http://10.0.2.2:8080` to reach a server on the host computer.
Build variables are embedded in the app, so they must never contain secrets.

On Windows, run the local configuration with:

```powershell
.\run.ps1
```

It passes `API_BASE_URL=http://localhost:8080`. Override the URL with
`$env:API_BASE_URL` or `-ApiBaseUrl`. Flutter must be on `PATH`, discoverable
through `FLUTTER_ROOT`, or supplied with `-FlutterExecutable`. Use
`flutter doctor -v` if the Windows desktop toolchain is unavailable. Debug runs
do not require FlutterFalcon prebuild metadata; release builds remain strict.

The app renders its own `ExampleAboutPage` cards, buttons, switches, labels, and
colors. Its `FlutterFalconUpdateWorkflow` comes from the package and owns the
controller, HTTP clients, preferences, diagnostics, lifecycle handling, and
capability-driven update actions:

- Direct targets start the signed operating-system installer route.
- Store targets open only their official store route.
- Web asks only the active service worker to update.

The custom About/update page displays the installed and target versions, update
type, profile, route, progress, full failure reason, and capability-driven
actions. Automatic updates are persisted, default off, and start only direct
plans that declare `start`; stores and manual downloads remain explicit. After
Android installer permission is granted, the pending update retries once when
the app resumes. Optional application-log reporting also requires consent.

## Validate the root target

Run prebuild for the artifact being built:

```sh
flutter pub get
dart run flutter_falcon:flutter_falcon_v2_prebuild \
  --project . \
  --platform android \
  --artifact-type apk
flutter build apk --release \
  --dart-define-from-file=.dart_tool/flutter_falcon_v2_defines.json
```

Replace the platform and artifact type for iOS, macOS, Windows, Linux, or Web. The
prebuild fails before compilation if the selected profile, OS adapter, version,
route identity, architecture, minimum OS, or signing declaration drifts.

## Validate Android Play

```sh
cd apps/android_play
flutter pub get
dart run flutter_falcon:flutter_falcon_v2_prebuild \
  --project . \
  --platform android \
  --artifact-type aab
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
