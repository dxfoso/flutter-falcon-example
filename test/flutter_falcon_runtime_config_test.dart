import 'package:flutter_falcon/flutter_falcon_api.dart';
import 'package:flutter_falcon_example/flutter_falcon_updates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('version builder appends build number when needed', () {
    expect(flutterFalconPackageVersion('1.0.1', '3'), '1.0.1+3');
    expect(flutterFalconPackageVersion('1.0.1+2', '3'), '1.0.1+2');
    expect(flutterFalconPackageVersion('', '3'), '');
    expect(flutterFalconPackageVersion('1.0.1', ''), '1.0.1');
  });

  test('effective base version prefers the active patch version', () {
    expect(flutterFalconEffectiveBaseVersion('1.1.6+4', '1.1.6+5'), '1.1.6+5');
    expect(flutterFalconEffectiveBaseVersion('1.1.6+4', '  '), '1.1.6+4');
    expect(flutterFalconEffectiveBaseVersion('1.1.6+4', null), '1.1.6+4');
  });

  test('app controller uses the stable hosted stream without credentials', () {
    expect(falconController.serverUrl, 'https://flutterfalcon.com');
    expect(falconController.appId, 'flutter-falcon-example');
    expect(falconController.channel, 'stable');
  });

  test(
    'controller derives the installed build and keeps the explicit app id',
    () async {
      final controller = FlutterFalconController(
        serverUrl: 'https://flutterfalcon.com',
        appId: 'flutter-falcon-example',
        channel: 'stable',
        packageInfoLoader: () async {
          return const FlutterFalconPackageInfo(
            version: '2.4.1',
            buildNumber: '17',
            packageName: 'ignored.package.name',
          );
        },
        statusSnapshotLoader: ({required client, checkResult}) async => null,
        latestReleaseLoader:
            (client) async =>
                FlutterFalconLatestReleaseResult(config: client.config),
        checkLoader:
            (client) async => FlutterFalconUpdateCheckResult(
              status: FlutterFalconUpdateStatus.current,
              config: client.config,
              currentVersion: client.config.baseVersion,
            ),
      );

      final info = await controller.load();

      expect(info.installedVersion, '2.4.1+17');
      expect(info.currentRuntimeVersion, '2.4.1+17');
      expect(info.configuredAppId, 'flutter-falcon-example');
      expect(info.effectiveAppId, 'flutter-falcon-example');
      expect(info.serverUrl, 'https://flutterfalcon.com');
    },
  );
}
