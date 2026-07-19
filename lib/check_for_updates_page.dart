import 'package:flutter/material.dart';
import 'package:flutter_falcon/flutter_falcon_api.dart';

import 'flutter_falcon_updates.dart';

class CheckForUpdatesPage extends StatefulWidget {
  const CheckForUpdatesPage({super.key, this.controller = falconController});

  static const routeName = '/updates';

  final FlutterFalconControllerApi controller;

  @override
  State<CheckForUpdatesPage> createState() => _CheckForUpdatesPageState();
}

class _CheckForUpdatesPageState extends State<CheckForUpdatesPage> {
  late final FlutterFalconUpdateSession _session;

  @override
  void initState() {
    super.initState();
    _session = FlutterFalconUpdateSession(controller: widget.controller)
      ..addListener(_sessionChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _session.check(clearActionResult: false);
      }
    });
  }

  void _sessionChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _session
      ..removeListener(_sessionChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessionState = _session.state;
    final info = sessionState.info;
    final status = sessionState.presentation;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check for updates'),
        actions: [
          IconButton(
            key: const Key('check-updates-icon-button'),
            onPressed: sessionState.isBusy ? null : () => _session.check(),
            tooltip: 'Check again',
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Flutter Falcon updates',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Review the installed runtime and safely apply updates '
                    'from the stable channel.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Semantics(
                    liveRegion: true,
                    label: status.title,
                    child: _StatusPanel(
                      presentation: status,
                      showProgress:
                          sessionState.operation ==
                              FlutterFalconSessionOperation.checking ||
                          sessionState.operation ==
                              FlutterFalconSessionOperation.applying ||
                          sessionState.operation ==
                              FlutterFalconSessionOperation.confirmingBoot,
                    ),
                  ),
                  if (sessionState.actionResult?.succeeded ?? false) ...[
                    const SizedBox(height: 12),
                    _FeedbackPanel(
                      message: sessionState.actionResult!.message,
                      success: true,
                    ),
                  ],
                  if (sessionState.failureMessage != null) ...[
                    const SizedBox(height: 12),
                    _FailurePanel(
                      message: sessionState.failureMessage!,
                      statusCode: info?.failureStatusCode,
                      responseBody: info?.failureResponseBody,
                      onRetry:
                          sessionState.isBusy ? null : () => _session.check(),
                    ),
                  ],
                  if (info != null) ...[
                    const SizedBox(height: 24),
                    _VersionSummary(info: info),
                    const SizedBox(height: 24),
                    Text(
                      'Update status',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      label: 'Check status',
                      value: info.checkStatus.name,
                    ),
                    _InfoRow(
                      label: 'Runtime state',
                      value: info.runtimeState.name,
                    ),
                    _InfoRow(
                      label: 'Effective app ID',
                      value: info.effectiveAppId,
                      monospace: true,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      info.statusExplanation,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _ActionBar(
                    presentation: status,
                    hasInfo: info != null,
                    busy: sessionState.isBusy,
                    onCheck: () => _session.check(),
                    onPrimaryAction: _session.runPrimaryAction,
                  ),
                  if (info != null) ...[
                    const SizedBox(height: 24),
                    _Diagnostics(info: info),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.presentation, required this.showProgress});

  final FlutterFalconUpdatePresentation presentation;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (background, foreground) = switch (presentation.tone) {
      FlutterFalconStatusTone.failure => (
        colors.errorContainer,
        colors.onErrorContainer,
      ),
      FlutterFalconStatusTone.success || FlutterFalconStatusTone.stable => (
        colors.tertiaryContainer,
        colors.onTertiaryContainer,
      ),
      FlutterFalconStatusTone.available ||
      FlutterFalconStatusTone.staged ||
      FlutterFalconStatusTone.warning ||
      FlutterFalconStatusTone
          .rollback => (colors.secondaryContainer, colors.onSecondaryContainer),
      FlutterFalconStatusTone.neutral => (
        colors.primaryContainer,
        colors.onPrimaryContainer,
      ),
    };
    final icon = switch (presentation.glyph) {
      FlutterFalconStatusGlyph.config => Icons.settings_outlined,
      FlutterFalconStatusGlyph.verified => Icons.check_circle_outline,
      FlutterFalconStatusGlyph.download => Icons.downloading,
      FlutterFalconStatusGlyph.packageReady => Icons.inventory_2_outlined,
      FlutterFalconStatusGlyph.active => Icons.task_alt,
      FlutterFalconStatusGlyph.pending => Icons.restart_alt,
      FlutterFalconStatusGlyph.rollback => Icons.restore,
      FlutterFalconStatusGlyph.failure => Icons.error_outline,
    };
    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: foreground, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        presentation.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        presentation.detail,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: foreground,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (showProgress)
            LinearProgressIndicator(
              minHeight: 3,
              color: foreground,
              backgroundColor: background,
            ),
        ],
      ),
    );
  }
}

