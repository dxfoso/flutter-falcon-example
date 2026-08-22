import 'package:flutter/material.dart';
import 'package:flutter_falcon/flutter_falcon.dart';

void main() => runApp(const FlutterFalconPlayExample());

class FlutterFalconPlayExample extends StatelessWidget {
  const FlutterFalconPlayExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterFalcon Play Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3159C6)),
        useMaterial3: true,
      ),
      home: FlutterFalconAboutPage.standard(
        serverUrl: 'https://flutterfalcon.com',
        debugAppId: 'flutter_falcon_example_play',
        debugProfile: FlutterFalconDistributionProfile.androidPlay,
        debugStoreListingId: 'com.example.flutter_falcon_example_play',
        applicationServerUrl: 'https://flutterfalcon.com',
      ),
    );
  }
}
