import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('physical runtime probe is inert unless explicitly configured', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(source, contains("String.fromEnvironment('FF_E2E_RUNTIME_MARKER')"));
    expect(
      source,
      contains('--flutter-falcon-e2e-hold-before-first-frame'),
    );
    expect(source, contains('phase=hold-before-first-frame'));
    expect(source, contains('_e2eRuntimeMarker.isNotEmpty'));
    expect(source, contains('current=\${info.currentPatchNumber}'));
    expect(source, contains('next=\${info.nextPatchNumber}'));
    expect(source, isNot(contains("import 'dart:io'")));

    final conditionalImport =
        File('lib/runtime_probe_arguments.dart').readAsStringSync();
    expect(conditionalImport, contains('if (dart.library.io)'));
    expect(
      File('lib/runtime_probe_arguments_io.dart').readAsStringSync(),
      contains('Platform.executableArguments.contains(argument)'),
    );
  });
}
