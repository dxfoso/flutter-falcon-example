import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_falcon/flutter_falcon_api.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'falcon_versioning.dart';
import 'falcon_runtime_support_stub.dart'
    if (dart.library.io) 'falcon_runtime_support_io.dart';

const _defaultServerUrl = 'https://flutterfalcon.com';
const _channel = 'stable';
const _buildUnknownVersion = 'Unknown';

void main() => runApp(const RedRectApp());

class RedRectApp extends StatelessWidget {
  const RedRectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FalconVersionPage(),
    );
  }
}

class FalconVersionPage extends StatefulWidget {
  const FalconVersionPage({super.key});

  @override
  State<FalconVersionPage> createState() => _FalconVersionPageState();
}

class _FalconVersionPageState extends State<FalconVersionPage> {
  late Future<_VersionInfo> _infoFuture;
  bool _actionRunning = false;
  String? _actionMessage;
  String? _actionError;

  @override
  void initState() {
    super.initState();
    _infoFuture = _loadVersionInfo();
  }

  Future<void> _refresh() async {
    setState(() {
      _actionMessage = null;
      _actionError = null;
      _infoFuture = _loadVersionInfo();
    });
  }

  Future<void> _applyOrConfirm(_VersionInfo info) async {
    setState(() {
      _actionRunning = true;
      _actionMessage = null;
      _actionError = null;
    });
    try {
      final client = _createClient(
        serverUrl: info.serverUrl,
        configuredAppId: info.configuredAppId,
        baseVersion: info.baseVersion,
      );
      if (info.requiresBootConfirmation) {
        final result = await falconConfirmBoot(client: client);
        setState(() {
          _actionMessage =
              result.changed
                  ? 'Boot confirmed for ${info.activePatchVersion ?? info.latestVersion}.'
                  : result.message;
        });
      } else if (info.installableUpdateAvailable) {
        final result = await falconApplyUpdate(
          client: client,
          installedVersion: info.installedVersion,
        );
        if (result.changed) {
          setState(() {
            _actionMessage = result.message;
          });
        } else {
          setState(() {
            _actionError = result.message;
          });
        }
      } else {
        setState(() {
          _actionMessage =
              'No installable Falcon update is available right now.';
        });
      }
      await _refresh();
    } catch (error) {
      setState(() {
        _actionError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _actionRunning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1EE),
      appBar: AppBar(
        title: const Text('Flutter Falcon Version'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<_VersionInfo>(
        future: _infoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final message = snapshot.error?.toString() ?? 'unknown error';
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Unable to load version info.\n$message',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data = snapshot.data!;
          return Center(
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFd7dde2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Installed version'),
                  Text(
                    data.installedVersion,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Latest version on server'),
                  Text(
                    data.latestVersion,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Installable Falcon target'),
                  Text(
                    data.installableTargetVersion,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  const Text('Server check status'),
                  Text(
                    data.checkStatus,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color:
                          data.checkStatus == 'available'
                              ? Colors.orange.shade700
                              : data.checkStatus == 'failed' ||
                                  data.checkStatus == 'notConfigured'
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Runtime state'),
                  Text(
                    data.runtimeState,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (data.activePatchVersion != null) ...[
                    const SizedBox(height: 8),
                    const Text('Active patch version'),
                    Text(
                      data.activePatchVersion!,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                  if (_actionMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _actionMessage!,
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (_actionError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _actionError!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (data.failureMessage != null) ...[
                    const SizedBox(height: 8),
                    const Text('Check failure'),
                    Text(
                      data.failureMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Text('What this means'),
                  Text(
                    data.statusExplanation,
                    style: const TextStyle(height: 1.3),
                  ),
                  const SizedBox(height: 12),
                  const Text('Exact /updates request'),
                  Text(
                    data.updatesRequestUrl,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Exact /releases/latest request'),
                  Text(
                    data.releaseLatestRequestUrl,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Request context sent to server'),
                  Text(
                    'configuredAppId: ${data.configuredAppId}',
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                  Text(
                    'effectiveAppId: ${data.effectiveAppId}',
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                  Text(
                    'appIdSource: ${data.appIdSource}',
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                  Text(
                    'channel: $_channel',
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                  Text(
                    'baseVersion: ${data.baseVersion}',
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                  Text(
                    'latestReleaseFound: ${data.latestReleaseFound ? 'yes' : 'no'}',
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                  Text(
                    'configured: ${data.configured ? 'yes' : 'no'}',
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                  if (data.failureStatusCode != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'failure status code: ${data.failureStatusCode}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.red,
                      ),
                    ),
                  ],
                  if (data.failureResponseBody != null) ...[
                    const SizedBox(height: 4),
                    const Text('failure response'),
                    Text(
                      data.failureResponseBody!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.red,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    data.updateAvailable
                        ? 'Newer hosted version exists'
                        : 'Hosted version matches this build',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color:
                          data.updateAvailable
                              ? Colors.green.shade700
                              : Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed:
                          _actionRunning ||
                                  (!data.installableUpdateAvailable &&
                                      !data.requiresBootConfirmation)
                              ? null
                              : () => _applyOrConfirm(data),
                      icon:
                          _actionRunning
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : Icon(
                                data.requiresBootConfirmation
                                    ? Icons.verified
                                    : Icons.system_update_alt,
                              ),
                      label: Text(
                        data.requiresBootConfirmation
                            ? 'Confirm updated boot'
                            : 'Download and apply update',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('effective appId', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    data.effectiveAppId,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                  if (data.configuredAppId != data.effectiveAppId) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'configured appId',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.configuredAppId,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text('server', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    data.serverUrl,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VersionInfo {
  const _VersionInfo({
    required this.installedVersion,
    required this.latestVersion,
    required this.installableTargetVersion,
    required this.configuredAppId,
    required this.effectiveAppId,
    required this.appIdSource,
    required this.serverUrl,
    required this.updateAvailable,
    required this.installableUpdateAvailable,
    required this.checkStatus,
    this.failureMessage,
    required this.statusExplanation,
    required this.baseVersion,
    required this.configured,
    required this.failureStatusCode,
    required this.failureResponseBody,
    required this.updatesRequestUrl,
    required this.releaseLatestRequestUrl,
    required this.latestReleaseFound,
    required this.runtimeState,
    required this.requiresBootConfirmation,
    required this.activePatchVersion,
  });

  final String installedVersion;
  final String latestVersion;
  final String installableTargetVersion;
  final String configuredAppId;
  final String effectiveAppId;
  final String appIdSource;
  final String serverUrl;
  final bool updateAvailable;
  final bool installableUpdateAvailable;
  final String checkStatus;
  final String? failureMessage;
  final String statusExplanation;
  final String baseVersion;
  final bool configured;
  final int? failureStatusCode;
  final String? failureResponseBody;
  final String updatesRequestUrl;
  final String releaseLatestRequestUrl;
  final bool latestReleaseFound;
  final String runtimeState;
  final bool requiresBootConfirmation;
  final String? activePatchVersion;
}

Future<_VersionInfo> _loadVersionInfo() async {
  final packageInfo = await PackageInfo.fromPlatform();
  final packageVersion = falconPackageVersion(
    packageInfo.version,
    packageInfo.buildNumber,
  );
  final configuredAppId = _falconAppId(packageInfo.packageName);
  final client = _createClient(
    serverUrl: _falconServerUrl(),
    configuredAppId: configuredAppId,
    baseVersion: packageVersion,
  );
  final effectiveConfig = client.config;

  final latestReleaseResult = await client.latestRelease();
  final checkResult = await client.check();
  final snapshot = await falconStatusSnapshot(
    client: client,
    checkResult: checkResult,
  );
  if (!checkResult.configured) {
    throw Exception(
      checkResult.failureMessage ?? 'runtime configuration is incomplete',
    );
  }

  final installedVersion =
      packageVersion.isEmpty ? _buildUnknownVersion : packageVersion;
  final installableTargetVersion = checkResult.targetVersion?.trim() ?? '';
  final latestReleaseVersion = latestReleaseResult.version?.trim() ?? '';
  final latestVersion =
      latestReleaseVersion.isNotEmpty
          ? latestReleaseVersion
          : installableTargetVersion.isNotEmpty
          ? installableTargetVersion
          : installedVersion;

  return _VersionInfo(
    installedVersion: installedVersion,
    latestVersion: latestVersion,
    installableTargetVersion:
        installableTargetVersion.isEmpty
            ? installedVersion
            : installableTargetVersion,
    configuredAppId: effectiveConfig.configuredAppId,
    effectiveAppId: effectiveConfig.effectiveAppId,
    appIdSource: effectiveConfig.appIdSource.name,
    serverUrl: effectiveConfig.serverUrl,
    updateAvailable:
        packageVersion.isNotEmpty &&
        latestVersion.isNotEmpty &&
        installedVersion != latestVersion,
    installableUpdateAvailable: checkResult.updateAvailable,
    checkStatus: checkResult.status.name,
    failureMessage: checkResult.failureMessage,
    statusExplanation: _falconStatusExplanation(
      checkStatus: checkResult.status,
      configured: checkResult.configured,
      latestVersion: latestVersion,
      installableTargetVersion: installableTargetVersion,
      latestReleaseFound: latestReleaseResult.found,
      failureMessage: checkResult.failureMessage,
      requiresBootConfirmation: snapshot?.requiresBootConfirmation ?? false,
    ),
    baseVersion: packageVersion,
    configured: checkResult.configured,
    failureStatusCode: checkResult.failureStatusCode,
    failureResponseBody: checkResult.failureResponseBody,
    updatesRequestUrl: _falconUpdatesRequestUrl(
      serverUrl: effectiveConfig.serverUrl,
      appId: effectiveConfig.effectiveAppId,
      channel: _channel,
      baseVersion: packageVersion,
    ),
    releaseLatestRequestUrl: _falconReleaseLatestRequestUrl(
      serverUrl: effectiveConfig.serverUrl,
      appId: effectiveConfig.effectiveAppId,
      channel: _channel,
    ),
    latestReleaseFound: latestReleaseResult.found,
    runtimeState: snapshot?.state.name ?? 'unsupported',
    requiresBootConfirmation: snapshot?.requiresBootConfirmation ?? false,
    activePatchVersion: snapshot?.activePatchVersion,
  );
}

FlutterFalconUpdateClient _createClient({
  required String serverUrl,
  required String configuredAppId,
  required String baseVersion,
}) {
  return FlutterFalconUpdateClient(
    config: FlutterFalconUpdateConfig(
      serverUrl: serverUrl,
      appId: configuredAppId,
      channel: _channel,
      baseVersion: baseVersion,
    ),
  );
}

String _falconUpdatesRequestUrl({
  required String serverUrl,
  required String appId,
  required String channel,
  required String baseVersion,
}) {
  final parsed = Uri.tryParse(serverUrl);
  if (parsed == null) {
    return 'invalid server URL';
  }
  final normalizedPath = parsed.path.trim();
  final path =
      normalizedPath.endsWith('/updates') || normalizedPath == '/updates'
          ? normalizedPath
          : '/updates';
  final url = parsed.replace(path: path, queryParameters: null, fragment: null);
  return url
      .replace(
        queryParameters: {
          'appId': appId,
          'platform': _falconDefaultRuntimePlatform(),
          'channel': channel,
          'baseVersion': baseVersion,
        },
      )
      .toString();
}

String _falconReleaseLatestRequestUrl({
  required String serverUrl,
  required String appId,
  required String channel,
}) {
  final parsed = Uri.tryParse(serverUrl);
  if (parsed == null) {
    return 'invalid server URL';
  }
  return parsed
      .replace(
        path: '/releases/latest',
        queryParameters: {
          'appId': appId,
          'platform': _falconDefaultRuntimePlatform(),
          'channel': channel,
        },
        fragment: null,
      )
      .toString();
}

String _falconDefaultRuntimePlatform() {
  if (kIsWeb) {
    return 'web';
  }
  return switch (defaultTargetPlatform) {
    TargetPlatform.windows => 'windows-x64',
    TargetPlatform.macOS => 'macos-universal',
    TargetPlatform.linux => 'linux-x64',
    TargetPlatform.android => 'android-arm64',
    TargetPlatform.iOS => 'ios-arm64',
    TargetPlatform.fuchsia => 'fuchsia',
  };
}

String _falconStatusExplanation({
  required FlutterFalconUpdateStatus checkStatus,
  required bool configured,
  required String latestVersion,
  required String installableTargetVersion,
  required bool latestReleaseFound,
  required bool requiresBootConfirmation,
  String? failureMessage,
}) {
  if (!configured) {
    return 'Not configured: runtime config needs serverUrl, appId, and baseVersion.';
  }
  if (requiresBootConfirmation) {
    return 'An update is staged. Restart this app, verify it boots correctly, then click Confirm updated boot.';
  }
  if (checkStatus == FlutterFalconUpdateStatus.current &&
      latestReleaseFound &&
      latestVersion.isNotEmpty &&
      latestVersion != installableTargetVersion) {
    return 'Latest hosted release is "$latestVersion". No installable Falcon update is published for this installed base version yet, so /updates is still current.';
  }
  return switch (checkStatus) {
    FlutterFalconUpdateStatus.available =>
      'A newer installable Falcon update is available for this installed build. Click the button to download and activate it.',
    FlutterFalconUpdateStatus.current =>
      'No newer installable patch was found for this installed build.',
    FlutterFalconUpdateStatus.failed =>
      'The server check failed: ${failureMessage ?? 'unknown failure'}.',
    FlutterFalconUpdateStatus.notConfigured =>
      'Runtime config is incomplete for update checks.',
    FlutterFalconUpdateStatus.downloaded =>
      'An update was downloaded but not applied yet.',
    FlutterFalconUpdateStatus.active =>
      'An update is active and marked as current runtime state.',
  };
}

String _falconAppId(String packageName) {
  final trimmed = packageName.trim();
  if (trimmed.isNotEmpty) {
    return trimmed;
  }
  return 'flutter-falcon-example';
}

String _falconServerUrl() {
  return _defaultServerUrl;
}
