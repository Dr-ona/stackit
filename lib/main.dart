import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/stackit_app.dart';
import 'data/analytics_service.dart';
import 'data/app_check_service.dart';
import 'data/auth_service.dart';
import 'data/contextual_explanation_service.dart';
import 'data/crashlytics_service.dart';
import 'data/dictionary_pre_cache_service.dart';
import 'data/example_enrichment_service.dart';
import 'data/gemini_dictionary_service.dart';
import 'data/meaning_discovery_service.dart';
import 'data/local_dictionary_cache.dart';
import 'data/offline_dictionary.dart';
import 'data/platform_bridge.dart';
import 'data/profile_avatar_store.dart';
import 'data/review_notification_service.dart';
import 'data/user_profile_cloud_store.dart';
import 'data/vocabulary_cloud_store.dart';
import 'features/vocabulary/vocabulary_controller.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final crashReporter = CrashlyticsService();
  await crashReporter.initialize();
  await const AppCheckService().activate();

  final authService = AuthService();
  await authService.initialize();
  final notificationService = ReviewNotificationService();
  await notificationService.initialize();
  final analyticsService = FirebaseAnalyticsService();

  final localCache = LocalDictionaryCache();
  final geminiDictionaryService = GeminiDictionaryService();
  final preCacheService = DictionaryPreCacheService(
    cache: localCache,
    gemini: geminiDictionaryService,
  );

  final controller = VocabularyController(
    OfflineDictionary(),
    PlatformBridge(),
    FirestoreVocabularyCloudStore(),
    FirebaseContextualExplanationService(),
    notificationService,
    FirestoreUserProfileCloudStore(),
    FirebaseMeaningDiscoveryService(),
    FirebaseProfileAvatarStore(),
    crashReporter,
    analyticsService,
    FirebaseExampleEnrichmentService(),
    localCache,
    geminiDictionaryService,
    preCacheService,
  );

  await controller.initialize();
  runApp(StackitApp(controller: controller, authService: authService));
}
