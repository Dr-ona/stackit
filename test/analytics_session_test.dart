import 'package:flutter_test/flutter_test.dart';
import 'package:stackit/data/analytics_service.dart';

class _SpyAnalyticsService implements AnalyticsService {
  final List<(String, Map<String, Object?>?)> events = [];

  @override
  void setConsent(bool enabled) {}

  @override
  void logEvent(String name, {Map<String, Object?>? parameters}) {
    events.add((name, parameters));
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

void main() {
  group('logReviewSessionCompleted', () {
    test('logs event with correct parameters', () {
      final service = _SpyAnalyticsService();
      service.logReviewSessionCompleted(
        cardsReviewed: 10,
        correctCount: 8,
        duration: const Duration(minutes: 3, seconds: 30),
      );
      expect(service.events.length, 1);
      final (name, params) = service.events.first;
      expect(name, 'review_session_completed');
      expect(params!['cards_reviewed'], 10);
      expect(params['correct_count'], 8);
      expect(params['accuracy'], 0.8);
      expect(params['duration_ms'], 210000);
    });

    test('accuracy is 0 when no cards reviewed', () {
      final service = _SpyAnalyticsService();
      service.logReviewSessionCompleted(
        cardsReviewed: 0,
        correctCount: 0,
        duration: Duration.zero,
      );
      final (_, params) = service.events.first;
      expect(params!['accuracy'], 0.0);
      expect(params['cards_reviewed'], 0);
    });

    test('accuracy is 1.0 when all correct', () {
      final service = _SpyAnalyticsService();
      service.logReviewSessionCompleted(
        cardsReviewed: 5,
        correctCount: 5,
        duration: const Duration(seconds: 45),
      );
      final (_, params) = service.events.first;
      expect(params!['accuracy'], 1.0);
    });
  });

  group('logSessionOpened', () {
    test('logs event without duration on fresh install', () {
      final service = _SpyAnalyticsService();
      service.logSessionOpened();
      expect(service.events.length, 1);
      final (name, params) = service.events.first;
      expect(name, 'session_opened');
      expect(params, isEmpty);
    });

    test('logs event with sinceLastSession', () {
      final service = _SpyAnalyticsService();
      service.logSessionOpened(sinceLastSession: const Duration(hours: 25));
      final (_, params) = service.events.first;
      expect(params!['since_last_ms'], 90000000);
    });

    test('zero sinceLastSession logs zero', () {
      final service = _SpyAnalyticsService();
      service.logSessionOpened(sinceLastSession: Duration.zero);
      final (_, params) = service.events.first;
      expect(params!['since_last_ms'], 0);
    });

    test('7-day return logs correct milliseconds', () {
      final service = _SpyAnalyticsService();
      service.logSessionOpened(sinceLastSession: const Duration(days: 7));
      final (_, params) = service.events.first;
      expect(params!['since_last_ms'], 604800000);
    });
  });
}
