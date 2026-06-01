import 'package:red_rect_app/falcon_versioning.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('version builder appends build number when needed', () {
    expect(falconPackageVersion('1.0.1', '3'), '1.0.1+3');
    expect(falconPackageVersion('1.0.1+2', '3'), '1.0.1+2');
    expect(falconPackageVersion('', '3'), '');
    expect(falconPackageVersion('1.0.1', ''), '1.0.1');
  });

  test('effective base version prefers the active patch version', () {
    expect(falconEffectiveBaseVersion('1.1.6+4', '1.1.6+5'), '1.1.6+5');
    expect(falconEffectiveBaseVersion('1.1.6+4', '  '), '1.1.6+4');
    expect(falconEffectiveBaseVersion('1.1.6+4', null), '1.1.6+4');
  });
}
