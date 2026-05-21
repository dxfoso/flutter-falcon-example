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
      'baseVersion': '1.0.1+2',
    });
  });

  test('committed config loads directly into the runtime client', () {
    const rawConfig = <String, dynamic>{
      'serverUrl': 'https://flutterfalcon.com',
      'appId': 'com.example.red_rect_app',
      'baseVersion': '1.0.1+2',
    };
    final client = FlutterFalconUpdateClient.fromJson(rawConfig);
    final config = client.config;

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
      final client = FlutterFalconUpdateClient.fromJsonString(
        File('.flutter_falcon.json').readAsStringSync(),
      );
      final result = await client.check();

      expect(result.configured, isTrue);
      expect(result.status, isNot(FlutterFalconUpdateStatus.notConfigured));
      expect(result.status, isNot(FlutterFalconUpdateStatus.failed));
    },
  );
}
