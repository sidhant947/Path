import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'utils/step_service.dart';
import 'pages/goal_setup_page.dart';
import 'pages/main_page.dart';
import 'pages/welcome_page.dart';
import 'providers/step_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  await prefs.reload(); // Critical for cross-isolate sync on startup

  final repository = StepService(prefs);
  final hasCompletedOnboarding = prefs.getBool('onboarding_complete') ?? false;

  final stepProvider = StepProvider(repository);
  
  // Kick off async init (permissions, stream) without awaiting
  // so the UI can render immediately with the sync data from constructor
  stepProvider.init();

  runApp(
    ChangeNotifierProvider<StepProvider>.value(
      value: stepProvider,
      child: MyApp(
        initialGoal: prefs.getInt('daily_goal'),
        repository: repository,
        hasCompletedOnboarding: hasCompletedOnboarding,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final int? initialGoal;
  final StepService repository;
  final bool hasCompletedOnboarding;

  const MyApp({
    super.key,
    this.initialGoal,
    required this.repository,
    required this.hasCompletedOnboarding,
  });

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<StepProvider, ThemeMode>((p) => p.themeMode);

    return MaterialApp(
      title: 'Step Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        brightness: Brightness.light,
        fontFamily: 'Space Grotesk',
      ),
      darkTheme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        brightness: Brightness.dark,
        fontFamily: 'Space Grotesk',
      ),
      themeMode: themeMode,
      home: hasCompletedOnboarding
          ? (initialGoal == null
                ? GoalSetupPage(repository: repository)
                : MainPage(repository: repository))
          : WelcomePage(repository: repository),
    );
  }
}
