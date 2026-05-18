import 'package:flutter/material.dart';

class CloudFlutterFalconUpdateButton extends StatelessWidget {
  const CloudFlutterFalconUpdateButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () {
        final messenger = ScaffoldMessenger.maybeOf(context);
        if (messenger == null) return;
        messenger.showSnackBar(
          const SnackBar(
            content: Text('FlutterFalcon update check placeholder'),
          ),
        );
      },
      child: const Text('Check for updates'),
    );
  }
}
