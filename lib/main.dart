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
    this.updateWorkflow,
  });

  final ExampleRuntimeConfiguration runtimeConfiguration;
  final FlutterFalconUpdateWorkflow? updateWorkflow;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Flutter Falcon Example',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3159C6)),
      useMaterial3: true,
      visualDensity: VisualDensity.compact,
    ),
    home: ExampleAboutPage(
      runtimeConfiguration: runtimeConfiguration,
      updateWorkflow: updateWorkflow,
    ),
  );
}

class ExampleAboutPage extends StatefulWidget {
  const ExampleAboutPage({
    super.key,
    required this.runtimeConfiguration,
    this.updateWorkflow,
  });

  final ExampleRuntimeConfiguration runtimeConfiguration;
  final FlutterFalconUpdateWorkflow? updateWorkflow;

  @override
  State<ExampleAboutPage> createState() => _ExampleAboutPageState();
}

class _ExampleAboutPageState extends State<ExampleAboutPage> {
  late final FlutterFalconUpdateWorkflow _updates;
  late final bool _ownsWorkflow;

  @override
  void initState() {
    super.initState();
    _ownsWorkflow = widget.updateWorkflow == null;
    _updates =
        widget.updateWorkflow ??
        FlutterFalconUpdateWorkflow.standard(
          serverUrl: 'https://flutterfalcon.com',
          debugAppId: 'flutter_falcon_example',
          debugStoreListingId: '0000000000',
        );
    unawaited(_updates.initialize());
  }

  @override
  void dispose() {
    if (_ownsWorkflow) _updates.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _updates,
    builder: (context, _) {
      final info = _updates.info;
      return Scaffold(
        appBar: AppBar(
          title: const Text('79 Falcon example'),
          actions: [
            IconButton(
              key: const Key('check-icon'),
              onPressed: _updates.canCheck ? _updates.checkForUpdate : null,
              tooltip: 'Check for updates',
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: SelectionArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ServerCard(configuration: widget.runtimeConfiguration),
              const SizedBox(height: 12),
              _UpdateCard(workflow: _updates),
              if (info != null) ...[
                const SizedBox(height: 12),
                _VersionCard(workflow: _updates),
              ],
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                key: const Key('automatic-updates-switch'),
                contentPadding: EdgeInsets.zero,
                value: _updates.automaticUpdates,
                onChanged: _updates.busy ? null : _updates.setAutomaticUpdates,
                title: const Text('Automatic direct updates'),
              ),
              SwitchListTile.adaptive(
                key: const Key('diagnostic-logs-switch'),
                contentPadding: EdgeInsets.zero,
                value: _updates.captureRuntimeLogs,
                onChanged: _updates.setCaptureRuntimeLogs,
                title: const Text('Send diagnostic logs'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ServerCard extends StatelessWidget {
  const _ServerCard({required this.configuration});
  final ExampleRuntimeConfiguration configuration;

  @override
  Widget build(BuildContext context) {
    final artifact = FlutterFalconV2BuildArtifactInfo.fromEnvironment();
    final buildLabel =
        artifact == null
            ? 'Local Flutter build'
            : '${artifact.platform.name} · ${artifact.artifactType.toUpperCase()}';
    return Card.filled(
      child: ListTile(
        leading: Icon(configuration.isLocal ? Icons.computer : Icons.public),
        title: Text(configuration.isLocal ? 'Local server' : 'Live server'),
        subtitle: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(configuration.apiBaseUrl),
            Text(buildLabel),
          ],
        ),
      ),
    );
  }
}

class _UpdateCard extends StatelessWidget {
  const _UpdateCard({required this.workflow});
  final FlutterFalconUpdateWorkflow workflow;

  @override
  Widget build(BuildContext context) {
    final progress = workflow.progress?.clamp(0.0, 1.0).toDouble();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _stateTitle(workflow.state),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (workflow.reason?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 4),
              SelectableText(workflow.reason!),
            ],
            if (workflow.busy) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: progress),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (workflow.canStart)
                  FilledButton(
                    key: const Key('start-update-button'),
                    onPressed: workflow.startUpdate,
                    child: Text(workflow.updateActionLabel),
                  ),
                if (workflow.canOpenStore)
                  FilledButton(
                    key: const Key('open-store-button'),
                    onPressed: workflow.openStore,
                    child: const Text('Open store'),
                  ),
                if (workflow.canOpenManualDownload)
                  OutlinedButton(
                    key: const Key('manual-download-button'),
                    onPressed: workflow.openManualDownload,
                    child: const Text('Download manually'),
                  ),
                if (workflow.canCancel)
                  OutlinedButton(
                    key: const Key('cancel-update-button'),
                    onPressed: workflow.cancelUpdate,
                    child: const Text('Cancel'),
                  ),
                OutlinedButton(
                  key: const Key('check-updates-button'),
                  onPressed: workflow.canCheck ? workflow.checkForUpdate : null,
                  child: Text(
                    workflow.state == FlutterFalconUpdateState.failed
                        ? 'Retry'
                        : 'Check for updates',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VersionCard extends StatelessWidget {
  const _VersionCard({required this.workflow});
  final FlutterFalconUpdateWorkflow workflow;

  @override
  Widget build(BuildContext context) {
    final info = workflow.info!;
    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            _Fact('Installed', info.installed.displayVersion),
            _Fact('Available', info.plan?.targetVersion ?? 'Current'),
            _Fact('Update type', info.updateType?.name ?? 'None'),
            _Fact('Profile', info.installed.profile.wireName),
            _Fact('Route', info.plan?.route.name ?? 'No update'),
            _Fact('Channel', workflow.configuration.channel),
            _Fact('Update server', workflow.configuration.serverUrl),
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelMedium),
      SelectableText(
        value,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ],
  );
}

String _stateTitle(FlutterFalconUpdateState state) => switch (state) {
  FlutterFalconUpdateState.checking => 'Checking for updates',
  FlutterFalconUpdateState.current => 'You are up to date',
  FlutterFalconUpdateState.available => 'Update available',
  FlutterFalconUpdateState.waitingForUser => 'Waiting for approval',
  FlutterFalconUpdateState.downloading => 'Downloading update',
  FlutterFalconUpdateState.installing => 'Installing update',
  FlutterFalconUpdateState.restartRequired => 'Restart required',
  FlutterFalconUpdateState.completed => 'Update completed',
  FlutterFalconUpdateState.cancelled => 'Update cancelled',
  FlutterFalconUpdateState.failed => 'Update failed',
  FlutterFalconUpdateState.unavailable => 'Ready to check',
};
