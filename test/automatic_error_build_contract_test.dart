import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('both packaged example artifacts execute the SDK entrypoint', () {
    final script = File('.cloud-ci/tasks/flutter-falcon-example.sh').readAsStringSync();
    final commands = script.split('\n').where((line) =>
        line.trimLeft().startsWith('flutter build ')).toList();
    expect(commands, hasLength(2));
    for (final command in commands) {
      expect(command, contains('--target=.dart_tool/flutter_falcon_app.dart'));
    }
  });
}
