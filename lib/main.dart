import 'package:flutter/material.dart';
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
        title: const Text('Flutter Falcon Version'),
        actions: [IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh))],
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
                child: Text('Unable to load version info.\n$message', textAlign: TextAlign.center),
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
                  Text(data.installedVersion, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  const Text('Latest version on server'),
                  Text(data.latestVersion, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Text(
                    data.updateAvailable ? 'Update available' : 'You are up to date',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: data.updateAvailable ? Colors.green.shade700 : Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('appId', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(data.appId, style: const TextStyle(fontFamily: 'monospace')),
                  const SizedBox(height: 16),
                  const Text('server', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(data.serverUrl, style: const TextStyle(fontFamily: 'monospace')),
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
  });

  final String installedVersion;
  final String latestVersion;
  final String appId;
  final String serverUrl;
  final bool updateAvailable;
}

Future<_VersionInfo> _loadVersionInfo() async {
  final packageInfo = await PackageInfo.fromPlatform();
  final serverUrl = _falconServerUrl();
  final appId = _falconAppId(packageInfo.packageName);
  final baseVersion = _falconBaseVersion(packageInfo.version, packageInfo.buildNumber);

  final client = FlutterFalconUpdateClient(
    config: FlutterFalconUpdateConfig(
      serverUrl: serverUrl,
      appId: appId,
      channel: _channel,
      baseVersion: baseVersion,
    ),
  );

  final checkResult = await client.check();
  if (!checkResult.configured) {
    throw Exception(checkResult.failureMessage ?? 'runtime configuration is incomplete');
  }

  final installedVersion = baseVersion.isEmpty ? _buildUnknownVersion : baseVersion;
  final latestVersion = checkResult.targetVersion?.trim().isNotEmpty == true
      ? checkResult.targetVersion!.trim()
      : installedVersion;

  return _VersionInfo(
    installedVersion: installedVersion,
    latestVersion: latestVersion,
    appId: appId,
    serverUrl: serverUrl,
    updateAvailable:
        installedVersion.isNotEmpty &&
            latestVersion.isNotEmpty &&
            installedVersion != latestVersion,
  );
}

String _falconBaseVersion(String version, String buildNumber) {
  final cleanVersion = version.trim();
  final cleanBuild = buildNumber.trim();
  if (cleanVersion.isEmpty) {
    return '';
  }
  if (cleanBuild.isEmpty) {
    return cleanVersion;
  }
  if (cleanVersion.contains('+')) {
    return cleanVersion;
  }
  return '$cleanVersion+$cleanBuild';
}

String _falconAppId(String packageName) {
  final override = const String.fromEnvironment('FLUTTER_FALCON_RUNTIME_APP_ID');
  final fallback = packageName.trim();

  final trimmedOverride = override.trim();
  if (trimmedOverride.isNotEmpty) {
    return trimmedOverride;
  }
  return fallback;
}

String _falconServerUrl() {
  final override = const String.fromEnvironment('FLUTTER_FALCON_RUNTIME_SERVER_URL');
  final fallback = const String.fromEnvironment('FLUTTER_FALCON_SERVER_URL');
  final trimmedOverride = override.trim();
  if (trimmedOverride.isNotEmpty) {
    return trimmedOverride;
  }
  if (fallback.trim().isNotEmpty) {
    return fallback;
  }
  return _defaultServerUrl;
}
