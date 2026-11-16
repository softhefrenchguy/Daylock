import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/daylock_state.dart';

/// Why a backup file could not be restored.
enum BackupProblem { notDaylock, newerVersion, damaged }

class BackupException implements Exception {
  final BackupProblem problem;
  const BackupException(this.problem);
}

/// Daylock backup files: plans, history, Areas, routines, achievements and
/// settings in one JSON file. Calendar sign-ins are never included.
abstract final class DaylockBackup {
  static const app = 'daylock';
  static const format = 1;

  static String encode(DaylockState state, DateTime exportedAt) =>
      const JsonEncoder.withIndent(' ').convert({
        'app': app,
        'format': format,
        'exportedAt': exportedAt.toUtc().toIso8601String(),
        'state': state.toJson(),
      });

  /// The saved state in [text]; throws [BackupException] when it isn't a
  /// usable Daylock backup.
  static DaylockState decode(String text) {
    final Object? json;
    try {
      json = jsonDecode(text);
    } catch (_) {
      throw const BackupException(BackupProblem.notDaylock);
    }
    if (json is! Map || json['app'] != app || json['state'] is! Map) {
      throw const BackupException(BackupProblem.notDaylock);
    }
    final version = json['format'];
    if (version is! int) throw const BackupException(BackupProblem.damaged);
    if (version > format) {
      throw const BackupException(BackupProblem.newerVersion);
    }
    try {
      return DaylockState.fromJson(
        Map<String, dynamic>.from(json['state'] as Map),
      );
    } catch (_) {
      throw const BackupException(BackupProblem.damaged);
    }
  }

  /// "daylock-backup-2026-11-16.json"
  static String fileName(DateTime now) =>
      'daylock-backup-${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}.json';
}

/// Opens Android's Save and Open file screens for backups.
class BackupFiles {
  final MethodChannel _channel;
  BackupFiles({@visibleForTesting MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('daylock/backup');

  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// True when saved, false when cancelled.
  Future<bool> save(String name, String content) async =>
      await _channel.invokeMethod<bool>('save', {
        'name': name,
        'content': content,
      }) ??
      false;

  /// The chosen file's text, or null when cancelled.
  Future<String?> open() => _channel.invokeMethod<String>('open');
}
