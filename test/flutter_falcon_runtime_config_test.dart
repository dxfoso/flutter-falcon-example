import 'package:flutter_falcon/flutter_falcon.dart';
import 'package:flutter_falcon_example/flutter_falcon_updates.dart';
import 'package:flutter_falcon_example/runtime_configuration.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shared v2 application identity accepts the configured service', () {
    const configuration = FlutterFalconV2Configuration(
      appId: flutterFalconExamplePubspecName,
      serverUrl: 'https://flutterfalcon.com',
      profile: FlutterFalconDistributionProfile.androidDirect,
      channel: flutterFalconChannel,
      directSigningPublicKey:
          'abababababababababababababababababababababababababababababababab',
    );

    expect(configuration.appId, 'flutter_falcon_example');
    expect(configuration.serverUrl, 'https://flutterfalcon.com');
    expect(configuration.channel, 'stable');
    expect(
      () => configuration.validateForPlatform(FlutterFalconPlatform.android),
      returnsNormally,
    );
  });

  test('debug runs default to the local API server', () {
    final configuration = ExampleRuntimeConfiguration.fromEnvironment(
      apiBaseUrl: '',
      releaseMode: false,
    );

    expect(configuration.apiBaseUrl, localApiBaseUrl);
    expect(configuration.serverLabel, 'Local server');
  });

  test('normal Windows debug run does not need generated defines', () {
    final configuration = debugFlutterFalconConfiguration(
      platform: TargetPlatform.windows,
    );

    expect(configuration.appId, flutterFalconExamplePubspecName);
    expect(
      configuration.profile,
      FlutterFalconDistributionProfile.windowsDirect,
    );
    expect(
      () => configuration.validateForPlatform(FlutterFalconPlatform.windows),
      returnsNormally,
    );
  });

  test('FlutterFalcon build variables select the live API server', () {
    final configuration = ExampleRuntimeConfiguration.fromEnvironment(
      apiBaseUrl: 'https://flutterfalcon.com',
      releaseMode: true,
    );

    expect(configuration.apiBaseUrl, 'https://flutterfalcon.com');
    expect(configuration.serverLabel, 'Live server');
  });

  test('release builds fail when API_BASE_URL is missing', () {
    expect(
      () => ExampleRuntimeConfiguration.fromEnvironment(
        apiBaseUrl: '',
        releaseMode: true,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('v2 configuration never falls back to another platform route', () {
    const configuration = FlutterFalconV2Configuration(
      appId: flutterFalconExamplePubspecName,
      serverUrl: 'https://flutterfalcon.com',
      profile: FlutterFalconDistributionProfile.androidDirect,
      directSigningPublicKey:
          'abababababababababababababababababababababababababababababababab',
    );

    expect(
      () => configuration.validateForPlatform(FlutterFalconPlatform.windows),
      throwsStateError,
    );
  });
}
