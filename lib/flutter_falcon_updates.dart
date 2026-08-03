import 'dart:async';

import 'package:flutter_falcon/flutter_falcon.dart';

const flutterFalconExampleAppId = 'flutter-falcon-example';
const flutterFalconServerUrl = 'https://flutterfalcon.com';
const flutterFalconChannel = 'stable';

abstract interface class FlutterFalconExampleUpdateClient {
  FlutterFalconV2Configuration get configuration;

  Stream<FlutterFalconUpdateEvent> get events;

  Future<FlutterFalconUpdateInfo> checkForUpdate();

  Future<void> startUpdate(FlutterFalconUpdateInfo info);

  Future<void> openStore(FlutterFalconUpdateInfo info);

  Future<void> cancelUpdate(FlutterFalconUpdateInfo info);

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
    final configuration = FlutterFalconV2Configuration.fromEnvironment(
      appId: flutterFalconExampleAppId,
      serverUrl: flutterFalconServerUrl,
      channel: flutterFalconChannel,
      storeListingId: const String.fromEnvironment('FLUTTER_FALCON_STORE_ID'),
    );
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
  Future<void> cancelUpdate(FlutterFalconUpdateInfo info) {
    return _controller.cancelUpdate(info);
  }

  @override
  Future<void> dispose() async {
    _diagnostics?.close();
    await _controller.dispose();
  }
}
