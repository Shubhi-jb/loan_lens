import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:loan_lens/core/theme/app_theme.dart';
import 'package:loan_lens/core/services/hive_service.dart';
import 'package:loan_lens/features/home/presentation/pages/home_screen.dart';
import 'package:loan_lens/features/onboarding/presentation/pages/onboarding_screen.dart';
import 'package:loan_lens/features/voice/logic/language_provider.dart';
import 'package:loan_lens/features/voice/logic/voice_provider.dart';
import 'package:loan_lens/features/analysis/logic/analysis_provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:loan_lens/features/config/logic/remote_config_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
void main() async {
  debugPrint('DEBUG: App Starting Main...');
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('DEBUG: .env load successful');
  } catch (e) {
    debugPrint('DEBUG: .env load FAILED: $e');
  }
  // Override the default grey screen of death with a user-friendly UI
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.teal),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong or you are offline.',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Please check your connection or restart the app. Your data is still safely saved on your device.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  };
  
  // 1. ALWAYS initialize Hive storage first (Required for initial route)
  try {
    await HiveService.init();
  } catch (e) {
    debugPrint('Hive initialization failed: $e');
  }

  // 2. Background Firebase and Remote Config (Non-blocking)
  _initOptionalServices();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => VoiceProvider()),
        ChangeNotifierProvider(create: (_) => AnalysisProvider()),
      ],
      child: const LoanLensApp(),
    ),
  );
}

/// Initializes non-critical services in the background
Future<void> _initOptionalServices() async {
  try {
    // Attempt Firebase init without blocking the UI
    try {
      await Firebase.initializeApp();
      
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
      );
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
    }

    await RemoteConfigService.init();
    debugPrint('Optional services initialized in background.');
  } catch (e) {
    debugPrint('Background initialization failed (Offline mode likely): $e');
  }
}

class LoanLensApp extends StatelessWidget {
  const LoanLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LoanLens',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: HiveService.getSetting('onboarding_seen', defaultValue: false) 
          ? const HomeScreen() 
          : const OnboardingScreen(),
    );
  }
}
