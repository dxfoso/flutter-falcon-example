import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_falcon/flutter_falcon_api.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

final Future<String> _versionFuture = _loadVersion();

void main() => runApp(const RedRectApp());

Future<String> _loadVersion() async {
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    if (packageInfo.buildNumber.isEmpty) {
      return packageInfo.version;
    }
    return '${packageInfo.version}+${packageInfo.buildNumber}';
  } catch (_) {
    return 'unknown';
  }
}

class RedRectApp extends StatelessWidget {
  const RedRectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FalconFixturePage(),
    );
  }
}

class FalconFixturePage extends StatelessWidget {
  const FalconFixturePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _versionFuture,
      builder: (context, snapshot) {
        final version = snapshot.data;
        return Scaffold(
          backgroundColor: const Color(0xFFF6F1EE),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 280,
                  height: 180,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD63A2F),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    version ?? 'Loading...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (version == null)
                  const CircularProgressIndicator()
                else
                  FalconCheckButton(installedVersion: version),
              ],
            ),
          ),
        );
      },
    );
  }
}

class FalconCheckButton extends StatefulWidget {
  const FalconCheckButton({
    super.key,
    required this.installedVersion,
  });

  final String installedVersion;

  @override
  State<FalconCheckButton> createState() => _FalconCheckButtonState();
}

class _FalconCheckButtonState extends State<FalconCheckButton> {
  bool _checking = false;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _checking ? null : _checkForUpdate,
      icon: _checking
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.system_update_alt),
      label: const Text('Check for update'),
    );
  }

  Future<void> _checkForUpdate() async {
    setState(() {
      _checking = true;
    });
    try {
      final rawConfig = await rootBundle.loadString('.flutter_falcon.json');
      final config = FlutterFalconUpdateConfig.fromJson(
        jsonDecode(rawConfig) as Map<String, dynamic>,
        baseVersion: widget.installedVersion,
      );
      final result = await FlutterFalconUpdateClient(config: config).check();
      if (!mounted) {
        return;
      }
      setState(() {
        _checking = false;
      });
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Falcon update'),
          content: Text(_messageFor(result)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _checking = false;
      });
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Falcon update'),
          content: Text('Could not load .flutter_falcon.json.\n\n$error'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  String _messageFor(FlutterFalconUpdateCheckResult result) {
    if (!result.configured) {
      return result.message ?? 'Falcon update settings are not configured.';
    }
    if (result.updateAvailable && result.targetVersion != null) {
      return 'Installed: ${result.currentVersion}\n'
          'Falcon: ${result.targetVersion}\n\n'
          'Apply the published Falcon update through the updater flow.';
    }
    return result.message ??
        'Installed: ${result.currentVersion}\nFalcon: current';
  }
}
