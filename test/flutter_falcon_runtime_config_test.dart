import 'package:flutter_falcon/flutter_falcon_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('version builder appends build number when needed', () {
    expect(flutterFalconPackageVersion('1.0.1', '3'), '1.0.1+3');
    expect(flutterFalconPackageVersion('1.0.1+2', '3'), '1.0.1+2');
    expect(flutterFalconPackageVersion('', '3'), '');
    expect(flutterFalconPackageVersion('1.0.1', ''), '1.0.1');
  });

  test('effective base version prefers the active patch version', () {
    expect(flutterFalconEffectiveBaseVersion('1.1.6+4', '1.1.6+5'), '1.1.6+5');
    expect(flutterFalconEffectiveBaseVersion('1.1.6+4', '  '), '1.1.6+4');
    expect(flutterFalconEffectiveBaseVersion('1.1.6+4', null), '1.1.6+4');
  });
}