class _FeedbackPanel extends StatelessWidget {
  const _FeedbackPanel({required this.message, required this.success});

  final String message;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground =
        success ? colors.onTertiaryContainer : colors.onErrorContainer;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: success ? colors.tertiaryContainer : colors.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              success ? Icons.task_alt : Icons.info_outline,
              color: foreground,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FailurePanel extends StatelessWidget {
  const _FailurePanel({
    required this.message,
    required this.statusCode,
    required this.responseBody,
    required this.onRetry,
  });

  final String message;
  final int? statusCode;
  final String? responseBody;
  final VoidCallback? onRetry;

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
          if (statusCode != null) ...[
            const SizedBox(height: 8),
            Text(
              'HTTP status: $statusCode',
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ],
          if (responseBody?.isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            SelectableText(
              responseBody!,
              style: TextStyle(
                color: colors.onErrorContainer,
                fontFamily: 'monospace',
              ),
            ),
          ],
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

class _VersionSummary extends StatelessWidget {
  const _VersionSummary({required this.info});

  final FlutterFalconVersionInfo info;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Installed', info.installedVersion),
      ('Current runtime', info.currentRuntimeVersion),
      ('Latest hosted', info.latestVersion),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 560;
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              narrow
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var index = 0; index < items.length; index++) ...[
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: _VersionValue(
                            label: items[index].$1,
                            value: items[index].$2,
                          ),
                        ),
                        if (index < items.length - 1) const Divider(height: 1),
                      ],
                    ],
                  )
                  : IntrinsicHeight(
                    child: Row(
                      children: [
                        for (var index = 0; index < items.length; index++) ...[
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: _VersionValue(
                                label: items[index].$1,
                                value: items[index].$2,
                              ),
                            ),
                          ),
                          if (index < items.length - 1)
                            const VerticalDivider(width: 1),
                        ],
                      ],
                    ),
                  ),
        );
      },
    );
  }
}

class _VersionValue extends StatelessWidget {
  const _VersionValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 5),
        SelectableText(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.monospace = false,
  });

  final String label;
  final String value;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 152,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontFamily: monospace ? 'monospace' : null,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.presentation,
    required this.hasInfo,
    required this.busy,
    required this.onCheck,
    required this.onPrimaryAction,
  });

  final FlutterFalconUpdatePresentation presentation;
  final bool hasInfo;
  final bool busy;
  final VoidCallback onCheck;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final hasPrimaryAction =
        presentation.action != FlutterFalconPrimaryAction.none;
    final confirming =
        presentation.action == FlutterFalconPrimaryAction.confirmBoot;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.end,
      children: [
        OutlinedButton.icon(
          key: const Key('check-updates-button'),
          onPressed: busy ? null : onCheck,
          icon: const Icon(Icons.refresh),
          label: Text(hasInfo ? 'Check again' : 'Check for updates'),
        ),
        if (hasPrimaryAction)
          FilledButton.icon(
            key: const Key('falcon-primary-action-button'),
            onPressed: busy ? null : onPrimaryAction,
            icon:
                busy
                    ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Icon(
                      confirming ? Icons.verified_outlined : Icons.downloading,
                    ),
            label: Text(presentation.actionLabel),
          ),
      ],
    );
  }
}

class _Diagnostics extends StatelessWidget {
  const _Diagnostics({required this.info});

  final FlutterFalconVersionInfo info;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: const Text('Request diagnostics'),
        subtitle: const Text('App stream, channel, and exact check URLs'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DiagnosticValue('Configured app ID', info.configuredAppId),
          _DiagnosticValue('Effective app ID', info.effectiveAppId),
          _DiagnosticValue('App ID source', info.appIdSource.name),
          const _DiagnosticValue('Channel', 'stable'),
          _DiagnosticValue('Server', info.serverUrl),
          _DiagnosticValue('Base version', info.baseVersion),
          _DiagnosticValue('Installable target', info.installableTargetVersion),
          _DiagnosticValue('Updates request', info.updatesRequestUrl),
          _DiagnosticValue(
            'Latest release request',
            info.releaseLatestRequestUrl,
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
