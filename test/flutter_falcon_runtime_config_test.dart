import 'dart:convert';
import 'dart:io';

import 'package:flutter_falcon/flutter_falcon_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('committed config stays minimal', () {
    final file = File('.flutter_falcon.json');
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

    expect(json, <String, dynamic>{
      'serverUrl': 'https://flutterfalcon.com',
      'appId': 'com.example.red_rect_app',
    });
  });

  test('minimal config defaults stay app-friendly', () {
    const rawConfig = <String, dynamic>{
      'serverUrl': 'https://flutterfalcon.com',
      'appId': 'com.example.red_rect_app',
    };
    final config = FlutterFalconUpdateConfig.fromJson(
      rawConfig,
      baseVersion: '1.0.1+2',
    );

    expect(config.serverUrl, 'https://flutterfalcon.com');
    expect(config.appId, 'com.example.red_rect_app');
    expect(config.channel, 'stable');
    expect(config.automatic, isFalse);
    expect(config.baseVersion, '1.0.1+2');
  });

  test(
    'live update check works with committed runtime config',
    skip: !const bool.fromEnvironment('FLUTTER_FALCON_LIVE_SMOKE'),
    () async {
      final rawConfig =
          jsonDecode(File('.flutter_falcon.json').readAsStringSync())
              as Map<String, dynamic>;
      final config = FlutterFalconUpdateConfig.fromJson(
        rawConfig,
        baseVersion: '1.0.1+2',
      );

      final result = await FlutterFalconUpdateClient(config: config).check();

      expect(result.configured, isTrue);
      expect(result.status, isNot(FlutterFalconUpdateStatus.notConfigured));
      expect(result.status, isNot(FlutterFalconUpdateStatus.failed));
    },
  );
}
