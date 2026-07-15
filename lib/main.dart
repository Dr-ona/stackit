import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/stackit_app.dart';
import 'data/app_check_service.dart';
import 'data/auth_service.dart';
import 'data/contextual_explanation_service.dart';
import 'data/offline_dictionary.dart';
import 'data/platform_bridge.dart';
import 'data/review_notification_service.dart';
import 'data/vocabulary_cloud_store.dart';
import 'features/vocabulary/vocabulary_controller.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await const AppCheckService().activate();

  final authService = AuthService();
  await authService.initialize();
  final notificationService = ReviewNotificationService();
  await notificationService.initialize();

  final controller = VocabularyController(
    OfflineDictionary(),
    PlatformBridge(),
    FirestoreVocabularyCloudStore(),
    FirebaseContextualExplanationService(),
    notificationService,
  );

  await controller.initialize();
  runApp(StackitApp(controller: controller, authService: authService));
}
