import 'package:flutter/material.dart';
import 'package:flutter_falcon/flutter_falcon_api.dart';

import 'flutter_falcon_updates.dart';

class _UpdateMessageText {
  const _UpdateMessageText({required this.title, required this.detail});

  final String title;
  final String detail;
}

_UpdateMessageText _updateMessageText(
  BuildContext context,
  FlutterFalconUpdatePresentation presentation,
) {
  final arabic = Localizations.localeOf(context).languageCode == 'ar';
  if (!arabic) {
    return _UpdateMessageText(
      title: presentation.title,
      detail: presentation.detail,
    );
  }
  return switch (presentation.code) {
    'flutter_falcon.update.up_to_date' => const _UpdateMessageText(
      title: 'تطبيقك محدّث',
      detail: 'لا يوجد تحديث متوافق متاح لهذا الإصدار من التطبيق.',
    ),
    'flutter_falcon.update.available' => const _UpdateMessageText(
      title: 'يتوفر تحديث',
      detail: 'يتوفر تحديث متوافق ويمكن تنزيله الآن.',
    ),
    'flutter_falcon.update.checking' => const _UpdateMessageText(
      title: 'جارٍ البحث عن تحديثات',
      detail: 'يتم تحميل حالة التحديث من الجهاز والخادم.',
    ),
    'flutter_falcon.update.google_play_available' => const _UpdateMessageText(
      title: 'يتوفر تحديث على Google Play',
      detail: 'يتوفر إصدار كامل أحدث ويمكن تثبيته من Google Play.',
    ),
    'flutter_falcon.update.apple_app_store_available' =>
      const _UpdateMessageText(
        title: 'يتوفر تحديث على App Store',
        detail: 'يتوفر إصدار كامل أحدث ويمكن فتحه في App Store.',
      ),
    'flutter_falcon.update.full_release_available' => const _UpdateMessageText(
      title: 'يتوفر إصدار جديد من التطبيق',
      detail: 'يوجد إصدار كامل أحدث، ولكن لا يتوفر مسار تحديث تلقائي.',
    ),
    'flutter_falcon.update.store_check_failed' => const _UpdateMessageText(
      title: 'تعذر التحقق من تحديث المتجر',
      detail: 'لم يتمكن متجر المنصة من تأكيد حالة التحديث.',
    ),
    _ => _UpdateMessageText(
      title: presentation.title,
      detail: presentation.detail,
    ),
  };
}

class CheckForUpdatesPage extends StatefulWidget {
  const CheckForUpdatesPage({
    super.key,
    this.controller = falconController,
    this.captureRuntimeLogs = false,
    this.onCaptureRuntimeLogsChanged,
  });

  static const routeName = '/updates';

  final FlutterFalconControllerApi controller;
  final bool captureRuntimeLogs;
  final ValueChanged<bool>? onCaptureRuntimeLogsChanged;

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
        title: const Text('FFFCheck for updates'),
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
        child: LayoutBuilder(
          builder: (context, viewport) {
            final compact = viewport.maxWidth < 600;
            final sectionGap = compact ? 12.0 : 24.0;
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 12 : 20,
                    compact ? 8 : 16,
                    compact ? 12 : 20,
                    compact ? 24 : 40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!compact) ...[
                        Text(
                          'Flutter Falcon updates',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Review the installed runtime and apply verified '
                          'updates from the stable channel.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      Semantics(
                        liveRegion: true,
                        label: _updateMessageText(context, status).title,
                        child: _StatusPanel(
                          presentation: status,
                          showProgress: sessionState.showProgress,
                          compact: compact,
                        ),
                      ),
                      if (sessionState.actionResult?.succeeded ?? false) ...[
                        const SizedBox(height: 8),
                        _FeedbackPanel(
                          message: sessionState.actionResult!.message,
                          success: true,
                        ),
                      ],
                      if (sessionState.failureMessage != null) ...[
                        const SizedBox(height: 8),
                        _FailurePanel(
                          message: sessionState.failureMessage!,
                          statusCode: info?.failureStatusCode,
                          responseBody: info?.failureResponseBody,
                          onRetry:
                              sessionState.isBusy
                                  ? null
                                  : () => _session.check(),
                        ),
                      ],
                      if (info != null) ...[
                        SizedBox(height: sectionGap),
                        _VersionSummary(info: info, compact: compact),
                        SizedBox(height: sectionGap),
                        _RuntimeSummary(info: info, compact: compact),
                      ],
                      SizedBox(height: sectionGap),
                      _ActionBar(
                        presentation: status,
                        info: info,
                        hasInfo: info != null,
                        busy: sessionState.isBusy,
                        compact: compact,
                        onCheck: () => _session.check(),
                        onPrimaryAction: _session.runPrimaryAction,
                      ),
                      if (info != null) ...[
                        SizedBox(height: sectionGap),
                        _Diagnostics(info: info, compact: compact),
                      ],
                      if (widget.onCaptureRuntimeLogsChanged != null) ...[
                        SizedBox(height: sectionGap),
                        SwitchListTile.adaptive(
                          value: widget.captureRuntimeLogs,
                          onChanged: widget.onCaptureRuntimeLogsChanged,
                          title: const Text('Send diagnostic logs'),
                          subtitle: const Text(
                            'Optional redacted logs help diagnose app failures.',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.presentation,
    required this.showProgress,
    required this.compact,
  });

  final FlutterFalconUpdatePresentation presentation;
  final bool showProgress;
  final bool compact;

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
            padding: EdgeInsets.all(compact ? 14 : 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: foreground, size: compact ? 24 : 28),
                SizedBox(width: compact ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _updateMessageText(context, presentation).title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: compact ? 3 : 6),
                      Text(
                        _updateMessageText(context, presentation).detail,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: foreground,
                          height: compact ? 1.25 : 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        presentation.code,
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(color: foreground),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        presentation.explanation,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: foreground),
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
  const _VersionSummary({required this.info, required this.compact});

  final FlutterFalconVersionInfo info;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final items = <({String fullLabel, String shortLabel, String value})>[
      (
        fullLabel: 'Installed',
        shortLabel: 'Installed',
        value: info.installedVersion,
      ),
      (
        fullLabel: 'Current runtime',
        shortLabel: 'Running',
        value: info.currentRuntimeVersion,
      ),
      (
        fullLabel: 'Latest hosted',
        shortLabel: 'Latest',
        value: info.latestVersion,
      ),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 10 : 16,
                    vertical: compact ? 11 : 16,
                  ),
                  child: _VersionValue(
                    label:
                        compact
                            ? items[index].shortLabel
                            : items[index].fullLabel,
                    value: items[index].value,
                    compact: compact,
                  ),
                ),
              ),
              if (index < items.length - 1) const VerticalDivider(width: 1),
            ],
          ],
        ),
      ),
    );
  }
}

