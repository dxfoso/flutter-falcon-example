import 'package:flutter/material.dart';

void main() {
  runApp(const RedRectApp());
}

class RedRectApp extends StatelessWidget {
  const RedRectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 200,
            height: 120,
            child: ColoredBox(color: Colors.red),
          ),
        ),
      ),
    );
  }
}
