import 'package:flutter/material.dart';
import 'package:flutter_falcon/cloud_flutter_falcon_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

const String kFalconServerUrl = String.fromEnvironment(
  'FLUTTER_FALCON_SERVER_URL',
  defaultValue: 'https://flutterfalcon.com',
);
const String kFalconReadToken = String.fromEnvironment(
  'FLUTTER_FALCON_READ_TOKEN',
);
const String kFalconAppId = String.fromEnvironment(
  'FLUTTER_FALCON_APP_ID',
  defaultValue: 'com.example.red_rect_app',
);
const String kFalconPlatform = String.fromEnvironment(
  'FLUTTER_FALCON_PLATFORM',
  defaultValue: 'windows-x64',
);
const String kFalconChannel = String.fromEnvironment(
  'FLUTTER_FALCON_CHANNEL',
  defaultValue: 'stable',
);

void main() {
  runApp(const RedRectApp());
}

class RedRectApp extends StatelessWidget {
  const RedRectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        scaffoldBackgroundColor: const Color(0xFFF6F1EE),
      ),
      home: const _FalconFixturePage(),
    );
  }
}

class _FalconFixturePage extends StatefulWidget {
  const _FalconFixturePage();

  @override
  State<_FalconFixturePage> createState() => _FalconFixturePageState();
}

class _FalconFixturePageState extends State<_FalconFixturePage> {
  String? _version;

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
        _version =
            packageInfo.buildNumber.isEmpty
                ? packageInfo.version
                : '${packageInfo.version}+${packageInfo.buildNumber}';
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
    final version = _version;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 280,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFD63A2F),
                borderRadius: BorderRadius.circular(24),
              ),
              alignment: Alignment.center,
              child: Text(
                version == null ? 'Loading...' : 'Version $version',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (version == null)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(),
              )
            else
              CloudFlutterFalconUpdateButton(
                config: CloudFlutterFalconUpdateConfig(
                  serverUrl: kFalconServerUrl,
                  readToken: kFalconReadToken,
                  appId: kFalconAppId,
                  platform: kFalconPlatform,
                  channel: kFalconChannel,
                  baseVersion: version,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
