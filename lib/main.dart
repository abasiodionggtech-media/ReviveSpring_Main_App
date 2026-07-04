import 'package:flutter/material.dart';

import 'core/app_colors.dart';
import 'core/app_controller.dart';
import 'core/app_stage.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/auth/verify_screen.dart';
import 'screens/language_screen.dart';
import 'screens/main/app_shell.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'services/mobile_ads_service.dart';
import 'services/notification_service.dart';
import 'widgets/animated_background.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAdsService.instance.initialize();
  await NotificationService.instance.initializeBackgroundNotificationSync();
  runApp(const ReviveSpringApp());
}

class ReviveSpringApp extends StatefulWidget {
  const ReviveSpringApp({super.key});

  @override
  State<ReviveSpringApp> createState() => _ReviveSpringAppState();
}

class _ReviveSpringAppState extends State<ReviveSpringApp> {
  late final AppController controller;

  @override
  void initState() {
    super.initState();
    controller = AppController()..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReviveSpring',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        scaffoldBackgroundColor: AppColors.iconCream,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.deepEmerald),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: AppColors.deepEmerald,
          displayColor: AppColors.deepEmerald,
        ),
        iconTheme: const IconThemeData(color: AppColors.deepEmerald),
      ),
      home: AnimatedBackground(
        child: PopScope(
          canPop: !controller.canHandleSystemBack,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) controller.handleSystemBack();
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 620),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final curved = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              );
              return FadeTransition(
                opacity: curved,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(.08, .02),
                    end: Offset.zero,
                  ).animate(curved),
                  child: child,
                ),
              );
            },
            child: switch (controller.stage) {
              AppStage.splash => SplashScreen(
                key: const ValueKey('splash'),
                controller: controller,
              ),
              AppStage.language => LanguageScreen(
                key: const ValueKey('language'),
                controller: controller,
              ),
              AppStage.onboarding => OnboardingScreen(
                key: const ValueKey('onboarding'),
                controller: controller,
              ),
              AppStage.auth => AuthScreen(
                key: const ValueKey('auth'),
                controller: controller,
              ),
              AppStage.verify => VerifyScreen(
                key: const ValueKey('verify'),
                controller: controller,
              ),
              AppStage.app => AppShell(
                key: const ValueKey('app'),
                controller: controller,
              ),
            },
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => const ReviveSpringApp();
}
