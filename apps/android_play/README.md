# FlutterFalcon Android Play example

This target contains only `flutter_falcon_android_play`. It checks the exact
`android-play` release stream and delegates updates to Google Play. It does not
contain the Android Direct adapter, APK downloading, FileProvider, or
`REQUEST_INSTALL_PACKAGES`.

The store listing ID is public build configuration injected from
`flutter_falcon_v2.android-play.json`. Signing credentials are resolved only by
trusted build automation through the named secret reference.
