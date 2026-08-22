import 'package:flutter_falcon_example/runtime_configuration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('debug runs default to the local API server', () {
    final configuration = ExampleRuntimeConfiguration.fromEnvironment(
      apiBaseUrl: '',
      releaseMode: false,
    );

    expect(configuration.apiBaseUrl, localApiBaseUrl);
    expect(configuration.serverLabel, 'Local server');
  });

  test('FlutterFalcon build variables select the live API server', () {
    final configuration = ExampleRuntimeConfiguration.fromEnvironment(
      apiBaseUrl: 'https://flutterfalcon.com',
      releaseMode: true,
    );

    expect(configuration.apiBaseUrl, 'https://flutterfalcon.com');
    expect(configuration.serverLabel, 'Live server');
  });

  test('release builds fail when API_BASE_URL is missing', () {
    expect(
      () => ExampleRuntimeConfiguration.fromEnvironment(
        apiBaseUrl: '',
        releaseMode: true,
      ),
      throwsA(isA<StateError>()),
    );
  });
}
