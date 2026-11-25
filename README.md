# FlutterFalcon example

This app installs only `flutter_falcon`. Its About page uses app-owned
Material widgets while `FlutterFalconCodePushController` owns update events.

Local Flutter stays independent:

```sh
flutter run
```

It shows **Local server**, uses `http://localhost:8080`, and runs as standard
Flutter. Override the app API when needed:

```sh
flutter run --dart-define=API_BASE_URL=https://api.example.com
```

In the FlutterFalcon repository page, save the non-secret build variable:

```text
API_BASE_URL=https://api.example.com
```

Then choose the artifact and build mode:

- **Standard** produces a normal Flutter artifact.
- **FlutterFalcon** produces the pinned custom-engine APK/AAB. The first build
  registers the store baseline; later compatible Dart-only commits publish a
  signed patch for that exact installed version.

The page shows Local/Live, Standard/FlutterFalcon, artifact and update type,
patch numbers, automatic updates, Check, Update, Retry, and Restart.

Build variables are compiled into the app and must never contain secrets.
Google Play/App Store publishing still requires the relevant store account and
signing credentials.

Release identity uses SDK4.3.1 or newer: keep canonical version+build in update/store APIs, display through formatFlutterFalconReleaseVersion, and show build mode separately. Hosted builds select the identity; prebuild and every compiler stage must receive that same value.

Automatic error reporting uses SDK4.3.4 and the generated application entrypoint, with framework/dispatcher capture installed before asynchronous startup settings load. Hosted FlutterFalcon builds select it automatically; both packaged CI builds pass `--target=.dart_tool/flutter_falcon_app.dart`. Existing installations need an updated build. Deliberately caught errors can use the shared `reportFlutterFalconError` API. Optional debug-log consent remains separate.
