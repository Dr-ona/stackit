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

  void logMeaningReported();

  void logReviewSessionCompleted({
    required int cardsReviewed,
    required int correctCount,
    required Duration duration,
  });

  void logSessionOpened({Duration? sinceLastSession});
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
  void logEvent(String name, {Map<String, Object?>? parameters}) {
    if (!_consent) return;
    _analytics.logEvent(
      name: name,
      parameters: parameters?.map((k, v) => MapEntry(k, v ?? '')),
    );
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

  @override
  void logMeaningReported() => logEvent('meaning_reported');

  @override
  void logReviewSessionCompleted({
    required int cardsReviewed,
    required int correctCount,
    required Duration duration,
  }) {
    logEvent(
      'review_session_completed',
      parameters: {
        'cards_reviewed': cardsReviewed,
        'correct_count': correctCount,
        'accuracy': cardsReviewed > 0 ? correctCount / cardsReviewed : 0.0,
        'duration_ms': duration.inMilliseconds,
      },
    );
  }

  @override
  void logSessionOpened({Duration? sinceLastSession}) {
    logEvent(
      'session_opened',
      parameters: {
        if (sinceLastSession != null)
          'since_last_ms': sinceLastSession.inMilliseconds,
      },
    );
  }
}
