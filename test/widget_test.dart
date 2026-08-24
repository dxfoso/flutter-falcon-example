import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
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
          'updateType': 'dartCodePush',
          'currentPatchNumber': 0,
          'nextPatchNumber': 1,
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
        controller: controller,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Local server'), findsOneWidget);
    expect(find.text('82 FlutterFalcon patched'), findsOneWidget);
    expect(find.textContaining('FlutterFalcon · android APK'), findsOneWidget);
    expect(find.text('You are up to date'), findsOneWidget);
    expect(find.textContaining('Update: Dart code push'), findsOneWidget);
    expect(find.byKey(const Key('check-updates-button')), findsOneWidget);
    expect(find.byKey(const Key('automatic-updates-switch')), findsOneWidget);

    await tester.tap(find.byKey(const Key('check-updates-button')));
    await tester.pumpAndSettle();
    expect(find.text('You are up to date'), findsOneWidget);
    await controller.dispose();
  });
}
