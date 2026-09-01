import 'dart:io';

bool hasRuntimeProbeArgument(String argument) =>
    Platform.executableArguments.contains(argument);
