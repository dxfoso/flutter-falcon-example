import 'package:flutter/foundation.dart';

const localApiBaseUrl = 'http://localhost:8080';

class ExampleRuntimeConfiguration {
  const ExampleRuntimeConfiguration({
    required this.apiBaseUrl,
    required this.isLocal,
  });

  factory ExampleRuntimeConfiguration.fromEnvironment({
    String apiBaseUrl = const String.fromEnvironment('API_BASE_URL'),
    bool releaseMode = kReleaseMode,
  }) {
    final value = apiBaseUrl.trim();
    if (value.isEmpty && releaseMode) {
      throw StateError(
        'API_BASE_URL is required for release builds. Add it to the selected '
        'FlutterFalcon pubspec.yaml build variables.',
      );
    }

    final resolved = value.isEmpty ? localApiBaseUrl : value;
    final uri = Uri.tryParse(resolved);
    if (uri == null ||
        !uri.hasScheme ||
        !const {'http', 'https'}.contains(uri.scheme) ||
        uri.host.isEmpty) {
      throw StateError('API_BASE_URL must be an http:// or https:// URL.');
    }

    return ExampleRuntimeConfiguration(
      apiBaseUrl: resolved,
      isLocal: _isLocalHost(uri.host),
    );
  }

  final String apiBaseUrl;
  final bool isLocal;

  String get serverLabel => isLocal ? 'Local server' : 'Live server';
}

bool _isLocalHost(String host) {
  final normalized = host.toLowerCase();
  return normalized == 'localhost' ||
      normalized == '127.0.0.1' ||
      normalized == '::1' ||
      normalized == '10.0.2.2';
}
