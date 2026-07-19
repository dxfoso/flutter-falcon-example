import 'package:flutter/material.dart';
import 'package:flutter_falcon/flutter_falcon_api.dart';

import 'check_for_updates_page.dart';
import 'flutter_falcon_updates.dart';

void main() => runApp(const FlutterFalconExampleApp());

class FlutterFalconExampleApp extends StatelessWidget {
  const FlutterFalconExampleApp({
    super.key,
    this.updateController = falconController,
    this.initialRoute = CheckForUpdatesPage.routeName,
  });

  final FlutterFalconControllerApi updateController;
  final String initialRoute;

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
      initialRoute: initialRoute,
      routes: {
        '/': (context) => const _HomePage(),
        CheckForUpdatesPage.routeName:
            (context) => CheckForUpdatesPage(controller: updateController),
      },
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage();

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
                  'Flutter Falcon runtime updates',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
