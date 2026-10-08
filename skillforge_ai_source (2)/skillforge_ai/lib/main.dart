import 'dart:async';

import 'package:flutter/material.dart';

import 'features/onboarding/onboarding_screen.dart';
import 'state/app_controller.dart';
import 'theme.dart';

void main() {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      // Show a friendly message instead of the red error screen.
      ErrorWidget.builder = (details) => const Material(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Something went wrong on this screen. Please go back and try again.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
      runApp(SkillForgeApp(controller: AppController()));
    },
    (error, stack) => debugPrint('Unhandled error: $error'),
  );
}

class SkillForgeApp extends StatelessWidget {
  const SkillForgeApp({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkillForge AI',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: OnboardingScreen(controller: controller),
    );
  }
}
