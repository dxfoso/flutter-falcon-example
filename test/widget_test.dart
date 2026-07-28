import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_falcon/flutter_falcon_api.dart';
import 'package:flutter_falcon_example/check_for_updates_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows idle, loading, and current states with controller data', (
    tester,
  ) async {
    final load = Completer<FlutterFalconVersionInfo>();
    final controller = _FakeFalconController(loadResults: [load.future]);

    await tester.pumpWidget(_testApp(controller));
    expect(find.text('Ready to check'), findsOneWidget);

    await tester.pump();
    expect(find.text('Checking for updates'), findsOneWidget);

    load.complete(_versionInfo());
    await tester.pumpAndSettle();

    expect(find.text('You are up to date'), findsOneWidget);
    expect(find.text('1.1.6+11'), findsNWidgets(3));
    expect(find.text('current'), findsOneWidget);
    expect(find.text('flutter-falcon-example'), findsOneWidget);
    expect(find.text('Update app'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('falcon-primary-action-button')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('runs an available update once and reloads after real success', (
    tester,
  ) async {
    final action = Completer<FlutterFalconActionResult>();
    final controller = _FakeFalconController(
      loadResults: [
        Future.value(_versionInfo(updateAvailable: true)),
        Future.value(
          _versionInfo(runtimeState: FlutterFalconAppUpdateState.active),
        ),
      ],
      actionResult: action.future,
    );

    await tester.pumpWidget(_testApp(controller));
    await tester.pumpAndSettle();
    expect(find.text('Update available'), findsOneWidget);
    expect(find.text('Update to 1.1.7+12'), findsOneWidget);

    final primaryAction = find.byKey(const Key('falcon-primary-action-button'));
    await tester.ensureVisible(primaryAction);
    await tester.tap(primaryAction);
    await tester.pump();

    expect(find.text('Applying update'), findsOneWidget);
    expect(controller.actionCalls, 1);
    final button = tester.widget<FilledButton>(primaryAction);
    expect(button.onPressed, isNull);

    action.complete(
      const FlutterFalconActionResult(
        outcome: FlutterFalconActionOutcome.succeeded,
        message: 'Runtime update activated.',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Runtime action succeeded'), findsOneWidget);
    expect(find.text('Runtime update activated.'), findsOneWidget);
    expect(controller.loadCalls, 2);
  });

  testWidgets('shows boot confirmation action and uses the primary action', (
    tester,
  ) async {
    final controller = _FakeFalconController(
      loadResults: [
        Future.value(_versionInfo(requiresBootConfirmation: true)),
        Future.value(
          _versionInfo(runtimeState: FlutterFalconAppUpdateState.active),
        ),
      ],
      actionResult: Future.value(
        const FlutterFalconActionResult(
          outcome: FlutterFalconActionOutcome.succeeded,
          message: 'Boot confirmed.',
        ),
      ),
    );

    await tester.pumpWidget(_testApp(controller));
    await tester.pumpAndSettle();

    expect(find.text('Boot confirmation required'), findsOneWidget);
    final primaryAction = find.byKey(const Key('falcon-primary-action-button'));
    await tester.ensureVisible(primaryAction);
    expect(find.text('Confirm updated boot'), findsOneWidget);
    await tester.tap(primaryAction);
    await tester.pumpAndSettle();

    expect(find.text('Boot confirmed.'), findsOneWidget);
    expect(controller.actionCalls, 1);
  });

  testWidgets('starts a full app update through the package store action', (
    tester,
  ) async {
    final controller = _FakeFalconController(
      loadResults: [
        Future.value(
          _versionInfo(
            newerReleaseAvailable: true,
            storeUpdate: const FlutterFalconStoreUpdateInfo(
              store: FlutterFalconStoreKind.googlePlay,
              availability: FlutterFalconStoreUpdateAvailability.available,
              immediateAllowed: true,
              flexibleAllowed: true,
            ),
          ),
        ),
        Future.value(
          _versionInfo(
            newerReleaseAvailable: true,
            storeUpdate: const FlutterFalconStoreUpdateInfo(
              store: FlutterFalconStoreKind.googlePlay,
              availability: FlutterFalconStoreUpdateAvailability.inProgress,
            ),
          ),
        ),
      ],
      actionResult: Future.value(
        const FlutterFalconActionResult(
          outcome: FlutterFalconActionOutcome.succeeded,
          message: 'Google Play update flow started.',
        ),
      ),
    );

    await tester.pumpWidget(_testApp(controller));
    await tester.pumpAndSettle();

    expect(find.text('Google Play update available'), findsOneWidget);
    final primaryAction = find.byKey(const Key('falcon-primary-action-button'));
    await tester.ensureVisible(primaryAction);
    expect(find.text('Update to 1.1.7+12'), findsOneWidget);
    await tester.tap(primaryAction);
    await tester.pumpAndSettle();

    expect(find.text('Store update started'), findsOneWidget);
    expect(find.text('Google Play update flow started.'), findsNWidgets(2));
    expect(controller.actionCalls, 1);
  });

  testWidgets('preserves failure details and retries the update check', (
    tester,
  ) async {
    final failedLoad = Completer<FlutterFalconVersionInfo>();
    final controller = _FakeFalconController(
      loadResults: [failedLoad.future, Future.value(_versionInfo())],
    );

    await tester.pumpWidget(_testApp(controller));
    await tester.pump();
    failedLoad.completeError(Exception('connection refused'));
    await tester.pumpAndSettle();

    expect(find.text('Update request failed'), findsOneWidget);
    expect(find.textContaining('connection refused'), findsWidgets);

    final retry = find.byKey(const Key('retry-update-check-button'));
    await tester.tap(retry);
    await tester.pumpAndSettle();

    expect(find.text('You are up to date'), findsOneWidget);
    expect(controller.loadCalls, 2);
  });

  testWidgets('remains readable on a narrow phone viewport', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = _FakeFalconController(
      loadResults: [Future.value(_versionInfo(updateAvailable: true))],
    );

    await tester.pumpWidget(_testApp(controller));
    await tester.pumpAndSettle();

    expect(find.text('Update available'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Update available')).dy, lessThan(160));
    final installedY = tester.getTopLeft(find.text('Installed')).dy;
    expect(tester.getTopLeft(find.text('Running')).dy, installedY);
    expect(tester.getTopLeft(find.text('Latest')).dy, installedY);
    expect(
      tester.getBottomRight(find.text('Request diagnostics')).dy,
      lessThanOrEqualTo(800),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('diagnostics display the controller effective channel', (
    tester,
  ) async {
    final controller = _FakeFalconController(
      loadResults: [Future.value(_versionInfo(channel: 'beta'))],
    );

    await tester.pumpWidget(_testApp(controller));
    await tester.pumpAndSettle();
    final diagnostics = find.text('Request diagnostics');
    await tester.ensureVisible(diagnostics);
    await tester.tap(diagnostics);
    await tester.pumpAndSettle();

    expect(find.text('Channel'), findsOneWidget);
    expect(find.text('beta'), findsOneWidget);
  });
}

Widget _testApp(FlutterFalconControllerApi controller) {
  return MaterialApp(home: CheckForUpdatesPage(controller: controller));
}

class _FakeFalconController implements FlutterFalconControllerApi {
  _FakeFalconController({
    required Iterable<Future<FlutterFalconVersionInfo>> loadResults,
    Future<FlutterFalconActionResult>? actionResult,
  }) : _loadResults = Queue.of(loadResults),
       _actionResult =
           actionResult ??
           Future.value(
             const FlutterFalconActionResult(
               outcome: FlutterFalconActionOutcome.noChange,
               message: 'No update available.',
             ),
           );

  final Queue<Future<FlutterFalconVersionInfo>> _loadResults;
  final Future<FlutterFalconActionResult> _actionResult;
  int loadCalls = 0;
  int actionCalls = 0;

  @override
  Future<FlutterFalconVersionInfo> load() {
    loadCalls += 1;
    return _loadResults.removeFirst();
  }

  @override
  Future<FlutterFalconActionResult> runPrimaryAction(
    FlutterFalconVersionInfo info,
  ) {
    actionCalls += 1;
    return _actionResult;
  }
}

FlutterFalconVersionInfo _versionInfo({
  bool updateAvailable = false,
  bool newerReleaseAvailable = false,
  bool requiresBootConfirmation = false,
  String channel = 'stable',
  FlutterFalconAppUpdateState runtimeState =
      FlutterFalconAppUpdateState.noPatch,
  FlutterFalconStoreUpdateInfo storeUpdate =
      const FlutterFalconStoreUpdateInfo.unsupported(),
}) {
  final latestAvailable = updateAvailable || newerReleaseAvailable;
  return FlutterFalconVersionInfo(
    installedVersion: '1.1.6+11',
    currentRuntimeVersion: '1.1.6+11',
    latestVersion: latestAvailable ? '1.1.7+12' : '1.1.6+11',
    installableTargetVersion: updateAvailable ? '1.1.7+12' : '1.1.6+11',
    configuredAppId: 'flutter-falcon-example',
    effectiveAppId: 'flutter-falcon-example',
    appIdSource: FlutterFalconAppIdSource.configured,
    serverUrl: 'https://flutterfalcon.com',
    channel: channel,
    updateAvailable: latestAvailable,
    installableUpdateAvailable: updateAvailable,
    checkStatus: updateAvailable
        ? FlutterFalconUpdateStatus.available
        : FlutterFalconUpdateStatus.current,
    statusExplanation: updateAvailable
        ? 'An installable update is available.'
        : 'No installable patch was found.',
    baseVersion: '1.1.6+11',
    configured: true,
    updatesRequestUrl:
        'https://flutterfalcon.com/updates?appId=flutter-falcon-example',
    releaseLatestRequestUrl:
        'https://flutterfalcon.com/releases/latest?appId=flutter-falcon-example',
    latestReleaseFound: true,
    runtimeState: requiresBootConfirmation
        ? FlutterFalconAppUpdateState.pendingBoot
        : runtimeState,
    requiresBootConfirmation: requiresBootConfirmation,
    activePatchVersion:
        requiresBootConfirmation ||
            runtimeState == FlutterFalconAppUpdateState.active
        ? '1.1.7+12'
        : null,
    storeUpdate: storeUpdate,
  );
}
