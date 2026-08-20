import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_falcon/flutter_falcon.dart';

import 'flutter_falcon_updates.dart';

class CheckForUpdatesPage extends StatefulWidget {
  const CheckForUpdatesPage({
    super.key,
    required this.controller,
    this.captureRuntimeLogs = false,
    this.onCaptureRuntimeLogsChanged,
  });

  static const routeName = '/updates';

  final FlutterFalconExampleUpdateClient controller;
  final bool captureRuntimeLogs;
  final ValueChanged<bool>? onCaptureRuntimeLogsChanged;

  @override
  State<CheckForUpdatesPage> createState() => _CheckForUpdatesPageState();
}

class _CheckForUpdatesPageState extends State<CheckForUpdatesPage> {
  StreamSubscription<FlutterFalconUpdateEvent>? _subscription;
  FlutterFalconUpdateInfo? _info;
  FlutterFalconUpdateEvent? _event;
  String? _failure;
  bool _checking = false;
  bool _acting = false;

  bool get _busy => _checking || _acting;

  @override
  void initState() {
    super.initState();
    _listen();
    unawaited(_check());
  }

  @override
  void didUpdateWidget(CheckForUpdatesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      unawaited(_subscription?.cancel());
      _info = null;
      _event = null;
      _failure = null;
      _listen();
      unawaited(_check());
    }
  }

  void _listen() {
    _subscription = widget.controller.events.listen(
      (event) {
        if (!mounted) return;
        setState(() {
          _event = event;
          if (event.state == FlutterFalconUpdateState.failed) {
            _failure = event.reason;
          }
        });
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() => _failure = error.toString());
      },
    );
  }

  Future<void> _check() async {
    if (_busy) return;
    setState(() {
      _checking = true;
      _failure = null;
    });
    try {
      final info = await widget.controller.checkForUpdate();
      if (!mounted) return;
      setState(() => _info = info);
    } catch (error) {
      if (!mounted) return;
      setState(() => _failure = error.toString());
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _runAction(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _acting = true;
      _failure = null;
    });
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      setState(() => _failure = error.toString());
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 560;
    final info = _info;
    final plan = info?.plan;
    final state = _visibleState;
    return Scaffold(
      appBar: AppBar(
        title: const Text('73+ Check for updates'),
        actions: [
          IconButton(
            key: const Key('check-updates-icon-button'),
            onPressed: _busy ? null : _check,
            tooltip: 'Check again',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: SelectionArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(compact ? 16 : 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StatusPanel(
                      state: state,
                      reason: _failure ?? _event?.reason ?? info?.reason,
                      progress: _event?.progress,
                    ),
                    if (info != null) ...[
                      const SizedBox(height: 16),
                      _VersionSummary(info: info),
                      const SizedBox(height: 16),
                      _RouteSummary(info: info),
                    ],
                    if (_failure != null) ...[
                      const SizedBox(height: 16),
                      _FailurePanel(message: _failure!, onRetry: _check),
                    ],
                    const SizedBox(height: 16),
                    _ActionPanel(
                      info: info,
                      busy: _busy,
                      compact: compact,
                      onCheck: _check,
                      onStart:
                          plan?.capabilities.contains(
                                    FlutterFalconUpdateCapability.start,
                                  ) ==
                                  true
                              ? () => _runAction(
                                () => widget.controller.startUpdate(info!),
                              )
                              : null,
                      onStore:
                          plan?.capabilities.contains(
                                    FlutterFalconUpdateCapability.openStore,
                                  ) ==
                                  true
                              ? () => _runAction(
                                () => widget.controller.openStore(info!),
                              )
                              : null,
                      onManualDownload:
                          (plan?.manualArtifactUrl != null ||
                                      plan?.artifactUrl != null) &&
                                  plan?.profile.storeManaged == false
                              ? () => _runAction(
                                () =>
                                    widget.controller.openManualDownload(info!),
                              )
                              : null,
                      onCancel:
                          plan?.capabilities.contains(
                                    FlutterFalconUpdateCapability.cancel,
                                  ) ==
                                  true
                              ? () => _runAction(
                                () => widget.controller.cancelUpdate(info!),
                              )
                              : null,
                    ),
                    if (info != null) ...[
                      const SizedBox(height: 16),
                      _Diagnostics(
                        info: info,
                        configuration: widget.controller.configuration,
                      ),
                    ],
                    if (widget.onCaptureRuntimeLogsChanged != null) ...[
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        value: widget.captureRuntimeLogs,
                        onChanged: widget.onCaptureRuntimeLogsChanged,
                        title: const Text('Send diagnostic logs'),
                        subtitle: const Text(
                          'Optional redacted application logs. Error reports '
                          'remain minimized and automatic.',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  FlutterFalconUpdateState get _visibleState {
    if (_failure != null) return FlutterFalconUpdateState.failed;
    if (_checking) return FlutterFalconUpdateState.checking;
    if (_event != null) return _event!.state;
    return _info?.state ?? FlutterFalconUpdateState.unavailable;
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.state,
    required this.reason,
    required this.progress,
  });

  final FlutterFalconUpdateState state;
  final String? reason;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final failed = state == FlutterFalconUpdateState.failed;
    final current = state == FlutterFalconUpdateState.current;
    final background =
        failed
            ? colors.errorContainer
            : current
            ? colors.tertiaryContainer
            : colors.primaryContainer;
    final foreground =
        failed
            ? colors.onErrorContainer
            : current
            ? colors.onTertiaryContainer
            : colors.onPrimaryContainer;
    final progressValue = progress?.clamp(0.0, 1.0).toDouble();
    return Semantics(
      liveRegion: true,
      child: Container(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_stateIcon(state), color: foreground, size: 30),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _stateTitle(state),
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          reason?.trim().isNotEmpty == true
                              ? reason!
                              : _stateDescription(state),
                          style: TextStyle(color: foreground, height: 1.35),
                        ),
                        if (progressValue != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            '${(progressValue * 100).round()}%',
                            style: TextStyle(
                              color: foreground,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_stateIsActive(state))
              LinearProgressIndicator(
                value: progressValue,
                color: foreground,
                backgroundColor: background,
              ),
          ],
        ),
      ),
    );
  }
}

class _VersionSummary extends StatelessWidget {
  const _VersionSummary({required this.info});

  final FlutterFalconUpdateInfo info;

  @override
  Widget build(BuildContext context) {
    final installed = info.installed.displayVersion;
    final target = info.plan?.targetVersion ?? installed;
    return Row(
      children: [
        Expanded(child: _Fact(label: 'Installed', value: installed)),
        const SizedBox(width: 12),
        Expanded(child: _Fact(label: 'Available', value: target)),
      ],
    );
  }
}

class _RouteSummary extends StatelessWidget {
  const _RouteSummary({required this.info});

  final FlutterFalconUpdateInfo info;

  @override
  Widget build(BuildContext context) {
    final plan = info.plan;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _Fact(label: 'Platform', value: info.installed.platform.name),
        _Fact(label: 'Profile', value: info.installed.profile.wireName),
        _Fact(label: 'Route', value: plan?.route.name ?? 'No update'),
        _Fact(label: 'Architecture', value: info.installed.architecture),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 130),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _FailurePanel extends StatelessWidget {
  const _FailurePanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Failure details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.onErrorContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            message,
            style: TextStyle(color: colors.onErrorContainer),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            key: const Key('retry-update-check-button'),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.info,
    required this.busy,
    required this.compact,
    required this.onCheck,
    required this.onStart,
    required this.onStore,
    required this.onManualDownload,
    required this.onCancel,
  });

  final FlutterFalconUpdateInfo? info;
  final bool busy;
  final bool compact;
  final VoidCallback onCheck;
  final VoidCallback? onStart;
  final VoidCallback? onStore;
  final VoidCallback? onManualDownload;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      if (onStart != null)
        FilledButton.icon(
          key: const Key('falcon-update-button'),
          onPressed: busy ? null : onStart,
          icon: const Icon(Icons.system_update_alt),
          label: Text(_startLabel(info)),
        ),
      if (onStore != null)
        FilledButton.icon(
          key: const Key('store-update-button'),
          onPressed: busy ? null : onStore,
          icon: const Icon(Icons.storefront_outlined),
          label: const Text('Open store'),
        ),
      if (onManualDownload != null)
        OutlinedButton.icon(
          key: const Key('manual-download-button'),
          onPressed: busy ? null : onManualDownload,
          icon: const Icon(Icons.download_outlined),
          label: const Text('Download APK manually'),
        ),
      if (onCancel != null)
        OutlinedButton.icon(
          key: const Key('cancel-update-button'),
          onPressed: busy ? null : onCancel,
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Cancel update'),
        ),
      OutlinedButton.icon(
        key: const Key('check-updates-button'),
        onPressed: busy ? null : onCheck,
        icon: const Icon(Icons.refresh),
        label: Text(info == null ? 'Check for updates' : 'Check again'),
      ),
    ];
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < buttons.length; index++) ...[
            buttons[index],
            if (index != buttons.length - 1) const SizedBox(height: 8),
          ],
        ],
      );
    }
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 12,
      runSpacing: 12,
      children: buttons,
    );
  }
}

