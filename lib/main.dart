import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_falcon/cloud_flutter_falcon_update.dart';

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
      home: _DiagnosticsPage(),
    );
  }
}

class _DiagnosticsPage extends StatefulWidget {
  const _DiagnosticsPage();

  @override
  State<_DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends State<_DiagnosticsPage> {
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
      appBar: AppBar(
        title: const Text('Diagnostics'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            const Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.all(Radius.circular(18)),
                ),
                child: SizedBox(
                  width: 240,
                  height: 140,
                  child: Center(
                    child: Text(
                      'Updated build',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
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
                      const Text(
                        'Falcon diagnostics',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const CloudFlutterFalconUpdateButton(),
                      const SizedBox(height: 8),
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
