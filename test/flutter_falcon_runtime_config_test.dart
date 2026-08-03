import 'package:flutter_falcon/flutter_falcon.dart';
import 'package:flutter_falcon_example/flutter_falcon_updates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shared v2 application identity uses the public hosted service', () {
    const configuration = FlutterFalconV2Configuration(
      appId: flutterFalconExamplePubspecName,
      serverUrl: flutterFalconServerUrl,
      profile: FlutterFalconDistributionProfile.androidDirect,
      channel: flutterFalconChannel,
    );

    expect(configuration.appId, 'flutter_falcon_example');
    expect(configuration.serverUrl, 'https://flutterfalcon.com');
    expect(configuration.channel, 'stable');
    expect(
      () => configuration.validateForPlatform(FlutterFalconPlatform.android),
      returnsNormally,
    );
  });

  test('v2 configuration never falls back to another platform route', () {
    const configuration = FlutterFalconV2Configuration(
      appId: flutterFalconExamplePubspecName,
      serverUrl: flutterFalconServerUrl,
      profile: FlutterFalconDistributionProfile.androidDirect,
    );

    expect(
      () => configuration.validateForPlatform(FlutterFalconPlatform.windows),
      throwsStateError,
    );
  });
}
