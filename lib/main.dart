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

final Future<String> _versionFuture = _loadVersion();

void main() => runApp(const RedRectApp());

Future<String> _loadVersion() async {
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    if (packageInfo.buildNumber.isEmpty) {
      return packageInfo.version;
    }
    return '${packageInfo.version}+${packageInfo.buildNumber}';
  } catch (_) {
    return 'unknown';
  }
}

class RedRectApp extends StatelessWidget {
  const RedRectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FalconFixturePage(),
    );
  }
}

class FalconFixturePage extends StatelessWidget {
  const FalconFixturePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _versionFuture,
      builder: (context, snapshot) {
        final version = snapshot.data;
        return Scaffold(
          backgroundColor: const Color(0xFFF6F1EE),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 280,
                  height: 180,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD63A2F),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    version ?? 'Loading...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (version == null)
                  const CircularProgressIndicator()
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
      },
    );
  }
}