class _Diagnostics extends StatelessWidget {
  const _Diagnostics({required this.info, required this.configuration});

  final FlutterFalconUpdateInfo info;
  final FlutterFalconV2Configuration configuration;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: const Text('Request diagnostics'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DiagnosticValue('App ID', configuration.appId),
          _DiagnosticValue('Client ID', info.installed.clientId),
          _DiagnosticValue('Channel', configuration.channel),
          _DiagnosticValue('Server', configuration.serverUrl),
          _DiagnosticValue('Package', info.installed.packageName),
          _DiagnosticValue('OS version', info.installed.osVersion),
          _DiagnosticValue(
            'Release ID',
            info.plan?.releaseId ?? 'No update selected',
          ),
        ],
      ),
    );
  }
}

class _DiagnosticValue extends StatelessWidget {
  const _DiagnosticValue(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: const TextStyle(fontFamily: 'monospace', height: 1.35),
          ),
        ],
      ),
    );
  }
}

bool _stateIsActive(FlutterFalconUpdateState state) => switch (state) {
  FlutterFalconUpdateState.checking ||
  FlutterFalconUpdateState.waitingForUser ||
  FlutterFalconUpdateState.downloading ||
  FlutterFalconUpdateState.installing => true,
  _ => false,
};

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
  FlutterFalconUpdateState.failed => 'Update request failed',
  FlutterFalconUpdateState.unavailable => 'Ready to check',
};

