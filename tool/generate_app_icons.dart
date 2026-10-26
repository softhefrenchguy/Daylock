import 'dart:io';

/// Keep the existing AppIcon project wiring: flutter_launcher_icons 0.14.4
/// matches every ASSETCATALOG setting and can overwrite unrelated YES/NO values.
Future<void> main() async {
  final project = File('ios/Runner.xcodeproj/project.pbxproj');
  final original = project.readAsBytesSync();
  if (!project.readAsStringSync().contains(
    'ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;',
  )) {
    throw StateError(
      'Expected the existing iOS AppIcon catalog configuration.',
    );
  }
  try {
    final process = await Process.start(Platform.resolvedExecutable, [
      'run',
      'flutter_launcher_icons',
    ], mode: ProcessStartMode.inheritStdio);
    exitCode = await process.exitCode;
  } finally {
    project.writeAsBytesSync(original);
  }
}
