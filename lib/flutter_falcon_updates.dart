import 'package:flutter_falcon/flutter_falcon_api.dart';

const falconController = FlutterFalconController(
  serverUrl: 'https://flutterfalcon.com',
  appId: 'flutter-falcon-example',
  channel: 'stable',
  appleAppStoreId: String.fromEnvironment('FLUTTER_FALCON_APP_STORE_ID'),
);
