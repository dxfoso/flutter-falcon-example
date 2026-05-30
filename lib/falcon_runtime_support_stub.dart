import 'package:flutter_falcon/flutter_falcon_api.dart';

typedef FalconApplyResult = ({bool changed, String message});

Future<FlutterFalconAppUpdateSnapshot?> falconStatusSnapshot({
  required FlutterFalconUpdateClient client,
  FlutterFalconUpdateCheckResult? checkResult,
}) async {
  return null;
}

Future<FalconApplyResult> falconApplyUpdate({
  required FlutterFalconUpdateClient client,
  required String installedVersion,
}) async {
  return (
    changed: false,
    message: 'Runtime patch activation is only supported on native app builds.',
  );
}

Future<FlutterFalconRuntimeBootResult> falconConfirmBoot({
  required FlutterFalconUpdateClient client,
}) async {
  return const FlutterFalconRuntimeBootResult(
    changed: false,
    restoredPreviousGood: false,
    bootState: null,
    message: 'Runtime boot confirmation is only supported on native app builds.',
  );
}
