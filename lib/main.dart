import 'package:flutter/material.dart';
import 'package:flutter_falcon/flutter_falcon_api.dart';

const _controller = FlutterFalconExampleController();

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
  late Future<FlutterFalconExampleVersionInfo> _infoFuture;
  bool _actionRunning = false;
  String? _actionMessage;
  String? _actionError;

  @override
  void initState() {
    super.initState();
    _infoFuture = _controller.load();
  }

  Future<void> _refresh() async {
    setState(() {
      _actionMessage = null;
      _actionError = null;
      _infoFuture = _controller.load();
    });
  }

  Future<void> _applyOrConfirm(FlutterFalconExampleVersionInfo info) async {
    setState(() {
      _actionRunning = true;
      _actionMessage = null;
      _actionError = null;
    });
    try {
      final result = await _controller.runPrimaryAction(info);
      setState(() {
        if (result.changed || info.requiresBootConfirmation) {
          _actionMessage = result.message;
        } else {
          _actionError = result.message;
        }
      });
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
      backgroundColor: const Color.fromARGB(255, 90, 59, 11),
      appBar: AppBar(
        title: const Text('Flutter Falcon Version'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<FlutterFalconExampleVersionInfo>(
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
                  const SizedBox(height: 12),
                  const Text('Current Falcon runtime'),
                  Text(
                    data.currentRuntimeVersion,
                    style: const TextStyle(fontWeight: FontWeight.w700),
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
                      color: _statusColor(data.checkStatus),
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
                    'channel: ${_controller.channel}',
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

Color _statusColor(String status) {
  if (status == FlutterFalconUpdateStatus.available.name) {
    return Colors.orange.shade700;
  }
  if (status == FlutterFalconUpdateStatus.failed.name ||
      status == FlutterFalconUpdateStatus.notConfigured.name) {
    return Colors.red.shade700;
  }
  return Colors.green.shade700;
}
