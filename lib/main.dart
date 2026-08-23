import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_falcon/flutter_falcon.dart';

import 'runtime_configuration.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    FlutterFalconExampleApp(
      runtimeConfiguration: ExampleRuntimeConfiguration.fromEnvironment(),
    ),
  );
}

class FlutterFalconExampleApp extends StatelessWidget {
  const FlutterFalconExampleApp({
    super.key,
    required this.runtimeConfiguration,
    this.controller,
  });

  final ExampleRuntimeConfiguration runtimeConfiguration;
  final FlutterFalconCodePushController? controller;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'FlutterFalcon Example',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3159C6),
          ),
          useMaterial3: true,
          visualDensity: VisualDensity.compact,
        ),
        home: ExampleAboutPage(
          runtimeConfiguration: runtimeConfiguration,
          controller: controller,
        ),
      );
}

class ExampleAboutPage extends StatefulWidget {
  const ExampleAboutPage({
    super.key,
    required this.runtimeConfiguration,
    this.controller,
  });

  final ExampleRuntimeConfiguration runtimeConfiguration;
  final FlutterFalconCodePushController? controller;

  @override
  State<ExampleAboutPage> createState() => _ExampleAboutPageState();
}

class _ExampleAboutPageState extends State<ExampleAboutPage> {
  late final FlutterFalconCodePushController _updates;
  late final bool _ownsController;
  StreamSubscription<FlutterFalconRuntimeInfo>? _subscription;
  FlutterFalconRuntimeInfo? _info;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _updates = widget.controller ?? FlutterFalconCodePushController();
    _subscription = _updates.events.listen((info) {
      if (mounted) setState(() => _info = info);
    });
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    final info = await _updates.initialize();
    if (mounted) setState(() => _info = info);
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    if (_ownsController) unawaited(_updates.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;
    final state = info?.state ?? FlutterFalconRuntimeState.idle;
    final busy = state == FlutterFalconRuntimeState.checking ||
        state == FlutterFalconRuntimeState.downloading;
    final build = _updates.build;
    return Scaffold(
      appBar: AppBar(title: const Text('82 FlutterFalcon example')),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card.filled(
              child: ListTile(
                leading: Icon(
                  widget.runtimeConfiguration.isLocal
                      ? Icons.computer
                      : Icons.public,
                ),
                title: Text(widget.runtimeConfiguration.serverLabel),
                subtitle: Text(
                  '${widget.runtimeConfiguration.apiBaseUrl}\n'
                  '${build.codePushEnabled ? 'FlutterFalcon' : 'Standard Flutter'}'
                  '${build.platform.isEmpty ? '' : ' · ${build.platform} ${build.artifactType.toUpperCase()}'}',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _stateLabel(state),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (info?.message case final message?) ...[
                      const SizedBox(height: 4),
                      Text(message),
                    ],
                    if (busy) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          key: const Key('check-updates-button'),
                          onPressed: busy ? null : _updates.checkForUpdate,
                          icon: const Icon(Icons.refresh),
                          label: Text(
                            state == FlutterFalconRuntimeState.failed
                                ? 'Retry'
                                : 'Check for updates',
                          ),
                        ),
                        if (info?.updateAvailable == true)
                          FilledButton.icon(
                            key: const Key('update-button'),
                            onPressed: busy ? null : _updates.update,
                            icon: const Icon(Icons.download),
                            label: const Text('Update'),
                          ),
                        if (info?.restartRequired == true)
                          FilledButton.icon(
                            key: const Key('restart-button'),
                            onPressed: info!.restartSupported
                                ? _updates.restart
                                : null,
                            icon: const Icon(Icons.restart_alt),
                            label: Text(
                              info.restartSupported
                                  ? 'Restart'
                                  : 'Close and reopen',
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SwitchListTile.adaptive(
              key: const Key('automatic-updates-switch'),
              contentPadding: EdgeInsets.zero,
              value: info?.automaticUpdates ?? true,
              onChanged: busy ? null : _updates.setAutomaticUpdates,
              title: const Text('Automatic updates'),
            ),
            if (info != null)
              Text(
                'Engine: ${info.engineAvailable ? 'ready' : 'standard'} · '
                'Patch: ${info.currentPatchNumber} · '
                'Next: ${info.nextPatchNumber}',
              ),
          ],
        ),
      ),
    );
  }
}

String _stateLabel(FlutterFalconRuntimeState state) => switch (state) {
      FlutterFalconRuntimeState.idle => 'Ready to check',
      FlutterFalconRuntimeState.checking => 'Checking for updates',
      FlutterFalconRuntimeState.current => 'You are up to date',
      FlutterFalconRuntimeState.updateAvailable => 'Update available',
      FlutterFalconRuntimeState.downloading => 'Downloading update',
      FlutterFalconRuntimeState.restartRequired => 'Restart required',
      FlutterFalconRuntimeState.failed => 'Update failed',
    };
