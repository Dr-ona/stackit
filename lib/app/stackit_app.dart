import 'package:flutter/material.dart';

import '../data/auth_service.dart';
import '../features/auth/auth_gate.dart';
import '../features/vocabulary/vocabulary_controller.dart';

class StackitApp extends StatelessWidget {
  const StackitApp({
    super.key,
    required this.controller,
    required this.authService,
  });

  final VocabularyController controller;
  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF17251F);
    const moss = Color(0xFF356859);
    const paper = Color(0xFFF7F4EC);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stackit',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: paper,
        colorScheme: ColorScheme.fromSeed(
          seedColor: moss,
          brightness: Brightness.light,
          surface: const Color(0xFFFFFCF5),
        ),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: ink,
          displayColor: ink,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: ink,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFFFFFCF5),
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.72),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: AuthGate(authService: authService, controller: controller),
    );
  }
}
