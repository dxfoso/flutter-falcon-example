import 'package:flutter_test/flutter_test.dart';

void main() {
  test('version builder appends build number when needed', () {
    expect(_falconBaseVersionForTest('1.0.1', '3'), '1.0.1+3');
    expect(_falconBaseVersionForTest('1.0.1+2', '3'), '1.0.1+2');
    expect(_falconBaseVersionForTest('', '3'), '');
    expect(_falconBaseVersionForTest('1.0.1', ''), '1.0.1');
  });
}

String _falconBaseVersionForTest(String version, String buildNumber) {
  final cleanVersion = version.trim();
  final cleanBuild = buildNumber.trim();
  if (cleanVersion.isEmpty) {
    return '';
  }
  if (cleanBuild.isEmpty) {
    return cleanVersion;
  }
  if (cleanVersion.contains('+')) {
    return cleanVersion;
  }
  return '$cleanVersion+$cleanBuild';
}
