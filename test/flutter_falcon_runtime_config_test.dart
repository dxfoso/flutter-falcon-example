import 'package:red_rect_app/falcon_versioning.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('version builder appends build number when needed', () {
    expect(falconPackageVersion('1.0.1', '3'), '1.0.1+3');
    expect(falconPackageVersion('1.0.1+2', '3'), '1.0.1+2');
    expect(falconPackageVersion('', '3'), '');
    expect(falconPackageVersion('1.0.1', ''), '1.0.1');
  });
}
