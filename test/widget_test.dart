import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_falcon/flutter_falcon.dart';
import 'package:flutter_falcon_example/main.dart';
import 'package:flutter_falcon_example/runtime_configuration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('renders custom UI driven by the package workflow', (
    tester,
  ) async {
    final workflow = FlutterFalconUpdateWorkflow(
      controller: FlutterFalconUpdateController(
        configuration: const FlutterFalconV2Configuration(
          appId: 'flutter_falcon_example',
          serverUrl: 'https://flutterfalcon.test',
          profile: FlutterFalconDistributionProfile.windowsDirect,
        ),
        releaseSource: const _CurrentReleaseSource(),
        platformAdapter: _WindowsAdapter(),
        packageInfoLoader:
            () async => PackageInfo(
              appName: 'Example',
              packageName: 'com.example.flutter_falcon_example',
              version: '2.0.0',
              buildNumber: '76',
            ),
      ),
      enableDiagnostics: false,
    );

    await tester.pumpWidget(
      FlutterFalconExampleApp(
        runtimeConfiguration: const ExampleRuntimeConfiguration(
          apiBaseUrl: 'http://localhost:8080',
          isLocal: true,
        ),
        updateWorkflow: workflow,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FlutterFalconAboutPage), findsNothing);
    expect(find.byType(ExampleAboutPage), findsOneWidget);
    expect(find.text('Local server'), findsOneWidget);
    expect(find.text('You are up to date'), findsOneWidget);
    expect(find.text('Installed'), findsOneWidget);
    expect(find.text('Available'), findsOneWidget);
    expect(find.text('Update type'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Route'), findsOneWidget);
    expect(find.text('Channel'), findsOneWidget);
    expect(find.text('Update server'), findsOneWidget);
    expect(find.byKey(const Key('check-updates-button')), findsOneWidget);
    expect(find.byKey(const Key('automatic-updates-switch')), findsOneWidget);
    expect(find.byKey(const Key('diagnostic-logs-switch')), findsOneWidget);

    await tester.tap(find.byKey(const Key('check-updates-button')));
    await tester.pumpAndSettle();
    expect(find.text('You are up to date'), findsOneWidget);

    workflow.dispose();
  });
}

class _CurrentReleaseSource implements FlutterFalconReleaseSource {
  const _CurrentReleaseSource();

  @override
  Future<FlutterFalconUpdatePlan?> checkForUpdate({
    required FlutterFalconV2Configuration configuration,
    required FlutterFalconInstalledApp installed,
  }) async => null;
}

class _WindowsAdapter implements FlutterFalconPlatformUpdateAdapter {
  final _events = StreamController<FlutterFalconUpdateEvent>.broadcast();

  @override
  FlutterFalconPlatform get platform => FlutterFalconPlatform.windows;

  @override
  Stream<FlutterFalconUpdateEvent> get events => _events.stream;

  @override
  Future<FlutterFalconPlatformIdentity> identity(
    FlutterFalconV2Configuration configuration,
  ) async => const FlutterFalconPlatformIdentity(
    clientId: '0123456789abcdef0123456789abcdef',
    architecture: 'x64',
    osVersion: 'Windows 11',
  );

  @override
  Future<Set<FlutterFalconUpdateCapability>> capabilities(
    FlutterFalconV2Configuration configuration,
  ) async => const {FlutterFalconUpdateCapability.check};

  @override
  Future<void> startUpdate(
    FlutterFalconUpdatePlan plan,
    FlutterFalconInstalledApp installed,
  ) async {}

  @override
  Future<void> cancelUpdate(
    FlutterFalconUpdatePlan plan,
    FlutterFalconInstalledApp installed,
  ) async {}

  @override
  Future<void> openStore(
    FlutterFalconUpdatePlan plan,
    FlutterFalconInstalledApp installed,
  ) async {}

  @override
  Future<FlutterFalconBootResult> confirmPendingBoot(
    FlutterFalconV2Configuration configuration,
  ) async => const FlutterFalconBootResult(confirmed: false, pending: false);
}
