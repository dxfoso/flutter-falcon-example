import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'check_for_updates_page.dart';
import 'flutter_falcon_updates.dart';
import 'runtime_configuration.dart';

const _captureRuntimeLogsPreference = 'capture_runtime_logs';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final runtimeConfiguration = ExampleRuntimeConfiguration.fromEnvironment();
  runApp(
    FlutterFalconExampleApp(
      runtimeConfiguration: runtimeConfiguration,
      captureRuntimeLogs:
          preferences.getBool(_captureRuntimeLogsPreference) ?? false,
    ),
  );
}

class FlutterFalconExampleApp extends StatefulWidget {
  const FlutterFalconExampleApp({
    super.key,
    required this.runtimeConfiguration,
    this.updateController,
    this.captureRuntimeLogs = false,
    this.initialRoute = CheckForUpdatesPage.routeName,
  });

  final FlutterFalconExampleUpdateClient? updateController;
  final ExampleRuntimeConfiguration runtimeConfiguration;
  final bool captureRuntimeLogs;
  final String initialRoute;

  @override
  State<FlutterFalconExampleApp> createState() =>
      _FlutterFalconExampleAppState();
}

class _FlutterFalconExampleAppState extends State<FlutterFalconExampleApp> {
  late bool _captureRuntimeLogs = widget.captureRuntimeLogs;
  late FlutterFalconExampleUpdateClient _updateController =
      widget.updateController ??
      createFalconController(captureRuntimeLogs: _captureRuntimeLogs);

  bool get _ownsController => widget.updateController == null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_updateController.confirmPendingBoot());
    });
  }

  Future<void> _setCaptureRuntimeLogs(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_captureRuntimeLogsPreference, enabled);
    if (!mounted) return;
    if (_ownsController) {
      await _updateController.dispose();
      _updateController = createFalconController(captureRuntimeLogs: enabled);
    }
    if (mounted) setState(() => _captureRuntimeLogs = enabled);
  }

  @override
  void dispose() {
    if (_ownsController) {
      unawaited(_updateController.dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF3159C6);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'Flutter Falcon Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: colorScheme.surface,
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      initialRoute: widget.initialRoute,
      routes: {
        '/':
            (context) => _HomePage(
              captureRuntimeLogs: _captureRuntimeLogs,
              onCaptureRuntimeLogsChanged: _setCaptureRuntimeLogs,
            ),
        CheckForUpdatesPage.routeName:
            (context) => CheckForUpdatesPage(
              key: ValueKey((_captureRuntimeLogs, _updateController)),
              controller: _updateController,
              apiBaseUrl: widget.runtimeConfiguration.apiBaseUrl,
              captureRuntimeLogs: _captureRuntimeLogs,
              onCaptureRuntimeLogsChanged: _setCaptureRuntimeLogs,
            ),
      },
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage({
    required this.captureRuntimeLogs,
    required this.onCaptureRuntimeLogsChanged,
  });

  final bool captureRuntimeLogs;
  final ValueChanged<bool> onCaptureRuntimeLogsChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Falcon Example')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.rocket_launch_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Flutter Falcon runtime updates.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Inspect this installed build and manage updates from the '
                  'stable hosted stream.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed:
                      () => Navigator.pushNamed(
                        context,
                        CheckForUpdatesPage.routeName,
                      ),
                  icon: const Icon(Icons.system_update_alt),
                  label: const Text('Check for updates'),
                ),
                const SizedBox(height: 16),
                SwitchListTile.adaptive(
                  value: captureRuntimeLogs,
                  onChanged: onCaptureRuntimeLogsChanged,
                  title: const Text('Send diagnostic logs'),
                  subtitle: const Text(
                    'Optional redacted logs help diagnose app failures.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
