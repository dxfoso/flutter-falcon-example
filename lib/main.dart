import 'package:flutter/material.dart';
import 'package:flutter_falcon/flutter_falcon.dart';

import 'runtime_configuration.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    FlutterFalconExampleApp(
      runtimeConfiguration: ExampleRuntimeConfiguration.fromEnvironment(),
    ),
  );
}

class FlutterFalconExampleApp extends StatelessWidget {
  const FlutterFalconExampleApp({
    super.key,
    required this.runtimeConfiguration,
  });

  final ExampleRuntimeConfiguration runtimeConfiguration;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Falcon Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3159C6)),
        useMaterial3: true,
        visualDensity: VisualDensity.compact,
      ),
      home: FlutterFalconAboutPage.standard(
        serverUrl: 'https://flutterfalcon.com',
        debugAppId: 'flutter_falcon_example',
        debugStoreListingId: '0000000000',
        applicationServerUrl: runtimeConfiguration.apiBaseUrl,
      ),
    );
  }
}
