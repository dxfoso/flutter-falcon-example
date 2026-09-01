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
  });
}
