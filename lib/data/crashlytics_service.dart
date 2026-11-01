import 'dart:async';
import 'dart:ui' as ui;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'crash_reporter.dart';

class CrashlyticsService implements CrashReporter {
  CrashlyticsService({FirebaseCrashlytics? crashlytics})
    : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  static const _enableInDebug = bool.fromEnvironment(
    'ENABLE_CRASHLYTICS_IN_DEBUG',
  );

  final FirebaseCrashlytics _crashlytics;

  bool get _isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  Future<void> initialize() async {
    if (!_isSupported) return;

    try {
      await _crashlytics.setCrashlyticsCollectionEnabled(
        !kDebugMode || _enableInDebug,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Stackit Crashlytics initialization failed: $error\n$stackTrace',
      );
      return;
    }
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      unawaited(_recordFlutterFatalError(details));
    };
    ui.PlatformDispatcher.instance.onError = (error, stackTrace) {
      unawaited(_recordFatalError(error, stackTrace));
      return true;
    };
  }

  @override
  Future<void> recordNonFatal(
    Object error,
    StackTrace stackTrace, {
    required String operation,
  }) async {
    if (!_isSupported) return;

    try {
      await _crashlytics.recordError(
        error,
        stackTrace,
        reason: 'Cloud operation failed',
        information: <Object>['operation=$operation'],
        fatal: false,
      );
    } catch (reportingError, reportingStackTrace) {
      debugPrint(
        'Stackit Crashlytics non-fatal reporting failed: '
        '$reportingError\n$reportingStackTrace',
      );
    }
  }

  Future<void> _recordFlutterFatalError(FlutterErrorDetails details) async {
    try {
      await _crashlytics.recordFlutterFatalError(details);
    } catch (error, stackTrace) {
      debugPrint(
        'Stackit Crashlytics Flutter reporting failed: $error\n$stackTrace',
      );
    }
  }

  Future<void> _recordFatalError(Object error, StackTrace stackTrace) async {
    try {
      await _crashlytics.recordError(error, stackTrace, fatal: true);
    } catch (reportingError, reportingStackTrace) {
      debugPrint(
        'Stackit Crashlytics async reporting failed: '
        '$reportingError\n$reportingStackTrace',
      );
    }
  }
}