String _stateDescription(FlutterFalconUpdateState state) => switch (state) {
  FlutterFalconUpdateState.checking =>
    'Checking the exact distribution profile for this installed app.',
  FlutterFalconUpdateState.current =>
    'No newer release is available for this profile and channel.',
  FlutterFalconUpdateState.available =>
    'A compatible update is ready through the declared route.',
  FlutterFalconUpdateState.waitingForUser =>
    'Continue in the operating-system confirmation screen.',
  FlutterFalconUpdateState.downloading =>
    'The verified update artifact is downloading.',
  FlutterFalconUpdateState.installing =>
    'The operating system is installing the verified update.',
  FlutterFalconUpdateState.restartRequired =>
    'Restart the app to finish activating the update.',
  FlutterFalconUpdateState.completed => 'The update finished successfully.',
  FlutterFalconUpdateState.cancelled => 'The update was cancelled.',
  FlutterFalconUpdateState.failed =>
    'The complete failure reason is shown below.',
  FlutterFalconUpdateState.unavailable =>
    'Start a check to inspect the installed app and update route.',
};

IconData _stateIcon(FlutterFalconUpdateState state) => switch (state) {
  FlutterFalconUpdateState.current ||
  FlutterFalconUpdateState.completed => Icons.check_circle_outline,
  FlutterFalconUpdateState.available => Icons.system_update_alt,
  FlutterFalconUpdateState.checking ||
  FlutterFalconUpdateState.downloading ||
  FlutterFalconUpdateState.installing => Icons.downloading,
  FlutterFalconUpdateState.waitingForUser => Icons.touch_app_outlined,
  FlutterFalconUpdateState.restartRequired => Icons.restart_alt,
  FlutterFalconUpdateState.cancelled => Icons.cancel_outlined,
  FlutterFalconUpdateState.failed => Icons.error_outline,
  FlutterFalconUpdateState.unavailable => Icons.update,
};

String _startLabel(FlutterFalconUpdateInfo? info) => switch (info?.updateType) {
  FlutterFalconUpdateType.dartPatch => 'Apply FlutterFalcon patch',
  FlutterFalconUpdateType.fullPackage => switch (info?.installed.platform) {
    FlutterFalconPlatform.android => 'Install Android update',
    FlutterFalconPlatform.windows => 'Open App Installer',
    FlutterFalconPlatform.macos => 'Open Apple Installer',
    FlutterFalconPlatform.linux => 'Install AppImage update',
    _ => 'Install full update',
  },
  FlutterFalconUpdateType.webApp => 'Apply web update',
  FlutterFalconUpdateType.store => 'Open store',
  null => 'Start update',
};