class _VersionValue extends StatelessWidget {
  const _VersionValue({
    required this.label,
    required this.value,
    required this.compact,
  });

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style:
              compact
                  ? Theme.of(context).textTheme.labelMedium
                  : Theme.of(context).textTheme.labelLarge,
        ),
        SizedBox(height: compact ? 3 : 5),
        SelectableText(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: compact ? 14 : null,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _RuntimeSummary extends StatelessWidget {
  const _RuntimeSummary({required this.info, required this.compact});

  final FlutterFalconVersionInfo info;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _CompactFact(
                  label: 'Check status',
                  value: info.checkStatus.name,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CompactFact(
                  label: 'Runtime state',
                  value: info.runtimeState.name,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 10 : 14),
          _CompactFact(
            label: 'Effective app ID',
            value: info.effectiveAppId,
            monospace: true,
          ),
          SizedBox(height: compact ? 10 : 14),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          SizedBox(height: compact ? 9 : 13),
          Text(
            info.statusExplanation,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactFact extends StatelessWidget {
  const _CompactFact({
    required this.label,
    required this.value,
    this.monospace = false,
  });

  final String label;
  final String value;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        SelectableText(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontFamily: monospace ? 'monospace' : null,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.presentation,
    required this.info,
    required this.hasInfo,
    required this.busy,
    required this.compact,
    required this.onCheck,
    required this.onPrimaryAction,
  });

  final FlutterFalconUpdatePresentation presentation;
  final FlutterFalconVersionInfo? info;
  final bool hasInfo;
  final bool busy;
  final bool compact;
  final VoidCallback onCheck;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final canRunPrimaryAction =
        presentation.action != FlutterFalconPrimaryAction.none;
    final confirming =
        presentation.action == FlutterFalconPrimaryAction.confirmBoot;
    final targetVersion = switch (presentation.action) {
      FlutterFalconPrimaryAction.applyUpdate => info?.installableTargetVersion,
      FlutterFalconPrimaryAction.startStoreUpdate => info?.latestVersion,
      _ => null,
    };

    final checkButton = OutlinedButton.icon(
      key: const Key('check-updates-button'),
      onPressed: busy ? null : onCheck,
      icon: const Icon(Icons.refresh),
      label: Text(hasInfo ? 'Check again' : 'Check for updates'),
    );
    final primaryButton = FilledButton.icon(
      key: const Key('falcon-primary-action-button'),
      onPressed: busy || !canRunPrimaryAction ? null : onPrimaryAction,
      icon:
          busy
              ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : Icon(confirming ? Icons.verified_outlined : Icons.downloading),
      label: Text(
        busy || confirming
            ? presentation.actionLabel
            : targetVersion == null || targetVersion.isEmpty
            ? 'Update app'
            : 'Update to $targetVersion',
      ),
    );

    if (compact) {
      return SizedBox(
        height: 48,
        child: Row(
          children: [
            Expanded(child: checkButton),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: primaryButton),
          ],
        ),
      );
    }
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.end,
      children: [checkButton, primaryButton],
    );
  }
}

class _Diagnostics extends StatelessWidget {
  const _Diagnostics({required this.info, required this.compact});

  final FlutterFalconVersionInfo info;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        dense: compact,
        visualDensity: compact ? VisualDensity.compact : null,
        title: const Text('Request diagnostics'),
        subtitle:
            compact
                ? null
                : const Text('App stream, channel, and exact check URLs'),
        childrenPadding: EdgeInsets.fromLTRB(
          compact ? 12 : 16,
          0,
          compact ? 12 : 16,
          compact ? 12 : 16,
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DiagnosticValue('Configured app ID', info.configuredAppId),
          _DiagnosticValue('Effective app ID', info.effectiveAppId),
          _DiagnosticValue('App ID source', info.appIdSource.name),
          _DiagnosticValue('Channel', info.channel),
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
