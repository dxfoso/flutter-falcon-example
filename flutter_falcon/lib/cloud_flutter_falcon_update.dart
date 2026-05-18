import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

class CloudFlutterFalconUpdateConfig {
  const CloudFlutterFalconUpdateConfig({
    this.serverUrl = '',
    this.readToken = '',
    this.appId = '',
    this.platform = '',
    this.channel = 'stable',
    this.baseVersion = '',
    this.rolloutKey = '',
  });

  factory CloudFlutterFalconUpdateConfig.fromEnvironment() {
    return const CloudFlutterFalconUpdateConfig(
      serverUrl: String.fromEnvironment('FLUTTER_FALCON_SERVER_URL'),
      readToken: String.fromEnvironment('FLUTTER_FALCON_READ_TOKEN'),
      appId: String.fromEnvironment('FLUTTER_FALCON_APP_ID'),
      platform: String.fromEnvironment('FLUTTER_FALCON_PLATFORM'),
      channel: String.fromEnvironment(
        'FLUTTER_FALCON_CHANNEL',
        defaultValue: 'stable',
      ),
      baseVersion: String.fromEnvironment('FLUTTER_FALCON_BASE_VERSION'),
      rolloutKey: String.fromEnvironment('FLUTTER_FALCON_ROLLOUT_KEY'),
    );
  }

  final String serverUrl;
  final String readToken;
  final String appId;
  final String platform;
  final String channel;
  final String baseVersion;
  final String rolloutKey;

  bool get isConfigured =>
      serverUrl.trim().isNotEmpty &&
      appId.trim().isNotEmpty &&
      platform.trim().isNotEmpty &&
      baseVersion.trim().isNotEmpty;
}

class CloudFlutterFalconUpdateInfo {
  const CloudFlutterFalconUpdateInfo({
    required this.configured,
    required this.updateAvailable,
    required this.currentVersion,
    this.targetVersion,
    this.message,
  });

  final bool configured;
  final bool updateAvailable;
  final String currentVersion;
  final String? targetVersion;
  final String? message;
}

class CloudFlutterFalconUpdateClient {
  const CloudFlutterFalconUpdateClient({
    this.config = const CloudFlutterFalconUpdateConfig(),
  });

  final CloudFlutterFalconUpdateConfig config;

  Future<CloudFlutterFalconUpdateInfo> check() async {
    final effective =
        config.isConfigured
            ? config
            : CloudFlutterFalconUpdateConfig.fromEnvironment();
    if (!effective.isConfigured) {
      return CloudFlutterFalconUpdateInfo(
        configured: false,
        updateAvailable: false,
        currentVersion: effective.baseVersion,
        message: 'Falcon update settings are not configured for this build.',
      );
    }

    final serverUri = Uri.tryParse(effective.serverUrl);
    if (serverUri == null || serverUri.host.isEmpty) {
      return CloudFlutterFalconUpdateInfo(
        configured: true,
        updateAvailable: false,
        currentVersion: effective.baseVersion,
        message: 'Falcon update server URL is invalid.',
      );
    }

    final uri = serverUri.replace(
      path: _joinPath(serverUri.path, 'updates'),
      queryParameters: {
        'appId': effective.appId,
        'platform': effective.platform,
        'channel': effective.channel,
        'baseVersion': effective.baseVersion,
        if (effective.rolloutKey.trim().isNotEmpty)
          'rolloutKey': effective.rolloutKey,
      },
    );

    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      if (effective.readToken.trim().isNotEmpty) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer ${effective.readToken}',
        );
      }
      final response = await request.close();
      final body = await utf8.decodeStream(response);
      if (response.statusCode != HttpStatus.ok) {
        return CloudFlutterFalconUpdateInfo(
          configured: true,
          updateAvailable: false,
          currentVersion: effective.baseVersion,
          message: 'Falcon check failed: HTTP ${response.statusCode}.',
        );
      }
      final decoded = json.decode(body);
      final update = decoded is Map ? decoded['update'] : null;
      if (update is! Map) {
        return CloudFlutterFalconUpdateInfo(
          configured: true,
          updateAvailable: false,
          currentVersion: effective.baseVersion,
          message: 'Version ${effective.baseVersion} is current.',
        );
      }
      final targetVersion = update['targetVersion']?.toString();
      return CloudFlutterFalconUpdateInfo(
        configured: true,
        updateAvailable: targetVersion != null && targetVersion.isNotEmpty,
        currentVersion: effective.baseVersion,
        targetVersion: targetVersion,
        message:
            targetVersion == null || targetVersion.isEmpty
                ? 'Version ${effective.baseVersion} is current.'
                : 'Falcon update available: $targetVersion.',
      );
    } on FormatException catch (error) {
      return CloudFlutterFalconUpdateInfo(
        configured: true,
        updateAvailable: false,
        currentVersion: effective.baseVersion,
        message: 'Falcon response was invalid: ${error.message}.',
      );
    } on SocketException catch (error) {
      return CloudFlutterFalconUpdateInfo(
        configured: true,
        updateAvailable: false,
        currentVersion: effective.baseVersion,
        message: 'Falcon server is unreachable: ${error.message}.',
      );
    } finally {
      client.close(force: true);
    }
  }
}

class CloudFlutterFalconUpdateButton extends StatefulWidget {
  const CloudFlutterFalconUpdateButton({
    super.key,
    this.config = const CloudFlutterFalconUpdateConfig(),
    this.child,
  });

  final CloudFlutterFalconUpdateConfig config;
  final Widget? child;

  @override
  State<CloudFlutterFalconUpdateButton> createState() =>
      _CloudFlutterFalconUpdateButtonState();
}

class _CloudFlutterFalconUpdateButtonState
    extends State<CloudFlutterFalconUpdateButton> {
  bool _checking = false;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _checking ? null : _checkForUpdate,
      icon:
          _checking
              ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : const Icon(Icons.system_update_alt),
      label: widget.child ?? const Text('Check for update'),
    );
  }

  Future<void> _checkForUpdate() async {
    setState(() {
      _checking = true;
    });
    final info =
        await CloudFlutterFalconUpdateClient(config: widget.config).check();
    if (!mounted) return;
    setState(() {
      _checking = false;
    });
    await showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Falcon update'),
            content: Text(_messageFor(info)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  String _messageFor(CloudFlutterFalconUpdateInfo info) {
    if (!info.configured) {
      return info.message ?? 'Falcon update settings are not configured.';
    }
    if (info.updateAvailable && info.targetVersion != null) {
      return 'Installed: ${info.currentVersion}\n'
          'Falcon: ${info.targetVersion}\n\n'
          'Apply the published Falcon update through the updater flow.';
    }
    return info.message ?? 'Installed: ${info.currentVersion}\nFalcon: current';
  }
}

String _joinPath(String basePath, String child) {
  final cleanBase =
      basePath.endsWith('/')
          ? basePath.substring(0, basePath.length - 1)
          : basePath;
  if (cleanBase.isEmpty) return '/$child';
  return '$cleanBase/$child';
}
