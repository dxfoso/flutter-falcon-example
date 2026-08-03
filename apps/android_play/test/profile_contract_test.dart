import 'package:flutter_falcon/flutter_falcon.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Play target declares only the Android Play distribution route', () {
    final configuration = FlutterFalconV2BuildConfiguration.fromPubspec(
      pubspec: const {
        'name': 'flutter_falcon_example_play',
        'version': '2.0.0+54',
      },
      targetPlatform: FlutterFalconPlatform.android,
      resolvedPackages: const {'flutter_falcon', 'flutter_falcon_android_play'},
      packageIdentity: 'com.example.flutter_falcon_example_play',
    );

    expect(configuration.profile, FlutterFalconDistributionProfile.androidPlay);
    expect(configuration.storeListingId, isNotEmpty);
    expect(configuration.directPackageIdentity, isNull);
    expect(
      () => configuration.validate(
        targetPlatform: FlutterFalconPlatform.android,
        resolvedPackages: const {
          'flutter_falcon',
          'flutter_falcon_android_play',
        },
        pubspecVersion: '2.0.0+54',
      ),
      returnsNormally,
    );
  });
}
