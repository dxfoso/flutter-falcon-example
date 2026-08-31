import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_falcon/flutter_falcon.dart';
import 'package:flutter_falcon_example/main.dart';
import 'package:flutter_falcon_example/runtime_configuration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_falcon_example_test');

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getRuntimeInfo') {
        return {
          'engineAvailable': true,
          'restartSupported': true,
          'currentPatchNumber': 0,
          'nextPatchNumber': 0,
        };
      }
      if (call.method == 'checkForUpdate') {
        return {'available': false};
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('uses app UI with package-owned update events', (tester) async {
    final controller = FlutterFalconCodePushController(
      channel: channel,
      buildInfo: const FlutterFalconBuildInfo(
        mode: FlutterFalconBuildMode.codePush,
        platform: 'android',
        artifactType: 'apk',
        engineRevision: 'engine',
      ),
    );
    await tester.pumpWidget(
      FlutterFalconExampleApp(
        runtimeConfiguration: const ExampleRuntimeConfiguration(
          apiBaseUrl: 'http://localhost:8080',
          isLocal: true,
        ),
        appVersion: '2.0.4+105',
        controller: controller,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Local server'), findsOneWidget);
    expect(
      find.text('FlutterFalcon Example · Automatic Android update'),
      findsOneWidget,
    );
    expect(find.textContaining('FlutterFalcon · android APK'), findsOneWidget);
    expect(find.textContaining('Version 2.0.4+105'), findsOneWidget);
    expect(find.text('App is up to date'), findsOneWidget);
    expect(
      find.text('Update direction: No update available'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Direction: No update available'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('check-updates-button')), findsOneWidget);
    expect(find.byKey(const Key('automatic-updates-switch')), findsOneWidget);

    await tester.tap(find.byKey(const Key('check-updates-button')));
    await tester.pumpAndSettle();
    expect(find.text('App is up to date'), findsOneWidget);
    await controller.dispose();
  });

  testWidgets('shows no inferred update route for a standard build',
      (tester) async {
    final controller = FlutterFalconCodePushController(
      channel: channel,
      buildInfo: const FlutterFalconBuildInfo(
        mode: FlutterFalconBuildMode.standard,
        platform: 'android',
        artifactType: 'apk',
        engineRevision: '',
      ),
    );
    await tester.pumpWidget(
      FlutterFalconExampleApp(
        runtimeConfiguration: const ExampleRuntimeConfiguration(
          apiBaseUrl: 'http://localhost:8080',
          isLocal: true,
        ),
        appVersion: '2.0.4+105',
        controller: controller,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Update direction: No update available',
      ),
      findsOneWidget,
    );
    await controller.dispose();
  });

  testWidgets('uses the package restart action for an iOS-style runtime',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getRuntimeInfo') {
        return {
          'engineAvailable': true,
          'restartSupported': false,
          'currentPatchNumber': 0,
          'nextPatchNumber': 1,
        };
      }
      return null;
    });
    final controller = FlutterFalconCodePushController(
      channel: channel,
      buildInfo: const FlutterFalconBuildInfo(
        mode: FlutterFalconBuildMode.codePush,
        platform: 'ios',
        artifactType: 'ipa',
        engineRevision: 'engine',
      ),
    );
    await tester.pumpWidget(
      FlutterFalconExampleApp(
        runtimeConfiguration: const ExampleRuntimeConfiguration(
          apiBaseUrl: 'https://api.example.com',
          isLocal: false,
        ),
        appVersion: '2.0.4+105',
        controller: controller,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Close and reopen'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('restart-button')),
    );
    expect(button.onPressed, isNull);
    await controller.dispose();
  });

  testWidgets('shows the Google Play route and target returned by the package',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'flutter_falcon.automatic_updates': false,
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      return switch (call.method) {
        'getRuntimeInfo' => {
            'engineAvailable': true,
            'currentPatchNumber': 0,
            'nextPatchNumber': 0,
          },
        'checkFullReplacement' => {
            'available': true,
            'version': '97',
          },
        _ => null,
      };
    });
    final controller = FlutterFalconCodePushController(
      channel: channel,
      buildInfo: const FlutterFalconBuildInfo(
        mode: FlutterFalconBuildMode.codePush,
        platform: 'android',
        artifactType: 'aab',
        engineRevision: 'engine',
      ),
    );
    await tester.pumpWidget(
      FlutterFalconExampleApp(
        runtimeConfiguration: const ExampleRuntimeConfiguration(
          apiBaseUrl: 'https://api.example.com',
          isLocal: false,
        ),
        appVersion: '2.0.4+105',
        controller: controller,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('check-updates-button')));
    await tester.pumpAndSettle();

    expect(
      find.text('Update direction: Google Play app update'),
      findsOneWidget,
    );
    expect(find.text('Target version: 97'), findsOneWidget);
    expect(find.byKey(const Key('update-button')), findsOneWidget);
    await controller.dispose();
  });
}
