import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_falcon/flutter_falcon_api.dart';

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

  @override
  void initState() {
    super.initState();
    _infoFuture = _loadVersionInfo();
  }

  Future<void> _refresh() async {
    setState(() {
      _infoFuture = _loadVersionInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1EE),
      appBar: AppBar(
        title: const Text('Flutter Falcon Version zzzx'),
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
              width: 360,
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
                  const Text('Server check status'),
                  Text(
                    data.checkStatus,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: data.checkStatus == 'available'
                          ? Colors.orange.shade700
                          : data.checkStatus == 'failed' ||
                              data.checkStatus == 'notConfigured'
                          ? Colors.red.shade700
                          : Colors.green.shade700,
                    ),
                  ),
                  if (data.failureMessage != null) ...[
                    const SizedBox(height: 8),
                    const Text('Check failure'),
                    Text(
                      data.failureMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Text('Exact /updates request'),
                  Text(
                    data.updatesRequestUrl,
                    style: const TextStyle(fontFamily: 'monospace', height: 1.2),
                  ),
                  const SizedBox(height: 12),
                  const Text('What this means'),
                  Text(data.statusExplanation, style: const TextStyle(height: 1.3)),
                  const SizedBox(height: 12),
                  const Text('Request context sent to server'),
                  Text(
                    'appId: ${data.appId}',
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
                    'configured: ${data.configured ? 'yes' : 'no'}',
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                  if (data.failureStatusCode != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'failure status code: ${data.failureStatusCode}',
                      style: const TextStyle(fontFamily: 'monospace', color: Colors.red),
                    ),
                  ],
                  if (data.failureResponseBody != null) ...[
                    const SizedBox(height: 4),
                    const Text('failure response'),
                    Text(
                      data.failureResponseBody!,
                      style: const TextStyle(fontFamily: 'monospace', color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    data.updateAvailable
                        ? 'Update available'
                        : 'You are up to date',
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
                      onPressed: _refresh,
                      icon: const Icon(Icons.system_update_alt),
                      label: const Text('Check for update'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('appId', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    data.appId,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
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
    required this.appId,
    required this.serverUrl,
    required this.updateAvailable,
    required this.checkStatus,
    this.failureMessage,
    required this.statusExplanation,
    required this.baseVersion,
    required this.configured,
    required this.failureStatusCode,
    required this.failureResponseBody,
    required this.updatesRequestUrl,
  });

  final String installedVersion;
  final String latestVersion;
  final String appId;
  final String serverUrl;
  final bool updateAvailable;
  final String checkStatus;
  final String? failureMessage;
  final String statusExplanation;
  final String baseVersion;
  final bool configured;
  final int? failureStatusCode;
  final String? failureResponseBody;
  final String updatesRequestUrl;
}

Future<_VersionInfo> _loadVersionInfo() async {
  final packageInfo = await PackageInfo.fromPlatform();
  final packageVersion = _falconPackageVersion(packageInfo.version);
  final serverUrl = _falconServerUrl();
  final appId = _falconAppId(packageInfo.packageName, packageVersion);

  final client = FlutterFalconUpdateClient(
    config: FlutterFalconUpdateConfig(
      serverUrl: serverUrl,
      appId: appId,
      channel: _channel,
      baseVersion: packageVersion,
    ),
  );

  final checkResult = await client.check();
  if (!checkResult.configured) {
    throw Exception(
      checkResult.failureMessage ?? 'runtime configuration is incomplete',
    );
  }

  final installedVersion =
      packageVersion.isEmpty ? _buildUnknownVersion : packageVersion;
  final latestVersion =
      checkResult.targetVersion?.trim().isNotEmpty == true
          ? checkResult.targetVersion!.trim()
          : installedVersion;

  return _VersionInfo(
    installedVersion: installedVersion,
    latestVersion: latestVersion,
    appId: appId,
    serverUrl: serverUrl,
    checkStatus: checkResult.status.name,
    failureMessage: checkResult.failureMessage,
    updatesRequestUrl: _falconUpdatesRequestUrl(
      serverUrl: serverUrl,
      appId: appId,
      channel: _channel,
      baseVersion: packageVersion,
    ),
    statusExplanation: _falconStatusExplanation(
      checkStatus: checkResult.status,
      configured: checkResult.configured,
      latestVersion: latestVersion,
      failureMessage: checkResult.failureMessage,
    ),
    baseVersion: packageVersion,
    configured: checkResult.configured,
    failureStatusCode: checkResult.failureStatusCode,
    failureResponseBody: checkResult.failureResponseBody,
    updateAvailable:
        packageVersion.isNotEmpty &&
        latestVersion.isNotEmpty &&
        installedVersion != latestVersion,
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
  String? failureMessage,
}) {
  if (!configured) {
    return 'Not configured: runtime config needs serverUrl, appId, and baseVersion.';
  }
  return switch (checkStatus) {
    FlutterFalconUpdateStatus.available => 'A newer target version was found on the server for your installed version.',
    FlutterFalconUpdateStatus.current => 'No newer patch was found. Server reports current as version "$latestVersion", so app is up to date relative to your current build.',
    FlutterFalconUpdateStatus.failed =>
      'The server check failed: ${failureMessage ?? 'unknown failure'}.',
    FlutterFalconUpdateStatus.notConfigured =>
      'Runtime config is incomplete for update checks.',
    FlutterFalconUpdateStatus.downloaded => 'An update was downloaded but not applied yet.',
    FlutterFalconUpdateStatus.active => 'An update is active and marked as current runtime state.',
  };
}

String _falconPackageVersion(String version) {
  final cleanVersion = version.trim();
  if (cleanVersion.isEmpty) {
    return '';
  }
  return cleanVersion;
}

String _falconAppId(String packageName, String flutterVersion) {
  final user = _falconUserTokenFromPackage(packageName);
  final normalizedVersion = _falconVersionToken(flutterVersion);
  if (user.isNotEmpty) {
    return '$user-$normalizedVersion';
  }
  return normalizedVersion;
}

String _falconServerUrl() {
  return _defaultServerUrl;
}

String _falconAppIdFromUser(String user) {
  final token = user.trim().toLowerCase();
  final cleaned = token.replaceAll(RegExp(r'[^a-z0-9._-]'), '-');
  return cleaned.isEmpty ? 'falcon-user' : cleaned;
}

String _falconVersionToken(String rawVersion) {
  final token = rawVersion.trim().toLowerCase();
  return token.replaceAll(RegExp(r'[^a-z0-9._+-]'), '-');
}

String _falconUserTokenFromPackage(String packageName) {
  final trimmed = packageName.trim().toLowerCase();
  if (trimmed.isEmpty) {
    return 'falcon-user';
  }
  final parts = trimmed.split('.').where((item) => item.isNotEmpty).toList();
  if (parts.isEmpty) {
    return 'falcon-user';
  }
  if (parts.length == 1) {
    return _falconAppIdFromUser(parts.first);
  }
  if (parts.length >= 3) {
    return _falconAppIdFromUser(parts[1]);
  }
  return _falconAppIdFromUser(parts.first);
}
