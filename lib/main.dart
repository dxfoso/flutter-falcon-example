import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:9010',
);

const String kServerBaseUrl = String.fromEnvironment(
  'SERVER_BASE_URL',
  defaultValue: 'http://localhost:9010',
);

const String kBuildCommitDate = String.fromEnvironment(
  'BUILD_COMMIT_DATE',
  defaultValue: 'not available',
);

const String kBuildReleaseDate = String.fromEnvironment(
  'BUILD_RELEASE_DATE',
  defaultValue: 'not available',
);

void main() {
  runApp(const RedRectApp());
}

class RedRectApp extends StatelessWidget {
  const RedRectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _RedRectScreen(),
    );
  }
}

class _RedRectScreen extends StatefulWidget {
  const _RedRectScreen();

  @override
  State<_RedRectScreen> createState() => _RedRectScreenState();
}

class _RedRectScreenState extends State<_RedRectScreen> {
  String _version = 'loading';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        final build =
            packageInfo.buildNumber.isEmpty
                ? packageInfo.version
                : '${packageInfo.version}+${packageInfo.buildNumber}';
        _version = build;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _version = 'unknown';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const Center(
              child: SizedBox(
                width: 200,
                height: 120,
                child: ColoredBox(color: Colors.red),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.3,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Version: $_version'),
                      Text('Build commit date: $kBuildCommitDate'),
                      Text('Release date: $kBuildReleaseDate'),
                      Text('API_BASE_URL: $kApiBaseUrl'),
                      Text('SERVER_BASE_URL: $kServerBaseUrl'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
