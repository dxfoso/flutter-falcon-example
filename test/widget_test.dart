import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_falcon/flutter_falcon.dart';
import 'package:flutter_falcon_example/check_for_updates_page.dart';
import 'package:flutter_falcon_example/flutter_falcon_updates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows checking and current states from the v2 controller', (
    tester,
  ) async {
    final result = Completer<FlutterFalconUpdateInfo>();
    final controller = _FakeUpdateClient([result.future]);

    await tester.pumpWidget(_testApp(controller));
    await tester.pump();
    expect(find.text('Checking for updates'), findsOneWidget);

    result.complete(_info());
    await tester.pumpAndSettle();

    expect(find.text('You are up to date'), findsOneWidget);
    expect(find.text('2.0.0+54'), findsNWidgets(2));
    expect(find.text('android-direct'), findsOneWidget);
    expect(find.text('No update'), findsOneWidget);
    expect(find.text('Check again'), findsWidgets);
  });

  testWidgets('starts only the capability declared by a direct release', (
    tester,
  ) async {
    final controller = _FakeUpdateClient([
      Future.value(_info(plan: _directPlan())),
    ]);

    await tester.pumpWidget(_testApp(controller));
    await tester.pumpAndSettle();

    expect(find.text('Update available'), findsOneWidget);
    expect(find.text('Install Android update'), findsOneWidget);
    expect(find.text('Download APK manually'), findsOneWidget);
    expect(find.byKey(const Key('store-update-button')), findsNothing);

    await tester.tap(find.byKey(const Key('falcon-update-button')));
    await tester.pump();

    expect(controller.startCalls, 1);
    expect(find.text('Downloading update'), findsOneWidget);
    expect(find.text('45%'), findsOneWidget);

    await tester.tap(find.byKey(const Key('manual-download-button')));
    await tester.pump();
    expect(controller.manualDownloadCalls, 1);
  });

  testWidgets('labels a Dart patch separately from a full Android update', (
    tester,
  ) async {
    final controller = _FakeUpdateClient([
      Future.value(_info(plan: _directPlan(dartPatch: true))),
    ]);

    await tester.pumpWidget(_testApp(controller));
    await tester.pumpAndSettle();

    expect(find.text('Apply FlutterFalcon patch'), findsOneWidget);
    expect(find.text('Install Android update'), findsNothing);
  });

  testWidgets('opens only the store for a store-managed release', (
    tester,
  ) async {
    final controller = _FakeUpdateClient([
      Future.value(
        _info(
          profile: FlutterFalconDistributionProfile.androidPlay,
          plan: _storePlan(),
        ),
      ),
    ], profile: FlutterFalconDistributionProfile.androidPlay);

    await tester.pumpWidget(_testApp(controller));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('falcon-update-button')), findsNothing);
    expect(find.byKey(const Key('manual-download-button')), findsNothing);
    expect(find.text('Open store'), findsOneWidget);
    await tester.tap(find.byKey(const Key('store-update-button')));
    await tester.pump();
    expect(controller.storeCalls, 1);
  });

  testWidgets('shows the complete failure reason and retries', (tester) async {
    final failed = Completer<FlutterFalconUpdateInfo>();
    final controller = _FakeUpdateClient([
      failed.future,
      Future.value(_info()),
    ]);

    await tester.pumpWidget(_testApp(controller));
    await tester.pump();
    failed.completeError(StateError('manifest profile does not match adapter'));
    await tester.pumpAndSettle();

    expect(find.text('Update request failed'), findsOneWidget);
    expect(
      find.textContaining('manifest profile does not match adapter'),
      findsWidgets,
    );

    await tester.tap(find.byKey(const Key('retry-update-check-button')));
    await tester.pumpAndSettle();
    expect(find.text('You are up to date'), findsOneWidget);
    expect(controller.checkCalls, 2);
  });

  testWidgets('keeps actions and diagnostics readable on a phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = _FakeUpdateClient([
      Future.value(_info(plan: _directPlan())),
    ]);

    await tester.pumpWidget(_testApp(controller));
    await tester.pumpAndSettle();

    final action = find.byKey(const Key('falcon-update-button'));
    await tester.ensureVisible(action);
    expect(tester.getBottomRight(action).dx, lessThanOrEqualTo(360));
    final diagnostics = find.text('Request diagnostics');
    await tester.ensureVisible(diagnostics);
    expect(tester.getBottomRight(diagnostics).dx, lessThanOrEqualTo(360));
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows v2 diagnostics and changes explicit log consent', (
    tester,
  ) async {
    final controller = _FakeUpdateClient([Future.value(_info())]);
    var consent = false;

    await tester.pumpWidget(
      MaterialApp(
        home: CheckForUpdatesPage(
          controller: controller,
          captureRuntimeLogs: consent,
          onCaptureRuntimeLogsChanged: (value) => consent = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Request diagnostics'));
    await tester.pumpAndSettle();
    expect(find.text('stable'), findsOneWidget);
    expect(find.text('client-example-0001'), findsOneWidget);

    final consentControl = find.byType(SwitchListTile);
    await tester.ensureVisible(consentControl);
    await tester.pumpAndSettle();
    await tester.tap(consentControl);
    expect(consent, isTrue);
  });
}

Widget _testApp(FlutterFalconExampleUpdateClient controller) {
  return MaterialApp(home: CheckForUpdatesPage(controller: controller));
}

class _FakeUpdateClient implements FlutterFalconExampleUpdateClient {
  _FakeUpdateClient(
    Iterable<Future<FlutterFalconUpdateInfo>> results, {
    this.profile = FlutterFalconDistributionProfile.androidDirect,
  }) : _results = Queue.of(results);

  final Queue<Future<FlutterFalconUpdateInfo>> _results;
  final FlutterFalconDistributionProfile profile;
  final StreamController<FlutterFalconUpdateEvent> _events =
      StreamController<FlutterFalconUpdateEvent>.broadcast();
  int checkCalls = 0;
  int startCalls = 0;
  int storeCalls = 0;
  int manualDownloadCalls = 0;
  int cancelCalls = 0;

  @override
  FlutterFalconV2Configuration get configuration =>
      FlutterFalconV2Configuration(
        appId: flutterFalconExamplePubspecName,
        serverUrl: flutterFalconServerUrl,
        profile: profile,
        channel: flutterFalconChannel,
        storeListingId: profile.storeManaged ? 'com.example.store' : null,
        directSigningPublicKey:
            profile == FlutterFalconDistributionProfile.androidDirect
                ? List.filled(32, 'ab').join()
                : null,
      );

  @override
  Stream<FlutterFalconUpdateEvent> get events => _events.stream;

  @override
  Future<FlutterFalconUpdateInfo> checkForUpdate() {
    checkCalls += 1;
    return _results.removeFirst();
  }

  @override
  Future<void> startUpdate(FlutterFalconUpdateInfo info) async {
    startCalls += 1;
    _events.add(
      FlutterFalconUpdateEvent(
        state: FlutterFalconUpdateState.downloading,
        installed: info.installed,
        occurredUtc: DateTime.utc(2026, 8, 3),
        plan: info.plan,
        progress: 0.45,
      ),
    );
  }

  @override
  Future<void> openStore(FlutterFalconUpdateInfo info) async {
    storeCalls += 1;
  }

  @override
  Future<void> openManualDownload(FlutterFalconUpdateInfo info) async {
    manualDownloadCalls += 1;
  }

  @override
  Future<void> cancelUpdate(FlutterFalconUpdateInfo info) async {
    cancelCalls += 1;
  }

  @override
  Future<void> confirmPendingBoot() async {}

  @override
  Future<void> dispose() async {
    await _events.close();
  }
}

FlutterFalconUpdateInfo _info({
  FlutterFalconDistributionProfile profile =
      FlutterFalconDistributionProfile.androidDirect,
  FlutterFalconUpdatePlan? plan,
}) {
  return FlutterFalconUpdateInfo(
    state:
        plan == null
            ? FlutterFalconUpdateState.current
            : FlutterFalconUpdateState.available,
    installed: _installed(profile),
    plan: plan,
  );
}

FlutterFalconInstalledApp _installed(FlutterFalconDistributionProfile profile) {
  return FlutterFalconInstalledApp(
    clientId: 'client-example-0001',
    appId: flutterFalconExamplePubspecName,
    packageName: 'com.example.flutter_falcon_example',
    version: '2.0.0',
    buildNumber: '54',
    platform: FlutterFalconPlatform.android,
    architecture: 'arm64-v8a',
    osVersion: 'Android 16',
    profile: profile,
  );
}

FlutterFalconUpdatePlan _directPlan({bool dartPatch = false}) {
  return FlutterFalconUpdatePlan(
    releaseId: 'android-direct-2.0.1-51',
    appId: flutterFalconExamplePubspecName,
    platform: FlutterFalconPlatform.android,
    architecture: 'arm64-v8a',
    profile: FlutterFalconDistributionProfile.androidDirect,
    route:
        dartPatch
            ? FlutterFalconDeliveryRoute.androidDartPatch
            : FlutterFalconDeliveryRoute.androidPackageInstaller,
    sourceVersion: '2.0.0+50',
    targetVersion: '2.0.1+51',
    capabilities: const {
      FlutterFalconUpdateCapability.check,
      FlutterFalconUpdateCapability.start,
      FlutterFalconUpdateCapability.progress,
    },
    artifactUrl: 'https://flutterfalcon.com/v2/artifacts/update.apk',
    artifactSha256:
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  );
}

FlutterFalconUpdatePlan _storePlan() {
  return FlutterFalconUpdatePlan(
    releaseId: 'android-play-2.0.1-51',
    appId: flutterFalconExamplePubspecName,
    platform: FlutterFalconPlatform.android,
    architecture: 'arm64-v8a',
    profile: FlutterFalconDistributionProfile.androidPlay,
    route: FlutterFalconDeliveryRoute.googlePlay,
    sourceVersion: '2.0.0+50',
    targetVersion: '2.0.1+51',
    capabilities: const {
      FlutterFalconUpdateCapability.check,
      FlutterFalconUpdateCapability.openStore,
    },
    storeListingId: 'com.example.flutter_falcon_example',
  );
}
