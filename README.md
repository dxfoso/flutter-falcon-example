# flutter-falcon-example

A minimal Flutter app with a production-connected **Check for updates** page for
Flutter Falcon.

The app uses its own `pubspec.yaml` as the deployable target and includes
`flutter_falcon` only as a Git package dependency. Runtime configuration is
defined directly in Dart—there is no separate runtime-config asset, legacy
adapter, or fallback reader.

## Runtime stream

- Server: `https://flutterfalcon.com`
- Configured app ID: `flutter-falcon-example`
- Channel: `stable`
- Saved public build variable:
  `FLUTTER_FALCON_SERVER_URL=https://flutterfalcon.com`

`FlutterFalconController` derives the installed version and build number from
package metadata and detects the runtime platform. Hosted builds may override
the effective app ID for tenant isolation, so the Updates page displays both
the effective app ID and its source in the request diagnostics.

`FlutterFalconUpdateSession` owns check/action/reload orchestration, concurrency
locking, retry state, typed action outcomes, and semantic status presentation.
It also selects Falcon patching, Google Play in-app update, Google Play listing,
or App Store listing as the primary action. The app uses the package-provided
label and action and keeps only navigation and Material rendering.

The app never contains publish tokens, registry credentials, or other secrets.

## Update page

The `/updates` route opens on launch and is also reachable from the app's home
page. It:

- checks automatically on page load and supports manual checks and retry;
- shows installed, active runtime, and latest hosted versions;
- shows check status, explanation, effective app ID, runtime state, and full
  failure details;
- distinguishes current, available, applying, boot confirmation, success, and
  failure states;
- disables repeated actions while a request is running;
- calls the package's real primary action for Falcon, boot-confirmation, or
  platform-store updates, reports the returned message, and reloads status.

## Run and verify

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d windows
```

Passing widget or API tests are not an end-to-end update result. An end-to-end
claim requires launching the shipped artifact on its real target platform,
opening the update page, and exercising the real runtime action.

## Operator create-update flow

1. Build and install the first Falcon-ready base app.
2. Make the next app change and build the newer version.
3. Publish and promote the hosted Falcon update for the same effective app ID,
   runtime platform, and `stable` channel.
4. Open the already installed base app and trigger its update check.

Publish and promote from a trusted operator environment (never from the app):

```text
flutter_falcon publish-index --server-url https://flutterfalcon.com --publish-token <publish> --index flutter_falcon_update_index.json
flutter_falcon promote-update --server-url https://flutterfalcon.com --publish-token <publish> --app-id flutter-falcon-example --platform <platform-id> --channel stable --target-version <new-version>
```

Operator check URL:

```text
https://flutterfalcon.com/updates?appId=flutter-falcon-example&platform=<platform-id>&channel=stable&baseVersion=<installed-base-version>
```

The effective hosted app ID must stay stable for the app stream. Platform,
channel, and installed base version must match the published update. Native
runner, plugin, permission, dependency, signing, or installer changes require a
new full package build rather than a Falcon patch.
