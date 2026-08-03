import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_falcon/flutter_falcon.dart';

const _serverUrl = 'https://flutterfalcon.com';

void main() {
  runApp(const FlutterFalconPlayExample());
}

class FlutterFalconPlayExample extends StatelessWidget {
  const FlutterFalconPlayExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterFalcon Play Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3159C6)),
        useMaterial3: true,
      ),
      home: const _UpdatePage(),
    );
  }
}

class _UpdatePage extends StatefulWidget {
  const _UpdatePage();

  @override
  State<_UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends State<_UpdatePage> {
  late final FlutterFalconV2Configuration _configuration =
      FlutterFalconV2Configuration.fromEnvironment(
        appId: 'flutter-falcon-example',
        serverUrl: _serverUrl,
        storeListingId: const String.fromEnvironment('FLUTTER_FALCON_STORE_ID'),
      );
  late final FlutterFalconUpdateController _controller =
      FlutterFalconUpdateController(
        configuration: _configuration,
        releaseSource: FlutterFalconHttpReleaseSource(),
        platformAdapter: FlutterFalconMethodChannelUpdateAdapter(),
        eventReporter: FlutterFalconHttpEventReporter(serverUrl: _serverUrl),
      );
  FlutterFalconUpdateInfo? _info;
  FlutterFalconUpdateEvent? _event;
  StreamSubscription<FlutterFalconUpdateEvent>? _subscription;
  String? _failure;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _subscription = _controller.updateEvents.listen((event) {
      if (mounted) setState(() => _event = event);
    });
    unawaited(_check());
  }

  Future<void> _check() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      final result = await _controller.checkForUpdate();
      if (mounted) setState(() => _info = result);
    } catch (error) {
      if (mounted) setState(() => _failure = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openStore() async {
    final info = _info;
    if (_busy || info == null) return;
    setState(() => _busy = true);
    try {
      await _controller.openStore(info);
    } catch (error) {
      if (mounted) setState(() => _failure = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canOpenStore =
        _info?.plan?.capabilities.contains(
          FlutterFalconUpdateCapability.openStore,
        ) ==
        true;
    final state = _failure != null
        ? FlutterFalconUpdateState.failed
        : _event?.state ?? _info?.state ?? FlutterFalconUpdateState.checking;
    return Scaffold(
      appBar: AppBar(title: const Text('Google Play updates')),
      body: SelectionArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    state == FlutterFalconUpdateState.failed
                        ? Icons.error_outline
                        : Icons.play_circle_outline,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _title(state),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (_failure != null) ...[
                    const SizedBox(height: 12),
                    SelectableText(_failure!, textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    key: const Key('store-update-button'),
                    onPressed: _busy || !canOpenStore ? null : _openStore,
                    icon: const Icon(Icons.storefront_outlined),
                    label: const Text('Open Google Play'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: const Key('check-updates-button'),
                    onPressed: _busy ? null : _check,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Check again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _title(FlutterFalconUpdateState state) => switch (state) {
  FlutterFalconUpdateState.checking => 'Checking Google Play',
  FlutterFalconUpdateState.current => 'You are up to date',
  FlutterFalconUpdateState.available => 'Google Play update available',
  FlutterFalconUpdateState.waitingForUser => 'Waiting for approval',
  FlutterFalconUpdateState.downloading => 'Google Play is downloading',
  FlutterFalconUpdateState.installing => 'Google Play is installing',
  FlutterFalconUpdateState.restartRequired => 'Restart required',
  FlutterFalconUpdateState.completed => 'Update completed',
  FlutterFalconUpdateState.cancelled => 'Update cancelled',
  FlutterFalconUpdateState.failed => 'Update request failed',
  FlutterFalconUpdateState.unavailable => 'Update unavailable',
};
