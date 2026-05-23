import 'package:flutter/material.dart';
import 'package:flutter_falcon/flutter_falcon_api.dart';
import 'package:flutter/services.dart';

final Future<FlutterFalconUpdateClient> _clientFuture = _loadClient();

void main() => runApp(const RedRectApp());

Future<FlutterFalconUpdateClient> _loadClient() async {
  final rawConfig = await rootBundle.loadString('.flutter_falcon.json');
  return FlutterFalconUpdateClient.fromJsonString(rawConfig);
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
    return FutureBuilder<FlutterFalconUpdateClient>(
      future: _clientFuture,
      builder: (context, snapshot) {
        final client = snapshot.data;
        final version = client?.config.baseVersion;
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
                    color: Colors.blue,
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
                if (client == null)
                  const CircularProgressIndicator()
                else
                  FalconCheckButton(client: client),
              ],
            ),
          ),
        );
      },
    );
  }
}

class FalconCheckButton extends StatefulWidget {
  const FalconCheckButton({super.key, required this.client});

  final FlutterFalconUpdateClient client;

  @override
  State<FalconCheckButton> createState() => _FalconCheckButtonState();
}

class _FalconCheckButtonState extends State<FalconCheckButton> {
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
      label: const Text('Check for update zzz'),
    );
  }

  Future<void> _checkForUpdate() async {
    setState(() {
      _checking = true;
    });
    try {
      final result = await widget.client.check();
      if (!mounted) {
        return;
      }
      setState(() {
        _checking = false;
      });
      await showDialog<void>(
        context: context,
        builder:
            (context) => AlertDialog(
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
        builder:
            (context) => AlertDialog(
              title: const Text('Falcon update'),
              content: Text('Could not check for a Falcon update.\n\n$error'),
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
      return 'Falcon update settings are not configured for this build.';
    }
    switch (result.status) {
      case FlutterFalconUpdateStatus.available:
        return 'Installed: ${result.currentVersion}\n'
            'Falcon: ${result.targetVersion ?? 'available'}\n\n'
            'Apply the published Falcon update through the updater flow.';
      case FlutterFalconUpdateStatus.current:
        return 'Installed: ${result.currentVersion}\n'
            'Falcon: no published update matched this version yet.';
      case FlutterFalconUpdateStatus.failed:
        final parts = <String>['Falcon check failed.'];
        if (result.failureStatusCode != null) {
          parts.add('HTTP ${result.failureStatusCode}');
        }
        if (result.failureResponseBody != null &&
            result.failureResponseBody!.trim().isNotEmpty) {
          parts.add(result.failureResponseBody!.trim());
        } else if (result.failureMessage != null &&
            result.failureMessage!.trim().isNotEmpty) {
          parts.add(result.failureMessage!.trim());
        }
        return parts.join('\n\n');
      case FlutterFalconUpdateStatus.notConfigured:
        return 'Falcon update settings are not configured for this build.';
      case FlutterFalconUpdateStatus.downloaded:
      case FlutterFalconUpdateStatus.active:
        return 'Installed: ${result.currentVersion}';
    }
  }
}
