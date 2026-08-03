import 'dart:convert';
import 'dart:io';

import 'package:flutter_falcon/flutter_falcon.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Play target declares only the Android Play distribution route', () {
    final manifest =
        jsonDecode(
              File('flutter_falcon_v2.android-play.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    final configuration = FlutterFalconV2BuildConfiguration.fromJson(manifest);

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
        pubspecVersion: '2.0.0+49',
      ),
      returnsNormally,
    );
  });
}
