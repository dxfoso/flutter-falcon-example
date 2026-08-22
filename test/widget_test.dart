import 'package:flutter/material.dart';
import 'package:flutter_falcon/flutter_falcon.dart';
import 'package:flutter_falcon_example/main.dart';
import 'package:flutter_falcon_example/runtime_configuration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('uses the package-owned About and update workflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      const FlutterFalconExampleApp(
        runtimeConfiguration: ExampleRuntimeConfiguration(
          apiBaseUrl: 'http://localhost:8080',
          isLocal: true,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(FlutterFalconAboutPage), findsOneWidget);
    expect(find.text('About & updates'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
  });
}
