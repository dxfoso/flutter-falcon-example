String falconPackageVersion(String version, String buildNumber) {
  final cleanVersion = version.trim();
  final cleanBuildNumber = buildNumber.trim();
  if (cleanVersion.isEmpty) {
    return '';
  }
  if (cleanVersion.contains('+') || cleanBuildNumber.isEmpty) {
    return cleanVersion;
  }
  return '$cleanVersion+$cleanBuildNumber';
}

String falconEffectiveBaseVersion(
  String packageVersion,
  String? activePatchVersion,
) {
  final cleanActivePatchVersion = activePatchVersion?.trim() ?? '';
  if (cleanActivePatchVersion.isNotEmpty) {
    return cleanActivePatchVersion;
  }
  return packageVersion.trim();
}
