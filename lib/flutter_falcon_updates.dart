import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_falcon/flutter_falcon.dart';

const flutterFalconExamplePubspecName = 'flutter_falcon_example';
const flutterFalconServerUrl = 'https://flutterfalcon.com';
const flutterFalconChannel = 'stable';

abstract interface class FlutterFalconExampleUpdateClient {
  FlutterFalconV2Configuration get configuration;

  Stream<FlutterFalconUpdateEvent> get events;

  Future<FlutterFalconUpdateInfo> checkForUpdate();

  Future<void> startUpdate(FlutterFalconUpdateInfo info);

  Future<void> openStore(FlutterFalconUpdateInfo info);

  Future<void> openManualDownload(FlutterFalconUpdateInfo info);

  Future<void> cancelUpdate(FlutterFalconUpdateInfo info);

  Future<void> confirmPendingBoot();

  Future<void> dispose();
}

FlutterFalconExampleUpdateClient createFalconController({
  required bool captureRuntimeLogs,
}) {
  return HostedFlutterFalconExampleUpdateClient(
    captureRuntimeLogs: captureRuntimeLogs,
  );
}

class HostedFlutterFalconExampleUpdateClient
    implements FlutterFalconExampleUpdateClient {
  factory HostedFlutterFalconExampleUpdateClient({
    required bool captureRuntimeLogs,
  }) {
    final configuration = _exampleFalconConfiguration();
    return HostedFlutterFalconExampleUpdateClient._(
      captureRuntimeLogs: captureRuntimeLogs,
      configuration: configuration,
    );
  }

  HostedFlutterFalconExampleUpdateClient._({
    required this.captureRuntimeLogs,
    required this.configuration,
  }) : _controller = FlutterFalconUpdateController(
         configuration: configuration,
         releaseSource: FlutterFalconHttpReleaseSource(),
         platformAdapter: FlutterFalconMethodChannelUpdateAdapter(),
         eventReporter: FlutterFalconHttpEventReporter(
           serverUrl: flutterFalconServerUrl,
         ),
       );

  final bool captureRuntimeLogs;

  @override
  final FlutterFalconV2Configuration configuration;

  final FlutterFalconUpdateController _controller;
  FlutterFalconV2Diagnostics? _diagnostics;

  @override
  Stream<FlutterFalconUpdateEvent> get events => _controller.updateEvents;

  @override
  Future<FlutterFalconUpdateInfo> checkForUpdate() async {
    final info = await _controller.checkForUpdate();
    _diagnostics?.close();
    _diagnostics = FlutterFalconV2Diagnostics.install(
      diagnostics: FlutterFalconV2Diagnostics(
        configuration: configuration,
        installed: info.installed,
        logConsentGranted: captureRuntimeLogs,
      ),
    );
    return info;
  }

  @override
  Future<void> startUpdate(FlutterFalconUpdateInfo info) {
    return _controller.startUpdate(info);
  }

  @override
  Future<void> openStore(FlutterFalconUpdateInfo info) {
    return _controller.openStore(info);
  }

  @override
  Future<void> openManualDownload(FlutterFalconUpdateInfo info) {
    return _controller.openManualDownload(info);
  }

  @override
  Future<void> cancelUpdate(FlutterFalconUpdateInfo info) {
    return _controller.cancelUpdate(info);
  }

  @override
  Future<void> confirmPendingBoot() {
    return _controller.confirmPendingBoot();
  }

  @override
  Future<void> dispose() async {
    _diagnostics?.close();
    await _controller.dispose();
  }
}

FlutterFalconV2Configuration _exampleFalconConfiguration() {
  if (FlutterFalconV2Configuration.environmentProfile.isNotEmpty ||
      kReleaseMode) {
    return FlutterFalconV2Configuration.fromEnvironment(
      serverUrl: flutterFalconServerUrl,
      channel: flutterFalconChannel,
      storeListingId: const String.fromEnvironment('FLUTTER_FALCON_STORE_ID'),
    );
  }
  return debugFlutterFalconConfiguration(
    platform: defaultTargetPlatform,
    isWeb: kIsWeb,
  );
}

@visibleForTesting
FlutterFalconV2Configuration debugFlutterFalconConfiguration({
  required TargetPlatform platform,
  bool isWeb = false,
}) {
  final profile = switch ((isWeb, platform)) {
    (true, _) => FlutterFalconDistributionProfile.webPwa,
    (false, TargetPlatform.android) =>
      FlutterFalconDistributionProfile.androidDirect,
    (false, TargetPlatform.iOS) => FlutterFalconDistributionProfile.iosAppStore,
    (false, TargetPlatform.macOS) =>
      FlutterFalconDistributionProfile.macAppStore,
    (false, TargetPlatform.windows) =>
      FlutterFalconDistributionProfile.windowsDirect,
    (false, TargetPlatform.linux) =>
      FlutterFalconDistributionProfile.linuxFlatpak,
    (false, TargetPlatform.fuchsia) =>
      throw UnsupportedError('FlutterFalcon does not support Fuchsia.'),
  };
  final storeListingId = switch (profile) {
    FlutterFalconDistributionProfile.iosAppStore ||
    FlutterFalconDistributionProfile.macAppStore => '0000000000',
    FlutterFalconDistributionProfile.linuxFlatpak =>
      'com.example.flutter_falcon_example',
    _ => null,
  };
  return FlutterFalconV2Configuration(
    appId: flutterFalconExamplePubspecName,
    serverUrl: flutterFalconServerUrl,
    profile: profile,
    channel: flutterFalconChannel,
    storeListingId: storeListingId,
    directSigningPublicKey:
        profile == FlutterFalconDistributionProfile.androidDirect
            ? '0000000000000000000000000000000000000000000000000000000000000000'
            : null,
  );
}
