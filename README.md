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
