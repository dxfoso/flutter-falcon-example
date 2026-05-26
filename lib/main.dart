import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_falcon/flutter_falcon.dart';

const _channel = 'stable';

void main() => runApp(const RedRectApp());

class RedRectApp extends StatelessWidget {
  const RedRectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const FalconVersionPage(),
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
              width: 340,
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
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  const Text('Latest version on server'),
                  Text(
                    data.latestVersion,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
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
                  Text(
                    data.appId,
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
    required this.updateAvailable,
  });

  final String installedVersion;
  final String latestVersion;
  final String appId;
  final bool updateAvailable;
}

Future<_VersionInfo> _loadVersionInfo() async {
  final rawConfig = await rootBundle.loadString('.flutter_falcon.json');
  final client = FlutterFalconUpdateClient.fromJsonString(rawConfig);

  final installedVersion = client.config.baseVersion.trim();
  final latestVersion = await _fetchLatestVersion(
    serverUrl: client.config.serverUrl,
    appId: client.config.appId,
    platform: client.config.resolvedPlatform,
  );

  return _VersionInfo(
    installedVersion: installedVersion.isEmpty ? 'Unknown' : installedVersion,
    latestVersion: latestVersion,
    appId: client.config.appId,
    updateAvailable:
        installedVersion.isNotEmpty && installedVersion != latestVersion,
  );
}

Future<String> _fetchLatestVersion({
  required String serverUrl,
  required String appId,
  required String platform,
}) async {
  final uri = Uri.parse(serverUrl).replace(
    path: '/releases/latest',
    queryParameters: <String, String>{
      'appId': appId,
      'platform': platform,
      'channel': _channel,
    },
  );

  final request = await HttpClient().getUrl(uri);
  final response = await request.close();
  final body = await response.fold<String>(
    '',
    (acc, chunk) => acc + utf8.decode(chunk, allowMalformed: true),
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('Request failed with ${response.statusCode}: $body');
  }

  final payload = json.decode(body);
  if (payload is! Map<String, dynamic>) {
    throw Exception('Unexpected releases response.');
  }

  final version = (payload['version'] as String?)?.trim();
  if (version == null || version.isEmpty) {
    throw Exception('Server response has no version.');
  }
  return version;
}
