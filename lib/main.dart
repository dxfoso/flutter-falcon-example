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
        visualDensity: VisualDensity.compact,
        scaffoldBackgroundColor: colorScheme.surface,
        appBarTheme: AppBarTheme(
          toolbarHeight: 52,
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
