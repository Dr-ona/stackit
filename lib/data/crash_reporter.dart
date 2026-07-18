abstract interface class CrashReporter {
  Future<void> recordNonFatal(
    Object error,
    StackTrace stackTrace, {
    required String operation,
  });
}
