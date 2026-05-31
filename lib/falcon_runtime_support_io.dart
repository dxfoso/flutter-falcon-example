import 'dart:io';

import 'package:flutter_falcon/flutter_falcon_api.dart';

typedef FalconApplyResult = ({bool changed, String message});

const _channel = 'stable';
const _buildUnknownVersion = 'Unknown';

Future<FlutterFalconAppUpdateSnapshot?> falconStatusSnapshot({
  required FlutterFalconUpdateClient client,
  FlutterFalconUpdateCheckResult? checkResult,
}) async {
  final installDir = _falconInstallDir();
  final snapshot = await client.statusSnapshot(
    installDir: installDir,
    checkResult: checkResult,
  );
  if (snapshot?.requiresBootConfirmation ?? false) {
    await client.markBootSuccessful(installDir: installDir);
    return client.statusSnapshot(
      installDir: installDir,
      checkResult: checkResult,
    );
  }
  return snapshot;
}

Future<FalconApplyResult> falconApplyUpdate({
  required FlutterFalconUpdateClient client,
  required String installedVersion,
}) async {
  final installDir = _falconInstallDir();
  final runtimeRoot = _falconRuntimeRoot(installDir);
  await runtimeRoot.create(recursive: true);

  final baseManifest = await buildReleaseManifest(
    releaseDir: installDir,
    platform: client.config.resolvedPlatform,
    appId: client.config.effectiveAppId,
    version:
        installedVersion.trim().isEmpty
            ? _buildUnknownVersion
            : installedVersion.trim(),
    channel: _channel,
    buildMode: 'release',
    flutterVersion: 'unknown',
    dartVersion: 'unknown',
    engineHash: 'unknown',
  );

  final activation = await client.checkDownloadActivate(
    baseManifest: baseManifest,
    cacheDir: Directory(
      '${runtimeRoot.path}${Platform.pathSeparator}cache',
    ),
    installDir: installDir,
    stagingDir: Directory(
      '${runtimeRoot.path}${Platform.pathSeparator}staging',
    ),
    backupDir: Directory(
      '${runtimeRoot.path}${Platform.pathSeparator}backup',
    ),
  );
  if (activation == null) {
    return (
      changed: false,
      message: 'No installable Falcon update is published for this build.',
    );
  }
  final snapshot = await client.statusSnapshot(
    installDir: installDir,
    activationResult: activation,
  );
  final targetVersion = activation.update.targetVersion;
  final message =
      snapshot.requiresBootConfirmation
          ? 'Downloaded and activated Falcon update $targetVersion. Restarting into the updated build now.'
          : 'Activated Falcon update $targetVersion.';
  if (snapshot.requiresBootConfirmation) {
    await _restartCurrentExecutable();
    exit(0);
  }
  return (changed: true, message: message);
}

Future<FlutterFalconRuntimeBootResult> falconConfirmBoot({
  required FlutterFalconUpdateClient client,
}) {
  return client.markBootSuccessful(installDir: _falconInstallDir());
}

Directory _falconInstallDir() {
  return File(Platform.resolvedExecutable).parent.absolute;
}

Directory _falconRuntimeRoot(Directory installDir) {
  return Directory(
    '${installDir.path}${Platform.pathSeparator}.flutter_falcon_runtime',
  );
}

Future<void> _restartCurrentExecutable() async {
  final executable = Platform.resolvedExecutable;
  final arguments = Platform.executableArguments;
  if (Platform.isWindows) {
    final script = '''
Start-Sleep -Milliseconds 700
Start-Process -FilePath '${_powershellQuoted(executable)}'${arguments.isEmpty ? '' : ' -ArgumentList @(${arguments.map(_powershellSingleQuoted).join(', ')})'}
''';
    await Process.start(
      'powershell',
      [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-WindowStyle',
        'Hidden',
        '-Command',
        script,
      ],
      mode: ProcessStartMode.detached,
    );
    return;
  }
  await Process.start(
    executable,
    arguments,
    mode: ProcessStartMode.detached,
  );
}

String _powershellQuoted(String value) {
  return value.replaceAll("'", "''");
}

String _powershellSingleQuoted(String value) {
  return "'${_powershellQuoted(value)}'";
}
