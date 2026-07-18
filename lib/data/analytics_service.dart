import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

abstract interface class AnalyticsService {
  void setConsent(bool enabled);

  void logEvent(String name, {Map<String, Object?>? parameters});

  void logFirstCapture();

  void logFirstSave();

  void logFirstReview();

  void logMeaningExpanded();

  void logAiExplanationRequested();
}

class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService({FirebaseAnalytics? analytics})
    : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;
  bool _consent = false;

  @override
  void setConsent(bool enabled) {
    _consent = enabled;
    _analytics.setAnalyticsCollectionEnabled(enabled);
    debugPrint('Stackit analytics ${enabled ? "enabled" : "disabled"}');
  }

  @override
  void logEvent(String name, {Map<String, Object>? parameters}) {
    if (!_consent) return;
    _analytics.logEvent(name: name, parameters: parameters);
  }

  @override
  void logFirstCapture() => logEvent('first_capture');

  @override
  void logFirstSave() => logEvent('first_save');

  @override
  void logFirstReview() => logEvent('first_review');

  @override
  void logMeaningExpanded() => logEvent('meaning_expanded');

  @override
  void logAiExplanationRequested() => logEvent('ai_explanation_requested');
}
